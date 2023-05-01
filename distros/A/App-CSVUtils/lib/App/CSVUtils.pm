package App::CSVUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Cwd;
use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-31'; # DATE
our $DIST = 'App-CSVUtils'; # DIST
our $VERSION = '1.023'; # VERSION

our @EXPORT_OK = qw(
                       gen_csv_util
                       compile_eval_code
                       eval_code
               );

our %SPEC;

our $sch_req_str_or_code = ['any*', of=>['str*', 'code*']];

sub _open_file_read {
    my $filename = shift;

    my ($fh, $err);
    if ($filename eq '-') {
        $fh = *STDIN;
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

sub _open_file_write {
    my $filename = shift;

    my ($fh, $err);
    if ($filename eq '-') {
        $fh = *STDOUT;
    } else {
        open $fh, ">", $filename or do {
            $err = [500, "Can't open output filename '$filename': $!"];
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

    my $fh;
    if ($filename eq '-') {
        $fh = \*STDOUT;
    } else {
        if (-f $filename) {
            if ($overwrite) {
                log_info "[csvutil] Overwriting output file $filename";
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

sub compile_eval_code {
    return $_[0] if ref $_[0] eq 'CODE';
    my ($str, $label) = @_;
    defined($str) && length($str) or die [400, "Please specify code ($label)"];
    $str = "package main; no strict; no warnings; sub { $str }";
    log_trace "[csvutil] Compiling Perl code: $str";
    my $code = eval $str; ## no critic: BuiltinFunctions::ProhibitStringyEval
    die [400, "Can't compile code ($label) '$str': $@"] if $@;
    $code;
}

sub eval_code {
    no warnings 'once';
    my ($code, $r, $value_for_topic, $return_topic) = @_;
    local $_ = $value_for_topic;
    local $main::r = $r;
    local $main::row = $r->{input_row};
    local $main::rownum = $r->{input_rownum};
    local $main::data_rownum = $r->{input_data_rownum};
    local $main::csv = $r->{input_parser};
    local $main::fields_idx = $r->{input_fields_idx};
    if ($return_topic) {
        $code->($_);
        $_;
    } else {
        $code->($_);
    }
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
    } elsif ($args->{"${prefix}tsv"}) {
        $tcsv_opts{"sep_char"}    = "\t";
        $tcsv_opts{"quote_char"}  = undef;
        $tcsv_opts{"escape_char"} = undef;
    }
    $tcsv_opts{always_quote} = 1 if $args->{"${prefix}always_quote"};
    $tcsv_opts{quote_empty} = 1 if $args->{"${prefix}quote_empty"};

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
    return {message=>"Please specify input filename first"} unless defined $args && $args->{input_filename};

    # user wants to read CSV from stdin, bail
    return {message=>"Can't get field list when input is stdin"} if $args->{input_filename} eq '-';

    # can the file be opened?
    my $csv_parser = _instantiate_parser(\%args, 'input_');
    open my($fh), "<encoding(utf8)", $args->{input_filename} or do {
        #warn "csvutils: Cannot open file '$args->{input_filename}': $!\n";
        return [];
    };

    # can the header row be read?
    my $row = $csv_parser->getline($fh) or return [];

    if (defined $args->{input_header} && !$args->{input_header}) {
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

# check that the first N values of a field are all defined and numeric. if there
# are now rows or less than N values, return true.
sub _is_numeric_field {
    require Scalar::Util::Numeric;

    my ($rows, $field_idx, $num_samples) = @_;
    $num_samples //= 5;

    my $is_numeric = 1;
    for my $row (@$rows) {
        my $val = $row->[$field_idx];
        return 0 unless defined $val;
        return 0 unless Scalar::Util::Numeric::isnum($val);
    }
    $is_numeric;
}

# find a single field by name or index (1-based), return index (0-based). die
# when requested field does not exist.
sub _find_field {
    my ($fields, $name_or_idx) = @_;

    # search by name first
    for my $i (0 .. $#{$fields}) {
        my $field = $fields->[$i];
        return $i if $field eq $name_or_idx;
    }

    if ($name_or_idx eq '0') {
        die [400, "Field index 0 is requested, you probably meant 1 for the first field?"];
    } elsif ($name_or_idx =~ /\A[1-9][0-9]*\z/) {
        if ($name_or_idx > @$fields) {
            die [400, "There are only ".scalar(@$fields)." field(s) but field index $name_or_idx is requested"];
        } else {
            return $name_or_idx-1;
        }
    } elsif ($name_or_idx =~ /\A-[1-9][0-9]*\z/) {
        if (-$name_or_idx > @$fields) {
            die [400, "There are only ".scalar(@$fields)." field(s) but field index $name_or_idx is requested"];
        } else {
            return @$fields + $name_or_idx;
        }
    }

    # not found
    die [404, "Unknown field name/index '$name_or_idx' (known fields include: ".
         join(", ", map { "'$_'" } @$fields).")"];
}

# select one or more fields with options like --include-field, etc
sub _select_fields {
    my ($fields, $field_idxs, $args, $default_select_choice) = @_;

    my @selected_fields;

    my $select_field_options_used;

    if (defined $args->{include_field_pat}) {
        $select_field_options_used++;
        for my $field (@$fields) {
            if ($field =~ $args->{include_field_pat}) {
                push @selected_fields, $field;
            }
        }
    }
    if (defined $args->{exclude_field_pat}) {
        $select_field_options_used++;
        @selected_fields = grep { $_ !~ $args->{exclude_field_pat} }
            @selected_fields;
    }
    if (defined $args->{include_fields}) {
        $select_field_options_used++;
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
        $select_field_options_used++;
      FIELD:
        for my $field (@{ $args->{exclude_fields} }) {
            unless (defined $field_idxs->{$field}) {
                return [400, "Unknown field '$field'"] unless $args->{ignore_unknown_fields};
                next FIELD;
            }
            @selected_fields = grep { $field ne $_ } @selected_fields;
        }
    }

    if (!$select_field_options_used && $default_select_choice) {
        if ($default_select_choice eq 'all') {
            @selected_fields = @$fields;
        } elsif ($default_select_choice eq 'first') {
            @selected_fields = ($fields->[0]) if @$fields;
        } elsif ($default_select_choice eq 'last') {
            @selected_fields = ($fields->[-1]) if @$fields;
        } elsif ($default_select_choice eq 'first-if-only-field') {
            @selected_fields = ($fields->[0]) if @$fields == 1;
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

our $xcomp_csvfiles = [filename => {file_ext_filter => qr/^[tc]sv$/i}];

our %argspecs_csv_input = (
    input_header => {
        summary => 'Specify whether input CSV has a header row',
        'summary.alt.bool.not' => 'Specify that input CSV does not have a header row',
        schema => 'bool*',
        default => 1,
        description => <<'_',

By default, the first row of the input CSV will be assumed to contain field
names (and the second row contains the first data row). When you declare that
input CSV does not have header row (`--no-input-header`), the first row of the
CSV is assumed to contain the first data row. Fields will be named `field1`,
`field2`, and so on.

_
        cmdline_aliases => {
        },
        tags => ['category:input'],
    },
    input_tsv => {
        summary => "Inform that input file is in TSV (tab-separated) format instead of CSV",
        schema => 'true*',
        description => <<'_',

Overriden by `--input-sep-char`, `--input-quote-char`, `--input-escape-char`
options. If one of those options is specified, then `--input-tsv` will be
ignored.

_
        tags => ['category:input'],
    },
    input_sep_char => {
        summary => 'Specify field separator character in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `,` (comma). Overrides `--input-tsv` option.

_
        tags => ['category:input'],
    },
    input_quote_char => {
        summary => 'Specify field quote character in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `"` (double quote). Overrides `--input-tsv` option.

_
        tags => ['category:input'],
    },
    input_escape_char => {
        summary => 'Specify character to escape value in field in input CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

Defaults to `\\` (backslash). Overrides `--input-tsv` option.

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

This is like `--input-tsv` option but for output instead of input.

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

This is like `--input-sep-char` option but for output instead of input.

Defaults to `,` (comma). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
    output_quote_char => {
        summary => 'Specify field quote character in output CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

This is like `--input-quote-char` option but for output instead of input.

Defaults to `"` (double quote). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
    output_escape_char => {
        summary => 'Specify character to escape value in field in output CSV, will be passed to Text::CSV_XS',
        schema => ['str*', len=>1],
        description => <<'_',

This is like `--input-escape-char` option but for output instead of input.

Defaults to `\\` (backslash). Overrides `--output-tsv` option.

_
        tags => ['category:output'],
    },
    output_always_quote => {
        summary => 'Whether to always quote values',
        schema => 'bool*',
        default => 0,
        description => <<'_',

When set to false (the default), values are quoted only when necessary:

    field1,field2,"field three contains comma (,)",field4

When set to true, then all values will be quoted:

    "field1","field2","field three contains comma (,)","field4"

_
        tags => ['category:output'],
    },
    output_quote_empty => {
        summary => 'Whether to quote empty values',
        schema => 'bool*',
        default => 0,
        description => <<'_',

When set to false (the default), empty values are not quoted:

    field1,field2,,field4

When set to true, then empty values will be quoted:

    field1,field2,"",field4

_
        tags => ['category:output'],
    },
);

our %argspecopt_input_filename = (
    input_filename => {
        summary => 'Input CSV file',
        description => <<'_',

Use `-` to read from stdin.

Encoding of input file is assumed to be UTF-8.

_
        schema => 'filename*',
        default => '-',
        'x.completion' => $xcomp_csvfiles,
        tags => ['category:input'],
    },
);

our %argspecopt_input_filenames = (
    input_filenames => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'input_filename',
        summary => 'Input CSV files',
        description => <<'_',

Use `-` to read from stdin.

Encoding of input file is assumed to be UTF-8.

_
        schema => ['array*', of=>'filename*'],
        default => ['-'],
        'x.completion' => $xcomp_csvfiles,
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

our %argspecsopt_inplace = (
    inplace => {
        summary => 'Output to the same file as input',
        schema => 'true*',
        description => <<'_',

Normally, you output to a different file than input. If you try to output to the
same file (`-o INPUT.csv -O`) you will clobber the input file; thus the utility
prevents you from doing it. However, with this `--inplace` option, you can
output to the same file. Like perl's `-i` option, this will first output to a
temporary file in the same directory as the input file then rename to the final
file at the end. You cannot specify output file (`-o`) when using this option,
but you can specify backup extension with `-b` option.

Some caveats:

- if input file is a symbolic link, it will be replaced with a regular file;
- renaming (implemented using `rename()`) can fail if input filename is too long;
- value specified in `-b` is currently not checked for acceptable characters;
- things can also fail if permissions are restrictive;

_
        tags => ['category:output'],
    },
    inplace_backup_ext => {
        summary => 'Extension to add for backup of input file',
        schema => 'str*',
        default => '',
        description => <<'_',

In inplace mode (`--inplace`), if this option is set to a non-empty string, will
rename the input file using this extension as a backup. The old existing backup
will be overwritten, if any.

_
        cmdline_aliases => {b=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_output_filename = (
    output_filename => {
        summary => 'Output filename',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option).

Encoding of output file is assumed to be UTF-8.

_
        schema => 'filename*',
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_output_filenames = (
    output_filenames => {
        summary => 'Output filenames',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option).

Encoding of output file is assumed to be UTF-8.

_
        schema => ['array*', of=>'filename*'],
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_field = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { f=>{} },
        completion => \&_complete_field,
    },
);

our %argspecopt_field_1 = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        pos => 1,
        cmdline_aliases => { f=>{} },
        completion => \&_complete_field,
    },
);

our %argspec_field_1 = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { f=>{} },
        req => 1,
        pos => 1,
        completion => \&_complete_field,
    },
);

our %argspec_fields_1plus = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        summary => 'Field names',
        schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        req => 1,
        pos => 1,
        slurpy => 1,
        cmdline_aliases => {f=>{}},
        element_completion => \&_complete_field,
    },
);

# without completion, for adding new field
our %argspec_field_1_nocomp = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { f=>{} },
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
        cmdline_aliases => { f=>{} },
        req => 1,
        pos => 1,
        slurpy => 1,
    },
);

our %argspec_fields = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        summary => 'Field names',
        schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        req => 1,
        cmdline_aliases => {f=>{}},
        element_completion => \&_complete_field,
    },
);

our %argspecopt_fields = (
    fields => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'field',
        summary => 'Field names',
        schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        cmdline_aliases => {f=>{}},
        element_completion => \&_complete_field,
    },
);

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
            a => { summary => 'Shortcut for --field-pat=.*, effectively selecting all fields', is_flag=>1, code => sub { $_[0]{include_field_pat} = '.*' } },
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
            exclude_all_fields => { summary => 'Shortcut for --exclude-field-pat=.*, effectively excluding all fields', is_flag=>1, code => sub { $_[0]{exclude_field_pat} = '.*' } },
            A => { summary => 'Shortcut for --exclude-field-pat=.*, effectively excluding all fields', is_flag=>1, code => sub { $_[0]{exclude_field_pat} = '.*' } },
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

The code will receive the row (arrayref, or if -H is specified, hashref) as the
argument.

_
        schema => $sch_req_str_or_code,
        cmdline_aliases => {k=>{}},
    },
);

our %argspecs_sort_rows = (
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
    by_code => {
        summary => 'Sort by using Perl code',
        schema => $sch_req_str_or_code,
        description => <<'_',

`$a` and `$b` (or the first and second argument) will contain the two rows to be
compared. Which are arrayrefs; or if `--hash` (`-H`) is specified, hashrefs; or
if `--key` is specified, whatever the code in `--key` returns.

_
    },
    %argspecopt_key,
    %argspecsopt_sortsub,
);

our %argspecs_sort_fields = (
    reverse => {
        schema => ['bool', is=>1],
        cmdline_aliases => {r=>{}},
    },
    ci => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    by_examples => {
        summary => 'Sort by a list of field names as examples',
        'summary.alt.plurality.singular' => 'Add a field to sort by example',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'by_example',
        schema => ['array*', of=>'str*'],
        element_completion => \&_complete_field,
    },
    by_code => {
        summary => 'Sort fields using Perl code',
        schema => $sch_req_str_or_code,
        description => <<'_',

`$a` and `$b` (or the first and second argument) will contain `[$field_name,
$field_idx]`.

_
    },
    %argspecsopt_sortsub,
);

our %argspecopt_with_data_rows = (
    with_data_rows => {
        summary => 'Whether to also output data rows',
        schema => 'bool',
    },
);

our %argspecopt_hash = (
    hash => {
        summary => 'Provide row in $_ as hashref instead of arrayref',
        schema => ['bool*', is=>1],
        cmdline_aliases => {H=>{}},
    },
);

# add a position to specified argument, if possible
sub _add_arg_pos {
    my ($args, $argname, $is_slurpy) = @_;

    # argument already has a position, return
    return if defined $args->{$argname}{pos};

    # position of slurpy argument
    my $slurpy_pos;
    for (keys %$args) {
        next unless $args->{$_}{slurpy};
        $slurpy_pos = $args->{$_}{pos};
        last;
    }

    # there is already a slurpy arg, return
    return if $is_slurpy && defined $slurpy_pos;

    # find the lowest position that's not available
  ARG:
    for my $j (0 .. scalar(keys %$args)-1) {
        last if defined $slurpy_pos && $j >= $slurpy_pos;
        for (keys %$args) {
            next ARG if defined $args->{$_}{pos} && $args->{$_}{pos} == $j;
        }
        $args->{$argname}{pos} = $j;
        $args->{$argname}{slurpy} = 1 if $is_slurpy;
        last;
    }
}

sub _randext {
    state $charset = [0..9, "A".."Z","a".."z"];
    my $len = shift;
    my $ext = "";
    for (1..$len) { $ext .= $charset->[rand @$charset] }
    $ext;
}

$SPEC{gen_csv_util} = {
    v => 1.1,
    summary => 'Generate a CSV utility',
    description => <<'_',

This routine is used to generate a CSV utility in the form of a <pm:Rinci>
function (code and metadata). You can then produce a CLI from the Rinci function
simply using <pm:Perinci::CmdLine::Gen> or, if you use <pm:Dist::Zilla>,
<pm:Dist::Zilla::Plugin::GenPericmdScript> or, if on the command-line,
<prog:gen-pericmd-script>.

Using this routine, by providing just one or a few hooks and setting some
parameters like a couple of extra arguments, you will get a complete CLI with
decent POD/manpage, ability to read one or multiple CSV's and write one or
multiple CSV's, some command-line options to customize how the input CSV's
should be parsed and how the output CSV's should be formatted and named. Your
CLI also has tab completion, usage and help message, and other features.

To create a CSV utility, you specify a `name` (e.g. `csv_dump`; must be a valid
unqualified Perl identifier/function name) and optionally `summary`,
`description`, and other metadata like `links` or even `add_meta_props`. Then
you specify one or more of `on_*` or `before_*` or `after_*` arguments to supply
handlers (coderefs) for your CSV utility at various hook points.


*THE HOOKS*

All code for hooks should accept a single argument `r`. `r` is a stash (hashref)
of various data, the keys of which will depend on which hook point being called.
You can also add more keys to store data or for flow control (see hook
documentation below for more details).

The order of the hooks, in processing chronological order:

* on_begin

  Called when utility begins, before reading CSV. You can use this hook e.g. to
  process arguments, set output filenames (if you allow custom output
  filenames).

* before_read_input

  Called before opening any input CSV file. This hook is *still* called even if
  your utility sets `reads_csv` to false.

  At this point, the `input_filenames` stash key (as well as other keys like
  `input_filename`, `input_filenum`, etc) has not been set. You can use this
  hook e.g. to set a custom `input_filenames`.

* before_open_input_files

  Called before an input CSV file is about to be opened, including for stdin
  (`-`). You can use this hook e.g. to check/preprocess input file. Flow control
  is available by setting `$r->{wants_skip_files}` to skip reading all the input
  file and go directly to the `after_read_input` hook.

* before_open_input_file

  Called before an input CSV file is about to be opened, including for stdin
  (`-`). For the first file, called after `before_open_input_file` hook. You can
  use this hook e.g. to check/preprocess input file. Flow control is available
  by setting `$r->{wants_skip_file}` to skip reading a single input file and go
  to the next file, or `$r->{wants_skip_files}` to skip reading the rest of the
  files and go directly to the `after_read_input` hook.

* on_input_header_row

  Called when receiving header row. Will be called for every input file, and
  called even when user specify `--no-input-header`, in which case the header
  row will be the generated `["field1", "field2", ...]`. You can use this hook
  e.g. to add/remove/rearrange fields.

  You can set `$r->{wants_fill_rows}` to a defined false if you do not want
  `$r->{input_rows}` to be filled with empty string elements when it contains
  less than the number of fields (in case of sparse values at the end). Normally
  you only want to do this when you want to do checking, e.g. in
  <prog:csv-check-rows>.

* on_input_data_row

  Called when receiving each data row. You can use this hook e.g. to modify the
  row or print output (for line-by-line transformation or filtering).

* after_close_input_file

  Called after each input file is closed, including for stdin (`-`) (although
  for stdin, the handle is not actually closed). Flow control is possible by
  setting `$r->{wants_skip_files}` to skip reading the rest of the files and go
  straight to the `after_close_input_files` hook.

* after_close_input_files

  Called after the last input file is closed, after the last
  `after_close_input_file` hook, including for stdin (`-`) (although for stdin,
  the handle is not actually closed).

* after_read_input

  Called after the last row of the last CSV file is read and the last file is
  closed. This hook is *still* called, if you set `reads_csv` option to false.
  At this point the stash keys related to CSV reading have all been cleared,
  including `input_filenames`, `input_filename`, `input_fh`, etc.

  You can use this hook e.g. to print output if you buffer the output.

* on_end

  Called when utility is about to exit. You can use this hook e.g. to return the
  final result.


*THE STASH*

The common keys that `r` will contain:

- `gen_args`, hash. The arguments used to generate the CSV utility.

- `util_args`, hash. The arguments that your CSV utility accepts. Parsed from
  command-line arguments (or configuration files, or environment variables).

- `name`, str. The name of the CSV utility. Which can also be retrieved via
  `gen_args`.

- `code_print`, coderef. Routine provided for you to print something. Accepts a
  string. Takes care of opening the output files for you.

- `code_print_row`, coderef. Routine provided for you to print a data row. You
  pass the row (either arrayref or hashref). Takes care of opening the output
  files for you, as well as printing header row the first time, if needed.

- `code_print_header_row`, coderef. Routine provided for you to print header
  row. You don't need to pass any arguments. Will only print the header row once
  per output file if output header is enabled, even if called multiple times.

If you are accepting CSV data (`reads_csv` gen argument set to true), the
following keys will also be available (in `on_input_header_row` and
`on_input_data_row` hooks):

- `input_parser`, a <pm:Text::CSV_XS> instance for input parsing.

- `input_filenames`, array of str.

- `input_filename`, str. The name of the current input file being read (`-` if
  reading from stdin).

- `input_filenum`, uint. The number of the current input file, 1 being the first
  file, 2 for the second, and so on.

- `input_fh`, the handle to the current file being read.

- `input_rownum`, uint. The number of rows that have been read (reset after each
  input file). In `on_input_header_row` phase, this will be 1 since header row
  (including the generated one) is the first row. Then in `on_input_data_row`
  phase (called the first time for a file), it will be 2 for the first data row,
  even if physically it is the first row for CSV file that does not have a
  header.

- `input_data_rownum`, uint. The number of data rows that have been read (reset
  after each input file). This will be equal to `input_rownum` less 1 if input
  file has header.

- `input_row`, aos (array of str). The current input CSV row as an arrayref.

- `input_row_as_hashref`, hos (hash of str). The current input CSV row as a
  hashref, with field names as hash keys and field values as hash values. This
  will only be calculated if utility wants it. Utility can express so by setting
  `$r->{wants_input_row_as_hashref}` to true, e.g. in the `on_begin` hook.

- `input_header_row_count`, uint. Contains the number of actual header rows that
  have been read. If CLI user specifies `--no-input-header`, this will stay at
  zero. Will be reset for each CSV file.

- `input_data_row_count`, int. Contains the number of actual data rows that have
  read. Will be reset for each CSV file.

If you are outputting CSV (`writes_csv` gen argument set to true), the following
keys will be available:

- `output_emitter`, a <pm:Text::CSV_XS> instance for output.

- `output_filenames`, array of str.

- `output_filename`, str, name of current output file.

- `output_filenum`, uint, the number of the current output file, 1 being the
  first file, 2 for the second, and so on.

- `output_fh`, handle to the current output file.

- `output_rownum`, uint. The number of rows that have been outputted (reset
  after each output file).

- `output_data_rownum`, uint. The number of data rows that have been outputted
  (reset after each output file). This will be equal to `input_rownum` less 1 if
  input file has header.

For other hook-specific keys, see the documentation for associated hook point.


*ACCEPTING ADDITIONAL COMMAND-LINE OPTIONS/ARGUMENTS*

As mentioned above, you will get additional command-line options/arguments in
`$r->{util_args}` hashref. Some options/arguments are already added by
`gen_csv_util`, e.g. `input_filename` or `input_filenames` along with
`input_sep_char`, etc (when your utility declares `reads_csv`),
`output_filename` or `output_filenames` along with `overwrite`,
`output_sep_char`, etc (when your utility declares `writes_csv`).

If you want to accept additional arguments/options, you specify them in
`add_args` (hashref, with key being Each option/argument has to be specified
first via `add_args` (as hashref, with key being argument name and value the
argument specification as defined in <pm:Rinci::function>)). Some argument
specifications have been defined in <pm:App::CSVUtils> and can be used. See
existing utilities for examples.


*READING CSV DATA*

To read CSV data, normally your utility would provide handler for the
`on_input_data_row` hook and sometimes additionally `on_input_header_row`.


*OUTPUTTING STRING OR RETURNING RESULT*

To output string, usually you call the provided routine `$r->{code_print}`. This
routine will open the output files for you.

You can also return enveloped result directly by setting `$r->{result}`.


*OUTPUTTING CSV DATA*

To output CSV data, usually you call the provided routine `$r->{code_print_row}`.
This routine accepts a row (arrayref or hashref). This routine will open the
output files for you when needed, as well as print header row automatically.

You can also buffer rows from input to e.g. `$r->{output_rows}`, then call
`$r->{code_print_row}` repeatedly in the `after_read_input` hook to print all the
rows.


*READING MULTIPLE CSV FILES*

To read multiple CSV files, you first specify `reads_multiple_csv`. Then, you
can supply handler for `on_input_header_row` and `on_input_data_row` as usual.
If you want to do something before/after each input file, you can also supply
handler for `before_open_input_file` or `after_close_input_file`.


*WRITING TO MULTIPLE CSV FILES*

Similarly, to write to many CSv files, you first specify `writes_multiple_csv`.
Then, you can supply handler for `on_input_header_row` and `on_input_data_row`
as usual. To switch to the next file, set
`$r->{wants_switch_to_next_output_file}` to true, in which case the next call to
`$r->{code_print_row}` will close the current file and open the next file.


*CHANGING THE OUTPUT FIELDS*

When calling `$r->{code_print_row}`, you can output whatever fields you want. By
convention, you can set `$r->{output_fields}` and `$r->{output_fields_idx}` to
let other handlers know about the output fields. For example, see the
implementation of <prog:csv-concat>.

_
    args => {
        name => {
            schema => 'perl::identifier::unqualified_ascii*',
            req => 1,
            tags => ['category:metadata'],
        },
        summary => {
            schema => 'str*',
            tags => ['category:metadata'],
        },
        description => {
            schema => 'str*',
            tags => ['category:metadata'],
        },
        links => {
            schema => ['array*', of=>'hash*'], # XXX defhashes
            tags => ['category:metadata'],
        },
        examples => {
            schema => ['array*'], # defhashes
            tags => ['category:metadata'],
        },
        add_meta_props => {
            summary => 'Add additional Rinci function metadata properties',
            schema => ['hash*'],
            tags => ['category:metadata'],
        },
        add_args => {
            schema => ['hash*'],
            tags => ['category:metadata'],
        },
        add_args_rels => {
            schema => ['hash*'],
            tags => ['category:metadata'],
        },

        reads_csv => {
            summary => 'Whether utility reads CSV data',
            'summary.alt.bool.not' => 'Specify that utility does not read CSV data',
            schema => 'bool*',
            default => 1,
        },
        reads_multiple_csv => {
            summary => 'Whether utility accepts CSV data',
            schema => 'bool*',
            description => <<'_',

Setting this option to true will implicitly set the `reads_csv` option to true,
obviously.

_
        },
        writes_csv => {
            summary => 'Whether utility writes CSV data',
            'summary.alt.bool.not' => 'Specify that utility does not write CSV data',
            schema => 'bool*',
            default => 1,
        },
        writes_multiple_csv => {
            summary => 'Whether utility outputs CSV data',
            schema => 'bool*',
            description => <<'_',

Setting this option to true will implicitly set the `writes_csv` option to true,
obviously.

_
        },

        on_begin => {
            schema => 'code*',
        },
        before_read_input => {
            schema => 'code*',
        },
        before_open_input_files => {
            schema => 'code*',
        },
        before_open_input_file => {
            schema => 'code*',
        },
        on_input_header_row => {
            schema => 'code*',
        },
        on_input_data_row => {
            schema => 'code*',
        },
        after_close_input_file => {
            schema => 'code*',
        },
        after_close_input_files => {
            schema => 'code*',
        },
        after_read_input => {
            schema => 'code*',
        },
        on_end => {
            schema => 'code*',
        },
    },
    result_naked => 1,
    result => {
        schema => 'bool*',
    },
};
sub gen_csv_util {
    my %gen_args = @_;

    my $name = delete($gen_args{name}) or die "Please specify name";
    my $summary = delete($gen_args{summary}) // '(No summary)';
    my $description = delete($gen_args{description}) // '(No description)';
    my $links = delete($gen_args{links}) // [];
    my $examples = delete($gen_args{examples}) // [];
    my $add_meta_props = delete $gen_args{add_meta_props};
    my $add_args = delete $gen_args{add_args};
    my $add_args_rels = delete $gen_args{add_args_rels};
    my $reads_multiple_csv = delete($gen_args{reads_multiple_csv});
    my $reads_csv = delete($gen_args{reads_csv}) // 1;
    my $tags = [ @{ delete($gen_args{tags}) // [] } ];
    $reads_csv = 1 if $reads_multiple_csv;
    my $writes_multiple_csv = delete($gen_args{writes_multiple_csv});
    my $writes_csv = delete($gen_args{writes_csv}) // 1;
    $writes_csv = 1 if $writes_multiple_csv;
    my $on_begin                 = delete $gen_args{on_begin};
    my $before_read_input        = delete $gen_args{before_read_input};
    my $before_open_input_files  = delete $gen_args{before_open_input_files};
    my $before_open_input_file   = delete $gen_args{before_open_input_file};
    my $on_input_header_row      = delete $gen_args{on_input_header_row};
    my $on_input_data_row        = delete $gen_args{on_input_data_row};
    my $after_close_input_file   = delete $gen_args{after_close_input_file};
    my $after_close_input_files  = delete $gen_args{after_close_input_files};
    my $after_read_input         = delete $gen_args{after_read_input};
    my $on_end                   = delete $gen_args{on_end};

    scalar(keys %gen_args) and die "Unknown argument(s): ".join(", ", keys %gen_args);

    my $code;
  CREATE_CODE: {
        $code = sub {
            my %util_args = @_;

            my $has_header = $util_args{input_header} // 1;
            my $outputs_header = $util_args{output_header} // $has_header;

            my $r = {
                gen_args => \%gen_args,
                util_args => \%util_args,
                name => $name,
            };

            # inside the main eval block, we call hook handlers. A handler can
            # throw an exception (which can be a string or an enveloped response
            # like [500, "some error message"], see Rinci::function). we trap
            # the exception so we can return the appropriate enveloped response.
          MAIN_EVAL:
            eval {

                # do some checking
                if ($util_args{inplace} && (!$reads_csv || !$writes_csv)) {
                    die [412, "--inplace cannot be specified when we do not read & write CSV"];
                }

                if ($on_begin) {
                    log_trace "[csvutil] Calling on_begin hook handler ...";
                    $on_begin->($r);
                }

                my $code_open_file = sub {
                    # set output filenames, if not yet
                    unless ($r->{output_filenames}) {
                        my @output_filenames;
                        if ($util_args{inplace}) {
                            for my $input_filename (@{ $r->{input_filenames} }) {
                                my $output_filename;
                                while (1) {
                                    $output_filename = $input_filename . "." . _randext(5);
                                    last unless -e $output_filename;
                                }
                                push @output_filenames, $output_filename;
                            }
                        } elsif ($writes_multiple_csv) {
                            @output_filenames = @{ $util_args{output_filenames} // ['-'] };
                        } else {
                            @output_filenames = ($util_args{output_filename} // '-');
                        }

                      CHECK_OUTPUT_FILENAME_SAME_AS_INPUT_FILENAME: {
                            my %seen_output_abs_path; # key = output filename
                            last unless $reads_csv && $writes_csv;
                            for my $input_filename (@{ $r->{input_filenames} }) {
                                next if $input_filename eq '-';
                                my $input_abs_path = Cwd::abs_path($input_filename);
                                die [500, "Can't get absolute path of input filename '$input_filename'"] unless $input_abs_path;
                                for my $output_filename (@output_filenames) {
                                    next if $output_filename eq '-';
                                    next if $seen_output_abs_path{$output_filename};
                                    my $output_abs_path = Cwd::abs_path($output_filename);
                                    die [500, "Can't get absolute path of output filename '$output_filename'"] unless $output_abs_path;
                                    die [412, "Cannot set output filename to '$output_filename' ".
                                         ($output_filename ne $output_abs_path ? "($output_abs_path) ":"").
                                         "because it is the same as input filename and input will be clobbered; use --inplace to avoid clobbering<"]
                                        if $output_abs_path eq $input_abs_path;
                                }
                            }
                        } # CHECK_OUTPUT_FILENAME_SAME_AS_INPUT_FILENAME

                        $r->{output_filenames} = \@output_filenames;
                        $r->{output_num_of_files} //= scalar(@output_filenames);
                    } # set output filenames

                    # open the next file, if not yet
                    if (!$r->{output_fh} || $r->{wants_switch_to_next_output_file}) {
                        $r->{output_filenum} //= 0;
                        $r->{output_filenum}++;

                        $r->{output_rownum} = 0;
                        $r->{output_data_rownum} = 0;

                        # close the previous file, if any
                        if ($r->{output_fh} && $r->{output_filename} ne '-') {
                            log_info "[csvutil] Closing output file '$r->{output_filename}' ...";
                            close $r->{output_fh} or die [500, "Can't close output file '$r->{output_filename}': $!"];
                            delete $r->{has_printed_header};
                            delete $r->{wants_switch_to_next_output_file};
                        }

                        # we have exhausted all the files, do nothing & return
                        return if $r->{output_filenum} > @{ $r->{output_filenames} };

                        $r->{output_filename} = $r->{output_filenames}[ $r->{output_filenum}-1 ];
                        log_info "[csvutil] [%d/%s] Opening output file %s ...",
                            $r->{output_filenum}, $r->{output_num_of_files}, $r->{output_filename};
                        if ($r->{output_filename} eq '-') {
                            $r->{output_fh} = \*STDOUT;
                        } else {
                            if (-f $r->{output_filename}) {
                                if ($r->{util_args}{overwrite}) {
                                    log_info "[csvutil] Will be overwriting output file %s", $r->{output_filename};
                                } else {
                                    die [412, "Refusing to overwrite existing output file '$r->{output_filename}', choose another name or use --overwrite (-O)"];
                                }
                            }
                            my ($fh, $err) = _open_file_write($r->{output_filename});
                            die $err if $err;
                            $r->{output_fh} = $fh;
                        }
                    } # open the next file
                }; # code_open_file

                my $code_print = sub {
                    my $str = shift;
                    $code_open_file->();
                    print { $r->{output_fh} } $str;
                }; # code_print
                $r->{code_print} = $code_print;

                if ($writes_csv) {
                    my $output_emitter = _instantiate_emitter(\%util_args);
                    $r->{output_emitter} = $output_emitter;
                    $r->{has_printed_header} = 0;

                    my $code_print_header_row = sub {
                        # set output fields, if not yet
                        unless ($r->{output_fields}) {
                            # by default, use the
                            $r->{output_fields} = $r->{input_fields};
                        }

                        # index the output fields, if not yet
                        unless ($r->{output_fields_idx}) {
                            $r->{output_fields_idx} = {};
                            for my $j (0 .. $#{ $r->{output_fields} }) {
                                $r->{output_fields_idx}{ $r->{output_fields}[$j] } = $j;
                            }
                        }

                        $code_open_file->();

                        # print header line, if not yet
                        if ($outputs_header && !$r->{has_printed_header}) {
                            $r->{has_printed_header}++;
                            $r->{output_emitter}->print($r->{output_fh}, $r->{output_fields});
                            print { $r->{output_fh} } "\n";
                            $r->{output_rownum}++;
                        }
                    };
                    $r->{code_print_header_row} = $code_print_header_row;

                    my $code_print_row = sub {
                        my $row = shift;

                        $code_print_header_row->();

                        # print data line
                        if ($row) {
                            if (ref $row eq 'HASH') {
                                my $row0 = $row;
                                $row = [];
                                for my $j (0 .. $#{ $r->{output_fields} }) {
                                    $row->[$j] = $row0->{ $r->{output_fields}[$j] } // '';
                                }
                            }
                            $r->{output_emitter}->print( $r->{output_fh}, $row );
                            print { $r->{output_fh} } "\n";
                            $r->{output_rownum}++;
                            $r->{output_data_rownum}++;
                        }
                    }; # code_print_row
                    $r->{code_print_row} = $code_print_row;
                } # if outputs csv

                if ($before_read_input) {
                    log_trace "[csvutil] Calling before_read_input handler ...";
                    $before_read_input->($r);
                }

              READ_CSV: {
                    last unless $reads_csv;

                    my $input_parser = _instantiate_parser(\%util_args, 'input_');
                    $r->{input_parser} = $input_parser;

                    my @input_filenames;
                    if ($reads_multiple_csv) {
                        @input_filenames = @{ $util_args{input_filenames} // ['-'] };
                    } else {
                        @input_filenames = ($util_args{input_filename} // '-');
                    }
                    $r->{input_filenames} //= \@input_filenames;

                  BEFORE_INPUT_FILENAME:
                    $r->{input_filenum} = 0;

                  INPUT_FILENAME:
                    for my $input_filename (@input_filenames) {
                        $r->{input_filenum}++;
                        $r->{input_filename} = $input_filename;

                        if ($r->{input_filenum} == 1 && $before_open_input_files) {
                            log_trace "[csvutil] Calling before_open_input_files handler ...";
                            $before_open_input_files->($r);
                            if (delete $r->{wants_skip_files}) {
                                log_trace "[csvutil] Handler wants to skip files, skipping all input files";
                                last READ_CSV;
                            }
                        }

                        if ($before_open_input_file) {
                            log_trace "[csvutil] Calling before_open_input_file handler ...";
                            $before_open_input_file->($r);
                            if (delete $r->{wants_skip_file}) {
                                log_trace "[csvutil] Handler wants to skip this file, moving on to the next file";
                                next INPUT_FILENAME;
                            } elsif (delete $r->{wants_skip_files}) {
                                log_trace "[csvutil] Handler wants to skip all files, skipping all input files";
                                last READ_CSV;
                            }
                        }

                        log_info "[csvutil] [file %d/%d] Reading input file %s ...",
                            $r->{input_filenum}, scalar(@input_filenames), $input_filename;
                        my ($fh, $err) = _open_file_read($input_filename);
                        die $err if $err;
                        $r->{input_fh} = $r->{input_fhs}[ $r->{input_filenum}-1 ] = $fh;

                        my $i;
                        $r->{input_header_row_count} = 0;
                        $r->{input_data_row_count} = 0;
                        $r->{input_fields} = []; # array, field names in order
                        $r->{input_field_idxs} = {}; # key=field name, value=index (0-based)
                        my $row0;
                        my $code_getline = sub {
                            if ($r->{stdin_input_fields} && $r->{input_filename} eq '-') {
                                if ($i == 0) {
                                    # we have read the header for stdin. since
                                    # we can't seek to the beginning, we return
                                    # the saved fields
                                    $r->{input_header_row_count}++;
                                    return $r->{stdin_input_fields};
                                } else {
                                    my $row = $input_parser->getline($r->{input_fh});
                                    $r->{input_data_row_count}++ if $row;
                                    return $row;
                                }
                            } elsif ($i == 0 && !$has_header) {
                                # this is the first line of a file and user
                                # specifies there is no input header. we save
                                # the line and return the generated field names
                                # instead.
                                $row0 = $input_parser->getline($r->{input_fh});
                                return unless $row0;
                                return [map { "field$_" } 1..@$row0];
                            } elsif ($i == 1 && !$has_header) {
                                # we return the saved first line
                                $r->{input_data_row_count}++ if $row0;
                                return $row0;
                            }
                            my $res = $input_parser->getline($r->{input_fh});
                            if ($res) {
                                $r->{input_header_row_count}++ if $i==0;
                                $r->{input_data_row_count}++ if $i;
                            }
                            $res;
                        };
                        $r->{code_getline} = $code_getline;

                        $i = 0;
                        while ($r->{input_row} = $code_getline->()) {
                            $i++;
                            $r->{input_rownum} = $i;
                            $r->{input_data_rownum} = $has_header ? $i-1 : $i;
                            if ($i == 1) {
                                # gather the list of fields
                                $r->{input_fields} = $r->{input_row};
                                $r->{stdin_input_fields} //= $r->{input_row} if $input_filename eq '-';
                                $r->{orig_input_fields} = $r->{input_fields};
                                $r->{input_fields_idx} = {};
                                for my $j (0 .. $#{ $r->{input_fields} }) {
                                    $r->{input_fields_idx}{ $r->{input_fields}[$j] } = $j;
                                }

                                if ($on_input_header_row) {
                                    log_trace "[csvutil] Calling on_input_header_row hook handler ...";
                                    $on_input_header_row->($r);

                                    if (delete $r->{wants_skip_file}) {
                                        log_trace "[csvutil] Handler wants to skip this file, moving on to the next file";
                                        next INPUT_FILENAME;
                                    } elsif (delete $r->{wants_skip_files}) {
                                        log_trace "[csvutil] Handler wants to skip all files, skipping all input files";
                                        last READ_CSV;
                                    }
                                }

                                # reindex the fields, should the above hook
                                # handler adds/removes fields. let's save the
                                # old fields_idx to orig_fields_idx.
                                $r->{orig_input_fields_idx} = $r->{input_fields_idx};
                                $r->{input_fields_idx} = {};
                                for my $j (0 .. $#{ $r->{input_fields} }) {
                                    $r->{input_fields_idx}{ $r->{input_fields}[$j] } = $j;
                                }

                            } else {
                                # fill up the elements of row to the number of
                                # fields, in case the row contains sparse values
                                unless (defined $r->{wants_fill_rows} && !$r->{wants_fill_rows}) {
                                    if (@{ $r->{input_row} } < @{ $r->{input_fields} }) {
                                        splice @{ $r->{input_row} }, scalar(@{ $r->{input_row} }), 0, (("") x (@{ $r->{input_fields} } - @{ $r->{input_row} }));
                                    }
                                }

                                # generate the hashref version of row if utility
                                # requires it
                                if ($r->{wants_input_row_as_hashref}) {
                                    $r->{input_row_as_hashref} = {};
                                    for my $j (0 .. $#{ $r->{input_row} }) {
                                        # ignore extraneous data fields
                                        last if $j >= @{ $r->{input_fields} };
                                        $r->{input_row_as_hashref}{ $r->{input_fields}[$j] } = $r->{input_row}[$j];
                                    }
                                }

                                if ($on_input_data_row) {
                                    log_trace "[csvutil] Calling on_input_data_row hook handler (for first data row) ..." if $r->{input_rownum} <= 2;
                                    $on_input_data_row->($r);

                                    if (delete $r->{wants_skip_file}) {
                                        log_trace "[csvutil] Handler wants to skip this file, moving on to the next file";
                                        next INPUT_FILENAME;
                                    } elsif (delete $r->{wants_skip_files}) {
                                        log_trace "[csvutil] Handler wants to skip all files, skipping all input files";
                                        last READ_CSV;
                                    }
                                }
                            }

                        } # while getline

                        # XXX actually close filehandle except stdin

                        if ($after_close_input_file) {
                            log_trace "[csvutil] Calling after_close_input_file handler ...";
                            $after_close_input_file->($r);
                            if (delete $r->{wants_skip_files}) {
                                log_trace "[csvutil] Handler wants to skip reading all file, skipping";
                                last READ_CSV;
                            }
                        }
                    } # for input_filename

                    if ($after_close_input_files) {
                        log_trace "[csvutil] Calling after_close_input_files handler ...";
                        $after_close_input_files->($r);
                    }

                } # READ_CSV

                # cleanup stash from csv-reading-related keys
                delete $r->{input_filenames};
                delete $r->{input_filenum};
                delete $r->{input_filename};
                delete $r->{input_fh};
                delete $r->{input_rownum};
                delete $r->{input_data_rownum};
                delete $r->{input_row};
                delete $r->{input_row_as_hashref};
                delete $r->{input_fields};
                delete $r->{input_fields_idx};
                delete $r->{orig_input_fields_idx};
                delete $r->{code_getline};
                delete $r->{wants_input_row_as_hashref};

                if ($after_read_input) {
                    log_trace "[csvutil] Calling after_read_input handler ...";
                    $after_read_input->($r);
                }

                # cleanup stash from csv-outputting-related keys
                delete $r->{output_num_of_files};
                delete $r->{output_filenum};
                if ($r->{output_fh}) {
                    if ($r->{output_filename} ne '-') {
                        log_info "[csvutil] Closing output file '$r->{output_filename}' ...";
                        close $r->{output_fh} or die [500, "Can't close output file '$r->{output_filename}': $!"];
                    }
                    delete $r->{output_fh};
                }
                if ($r->{util_args}{inplace}) {
                    my $output_filenum = $r->{output_filenum} // 0;
                    my $i = -1;
                    for my $output_filename (@{ $r->{output_filenames} }) {
                        $i++;
                        last if $i > $output_filenum;
                        (my $input_filename = $output_filename) =~ s/\.\w{5}\z//
                            or die [500, "BUG: Can't get original input file '$output_filename'"];
                        if (length(my $ext = $r->{util_args}{inplace_backup_ext})) {
                            my $backup_filename = $input_filename . $ext;
                            log_info "[csvutil] Backing up input file '$output_filename' -> '$backup_filename' ...";
                            rename $input_filename, $backup_filename or die [500, "Can't rename '$input_filename' -> '$backup_filename': $!"];
                        }
                        log_info "[csvutil] Renaming from temporary output file '$output_filename' -> '$input_filename' ...";
                        rename $output_filename, $input_filename or die [500, "Can't rename back '$output_filename' -> '$input_filename': $!"];
                    }
                }
                delete $r->{output_filenames};
                delete $r->{output_filename};
                delete $r->{output_rownum};
                delete $r->{output_data_rownum};
                delete $r->{code_print};
                delete $r->{code_print_row};
                delete $r->{code_print_header_row};
                delete $r->{has_printed_header};
                delete $r->{wants_switch_to_next_output_file};

                if ($on_end) {
                    log_trace "[csvutil] Calling on_end hook handler ...";
                    $on_end->($r);
                }

            }; # MAIN_EVAL

            my $err = $@;
            if ($err) {
                $err = [500, $err] unless ref $err;
                return $err;
            }

          RETURN_RESULT:
            if (!$r->{result}) {
                $r->{result} = [200];
            } elsif (!ref($r->{result})) {
                $r->{result} = [500, "BUG: Result (r->{result}) is set to a non-reference ($r->{result}), probably by one of the handlers"];
            } elsif (ref($r->{result}) ne 'ARRAY') {
                $r->{result} = [500, "BUG: Result (r->{result}) is not set to an enveloped result (arrayref) ($r->{result}), probably by one of the handlers"];
            }
            $r->{result};
        };
    } # CREATE_CODE

    my $meta;
  CREATE_META: {

        $meta = {
            v => 1.1,
            summary => $summary,
            description => $description,
            args => {},
            args_rels => {},
            links => $links,
            examples => $examples,
            tags => $tags,
        };

      CREATE_ARGS_PROP: {
            if ($add_args) {
                $meta->{args}{$_} = $add_args->{$_} for keys %$add_args;
            }

            if ($reads_csv) {
                $meta->{args}{$_} = {%{$argspecs_csv_input{$_}}} for keys %argspecs_csv_input;

                if ($reads_multiple_csv) {
                    $meta->{args}{input_filenames} = {%{$argspecopt_input_filenames{input_filenames}}};
                    _add_arg_pos($meta->{args}, 'input_filenames', 'slurpy');
                    push @$tags, 'reads-multiple-csv';
                } else {
                    $meta->{args}{input_filename} = {%{$argspecopt_input_filename{input_filename}}};
                    _add_arg_pos($meta->{args}, 'input_filename');
                }

                push @$tags, 'reads-csv';
            } # if reads_csv

            if ($writes_csv) {
                $meta->{args}{$_} = {%{$argspecs_csv_output{$_}}} for keys %argspecs_csv_output;

                if ($reads_csv) {
                    $meta->{args}{$_} = {%{$argspecsopt_inplace{$_}}} for keys %argspecsopt_inplace;
                    $meta->{args_rels}{'dep_all&'} //= [];
                    push @{ $meta->{args_rels}{'dep_all&'} }, ['inplace_backup_ext', ['inplace']];
                    $meta->{args_rels}{'choose_one&'} //= [];
                    push @{ $meta->{args_rels}{'choose_one&'} }, ['inplace', 'output_filename'];
                    push @{ $meta->{args_rels}{'choose_one&'} }, ['inplace', 'output_filenames'];
                }

                if ($writes_multiple_csv) {
                    $meta->{args}{output_filenames} = {%{$argspecopt_output_filenames{output_filenames}}};
                    _add_arg_pos($meta->{args}, 'output_filenames', 'slurpy');
                    if ($reads_csv) {
                        $meta->{args_rels}{'choose_one&'} //= [];
                        push @{ $meta->{args_rels}{'choose_one&'} }, [qw/output_filenames inplace/];
                    }
                    push @$tags, 'writes-multiple-csv';
                } else {
                    $meta->{args}{output_filename} = {%{$argspecopt_output_filename{output_filename}}};
                    _add_arg_pos($meta->{args}, 'output_filename');
                    if ($reads_csv) {
                        $meta->{args_rels}{'choose_one&'} //= [];
                        push @{ $meta->{args_rels}{'choose_one&'} }, [qw/output_filename inplace/];
                    }
                }

                $meta->{args}{overwrite} = {%{$argspecopt_overwrite{overwrite}}};
                $meta->{args_rels}{'dep_any&'} //= [];
                push @{ $meta->{args_rels}{'dep_any&'} }, ['overwrite', ['output_filename', 'output_filenames']];

                push @$tags, 'writes-csv';
            } # if writes csv

        } # CREATE_ARGS_PROP

      CREATE_ARGS_RELS_PROP: {
            $meta->{args_rels} = {};
            if ($add_args_rels) {
                $meta->{args_rels}{$_} = $add_args_rels->{$_} for keys %$add_args_rels;
            }
        } # CREATE_ARGS_RELS_PROP

        if ($add_meta_props) {
            $meta->{$_} = $add_meta_props->{$_} for keys %$add_meta_props;
        }

    } # CREATE_META

    {
        my $package = caller();
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        *{"$package\::$name"} = $code;
        #use DD; dd $meta;
        ${"$package\::SPEC"}{$name} = $meta;
    }

    1;
}

1;
# ABSTRACT: CLI utilities related to CSV

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSVUtils - CLI utilities related to CSV

=head1 VERSION

This document describes version 1.023 of App::CSVUtils (from Perl distribution App-CSVUtils), released on 2023-03-31.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item 1. L<csv-add-fields>

=item 2. L<csv-avg>

=item 3. L<csv-check-cell-values>

=item 4. L<csv-check-field-names>

=item 5. L<csv-check-field-values>

=item 6. L<csv-check-rows>

=item 7. L<csv-cmp>

=item 8. L<csv-concat>

=item 9. L<csv-convert-to-hash>

=item 10. L<csv-csv>

=item 11. L<csv-delete-fields>

=item 12. L<csv-dump>

=item 13. L<csv-each-row>

=item 14. L<csv-fill-template>

=item 15. L<csv-find-values>

=item 16. L<csv-freqtable>

=item 17. L<csv-gen>

=item 18. L<csv-get-cells>

=item 19. L<csv-grep>

=item 20. L<csv-info>

=item 21. L<csv-intrange>

=item 22. L<csv-list-field-names>

=item 23. L<csv-lookup-fields>

=item 24. L<csv-ltrim>

=item 25. L<csv-map>

=item 26. L<csv-munge-field>

=item 27. L<csv-munge-rows>

=item 28. L<csv-pick>

=item 29. L<csv-pick-fields>

=item 30. L<csv-pick-rows>

=item 31. L<csv-quote>

=item 32. L<csv-replace-newline>

=item 33. L<csv-rtrim>

=item 34. L<csv-select-fields>

=item 35. L<csv-select-rows>

=item 36. L<csv-setop>

=item 37. L<csv-shuf>

=item 38. L<csv-shuf-fields>

=item 39. L<csv-shuf-rows>

=item 40. L<csv-sort>

=item 41. L<csv-sort-fields>

=item 42. L<csv-sort-rows>

=item 43. L<csv-sorted>

=item 44. L<csv-sorted-fields>

=item 45. L<csv-sorted-rows>

=item 46. L<csv-split>

=item 47. L<csv-sum>

=item 48. L<csv-transpose>

=item 49. L<csv-trim>

=item 50. L<csv-uniq>

=item 51. L<csv-unquote>

=item 52. L<csv2ltsv>

=item 53. L<csv2paras>

=item 54. L<csv2td>

=item 55. L<csv2tsv>

=item 56. L<csv2vcf>

=item 57. L<list-csvutils>

=item 58. L<paras2csv>

=item 59. L<tsv2csv>

=back

=head1 FUNCTIONS


=head2 gen_csv_util

Usage:

 gen_csv_util(%args) -> bool

Generate a CSV utility.

This routine is used to generate a CSV utility in the form of a L<Rinci>
function (code and metadata). You can then produce a CLI from the Rinci function
simply using L<Perinci::CmdLine::Gen> or, if you use L<Dist::Zilla>,
L<Dist::Zilla::Plugin::GenPericmdScript> or, if on the command-line,
L<gen-pericmd-script>.

Using this routine, by providing just one or a few hooks and setting some
parameters like a couple of extra arguments, you will get a complete CLI with
decent POD/manpage, ability to read one or multiple CSV's and write one or
multiple CSV's, some command-line options to customize how the input CSV's
should be parsed and how the output CSV's should be formatted and named. Your
CLI also has tab completion, usage and help message, and other features.

To create a CSV utility, you specify a C<name> (e.g. C<csv_dump>; must be a valid
unqualified Perl identifier/function name) and optionally C<summary>,
C<description>, and other metadata like C<links> or even C<add_meta_props>. Then
you specify one or more of C<on_*> or C<before_*> or C<after_*> arguments to supply
handlers (coderefs) for your CSV utility at various hook points.

I<THE HOOKS>

All code for hooks should accept a single argument C<r>. C<r> is a stash (hashref)
of various data, the keys of which will depend on which hook point being called.
You can also add more keys to store data or for flow control (see hook
documentation below for more details).

The order of the hooks, in processing chronological order:

=over

=item * on_begin

Called when utility begins, before reading CSV. You can use this hook e.g. to
process arguments, set output filenames (if you allow custom output
filenames).

=item * before_read_input

Called before opening any input CSV file. This hook is I<still> called even if
your utility sets C<reads_csv> to false.

At this point, the C<input_filenames> stash key (as well as other keys like
C<input_filename>, C<input_filenum>, etc) has not been set. You can use this
hook e.g. to set a custom C<input_filenames>.

=item * before_open_input_files

Called before an input CSV file is about to be opened, including for stdin
(C<->). You can use this hook e.g. to check/preprocess input file. Flow control
is available by setting C<< $r-E<gt>{wants_skip_files} >> to skip reading all the input
file and go directly to the C<after_read_input> hook.

=item * before_open_input_file

Called before an input CSV file is about to be opened, including for stdin
(C<->). For the first file, called after C<before_open_input_file> hook. You can
use this hook e.g. to check/preprocess input file. Flow control is available
by setting C<< $r-E<gt>{wants_skip_file} >> to skip reading a single input file and go
to the next file, or C<< $r-E<gt>{wants_skip_files} >> to skip reading the rest of the
files and go directly to the C<after_read_input> hook.

=item * on_input_header_row

Called when receiving header row. Will be called for every input file, and
called even when user specify C<--no-input-header>, in which case the header
row will be the generated C<["field1", "field2", ...]>. You can use this hook
e.g. to add/remove/rearrange fields.

You can set C<< $r-E<gt>{wants_fill_rows} >> to a defined false if you do not want
C<< $r-E<gt>{input_rows} >> to be filled with empty string elements when it contains
less than the number of fields (in case of sparse values at the end). Normally
you only want to do this when you want to do checking, e.g. in
L<csv-check-rows>.

=item * on_input_data_row

Called when receiving each data row. You can use this hook e.g. to modify the
row or print output (for line-by-line transformation or filtering).

=item * after_close_input_file

Called after each input file is closed, including for stdin (C<->) (although
for stdin, the handle is not actually closed). Flow control is possible by
setting C<< $r-E<gt>{wants_skip_files} >> to skip reading the rest of the files and go
straight to the C<after_close_input_files> hook.

=item * after_close_input_files

Called after the last input file is closed, after the last
C<after_close_input_file> hook, including for stdin (C<->) (although for stdin,
the handle is not actually closed).

=item * after_read_input

Called after the last row of the last CSV file is read and the last file is
closed. This hook is I<still> called, if you set C<reads_csv> option to false.
At this point the stash keys related to CSV reading have all been cleared,
including C<input_filenames>, C<input_filename>, C<input_fh>, etc.

You can use this hook e.g. to print output if you buffer the output.

=item * on_end

Called when utility is about to exit. You can use this hook e.g. to return the
final result.

=back

I<THE STASH>

The common keys that C<r> will contain:

=over

=item * C<gen_args>, hash. The arguments used to generate the CSV utility.

=item * C<util_args>, hash. The arguments that your CSV utility accepts. Parsed from
command-line arguments (or configuration files, or environment variables).

=item * C<name>, str. The name of the CSV utility. Which can also be retrieved via
C<gen_args>.

=item * C<code_print>, coderef. Routine provided for you to print something. Accepts a
string. Takes care of opening the output files for you.

=item * C<code_print_row>, coderef. Routine provided for you to print a data row. You
pass the row (either arrayref or hashref). Takes care of opening the output
files for you, as well as printing header row the first time, if needed.

=item * C<code_print_header_row>, coderef. Routine provided for you to print header
row. You don't need to pass any arguments. Will only print the header row once
per output file if output header is enabled, even if called multiple times.

=back

If you are accepting CSV data (C<reads_csv> gen argument set to true), the
following keys will also be available (in C<on_input_header_row> and
C<on_input_data_row> hooks):

=over

=item * C<input_parser>, a L<Text::CSV_XS> instance for input parsing.

=item * C<input_filenames>, array of str.

=item * C<input_filename>, str. The name of the current input file being read (C<-> if
reading from stdin).

=item * C<input_filenum>, uint. The number of the current input file, 1 being the first
file, 2 for the second, and so on.

=item * C<input_fh>, the handle to the current file being read.

=item * C<input_rownum>, uint. The number of rows that have been read (reset after each
input file). In C<on_input_header_row> phase, this will be 1 since header row
(including the generated one) is the first row. Then in C<on_input_data_row>
phase (called the first time for a file), it will be 2 for the first data row,
even if physically it is the first row for CSV file that does not have a
header.

=item * C<input_data_rownum>, uint. The number of data rows that have been read (reset
after each input file). This will be equal to C<input_rownum> less 1 if input
file has header.

=item * C<input_row>, aos (array of str). The current input CSV row as an arrayref.

=item * C<input_row_as_hashref>, hos (hash of str). The current input CSV row as a
hashref, with field names as hash keys and field values as hash values. This
will only be calculated if utility wants it. Utility can express so by setting
C<< $r-E<gt>{wants_input_row_as_hashref} >> to true, e.g. in the C<on_begin> hook.

=item * C<input_header_row_count>, uint. Contains the number of actual header rows that
have been read. If CLI user specifies C<--no-input-header>, this will stay at
zero. Will be reset for each CSV file.

=item * C<input_data_row_count>, int. Contains the number of actual data rows that have
read. Will be reset for each CSV file.

=back

If you are outputting CSV (C<writes_csv> gen argument set to true), the following
keys will be available:

=over

=item * C<output_emitter>, a L<Text::CSV_XS> instance for output.

=item * C<output_filenames>, array of str.

=item * C<output_filename>, str, name of current output file.

=item * C<output_filenum>, uint, the number of the current output file, 1 being the
first file, 2 for the second, and so on.

=item * C<output_fh>, handle to the current output file.

=item * C<output_rownum>, uint. The number of rows that have been outputted (reset
after each output file).

=item * C<output_data_rownum>, uint. The number of data rows that have been outputted
(reset after each output file). This will be equal to C<input_rownum> less 1 if
input file has header.

=back

For other hook-specific keys, see the documentation for associated hook point.

I<ACCEPTING ADDITIONAL COMMAND-LINE OPTIONS/ARGUMENTS>

As mentioned above, you will get additional command-line options/arguments in
C<< $r-E<gt>{util_args} >> hashref. Some options/arguments are already added by
C<gen_csv_util>, e.g. C<input_filename> or C<input_filenames> along with
C<input_sep_char>, etc (when your utility declares C<reads_csv>),
C<output_filename> or C<output_filenames> along with C<overwrite>,
C<output_sep_char>, etc (when your utility declares C<writes_csv>).

If you want to accept additional arguments/options, you specify them in
C<add_args> (hashref, with key being Each option/argument has to be specified
first via C<add_args> (as hashref, with key being argument name and value the
argument specification as defined in L<Rinci::function>)). Some argument
specifications have been defined in L<App::CSVUtils> and can be used. See
existing utilities for examples.

I<READING CSV DATA>

To read CSV data, normally your utility would provide handler for the
C<on_input_data_row> hook and sometimes additionally C<on_input_header_row>.

I<OUTPUTTING STRING OR RETURNING RESULT>

To output string, usually you call the provided routine C<< $r-E<gt>{code_print} >>. This
routine will open the output files for you.

You can also return enveloped result directly by setting C<< $r-E<gt>{result} >>.

I<OUTPUTTING CSV DATA>

To output CSV data, usually you call the provided routine C<< $r-E<gt>{code_print_row} >>.
This routine accepts a row (arrayref or hashref). This routine will open the
output files for you when needed, as well as print header row automatically.

You can also buffer rows from input to e.g. C<< $r-E<gt>{output_rows} >>, then call
C<< $r-E<gt>{code_print_row} >> repeatedly in the C<after_read_input> hook to print all the
rows.

I<READING MULTIPLE CSV FILES>

To read multiple CSV files, you first specify C<reads_multiple_csv>. Then, you
can supply handler for C<on_input_header_row> and C<on_input_data_row> as usual.
If you want to do something before/after each input file, you can also supply
handler for C<before_open_input_file> or C<after_close_input_file>.

I<WRITING TO MULTIPLE CSV FILES>

Similarly, to write to many CSv files, you first specify C<writes_multiple_csv>.
Then, you can supply handler for C<on_input_header_row> and C<on_input_data_row>
as usual. To switch to the next file, set
C<< $r-E<gt>{wants_switch_to_next_output_file} >> to true, in which case the next call to
C<< $r-E<gt>{code_print_row} >> will close the current file and open the next file.

I<CHANGING THE OUTPUT FIELDS>

When calling C<< $r-E<gt>{code_print_row} >>, you can output whatever fields you want. By
convention, you can set C<< $r-E<gt>{output_fields} >> and C<< $r-E<gt>{output_fields_idx} >> to
let other handlers know about the output fields. For example, see the
implementation of L<csv-concat>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_args> => I<hash>

(No description)

=item * B<add_args_rels> => I<hash>

(No description)

=item * B<add_meta_props> => I<hash>

Add additional Rinci function metadata properties.

=item * B<after_close_input_file> => I<code>

(No description)

=item * B<after_close_input_files> => I<code>

(No description)

=item * B<after_read_input> => I<code>

(No description)

=item * B<before_open_input_file> => I<code>

(No description)

=item * B<before_open_input_files> => I<code>

(No description)

=item * B<before_read_input> => I<code>

(No description)

=item * B<description> => I<str>

(No description)

=item * B<examples> => I<array>

(No description)

=item * B<links> => I<array[hash]>

(No description)

=item * B<name>* => I<perl::identifier::unqualified_ascii>

(No description)

=item * B<on_begin> => I<code>

(No description)

=item * B<on_end> => I<code>

(No description)

=item * B<on_input_data_row> => I<code>

(No description)

=item * B<on_input_header_row> => I<code>

(No description)

=item * B<reads_csv> => I<bool> (default: 1)

Whether utility reads CSV data.

=item * B<reads_multiple_csv> => I<bool>

Whether utility accepts CSV data.

Setting this option to true will implicitly set the C<reads_csv> option to true,
obviously.

=item * B<summary> => I<str>

(No description)

=item * B<writes_csv> => I<bool> (default: 1)

Whether utility writes CSV data.

=item * B<writes_multiple_csv> => I<bool>

Whether utility outputs CSV data.

Setting this option to true will implicitly set the C<writes_csv> option to true,
obviously.


=back

Return value:  (bool)


=head2 compile_eval_code

Usage:

 $coderef = compile_eval_code($str, $label);

Compile string code C<$str> to coderef in 'main' package, without C<use strict>
or C<use warnings>. Die on compile error.

=head2 eval_code

Usage:

 $res = eval_code($coderef, $r, $topic_var_value, $return_topic_var);

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
