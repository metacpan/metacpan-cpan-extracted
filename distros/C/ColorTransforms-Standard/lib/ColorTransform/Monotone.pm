package ColorTransform::Monotone;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'ColorTransforms-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Color::RGB::Util qw(rgb2hsv hsv2rgb);

our %SPEC;

$SPEC{transform} = {
    v => 1.1,
    summary => 'Monotone color',
    description => <<'_',

Change the hue of color to a single value. By default, a red monotone (hue=0) is
produced. You can configure the `hue` option (0-360) to produce monotone of
other hues, e.g. green (120) or blue (240).

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        hue => {
            schema => ['num*', between=>[0,360]],
            default => '0',
        },
    },
    result_naked => 1,
    examples => [
    ],
};
sub transform {
    my %args = @_;

    my $hsv = rgb2hsv($args{color});
    my ($h, $s, $v) = split / /, $hsv;
    $h = $args{hue} // 0;
    hsv2rgb("$h $s $v");
}

1;
# ABSTRACT: Monotone color

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Monotone - Monotone color

=head1 VERSION

This document describes version 0.002 of ColorTransform::Monotone (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Monotone color.

Change the hue of color to a single value. By default, a red monotone (hue=0) is
produced. You can configure the C<hue> option (0-360) to produce monotone of
other hues, e.g. green (120) or blue (240).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

=item * B<hue> => I<num> (default: 0)


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

L<ColorTransform::Grayscale>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
