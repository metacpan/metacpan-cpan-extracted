package ColorTransform::Lighten;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'ColorTransforms-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Color::RGB::Util qw(mix_2_rgb_colors);

our %SPEC;

$SPEC{transform} = {
    v => 1.1,
    summary => 'Lighten color',
    description => <<'_',

Lightening is done by mixing the input color with white (ffffff).

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        percent => {
            schema => ['num*', between=>[0,100]],
            default => '50',
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {color=>'800000'},
            result  => 'bf7f7f',
        },
        {
            args => {color=>'800000', percent=>75},
            result  => 'dfbfbf',
        },
    ],
};
sub transform {
    my %args = @_;

    mix_2_rgb_colors($args{color}, 'ffffff', ($args{percent} // 50)/100);
}

1;
# ABSTRACT: Lighten color

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Lighten - Lighten color

=head1 VERSION

This document describes version 0.002 of ColorTransform::Lighten (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Lighten color.

Examples:

=over

=item * Example #1:

 transform(color => 800000); # -> "bf7f7f"

=item * Example #2:

 transform(color => 800000, percent => 75); # -> "dfbfbf"

=back

Lightening is done by mixing the input color with white (ffffff).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

=item * B<percent> => I<num> (default: 50)


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

L<ColorTransform::Lighten>

L<ColorTransform::Tint>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
