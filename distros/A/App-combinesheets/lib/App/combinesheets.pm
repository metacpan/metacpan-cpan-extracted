#-----------------------------------------------------------------
# App::combinesheets
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer se below.
#
# ABSTRACT: command-line tool merging CSV and TSV spreadsheets
# PODNAME: App::combinesheets
#-----------------------------------------------------------------
use warnings;
use strict;

package App::combinesheets;

our $VERSION = '0.2.14'; # VERSION

use base 'App::Cmd::Simple';

use Pod::Usage;
use Pod::Find qw(pod_where);

use Text::CSV::Simple;
use Text::CSV_XS;
use File::Spec;
use File::Temp;
use File::Which;
use File::BOM qw( :all );
use Algorithm::Loops qw( NestedLoops );
use autouse 'IO::CaptureOutput' => qw(capture_exec);

# reserved keywords in the configuration
use constant {
    CFG_MATCH => 'MATCH',
    CFG_PROG  => 'PROG',
    CFG_PROGS => 'PROGS',
    CFG_PERL  => 'PERL',
};

# types of input files
use constant {
    TYPE_CSV => 'csv',
    TYPE_TSV => 'tsv',
#    TYPE_XSL => 'xsl',    # not-yet-supported
};

# hash keys describing an input ($inputs)
use constant {
    INPUT_FILE              => 'file',
    INPUT_TYPE              => 'type',
    INPUT_MATCHED_BY        => 'matched_by',
    INPUT_MATCHED_BY_INDEX  => 'matched_by_index',
    INPUT_HEADERS           => 'headers',
    INPUT_CONTENT           => 'content',
};

# hash keys describing wanted fields ($wanted_columns)
use constant {
    CFG_TYPE     => 'type',   # what kind of input (MATCH, PROG, PROGS or PERL)
    CFG_OUT_COL  => 'ocol',   # a name for this column used in the output
    # keys used for the normal (MATCH) columns
    CFG_ID       => 'id',     # which input
    CFG_IN_COL   => 'icol',   # a column in such input
    # keys used for the calculated columns (i.e. of type PROG, PROGS or PERL)
    CFG_EXT      => 'id',     # name of the external program or Perl external subroutine
    PERL_DETAILS => '_perl_details_', # added during the config processing
};

# ----------------------------------------------------------------
# Command-line arguments and script usage
# ----------------------------------------------------------------
sub usage_desc {
     my $self = shift;
     return "%c -config <config-file> -inputs <inputs> [other otions...]";
}
sub opt_spec {
    return (
        [ 'h'               => "display a short usage message" ],
        [ 'help'            => "display a full usage message"  ],
        [ 'man|m'           => "display a full manual page"    ],
        [ 'version|v'       => "display a version"             ],
        [],
        [ 'config|cfg=s'    => "<configuration file>"          ],
        [ 'inputs|i=s@{1,}' => "<input files> in the form: <input-ID>=<filename>[,<input-ID>=<filename>...] (e.g. PERSON=<persons.tsv>,CAR=<cars.csv>)"                                  ],
        [ 'outfile|o=s'     => "<output file>"                 ],
        [ 'check|c'         => "only check the configuration"  ],

        { getopt_conf => ['no_bundling', 'no_ignore_case', 'auto_abbrev'] }
        );
}
sub validate_args {
    my ($self, $opt, $args) = @_;

    # show various levels of help and exit
    my $pod_where = pod_where ({-inc => 1}, __PACKAGE__);
    if ($opt->h) {
        print "Usage: " . $self->usage();
        if ($^S) { die "Okay\n" } else { exit (0) };
    }
    pod2usage (-input => $pod_where, -verbose => 1, -exitval => 0) if $opt->help;
    pod2usage (-input => $pod_where, -verbose => 2, -exitval => 0) if $opt->man;

    # show version and exit
    if ($opt->version) {
        ## no critic
        no strict;    # because the $VERSION will be added only when
        no warnings;  # the distribution is fully built up
        print "$VERSION\n";
        if ($^S) { die "Okay\n" } else { exit (0) };
    }

    # check required command-line arguments
    $self->usage_error ("Parameter '-config' is required.")
        unless $opt->config;
    $self->usage_error ("Parameter '-inputs' is required.")
        unless $opt->inputs;

    return;
}
sub usage_error {
    my ( $self, $error ) = @_;
    die "Error: $error\nUsage: " . $self->usage->text;
}

