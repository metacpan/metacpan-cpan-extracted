package App::SpreadsheetUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-29'; # DATE
our $DIST = 'App-SpreadsheetUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(
                       gen_ss_util
               );

our %SPEC;

our $sch_req_str_or_code = ['any*', of=>['str*', 'code*']];

sub _get_book {
    my $filename = shift;

    if ($filename eq '-') {
        require File::Temp;

        log_trace "Writing spreadsheet data from stdin to temporary file first ...";
        my ($tempfh, $tempfilename) = File::Temp::tempfile();
        log_trace "Temporary filename: %s", $tempfilename;
        while (my $line = <STDIN>) { print $tempfh $line }
        close $tempfh or die "Can't write $filename: $!";
        $filename = $tempfilename;
    }

    require Spreadsheet::Read;
    Spreadsheet::Read->new($filename);
}

sub _select_sheet {
    my ($book, $sheetidx_or_name) = @_;

    my ($sheetidx, $sheetname, $sheetobj);

    my @sheets = $book->sheets;
    $sheetidx_or_name //= 0;
    for my $i (0 .. $#sheets) {
        if ($sheetidx_or_name =~ /\A[1-9]*[0-9]\z/) {
            if ($i == $sheetidx_or_name) { $sheetidx = $i; $sheetname = $sheets[$i]; last }
        } else {
            if ($sheets[$i] eq $sheetidx_or_name) { $sheetidx = $1; $sheetname =  $sheetidx_or_name; last }
        }
    }
    die "unknown sheet '$sheetidx_or_name' in workbook" unless defined $sheetidx;

    $sheetobj = $book->sheet($sheetname) or die "BUG: Can't get sheet[#$sheetidx] named '$sheetname'";
    ($sheetidx, $sheetname, $sheetobj);
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
                log_info "Overwriting output file $filename";
            } else {
                return [412, "Refusing to ovewrite existing output file '$filename', please select another path or specify --overwrite"];
            }
        }
        open my $fh, ">", $filename or do {
            return [500, "Can't open output file '$filename': $!"];
        };
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
    log_trace "Compiling Perl code: $str";
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
    local $main::parser = $r->{input_parser};
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

