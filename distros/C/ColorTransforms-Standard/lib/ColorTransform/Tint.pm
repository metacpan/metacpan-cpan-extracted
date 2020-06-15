package ColorTransform::Tint;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'ColorTransforms-Standard'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Color::RGB::Util qw(tint_rgb_color);

our %SPEC;

$SPEC{transform} = {
    v => 1.1,
    summary => 'Tint color',
    description => <<'_',

Tinting is similar to mixing, but the less luminance the color is the less it is
tinted with the tint color. This has the effect of black color still being black
instead of becoming tinted.

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        tint_color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 1,
        },
        percent => {
            schema => ['num*', between=>[0,100]],
            default => '50',
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {color=>'ff0000', tint_color=>'00ff00'},
            result  => 'e31b00',
        },
        {
            args => {color=>'000000', tint_color=>'00ff00'},
            result  => '000000',
        },
        {
            args => {color=>'ff0000', tint_color=>'00ff00', percent=>75},
            result  => 'd62800',
        },
    ],
};
sub transform {
    my %args = @_;

    tint_rgb_color($args{color}, $args{tint_color}, ($args{percent} // 50)/100);
}

1;
# ABSTRACT: Tint color

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Tint - Tint color

=head1 VERSION

This document describes version 0.002 of ColorTransform::Tint (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Tint color.

Examples:

=over

=item * Example #1:

 transform(color => "ff0000", tint_color => "00ff00"); # -> "e31b00"

=item * Example #2:

 transform(color => "000000", tint_color => "00ff00"); # -> "000000"

=item * Example #3:

 transform(color => "ff0000", tint_color => "00ff00", percent => 75); # -> "d62800"

=back

Tinting is similar to mixing, but the less luminance the color is the less it is
tinted with the tint color. This has the effect of black color still being black
instead of becoming tinted.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

=item * B<percent> => I<num> (default: 50)

=item * B<tint_color>* => I<color::rgb24>


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
