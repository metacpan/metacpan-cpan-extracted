package App::RGBColorUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-16'; # DATE
our $DIST = 'App-RGBColorUtils'; # DIST
our $VERSION = '0.004'; # VERSION

our %SPEC;

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
    examples => [
        {args=>{color=>'112211'}},
        {args=>{color=>'ffccff'}},
    ],
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
    examples => [
        {args=>{color=>'112211'}},
        {args=>{color=>'ffccff'}},
    ],
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

$SPEC{mix_2_rgb_colors} = {
    v => 1.1,
    summary => 'Mix two RGB colors',
    args => {
        color1 => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        color2 => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 1,
        },
    },
    examples => [
        {args=>{color1=>'000000', color2=>'ffffff'}},
        {args=>{color1=>'ff0000', color2=>'00ff99'}},
    ],
};
sub mix_2_rgb_colors {
    require Color::RGB::Util;

    my %args = @_;
    [200, "OK", Color::RGB::Util::mix_2_rgb_colors($args{color1}, $args{color2})];
}

$SPEC{mix_rgb_colors} = {
    v => 1.1,
    summary => 'Mix several RGB colors together',
    args => {
        colors => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'color',
            schema => ['array*', of=>'color::rgb24*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    examples => [
        {args=>{colors=>['000000','ffffff','99cc00']}},
    ],
};
sub mix_rgb_colors {
    require Color::RGB::Util;

    my %args = @_;
    # XXX allow proportions
    [200, "OK", Color::RGB::Util::mix_rgb_colors(map { $_ => 1 } @{ $args{colors} })];
}

1;
# ABSTRACT: CLI utilities related to RGB color

__END__

=pod

=encoding UTF-8

=head1 NAME

App::RGBColorUtils - CLI utilities related to RGB color

=head1 VERSION

This document describes version 0.004 of App::RGBColorUtils (from Perl distribution App-RGBColorUtils), released on 2023-12-16.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<mix-2-rgb-colors>

=item * L<mix-rgb-colors>

=item * L<rgb-is-dark>

=item * L<rgb-is-light>

=back

=head1 FUNCTIONS


=head2 mix_2_rgb_colors

Usage:

 mix_2_rgb_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Mix two RGB colors.

Examples:

=over

=item * Example #1:

 mix_2_rgb_colors(color1 => "000000", color2 => "ffffff"); # -> [200, "OK", "7f7f7f", {}]

=item * Example #2:

 mix_2_rgb_colors(color1 => "ff0000", color2 => "00ff99"); # -> [200, "OK", "7f7f4c", {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color1>* => I<color::rgb24>

(No description)

=item * B<color2>* => I<color::rgb24>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mix_rgb_colors

Usage:

 mix_rgb_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Mix several RGB colors together.

Examples:

=over

=item * Example #1:

 mix_rgb_colors(colors => ["000000", "ffffff", "99cc00"]); # -> [200, "OK", 889955, {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<colors>* => I<array[color::rgb24]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 rgb_is_dark

Usage:

 rgb_is_dark(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if RGB color is dark.

Examples:

=over

=item * Example #1:

 rgb_is_dark(color => 112211);

Result:

 [
   200,
   "OK",
   1,
   {
     "cmdline.exit_code" => 0,
     "cmdline.result"    => "RGB color '112211' is dark",
   },
 ]

=item * Example #2:

 rgb_is_dark(color => "ffccff");

Result:

 [
   200,
   "OK",
   0,
   {
     "cmdline.exit_code" => 1,
     "cmdline.result"    => "RGB color 'ffccff' is NOT dark",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

(No description)

=item * B<quiet> => I<true>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 rgb_is_light

Usage:

 rgb_is_light(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if RGB color is light.

Examples:

=over

=item * Example #1:

 rgb_is_light(color => 112211);

Result:

 [
   200,
   "OK",
   0,
   {
     "cmdline.exit_code" => 1,
     "cmdline.result"    => "RGB color '112211' is NOT light",
   },
 ]

=item * Example #2:

 rgb_is_light(color => "ffccff");

Result:

 [
   200,
   "OK",
   1,
   {
     "cmdline.exit_code" => 0,
     "cmdline.result"    => "RGB color 'ffccff' is light",
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color>* => I<color::rgb24>

(No description)

=item * B<quiet> => I<true>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-RGBColorUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-RGBColorUtils>.

=head1 SEE ALSO

L<Color::RGB::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-RGBColorUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
