package ColorTransform::Darken;

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
    summary => 'Darken color',
    description => <<'_',

Darkening is done by mixing the input color with black (000000).

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
            args => {color=>'ff0000'},
            result  => '7f0000',
        },
        {
            args => {color=>'ff0000', percent=>75},
            result  => '3f0000',
        },
    ],
};
sub transform {
    my %args = @_;

    mix_2_rgb_colors($args{color}, '000000', ($args{percent} // 50)/100);
}

1;
# ABSTRACT: Darken color

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTransform::Darken - Darken color

=head1 VERSION

This document describes version 0.002 of ColorTransform::Darken (from Perl distribution ColorTransforms-Standard), released on 2020-06-13.

=head1 FUNCTIONS


=head2 transform

Usage:

 transform(%args) -> any

Darken color.

Examples:

=over

=item * Example #1:

 transform(color => "ff0000"); # -> "7f0000"

=item * Example #2:

 transform(color => "ff0000", percent => 75); # -> "3f0000"

=back

Darkening is done by mixing the input color with black (000000).

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
