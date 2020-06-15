package ColorTransform::Noop;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'ColorTransforms-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

$SPEC{transform} = {
    v => 1.1,
    summary => 'Return color as-is',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {color=>'ff0000'},
            result  => 'ff0000',
        },
    ],
};
sub transform {
    my %args = @_;

    $args{color};
}

1;
# ABSTRACT: Return color as-is

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Noop - Return color as-is

=head1 VERSION

This document describes version 0.002 of ColorTransform::Noop (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Return color as-is.

Examples:

=over

=item * Example #1:

 transform(color => "ff0000"); # -> "ff0000"

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTransforms-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTransforms-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTransforms-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
