package App::CSVUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Hash::Subset qw(hash_subset);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-14'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '0.054'; # VERSION

our %SPEC;

our $sch_req_str_or_code = ['any*', of=>['str*', 'code*']];

sub _read_file {
    my $filename = shift;

    my ($fh, $err);
    if ($filename eq '-') {
        $fh = *STDIN;
    } elsif ($filename =~ /\A\w+:/) {
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        my $resp = $ua->get($filename);
        unless ($resp->is_success) {
            $err = [$resp->code, "Can't get URL $filename: ".$resp->message];
            goto RETURN;
        }
        require IO::Scalar;
        my $content = $resp->content;
        $fh = IO::Scalar->new(\$content);
    } else {
        open $fh, "<", $filename or do {
            $err = [500, "Can't open input filename '$filename': $!"];
            goto RETURN;
        };
    }
    binmode $fh, ":encoding(utf8)";

  RETURN:
    ($fh, $err);
}

sub _return_or_write_file {
    my ($res, $filename, $overwrite) = @_;
    return $res if !defined($filename);
    if ($filename =~ /\A\w+:/) {
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        my $resp = $ua->put($filename, Content=>$res->[2]);
        unless ($resp->is_success) {
            return [$resp->code, "Can't put URL $filename: ".$resp->message];
        }
        return [200, "OK"];
    } else {
        my $fh;
        if ($filename eq '-') {
            $fh = \*STDIN;
        } else {
            if (-f $filename) {
                if ($overwrite) {
                    log_info "Overwriting output file $filename";
                } else {
                    return [412, "Refusing to ovewrite existing output file '$filename', please select another path or specify --overwrite"];
                }
            }
            open my $fh, ">", $filename or do {
                return [500, "Can't open output file '$filename': $!"];
            };
            binmode $fh, ":encoding(utf8)";
            print $fh $res->[2];
            close $fh or warn "Can't write to '$filename': $!";
            return [$res->[0], $res->[1]];
        }
    }
}

sub _compile {
    my $str = shift;
    return $str if ref $str eq 'CODE';
    defined($str) && length($str) or die "Please specify code (-e)\n";
    $str = "package main; no strict; no warnings; sub { $str }";
    log_trace "Compiling Perl code: $str";
    my $code = eval $str; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die "Can't compile code (-e) '$str': $@\n" if $@;
    $code;
}

sub _get_field_idx {
    my ($field, $field_idxs) = @_;
    defined($field) && length($field) or die "Please specify at least a field\n";
    my $idx = $field_idxs->{$field};
    die "Unknown field '$field' (known fields include: ".
        join(", ", map { "'$_'" } sort {$field_idxs->{$a} <=> $field_idxs->{$b}}
             keys %$field_idxs).")\n" unless defined $idx;
    $idx;
}

sub _get_csv_row {
    my ($csv, $row, $i, $outputs_header) = @_;
    #use DD; print "  "; dd $row;
    return "" if $i == 1 && !$outputs_header;
    my $status = $csv->combine(@$row)
        or die "Error in line $i: ".$csv->error_input."\n";
    $csv->string . "\n";
}

sub _instantiate_parser_default {
    require Text::CSV_XS;

    Text::CSV_XS->new({binary=>1});
}

sub _instantiate_parser {
    require Text::CSV_XS;

    my ($args, $prefix) = @_;
    $prefix //= '';

    my %tcsv_opts = (binary=>1);
    if (defined $args->{"${prefix}sep_char"} ||
            defined $args->{"${prefix}quote_char"} ||
            defined $args->{"${prefix}escape_char"}) {
        $tcsv_opts{"sep_char"}    = $args->{"${prefix}sep_char"}    if defined $args->{"${prefix}sep_char"};
        $tcsv_opts{"quote_char"}  = $args->{"${prefix}quote_char"}  if defined $args->{"${prefix}quote_char"};
        $tcsv_opts{"escape_char"} = $args->{"${prefix}escape_char"} if defined $args->{"${prefix}escape_char"};
    } elsif ($args->{tsv}) {
        $tcsv_opts{"sep_char"}    = "\t";
        $tcsv_opts{"quote_char"}  = undef;
        $tcsv_opts{"escape_char"} = undef;
    }

    Text::CSV_XS->new(\%tcsv_opts);
}

sub _instantiate_emitter {
    my $args = shift;
    _instantiate_parser($args, 'output_');
}

sub _complete_field_or_field_list {
    # return list of known fields of a CSV

    my $which = shift;

    my %args = @_;
    my $word = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r = $args{r};

    # we are not called from cmdline, bail
    return undef unless $cmdline; ## no critic: Subroutines::ProhibitExplicitReturnUndef

    # let's parse argv first
    my $args;
    {
        # this is not activated yet
        $r->{read_config} = 1;

        my $res = $cmdline->parse_argv($r);
        #return undef unless $res->[0] == 200;

        $cmdline->_read_config($r) unless $r->{config};
        $args = $res->[2];
    }

    # user hasn't specified -f, bail
    return {message=>"Please specify -f first"} unless defined $args && $args->{filename};

    # user wants to read CSV from stdin, bail
    return {message=>"Can't get field list when input is stdin"} if $args->{filename} eq '-';

    # user wants to read from url, bail
    return {message=>"Can't get field list when input is URL"} if $args->{filename} =~ /\A\w:/;

    # can the file be opened?
    my $csv_parser = _instantiate_parser(\%args);
    open my($fh), "<encoding(utf8)", $args->{filename} or do {
        #warn "csvutils: Cannot open file '$args->{filename}': $!\n";
        return [];
    };

    # can the header row be read?
    my $row = $csv_parser->getline($fh) or return [];

    if (defined $args->{header} && !$args->{header}) {
        $row = [map {"field$_"} 1 .. @$row];
    }

    if ($which =~ /sort/) {
        $row = [map {($_,"-$_","+$_","~$_")} @$row];
    }

    require Complete::Util;
    if ($which =~ /field_list/) {
        return Complete::Util::complete_comma_sep(
            word => $word,
            elems => $row,
            uniq => 1,
        );
    } else {
        return Complete::Util::complete_array_elem(
            word => $word,
            array => $row,
        );
    }
}

sub _complete_field {
    _complete_field_or_field_list('field', @_);
}

sub _complete_field_list {
    _complete_field_or_field_list('field_list', @_);
}

sub _complete_sort_field_list {
    _complete_field_or_field_list('sort_field_list', @_);
}

sub _complete_sort_field {
    _complete_field_or_field_list('sort_field', @_);
}

sub _array2hash {
    my ($row, $fields) = @_;
    my $rowhash = {};
    for my $i (0..$#{$fields}) {
        $rowhash->{ $fields->[$i] } = $row->[$i];
    }
    $rowhash;
}

sub _select_fields {
    my ($fields, $field_idxs, $args) = @_;

    my @selected_fields;

    if ($args->{pick_num}) {
        require List::Util;
        @selected_fields = List::Util::shuffle(@$fields);
        if ($args->{pick_num} < @selected_fields) {
            splice @selected_fields, 0, (@selected_fields-$args->{pick_num});
        }
    }

    if (defined $args->{include_field_pat}) {
        for my $field (@$fields) {
            if ($field =~ $args->{include_field_pat}) {
                push @selected_fields, $field;
            }
        }
    }
    if (defined $args->{exclude_field_pat}) {
        @selected_fields = grep { $_ !~ $args->{exclude_field_pat} }
            @selected_fields;
    }
    if (defined $args->{include_fields}) {
      FIELD:
        for my $field (@{ $args->{include_fields} }) {
            unless (defined $field_idxs->{$field}) {
                return [400, "Unknown field '$field'"] unless $args->{ignore_unknown_fields};
                next FIELD;
            }
            next if grep { $field eq $_ } @selected_fields;
            push @selected_fields, $field;
        }
    }
    if (defined $args->{exclude_fields}) {
      FIELD:
        for my $field (@{ $args->{exclude_fields} }) {
            unless (defined $field_idxs->{$field}) {
                return [400, "Unknown field '$field'"] unless $args->{ignore_unknown_fields};
                next FIELD;
            }
            @selected_fields = grep { $field ne $_ } @selected_fields;
        }
    }

    if ($args->{show_selected_fields}) {
        return [200, "OK", \@selected_fields];
    }

    #my %selected_field_idxs;
    #$selected_field_idxs{$_} = $fields_idx->{$_} for @selected_fields;

    my @selected_field_idxs_array;
    push @selected_field_idxs_array, $field_idxs->{$_} for @selected_fields;

    [100, "Continue", [\@selected_fields, \@selected_field_idxs_array]];
}

our %argspecs_common = (
    header => {
        summary => 'Whether input CSV has a header row',
        schema => 'bool*',
        default => 1,
        description => <<'_',

By default (`--header`), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (`--no-header`), the first row of the CSV is
assumed to contain the first data row. Fields will be named `field1`, `field2`,
and so on.

_
        cmdline_aliases => {input_header=>{}},
        tags => ['category:input'],
    },
    tsv => {
        summary => "Inform that input file is in TSV (tab-separated) format instead of CSV",
        schema => 'bool*',
        description => <<'_',

Overriden by `--sep-char`, `--quote-char`, `--escape-char` options. If one of
those options is specified, then `--tsv` will be ignored.

_
        cmdline_aliases => {input_tsv=>{}},
        tags => ['category:input'],
    },
    sep_char => {
        summary => 'Specify field separator character in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `,` (comma). Overrides `--tsv` option.

_
        tags => ['category:input'],
    },
    quote_char => {
        summary => 'Specify field quote character in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `"` (double quote). Overrides `--tsv` option.

_
        tags => ['category:input'],
    },
    escape_char => {
        summary => 'Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `\\` (backslash). Overrides `--tsv` option.

_
        tags => ['category:input'],
    },
);

our %argspecs_csv_output = (
    output_header => {
        summary => 'Whether output CSV should have a header row',
        schema => 'bool*',
        description => <<'_',

By default, a header row will be output *if* input CSV has header row. Under
`--output-header`, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
`--no-output-header`, header row will *not* be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

_
        tags => ['category:output'],
    },
    output_tsv => {
        summary => "Inform that output file is TSV (tab-separated) format instead of CSV",
        schema => 'bool*',
        description => <<'_',

This is like `--tsv` option but for output instead of input.

Overriden by `--output-sep-char`, `--output-quote-char`, `--output-escape-char`
options. If one of those options is specified, then `--output-tsv` will be
ignored.

_
        tags => ['category:output'],
    },
    output_sep_char => {
        summary => 'Specify field separator character in output CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

This is like `--sep-char` option but for output instead of input.

Defaults to `,` (comma). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
    output_quote_char => {
        summary => 'Specify field quote character in output CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

This is like `--quote-char` option but for output instead of input.

Defaults to `"` (double quote). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
    output_escape_char => {
        summary => 'Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

This is like `--escape-char` option but for output instead of input.

Defaults to `\\` (backslash). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
);

our %argspec_filename_1 = (
    filename => {
        summary => 'Input CSV file or URL',
        description => <<'_',

Use `-` to read from stdin, use `clipboard:` to read from clipboard.

_
        schema => 'filename*',
        req => 1,
        pos => 1,
        tags => ['category:input'],
    },
);

our %argspec_filename_0 = (
    filename => {
        summary => 'Input CSV file or URL',
        description => <<'_',

Use `-` to read from stdin, use `clipboard:` to read from clipboard.

_
        schema => 'filename*',
        req => 1,
        pos => 0,
        tags => ['category:input'],
    },
);

our %argspec_filenames_0plus = (
    filenames => {
        'x.name.is_plural' => 1,
        summary => 'Input CSV files or URLs',
        description => <<'_',

Use `-` to read from stdin, use `clipboard:` to read from clipboard.

_
        schema => ['array*', of=>'filename*'],
        req => 1,
        pos => 0,
        slurpy => 1,
        tags => ['category:input'],
    },
);

our %argspecopt_overwrite = (
    overwrite => {
        summary => 'Whether to override existing output file',
        schema => 'bool*',
        cmdline_aliases=>{O=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_output_filename = (
    output_filename => {
        summary => 'Output filename or URL',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option), use
`clipboard:` to write to clipboard.

_
        schema => 'filename*',
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_output_filename_1 = (
    output_filename => {
        summary => 'Output filename or URL',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option), use
`clipboard:` to write to clipboard.

_
        schema => 'filename*',
        pos => 1,
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_output_filename_2 = (
    output_filename => {
        summary => 'Output filename or URL',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option), use
`clipboard:` to write to clipboard.

_
        schema => 'filename*',
        pos => 2,
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_field = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { F=>{} },
    },
);

our %argspec_field_1 = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
        completion => \&_complete_field,
    },
);

# without completion, for adding new field
our %argspec_field_1_nocomp = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
    },
);

# without completion, for adding new fields
our %argspec_fields_1plus_nocomp = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        summary => 'Field names',
        'summary.alt.plurality.singular' => 'Field name',
        schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
        slurpy => 1,
    },
);

# let's just use field selection args for consistency
#our %argspecs1_fields = (
#    fields => {
#        'x.name.is_plural' => 1,
#        'x.name.singular' => 'field',
#        summary => 'Field names',
#        schema => ['array*', of=>'str*'],
#        cmdline_aliases => {
#            f => {},
#        },
#        pos => 1,
#        slurpy => 1,
#        element_completion => \&_complete_field,
#        tags => ['category:field-selection'],
#    },
#);

our %argspecsopt_field_selection = (
    include_fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_field',
        summary => 'Field names to include, takes precedence over --exclude-field-pat',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {
            f => {},
            field => {}, # backward compatibility
        },
        element_completion => \&_complete_field,
        tags => ['category:field-selection'],
    },
    include_field_pat => {
        summary => 'Field regex pattern to select, overidden by --exclude-field-pat',
        schema => 're*',
        cmdline_aliases => {
            field_pat => {}, # backward compatibility
            include_all_fields => { summary => 'Shortcut for --field-pat=.*, effectively selecting all fields', is_flag=>1, code => sub { $_[0]{include_field_pat} = '.*' } },
        },
        tags => ['category:field-selection'],
    },
    exclude_fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'exclude_field',
        summary => 'Field names to exclude, takes precedence over --fields',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => {
            F => {},
        },
        element_completion => \&_complete_field,
        tags => ['category:field-selection'],
    },
    exclude_field_pat => {
        summary => 'Field regex pattern to exclude, takes precedence over --field-pat',
        schema => 're*',
        cmdline_aliases => {
            exclude_all_fields => { summary => 'Shortcut for --field-pat=.*, effectively selecting all fields', is_flag=>1, code => sub { $_[0]{exclude_field_pat} = '.*' } },
        },
        tags => ['category:field-selection'],
    },
    ignore_unknown_fields => {
        summary => 'When unknown fields are specified in --include-field (--field) or --exclude-field options, ignore them instead of throwing an error',
        schema => 'bool*',
    },
    show_selected_fields => {
        summary => 'Show selected fields and then immediately exit',
        schema => 'true*',
    },
);

