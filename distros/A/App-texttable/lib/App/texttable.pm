package App::texttable;

our $DATE = '2019-01-11'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

use PerlX::Maybe;
use Text::Table::Any;

our %SPEC;

$SPEC{texttable} = {
    v => 1.1,
    summary => 'Render a text table using Text::Table::Any',
    args => {
        action => {
            schema => ['str*', in=>['list_backends', 'gen_table']],
            default => 'gen_table',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action=list_backends', code=>sub {$_[0]{action}='list_backends'}},
            },
        },
        rows => {
            summary => 'Table rows',
            schema  => ['array*', of=>['array*', of=>'str*']],
        },
        header_row => {
            schema  => 'bool*',
            default => 0,
        },
        backend => {
            schema => ['str*', in=>\@Text::Table::Any::BACKENDS],
            cmdline_aliases => {b=>{}},
        },
    },
    'cmdline.skip_format' => 1,
    examples => [
        {
            args=> {rows=>[ ['Name','Gender','Age'],
                            ['ujang','M',28],['iteung','F',25] ]}},
        {
            summary => 'List available backends',
            argv => ['-l'],
            'x.doc.show_result' => 0,
        },

    ],
    result_naked => 1,
};
sub texttable {
    my %args = @_;

    if ($args{action} eq 'list_backends') {
        join("", map {"$_\n"} @Text::Table::Any::BACKENDS);
    } else {
        return [400, "Please specify rows"] unless $args{rows};
        Text::Table::Any::table(
            rows => $args{rows},
            header_row => $args{header_row},
            maybe backend => $args{backend},
        );
    }
}

1;
# ABSTRACT: Generate text table using Text::Table::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

App::texttable - Generate text table using Text::Table::Any

=head1 VERSION

This document describes version 0.030 of App::texttable (from Perl distribution App-texttable), released on 2019-01-11.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 texttable

Usage:

 texttable(%args) -> any

Render a text table using Text::Table::Any.

Examples:

=over

=item * Example #1:

 texttable(
 rows => [
     ["Name", "Gender", "Age"],
     ["ujang", "M", 28],
     ["iteung", "F", 25],
   ]
 );

Result:

 [
   200,
   "OK",
   "+--------+--------+-----+\n| Name   | Gender | Age |\n| ujang  | M      | 28  |\n| iteung | F      | 25  |\n+--------+--------+-----+\n",
 ]

=item * List available backends:

 texttable( action => "list_backends");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "gen_table")

=item * B<backend> => I<str>

=item * B<header_row> => I<bool> (default: 0)

=item * B<rows> => I<array[array[str]]>

Table rows.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-texttable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-texttable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-texttable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::TableDataUtils> distribution which also contains some utilities to
generate text table.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
