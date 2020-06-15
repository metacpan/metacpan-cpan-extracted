package ColorTransform::DuotoneCyan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'ColorTransforms-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use ColorTransform::Weight ();

our %SPEC;

$SPEC{transform} = {
    v => 1.1,
    summary => 'Cyan duotone',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    examples => [
    ],
};
sub transform {
    my %args = @_;

    ColorTransform::Weight::transform(
        color => $args{color},
        r1 => 0.1, g1 => 0.3, b1 => 0.1,
        r2 => 0.2, g2 => 0.5, b2 => 0.3,
        r3 => 0.4, g3 => 0.7, b3 => 0.3,
    );
}

1;
# ABSTRACT: Cyan duotone

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::DuotoneCyan - Cyan duotone

=head1 VERSION

This document describes version 0.002 of ColorTransform::DuotoneCyan (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Cyan duotone.

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