our %argspecsopt_vcf = (
    name_vcf_field => {
        summary => 'Select field to use as VCF N (name) field',
        schema => 'str*',
    },
    cell_vcf_field => {
        summary => 'Select field to use as VCF CELL field',
        schema => 'str*',
    },
    email_vcf_field => {
        summary => 'Select field to use as VCF EMAIL field',
        schema => 'str*',
    },
);

our %argspec_eval = (
    eval => {
        summary => 'Perl code',
        schema => $sch_req_str_or_code,
        cmdline_aliases => { e=>{} },
        req => 1,
    },
);

our %argspecopt_eval = (
    eval => {
        summary => 'Perl code',
        schema => $sch_req_str_or_code,
        cmdline_aliases => { e=>{} },
    },
);

our %argspec_eval_1 = (
    eval => {
        summary => 'Perl code',
        schema => $sch_req_str_or_code,
        cmdline_aliases => { e=>{} },
        req => 1,
        pos => 1,
    },
);

our %argspec_eval_2 = (
    eval => {
        summary => 'Perl code',
        schema => $sch_req_str_or_code,
        cmdline_aliases => { e=>{} },
        req => 1,
        pos => 2,
    },
);

our %argspecopt_eval_2 = (
    eval => {
        summary => 'Perl code',
        schema => $sch_req_str_or_code,
        cmdline_aliases => { e=>{} },
        pos => 2,
    },
);

