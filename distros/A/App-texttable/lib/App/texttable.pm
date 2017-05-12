package App::texttable;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{texttable} = {
    v => 1.1,
    summary => 'Render a text table using Text::Table::Any',
    args => {
        rows => {
            summary => 'Table rows',
            schema  => ['array*', of=>['array*', of=>'str*']],
            req => 1,
        },
        header_row => {
            schema  => 'bool*',
            default => 0,
        },
    },
    'cmdline.skip_format' => 1,
    examples => [
        {args=>{rows=>[ ['Name','Gender','Age'],
                        ['ujang','M',28],['iteung','F',25] ]}},
    ],
    result_naked => 1,
};
sub texttable {
    require Text::Table::Any;

    my %args = @_;

    Text::Table::Any::table(rows=>$args{rows}, header_row=>$args{header_row});
}

1;
# ABSTRACT: Generate text table using Text::Table::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

App::texttable - Generate text table using Text::Table::Any

=head1 VERSION

This document describes version 0.02 of App::texttable (from Perl distribution App-texttable), released on 2016-01-18.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 texttable(%args) -> any

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

 "+--------+--------+-----+\n| Name   | Gender | Age |\n| ujang  | M      | 28  |\n| iteung | F      | 25  |\n+--------+--------+-----+\n"

=back

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<header_row> => I<bool> (default: 0)

=item * B<rows>* => I<array[array[str]]>

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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
