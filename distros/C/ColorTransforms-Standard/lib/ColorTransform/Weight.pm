package ColorTransform::Weight;

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
    summary => 'Weight each component (R, G, B) of the color',
    description => <<'_',

Weighting is used to create grayscale/sepia/duotone transforms.

See: <http://www.techrepublic.com/blog/howdoi/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/120>

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        r1 => { schema => 'float*', req => 1, pos=>1 },
        g1 => { schema => 'float*', req => 1, pos=>2 },
        b1 => { schema => 'float*', req => 1, pos=>3 },
        r2 => { schema => 'float*', req => 1, pos=>4 },
        g2 => { schema => 'float*', req => 1, pos=>5 },
        b2 => { schema => 'float*', req => 1, pos=>6 },
        r3 => { schema => 'float*', req => 1, pos=>7 },
        g3 => { schema => 'float*', req => 1, pos=>8 },
        b3 => { schema => 'float*', req => 1, pos=>9 },
    },
    result_naked => 1,
    examples => [
    ],
};
sub transform {
    my %args = @_;

    $args{color} =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    my $or = ($r*$args{r1}) + ($g*$args{g1}) + ($b*$args{b1});
    my $og = ($r*$args{r2}) + ($g*$args{g2}) + ($b*$args{b2});
    my $ob = ($r*$args{r3}) + ($g*$args{g3}) + ($b*$args{b3});
    for ($or, $og, $ob) { $_ = 255 if $_ > 255 }
    return sprintf("%02x%02x%02x", $or, $og, $ob);
}

1;
# ABSTRACT: Weight each component (R, G, B) of the color

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Weight - Weight each component (R, G, B) of the color

=head1 VERSION

This document describes version 0.002 of ColorTransform::Weight (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Weight each component (R, G, B) of the color.

Weighting is used to create grayscale/sepia/duotone transforms.

See: L<http://www.techrepublic.com/blog/howdoi/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/120>

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<b1>* => I<float>

=item * B<b2>* => I<float>

=item * B<b3>* => I<float>

=item * B<color>* => I<color::rgb24>

=item * B<g1>* => I<float>

=item * B<g2>* => I<float>

=item * B<g3>* => I<float>

=item * B<r1>* => I<float>

=item * B<r2>* => I<float>

=item * B<r3>* => I<float>


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

L<ColorTransform::Darken>

L<ColorTransform::Lighten>

L<Color::RGB::Util>'s C<tint_rgb_color>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
