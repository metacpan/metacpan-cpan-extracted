package App::CSVUtils;

our $DATE = '2019-04-29'; # DATE
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _compile {
    my $str = shift;
    return $str if ref $str eq 'CODE';
    defined($str) && length($str) or die "Please specify code (-e)\n";
    $str = "package main; no strict; no warnings; sub { $str }";
    my $code = eval $str;
    die "Can't compile code (-e) '$str': $@\n" if $@;
    $code;
}

sub _get_field_idx {
    my ($field, $field_idxs) = @_;
    defined($field) && length($field) or die "Please specify field (-F)\n";
    my $idx = $field_idxs->{$field};
    die "Unknown field '$field'\n" unless defined $idx;
    $idx;
}

sub _get_csv_row {
    my ($csv, $row, $i, $has_header) = @_;
    return "" if $i == 1 && !$has_header;
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

    my $args = shift;

    my %tcsv_opts = (binary=>1);
    if ($args->{tsv}) {
        $tcsv_opts{sep_char}    = "\t";
        $tcsv_opts{quote_char}  = undef;
        $tcsv_opts{escape_char} = undef;
    }

    Text::CSV_XS->new(\%tcsv_opts);
}

sub _complete_field_or_field_list {
    # return list of known fields of a CSV

    my $which = shift;

    my %args = @_;
    my $word = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r = $args{r};

    # we are not called from cmdline, bail
    return undef unless $cmdline;

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
    return undef unless defined $args && $args->{filename};

    # can the file be opened?
    my $csv = _instantiate_parser(\%args);
    open my($fh), "<:encoding(utf8)", $args->{filename} or
        return [];

    # can the header row be read?
    my $row = $csv->getline($fh) or return [];

    require Complete::Util;
    if ($which eq 'field') {
        return Complete::Util::complete_array_elem(
            word => $word,
            array => $row,
        );
    } else {
        # field_list
        return Complete::Util::complete_comma_sep(
            word => $word,
            elems => $row,
            uniq => 1,
        );
    }
}

sub _complete_field {
    _complete_field_or_field_list('field', @_);
}

sub _complete_field_list {
    _complete_field_or_field_list('field_list', @_);
}

our %args_common = (
    header => {
        summary => 'Whether CSV has a header row',
        schema => 'bool*',
        default => 1,
        description => <<'_',

When you declare that CSV does not have header row (`--no-header`), the fields
will be named `field1`, `field2`, and so on.

_
    },
    tsv => {
        summary => "Inform that input file is in TSV (tab-separated) format instead of CSV",
        schema => 'bool*',
    },
);

our %arg_filename_1 = (
    filename => {
        summary => 'Input CSV file',
        schema => 'filename*',
        req => 1,
        pos => 1,
        cmdline_aliases => {f=>{}},
    },
);

our %arg_filename_0 = (
    filename => {
        summary => 'Input CSV file',
        schema => 'filename*',
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

our %arg_filenames_0 = (
    filenames => {
        'x.name.is_plural' => 1,
        summary => 'Input CSV files',
        schema => ['array*', of=>'filename*'],
        req => 1,
        pos => 0,
        slurpy => 1,
        cmdline_aliases => {f=>{}},
    },
);

our %arg_field_1 = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
        completion => \&_complete_field,
    },
);

our %arg_field_1_nocomp = (
    field => {
        summary => 'Field name',
        schema => 'str*',
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
    },
);

our %arg_fields_1 = (
    fields => {
        'x.name.is_plural' => 1,
        summary => 'Field names',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => { F=>{} },
        req => 1,
        pos => 1,
        slurpy => 1,
        element_completion => \&_complete_field,
    },
);

our %arg_fields_or_field_pat = (
    fields => {
        'x.name.is_plural' => 1,
        summary => 'Field names',
        schema => ['array*', of=>'str*'],
        cmdline_aliases => { F=>{} },
        pos => 1,
        slurpy => 1,
        element_completion => \&_complete_field,
    },
    field_pat => {
        summary => 'Field regex pattern to select',
        schema => 're*',
    },
);

our %arg_eval_2 = (
    eval => {
        summary => 'Perl code to do munging',
        schema => ['any*', of=>['str*', 'code*']],
        cmdline_aliases => { e=>{} },
        req => 1,
        pos => 2,
    },
);

our %args_sort_rows_short = (
    reverse => {
        schema => ['bool', is=>1],
        cmdline_aliases => {r=>{}},
    },
    ci => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    by_fields => {
        summary => 'A comma-separated list of field sort specification',
        description => <<'_',

`+FIELD` to mean sort numerically ascending, `-FIELD` to sort numerically
descending, `FIELD` to mean sort ascibetically ascending, `~FIELD` to mean sort
ascibetically descending.

_
        schema => ['str*'],
        #completion => \&_complete_sort_field_list,
    },
    by_code => {
        summary => 'Perl code to do sorting',
        description => <<'_',

`$a` and `$b` (or the first and second argument) will contain the two rows to be
compared.

_
        schema => ['any*', of=>['str*', 'code*']],
    },
);

