package App::RGBColorUtils;

our $DATE = '2019-07-12'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

#mix_2_rgb_colors
#mix_rgb_colors
#rand_rgb_color
#assign_rgb_color
#assign_rgb_light_color
#assign_rgb_dark_color
#rgb2grayscale
#rgb2sepia
#reverse_rgb_color
#rgb_luminance
#tint_rgb_color
#rgb_distance
#rgb_diff

my %arg0_color = (
    color => {
        schema => 'color::rgb24*',
        req => 1,
        pos => 0,
    },
);

my %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
    },
);

$SPEC{rgb_is_dark} = {
    v => 1.1,
    summary => 'Check if RGB color is dark',
    args => {
        %arg0_color,
        %argopt_quiet,
    },
};
sub rgb_is_dark {
    require Color::RGB::Util;

    my %args = @_;
    my $is_dark = Color::RGB::Util::rgb_is_dark($args{color});
    [
        200,
        "OK",
        $is_dark,
        {
            'cmdline.result' => $args{quiet} ? "" : "RGB color '$args{color}' is ".($is_dark ? "" : "NOT ")."dark",
            'cmdline.exit_code' => $is_dark ? 0:1,
        },
    ];
}

$SPEC{rgb_is_light} = {
    v => 1.1,
    summary => 'Check if RGB color is light',
    args => {
        %arg0_color,
        %argopt_quiet,
    },
};
sub rgb_is_light {
    require Color::RGB::Util;

    my %args = @_;
    my $is_light = Color::RGB::Util::rgb_is_light($args{color});
    [
        200,
        "OK",
        $is_light,
        {
            'cmdline.result' => $args{quiet} ? "" : "RGB color '$args{color}' is ".($is_light ? "" : "NOT ")."light",
            'cmdline.exit_code' => $is_light ? 0:1,
        },
    ];
}

1;
# ABSTRACT: CLI utilities related to RGB color

__END__

=pod

=encoding UTF-8

=head1 NAME

App::RGBColorUtils - CLI utilities related to RGB color

=head1 VERSION

This document describes version 0.001 of App::RGBColorUtils (from Perl distribution App-RGBColorUtils), released on 2019-07-12.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<rgb-is-dark>

=item * L<rgb-is-light>

=back

=head1 FUNCTIONS


=head2 rgb_is_dark

Usage:

 rgb_is_dark(%args) -> [status, msg, payload, meta]

Check if RGB color is dark.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

=item * B<quiet> => I<true>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 rgb_is_light

Usage:

 rgb_is_light(%args) -> [status, msg, payload, meta]

Check if RGB color is light.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

=item * B<quiet> => I<true>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-RGBColorUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-RGBColorUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-RGBColorUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::RGB::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