sub _complete_sheet {
    # return list of known sheets of a workbook

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

    # user wants to read spreadsheet from stdin, bail
    return {message=>"Can't get sheet list when input is stdin"} if $args->{input_filename} eq '-';

    # can the file be opened?
    require Spreadsheet::Read;
    my $book = Spreadsheet::Read->new($args->{input_filename}) or do {
        #warn "Cannot open file '$args->{input_filename}': $!\n";
        return [];
    };

    require Complete::Util;
    return Complete::Util::complete_array_elem(
        word => $word,
        array => [$book->sheets],
    );
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
    return {message=>"Please specify -f first"} unless defined $args && $args->{input_filename};

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

sub _select_fields {
    my ($fields, $field_idxs, $args) = @_;

    my @selected_fields;

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

our $xcomp_spreadsheet_files = [filename => {file_ext_filter => qr/\.(?:sxc|ods|xls|xlsx|xlsm|csv)$/i}];

our %argspecs_csv_input = (
    # input_format?
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
);

our %argspecopt_input_filename = (
    input_filename => {
        summary => 'Input spreadsheet file',
        description => <<'_',

Use `-` to read from stdin.

Encoding of input file is assumed to be UTF-8.

_
        schema => 'filename*',
        default => '-',
        'x.completion' => $xcomp_spreadsheet_files,
        tags => ['category:input'],
    },
);

# TEMP
our %argspecopt0_input_filename = (
    input_filename => {
        summary => 'Input spreadsheet file',
        description => <<'_',

Use `-` to read from stdin.

Encoding of input file is assumed to be UTF-8.

_
        schema => 'filename*',
        default => '-',
        'x.completion' => $xcomp_spreadsheet_files,
        pos => 0,
        tags => ['category:input'],
    },
);


our %argspecopt_input_filenames = (
    input_filenames => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'input_filename',
        summary => 'Input spreadsheet files',
        description => <<'_',

Use `-` to read from stdin.

_
        schema => ['array*', of=>'filename*'],
        default => ['-'],
        'x.element_completion' => $xcomp_spreadsheet_files,
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
        summary => 'Output filename',
        description => <<'_',

Use `-` to output to stdout (the default if you don't specify this option).

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

_
        schema => ['array*', of=>'filename*'],
        cmdline_aliases=>{o=>{}},
        tags => ['category:output'],
    },
);

our %argspecopt_sheet = (
    sheet => {
        summary => 'Select specified worksheet in a workbook',
        schema => 'str*',
        description => <<'_',

Sheet can be selected by name, or by number (0 means the first sheet, 1 the
second, and so on). For CSV, the single worksheet name is the filename/path
itself. To quickly list the sheets of a workbook file, you can use
<prog:ss-list-sheets>.

_
        cmdline_aliases => {s=>{}},
        completion => \&_complete_sheet,
        tags => ['category:filtering'],
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

$SPEC{gen_ss_util} = {
    v => 1.1,
    summary => 'Generate a spreadsheet utility',
    description => <<'_',

This routine is used to generate a CSV utility in the form of a <pm:Rinci>
function (code and metadata). You can then produce a CLI from the Rinci function
simply using <pm:Perinci::CmdLine::Gen> or, if you use <pm:Dist::Zilla>,
<pm:Dist::Zilla::Plugin::GenPericmdScript> or, if on the command-line,
<prog:gen-pericmd-script>.

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
    tags => ['hidden'],
};
sub gen_ss_util {
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

                if ($on_begin) {
                    log_trace "Calling on_begin hook handler ...";
                    $on_begin->($r);
                }

                my $code_open_file = sub {
                    # set output filenames, if not yet
                    unless ($r->{output_filenames}) {
                        my @output_filenames;
                        if ($writes_multiple_csv) {
                            @output_filenames = @{ $util_args{output_filenames} // ['-'] };
                        } else {
                            @output_filenames = ($util_args{output_filename} // '-');
                        }

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
                            log_info "Closing output file '$r->{output_filename}' ...";
                            close $r->{output_fh} or die [500, "Can't close output file '$r->{output_filename}': $!"];
                            delete $r->{has_printed_header};
                            delete $r->{wants_switch_to_next_output_file};
                        }

                        # we have exhausted all the files, do nothing & return
                        return if $r->{output_filenum} > @{ $r->{output_filenames} };

                        $r->{output_filename} = $r->{output_filenames}[ $r->{output_filenum}-1 ];
                        log_info "[%d/%s] Opening output file %s ...",
                            $r->{output_filenum}, $r->{output_num_of_files}, $r->{output_filename};
                        if ($r->{output_filename} eq '-') {
                            $r->{output_fh} = \*STDOUT;
                        } else {
                            if (-f $r->{output_filename}) {
                                if ($r->{util_args}{overwrite}) {
                                    log_info "Will be overwriting output file %s", $r->{output_filename};
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
                    log_trace "Calling before_read_input handler ...";
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
                            log_trace "Calling before_open_input_files handler ...";
                            $before_open_input_files->($r);
                            if (delete $r->{wants_skip_files}) {
                                log_trace "Handler wants to skip files, skipping all input files";
                                last READ_CSV;
                            }
                        }

                        if ($before_open_input_file) {
                            log_trace "Calling before_open_input_file handler ...";
                            $before_open_input_file->($r);
                            if (delete $r->{wants_skip_file}) {
                                log_trace "Handler wants to skip this file, moving on to the next file";
                                next INPUT_FILENAME;
                            } elsif (delete $r->{wants_skip_files}) {
                                log_trace "Handler wants to skip all files, skipping all input files";
                                last READ_CSV;
                            }
                        }

                        log_info "[file %d/%d] Reading input file %s ...",
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
                                    log_trace "Calling on_input_header_row hook handler ...";
                                    $on_input_header_row->($r);

                                    if (delete $r->{wants_skip_file}) {
                                        log_trace "Handler wants to skip this file, moving on to the next file";
                                        next INPUT_FILENAME;
                                    } elsif (delete $r->{wants_skip_files}) {
                                        log_trace "Handler wants to skip all files, skipping all input files";
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
                                    log_trace "Calling on_input_data_row hook handler (for first data row) ..." if $r->{input_rownum} <= 2;
                                    $on_input_data_row->($r);

                                    if (delete $r->{wants_skip_file}) {
                                        log_trace "Handler wants to skip this file, moving on to the next file";
                                        next INPUT_FILENAME;
                                    } elsif (delete $r->{wants_skip_files}) {
                                        log_trace "Handler wants to skip all files, skipping all input files";
                                        last READ_CSV;
                                    }
                                }
                            }

                        } # while getline

                        # XXX actually close filehandle except stdin

                        if ($after_close_input_file) {
                            log_trace "Calling after_close_input_file handler ...";
                            $after_close_input_file->($r);
                            if (delete $r->{wants_skip_files}) {
                                log_trace "Handler wants to skip reading all file, skipping";
                                last READ_CSV;
                            }
                        }
                    } # for input_filename

                    if ($after_close_input_files) {
                        log_trace "Calling after_close_input_files handler ...";
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
                    log_trace "Calling after_read_input handler ...";
                    $after_read_input->($r);
                }

                # cleanup stash from csv-outputting-related keys
                delete $r->{output_filenames};
                delete $r->{output_num_of_files};
                delete $r->{output_filenum};
                if ($r->{output_fh}) {
                    if ($r->{output_filename} ne '-') {
                        log_info "Closing output file '$r->{output_filename}' ...";
                        close $r->{output_fh} or die [500, "Can't close output file '$r->{output_filename}': $!"];
                    }
                    delete $r->{output_fh};
                }
                delete $r->{output_filename};
                delete $r->{output_rownum};
                delete $r->{output_data_rownum};
                delete $r->{code_print};
                delete $r->{code_print_row};
                delete $r->{code_print_header_row};
                delete $r->{has_printed_header};
                delete $r->{wants_switch_to_next_output_file};

                if ($on_end) {
                    log_trace "Calling on_end hook handler ...";
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
                } else {
                    $meta->{args}{input_filename} = {%{$argspecopt_input_filename{input_filename}}};
                    _add_arg_pos($meta->{args}, 'input_filename');
                }
            } # if reads_csv

            if ($writes_csv) {
                $meta->{args}{$_} = {%{$argspecs_csv_output{$_}}} for keys %argspecs_csv_output;

                if ($writes_multiple_csv) {
                    $meta->{args}{output_filenames} = {%{$argspecopt_output_filenames{output_filenames}}};
                    _add_arg_pos($meta->{args}, 'output_filenames', 'slurpy');
                } else {
                    $meta->{args}{output_filename} = {%{$argspecopt_output_filename{output_filename}}};
                    _add_arg_pos($meta->{args}, 'output_filename');
                }

                $meta->{args}{overwrite} = {%{$argspecopt_overwrite{overwrite}}};
            } # if outputs csv

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
# ABSTRACT: CLI utilities related to spreadsheet (XLS, XLSX, ODS, ...)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadsheetUtils - CLI utilities related to spreadsheet (XLS, XLSX, ODS, ...)

=head1 VERSION

This document describes version 0.003 of App::SpreadsheetUtils (from Perl distribution App-SpreadsheetUtils), released on 2023-01-29.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<ss-info>

=item * L<ss-list-sheets>

=item * L<ss2csv>

=item * L<ss2ss>

=back

=for Pod::Coverage ^(gen_ss_util)$

=head1 FUNCTIONS

=head2 compile_eval_code

Usage:

 $coderef = compile_eval_code($str, $label);

Compile string code C<$str> to coderef in 'main' package, without C<use strict>
or C<use warnings>. Die on compile error.

=head2 eval_code

Usage:

 $res = eval_code($coderef, $r, $topic_var_value, $return_topic_var);

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SpreadsheetUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SpreadsheetUtils>.

=head1 SEE ALSO

L<Spreadsheet::Read>

L<App::CSVUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SpreadsheetUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