our %args_sort_fields = (
    sort_reverse => {
        schema => ['bool', is=>1],
    },
    sort_ci => {
        schema => ['bool', is=>1],
    },
    sort_example => {
        schema => ['array*', of=>'str*',
                   'x.perl.coerce_rules' => ['str_comma_sep']],
    },
);

our %args_sort_fields_short = (
    reverse => {
        schema => ['bool', is=>1],
        cmdline_aliases => {r=>{}},
    },
    ci => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    example => {
        summary => 'A comma-separated list of field names',
        schema => ['str*'],
        completion => \&_complete_field_list,
    },
);

our %arg_with_data_rows = (
    with_data_rows => {
        summary => 'Whether to also output data rows',
        schema => 'bool',
    },
);

our %arg_eval = (
    eval => {
        summary => 'Perl code',
        schema => ['any*', of=>['str*', 'code*']],
        cmdline_aliases => { e=>{} },
        req => 1,
    },
);

our %arg_hash = (
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
        %args_common,
        action => {
            schema => ['str*', in=>[
                'add-field',
                'list-field-names',
                'delete-field',
                'munge-field',
                #'replace-newline', # not implemented in csvutil
                'sort-rows',
                'sort-fields',
                'sum',
                'avg',
                'select-row',
                'grep',
                'map',
                'each-row',
                'convert-to-hash',
                #'concat', # not implemented in csvutil
                'select-fields',
                'dump',
                #'setop', # not implemented in csvutil
                #'lookup-fields', # not implemented in csvutil
            ]],
            req => 1,
            pos => 0,
            cmdline_aliases => {a=>{}},
        },
        %arg_filename_1,
        eval => {
            summary => 'Perl code to do munging',
            schema => ['any*', of=>['str*', 'code*']],
            cmdline_aliases => { e=>{} },
        },
        field => {
            summary => 'Field name',
            schema => 'str*',
            cmdline_aliases => { F=>{} },
        },
    },
    args_rels => {
    },
};
sub csvutil {
    my %args = @_;
    my $action = $args{action};
    my $has_header = $args{header} // 1;
    my $add_newline = $args{add_newline} // 1;

    my $csv = _instantiate_parser(\%args);
    open my($fh), "<:encoding(utf8)", $args{filename} or
        return [500, "Can't open input filename '$args{filename}': $!"];

    my $res = "";
    my $i = 0;
    my $fields;
    my %field_idxs;

    my $code;
    my $field_idx;
    my $field_idxs;
    my $sorted_fields;
    my @summary_row;
    my $selected_row;
    my $row_spec_sub;

    my $row0;
    my $code_getline = sub {
        if ($i == 0 && !$has_header) {
            $row0 = $csv->getline($fh);
            return unless $row0;
            return [map { "field$_" } 1..@$row0];
        } elsif ($i == 1 && !$has_header) {
            return $row0;
        }
        $csv->getline($fh);
    };

    my $rows = [];

    while (my $row = $code_getline->()) {
        $i++;
        if ($i == 1) {
            # header row

            $fields = $row;
            for my $j (0..$#{$row}) {
                unless (length $row->[$j]) {
                    #return [412, "Empty field name in field #$j"];
                    next;
                }
                if (defined $field_idxs{$row->[$j]}) {
                    return [412, "Duplicate field name '$row->[$j]'"];
                }
                $field_idxs{$row->[$j]} = $j;
            }
            if ($action eq 'sort-fields') {
                if (my $eg = $args{sort_example}) {
                    $eg = [split /\s*,\s*/, $eg] unless ref($eg) eq 'ARRAY';
                    require Sort::ByExample;
                    my $sorter = Sort::ByExample::sbe($eg);
                    $sorted_fields = [$sorter->(@$row)];
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
            if ($action eq 'select-row') {
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
                $row_spec_sub = eval 'sub { my $i = shift; '.join(" || ", @codestr).' }';
                return [400, "BUG: Invalid row_spec code: $@"] if $@;
            }
            if ($action eq 'grep') {
            } elsif ($action eq 'map') {
            } elsif ($action eq 'sort-rows') {
            } elsif ($action eq 'each-row') {
            }
        } # if i==1 (header row)

        if ($action eq 'list-field-names') {
            return [200, "OK",
                    [map { {name=>$_, index=>$field_idxs{$_}+1} }
                         sort keys %field_idxs],
                    {'table.fields'=>['name','index']}];
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
                    local $main::csv = $csv;
                    local $main::field_idxs = \%field_idxs;
                    eval { $code->($_) };
                    die "Error while munging row ".
                        "#$i field '$args{field}' value '$_': $@\n" if $@;
                    $row->[$field_idx] = $_;
                }
            }
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        } elsif ($action eq 'add-field') {
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
                    return [400, "Field '$args{before}' not found"]
                        unless defined $field_idx;
                } elsif (defined $args{after}) {
                    for (0..$#{$row}) {
                        if ($row->[$_] eq $args{after}) {
                            $field_idx = $_+1;
                            last;
                        }
                    }
                    return [400, "Field '$args{after}' not found"]
                        unless defined $field_idx;
                } else {
                    $field_idx = @$row;
                }
                splice @$row, $field_idx, 0, $args{field};
                for (keys %field_idxs) {
                    if ($field_idxs{$_} >= $field_idx) {
                        $field_idxs{$_}++;
                    }
                }
                $fields = $row;
            } else {
                unless ($code) {
                    $code = _compile($args{eval});
                    if (!defined($args{field}) || !length($args{field})) {
                        return [400, "Please specify field (-F)"];
                    }
                    if (defined $field_idxs{$args{field}}) {
                        return [412, "Field '$args{field}' already exists"];
                    }
                }
                {
                    local $_;
                    local $main::row = $row;
                    local $main::rownum = $i;
                    local $main::csv = $csv;
                    local $main::field_idxs = \%field_idxs;
                    eval { $_ = $code->() };
                    die "Error while adding field '$args{field}' for row #$i: $@\n"
                        if $@;
                    splice @$row, $field_idx, 0, $_;
                }
            }
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        } elsif ($action eq 'delete-field') {
            if (!defined($field_idxs)) {
                $field_idxs = [];
                for my $f (@{ $args{_fields} }) {
                    push @$field_idxs, _get_field_idx($f, \%field_idxs);
                }
                $field_idxs = [sort {$b<=>$a} @$field_idxs];
                for (@$field_idxs) {
                    splice @$row, $_, 1;
                    unless (@$row) {
                        return [412, "Can't delete field(s) because CSV will have zero fields"];
                    }
                }
            } else {
                for (@$field_idxs) {
                    splice @$row, $_, 1;
                }
            }
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        } elsif ($action eq 'select-fields') {
            if (!defined($field_idxs)) {
                $field_idxs = [];
                my %seen;
                if ($args{_fields}) {
                    for my $f (@{ $args{_fields} }) {
                        return [400, "Duplicate field '$f'"] if $seen{$f}++;
                        push @$field_idxs, _get_field_idx($f, \%field_idxs);
                    }
                } else {
                    for my $f (@$fields) {
                        next unless $f =~ $args{_field_pat};
                        push @$field_idxs, $field_idxs{$f};
                    }
                }
            }
            $row = [map { $row->[$_] } @$field_idxs];
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        } elsif ($action eq 'sort-fields') {
            unless ($i == 1) {
                my @new_row;
                for (@$sorted_fields) {
                    push @new_row, $row->[$field_idxs{$_}];
                }
                $row = \@new_row;
            }
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        } elsif ($action eq 'sum') {
            if ($i == 1) {
                $res .= _get_csv_row($csv, $row, $i, $has_header);
            } else {
                require Scalar::Util;
                for (0..$#{$row}) {
                    next unless Scalar::Util::looks_like_number($row->[$_]);
                    $summary_row[$_] += $row->[$_];
                }
                $res .= _get_csv_row($csv, $row, $i, $has_header)
                    if $args{_with_data_rows};
            }
        } elsif ($action eq 'avg') {
            if ($i == 1) {
                $res .= _get_csv_row($csv, $row, $i, $has_header);
            } else {
                require Scalar::Util;
                for (0..$#{$row}) {
                    next unless Scalar::Util::looks_like_number($row->[$_]);
                    $summary_row[$_] += $row->[$_];
                }
                $res .= _get_csv_row($csv, $row, $i, $has_header)
                    if $args{_with_data_rows};
            }
        } elsif ($action eq 'select-row') {
            if ($i == 1 || $row_spec_sub->($i)) {
                $res .= _get_csv_row($csv, $row, $i, $has_header);
            }
        } elsif ($action eq 'grep') {
            unless ($code) {
                $code = _compile($args{eval});
            }
            if ($i == 1 || do {
                my $rowhash;
                if ($args{hash}) {
                    $rowhash = {};
                    for (0..$#{$fields}) {
                        $rowhash->{ $fields->[$_] } = $row->[$_];
                    }
                }
                local $_ = $args{hash} ? $rowhash : $row;
                local $main::row = $row;
                local $main::rownum = $i;
                local $main::csv = $csv;
                local $main::field_idxs = \%field_idxs;
                $code->($row);
            }) {
                $res .= _get_csv_row($csv, $row, $i, $has_header);
            }
        } elsif ($action eq 'map' || $action eq 'each-row') {
            unless ($code) {
                $code = _compile($args{eval});
            }
            if ($i > 1) {
                my $rowres = do {
                    my $rowhash;
                    if ($args{hash}) {
                        $rowhash = {};
                        for (0..$#{$fields}) {
                            $rowhash->{ $fields->[$_] } = $row->[$_];
                        }
                    }
                    local $_ = $args{hash} ? $rowhash : $row;
                    local $main::row = $row;
                    local $main::rownum = $i;
                    local $main::csv = $csv;
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
        } elsif ($action eq 'convert-to-hash') {
            if ($i == $args{_row_number}) {
                $selected_row = $row;
            }
        } elsif ($action eq 'dump') {
            my $rowhash;
            if ($args{hash}) {
                $rowhash = {};
                for (0..$#{$fields}) {
                    $rowhash->{ $fields->[$_] } = $row->[$_];
                }
                push @$rows, $rowhash unless $i == 1;
            } else {
                push @$rows, $row;
            }
        } else {
            return [400, "Unknown action '$action'"];
        }
    } # while getline()

    if ($action eq 'convert-to-hash') {
        $selected_row //= [];
        my $hash = {};
        for (0..$#{$fields}) {
            $hash->{ $fields->[$_] } = $selected_row->[$_];
        }
        return [200, "OK", $hash];
    }

    if ($action eq 'sum') {
        $res .= _get_csv_row($csv, \@summary_row,
                             $args{_with_data_rows} ? $i+1 : 2,
                             $has_header);
    } elsif ($action eq 'avg') {
        if ($i > 2) {
            for (@summary_row) { $_ /= ($i-1) }
        }
        $res .= _get_csv_row($csv, \@summary_row,
                             $args{_with_data_rows} ? $i+1 : 2,
                             $has_header);
    }

    if ($action eq 'dump') {
        return [200, "OK", $rows];
    }

    if ($action eq 'sort-rows') {
        if ($args{sort_by_code}) {
            my $code0 = _compile($args{sort_by_code});
            if ($args{hash}) {
                $code = sub {
                    my $rowhash_a = {};
                    my $rowhash_b = {};
                    for (0..$#{$fields}) {
                        $rowhash_a->{ $fields->[$_] } = $a->[$_];
                        $rowhash_b->{ $fields->[$_] } = $b->[$_];
                    }
                    local $main::a = $rowhash_a;
                    local $main::b = $rowhash_b;
                    $code0->($a, $b);
                };
            } else {
                $code = $code0;
            }
        } elsif ($args{sort_by_fields}) {
            my @fields;
            my $code_str = "";
            for my $field_spec (split /,/, $args{sort_by_fields}) {
                my ($prefix, $field) = $field_spec =~ /\A([+~-]?)(.+)/;
                my $field_idx = $field_idxs{$field};
                return [400, "Unknown field '$field'"]
                    unless defined $field_idx;
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
        } else {
            return [400, "Please specify by_fields or by_code"];
        }

        @$rows = sort {
            local $main::a = $a;
            local $main::b = $b;
            $code->($a, $b);
        } @$rows;

        if ($has_header) {
            $csv->combine(@$fields);
            $res .= $csv->string . "\n";
        }
        for my $row (@$rows) {
            $res .= _get_csv_row($csv, $row, $i, $has_header);
        }
    }

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
} # csvutil

$SPEC{csv_add_field} = {
    v => 1.1,
    summary => 'Add a field to CSV file',
    description => <<'_',

Your Perl code (-e) will be called for each row (excluding the header row) and
should return the value for the new field. `$main::row` is available and
contains the current row. `$main::rownum` contains the row number (2 means the
first data row). `$csv` is the <pm:Text::CSV_XS> object. `$main::field_idxs` is
also available for additional information.

Field by default will be added as the last field, unless you specify one of
`--after` (to put after a certain field), `--before` (to put before a certain
field), or `--at` (to put at specific position, 1 means as the first field).

_
    args => {
        %args_common,
        %arg_filename_0,
        %arg_field_1_nocomp,
        %arg_eval_2,
        after => {
            summary => 'Put the new field after specified field',
            schema => 'str*',
        },
        before => {
            summary => 'Put the new field before specified field',
            schema => 'str*',
        },
        at => {
            summary => 'Put the new field at specific position '.
                '(1 means as first field)',
            schema => ['int*', min=>1],
        },
    },
    args_rels => {
        choose_one => [qw/after before at/],
    },
};
sub csv_add_field {
    my %args = @_;
    csvutil(
        %args, action=>'add-field',
        _after  => $args{after},
        _before => $args{before},
        _at     => $args{at},
    );
}

$SPEC{csv_list_field_names} = {
    v => 1.1,
    summary => 'List field names of CSV file',
    args => {
        %args_common,
        %arg_filename_0,
    },
};
sub csv_list_field_names {
    my %args = @_;
    csvutil(%args, action=>'list-field-names');
}

$SPEC{csv_delete_field} = {
    v => 1.1,
    summary => 'Delete one or more fields from CSV file',
    args => {
        %args_common,
        %arg_filename_0,
        %arg_fields_1,
    },
};
sub csv_delete_field {
    my %args = @_;
    csvutil(%args, action=>'delete-field', _fields => $args{fields});
}

$SPEC{csv_munge_field} = {
    v => 1.1,
    summary => 'Munge a field in every row of CSV file',
    description => <<'_',

Perl code (-e) will be called for each row (excluding the header row) and `$_`
will contain the value of the field, and the Perl code is expected to modify it.
`$main::row` will contain the current row array. `$main::rownum` contains the
row number (2 means the first data row). `$main::csv` is the <pm:Text::CSV_XS>
object. `$main::field_idxs` is also available for additional information.

_
    args => {
        %args_common,
        %arg_filename_0,
        %arg_field_1,
        %arg_eval_2,
    },
};
sub csv_munge_field {
    my %args = @_;
    csvutil(%args, action=>'munge-field');
}

$SPEC{csv_replace_newline} = {
    v => 1.1,
    summary => 'Replace newlines in CSV values',
    description => <<'_',

Some CSV parsers or applications cannot handle multiline CSV values. This
utility can be used to convert the newline to something else. There are a few
choices: replace newline with space (`--with-space`, the default), remove
newline (`--with-nothing`), replace with encoded representation
(`--with-backslash-n`), or with characters of your choice (`--with 'blah'`).

_
    args => {
        %args_common,
        %arg_filename_0,
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
};
sub csv_replace_newline {
    my %args = @_;
    my $with = $args{with};

    my $csv = _instantiate_parser(\%args);
    open my($fh), "<:encoding(utf8)", $args{filename} or
        return [500, "Can't open input filename '$args{filename}': $!"];

    my $res = "";
    my $i = 0;
    while (my $row = $csv->getline($fh)) {
        $i++;
        for my $col (@$row) {
            $col =~ s/[\015\012]+/$with/g;
        }
        my $status = $csv->combine(@$row)
            or die "Error in line $i: ".$csv->error_input;
        $res .= $csv->string . "\n";
    }

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
}

$SPEC{csv_sort_rows} = {
    v => 1.1,
    summary => 'Sort CSV rows',
    description => <<'_',

This utility sorts the rows in the CSV. Example input CSV:

    name,age
    Andy,20
    Dennis,15
    Ben,30
    Jerry,30

Example output CSV (using `--by-fields +age` which means by age numerically and
ascending):

    name,age
    Dennis,15
    Andy,20
    Ben,30
    Jerry,30

Example output CSV (using `--by-fields -age`, which means by age numerically and
descending):

    name,age
    Ben,30
    Jerry,30
    Andy,20
    Dennis,15

Example output CSV (using `--by-fields name`, which means by name ascibetically
and ascending):

    name,age
    Andy,20
    Ben,30
    Dennis,15
    Jerry,30

Example output CSV (using `--by-fields ~name`, which means by name ascibetically
and descending):

    name,age
    Jerry,30
    Dennis,15
    Ben,30
    Andy,20

Example output CSV (using `--by-fields +age,~name`):

    name,age
    Dennis,15
    Andy,20
    Jerry,30
    Ben,30

You can also reverse the sort order (`-r`), sort case-insensitively (`-i`), or
provides the code (`--by-code`, for example `--by-code '$a->[1] <=> $b->[1] ||
$b->[0] cmp $a->[0]'` which is equivalent to `--by-fields +age,~name`). If you
use `--hash`, your code will receive the rows to be compared as hashref, e.g.
`--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

_
    args => {
        %args_common,
        %arg_filename_0,
        %args_sort_rows_short,
        %arg_hash,
    },
    args_rels => {
        req_one => ['by_fields', 'by_code'],
    },
};
sub csv_sort_rows {
    my %args = @_;

    my %csvutil_args = (
        filename => $args{filename},
        action => 'sort-rows',
        sort_by_fields => $args{by_fields},
        sort_by_code   => $args{by_code},
        sort_reverse => $args{reverse},
        sort_ci => $args{ci},
        hash => $args{hash},
    );

    csvutil(%csvutil_args);
}

$SPEC{csv_sort_fields} = {
    v => 1.1,
    summary => 'Sort CSV fields',
    description => <<'_',

This utility sorts the order of fields in the CSV. Example input CSV:

    b,c,a
    1,2,3
    4,5,6

Example output CSV:

    a,b,c
    3,1,2
    6,4,5

You can also reverse the sort order (`-r`), sort case-insensitively (`-i`), or
provides the ordering, e.g. `--example a,c,b`.

_
    args => {
        %args_common,
        %arg_filename_0,
        %args_sort_fields_short,
    },
};
sub csv_sort_fields {
    my %args = @_;

    my %csvutil_args = (
        filename => $args{filename},
        action => 'sort-fields',
        (sort_example => $args{example}) x !!defined($args{example}),
        sort_reverse => $args{reverse},
        sort_ci => $args{ci},
    );

    csvutil(%csvutil_args);
}

$SPEC{csv_sum} = {
    v => 1.1,
    summary => 'Output a summary row which are arithmetic sums of data rows',
    args => {
        %args_common,
        %arg_filename_0,
        %arg_with_data_rows,
    },
};
sub csv_sum {
    my %args = @_;

    csvutil(%args, action=>'sum', _with_data_rows=>$args{with_data_rows});
}

$SPEC{csv_avg} = {
    v => 1.1,
    summary => 'Output a summary row which are arithmetic averages of data rows',
    args => {
        %args_common,
        %arg_filename_0,
        %arg_with_data_rows,
    },
};
sub csv_avg {
    my %args = @_;

    csvutil(%args, action=>'avg', _with_data_rows=>$args{with_data_rows});
}

$SPEC{csv_select_row} = {
    v => 1.1,
    summary => 'Only output specified row(s)',
    args => {
        %args_common,
        %arg_filename_0,
        row_spec => {
            schema => 'str*',
            summary => 'Row number (e.g. 2 for first data row), '.
                'range (2-7), or comma-separated list of such (2-7,10,20-23)',
            req => 1,
            pos => 1,
        },
    },
};
sub csv_select_row {
    my %args = @_;

    csvutil(%args, action=>'select-row');
}

$SPEC{csv_grep} = {
    v => 1.1,
    summary => 'Only output row(s) where Perl expression returns true',
    description => <<'_',

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
        %args_common,
        %arg_filename_0,
        %arg_eval,
        %arg_hash,
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
};
sub csv_grep {
    my %args = @_;

    csvutil(%args, action=>'grep');
}

$SPEC{csv_map} = {
    v => 1.1,
    summary => 'Return result of Perl code for every row',
    description => <<'_',

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
        %args_common,
        %arg_filename_0,
        %arg_eval,
        %arg_hash,
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
    description => <<'_',

This is like csv_map, except result of code is not printed.

_
    args => {
        %args_common,
        %arg_filename_0,
        %arg_eval,
        %arg_hash,
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
        %args_common,
        %arg_filename_0,
        row_number => {
            schema => ['int*', min=>2],
            default => 2,
            summary => 'Row number (e.g. 2 for first data row)',
            pos => 1,
        },
    },
};
sub csv_convert_to_hash {
    my %args = @_;

    csvutil(%args, action=>'convert-to-hash',
            _row_number=>$args{row_number} // 2);
}

$SPEC{csv_concat} = {
    v => 1.1,
    summary => 'Concatenate several CSV files together, '.
        'collecting all the fields',
    description => <<'_',

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
        %args_common,
        %arg_filenames_0,
    },
};
sub csv_concat {
    my %args = @_;

    my %res_field_idxs;
    my @rows;

    for my $filename (@{ $args{filenames} }) {
        my $csv = _instantiate_parser(\%args);
        open my($fh), "<:encoding(utf8)", $filename or
            return [500, "Can't open input filename '$filename': $!"];
        my $i = 0;
        my $fields;
        while (my $row = $csv->getline($fh)) {
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
                my $field = $fields->[$j];
                $res_row->[ $res_field_idxs{$field} ] = $row->[$j];
            }
            push @rows, $res_row;
        }
    } # for each filename

    my $num_fields = keys %res_field_idxs;
    my $res = "";
    my $csv = _instantiate_parser_default();

    # generate header
    my $status = $csv->combine(
        sort { $res_field_idxs{$a} <=> $res_field_idxs{$b} }
            keys %res_field_idxs)
        or die "Error in generating result header row: ".$csv->error_input;
    $res .= $csv->string . "\n";
    for my $i (0..$#rows) {
        my $row = $rows[$i];
        $row->[$num_fields-1] = undef if @$row < $num_fields;
        my $status = $csv->combine(@$row)
            or die "Error in generating data row #".($i+1).": ".
            $csv->error_input;
        $res .= $csv->string . "\n";
    }
    [200, "OK", $res, {"cmdline.skip_format"=>1}];
}

$SPEC{csv_select_fields} = {
    v => 1.1,
    summary => 'Only output selected field(s)',
    args => {
        %args_common,
        %arg_filename_0,
        %arg_fields_or_field_pat,
    },
    args_rels => {
        req_one => ['fields', 'field_pat'],
    },
};
sub csv_select_fields {
    my %args = @_;
    csvutil(%args, action=>'select-fields',
            _fields => $args{fields}, _field_pat => $args{field_pat});
}

$SPEC{csv_dump} = {
    v => 1.1,
    summary => 'Dump CSV as data structure (array of array/hash)',
    args => {
        %args_common,
        %arg_filename_0,
        %arg_hash,
    },
};
sub csv_dump {
    my %args = @_;
    csvutil(%args, action=>'dump');
}

$SPEC{csv_setop} = {
    v => 1.1,
    summary => 'Set operation against several CSV files',
    description => <<'_',

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

Each field specified in `--compare-fields` can be specified using `F1:F2:...`
format to refer to different field names or indexes in each file, for example if
`file3.csv` is:

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
        %args_common,
        %arg_filenames_0,
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
        open my($fh), "<:encoding(utf8)", $filename or
            return [500, "Can't open input filename '$filename': $!"];
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

    [200, "OK", $res, {"cmdline.skip_format"=>1}];
}

$SPEC{csv_lookup_fields} = {
    v => 1.1,
    summary => 'Fill fields of a CSV file from another',
    description => <<'_',

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
        %args_common,
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
        open my($fh), "<:encoding(utf8)", $args{source} or
            return [500, "Can't open '$args{source}': $!"];
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
        open my($fh), "<:encoding(utf8)", $args{target} or
            return [500, "Can't open '$args{target}': $!"];
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
        [200, "OK", $res, {"cmdline.skip_format"=>1}];
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

This document describes version 0.020 of App::CSVUtils (from Perl distribution App-CSVUtils), released on 2019-04-29.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<csv-add-field>

=item * L<csv-avg>

=item * L<csv-concat>

=item * L<csv-convert-to-hash>

=item * L<csv-delete-field>

=item * L<csv-dump>

=item * L<csv-each-row>

=item * L<csv-grep>

=item * L<csv-list-field-names>

=item * L<csv-lookup-fields>

=item * L<csv-map>

=item * L<csv-munge-field>

=item * L<csv-replace-newline>

=item * L<csv-select-fields>

=item * L<csv-select-row>

=item * L<csv-setop>

=item * L<csv-sort>

=item * L<csv-sort-fields>

=item * L<csv-sort-rows>

=item * L<csv-sum>

=item * L<dump-csv>

=back

=head1 FUNCTIONS


=head2 csv_add_field

Usage:

 csv_add_field(%args) -> [status, msg, payload, meta]

Add a field to CSV file.

Your Perl code (-e) will be called for each row (excluding the header row) and
should return the value for the new field. C<$main::row> is available and
contains the current row. C<$main::rownum> contains the row number (2 means the
first data row). C<$csv> is the L<Text::CSV_XS> object. C<$main::field_idxs> is
also available for additional information.

Field by default will be added as the last field, unless you specify one of
C<--after> (to put after a certain field), C<--before> (to put before a certain
field), or C<--at> (to put at specific position, 1 means as the first field).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<after> => I<str>

Put the new field after specified field.

=item * B<at> => I<int>

Put the new field at specific position (1 means as first field).

=item * B<before> => I<str>

Put the new field before specified field.

=item * B<eval>* => I<str|code>

Perl code to do munging.

=item * B<field>* => I<str>

Field name.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_avg

Usage:

 csv_avg(%args) -> [status, msg, payload, meta]

Output a summary row which are arithmetic averages of data rows.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=item * B<with_data_rows> => I<bool>

Whether to also output data rows.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_concat

Usage:

 csv_concat(%args) -> [status, msg, payload, meta]

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filenames>* => I<array[filename]>

Input CSV files.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_convert_to_hash

Usage:

 csv_convert_to_hash(%args) -> [status, msg, payload, meta]

Return a hash of field names as keys and first row as values.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<row_number> => I<int> (default: 2)

Row number (e.g. 2 for first data row).

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_delete_field

Usage:

 csv_delete_field(%args) -> [status, msg, payload, meta]

Delete one or more fields from CSV file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fields>* => I<array[str]>

Field names.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_dump

Usage:

 csv_dump(%args) -> [status, msg, payload, meta]

Dump CSV as data structure (array of array/hash).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_each_row

Usage:

 csv_each_row(%args) -> [status, msg, payload, meta]

Run Perl code for every row.

Examples:

=over

=item * Delete user data:

 csv_each_row(
   filename => "users.csv",
   eval => "unlink qq(/home/data/\$_->{username}.dat)",
   hash => 1
 );

=back

This is like csv_map, except result of code is not printed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_grep

Usage:

 csv_grep(%args) -> [status, msg, payload, meta]

Only output row(s) where Perl expression returns true.

Examples:

=over

=item * Only show rows where the amount field is divisible by 7:

 csv_grep( filename => "file.csv", eval => "\$_->{amount} % 7 ? 1:0", hash => 1);

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_list_field_names

Usage:

 csv_list_field_names(%args) -> [status, msg, payload, meta]

List field names of CSV file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_lookup_fields

Usage:

 csv_lookup_fields(%args) -> [status, msg, payload, meta]

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count> => I<bool>

Do not output rows, just report the number of rows filled.

=item * B<fill_fields>* => I<str>

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<ignore_case> => I<bool>

=item * B<lookup_fields>* => I<str>

=item * B<source>* => I<filename>

CSV file to lookup values from.

=item * B<target>* => I<filename>

CSV file to fill fields of.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_map

Usage:

 csv_map(%args) -> [status, msg, payload, meta]

Return result of Perl code for every row.

Examples:

=over

=item * Create SQL insert statements (escaping is left as an exercise for users):

 csv_map(
   filename => "file.csv",
   eval => "INSERT INTO mytable (id,amount) VALUES (\$_->{id}, \$_->{amount});",
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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_newline> => I<bool> (default: 1)

Whether to make sure each string ends with newline.

=item * B<eval>* => I<str|code>

Perl code.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_munge_field

Usage:

 csv_munge_field(%args) -> [status, msg, payload, meta]

Munge a field in every row of CSV file.

Perl code (-e) will be called for each row (excluding the header row) and C<$_>
will contain the value of the field, and the Perl code is expected to modify it.
C<$main::row> will contain the current row array. C<$main::rownum> contains the
row number (2 means the first data row). C<$main::csv> is the L<Text::CSV_XS>
object. C<$main::field_idxs> is also available for additional information.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<eval>* => I<str|code>

Perl code to do munging.

=item * B<field>* => I<str>

Field name.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_replace_newline

Usage:

 csv_replace_newline(%args) -> [status, msg, payload, meta]

Replace newlines in CSV values.

Some CSV parsers or applications cannot handle multiline CSV values. This
utility can be used to convert the newline to something else. There are a few
choices: replace newline with space (C<--with-space>, the default), remove
newline (C<--with-nothing>), replace with encoded representation
(C<--with-backslash-n>), or with characters of your choice (C<--with 'blah'>).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=item * B<with> => I<str> (default: " ")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_select_fields

Usage:

 csv_select_fields(%args) -> [status, msg, payload, meta]

Only output selected field(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<field_pat> => I<re>

Field regex pattern to select.

=item * B<fields> => I<array[str]>

Field names.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_select_row

Usage:

 csv_select_row(%args) -> [status, msg, payload, meta]

Only output specified row(s).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<row_spec>* => I<str>

Row number (e.g. 2 for first data row), range (2-7), or comma-separated list of such (2-7,10,20-23).

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_setop

Usage:

 csv_setop(%args) -> [status, msg, payload, meta]

Set operation against several CSV files.

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

Each field specified in C<--compare-fields> can be specified using C<F1:F2:...>
format to refer to different field names or indexes in each file, for example if
C<file3.csv> is:

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<compare_fields> => I<str>

=item * B<filenames>* => I<array[filename]>

Input CSV files.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<ignore_case> => I<bool>

=item * B<op>* => I<str>

Set operation to perform.

=item * B<result_fields> => I<str>

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_sort_fields

Usage:

 csv_sort_fields(%args) -> [status, msg, payload, meta]

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
provides the ordering, e.g. C<--example a,c,b>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool>

=item * B<example> => I<str>

A comma-separated list of field names.

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<reverse> => I<bool>

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_sort_rows

Usage:

 csv_sort_rows(%args) -> [status, msg, payload, meta]

Sort CSV rows.

This utility sorts the rows in the CSV. Example input CSV:

 name,age
 Andy,20
 Dennis,15
 Ben,30
 Jerry,30

Example output CSV (using C<--by-fields +age> which means by age numerically and
ascending):

 name,age
 Dennis,15
 Andy,20
 Ben,30
 Jerry,30

Example output CSV (using C<--by-fields -age>, which means by age numerically and
descending):

 name,age
 Ben,30
 Jerry,30
 Andy,20
 Dennis,15

Example output CSV (using C<--by-fields name>, which means by name ascibetically
and ascending):

 name,age
 Andy,20
 Ben,30
 Dennis,15
 Jerry,30

Example output CSV (using C<--by-fields ~name>, which means by name ascibetically
and descending):

 name,age
 Jerry,30
 Dennis,15
 Ben,30
 Andy,20

Example output CSV (using C<--by-fields +age,~name>):

 name,age
 Dennis,15
 Andy,20
 Jerry,30
 Ben,30

You can also reverse the sort order (C<-r>), sort case-insensitively (C<-i>), or
provides the code (C<--by-code>, for example C<< --by-code '$a-E<gt>[1] E<lt>=E<gt> $b-E<gt>[1] ||
$b-E<gt>[0] cmp $a-E<gt>[0]' >> which is equivalent to C<--by-fields +age,~name>). If you
use C<--hash>, your code will receive the rows to be compared as hashref, e.g.
`--hash --by-code '$a->{age} <=> $b->{age} || $b->{name} cmp $a->{name}'.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<str|code>

Perl code to do sorting.

C<$a> and C<$b> (or the first and second argument) will contain the two rows to be
compared.

=item * B<by_fields> => I<str>

A comma-separated list of field sort specification.

C<+FIELD> to mean sort numerically ascending, C<-FIELD> to sort numerically
descending, C<FIELD> to mean sort ascibetically ascending, C<~FIELD> to mean sort
ascibetically descending.

=item * B<ci> => I<bool>

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<hash> => I<bool>

Provide row in $_ as hashref instead of arrayref.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<reverse> => I<bool>

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 csv_sum

Usage:

 csv_sum(%args) -> [status, msg, payload, meta]

Output a summary row which are arithmetic sums of data rows.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

Input CSV file.

=item * B<header> => I<bool> (default: 1)

Whether CSV has a header row.

When you declare that CSV does not have header row (C<--no-header>), the fields
will be named C<field1>, C<field2>, and so on.

=item * B<tsv> => I<bool>

Inform that input file is in TSV (tab-separated) format instead of CSV.

=item * B<with_data_rows> => I<bool>

Whether to also output data rows.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(csvutil)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CSVUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSVUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSVUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<csvgrep>.

L<setop>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