# ----------------------------------------------------------------
# The main part
# ----------------------------------------------------------------
my $inputs;     # keys are input IDs
sub execute {
    my ($self, $opt, $args) = @_;

    $inputs = {};   # just in case somebody calls execute() twice

    my @opt_inputs = split (m{,}, join (',', @{ $opt->inputs }));
    my $opt_outfile = $opt->outfile;
    my $opt_cfgfile = $opt->config;

    # prepare output handler
    my $combined;
    if ($opt_outfile and not $opt->check) {
        open ($combined, '>', $opt_outfile)
            or die "[ER00] Cannot open file $opt_outfile for writing: $!\n";
    } else {
        $combined = *STDOUT;
    }

    # read configuration
    my $wanted_cols = [];   # each element: { CFG_TYPE, CFG_ID, CFG_IN_COL, CFG_OUT_COL... }
    my $known_inputs = {};  # input ID => 1  ... the same input IDs as in $wanted_cols (for speed)
    my $matches = {};       # input ID => matching column/header
    my $config;
    open ($config, '<', $opt_cfgfile)
        or die "[ER00] Cannot read configuration file $opt_cfgfile: $!\n";
    my $line_count = 0;
    while (<$config>) {
        $line_count++;
        chomp;
        next if m{^\s*$};   # ignore empty lines
        next if m{^\s*#};   # ignore comment lines
        s{^\s+|\s+$}{}g;    # trim whitespaces
        my ($input_id, $input_col, $output_col) = split (m{\s*\t\s*}, $_, 3);
        unless ($input_id and defined $input_col) {
            warn "[WR01] Configuration line $line_count ignored: '$_'\n";
            next;
        }
        $input_id = uc ($input_id);   # make config keys upper-case
        if ($input_id eq CFG_MATCH) {
            my ($input_id, $column) = split (m{\s*=\s*}, $input_col, 2);
            unless ($input_id and $column !~ m{^\s*$}) {
                warn "[WR02] Bad format in configuration line $line_count: '$input_col'. Ignored.\n";
                next;
            }
            $matches->{ uc ($input_id) } = $column;
            next;
        }
        my $wanted_col = {};
        if ($input_id eq CFG_PROG or $input_id eq CFG_PROGS or $input_id eq CFG_PERL) {
            $wanted_col->{CFG_TYPE()} = $input_id;
            $wanted_col->{CFG_EXT()} = $input_col;
            if (defined $output_col) {
                $wanted_col->{CFG_OUT_COL()} = $output_col;
            } else {
                warn "[WR10] Missing output column name in configuration line $line_count: '$input_col'.\n";
                $wanted_col->{CFG_OUT_COL()} = '';
            }
        } else {
            $wanted_col->{CFG_TYPE()}    = CFG_MATCH;
            $wanted_col->{CFG_ID()}      = $input_id;
            $wanted_col->{CFG_IN_COL()}  = $input_col;
            $wanted_col->{CFG_OUT_COL()} = (defined $output_col ? $output_col : $input_col);
            $known_inputs->{$input_id} = 1;
        }
        push (@$wanted_cols, $wanted_col);
    }
    close $config;

    # prepare for calculated columns
    foreach my $col (@$wanted_cols) {
        if ($col->{CFG_TYPE()} eq CFG_PROG or $col->{CFG_TYPE()} eq CFG_PROGS) {

            # locate the external program
            $col->{CFG_EXT()} = find_prog ($col->{CFG_EXT()});

        } elsif ($col->{CFG_TYPE()} eq CFG_PERL) {

            # load the wanted Perl module
            my $call = $col->{CFG_EXT()};
            $call =~ m{^(.+)((::)|(->))(.*)$};
            my $module = $1;
            my $subroutine = $5;
            my $how_to_call = $2;   # can be '::' or '->'
            unless ($module) {
                warn "[WR11] Missing module name in '[PERL] " . $col->{CFG_OUT_COL()} . "'. Column ignored.\n";
                $col->{ignored} = 1;
                next;
            }
            unless ($subroutine) {
                warn "[WR12] Missing subroutine name in '[PERL] " . $col->{CFG_OUT_COL()} . "'. Column ignored.\n";
                $col->{ignored} = 1;
                next;
            }
            if ($module =~ m{^:+}) {
                warn "[WR13] Uncomplete module name in '[PERL] " . $col->{CFG_OUT_COL()} . "'. Column ignored.\n";
                $col->{ignored} = 1;
                next;
            }
            eval "require $module";  ## no critic
            if ($@) {
                warn "[WR14] Cannot load module '$module': $@. Column '" . $col->{CFG_OUT_COL()} . " ignored\n";
                $col->{ignored} = 1;
                next;
            }
            $module->import();

            # remember what we just parsed and checked
            $col->{PERL_DETAILS()} = {};
            $col->{PERL_DETAILS()}->{what_to_call} = $module . $how_to_call . $subroutine;
            $col->{PERL_DETAILS()}->{module} = $module;
            $col->{PERL_DETAILS()}->{subroutine} = $subroutine;
            $col->{PERL_DETAILS()}->{how_to_call} = $how_to_call;
        }
    }
    $wanted_cols = [ grep { not $_->{ignored} } @$wanted_cols ];

    # locate expected inputs
    my $primary_input;   # ID of the first input
    foreach my $opt_input (@opt_inputs) {
        my ($key, $value) = split (m{\s*=\s*}, $opt_input, 2);
        next unless $key;
        next unless $value;
        $key = uc ($key);
        unless (exists $known_inputs->{$key}) {
            warn "[WR03] Configuration does not recognize the input named '$key'. Input ignored.\n";
            next;
        }
        unless (exists $matches->{$key}) {
            warn "[WR04] Input named '$key' does not have any MATCH column defined in configuration. Input ignored.\n";
            next;
        }
        $primary_input = $key unless $primary_input;   # remember which input came first
        my $input = { INPUT_FILE()       => $value,
                      INPUT_MATCHED_BY() => $matches->{$key} };
        if ($value =~ m{\.csv$}i) {
            $input->{INPUT_TYPE()} = TYPE_CSV;
        } else {
            $input->{INPUT_TYPE()} = TYPE_TSV;
        }
        $inputs->{$key} = $input;
    }
    die "[ER01] No valid inputs specified. Exiting.\n"
        unless scalar keys (%$inputs) > 0;

    # read headers from all inputs
    my $headers_by_id = {};  # used for re-using the same headers once read, and for some checks
    foreach my $input_id (keys %$inputs) {
        my $input = $inputs->{$input_id};
        my $headers;
        if (exists $headers_by_id->{$input_id}) {
            $headers = $headers_by_id->{$input_id};   # copy already known headers
        } else {
            $headers = read_headers ($input);
        }

        # add new properties to $input
        unless (exists $headers->{ $input->{INPUT_MATCHED_BY()} }) {
            warn ("[WR05] Input '$input_id' does not contain the matching header '" . $input->{INPUT_MATCHED_BY()} .
                  "'. Input ignored\n");
            delete $inputs->{$input_id};
            next;
        }
        $headers_by_id->{$input_id} = $headers
            unless exists $headers_by_id->{$input_id};
        $input->{INPUT_HEADERS()} = $headers;
        $input->{INPUT_MATCHED_BY_INDEX()} = $headers->{ $input->{INPUT_MATCHED_BY()} };
    }

    # check real headers vs. headers as defined in configuration
    my $already_reported = {};
    foreach my $col (@$wanted_cols) {
        next if $col->{CFG_TYPE()} ne CFG_MATCH;   # check is done only for normal columns
        my $input_id = $col->{CFG_ID()};
        if (exists $headers_by_id->{$input_id}) {
            # does the requested column exist in this input's headers?
            unless (column_exists ($input_id, $col->{CFG_IN_COL()})) {
                warn "[WR06] Column '$col->{CFG_IN_COL()}' not found in the input '$input_id'. Column will be ignored.\n";
                $col->{ignored} = 1;
            }
            next;

        } elsif (!exists $already_reported->{$input_id}) {
            $already_reported->{$input_id} = 1;
            warn "[WR07] Configuration defines columns from an input '$input_id' but no such input given (or was ignored). These columns will be ignored.\n";
        }
        $col->{ignored} = 1;
    }
    $wanted_cols = [ grep { not $_->{ignored} } @$wanted_cols ];

    foreach my $input_id (keys %$matches) {
        next unless exists $inputs->{$input_id};   # ignoring matches whose inputs are already ignored
        # does the matching column exist in this input's headers?
        unless (column_exists ($input_id, $matches->{$input_id})) {
            die "[ER02] Matching column '$matches->{$input_id}' not found in the input '$input_id'. Must exit.\n";
        }
    }

    # do we still have a primary input?
    unless (exists $inputs->{$primary_input}) {
        die "[ER03] Due to errors, the primary input '$primary_input' is now ignored. Must exit.\n";
    }

    # end of checking
    exit (0) if $opt->check;

    # read all inputs into memory
    foreach my $input_id (keys %$inputs) {
        my $input = $inputs->{$input_id};
        my $content = read_content ($input);
        $input->{INPUT_CONTENT()} = $content;
    }

    # output combined headers
    my @header_line = ();
    foreach my $col (@$wanted_cols) {
        push (@header_line, $col->{CFG_OUT_COL()});
    }
    print $combined join ("\t", @header_line) . "\n"
        unless scalar @header_line == 0;

    # combine all inputs and make output lines
    foreach my $matching_content (sort keys %{ $inputs->{$primary_input}->{INPUT_CONTENT()} }) {
        # $matching_content is, for example, a publication title ("An Atlas of....")

        # inputs may have more lines with the same value in the matching columns
        # therefore, extract first the matching lines from all inputs
        my $lines_to_combine = [];
        my $inputs_to_combine = {};  # keys are inputs' CFG_IDs, values are indeces into $lines_to_combine

        foreach my $col (@$wanted_cols) {
            if ($col->{CFG_TYPE()} eq CFG_MATCH) {
                unless (exists $inputs_to_combine->{ $col->{CFG_ID()} }) {
                    # remember the same lines (from the same input) only once
                    my $input = $inputs->{ $col->{CFG_ID()} };
                    push (@$lines_to_combine, $input->{INPUT_CONTENT()}->{$matching_content} || [undef]);
                    $inputs_to_combine->{ $col->{CFG_ID()} } = $#$lines_to_combine;
                }
            }
        }

        # make all combinantions of matching lines

        # let's have 3 inputs, identified by K, L and M
        # there are three matching lines in K, two in L and one in M:
        # my $lines_to_combine = [
        #       [ "line1", "line2", "line3", ], # from input K
        #       [ "lineX", "lineY", ],          # from input L
        #       [ "lineQ", ],                   # from input M
        #       );
        # my $inputs_to_combine = { K => 0, L => 1, M => 2 };
        #
        # the subroutine create_output_line() will be called 6 times
        # with the following arguments:
        #   line1, lineX, lineQ
        #   line1, lineY, lineQ
        #   line2, lineX, lineQ
        #   line2, lineY, lineQ
        #   line3, lineX, lineQ
        #   line3, lineY, lineQ

        NestedLoops ($lines_to_combine,
                     sub {
                         my @input_lines = @_;
                         my @output_line = ();
                         my @calculated = ();   # indeces of the yet-to-be-calculated elements
                         my $column_count = -1;
                         foreach my $col (@$wanted_cols) { # $col defines what data to push into @output_line
                             $column_count++;
                             if ($col->{CFG_TYPE()} eq CFG_MATCH) {
                                 my $input = $inputs->{ $col->{CFG_ID()} };
                                 my $input_line = @input_lines[$inputs_to_combine->{ $col->{CFG_ID()} }];
                                 # use Data::Dumper;
                                 # print Dumper (\@input_lines);
                                 # print Dumper ($inputs_to_combine);
                                 my $idx = $input->{INPUT_HEADERS()}->{ $col->{CFG_IN_COL()} };
                                 my $value = $input_line->[$idx] || '';
                                 push (@output_line, $value);
                             } else {
                                 push (@calculated, $column_count);
                                 push (@output_line, '');
                             }
                         }
                         # insert the calculated columns
                         foreach my $idx (@calculated) {
                             if ($wanted_cols->[$idx]->{CFG_TYPE()} eq CFG_PROG) {
                                 $output_line[$idx] = call_prog ($wanted_cols->[$idx], \@header_line, \@output_line);
                             } elsif ($wanted_cols->[$idx]->{CFG_TYPE()} eq CFG_PROGS) {
                                 $output_line[$idx] = call_prog_simple ($wanted_cols->[$idx]);
                             } elsif ($wanted_cols->[$idx]->{CFG_TYPE()} eq CFG_PERL) {
                                 $output_line[$idx] = call_perl ($wanted_cols->[$idx], \@header_line, \@output_line);
                             }
                         }

                         print $combined join ("\t", @output_line) . "\n"
                             unless scalar @output_line == 0;
                     });
    }
    close $combined if $opt_outfile;
}

# ----------------------------------------------------------------
# Call a Perl subroutine (from any module) in order to get a value for
# a "calculated" column. $column defines which column to fill,
# $header_line is an arra is an arrayref with column headers and the
# $data_line is another arrayref with the values for the current row.
#
# $column->{PERL_DETAILS} contains all details needed for the call
# ----------------------------------------------------------------
sub call_perl {
    my ($column, $header_line, $data_line) = @_;

    no strict;  ## no critic
    my $what_to_call = $column->{PERL_DETAILS()}->{what_to_call};
    my $how_to_call  = $column->{PERL_DETAILS()}->{how_to_call};
    my $module       = $column->{PERL_DETAILS()}->{module};
    my $subroutine   = $column->{PERL_DETAILS()}->{subroutine};

    if ($how_to_call eq '->') {
        return $module->$subroutine ($column, $header_line, $data_line);
    } else {
        return &$what_to_call ($column, $header_line, $data_line);
    }
}

# ----------------------------------------------------------------
# Call an external program in order to get a value for a "calculated"
# column. $column defines which column to fill, $header_line is an
# arra is an arrayref with column headers and the $data_line is
# another arrayref with the values for the current row.
#
# $column->{CFG_EXT} contains a program name to call
# ----------------------------------------------------------------
sub call_prog {
    my ($column, $header_line, $data_line) = @_;

    # prepare an input file for the external program
    my $tmp = File::Temp->new();
    for (my $i = 0; $i < @$header_line;$i++) {
        print $tmp $header_line->[$i] . "\t" . $data_line->[$i] . "\n";
    }

    # call it
    return _call_it ($column->{CFG_EXT()}, $tmp);
}

# ----------------------------------------------------------------
# Call an external program (without any command-line arguments) in
# order to get a value for a "calculated" column.
#
# $column->{CFG_EXT} contains a program name to call
# ----------------------------------------------------------------
sub call_prog_simple {
    my ($column) = @_;
    return _call_it ($column->{CFG_EXT()});
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub _call_it {
    my @command = @_;
    my ($stdout, $stderr, $success, $exit_code) = capture_exec (@command);
    if ($exit_code != 0 or $stderr) {
        my $errmsg = '[ER05] Failed command: ' . join (' ', map {"'$_'"} @command) . "\n";
        $errmsg .= "STDERR: $stderr\n" if $stderr;
        $errmsg .= "EXIT CODE: $exit_code\n";
        die $errmsg;
    }
    chomp $stdout;         # remove the last newline
    $stdout =~ s{\n}{ }g;  # better to replace newlines
    return $stdout;
}

# ----------------------------------------------------------------
# Locate given $prgname and return it, usually with an added path. Or
# die if such program cannot be found or it is not executable.
# ----------------------------------------------------------------
sub find_prog {
    my $prgname = shift;
    my $full_name;

    # 1) try the name as it is (e.g. the ones with an absolute path)
    if (-e $prgname and -x $prgname and
        File::Spec->file_name_is_absolute ($prgname)) {
        return $prgname;
    }

    # 2) try to find it on system PATH
    $full_name = which ($prgname);
    if ($full_name ) {
        chomp $full_name;
        return $full_name;
    }

    # 3) try the environment variable with a path
    if (exists $ENV{COMBINE_SHEETS_EXT_PATH}) {
        $full_name = File::Spec->catfile ($ENV{COMBINE_SHEETS_EXT_PATH}, $prgname);
        return maybe_die ($full_name);
    }

    # 4) try to find it in the current directory
    $full_name = File::Spec->catfile ('./', $prgname);
    return maybe_die ($full_name);
}
sub maybe_die {
    my $prg = shift;
    die "[ER04] '$prg' not found or is not executable.\n"
        unless -e $prg and -x $prg;
    return $prg;
}

# ----------------------------------------------------------------
# Does the requested $column exist in the given input's headers?
# ----------------------------------------------------------------
sub column_exists {
    my ($input_id, $column) = @_;
    return exists $inputs->{$input_id}->{INPUT_HEADERS()}->{$column};
}

# ----------------------------------------------------------------
# Read the headers (the first line) form an input file (given in
# hashref $input) and store them in the hashref $headers, each od them
# with its index as it appears in the read file. Do nothing if
# $headers already contains headers from the same input identifier.
# ----------------------------------------------------------------
sub read_headers {
    my ($input) = @_;

    my $headers;
    if ($input->{INPUT_TYPE()} eq TYPE_CSV) {
        $headers = read_csv_headers ($input->{INPUT_FILE()});
    } else {
        $headers = read_tsv_headers ($input->{INPUT_FILE()});
    }
    my $new_headers = {};
    my $column_index = 0;
    foreach my $column (@$headers) {
        $new_headers->{$column} = $column_index++;
    }
    return $new_headers;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub read_csv_headers {
    my ($file) = @_;
    my $line = read_first_line ($file);

    my $parser = Text::CSV_XS->new ({
        allow_loose_quotes => 1,
        escape_char        => "\\",
                                    });
    if ($parser->parse ($line)) {
        return [ $parser->fields ];
    } else {
        die "[ER04] Parsing CSV file $file failed: " .
            $parser->error_input  . "\n" .
            $parser->error_diag() . "\n";
    }
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub read_tsv_headers {
    my ($file) = @_;
    my $line = read_first_line ($file);
    return [ split (m{\t}, $line) ];
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub read_first_line {
    my ($file) = @_;
    my $fh;
    open_bom ($fh, $file); # or open ($fh, '<', $file)
        # or die "[ER00] Cannot read input file $file: $!\n";
    my $line = <$fh>;          # read just one line
    close $fh;
    $line =~ s{(\r|\n)+$}{};   # remove newlines of any kind
    return $line;
}

# ----------------------------------------------------------------
# Stringify a hashref
# ----------------------------------------------------------------
sub ph {
    my $hashref = shift;
    my $result = '';
    my ($key, $value);
    while (($key, $value) = each (%$hashref)) {
        $result .= "$key => $value,";
    }
    return substr ($result, 0, -1);
}

# ----------------------------------------------------------------
# Read contents...
# ----------------------------------------------------------------
sub read_content {
    my ($input) = @_;
    my $content;
    if ($input->{INPUT_TYPE()} eq TYPE_CSV) {
        $content = read_csv_content ($input->{INPUT_FILE()}, $input->{INPUT_MATCHED_BY_INDEX()});
    } else {
        $content = read_tsv_content ($input->{INPUT_FILE()}, $input->{INPUT_MATCHED_BY_INDEX()});
    }
    return $content;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub read_tsv_content {
    my ($file, $matched_index) = @_;
    my $fh;
    open_bom ($fh, $file); # or open ($fh, '<', $file)
        # or die "[ER00] Cannot read input file $file: $!\n";
    my $content = {};
    my $line_count = 0;
    while (my $line = <$fh>) {
        next if $line_count++ == 0;  # skip header line
        next if $line =~ m{^\s*$};   # ignore empty lines
        $line =~ s{(\r|\n)+$}{};     # remove newlines of any kind
        my @data = split (m{\t}, $line);
        $content->{ $data[$matched_index] } = [] unless $content->{ $data[$matched_index] };
        push (@{ $content->{ $data[$matched_index] } }, [@data]);
    }
    close $fh;
    return $content;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub read_csv_content {
    my ($file, $matched_index) = @_;
    my $count_lines = 0;
    my $content = {};

    # create a CSV parser; any error in reading input will be fatal
    my $csv = Text::CSV_XS->new ({
        allow_loose_quotes => 1,
        escape_char        => "\\",
        auto_diag          => 1,
                                 });

    # read the CSV input
    open_bom (my $fh, $file);
    while (<$fh>) {
        if ($csv->parse ($_)) {
            next if $count_lines++ == 0;   # headers are ignored
            my @data = $csv->fields;
            if (@data) {
                push (@{ $content->{ $data[$matched_index] } }, \@data);
            }
        } else {
            my $err = $csv->error_input;
            warn "[WR09] Possible a wrong or not-readable input file '$file': $err\n";
            exit (1);
        }
    }

    # $parser->add_trigger (after_parse => sub {
    #     my ($self, $data) = @_;
    #     return if $count_lines++ == 0;   # headers are ignored
    #     $content->{ $data->[$matched_index] } = [] unless $content->{ $data->[$matched_index] };
    #     push (@{ $content->{ $data->[$matched_index] } }, $data);
    #                       });
    # read CSV input (the result is not used here; everything is done in triggers)
    # $parser->read_file ($file);

    return $content;
}
1;



=pod

=head1 NAME

App::combinesheets - command-line tool merging CSV and TSV spreadsheets

=head1 VERSION

version 0.2.14

=head1 SYNOPSIS

   combinesheets -h
   combinesheets -help
   combinesheets -man
   combinesheets -version

   combinesheets -config <config-file> -inputs <input-files> [<options>] [-outfile <output-file>]

      where <input-files> has the form: <input-ID>=<filename> [<input-ID>=<filename>...]
      where <options> are: -check

=head1 DESCRIPTION

B<combinesheets> is a command-line tool merging together two or more
spreadsheets. The spreadsheets can be COMMA-separated or TAB-separated
files, each of them having the first line with column headers. Data in
one of the column (it can be a different column in each input
spreadsheet) serve to match lines. For example, having two spreadsheets,
PERSON and CAR, with the following contents:

   persons.tsv:

   Surname      First name  Sex  Age  Nickname
   Novak        Jan         M    52   Honza
   Gudernova    Jitka       F    56
   Senger       Martin      M    61   Tulak

   cars.tsv:

   Model  Year  Owned by
   Praga  1936  Someone else
   Mini   1968  Gudernova
   Skoda  2002  Senger

we want to merge these spreadsheet by C<Surname> in persons.tsv and by
C<Owned by> in cars.tsv. There are two possible results, depending
which spreadsheet is used as the first one (a primary one). If the
persons.tsv is the first, the result will be (which columns are
included in the result will be described later in this document):

   combinesheets -cfg config.cfg -in PERSON=persons.tsv CAR=cars.csv

   First name  Surname    Model  Sex  Nickname  Age  Year  Owned by
   Jitka       Gudernova  Mini   F              56   1968  Gudernova
   Jan         Novak             M    Honza     52
   Martin      Senger     Skoda  M    Tulak     61   2002  Senger

Or, if the cars.tsv is the first, the result will be:

   combinesheets -cfg config.cfg -in CAR=cars.csv PERSON=persons.tsv

   First name  Surname    Model  Sex  Nickname  Age  Year  Owned by
   Jitka       Gudernova  Mini   F              56   1968  Gudernova
   Martin      Senger     Skoda  M    Tulak     61   2002  Senger
                          Praga                      1936  Someone else

Of course, if both input spreadsheets have only the matching lines,
both results will be the same (it will not matter which one of them is
considered the primary one).

The rows in the resulting spreadsheet are sorted by values in the
column that was used as a matching column in the primary input.

The information which columns should be used to match the input
spreadsheets and which columns should appear in the resulting
spreadsheet is read from a configuration file (see the C<-config>
 - or C<-cfg> - argument).

The command-line arguments and options can be specified with single or
double dash. Most of them can be abbreviated to the nearest non-biased
length. They are case-sensitive.

=head2 Duplicated values in the matching columns

If there are repeated (the same) values in the column that serves as
matching criterion then the resulting spreadsheet will have as many
output lines (for a particular matching value) as is the number of all
combinations of the lines with that matching values in all input
spreadsheets. For example, let's have C<books.tsv> and C<authors.tsv>,
assuming that a book can have more authors and any author can
contribute to any number of books:

   books.tsv:
   Title   Note    Author
   Book 1  from B1-a       Kim
   Book 2  from B2-b       Kim
   Book 3  from B3-c       Katrin
   Book 1  from B1-d       Blanka
   Book 2  from B2-e       Katrin

   authors.tsv:
   Age     Name
   28      Kim
   20      Katrin
   30      Blanka
   50      Lazy author

The output (again, depending on which input is considered a primary
input) will be (a list of included column is defined in the
configuration file - see later):

   combinesheets -cfg books_to_authors.cfg -in BOOK=books.tsv AUTHOR=authors.tsv

   Name    Title   Age Note
   Blanka  Book 1  30  from B1-d
   Katrin  Book 3  20  from B3-c
   Katrin  Book 2  20  from B2-e
   Kim     Book 1  28  from B1-a
   Kim     Book 2  28  from B2-b

   combinesheets -cfg books_to_authors.cfg -in AUTHOR=authors.tsv BOOK=books.tsv

   Name        Title   Age  Note
   Blanka      Book 1  30   from B1-d
   Katrin      Book 3  20   from B3-c
   Katrin      Book 2  20   from B2-e
   Kim         Book 1  28   from B1-a
   Kim         Book 2  28   from B2-b
   Lazy author         50

=head1 ADVANCED USAGE

Additionally to the merging columns from one or more spreadsheets,
this script can also add completely new columns to the resulting
spreadsheet, the columns that do not exist in any of the input
spreadsheet. Such columns are called C<calculated columns>.

Each C<calculated column> is created either by an external,
command-line driven, program, or by a Perl subroutine. In both cases,
the user must create (write) such external program or such Perl
subroutine. Therefore, this usage is meant more for developers than
for the end users.

Note that this advanced feature is meant only for new columns, not for
new rows. Therefore, it cannot be used, for example, to create rows
with totals of columns.

=head2 Calculated columns by external programs

If specified, an external program is invoked for each row. It can be
specified either by a keyword B<PROG> or by a keyword B<PROGS> - see
syntax in the I<configuration> section. In both cases, the
value of the standard output of these programs become the value of the
calculated column (a trailing newline of this standard output is
removed and other newlines are replaced by spaces).

A program defined by the B<PROGS> is called without any arguments
(C<S> in I<PROGS> stands for a I<Simple>). That's why it does not have
any knowledge for which row it has been invoked. Its usage is,
therefore, for column values that are not dependent on other values
from the spreadsheet. For example, for the C<cars.tsv> shown above,
you can add a column C<Last updated> by calling a UNIX program C<date>
- again, see an example the I<configuration>
section.

A program defined by the B<PROG> is called with one argument which is
a filename. This file contains the current row; each of its lines has
two, TAB-separated, fields. The first field is the column name and the
second field is the column value. For example, when processing the
last row of the C<cars.tsv> given above, the file will have the
following content:

   Model       Skoda
   Year        2002
   Owned by    Senger

The files are only temporary and will be removed when
C<combinesheets> finishes.

=head2 Calculated columns by a Perl subroutine

If specified by the keyword B<PERL>, a Perl subroutine is called for
each row with the three arguments:

=over

=item 1

A hashref with information about the current column. Not often used
but may be handy if the same subroutine deals with more columns and,
therefore, needs to know for which column it was invoked. See the
I<flights> example in the I<configuration> section.

=item 2

An arrayref with all column names.

=item 3

An arrayref with all column values - in the same order as the column
names.

=back

Actually, depending how the subroutine is defined in the
configuration, it may get as the first argument the module/class name
where it belongs to. If you define it like this:

   PERL   Module::Example::test

the C<test> subroutine is called, indeed, with the three arguments as
described above. However, if your definition is rather:

   PERL   Module::Example->test

then the C<test> subroutine is considered a Perl method and its first
argument is the module/class name. It is up to you to decide how you
want/need to write your functions. Again, an example is available in
the I<configuration> section.

The return value of the subroutine will become a new value in the
calculated column. Do not return undef but rather an empty string if
the value cannot be created.

What is an advantage of writing my own module/package if I can simply
write an external program (perhaps also in Perl) doing exactly the
same? The Perl module stays in the memory for the whole time of
processing all input rows and, therefore, you can re-use some
calculations done for the previous rows. An example about it
(C<flights>) is given in the I<configuration>
section.

=head1 ARGUMENTS and OPTIONS

=over 4

=item B<-config <config-file>>

A filename with a configuration file. This is a mandatory
parameter. The configuration file describes:

=over

=item *

which columns in individual input spreadsheets should be
included in the resulting spreadsheet,

=item *

what names should be given to the resulting columns

=item *

in which order should be the columns in the resulting
spreadsheet

=item *

which columns should be used to match individual lines,

=back

The configuration file is a TAB-separated file (with no header
line). Empty lines and lines starting with a "#" character are
ignored. Each line has two columns, in some cases there is an optional
third column. Here is a configuration file used in the example above:

   # Columns to match records from individual inputs
   MATCH   PERSON=Surname
   MATCH   CAR=Owned by
   MATCH   CHILD=Parent

   # Columns - how they be in rows
   PERSON  First name
   PERSON  Surname
   CAR     Model
   PERSON  Sex
   CHILD   Name
   CHILD   Born
   PERSON  Nickname
   PERSON  Age
   CAR     Year
   CAR     Owned by

The first column is either a reserved word C<MATCH>, or an identifier
of an input spreadsheet. There are also few other reserved words - see
more about them a bit later.

The identifier can be almost anything (and it does not appear in the
input spreadsheet itself). It is also used in the command-line
argument C<-inputs> where it corresponds to a real file name of the
input. The lines with identifiers define what columns will be in the
result: the second column is the header of the wanted columns and an
optional third column (not used in the example above) is the header
used in the result. The resulting columns will be in the same order as
are these lines in the configuration file.

The reserved word C<MATCH> is used to define how to match lines in the
input spreadsheets. The format of its second column is:

   <input-ID>=<column-header>

There should be one MATCH line for each input spreadsheet. The data in
the column defined by the "column-header" will be used to find the
corresponding lines. In our example, the data in the column I<Surname>
in the C<persons.tsv> will be matched with the data in the column
I<Owned by> in the C<cars.tsv> (the rows having the same values in
these two columns will be merged into one resulting row).

B<Advanced configuration>

If you want to add so-called I<calculated columns> as described in the
L</"ADVANCED USAGE"> you need to use few additional reserved words in the
configuration file. These words are B<PROG>, B<PROGS> and/or
B<PERL>. They are used in the place where the new calculated column
should be placed. Their lines have the program name or the Perl
subroutine name in the second column, and they have mandatory third
column with the resulting name of the calculated column.

For example, we wish to add two columns to the input spreadsheet
C<cars.tsv>. The input file (the same as in the introduction) is:

   Model  Year  Owned by
   Praga  1936  Someone else
   Mini   1968  Gudernova
   Skoda  2002  Senger

We wish to add a column I<Car age> that shows the difference between
the actual year and the value from the I<Year> column. We have a
shell script C<age.sh> doing it:

   #!/bin/bash
   YEAR=`grep Year $1 | cut -f2`
   NOW=`date +%Y`
   echo $(($NOW-$YEAR))

The configuration file C<cars.cfg> (assuming that we want the other
columns to remain the same) is:

   MATCH   CAR=Owned by

   CAR     Owned by
   CAR     Model
   CAR     Year
   PROG    age.sh  Car age

When we run:

   combinesheets -config cars.cfg -inputs CAR=cars.tsv

we get this result:

   Owned by        Model   Year    Car age
   Gudernova       Mini    1968    44
   Senger          Skoda   2002    10
   Someone else    Praga   1936    76

You can see that there is no need to use C<combinesheets> for really
combining I<more> sheets, an input can be just one sheet.

Another example adds a I<fixed> column to the same input, a column
named I<Last updated> that gets its value from a UNIX command
C<date>. This program does not get any information which row it has
been invoked for. The configuration file is now (note the new line
with the B<PROGS>):

   MATCH   CAR=Owned by

   CAR     Owned by
   CAR     Model
   CAR     Year
   PROG    age.sh  Car age
   PROGS   date    Last updated

and the result is now:

   Owned by        Model   Year    Car age   Last updated
   Gudernova       Mini    1968    44        Mon Feb 27 12:32:04 AST 2012
   Senger          Skoda   2002    10        Mon Feb 27 12:32:04 AST 2012
   Someone else    Praga   1936    76        Mon Feb 27 12:32:04 AST 2012

The last possibility is to call a Perl subroutine - using the reserved
word B<PERL> in the configuration file. Let's have an input
spreadsheet (C<flights.tsv>) with data about flights:

   Date         Flight    Airport From      Airport To
   2009-01-18   AY838     London LHR        Helsinki Vantaa
   2009-01-22   AY839     Helsinki Vantaa   London LHR
   2009-03-15   NW2       Manila            Tokyo Narita
   2009-03-21   NW1       Tokyo Narita      Manila
   2011-05-06   SV326     Sharm El Sheik    Jeddah
   2011-07-31   RJ700     Amman             Jeddah
   2011-09-21   ME369     Jeddah            Beirut
   2011-09-24   ME368     Beirut            Jeddah
   2011-12-02   EZY3064   Prague            London Stansted
   2011-12-09   EZY3067   London Stansted   Prague
   2012-01-26   MS663     Cairo             Jeddah

We want to add columns with the international airport codes for both
I<Airport From> and I<Airport To>. The new columns will be named
I<Code From> and I<Code To>. The Perl subroutine will use a web
service to find the code. The subroutine will use a closure that will
remember already fetched codes so the web service does not need to be
called several times for the same airport name.

The configuration file C<flights.cfg> is:

   MATCH   FLY=Date

   FLY     Date
   FLY     Flight
   FLY     Airport From
   PERL    Airport->find_code      Code From
   FLY     Airport To
   PERL    Airport->find_code      Code To

The name of the subroutine is attached to the module where it comes
from by either B<::> or B<-E<gt>> notation.

The invocation is:

   combinesheets -config flights.cfg -inputs FLY=flights.tsv

The full code for the module C<Airport>, the file C<Airport.pm> is
here:

   package Airport;
   use warnings;
   use strict;

   use LWP::Simple;
   use JSON;

   # preparing a closure in order not to fetch the same airport code again and again
   my $already_found = make_already_found();
   sub make_already_found {
      my $already_found = {};
      return sub {
         my ($airport_name, $airport_code) = @_;
         if (exists $already_found->{$airport_name}) {
            if ($airport_code) {
                $already_found->{$airport_name} = $airport_code;
            }
            return $already_found->{$airport_name};
         } else {
            $already_found->{$airport_name} = ($airport_code ? $airport_code : 1);
            return 0;
         }
      }
   }

   sub find_code {
      my ($class, $column, $header_line, $data_line) = @_;

      my $column_with_airport_name = $column->{ocol};
      $column_with_airport_name =~ s{Code}{Airport};

      my $airport_name;
      for (my $i = 0; $i < @$header_line; $i++) {
         if ($header_line->[$i] eq $column_with_airport_name) {
            $airport_name = $data_line->[$i];
            last;
         }
      }
      return '' unless $airport_name;

      # now we have an airport name...
      my $airport_code = $already_found->($airport_name);
      return $airport_code if $airport_code;

      #... go and find its airport code
      $airport_code = '';
      my $escaped_airport_name = $airport_name;
      $escaped_airport_name =~ tr{ }{+};
      my $url = "http://airportcode.riobard.com/search?q=$escaped_airport_name&fmt=json";
      my $content = get ($url);
      warn "Cannot get a response for '$url'\n"
         unless defined $content;
      my $json = JSON->new->allow_nonref;
      my $data = $json->decode ($content);
      foreach my $code (@$data) {
         $airport_code .= $code->{code} . ",";
      }
      chop ($airport_code) if $airport_code;  # removing the trailing comma

      $already_found->($airport_name, $airport_code);
      return $airport_code;
   }
   1;

When run it creates the following output. Note that some airports have
more than one code because the name was ambiguous. Well, this is just
an example, isn't it?

   Date         Flight    Airport From      Code From   Airport To       Code To
   2009-01-18   AY838     London LHR        LHR         Helsinki Vantaa  HEL
   2009-01-22   AY839     Helsinki Vantaa   HEL         London LHR       LHR
   2009-03-15   NW2       Manila            MXA,MNL     Tokyo Narita     NRT
   2009-03-21   NW1       Tokyo Narita      NRT         Manila           MXA,MNL
   2011-05-06   SV326     Sharm El Sheik    SSH         Jeddah           JED
   2011-07-31   RJ700     Amman             ADJ,AMM     Jeddah           JED
   2011-09-21   ME369     Jeddah            JED         Beirut           BEY
   2011-09-24   ME368     Beirut            BEY         Jeddah           JED
   2011-12-02   EZY3064   Prague            PRG         London Stansted  STN
   2011-12-09   EZY3067   London Stansted   STN         Prague           PRG
   2012-01-26   MS663     Cairo             CAI,CIR     Jeddah           JED

=item B<-inputs <input_ID>=<filename> [<input_ID>=<filename>...]>

Each C<-inputs> can have one or more file names, and there can be one
or more C<-inputs> arguments. It defines what are the input
spreadsheets and how they are identified in the configuration file
(see the C<-config> argument). For example, the inputs for our example
above can be specified in any of these ways:

   -inputs PERSON=persons.tsv -inputs CAR=cars.tsv
   -inputs PERSON=persons.tsv CAR=cars.tsv
   -inputs PERSON=persons.tsv,CAR=cars.tsv

The first file name is considered to be the C<primary> input (see the
description above): the resulting spreadsheet will have the same
number of lines as the primary input.

The file names ending with the C<.csv> are considered to be in the
COMMA-separated formats, all others are considered to be
TAB-separated.

This is a mandatory parameter.

=item B<-outfile <output-file>>

An optional parameter specifying a filename of the combined result. By
default, it is created on STDOUT. It is always in the TAB-separated
format.

=item B<-check>

This option causes that the configuration file and the input files
(only their header lines will be read) will be checked for errors but
no resulting spreadsheet will be created.

=item B<-ignorecases>

Not yet implemented.

=item B<General options>

=over 8

=item B<-h>

Print a brief usage message and exits.

=item B<-help>

Print a brief usage message with options and exit.

=item B<-man>

Print a full usage message and exit.

=item B<-version>

Print the version and exit.

=back

=back

=head1 ENVIRONMENT VARIABLES

=head3 COMBINE_SHEETS_EXT_PATH

It contains a path that is used when looking for external programs
(when the reserved words PROG or PROGS are used). For example, the
C<examples> directory in the source distribution of this package has an
external program C<age.sh>. The full invocation can be done by:

   COMBINE_SHEETS_EXT_PATH=examples bin/combinesheets -cfg examples/cars.cfg --inputs CAR=examples/cars.csv

=head1 DEPENDENCIES

In order to run this tool you need Perl and the following Perl modules
to be installed:

   App::Cmd::Simple
   Text::CSV::Simple
   Text::CSV_XS
   File::BOM
   Getopt::Long::Descriptive
   Pod::Usage
   Algorithm::Loops

Optionally (if your configuration file uses the reserved word PROG or
PROGS for calculated columns):

   IO::CaptureOutput

=head1 KNOWN BUGS, MISSING FEATURES

=over

=item *

Columns are identified by their header names. There is no way
to identify them simply by their order (column number).

=item *

The input spreadsheet are read first into memory. Which may be
a problem with really huge spreadsheets.

=item *

The inputs can be COMMA-separated or TAB-separated. It would
be perhaps nice to allow also the Excel spreadsheets.

=item *

Comparing header names and rows is case-sensitive only. There
is a plan to implement the option C<-ignorecases>,

=back

Some of these missing features may be implemented later.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::combinesheets

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-combinesheets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-combinesheets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-combinesheets>

=item * Search CPAN

L<http://search.cpan.org/dist/App-combinesheets/>

=back

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