our %argspecopt_by_code = (
    by_code => {
        summary => 'Sort using Perl code',
        schema => $sch_req_str_or_code,
        description => <<'_',

`$a` and `$b` (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if `--hash` (`-H`) is specified, hashrefs; or
if `--key` is specified, whatever the code in `--key` returns.

_
    },
);

our %argspecsopt_sortsub = (
    by_sortsub => {
        schema => 'str*',
        description => <<'_',

When sorting rows, usually combined with `--key` because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

_
        summary => 'Sort using a Sort::Sub routine',
        'x.completion' => ['sortsub_spec'],
    },
    sortsub_args => {
        summary => 'Arguments to pass to Sort::Sub routine',
        schema => ['hash*', of=>'str*'],
    },
);

our %argspecopt_key = (
    key => {
        summary => 'Generate sort keys with this Perl code',
        description => <<'_',

If specified, then will compute sort keys using Perl code and sort using the
keys. Relevant when sorting using `--by-code` or `--by-sortsub`. If specified,
then instead of row when sorting rows, the code (or Sort::Sub routine) will
receive these sort keys to sort against.

Tthe code will receive the row (arrayref) as the argument.

_
        schema => $sch_req_str_or_code,
        cmdline_aliases => {k=>{}},
    },
);

# argspecs for csvutil
our %argspecsopt_sort = (
    sort_reverse => {
        schema => ['bool', is=>1],
    },
    sort_ci => {
        schema => ['bool', is=>1],
    },
    sort_by_sortsub => {
        schema => 'str*',
    },
    sort_sortsub_args => {
        schema => ['hash*'],
    },
    sort_by_code => {
        schema => $sch_req_str_or_code,
    },
    sort_key => {
        schema => $sch_req_str_or_code,
    },
    # for csv-sort-fields
    sort_examples => {
        schema => ['array*', of=>'str*'],
    },
);

# argspecs for csv-sort-rows
our %argspecs_sort_rows_short = (
    reverse => {
        schema => ['bool', is=>1],
        cmdline_aliases => {r=>{}},
    },
    ci => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    by_fields => {
        summary => 'Sort by a list of field specifications',
        'summary.alt.plurality.singular' => 'Add a sort field specification',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'by_field',
        description => <<'_',

Each field specification is a field name with an optional prefix. `FIELD`
(without prefix) means sort asciibetically ascending (smallest to largest),
`~FIELD` means sort asciibetically descending (largest to smallest), `+FIELD`
means sort numerically ascending, `-FIELD` means sort numerically descending.

_
        schema => ['array*', of=>'str*'],
        element_completion => \&_complete_sort_field,
    },
    %argspecopt_key,
    %argspecsopt_sortsub,
    %argspecopt_by_code,
);

# argspecs for csv-sort-fields
our %argspecs_sort_fields_short = (
    reverse => {
        schema => ['bool', is=>1],
        cmdline_aliases => {r=>{}},
    },
    ci => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    by_examples => {
        summary => 'A list of field names to sort by example',
        'summary.alt.plurality.singular' => 'Add a field to sort by example',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'by_example',
        schema => ['array*', of=>'str*'],
        element_completion => \&_complete_field,
    },
    %argspecopt_by_code,
    %argspecsopt_sortsub,
);

our %argspec_with_data_rows = (
    with_data_rows => {
        summary => 'Whether to also output data rows',
        schema => 'bool',
    },
);

our %argspec_hash = (
    hash => {
        summary => 'Provide row in $_ as hashref instead of arrayref',
        schema => ['bool*', is=>1],
        cmdline_aliases => {H=>{}},
    },
);

$SPEC{csvutil} = {
    v => 1.1,
    summary => 'Perform action on a CSV file',
    'x.no_index' => 1,
    args => {
        %argspecs_common,
        action => {
            schema => ['str*', in=>[
                'add-fields',
                'list-field-names',
                'info',
                'delete-fields',
                'munge-field',
                'munge-row',
                #'replace-newline', # not implemented in csvutil
                'sort-rows',
                'sort-fields',
                'sum',
                'avg',
                'select-rows',
                'split',
                'grep',
                'map',
                'each-row',
                'convert-to-hash',
                'convert-to-td',
                #'concat', # not implemented in csvutil
                'select-fields',
                'dump',
                'csv',
                #'setop', # not implemented in csvutil
                #'lookup-fields', # not implemented in csvutil
                'transpose',
                'freqtable',
                'get-cells',
                'fill-template',
                'convert-to-vcf',
                'pick-rows',
            ]],
            req => 1,
            pos => 0,
            cmdline_aliases => {a=>{}},
        },
        %argspec_filename_1,
        %argspecopt_output_filename_2,
        %argspecopt_overwrite,
        %argspecopt_eval,
        %argspecopt_field,
        %argspecsopt_field_selection,
        %argspecsopt_vcf,
        %argspecsopt_sort,
    },
    args_rels => {
    },
};
sub csvutil {
    my %args = @_;
    #use DD; dd \%args;

    my $action = $args{action};
    my $has_header = $args{header} // 1;
    my $outputs_header = $args{output_header} // $has_header;
    my $add_newline = $args{add_newline} // 1;

    my $csv_parser  = _instantiate_parser(\%args);
    my $csv_emitter = _instantiate_emitter(\%args);

    my ($fh, $err) = _read_file($args{filename});
    return $err if $err;

    my $res = "";
    my $i = 0;
    my $header_row_count = 0;
    my $data_row_count = 0;

    my $fields = []; # field names, in order
    my %field_idxs; # key = field name, val = index (0-based)

    my $selected_fields;
    my $selected_field_idxs_array;
    my $selected_field_idxs_array_sorted;
    my $code;
    my $field_idx;
    my $sorted_fields;
    my @summary_row;
    my $selected_row;
    my $row_spec_sub;
    my %freqtable; # key=value, val=frequency
    my @cells;

    # for action=split
    my ($split_fh, $split_filename, $split_lines);

    # for action convert-to-vcf
    my %fields_for;
    $fields_for{N}     = $args{name_vcf_field};
    $fields_for{CELL}  = $args{cell_vcf_field};
    $fields_for{EMAIL} = $args{email_vcf_field};

    my $row0;
    my $code_getline = sub {
        if ($i == 0 && !$has_header) {
            $row0 = $csv_parser->getline($fh);
            return unless $row0;
            return [map { "field$_" } 1..@$row0];
        } elsif ($i == 1 && !$has_header) {
            $data_row_count++ if $row0;
            return $row0;
        }
        my $res = $csv_parser->getline($fh);
        if ($res) {
            $header_row_count++ if $i==0;
            $data_row_count++ if $i;
        }
        $res;
    };

    my $rows = [];

    while (my $row = $code_getline->()) {
        #use DD; dd $row;
        $i++;
        if ($i == 1) {
            # header row

            $fields = $row;
            for my $j (0..$#{$row}) {
                unless (length $row->[$j]) {
                    #return [412, "Empty field name in field #$j"];
                    next;
                }
                if (defined $field_idxs{ $row->[$j] }) {
                    return [412, "Duplicate field name '$row->[$j]'"];
                }
                $field_idxs{$row->[$j]} = $j;
            }

            if ($action eq 'sort-fields') {
                if (my $eg = $args{sort_examples}) {
                    require Sort::ByExample;
                    my $sorter = Sort::ByExample::sbe($eg);
                    $sorted_fields = [$sorter->(@$row)];
                } elsif ($args{sort_by_code} || $args{sort_by_sortsub}) {
                    my $code;
                    if ($args{sort_by_code}) {
                        $code = _compile($args{sort_by_code});
                    } elsif (defined $args{sort_by_sortsub}) {
                        require Sort::Sub;
                        $code = Sort::Sub::get_sorter(
                            $args{sort_by_sortsub}, $args{sort_sortsub_args});
                    }
                    $sorted_fields = [sort { local $main::a=$a; local $main::b=$b; $code->($main::a,$main::b) } @$fields];
                } else {
                    # alphabetical
                    if ($args{sort_ci}) {
                        $sorted_fields = [sort {lc($a) cmp lc($b)} @$row];
                    } else {
                        $sorted_fields = [sort {$a cmp $b} @$row];
                    }
                }
                $sorted_fields = [reverse @$sorted_fields]
                    if $args{sort_reverse};
                $row = $sorted_fields;
            }

            if ($action eq 'sum' || $action eq 'avg') {
                @summary_row = map {0} @$row;
            }

            if ($action eq 'select-rows') {
                my $spec = $args{row_spec};
                my @codestr;
                for my $spec_item (split /\s*,\s*/, $spec) {
                    if ($spec_item =~ /\A\d+\z/) {
                        push @codestr, "(\$i == $spec_item)";
                    } elsif ($spec_item =~ /\A(\d+)\s*-\s*(\d+)\z/) {
                        push @codestr, "(\$i >= $1 && \$i <= $2)";
                    } else {
                        return [400, "Invalid row specification '$spec_item'"];
                    }
                }
                $row_spec_sub = eval 'sub { my $i = shift; '.join(" || ", @codestr).' }'; ## no critic: BuiltinFunctions::ProhibitStringyEval
                return [400, "BUG: Invalid row_spec code: $@"] if $@;
            }

            if ($action eq 'convert-to-vcf') {
                for my $field (@$fields) {
                    if ($field =~ /name/i && !defined($fields_for{N})) {
                        log_info "Will be using field '$field' for VCF field 'N' (name)";
                        $fields_for{N} = $field;
                    }
                    if ($field =~ /(e-?)?mail/i && !defined($fields_for{EMAIL})) {
                        log_info "Will be using field '$field' for VCF field 'EMAIL'";
                        $fields_for{EMAIL} = $field;
                    }
                    if ($field =~ /cell|hp|phone|wa|whatsapp/i && !defined($fields_for{CELL})) {
                        log_info "Will be using field '$field' for VCF field 'CELL' (cellular phone)";
                        $fields_for{CELL} = $field;
                    }
                }
                if (!defined($fields_for{N})) {
                    return [412, "Can't convert to VCF because we cannot determine which field to use as the VCF N (name) field"];
                }
                if (!defined($fields_for{EMAIL})) {
                    log_warn "We cannot determine which field to use as the VCF EMAIL field";
                }
                if (!defined($fields_for{CELL})) {
                    log_warn "We cannot determine which field to use as the VCF CELL (cellular phone) field";
                }
            }
        } # if i==1 (header row)

        if ($action eq 'list-field-names') {
            return [200, "OK",
                    [map { {name=>$_, index=>$field_idxs{$_}+1} }
                         sort keys %field_idxs],
                    {'table.fields'=>['name','index']}];
        } elsif ($action eq 'info') {
        } elsif ($action eq 'munge-field') {
            unless ($i == 1) {
                unless ($code) {
                    $code = _compile($args{eval});
                    $field_idx = _get_field_idx($args{field}, \%field_idxs);
                }
                if (defined $row->[$field_idx]) {
                    local $_ = $row->[$field_idx];
                    local $main::row = $row;
                    local $main::rownum = $i;
                    local $main::csv = $csv_parser;
                    local $main::field_idxs = \%field_idxs;
                    eval { $code->($_) };
                    die "Error while munging row ".
                        "#$i field '$args{field}' value '$_': $@\n" if $@;
                    $row->[$field_idx] = $_;
                }
            }
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'munge-row') {
            unless ($i == 1) {
                unless ($code) {
                    $code = _compile($args{eval});
                }
                local $_ = $args{hash} ? _array2hash($row, $fields) : $row;
                local $main::row = $row;
                local $main::rownum = $i;
                local $main::csv = $csv_parser;
                local $main::field_idxs = \%field_idxs;
                eval { $code->($_) };
                die "Error while munging row ".
                    "#$i field '$args{field}' value '$_': $@\n" if $@;
                if ($args{hash}) {
                    for my $field (keys %$_) {
                        next unless exists $field_idxs{$field};
                        $row->[$field_idxs{$field}] = $_->{$field};
                    }
                }
            }
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'add-fields') {
            if ($i == 1) {
                if (defined $args{_at}) {
                    $field_idx = $args{_at}-1;
                } elsif (defined $args{before}) {
                    for (0..$#{$row}) {
                        if ($row->[$_] eq $args{before}) {
                            $field_idx = $_;
                            last;
                        }
                    }
                    return [400, "Field '$args{before}' (to add new fields before) not found"]
                        unless defined $field_idx;
                } elsif (defined $args{after}) {
                    for (0..$#{$row}) {
                        if ($row->[$_] eq $args{after}) {
                            $field_idx = $_+1;
                            last;
                        }
                    }
                    return [400, "Field '$args{after}' (to add new fields after) not found"]
                        unless defined $field_idx;
                } else {
                    $field_idx = @$row;
                }
                splice @$row, $field_idx, 0, @{ $args{fields} };
                for (keys %field_idxs) {
                    if ($field_idxs{$_} >= $field_idx) {
                        $field_idxs{$_}++;
                    }
                }
                $fields = $row;
            } else {
                unless ($code) {
                    $code = _compile($args{eval} // 'return');
                    if (!defined($args{fields}) || !@{ $args{fields} }) {
                        return [400, "Please specify one or more fields (-F)"];
                    }
                    for (@{ $args{fields} }) {
                        unless (length $_) {
                            return [400, "New field name cannot be empty"];
                        }
                        if (defined $field_idxs{$_}) {
                            return [412, "Field '$_' already exists"];
                        }
                    }
                }
                {
                    local $_ = $args{hash} ? _array2hash($row, $fields) : $row;
                    local $main::row = $row;
                    local $main::rownum = $i;
                    local $main::csv = $csv_parser;
                    local $main::field_idxs = \%field_idxs;
                    my @vals;
                    eval { @vals = $code->() };
                    die "Error while adding field(s) '".join(",", @{$args{fields}})."' for row #$i: $@\n"
                        if $@;
                    if (ref $vals[0] eq 'ARRAY') { @vals = @{ $vals[0] } }
                    splice @$row, $field_idx, 0,
                        (map { $_ // '' } @vals[0 .. $#{$args{fields}} ]);
                }
            }
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'delete-fields') {
            unless ($selected_fields) {
                my $res = _select_fields($fields, \%field_idxs, \%args);
                return $res unless $res->[0] == 100;
                $selected_fields = $res->[2][0];
                $selected_field_idxs_array = $res->[2][1];
                return [412, "At least one field must remain"] if @$selected_fields == @$fields;
                $selected_field_idxs_array_sorted = [sort { $b <=> $a } @$selected_field_idxs_array];
            }
            for (@$selected_field_idxs_array_sorted) {
                splice @$row, $_, 1;
            }
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'select-fields') {
            unless ($selected_fields) {
                my $res = _select_fields($fields, \%field_idxs, \%args);
                return $res unless $res->[0] == 100;
                $selected_fields = $res->[2][0];
                return [412, "At least one field must be selected"] unless @$selected_fields;
                $selected_field_idxs_array = $res->[2][1];
            }
            $row = [@{$row}[@$selected_field_idxs_array]];
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'sort-fields') {
            unless ($i == 1) {
                my @new_row;
                for (@$sorted_fields) {
                    push @new_row, $row->[$field_idxs{$_}];
                }
                $row = \@new_row;
            }
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'sum') {
            if ($i == 1) {
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
            } else {
                require Scalar::Util;
                for (0..$#{$row}) {
                    next unless Scalar::Util::looks_like_number($row->[$_]);
                    $summary_row[$_] += $row->[$_];
                }
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header)
                    if $args{_with_data_rows};
            }
        } elsif ($action eq 'avg') {
            if ($i == 1) {
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
            } else {
                require Scalar::Util;
                for (0..$#{$row}) {
                    next unless Scalar::Util::looks_like_number($row->[$_]);
                    $summary_row[$_] += $row->[$_];
                }
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header)
                    if $args{_with_data_rows};
            }
        } elsif ($action eq 'freqtable') {
            if ($i == 1) {
            } else {
                $field_idx = _get_field_idx($args{field}, \%field_idxs);
                $freqtable{ $row->[$field_idx] }++;
            }
        } elsif ($action eq 'select-rows') {
            if ($i == 1 || $row_spec_sub->($i)) {
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
            }
        } elsif ($action eq 'split') {
            next if $i == 1;
            unless (defined $split_fh) {
                $split_filename = "xaa";
                $split_lines = 0;
                open $split_fh, ">", $split_filename
                    or die "Can't open '$split_filename': $!\n";
                binmode $split_fh, ":encoding(utf8)";
            }
            if ($split_lines >= $args{lines}) {
                $split_filename++;
                $split_lines = 0;
                open $split_fh, ">", $split_filename
                    or die "Can't open '$split_filename': $!\n";
            }
            if ($split_lines == 0 && $has_header) {
                $csv_emitter->print($split_fh, $fields);
                print $split_fh "\n";
            }
            $csv_emitter->print($split_fh, $row);
            print $split_fh "\n";
            $split_lines++;
        } elsif ($action eq 'grep') {
            unless ($code) {
                $code = _compile($args{eval});
            }
            if ($i == 1 || do {
                local $_ = $args{hash} ? _array2hash($row, $fields) : $row;
                local $main::row = $row;
                local $main::rownum = $i;
                local $main::csv = $csv_parser;
                local $main::field_idxs = \%field_idxs;
                $code->($row);
            }) {
                $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
            }
        } elsif ($action eq 'map' || $action eq 'each-row') {
            unless ($code) {
                $code = _compile($args{eval});
            }
            if ($i > 1) {
                my $rowres = do {
                    local $_ = $args{hash} ? _array2hash($row, $fields) : $row;
                    local $main::row = $row;
                    local $main::rownum = $i;
                    local $main::csv = $csv_parser;
                    local $main::field_idxs = \%field_idxs;
                    $code->($row);
                } // '';
                if ($action eq 'map') {
                    unless (!$add_newline || $rowres =~ /\R\z/) {
                        $rowres .= "\n";
                    }
                    $res .= $rowres;
                }
            }
        } elsif ($action eq 'sort-rows') {
            push @$rows, $row unless $i == 1;
        } elsif ($action eq 'pick-rows') {
            if ($i > 1) {
                if ($args{pick_num} == 1) {
                    # algorithm from Learning Perl
                    $rows->[0] = $row if rand($i-1) < 1;
                } else {
                    # algorithm from Learning Perl, modified
                    if (@$rows < $args{pick_num}) {
                        # we haven't reached $pick_num, put row to result in a
                        # random position
                        splice @$rows, rand(@$rows+1), 0, $row;
                    } else {
                        # we have reached $pick_num, just replace an item
                        # randomly, using algorithm from Learning Perl, slightly
                        # modified
                        rand($i-1) < @$rows and splice @$rows, rand(@$rows), 1, $row;
                    }
                }
            }
        } elsif ($action eq 'transpose') {
            push @$rows, $row;
        } elsif ($action eq 'convert-to-hash') {
            if ($i == $args{_row_number}) {
                $selected_row = $row;
            }
        } elsif ($action eq 'convert-to-td') {
            push @$rows, $row unless $i == 1;
        } elsif ($action eq 'dump') {
            if ($args{hash}) {
                push @$rows, _array2hash($row, $fields) unless $i == 1;
            } else {
                push @$rows, $row;
            }
        } elsif ($action eq 'fill-template') {
            push @$rows, _array2hash($row, $fields) unless $i == 1;
        } elsif ($action eq 'csv') {
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        } elsif ($action eq 'get-cells') {
            my $j = -1;
          COORD:
            for my $coord (@{ $args{coordinates} }) {
                $j++;
                my ($coord_col, $coord_row) = $coord =~ /\A(.+),(.+)\z/
                    or return [400, "Invalid coordinate '$coord': must be in col,row form"];
                $coord_row =~ /\A[0-9]+\z/
                    or return [400, "Invalid coordinate '$coord': invalid row syntax '$coord_row', must be a number"];
                next COORD unless $i == $coord_row;
                if ($coord_col =~ /\A[0-9]+\z/) {
                    $coord_col >= 0 && $coord_col < @$fields-1
                        or return [400, "Invalid coordinate '$coord': column number '$coord_col' out of bound, must be between 0-".(@$fields-1)];
                    $cells[$j] = $row->[$coord_col];
                } else {
                    exists $field_idxs{$coord_col}
                        or return [400, "Invalid coordinate '$coord': Unknown column name '$coord_col'"];
                    $cells[$j] = $row->[$field_idxs{$coord_col}];
                }
            }
        } elsif ($action eq 'convert-to-vcf') {
            unless ($i == 1) {
                my $vcard = join(
                    "",
                    "BEGIN:VCARD\n",
                    "VERSION:3.0\n",
                    "N:", $row->[$field_idxs{ $fields_for{N} }], "\n",
                    (defined $fields_for{EMAIL} ? ("EMAIL;type=INTERNET;type=WORK;pref:", $row->[$field_idxs{ $fields_for{EMAIL} }], "\n") : ()),
                    (defined $fields_for{CELL} ? ("TEL;type=CELL:", $row->[$field_idxs{ $fields_for{CELL} }], "\n") : ()),
                    "END:VCARD\n\n",
                );
                push @$rows, $vcard;
            }
        } else {
            return [400, "Unknown action '$action'"];
        }
    } # while getline()

    if ($action eq 'info') {
        return [200, "OK", {
            field_count => scalar @$fields,
            fields      => $fields,

            row_count        => $header_row_count + $data_row_count,
            header_row_count => $header_row_count,
            data_row_count   => $data_row_count,

            #file_size  => $chars, # we use csv's getline() so how?
            file_size   => (-s $fh),
        }];
    }

    if ($action eq 'convert-to-hash') {
        $selected_row //= [];
        my $hash = {};
        for (0..$#{$fields}) {
            $hash->{ $fields->[$_] } = $selected_row->[$_];
        }
        return [200, "OK", $hash];
    }

    if ($action eq 'convert-to-hash') {
        return [200, "OK", join("", @$rows)];
    }

    if ($action eq 'convert-to-td') {
        return [200, "OK", $rows, {'table.fields'=>$fields}];
    }

    if ($action eq 'convert-to-vcf') {
        return [200, "OK", join("", @$rows)];
    }

    if ($action eq 'sum') {
        $res .= _get_csv_row($csv_emitter, \@summary_row,
                             $args{_with_data_rows} ? $i+1 : 2,
                             $outputs_header);
    } elsif ($action eq 'avg') {
        if ($i > 2) {
            for (@summary_row) { $_ /= ($i-1) }
        }
        $res .= _get_csv_row($csv_emitter, \@summary_row,
                             $args{_with_data_rows} ? $i+1 : 2,
                             $outputs_header);
    }

    if ($action eq 'freqtable') {
        my @freqtable;
        for (sort { $freqtable{$b} <=> $freqtable{$a} } keys %freqtable) {
            push @freqtable, [$_, $freqtable{$_}];
        }
        return [200, "OK", \@freqtable, {'table.fields'=>['value','freq']}];
    }

    if ($action eq 'dump') {
        return [200, "OK", $rows];
    }

    if ($action eq 'pick-rows') {
        if ($has_header) {
            $csv_emitter->combine(@$fields);
            $res .= $csv_emitter->string . "\n";
        }
        for my $row (@$rows) {
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        }
    }

    if ($action eq 'sort-rows') {

        # whether we should compute keys
        my @keys;
        if ($args{sort_key}) {
            my $code_gen_key = _compile($args{sort_key});
            if ($action eq 'sort-rows') {
                for my $row (@$rows) {
                    local $_ = $args{hash} ? _array2hash($row, $fields) : $row;
                    push @keys, $code_gen_key->($_);
                }
            } else {
                # sort-fields
                for my $field (@$fields) {
                    local $_ = $field;
                    push @keys, $code_gen_key->($_);
                }
            }
        }

        if ($args{sort_by_code} || $args{sort_by_sortsub}) {

            my $code0;
            if ($args{sort_by_code}) {
                $code0 = _compile($args{sort_by_code});
            } elsif (defined $args{sort_by_sortsub}) {
                require Sort::Sub;
                $code0 = Sort::Sub::get_sorter(
                    $args{sort_by_sortsub}, $args{sort_sortsub_args});
            }

            if (@keys) {
                # compare two sort keys ($a & $b) are indices
                $code = sub {
                    local $main::a = $keys[$a];
                    local $main::b = $keys[$b];
                    $code0->($main::a, $main::b);
                };
            } else {
                if ($args{hash}) {
                    # compare two rowhashes
                    $code = sub {
                        local $main::a = _array2hash($a, $fields);
                        local $main::b = _array2hash($b, $fields);
                        $code0->($main::a, $main::b);
                    };
                } else {
                    # compare two arrayref rows
                    $code = $code0;
                }
            }

            if (@keys) {
                # sort indices according to keys first, then return sorted
                # rows according to indices
                my @sorted_indices = sort { local $main::a=$a; local $main::b=$b; $code->($main::a,$main::b) } 0..$#{$rows};
                $rows = [map {$rows->[$_]} @sorted_indices];
            } else {
                $rows = [sort { local $main::a=$a; local $main::b=$b; $code->($main::a,$main::b) } @$rows];
            }

        } elsif ($args{sort_by_fields}) {

            my @fields;
            my $code_str = "";
            for my $field_spec (@{ $args{sort_by_fields} }) {
                my ($prefix, $field) = $field_spec =~ /\A([+~-]?)(.+)/;
                my $field_idx = $field_idxs{$field};
                return [400, "Unknown field '$field' (known fields include: ".
                            join(", ", map { "'$_'" } sort {$field_idxs{$a} <=> $field_idxs{$b}}
                                 keys %field_idxs).")"] unless defined $field_idx;
                $prefix //= "";
                if ($prefix eq '+') {
                    $code_str .= ($code_str ? " || " : "") .
                        "(\$a->[$field_idx] <=> \$b->[$field_idx])";
                } elsif ($prefix eq '-') {
                    $code_str .= ($code_str ? " || " : "") .
                        "(\$b->[$field_idx] <=> \$a->[$field_idx])";
                } elsif ($prefix eq '') {
                    if ($args{sort_ci}) {
                        $code_str .= ($code_str ? " || " : "") .
                            "(lc(\$a->[$field_idx]) cmp lc(\$b->[$field_idx]))";
                    } else {
                        $code_str .= ($code_str ? " || " : "") .
                            "(\$a->[$field_idx] cmp \$b->[$field_idx])";
                    }
                } elsif ($prefix eq '~') {
                    if ($args{sort_ci}) {
                        $code_str .= ($code_str ? " || " : "") .
                            "(lc(\$b->[$field_idx]) cmp lc(\$a->[$field_idx]))";
                    } else {
                        $code_str .= ($code_str ? " || " : "") .
                            "(\$b->[$field_idx] cmp \$a->[$field_idx])";
                    }
                }
            }
            $code = _compile($code_str);
            $rows = [sort { local $main::a = $a; local $main::b = $b; $code->($main::a, $main::b) } @$rows];

        } else {

            return [400, "Please specify by_fields or by_sortsub or by_code"];

        }

        # output csv
        if ($has_header) {
            $csv_emitter->combine(@$fields);
            $res .= $csv_emitter->string . "\n";
        }
        for my $row (@$rows) {
            $res .= _get_csv_row($csv_emitter, $row, $i, $outputs_header);
        }
    }

    if ($action eq 'transpose') {
        my $transposed_rows = [];
        for my $rownum (0..$#{$rows}) {
            for my $colnum (0..$#{$fields}) {
                $transposed_rows->[$colnum][$rownum] =
                    $rows->[$rownum][$colnum];
            }
        }
        for my $rownum (0..$#{$transposed_rows}) {
            $res .= _get_csv_row($csv_emitter, $transposed_rows->[$rownum],
                                 $rownum+1, $outputs_header);
        }
    }

    if ($action eq 'get-cells') {
        if (@{ $args{coordinates} } == 1) {
            return [200, "OK", $cells[0]];
        } else {
            return [200, "OK", \@cells];
        }
    }

    if ($action eq 'fill-template') {
        require File::Slurper::Dash;

        my $output = '';
        my $template = File::Slurper::Dash::read_text($args{template_filename});
        for my $row (@$rows) {
            my $text = $template;
            $text =~ s/\[\[(.+?)\]\]/defined $row->{$1} ? $row->{$1} : "[[UNDEFINED:$1]]"/eg;
            $output .= (length $output ? "\n---\n" : "") . $text;
        }
        return [200, "OK", $output];
    }

    _return_or_write_file([200, "OK", $res, {"cmdline.skip_format"=>1}], $args{output_filename}, $args{overwrite});
} # csvutil

our $common_desc = <<'_';
*Common notes for the utilities*

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

_

$SPEC{csv_add_fields} = {
    v => 1.1,
    summary => 'Add one or more fields to CSV file',
    description => <<'_' . $common_desc,

The new fields by default will be added at the end, unless you specify one of
`--after` (to put after a certain field), `--before` (to put before a certain
field), or `--at` (to put at specific position, 1 means the first field). The
new fields will be clustered together though, you currently cannot set the
position of each new field. But you can later reorder fields using
<prog:csv-sort-fields>.

If supplied, your Perl code (`-e`) will be called for each row (excluding the
header row) and should return the value for the new fields (either as a list or
as an arrayref). `$_` contains the current row (as arrayref, or if you specify
`-H`, as a hashref). `$main::row` is available and contains the current row
(always as an arrayref). `$main::rownum` contains the row number (2 means the
first data row). `$csv` is the <pm:Text::CSV_XS> object. `$main::field_idxs` is
also available for additional information.

If `-e` is not supplied, the new fields will be getting the default value of
empty string (`''`).

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        %argspec_fields_1plus_nocomp,
        %argspecopt_eval,
        %argspec_hash,
        after => {
            summary => 'Put the new field after specified field',
            schema => 'str*',
            completion => \&_complete_field,
        },
        before => {
            summary => 'Put the new field before specified field',
            schema => 'str*',
            completion => \&_complete_field,
        },
        at => {
            summary => 'Put the new field at specific position '.
                '(1 means first field)',
            schema => ['int*', min=>1],
        },
    },
    args_rels => {
        choose_one => [qw/after before at/],
    },
    examples => [
        {
            summary => 'Add a few new blank fields at the end',
            argv => ['file.csv', 'field4', 'field6', 'field5'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a few new blank fields after a certain field',
            argv => ['file.csv', 'field4', 'field6', 'field5', '--after', 'field2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a new field and set its value',
            argv => ['file.csv', 'after_tax', '-e', '$main::row->[5] * 1.11'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Add a couple new fields and set their values',
            argv => ['file.csv', 'tax_rate', 'after_tax', '-e', '(0.11, $main::row->[5] * 1.11)'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    tags => ['outputs_csv'],
};
sub csv_add_fields {
    my %args = @_;
    csvutil(
        %args, action=>'add-fields',
        _after  => $args{after},
        _before => $args{before},
        _at     => $args{at},
    );
}

$SPEC{csv_list_field_names} = {
    v => 1.1,
    summary => 'List field names of CSV file',
    args => {
        %argspecs_common,
        %argspec_filename_0,
    },
    description => '' . $common_desc,
};
sub csv_list_field_names {
    my %args = @_;
    csvutil(%args, action=>'list-field-names');
}

$SPEC{csv_info} = {
    v => 1.1,
    summary => 'Show information about CSV file (number of rows, fields, etc)',
    args => {
        %argspecs_common,
        %argspec_filename_0,
    },
    description => '' . $common_desc,
};
sub csv_info {
    my %args = @_;
    csvutil(%args, action=>'info');
}

$SPEC{csv_delete_fields} = {
    v => 1.1,
    summary => 'Delete one or more fields from CSV file',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecsopt_field_selection,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_delete_fields {
    my %args = @_;
    csvutil(%args, action=>'delete-fields');
}

$SPEC{csv_munge_field} = {
    v => 1.1,
    summary => 'Munge a field in every row of CSV file with Perl code',
    description => <<'_' . $common_desc,

Perl code (-e) will be called for each row (excluding the header row) and `$_`
will contain the value of the field, and the Perl code is expected to modify it.
`$main::row` will contain the current row array. `$main::rownum` contains the
row number (2 means the first data row). `$main::csv` is the <pm:Text::CSV_XS>
object. `$main::field_idxs` is also available for additional information.

To munge multiple fields, use <prog:csv-munge-row>.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        %argspec_field_1,
        %argspec_eval_2,
    },
    tags => ['outputs_csv'],
};
sub csv_munge_field {
    my %args = @_;
    csvutil(%args, action=>'munge-field');
}

$SPEC{csv_munge_row} = {
    v => 1.1,
    summary => 'Munge each data arow of CSV file with Perl code',
    description => <<'_' . $common_desc,

Perl code (-e) will be called for each row (excluding the header row) and `$_`
will contain the row (arrayref, or hashref if `-H` is specified). The Perl code
is expected to modify it.

Aside from `$_`, `$main::row` will contain the current row array.
`$main::rownum` contains the row number (2 means the first data row).
`$main::csv` is the <pm:Text::CSV_XS> object. `$main::field_idxs` is also
available for additional information.

The modified `$_` will be rendered back to CSV row.

You can also munge a single field using <prog:csv-munge-field>.

You cannot add new fields using this utility. To do so, use
<prog:csv-add-fields>.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        %argspec_eval_1,
        %argspec_hash,
    },
    tags => ['outputs_csv'],
};
sub csv_munge_row {
    my %args = @_;
    csvutil(%args, action=>'munge-row');
}

$SPEC{csv_replace_newline} = {
    v => 1.1,
    summary => 'Replace newlines in CSV values',
    description => <<'_' . $common_desc,

Some CSV parsers or applications cannot handle multiline CSV values. This
utility can be used to convert the newline to something else. There are a few
choices: replace newline with space (`--with-space`, the default), remove
newline (`--with-nothing`), replace with encoded representation
(`--with-backslash-n`), or with characters of your choice (`--with 'blah'`).

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        with => {
            schema => 'str*',
            default => ' ',
            cmdline_aliases => {
                with_space => { is_flag=>1, code=>sub { $_[0]{with} = ' ' } },
                with_nothing => { is_flag=>1, code=>sub { $_[0]{with} = '' } },
                with_backslash_n => { is_flag=>1, code=>sub { $_[0]{with} = "\\n" } },
            },
        },
    },
    tags => ['outputs_csv'],
};
sub csv_replace_newline {
    my %args = @_;
    my $with = $args{with};

    my $csv_parser  = _instantiate_parser(\%args);
    my $csv_emitter = _instantiate_emitter(\%args);

    my ($fh, $err) = _read_file($args{filename});

    my $res = "";
    my $i = 0;
    while (my $row = $csv_parser->getline($fh)) {
        $i++;
        for my $col (@$row) {
            $col =~ s/[\015\012]+/$with/g;
        }
        my $status = $csv_emitter->combine(@$row)
            or die "Error in line $i: ".$csv_emitter->error_input;
        $res .= $csv_emitter->string . "\n";
    }

    _return_or_write_file([200, "OK", $res, {"cmdline.skip_format"=>1}], $args{output_filename}, $args{overwrite});
}

$SPEC{csv_sort_rows} = {
    v => 1.1,
    summary => 'Sort CSV rows',
    description => <<'_' . $common_desc,

This utility sorts the rows in the CSV. Example input CSV:

    name,age
    Andy,20
    Dennis,15
    Ben,30
    Jerry,30

Example output CSV (using `--by-field +age` which means by age numerically and
ascending):

    name,age
    Dennis,15
    Andy,20
    Ben,30
    Jerry,30

Example output CSV (using `--by-field -age`, which means by age numerically and
descending):

    name,age
    Ben,30
    Jerry,30
    Andy,20
    Dennis,15

Example output CSV (using `--by-field name`, which means by name ascibetically
and ascending):

    name,age
    Andy,20
    Ben,30
    Dennis,15
    Jerry,30

Example output CSV (using `--by-field ~name`, which means by name ascibetically
and descending):

    name,age
    Jerry,30
    Dennis,15
    Ben,30
    Andy,20

Example output CSV (using `--by-field +age --by-field ~name`):

    name,age
    Dennis,15
    Andy,20
    Jerry,30
    Ben,30

You can also reverse the sort order (`-r`) or sort case-insensitively (`-i`).

For more flexibility, instead of `--by-field` you can use `--by-code`:

Example output `--by-code '$a->[1] <=> $b->[1] || $b->[0] cmp $a->[0]'` (which
is equivalent to `--by-field +age --by-field ~name`):

    name,age
    Dennis,15
    Andy,20
    Jerry,30
    Ben,30

If you use `--hash`, your code will receive the rows to be compared as hashref,
e.g. `--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

A third alternative is to sort using <pm:Sort::Sub> routines. Example output
(using `--by-sortsub 'by_length<r>' --key '$_->[0]'`, which is to say to sort by
descending length of name):

    name,age
    Dennis,15
    Jerry,30
    Andy,20
    Ben,30

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,

        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_hash,

        %argspecs_sort_rows_short,
    },
    args_rels => {
        req_one => ['by_fields', 'by_code', 'by_sortsub'],
    },
    tags => ['outputs_csv'],
};
sub csv_sort_rows {
    my %args = @_;

    my %csvutil_args = (
        hash_subset(\%args, \%argspecs_common, \%argspecs_csv_output),
        action => 'sort-rows',

        filename => $args{filename},
        output_filename => $args{output_filename},
        overwrite => $args{overwrite},
        hash => $args{hash},

        sort_reverse => $args{reverse},
        sort_ci => $args{ci},
        sort_key => $args{key},
        sort_by_fields => $args{by_fields},
        sort_by_code   => $args{by_code},
        sort_by_sortsub => $args{by_sortsub},
        sort_sortsub_args => $args{sortsub_args},
    );

    csvutil(%csvutil_args);
}

$SPEC{csv_shuf_rows} = {
    v => 1.1,
    summary => 'Shuffle CSV rows',
    description => <<'_' . $common_desc,

This is basically like Unix command `shuf` except it does not shuffle the header
row.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
    },
    tags => ['outputs_csv'],
};
sub csv_shuf_rows {
    my %args = @_;
    csvutil(
        %args,
        action => 'sort-rows',
        # TODO: this feels less shuffled
        sort_by_code => sub { int(rand 3)-1 }, # return -1,0,1 randomly
    );
}

$SPEC{csv_sort_fields} = {
    v => 1.1,
    summary => 'Sort CSV fields',
    description => <<'_' . $common_desc,

This utility sorts the order of fields in the CSV. Example input CSV:

    b,c,a
    1,2,3
    4,5,6

Example output CSV:

    a,b,c
    3,1,2
    6,4,5

You can also reverse the sort order (`-r`), sort case-insensitively (`-i`), or
provides the ordering example, e.g. `--by-examples-json '["a","c","b"]'`, or use
`--by-code` or `--by-sortsub`.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,

        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,

        %argspecs_sort_fields_short,
    },
    tags => ['outputs_csv'],
};
sub csv_sort_fields {
    my %args = @_;

    my %csvutil_args = (
        hash_subset(\%args, \%argspecs_common, \%argspecs_csv_output),
        action => 'sort-fields',

        filename => $args{filename},
        output_filename => $args{output_filename},
        overwrite => $args{overwrite},

        sort_reverse => $args{reverse},
        sort_ci => $args{ci},
        (sort_examples => $args{by_examples}) x !!defined($args{by_examples}),
        (sort_by_code => $args{by_code}) x !!defined($args{by_code}),
        (sort_by_sortsub => $args{by_sortsub}) x !!defined($args{by_sortsub}),
    );
    csvutil(%csvutil_args);
}

$SPEC{csv_shuf_fields} = {
    v => 1.1,
    summary => 'Shuffle CSV fields',
    description => <<'_' . $common_desc,

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
    },
    tags => ['outputs_csv'],
};
sub csv_shuf_fields {
    my %args = @_;
    csvutil(
        %args,
        action => 'sort-fields',
        # TODO: this feels less shuffled
        sort_by_code => sub { int(rand 3)-1 }, # return -1,0,1 randomly
    );
}

$SPEC{csv_sum} = {
    v => 1.1,
    summary => 'Output a summary row which are arithmetic sums of data rows',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_with_data_rows,
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_sum {
    my %args = @_;

    csvutil(%args, action=>'sum', _with_data_rows=>$args{with_data_rows});
}

$SPEC{csv_avg} = {
    v => 1.1,
    summary => 'Output a summary row which are arithmetic averages of data rows',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_with_data_rows,
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_avg {
    my %args = @_;

    csvutil(%args, action=>'avg', _with_data_rows=>$args{with_data_rows});
}

$SPEC{csv_freqtable} = {
    v => 1.1,
    summary => 'Output a frequency table of values of a specified field in CSV',
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspec_field_1,
    },
    description => '' . $common_desc,
};
sub csv_freqtable {
    my %args = @_;

    csvutil(%args, action=>'freqtable');
}

$SPEC{csv_select_rows} = {
    v => 1.1,
    summary => 'Only output specified row(s)',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        row_spec => {
            schema => 'str*',
            summary => 'Row number (e.g. 2 for first data row), '.
                'range (2-7), or comma-separated list of such (2-7,10,20-23)',
            req => 1,
            pos => 2,
        },
    },
    description => '' . $common_desc,
    links => [
        {url=>"prog:csv-split"},
    ],
    tags => ['outputs_csv'],
};
sub csv_select_rows {
    my %args = @_;

    csvutil(%args, action=>'select-rows');
}

$SPEC{csv_split} = {
    v => 1.1,
    summary => 'Split CSV file into several files',
    description => <<'_' . $common_desc,

Will output split files xaa, xab, and so on. Each split file will contain a
maximum of `lines` rows (options to limit split files' size based on number of
characters and bytes will be added). Each split file will also contain CSV
header.

Warning: by default, existing split files xaa, xab, and so on will be
overwritten.

Interface is loosely based on the `split` Unix utility.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        lines => {
            schema => ['uint*', min=>1],
            default => 1000,
            cmdline_aliases => {l=>{}},
        },
        # XXX --bytes (-b)
        # XXX --line-bytes (-C)
        # XXX -d (numeric suffix)
        # --suffix-length (-a)
        # --number, -n (chunks)
    },
    links => [
        {url=>"prog:csv-select-rows"},
    ],
    tags => ['outputs_csv'],
};
sub csv_split {
    my %args = @_;

    csvutil(%args, action=>'split');
}

$SPEC{csv_grep} = {
    v => 1.1,
    summary => 'Only output row(s) where Perl expression returns true',
    description => <<'_' . $common_desc,

This is like Perl's `grep` performed over rows of CSV. In `$_`, your Perl code
will find the CSV row as an arrayref (or, if you specify `-H`, as a hashref).
`$main::row` is also set to the row (always as arrayref). `$main::rownum`
contains the row number (2 means the first data row). `$main::csv` is the
<pm:Text::CSV_XS> object. `$main::field_idxs` is also available for additional
information.

Your code is then free to return true or false based on some criteria. Only rows
where Perl expression returns true will be included in the result.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_eval,
        %argspec_hash,
    },
    examples => [
        {
            summary => 'Only show rows where the amount field '.
                'is divisible by 7',
            argv => ['-He', '$_->{amount} % 7 ? 1:0', 'file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Only show rows where date is a Wednesday',
            argv => ['-He', 'BEGIN { use DateTime::Format::Natural; $parser = DateTime::Format::Natural->new } $dt = $parser->parse_datetime($_->{date}); $dt->day_of_week == 3', 'file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:csvgrep'},
    ],
    tags => ['outputs_csv'],
};
sub csv_grep {
    my %args = @_;

    csvutil(%args, action=>'grep');
}

$SPEC{csv_pick_rows} = {
    v => 1.1,
    summary => 'Return one or more random rows from CSV',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        num => {
            summary => 'Number of rows to pick',
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {n=>{}},
        },
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_pick_rows {
    my %args = @_;
    csvutil(
        %args,
        action=>'pick-rows',
        pick_num => $args{num} // 1,
    );
}

$SPEC{csv_map} = {
    v => 1.1,
    summary => 'Return result of Perl code for every row',
    description => <<'_' . $common_desc,

This is like Perl's `map` performed over rows of CSV. In `$_`, your Perl code
will find the CSV row as an arrayref (or, if you specify `-H`, as a hashref).
`$main::row` is also set to the row (always as arrayref). `$main::rownum`
contains the row number (2 means the first data row). `$main::csv` is the
<pm:Text::CSV_XS> object. `$main::field_idxs` is also available for additional
information.

Your code is then free to return a string based on some operation against these
data. This utility will then print out the resulting string.

_
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_eval,
        %argspec_hash,
        add_newline => {
            summary => 'Whether to make sure each string ends with newline',
            schema => 'bool*',
            default => 1,
        },
    },
    examples => [
        {
            summary => 'Create SQL insert statements (escaping is left as an exercise for users)',
            argv => ['-He', '"INSERT INTO mytable (id,amount) VALUES ($_->{id}, $_->{amount});"', 'file.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:csvgrep'},
    ],
};
sub csv_map {
    my %args = @_;

    csvutil(%args, action=>'map');
}

$SPEC{csv_each_row} = {
    v => 1.1,
    summary => 'Run Perl code for every row',
    description => <<'_' . $common_desc,

This is like csv_map, except result of code is not printed.

_
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspec_eval,
        %argspec_hash,
    },
    examples => [
        {
            summary => 'Delete user data',
            argv => ['-He', '"unlink qq(/home/data/$_->{username}.dat)"', 'users.csv'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
    ],
};
sub csv_each_row {
    my %args = @_;

    csvutil(%args, action=>'each-row');
}

$SPEC{csv_convert_to_hash} = {
    v => 1.1,
    summary => 'Return a hash of field names as keys and first row as values',
    args => {
        %argspecs_common,
        %argspec_filename_0,
        row_number => {
            schema => ['int*', min=>2],
            default => 2,
            summary => 'Row number (e.g. 2 for first data row)',
            pos => 1,
        },
    },
    description => '' . $common_desc,
};
sub csv_convert_to_hash {
    my %args = @_;

    csvutil(%args, action=>'convert-to-hash',
            _row_number=>$args{row_number} // 2);
}

$SPEC{csv_transpose} = {
    v => 1.1,
    summary => 'Transpose a CSV',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_transpose {
    my %args = @_;

    csvutil(%args, action=>'transpose');
}

$SPEC{csv2td} = {
    v => 1.1,
    summary => 'Return an enveloped aoaos table data from CSV data',
    description => <<'_',

Read more about "table data" in <pm:App::td>, which comes with a CLI <prog:td>
to munge table data.

_
    args => {
        %argspecs_common,
        %argspec_filename_0,
    },
    description => '' . $common_desc,
};
sub csv2td {
    my %args = @_;

    csvutil(%args, action=>'convert-to-td');
}

$SPEC{csv2vcf} = {
    v => 1.1,
    summary => 'Create a VCF from selected fields of the CSV',
    description => <<'_',

You can set which CSV fields to use for name, cell phone, and email. If unset,
will guess from the field name. If that also fails, will warn/bail out.

_
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspecsopt_vcf,
    },
    description => '' . $common_desc,
};
sub csv2vcf {
    my %args = @_;

    csvutil(%args, action=>'convert-to-vcf');
}

$SPEC{csv_concat} = {
    v => 1.1,
    summary => 'Concatenate several CSV files together, '.
        'collecting all the fields',
    description => <<'_' . $common_desc,

Example, concatenating this CSV:

    col1,col2
    1,2
    3,4

and:

    col2,col4
    a,b
    c,d
    e,f

and:

    col3
    X
    Y

will result in:

    col1,col2,col4,col3
    1,2,
    3,4,
    ,a,b
    ,c,d
    ,e,f
    ,,,X
    ,,,Y

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filenames_0plus,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
    },
    tags => ['outputs_csv'],
};
sub csv_concat {
    my %args = @_;

    my %res_field_idxs;
    my @rows;

    for my $filename (@{ $args{filenames} }) {
        my $csv_parser  = _instantiate_parser(\%args);

        my ($fh, $err) = _read_file($filename);
        return $err if $err;

        my $i = 0;
        my $fields;
        while (my $row = $csv_parser->getline($fh)) {
            $i++;
            if ($i == 1) {
                $fields = $row;
                for my $field (@$fields) {
                    unless (exists $res_field_idxs{$field}) {
                        $res_field_idxs{$field} = keys(%res_field_idxs);
                    }
                }
                next;
            }
            my $res_row = [];
            for my $j (0..$#{$row}) {
                if ($j >= @$fields) {
                    log_warn "File %s line %d contains more than %d fields, skipped", $filename, $i, scalar(@$fields);
                    last;
                }
                my $field = $fields->[$j];
                $res_row->[ $res_field_idxs{$field} ] = $row->[$j];
            }
            push @rows, $res_row;
        }
    } # for each filename

    my $num_fields = keys %res_field_idxs;
    my $res = "";
    my $csv_emitter = _instantiate_emitter(\%args);

    # generate header
    my $status = $csv_emitter->combine(
        sort { $res_field_idxs{$a} <=> $res_field_idxs{$b} }
            keys %res_field_idxs)
        or die "Error in generating result header row: ".$csv_emitter->error_input;
    $res .= $csv_emitter->string . "\n";
    for my $i (0..$#rows) {
        my $row = $rows[$i];
        $row->[$num_fields-1] = undef if @$row < $num_fields;
        my $status = $csv_emitter->combine(@$row)
            or die "Error in generating data row #".($i+1).": ".
            $csv_emitter->error_input;
        $res .= $csv_emitter->string . "\n";
    }
    _return_or_write_file([200, "OK", $res, {"cmdline.skip_format"=>1}], $args{output_filename}, $args{overwrite});
}

$SPEC{csv_select_fields} = {
    v => 1.1,
    summary => 'Only output selected field(s)',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspecsopt_field_selection,
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_select_fields {
    my %args = @_;
    csvutil(%args, action=>'select-fields');
}

$SPEC{csv_pick_fields} = {
    v => 1.1,
    summary => 'Select one or more random fields from CSV',
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        num => {
            summary => 'Number of fields to pick',
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {n=>{}},
        },
    },
    description => '' . $common_desc,
    tags => ['outputs_csv'],
};
sub csv_pick_fields {
    my %args = @_;
    csvutil(
        %args,
        action=>'select-fields',
        pick_num => $args{num} // 1,
    );
}

$SPEC{csv_get_cells} = {
    v => 1.1,
    summary => 'Get one or more cells from CSV',
    args => {
        %argspecs_common,
        %argspec_filename_0,
        coordinates => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'coordinate',
            summary => 'List of coordinates, each in the form of <col>,<row> e.g. colname,0 or 1,1',
            schema => ['array*', of=>'str*'],
            pos => 1,
            slurpy => 1,
        },
    },
    description => <<'_' . $common_desc,

This utility lets you specify "coordinates" of cell locations to extract. Each
coordinate is in the form of `<col>,<row>` where `<col>` is the column name or
position (zero-based, so 0 is the first column) and `<row>` is the row position
(one-based, so 1 is the header row and 2 is the first data row).

_
};
sub csv_get_cells {
    my %args = @_;
    csvutil(%args, action=>'get-cells');
}

$SPEC{csv_fill_template} = {
    v => 1.1,
    summary => 'Substitute template values in a text file with fields from CSV rows',
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        template_filename => {
            schema => 'filename*',
            req => 1,
            pos => 2,
        },
        # XXX whether to output multiple files or combined
        # XXX row selection?
    },
    description => <<'_' . $common_desc,

Templates are text that contain `[[NAME]]` field placeholders. The field
placeholders will be replaced by values from the CSV file. This is a simple
alternative to mail-merge. (I first wrote this utility because LibreOffice
Writer, as always, has all the annoying bugs; this time, it prevents mail merge
from working.)

_
};
sub csv_fill_template {
    my %args = @_;
    csvutil(%args, action=>'fill-template');
}

$SPEC{csv_dump} = {
    v => 1.1,
    summary => 'Dump CSV as data structure (array of array/hash)',
    args => {
        %argspecs_common,
        %argspec_filename_0,
        %argspec_hash,
    },
    description => '' . $common_desc,
};
sub csv_dump {
    my %args = @_;
    csvutil(%args, action=>'dump');
}

$SPEC{csv_csv} = {
    v => 1.1,
    summary => 'Convert CSV to CSV',
    description => <<'_' . $common_desc,

Why convert CSV to CSV? When you want to change separator/quote/escape
character, for one.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filename_0,
        %argspecopt_output_filename_1,
        %argspecopt_overwrite,
        %argspec_hash,
    },
};
sub csv_csv {
    my %args = @_;
    csvutil(%args, action=>'csv');
}

$SPEC{csv_setop} = {
    v => 1.1,
    summary => 'Set operation (union/unique concatenation of rows, intersection/common rows, difference of rows) against several CSV files',
    description => <<'_' . $common_desc,

Example input:

    # file1.csv
    a,b,c
    1,2,3
    4,5,6
    7,8,9

    # file2.csv
    a,b,c
    1,2,3
    4,5,7
    7,8,9

Output of intersection (`--intersect file1.csv file2.csv`), which will return
common rows between the two files:

    a,b,c
    1,2,3
    7,8,9

Output of union (`--union file1.csv file2.csv`), which will return all rows with
duplicate removed:

    a,b,c
    1,2,3
    4,5,6
    4,5,7
    7,8,9

Output of difference (`--diff file1.csv file2.csv`), which will return all rows
in the first file but not in the second:

    a,b,c
    4,5,6

Output of symmetric difference (`--symdiff file1.csv file2.csv`), which will
return all rows in the first file not in the second, as well as rows in the
second not in the first:

    a,b,c
    4,5,6
    4,5,7

You can specify `--compare-fields` to only consider some fields only, for
example `--union --compare-fields a,b file1.csv file2.csv`:

    a,b,c
    1,2,3
    4,5,6
    7,8,9

Each field specified in `--compare-fields` can be specified using
`F1:OTHER1,F2:OTHER2,...` format to refer to different field names or indexes in
each file, for example if `file3.csv` is:

    # file3.csv
    Ei,Si,Bi
    1,3,2
    4,7,5
    7,9,8

Then `--union --compare-fields a:Ei,b:Bi file1.csv file3.csv` will result in:

    a,b,c
    1,2,3
    4,5,6
    7,8,9

Finally you can print out certain fields using `--result-fields`.

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspec_filenames_0plus,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        op => {
            summary => 'Set operation to perform',
            schema => ['str*', in=>[qw/intersect union diff symdiff/]],
            req => 1,
            cmdline_aliases => {
                intersect   => {is_flag=>1, summary=>'Shortcut for --op=intersect', code=>sub{ $_[0]{op} = 'intersect' }},
                union       => {is_flag=>1, summary=>'Shortcut for --op=union'    , code=>sub{ $_[0]{op} = 'union'     }},
                diff        => {is_flag=>1, summary=>'Shortcut for --op=diff'     , code=>sub{ $_[0]{op} = 'diff'      }},
                symdiff     => {is_flag=>1, summary=>'Shortcut for --op=symdiff'  , code=>sub{ $_[0]{op} = 'symdiff'   }},
            },
        },
        ignore_case => {
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        compare_fields => {
            schema => ['str*'],
        },
        result_fields => {
            schema => ['str*'],
        },
    },
    links => [
        {url=>'prog:setop'},
    ],
    tags => ['outputs_csv'],
};
sub csv_setop {
    require Tie::IxHash;

    my %args = @_;

    my $op = $args{op};
    my $ci = $args{ignore_case};
    my $num_files = @{ $args{filenames} };

    unless ($op ne 'cross' || $num_files > 1) {
        return [400, "Please specify at least 2 input files for cross"];
    }
    unless ($num_files >= 1) {
        return [400, "Please specify at least 1 input file"];
    }

    my @all_data_rows;   # elem=rows, one elem for each input file
    my @all_field_idxs;  # elem=field_idxs (hash, key=column name, val=index)
    my @all_field_names; # elem=[field1,field2,...] for 1st file, ...

    # read all csv
    for my $filename (@{ $args{filenames} }) {
        my $csv = _instantiate_parser(\%args);

        my ($fh, $err) = _read_file($filename);
        return $err if $err;

        my $i = 0;
        my @data_rows;
        my $field_idxs = {};
        while (my $row = $csv->getline($fh)) {
            $i++;
            if ($i == 1) {
                if ($args{header} // 1) {
                    my $fields = $row;
                    for my $field (@$fields) {
                        unless (exists $field_idxs->{$field}) {
                            $field_idxs->{$field} = keys(%$field_idxs);
                        }
                    }
                    push @all_field_names, $fields;
                    push @all_field_idxs, $field_idxs;
                    next;
                } else {
                    my $fields = [];
                    for (1..@$row) {
                        $field_idxs->{"field$_"} = $_-1;
                        push @$fields, "field$_";
                    }
                    push @all_field_names, $fields;
                    push @all_field_idxs, $field_idxs;
                }
            }
            push @data_rows, $row;
        }
        push @all_data_rows, \@data_rows;
    } # for each filename

    my @compare_fields; # elem = [fieldname-for-file1, fieldname-for-file2, ...]
    if (defined $args{compare_fields}) {
        my @ff = ref($args{compare_fields}) eq 'ARRAY' ?
            @{$args{compare_fields}} : split(/,/, $args{compare_fields});
        for my $field_idx (0..$#ff) {
            my @ff2 = split /:/, $ff[$field_idx];
            for (@ff2+1 .. $num_files) {
                push @ff2, $ff2[0];
            }
            $compare_fields[$field_idx] = \@ff2;
        }
    } else {
        for my $field_idx (0..$#{ $all_field_names[0] }) {
            $compare_fields[$field_idx] = [
                map { $all_field_names[0][$field_idx] } 0..$num_files-1];
        }
    }

    my @result_fields; # elem = fieldname, ...
    if (defined $args{result_fields}) {
        @result_fields = ref($args{result_fields}) eq 'ARRAY' ?
            @{$args{result_fields}} : split(/,/, $args{result_fields});
    } else {
        @result_fields = @{ $all_field_names[0] };
    }

    tie my(%res), 'Tie::IxHash';
    my $res = "";

    my $code_get_compare_key = sub {
        my ($file_idx, $row_idx) = @_;
        my $row   = $all_data_rows[$file_idx][$row_idx];
        my $key = join "|", map {
            my $field = $compare_fields[$_][$file_idx];
            my $field_idx = $all_field_idxs[$file_idx]{$field};
            my $val = defined $field_idx ? $row->[$field_idx] : "";
            $val = uc $val if $ci;
            $val;
        } 0..$#compare_fields;
        #say "D:compare_key($file_idx, $row_idx)=<$key>";
        $key;
    };

    my $csv = _instantiate_parser_default();
    my $code_format_result_row = sub {
        my ($file_idx, $row) = @_;
        my @res_row = map {
            my $field = $result_fields[$_];
            my $field_idx = $all_field_idxs[$file_idx]{$field};
            defined $field_idx ? $row->[$field_idx] : "";
        } 0..$#result_fields;
        $csv->combine(@res_row);
        $csv->string . "\n";
    };

    if ($op eq 'intersect') {
        for my $file_idx (0..$num_files-1) {
            if ($file_idx == 0) {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    $res{$key} //= [1, $row_idx]; # [num_of_occurrence, row_idx]
                }
            } else {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    if ($res{$key} && $res{$key}[0] == $file_idx) {
                        $res{$key}[0]++;
                    }
                }
            }

            # build result
            if ($file_idx == $num_files-1) {
                #use DD; dd \%res;
                $csv->combine(@result_fields);
                $res .= $csv->string . "\n";
                for my $key (keys %res) {
                    $res .= $code_format_result_row->(
                        0, $all_data_rows[0][$res{$key}[1]])
                        if $res{$key}[0] == $num_files;
                }
            }
        } # for file_idx

    } elsif ($op eq 'union') {
        $csv->combine(@result_fields);
        $res .= $csv->string . "\n";

        for my $file_idx (0..$num_files-1) {
            for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                my $key = $code_get_compare_key->($file_idx, $row_idx);
                next if $res{$key}++;
                my $row = $all_data_rows[$file_idx][$row_idx];
                $res .= $code_format_result_row->($file_idx, $row);
            }
        } # for file_idx

    } elsif ($op eq 'diff') {
        for my $file_idx (0..$num_files-1) {
            if ($file_idx == 0) {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    $res{$key} //= [$file_idx, $row_idx];
                }
            } else {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    delete $res{$key};
                }
            }

            # build result
            if ($file_idx == $num_files-1) {
                $csv->combine(@result_fields);
                $res .= $csv->string . "\n";
                for my $key (keys %res) {
                    my ($file_idx, $row_idx) = @{ $res{$key} };
                    $res .= $code_format_result_row->(
                        0, $all_data_rows[$file_idx][$row_idx]);
                }
            }
        } # for file_idx

    } elsif ($op eq 'symdiff') {
        for my $file_idx (0..$num_files-1) {
            if ($file_idx == 0) {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    $res{$key} //= [1, $file_idx, $row_idx];  # [num_of_occurrence, file_idx, row_idx]
                }
            } else {
                for my $row_idx (0..$#{ $all_data_rows[$file_idx] }) {
                    my $key = $code_get_compare_key->($file_idx, $row_idx);
                    if (!$res{$key}) {
                        $res{$key} = [1, $file_idx, $row_idx];
                    } else {
                        $res{$key}[0]++;
                    }
                }
            }

            # build result
            if ($file_idx == $num_files-1) {
                $csv->combine(@result_fields);
                $res .= $csv->string . "\n";
                for my $key (keys %res) {
                    my ($num_occur, $file_idx, $row_idx) = @{ $res{$key} };
                    $res .= $code_format_result_row->(
                        0, $all_data_rows[$file_idx][$row_idx])
                        if $num_occur == 1;
                }
            }
        } # for file_idx

    } else {
        return [400, "Unknown/unimplemented op '$op'"];
    }

    #use DD; dd +{
    #    compare_fields => \@compare_fields,
    #    result_fields => \@result_fields,
    #    all_field_idxs=>\@all_field_idxs,
    #    all_data_rows=>\@all_data_rows,
    #};

    _return_or_write_file([200, "OK", $res, {"cmdline.skip_format"=>1}], $args{output_filename}, $args{overwrite});
}

$SPEC{csv_lookup_fields} = {
    v => 1.1,
    summary => 'Fill fields of a CSV file from another',
    description => <<'_' . $common_desc,

Example input:

    # report.csv
    client_id,followup_staff,followup_note,client_email,client_phone
    101,Jerry,not renewing,
    299,Jerry,still thinking over,
    734,Elaine,renewing,

    # clients.csv
    id,name,email,phone
    101,Andy,andy@example.com,555-2983
    102,Bob,bob@acme.example.com,555-2523
    299,Cindy,cindy@example.com,555-7892
    400,Derek,derek@example.com,555-9018
    701,Edward,edward@example.com,555-5833
    734,Felipe,felipe@example.com,555-9067

To fill up the `client_email` and `client_phone` fields of `report.csv` from
`clients.csv`, we can use: `--lookup-fields client_id:id --fill-fields
client_email:email,client_phone:phone`. The result will be:

    client_id,followup_staff,followup_note,client_email,client_phone
    101,Jerry,not renewing,andy@example.com,555-2983
    299,Jerry,still thinking over,cindy@example.com,555-7892
    734,Elaine,renewing,felipe@example.com,555-9067

_
    args => {
        %argspecs_common,
        %argspecs_csv_output,
        %argspecopt_output_filename,
        %argspecopt_overwrite,
        target => {
            summary => 'CSV file to fill fields of',
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        source => {
            summary => 'CSV file to lookup values from',
            schema => 'filename*',
            req => 1,
            pos => 1,
        },
        ignore_case => {
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        fill_fields => {
            schema => ['str*'],
            req => 1,
        },
        lookup_fields => {
            schema => ['str*'],
            req => 1,
        },
        count => {
            summary => 'Do not output rows, just report the number of rows filled',
            schema => 'bool*',
            cmdline_aliases => {c=>{}},
        },
    },
    tags => ['outputs_csv'],
};
sub csv_lookup_fields {
    my %args = @_;

    my $op = $args{op};
    my $ci = $args{ignore_case};

    my @lookup_fields; # elem = [fieldname-in-target, fieldname-in-source]
    {
        my @ff = ref($args{lookup_fields}) eq 'ARRAY' ?
            @{$args{lookup_fields}} : split(/,/, $args{lookup_fields});
        for my $field_idx (0..$#ff) {
            my @ff2 = split /:/, $ff[$field_idx], 2;
            if (@ff2 < 2) {
                $ff2[1] = $ff2[0];
            }
            $lookup_fields[$field_idx] = \@ff2;
        }
    }

    my %fill_fields; # key=fieldname-in-target, val=fieldname-in-source
    {
        my @ff = ref($args{fill_fields}) eq 'ARRAY' ?
            @{$args{fill_fields}} : split(/,/, $args{fill_fields});
        for my $field_idx (0..$#ff) {
            my @ff2 = split /:/, $ff[$field_idx], 2;
            if (@ff2 < 2) {
                $ff2[1] = $ff2[0];
            }
            $fill_fields{ $ff2[0] } = $ff2[1];
        }
    }

    # read source csv
    my @source_data_rows;
    my %source_field_idxs;
    my @source_field_names;
    {
        my $csv = _instantiate_parser(\%args);

        my ($fh, $err) = _read_file($args{source});
        return $err if $err;

        my $i = 0;
        while (my $row = $csv->getline($fh)) {
            $i++;
            if ($i == 1) {
                if ($args{header} // 1) {
                    @source_field_names = @$row;
                    for my $field (@source_field_names) {
                        unless (exists $source_field_idxs{$field}) {
                            $source_field_idxs{$field} = keys(%source_field_idxs);
                        }
                    }
                    next;
                } else {
                    for (1..@$row) {
                        $source_field_idxs{"field$_"} = $_-1;
                        push @source_field_names, "field$_";
                    }
                }
            }
            push @source_data_rows, $row;
        }
    }

    # build lookup table
    my %lookup_table; # key = joined lookup fields, val = source row idx
    for my $row_idx (0..$#{source_data_rows}) {
        my $row = $source_data_rows[$row_idx];
        my $key = join "|", map {
            my $field = $lookup_fields[$_][1];
            my $field_idx = $source_field_idxs{$field};
            my $val = defined $field_idx ? $row->[$field_idx] : "";
            $val = lc $val if $ci;
            $val;
        } 0..$#lookup_fields;
        $lookup_table{$key} //= $row_idx;
    }
    #use DD; dd { lookup_fields=>\@lookup_fields, fill_fields=>\%fill_fields, lookup_table=>\%lookup_table };

    # fill target csv
    my $res = "";
    my @target_field_names;
    my %target_field_idxs;
    my $num_filled = 0;
    {
        my $csv_out = _instantiate_parser_default();
        my $csv = _instantiate_parser(\%args);

        my ($fh, $err) = _read_file($args{target});
        return $err if $err;

        my $i = 0;
        while (my $row = $csv->getline($fh)) {
            $i++;
            if ($i == 1) {
                if ($args{header} // 1) {
                    $csv_out->combine(@$row);
                    $res .= $csv_out->string . "\n";
                    @target_field_names = @$row;
                    for my $field (@target_field_names) {
                        unless (exists $target_field_idxs{$field}) {
                            $target_field_idxs{$field} = keys(%target_field_idxs);
                        }
                    }
                    next;
                } else {
                    for (1..@$row) {
                        $target_field_idxs{"field$_"} = $_-1;
                        push @target_field_names, "field$_";
                    }
                }
            }

            my $key = join "|", map {
                my $field = $lookup_fields[$_][0];
                my $field_idx = $target_field_idxs{$field};
                my $val = defined $field_idx ? $row->[$field_idx] : "";
                $val = lc $val if $ci;
                $val;
            } 0..$#lookup_fields;

            #say "D:looking up '$key' ...";
            if (defined(my $row_idx = $lookup_table{$key})) {
                #say "  D:found";
                my $row_filled;
                my $source_row = $source_data_rows[$row_idx];
                for my $field (keys %fill_fields) {
                    my $target_field_idx = $target_field_idxs{$field};
                    next unless defined $target_field_idx;
                    my $source_field_idx = $source_field_idxs{ $fill_fields{$field} };
                    next unless defined $source_field_idx;
                    $row->[$target_field_idx] =
                        $source_row->[$source_field_idx];
                    $row_filled++;
                }
                $num_filled++ if $row_filled;
            }
            $csv_out->combine(@$row);
            unless ($args{count}) {
                $res .= $csv_out->string . "\n";
            }
        }
    }

    if ($args{count}) {
        [200, "OK", $num_filled];
    } else {
        _return_or_write_file([200, "OK", $res, {"cmdline.skip_format"=>1}], $args{output_filename}, $args{overwrite});
    }
}

1;
# ABSTRACT: CLI utilities related to CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils - CLI utilities related to CSV

=head1 VERSION

This document describes version 0.054 of App::CSVUtils (from Perl distribution App-CSVUtils), released on 2022-12-14.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<csv-add-fields>

=item * L<csv-avg>

=item * L<csv-concat>

=item * L<csv-convert-to-hash>

=item * L<csv-csv>

=item * L<csv-delete-fields>

=item * L<csv-dump>

=item * L<csv-each-row>

=item * L<csv-fill-template>

=item * L<csv-freqtable>

=item * L<csv-get-cells>

=item * L<csv-grep>

=item * L<csv-info>

=item * L<csv-list-field-names>

=item * L<csv-lookup-fields>

=item * L<csv-map>

=item * L<csv-munge-field>

=item * L<csv-munge-row>

=item * L<csv-pick>

=item * L<csv-pick-fields>

=item * L<csv-pick-rows>

=item * L<csv-replace-newline>

=item * L<csv-select-fields>

=item * L<csv-select-rows>

=item * L<csv-setop>

=item * L<csv-shuf>

=item * L<csv-shuf-fields>

=item * L<csv-shuf-rows>

=item * L<csv-sort>

=item * L<csv-sort-fields>

=item * L<csv-sort-rows>

=item * L<csv-split>

=item * L<csv-sum>

=item * L<csv-transpose>

=item * L<csv2csv>

=item * L<csv2ltsv>

=item * L<csv2td>

=item * L<csv2tsv>

=item * L<csv2vcf>

=item * L<dump-csv>

=item * L<tsv2csv>

=back

=head1 FUNCTIONS


=head2 csv2td

Usage:

 csv2td(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return an enveloped aoaos table data from CSV data.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv2vcf

Usage:

 csv2vcf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Create a VCF from selected fields of the CSV.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cell_vcf_field> => I<str>

Select field to use as VCF CELL field.

=item * B<email_vcf_field> => I<str>

Select field to use as VCF EMAIL field.

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<name_vcf_field> => I<str>

Select field to use as VCF N (name) field.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_add_fields

Usage:

 csv_add_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add one or more fields to CSV file.

Examples:

=over

=item * Add a few new blank fields at the end:

 csv_add_fields(filename => "file.csv", fields => ["field4", "field6", "field5"]);

=item * Add a few new blank fields after a certain field:

 csv_add_fields(
     filename => "file.csv",
   fields   => ["field4", "field6", "field5"],
   after    => "field2"
 );

=item * Add a new field and set its value:

 csv_add_fields(
     filename => "file.csv",
   fields => ["after_tax"],
   eval => "\$main::row->[5] * 1.11"
 );

=item * Add a couple new fields and set their values:

 csv_add_fields(
     filename => "file.csv",
   fields => ["tax_rate", "after_tax"],
   eval => "(0.11, \$main::row->[5] * 1.11)"
 );

=back

The new fields by default will be added at the end, unless you specify one of
C<--after> (to put after a certain field), C<--before> (to put before a certain
field), or C<--at> (to put at specific position, 1 means the first field). The
new fields will be clustered together though, you currently cannot set the
position of each new field. But you can later reorder fields using
L<csv-sort-fields>.

If supplied, your Perl code (C<-e>) will be called for each row (excluding the
header row) and should return the value for the new fields (either as a list or
as an arrayref). C<$_> contains the current row (as arrayref, or if you specify
C<-H>, as a hashref). C<$main::row> is available and contains the current row
(always as an arrayref). C<$main::rownum> contains the row number (2 means the
first data row). C<$csv> is the L<Text::CSV_XS> object. C<$main::field_idxs> is
also available for additional information.

If C<-e> is not supplied, the new fields will be getting the default value of
empty string (C<''>).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<after> => I<str>

Put the new field after specified field.

=item * B<at> => I<int>

Put the new field at specific position (1 means first field).

=item * B<before> => I<str>

Put the new field before specified field.

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval> => I<str|code>

Perl code.

=item * B<fields>* => I<array[str]>

Field names.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_avg

Usage:

 csv_avg(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output a summary row which are arithmetic averages of data rows.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.

=item * B<with_data_rows> => I<bool>

Whether to also output data rows.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_concat

Usage:

 csv_concat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Concatenate several CSV files together, collecting all the fields.

Example, concatenating this CSV:

 col1,col2
 1,2
 3,4

and:

 col2,col4
 a,b
 c,d
 e,f

and:

 col3
 X
 Y

will result in:

 col1,col2,col4,col3
 1,2,
 3,4,
 ,a,b
 ,c,d
 ,e,f
 ,,,X
 ,,,Y

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filenames>* => I<array[filename]>

Input CSV files or URLs.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_convert_to_hash

Usage:

 csv_convert_to_hash(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return a hash of field names as keys and first row as values.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<row_number> => I<int> (default: 2)

Row number (e.g. 2 for first data row).

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_csv

Usage:

 csv_csv(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert CSV to CSV.

Why convert CSV to CSV? When you want to change separator/quote/escape
character, for one.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_delete_fields

Usage:

 csv_delete_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete one or more fields from CSV file.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<exclude_field_pat> => I<re>

Field regex pattern to exclude, takes precedence over --field-pat.

=item * B<exclude_fields> => I<array[str]>

Field names to exclude, takes precedence over --fields.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<ignore_unknown_fields> => I<bool>

When unknown fields are specified in --include-field (--field) or --exclude-field options, ignore them instead of throwing an error.

=item * B<include_field_pat> => I<re>

Field regex pattern to select, overidden by --exclude-field-pat.

=item * B<include_fields> => I<array[str]>

Field names to include, takes precedence over --exclude-field-pat.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<show_selected_fields> => I<true>

Show selected fields and then immediately exit.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_dump

Usage:

 csv_dump(%args) -> [$status_code, $reason, $payload, \%result_meta]

Dump CSV as data structure (array of arrayE<sol>hash).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_each_row

Usage:

 csv_each_row(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run Perl code for every row.

Examples:

=over

=item * Delete user data:

 csv_each_row(
     filename => "users.csv",
   eval => "\"unlink qq(/home/data/\$_->{username}.dat)\"",
   hash => 1
 );

=back

This is like csv_map, except result of code is not printed.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_fill_template

Usage:

 csv_fill_template(%args) -> [$status_code, $reason, $payload, \%result_meta]

Substitute template values in a text file with fields from CSV rows.

Templates are text that contain C<[[NAME]]> field placeholders. The field
placeholders will be replaced by values from the CSV file. This is a simple
alternative to mail-merge. (I first wrote this utility because LibreOffice
Writer, as always, has all the annoying bugs; this time, it prevents mail merge
from working.)

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<template_filename>* => I<filename>

(No description)

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_freqtable

Usage:

 csv_freqtable(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output a frequency table of values of a specified field in CSV.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<field>* => I<str>

Field name.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_get_cells

Usage:

 csv_get_cells(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get one or more cells from CSV.

This utility lets you specify "coordinates" of cell locations to extract. Each
coordinate is in the form of C<< E<lt>colE<gt>,E<lt>rowE<gt> >> where C<< E<lt>colE<gt> >> is the column name or
position (zero-based, so 0 is the first column) and C<< E<lt>rowE<gt> >> is the row position
(one-based, so 1 is the header row and 2 is the first data row).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<coordinates> => I<array[str]>

List of coordinates, each in the form of <colE<gt>,<rowE<gt> e.g. colname,0 or 1,1.

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_grep

Usage:

 csv_grep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Only output row(s) where Perl expression returns true.

Examples:

=over

=item * Only show rows where the amount field is divisible by 7:

 csv_grep(filename => "file.csv", eval => "\$_->{amount} % 7 ? 1:0", hash => 1);

=item * Only show rows where date is a Wednesday:

 csv_grep(
     filename => "file.csv",
   eval => "BEGIN { use DateTime::Format::Natural; \$parser = DateTime::Format::Natural->new } \$dt = \$parser->parse_datetime(\$_->{date}); \$dt->day_of_week == 3",
   hash => 1
 );

=back

This is like Perl's C<grep> performed over rows of CSV. In C<$_>, your Perl code
will find the CSV row as an arrayref (or, if you specify C<-H>, as a hashref).
C<$main::row> is also set to the row (always as arrayref). C<$main::rownum>
contains the row number (2 means the first data row). C<$main::csv> is the
L<Text::CSV_XS> object. C<$main::field_idxs> is also available for additional
information.

Your code is then free to return true or false based on some criteria. Only rows
where Perl expression returns true will be included in the result.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_info

Usage:

 csv_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show information about CSV file (number of rows, fields, etc).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_list_field_names

Usage:

 csv_list_field_names(%args) -> [$status_code, $reason, $payload, \%result_meta]

List field names of CSV file.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_lookup_fields

Usage:

 csv_lookup_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Fill fields of a CSV file from another.

Example input:

 # report.csv
 client_id,followup_staff,followup_note,client_email,client_phone
 101,Jerry,not renewing,
 299,Jerry,still thinking over,
 734,Elaine,renewing,
 
 # clients.csv
 id,name,email,phone
 101,Andy,andy@example.com,555-2983
 102,Bob,bob@acme.example.com,555-2523
 299,Cindy,cindy@example.com,555-7892
 400,Derek,derek@example.com,555-9018
 701,Edward,edward@example.com,555-5833
 734,Felipe,felipe@example.com,555-9067

To fill up the C<client_email> and C<client_phone> fields of C<report.csv> from
C<clients.csv>, we can use: C<--lookup-fields client_id:id --fill-fields
client_email:email,client_phone:phone>. The result will be:

 client_id,followup_staff,followup_note,client_email,client_phone
 101,Jerry,not renewing,andy@example.com,555-2983
 299,Jerry,still thinking over,cindy@example.com,555-7892
 734,Elaine,renewing,felipe@example.com,555-9067

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count> => I<bool>

Do not output rows, just report the number of rows filled.

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<fill_fields>* => I<str>

(No description)

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<lookup_fields>* => I<str>

(No description)

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<source>* => I<filename>

CSV file to lookup values from.

=item * B<target>* => I<filename>

CSV file to fill fields of.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_map

Usage:

 csv_map(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return result of Perl code for every row.

Examples:

=over

=item * Create SQL insert statements (escaping is left as an exercise for users):

 csv_map(
     filename => "file.csv",
   eval => "\"INSERT INTO mytable (id,amount) VALUES (\$_->{id}, \$_->{amount});\"",
   hash => 1
 );

=back

This is like Perl's C<map> performed over rows of CSV. In C<$_>, your Perl code
will find the CSV row as an arrayref (or, if you specify C<-H>, as a hashref).
C<$main::row> is also set to the row (always as arrayref). C<$main::rownum>
contains the row number (2 means the first data row). C<$main::csv> is the
L<Text::CSV_XS> object. C<$main::field_idxs> is also available for additional
information.

Your code is then free to return a string based on some operation against these
data. This utility will then print out the resulting string.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_newline> => I<bool> (default: 1)

Whether to make sure each string ends with newline.

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_munge_field

Usage:

 csv_munge_field(%args) -> [$status_code, $reason, $payload, \%result_meta]

Munge a field in every row of CSV file with Perl code.

Perl code (-e) will be called for each row (excluding the header row) and C<$_>
will contain the value of the field, and the Perl code is expected to modify it.
C<$main::row> will contain the current row array. C<$main::rownum> contains the
row number (2 means the first data row). C<$main::csv> is the L<Text::CSV_XS>
object. C<$main::field_idxs> is also available for additional information.

To munge multiple fields, use L<csv-munge-row>.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<field>* => I<str>

Field name.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_munge_row

Usage:

 csv_munge_row(%args) -> [$status_code, $reason, $payload, \%result_meta]

Munge each data arow of CSV file with Perl code.

Perl code (-e) will be called for each row (excluding the header row) and C<$_>
will contain the row (arrayref, or hashref if C<-H> is specified). The Perl code
is expected to modify it.

Aside from C<$_>, C<$main::row> will contain the current row array.
C<$main::rownum> contains the row number (2 means the first data row).
C<$main::csv> is the L<Text::CSV_XS> object. C<$main::field_idxs> is also
available for additional information.

The modified C<$_> will be rendered back to CSV row.

You can also munge a single field using L<csv-munge-field>.

You cannot add new fields using this utility. To do so, use
L<csv-add-fields>.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_pick_fields

Usage:

 csv_pick_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select one or more random fields from CSV.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<num> => I<posint> (default: 1)

Number of fields to pick.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_pick_rows

Usage:

 csv_pick_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return one or more random rows from CSV.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<num> => I<posint> (default: 1)

Number of rows to pick.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_replace_newline

Usage:

 csv_replace_newline(%args) -> [$status_code, $reason, $payload, \%result_meta]

Replace newlines in CSV values.

Some CSV parsers or applications cannot handle multiline CSV values. This
utility can be used to convert the newline to something else. There are a few
choices: replace newline with space (C<--with-space>, the default), remove
newline (C<--with-nothing>), replace with encoded representation
(C<--with-backslash-n>), or with characters of your choice (C<--with 'blah'>).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.

=item * B<with> => I<str> (default: " ")

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_select_fields

Usage:

 csv_select_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Only output selected field(s).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<exclude_field_pat> => I<re>

Field regex pattern to exclude, takes precedence over --field-pat.

=item * B<exclude_fields> => I<array[str]>

Field names to exclude, takes precedence over --fields.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<ignore_unknown_fields> => I<bool>

When unknown fields are specified in --include-field (--field) or --exclude-field options, ignore them instead of throwing an error.

=item * B<include_field_pat> => I<re>

Field regex pattern to select, overidden by --exclude-field-pat.

=item * B<include_fields> => I<array[str]>

Field names to include, takes precedence over --exclude-field-pat.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<show_selected_fields> => I<true>

Show selected fields and then immediately exit.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_select_rows

Usage:

 csv_select_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Only output specified row(s).

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<row_spec>* => I<str>

Row number (e.g. 2 for first data row), range (2-7), or comma-separated list of such (2-7,10,20-23).

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_setop

Usage:

 csv_setop(%args) -> [$status_code, $reason, $payload, \%result_meta]

Set operation (unionE<sol>unique concatenation of rows, intersectionE<sol>common rows, difference of rows) against several CSV files.

Example input:

 # file1.csv
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 
 # file2.csv
 a,b,c
 1,2,3
 4,5,7
 7,8,9

Output of intersection (C<--intersect file1.csv file2.csv>), which will return
common rows between the two files:

 a,b,c
 1,2,3
 7,8,9

Output of union (C<--union file1.csv file2.csv>), which will return all rows with
duplicate removed:

 a,b,c
 1,2,3
 4,5,6
 4,5,7
 7,8,9

Output of difference (C<--diff file1.csv file2.csv>), which will return all rows
in the first file but not in the second:

 a,b,c
 4,5,6

Output of symmetric difference (C<--symdiff file1.csv file2.csv>), which will
return all rows in the first file not in the second, as well as rows in the
second not in the first:

 a,b,c
 4,5,6
 4,5,7

You can specify C<--compare-fields> to only consider some fields only, for
example C<--union --compare-fields a,b file1.csv file2.csv>:

 a,b,c
 1,2,3
 4,5,6
 7,8,9

Each field specified in C<--compare-fields> can be specified using
C<F1:OTHER1,F2:OTHER2,...> format to refer to different field names or indexes in
each file, for example if C<file3.csv> is:

 # file3.csv
 Ei,Si,Bi
 1,3,2
 4,7,5
 7,9,8

Then C<--union --compare-fields a:Ei,b:Bi file1.csv file3.csv> will result in:

 a,b,c
 1,2,3
 4,5,6
 7,8,9

Finally you can print out certain fields using C<--result-fields>.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<compare_fields> => I<str>

(No description)

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filenames>* => I<array[filename]>

Input CSV files or URLs.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<op>* => I<str>

Set operation to perform.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<result_fields> => I<str>

(No description)

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_shuf_fields

Usage:

 csv_shuf_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Shuffle CSV fields.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_shuf_rows

Usage:

 csv_shuf_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Shuffle CSV rows.

This is basically like Unix command C<shuf> except it does not shuffle the header
row.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_sort_fields

Usage:

 csv_sort_fields(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort CSV fields.

This utility sorts the order of fields in the CSV. Example input CSV:

 b,c,a
 1,2,3
 4,5,6

Example output CSV:

 a,b,c
 3,1,2
 6,4,5

You can also reverse the sort order (C<-r>), sort case-insensitively (C<-i>), or
provides the ordering example, e.g. C<--by-examples-json '["a","c","b"]'>, or use
C<--by-code> or C<--by-sortsub>.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if C<--hash> (C<-H>) is specified, hashrefs; or
if C<--key> is specified, whatever the code in C<--key> returns.

=item * B<by_examples> => I<array[str]>

A list of field names to sort by example.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<reverse> => I<bool>

(No description)

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<sortsub_args> => I<hash>

Arguments to pass to Sort::Sub routine.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_sort_rows

Usage:

 csv_sort_rows(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort CSV rows.

This utility sorts the rows in the CSV. Example input CSV:

 name,age
 Andy,20
 Dennis,15
 Ben,30
 Jerry,30

Example output CSV (using C<--by-field +age> which means by age numerically and
ascending):

 name,age
 Dennis,15
 Andy,20
 Ben,30
 Jerry,30

Example output CSV (using C<--by-field -age>, which means by age numerically and
descending):

 name,age
 Ben,30
 Jerry,30
 Andy,20
 Dennis,15

Example output CSV (using C<--by-field name>, which means by name ascibetically
and ascending):

 name,age
 Andy,20
 Ben,30
 Dennis,15
 Jerry,30

Example output CSV (using C<--by-field ~name>, which means by name ascibetically
and descending):

 name,age
 Jerry,30
 Dennis,15
 Ben,30
 Andy,20

Example output CSV (using C<--by-field +age --by-field ~name>):

 name,age
 Dennis,15
 Andy,20
 Jerry,30
 Ben,30

You can also reverse the sort order (C<-r>) or sort case-insensitively (C<-i>).

For more flexibility, instead of C<--by-field> you can use C<--by-code>:

Example output C<< --by-code '$a-E<gt>[1] E<lt>=E<gt> $b-E<gt>[1] || $b-E<gt>[0] cmp $a-E<gt>[0]' >> (which
is equivalent to C<--by-field +age --by-field ~name>):

 name,age
 Dennis,15
 Andy,20
 Jerry,30
 Ben,30

If you use C<--hash>, your code will receive the rows to be compared as hashref,
e.g. `--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

A third alternative is to sort using L<Sort::Sub> routines. Example output
(using C<< --by-sortsub 'by_lengthE<lt>rE<gt>' --key '$_-E<gt>[0]' >>, which is to say to sort by
descending length of name):

 name,age
 Dennis,15
 Jerry,30
 Andy,20
 Ben,30

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Sort using Perl code.

C<$a> and C<$b> (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if C<--hash> (C<-H>) is specified, hashrefs; or
if C<--key> is specified, whatever the code in C<--key> returns.

=item * B<by_fields> => I<array[str]>

Sort by a list of field specifications.

Each field specification is a field name with an optional prefix. C<FIELD>
(without prefix) means sort asciibetically ascending (smallest to largest),
C<~FIELD> means sort asciibetically descending (largest to smallest), C<+FIELD>
means sort numerically ascending, C<-FIELD> means sort numerically descending.

=item * B<by_sortsub> => I<str>

Sort using a Sort::Sub routine.

When sorting rows, usually combined with C<--key> because most Sort::Sub routine
expects a string to be compared against.

When sorting fields, the Sort::Sub routine will get the field name as argument.

=item * B<ci> => I<bool>

(No description)

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<key> => I<str|code>

Generate sort keys with this Perl code.

If specified, then will compute sort keys using Perl code and sort using the
keys. Relevant when sorting using C<--by-code> or C<--by-sortsub>. If specified,
then instead of row when sorting rows, the code (or Sort::Sub routine) will
receive these sort keys to sort against.

Tthe code will receive the row (arrayref) as the argument.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<reverse> => I<bool>

(No description)

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<sortsub_args> => I<hash>

Arguments to pass to Sort::Sub routine.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_split

Usage:

 csv_split(%args) -> [$status_code, $reason, $payload, \%result_meta]

Split CSV file into several files.

Will output split files xaa, xab, and so on. Each split file will contain a
maximum of C<lines> rows (options to limit split files' size based on number of
characters and bytes will be added). Each split file will also contain CSV
header.

Warning: by default, existing split files xaa, xab, and so on will be
overwritten.

Interface is loosely based on the C<split> Unix utility.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<lines> => I<uint> (default: 1000)

(No description)

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_sum

Usage:

 csv_sum(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output a summary row which are arithmetic sums of data rows.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.

=item * B<with_data_rows> => I<bool>

Whether to also output data rows.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 csv_transpose

Usage:

 csv_transpose(%args) -> [$status_code, $reason, $payload, \%result_meta]

Transpose a CSV.

I<Common notes for the utilities>

Encoding: The utilities in this module/distribution accept and emit UTF8 text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<escape_char> => I<str>

Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS.

Defaults to C<\\> (backslash). Overrides C<--tsv> option.

=item * B<filename>* => I<filename>

Input CSV file or URL.

Use C<-> to read from stdin, use C<clipboard:> to read from clipboard.

=item * B<header> => I<bool> (default: 1)

Whether input CSV has a header row.

By default (C<--header>), the first row of the CSV will be assumed to contain
field names (and the second row contains the first data row). When you declare
that CSV does not have header row (C<--no-header>), the first row of the CSV is
assumed to contain the first data row. Fields will be named C<field1>, C<field2>,
and so on.

=item * B<output_escape_char> => I<str>

Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS.

This is like C<--escape-char> option but for output instead of input.

Defaults to C<\\> (backslash). Overrides C<--output-tsv> option.

=item * B<output_filename> => I<filename>

Output filename or URL.

Use C<-> to output to stdout (the default if you don't specify this option), use
C<clipboard:> to write to clipboard.

=item * B<output_header> => I<bool>

Whether output CSV should have a header row.

By default, a header row will be output I<if> input CSV has header row. Under
C<--output-header>, a header row will be output even if input CSV does not have
header row (value will be something like "col0,col1,..."). Under
C<--no-output-header>, header row will I<not> be printed even if input CSV has
header row. So this option can be used to unconditionally add or remove header
row.

=item * B<output_quote_char> => I<str>

Specify field quote character in output CSV, will be passed to Text::CSV_XS.

This is like C<--quote-char> option but for output instead of input.

Defaults to C<"> (double quote). Overrides C<--output-tsv> option.

=item * B<output_sep_char> => I<str>

Specify field separator character in output CSV, will be passed to Text::CSV_XS.

This is like C<--sep-char> option but for output instead of input.

Defaults to C<,> (comma). Overrides C<--output-tsv> option.

=item * B<output_tsv> => I<bool>

Inform that output file is TSV (tab-separated) format instead of CSV.

This is like C<--tsv> option but for output instead of input.

Overriden by C<--output-sep-char>, C<--output-quote-char>, C<--output-escape-char>
options. If one of those options is specified, then C<--output-tsv> will be
ignored.

=item * B<overwrite> => I<bool>

Whether to override existing output file.

=item * B<quote_char> => I<str>

Specify field quote character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<"> (double quote). Overrides C<--tsv> option.

=item * B<sep_char> => I<str>

Specify field separator character in input CSV, will be passed to Text::CSV_XS.

Defaults to C<,> (comma). Overrides C<--tsv> option.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

Overriden by C<--sep-char>, C<--quote-char>, C<--escape-char> options. If one of
those options is specified, then C<--tsv> will be ignored.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(csvutil)$

=head1 FAQ

=head2 My CSV does not have a header?

Use the C<--no-header> option. Fields will be named C<field1>, C<field2>, and so
on.

=head2 My data is TSV, not CSV?

Use the C<--tsv> option.

=head2 I have a big CSV and the utilities are too slow or eat too much RAM!

These utilities are not (yet) optimized, patches welcome. If your CSV is very
big, perhaps a C-based solution is what you need.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSVUtils>.

=head1 SEE ALSO

=head2 Similar CLI bundles for other format

L<App::TSVUtils>, L<App::LTSVUtils>, L<App::SerializeUtils>.

=head2 Other CSV-related utilities

L<xls2csv> and L<xlsx2csv> from L<Spreadsheet::Read>

L<import-csv-to-sqlite> from L<App::SQLiteUtils>

Query CSV with SQL using L<fsql> from L<App::fsql>

L<csvgrep> from L<csvgrep>

=head2 Other non-Perl-based CSV utilities

=head3 Python

B<csvkit>, L<https://csvkit.readthedocs.io/en/latest/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Adam Hopkins

Adam Hopkins <violapiratejunky@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
