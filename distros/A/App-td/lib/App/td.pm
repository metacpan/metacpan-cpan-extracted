package App::td;

our $DATE = '2017-01-01'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

use PerlX::Maybe;

our %SPEC;

sub _get_table_spec_from_envres {
    my $envres = shift;
    my $tf  = $envres->[3]{'table.fields'};
    my $tfa = $envres->[3]{'table.field_aligns'};
    my $tff = $envres->[3]{'table.field_formats'};
    my $tfu = $envres->[3]{'table.field_units'};
    return undef unless $tf;
    my $spec = {fields=>{}};
    my $i = 0;
    for (@$tf) {
        $spec->{fields}{$_} = {
            pos=>$i,
            maybe _align  => $tfa->[$i],
            maybe _format => $tff->[$i],
            maybe _unit   => $tfu->[$i],
        };
        $i++;
    }
    $spec;
}

sub _decode_json {
    require Cpanel::JSON::XS;

    state $json = Cpanel::JSON::XS->new->allow_nonref;
    $json->decode(shift);
}

$SPEC{td} = {
    v => 1.1,
    summary => 'Manipulate table data',
    description => <<'_',

*td* receives table data from standard input and performs an action on it. It
has functionality similar to some Unix commands like *head*, *tail*, *wc*,
*cut*, *sort* except that it operates on table rows/columns instead of
lines/characters. This is convenient to use with CLI scripts that output table
data.

A _table data_ is JSON-encoded data in the form of either: `hos` (hash of
scalars, which is viewed as a two-column table where the columns are `key` and
`value`), `aos` (array of scalars, which is viewed as a 1-column array where the
column is `elem`), `aoaos` (array of arrays of scalars), or `aohos` (array of
hashes of scalars).

The input can also be an _enveloped_ table data, where the envelope is an array:
`[status, message, content, meta]` and `content` is the actual table data. This
kind of data is produced by `Perinci::CmdLine`-based scripts and can contain
more detailed table specification in the `meta` hash, which `td` can parse.

First you might want to use the `info` action to see if the input is a table
data:

    % osnames -l --json | td info

If input is not valid JSON, a JSON parse error will be displayed. If input is
valid JSON but not a table data, another error will be displayed. Otherwise,
information about the table will be displayed (form, number of columns, column
names, number of rows, and so on).

Next, you can use these actions:

    # count number of rows (equivalent to "wc -l" Unix command)
    % osnames -l --json | td rowcount

    # append a row containing rowcount
    % osnames -l --json | td rowcount-row

    # append a row containing column names
    % lcpan related-mods Perinci::CmdLine | td colnames-row

    # count number of columns
    % osnames -l --json | td colcount

    # select some columns
    % osnames -l --json | td select value description

    # only show first 5 rows
    % osnames -l --json | td head -n5

    # only show last 5 rows
    % osnames -l --json | td tail -n5

    # sort by column(s) (add "-" prefix to for descending order)
    % osnames -l --json | td sort value tags
    % osnames -l --json | td sort -- -value

    # return sum of all numeric columns
    % list-files -l --json | td sum

    # append a sum row
    % list-files -l --json | td sum-row

    # return average of all numeric columns
    % list-files -l --json | td avg

    # append an average row
    % list-files -l --json | td avg-row

    # add a row number column (1, 2, 3, ...)
    % list-files -l --json | td rownum-col

_
    args => {
        action => {
            summary => 'Action to perform on input table',
            schema => ['str*', in => [qw/
                                            avg
                                            avg-row
                                            colcount
                                            colcount-row
                                            colnames-row
                                            head
                                            info
                                            rowcount
                                            rowcount-row
                                            rownum-col
                                            select
                                            sort
                                            sum
                                            sum-row
                                            tail
                                            wc
                                            wc-row
                                        /]],
            req => 1,
            pos => 0,
            description => <<'_',

_
        },
        argv => {
            summary => 'Arguments',
            schema => ['array*', of=>'str*'],
            default => [],
            pos => 1,
            greedy => 1,
        },

        # XXX only for head, tail
        lines => {
            schema => ['int*', min=>0],
            cmdline_aliases => {n=>{}},
        },
    },
};
sub td {
    my %args = @_;
    my $action = $args{action};
    my $argv   = $args{argv};

    my ($input, $input_form, $input_obj);
  GET_INPUT:
    {
        require Data::Check::Structure;
        eval {
            local $/;
            $input = _decode_json(~~<STDIN>);
        };
        return [400, "Input is not valid JSON: $@"] if $@;

        # give envelope if not enveloped
        unless (ref($input) eq 'ARRAY' &&
                    @$input >= 2 && @$input <= 4 &&
                    $input->[0] =~ /\A[2-5]\d\d\z/ &&
                    !ref($input->[1])
                ) {
            $input = [200, "Envelope added by td", $input];
        }

        # detect table form
        if (ref($input->[2]) eq 'HASH') {
            $input_form = 'hash';
            require TableData::Object::hash;
            $input_obj = TableData::Object::hash->new($input->[2]);
        } elsif (Data::Check::Structure::is_aos($input->[2])) {
            $input_form = 'aos';
            require TableData::Object::aos;
            $input_obj = TableData::Object::aos->new($input->[2]);
        } elsif (Data::Check::Structure::is_aoaos($input->[2])) {
            $input_form = 'aoaos';
            my $spec = _get_table_spec_from_envres($input);
            require TableData::Object::aoaos;
            $input_obj = TableData::Object::aoaos->new($input->[2], $spec);
        } elsif (Data::Check::Structure::is_aohos($input->[2])) {
            $input_form = 'aohos';
            my $spec = _get_table_spec_from_envres($input);
            require TableData::Object::aohos;
            $input_obj = TableData::Object::aohos->new($input->[2], $spec);
        } else {
            return [400, "Input is not table data, please feed a hash/aos/aoaos/aohos"];
        }
    } # GET_INPUT

    my $output;
  PROCESS:
    {
        if ($action eq 'info') {
            my $form = ref($input_obj); $form =~ s/^TableData::Object:://;
            my $info = {
                form => $form,
                rowcount => $input_obj->row_count,
                colcount => $input_obj->col_count,
                cols => join(", ", @{ $input_obj->cols_by_idx }),
            };
            $output = [200, "OK", $info];
            last;
        }

        if ($action eq 'rowcount') {
            $output = [200, "OK", $input_obj->row_count];
            last;
        }

        if ($action eq 'rowcount-row') {
            my $cols = $input_obj->cols_by_idx;
            my $rows = $input_obj->rows_as_aoaos;
            my $rowcount_row = [map {''} @$cols];
            $rowcount_row->[0] = $input_obj->row_count if @$rowcount_row;
            $output = [200, "OK", [@$rows, $rowcount_row],
                       {'table.fields' => $cols}];
            last;
        }

        if ($action eq 'head' || $action eq 'tail') {
            my $cols = $input_obj->cols_by_idx;
            my $rows = $input_obj->rows_as_aoaos;
            if ($action eq 'head') {
                splice @$rows, $args{lines} if $args{lines} < @$rows;
            } else {
                splice @$rows, 0, @$rows - $args{lines}
                    if $args{lines} < @$rows;
            }
            $output = [200, "OK", $rows, {'table.fields' => $cols}];
            last;
        }

        if ($action eq 'colcount') {
            $output = [200, "OK", $input_obj->col_count];
            last;
        }

        if ($action eq 'colnames-row') {
            my $cols = $input_obj->cols_by_idx;
            my $rows = $input_obj->rows_as_aoaos;
            my $colnames_row = [map {$cols->[$_]} 0..$#{$cols}];
            $output = [200, "OK", [@$rows, $colnames_row],
                       {'table.fields' => $cols}];
            last;
        }

        if ($action eq 'rownum-col') {
            $input_obj->add_col('_rownum', 0); # XXX if table already has that column, use _rownum2, ...
            $input_obj->set_col_val(_rownum => sub { my %a = @_; $a{row_idx}+1 });
            $output = [200, "OK", $input_obj->{data},
                       {'table.fields' => $input_obj->{cols_by_idx}}];
            last;
        }

        if ($action =~ /\A(sum|sum-row|avg|avg-row)\z/) {
            require Scalar::Util;
            my $cols = $input_obj->cols_by_idx;
            my $rows = $input_obj->rows_as_aoaos;
            my $sum_row = [map {0} @$cols];
            for my $i (0..$#{$rows}) {
                my $row = $rows->[$i];
                for my $j (0..@$cols-1) {
                    $sum_row->[$j] += $row->[$j]
                        if Scalar::Util::looks_like_number($row->[$j]);
                }
            }
            my $avg_row;
            if ($action =~ /avg/) {
                if (@$rows) {
                    $avg_row = [map { $_ / @$rows } @$sum_row];
                } else {
                    $avg_row = [map {0} @$cols];
                }
            }
            # XXX return aohos if input is aohos
            if ($action eq 'sum') {
                $output = [200, "OK", [$sum_row],
                           {'table.fields' => $cols}];
            } elsif ($action eq 'sum-row') {
                $output = [200, "OK", [@$rows, $sum_row],
                           {'table.fields' => $cols}];
            } elsif ($action eq 'avg') {
                $output = [200, "OK", [$avg_row],
                           {'table.fields' => $cols}];
            } elsif ($action eq 'avg-row') {
                $output = [200, "OK", [@$rows, $avg_row],
                           {'table.fields' => $cols}];
            }
            last;
        }

        if ($action =~ /\A(sort|select)\z/) {
            return [400, "Please specify one or more columns"] unless @$argv;
            my $res;
            if ($action eq 'sort') {
                if ($input_form eq 'aohos') {
                    $res = $input_obj->select_as_aohos(undef, undef, $argv);
                } else {
                    $res = $input_obj->select_as_aoaos(undef, undef, $argv);
                }
            } elsif ($action eq 'select') {
                if ($input_form eq 'aohos') {
                    $res = $input_obj->select_as_aohos($argv);
                } else {
                    $res = $input_obj->select_as_aoaos($argv);
                }
            }

            my $resmeta = {};
            {
                my $ff  = $res->{spec}{fields} or last;
                my $tf  = [];
                my $tfa = [];
                my $tff = [];
                my $tfu = [];
                for (keys %$ff) {
                    my $f = $ff->{$_};
                    my $i = $f->{pos};
                    $tf ->[$i] = $_;
                    $tfa->[$i] = $f->{_align};
                    $tff->[$i] = $f->{_format};
                    $tfu->[$i] = $f->{_unit};
               }
                $resmeta->{'table.fields'}        = $tf;
                $resmeta->{'table.field_aligns'}  = $tfa;
                $resmeta->{'table.field_formats'} = $tff;
                $resmeta->{'table.field_units'}   = $tfu;
            }
            $output = [200, "OK", $res->{data}, $resmeta];
            last;
        }

        return [400, "Unknown action '$action'"];
    } # PROCESS

  POSTPROCESS_OUTPUT:
    {
        require Pipe::Find;
        my $pipeinfo = Pipe::Find::get_stdout_pipe_process();
        last unless $pipeinfo;
        last unless
            $pipeinfo->{exe} =~ m![/\\]td\z! ||
            $pipeinfo->{cmdline} =~ m!\A([^\0]*[/\\])?perl\0([^\0]*[/\\])?td\0!;
        $output->[3]{'cmdline.default_format'} = 'json';
    }
    $output;
}

1;
# ABSTRACT: Manipulate table data

__END__

=pod

=encoding UTF-8

=head1 NAME

App::td - Manipulate table data

=head1 VERSION

This document describes version 0.08 of App::td (from Perl distribution App-td), released on 2016-01-01.

=head1 FUNCTIONS


=head2 td(%args) -> [status, msg, result, meta]

Manipulate table data.

I<td> receives table data from standard input and performs an action on it. It
has functionality similar to some Unix commands like I<head>, I<tail>, I<wc>,
I<cut>, I<sort> except that it operates on table rows/columns instead of
lines/characters. This is convenient to use with CLI scripts that output table
data.

A I<table data> is JSON-encoded data in the form of either: C<hos> (hash of
scalars, which is viewed as a two-column table where the columns are C<key> and
C<value>), C<aos> (array of scalars, which is viewed as a 1-column array where the
column is C<elem>), C<aoaos> (array of arrays of scalars), or C<aohos> (array of
hashes of scalars).

The input can also be an I<enveloped> table data, where the envelope is an array:
C<[status, message, content, meta]> and C<content> is the actual table data. This
kind of data is produced by C<Perinci::CmdLine>-based scripts and can contain
more detailed table specification in the C<meta> hash, which C<td> can parse.

First you might want to use the C<info> action to see if the input is a table
data:

 % osnames -l --json | td info

If input is not valid JSON, a JSON parse error will be displayed. If input is
valid JSON but not a table data, another error will be displayed. Otherwise,
information about the table will be displayed (form, number of columns, column
names, number of rows, and so on).

Next, you can use these actions:

 # count number of rows (equivalent to "wc -l" Unix command)
 % osnames -l --json | td rowcount
 
 # append a row containing rowcount
 % osnames -l --json | td rowcount-row
 
 # append a row containing column names
 % lcpan related-mods Perinci::CmdLine | td colnames-row
 
 # count number of columns
 % osnames -l --json | td colcount
 
 # select some columns
 % osnames -l --json | td select value description
 
 # only show first 5 rows
 % osnames -l --json | td head -n5
 
 # only show last 5 rows
 % osnames -l --json | td tail -n5
 
 # sort by column(s) (add "-" prefix to for descending order)
 % osnames -l --json | td sort value tags
 % osnames -l --json | td sort -- -value
 
 # return sum of all numeric columns
 % list-files -l --json | td sum
 
 # append a sum row
 % list-files -l --json | td sum-row
 
 # return average of all numeric columns
 % list-files -l --json | td avg
 
 # append an average row
 % list-files -l --json | td avg-row
 
 # add a row number column (1, 2, 3, ...)
 % list-files -l --json | td rownum-col

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action>* => I<str>

Action to perform on input table.

=item * B<argv> => I<array[str]> (default: [])

Arguments.

=item * B<lines> => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-td>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-td>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-td>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci::function> for a more detailed explanation on enveloped result.

L<TableDef> for more detailed explanation of table data definition, which can be
specified in enveloped result's `meta` hash in the `table` key (see
L<Perinci::Sub::Property::result::table>).

L<TableData::Object>

L<Perinci::CmdLine>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
