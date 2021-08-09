package App::ColorThemeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-08'; # DATE
our $DIST = 'App-ColorThemeUtils'; # DIST
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

sub _is_rgb_code {
    my $code = shift;
    $code =~ /\A#?[0-9A-Fa-f]{6}\z/;
}

sub _ansi_code_to_color_name {
    my $code = shift;
    $code =~ s/\e\[(.+)m/$1/g;
    "ansi:$code";
}

$SPEC{list_color_theme_modules} = {
    v => 1.1,
    summary => 'List ColorTheme modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_theme_modules {
    require Module::List::Tiny;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = Module::List::Tiny::list_modules(
        "ColorTheme::", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        $mod =~ s/\AColorTheme:://;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{show_color_theme_swatch} = {
    v => 1.1,
    args => {
        theme => {
            schema => 'perl::colortheme::modname_with_optional_args*',
            req => 1,
            pos => 0,
            cmdline_aliases => {m=>{}},
        },
        width => {
            schema => 'posint*',
            default => 80,
            cmdline_aliases => {w=>{}},
        },
    },
    links => [
        {url=>'prog:show-colors-from-theme'},
    ],
};
sub show_color_theme_swatch {
    require Color::ANSI::Util;
    require Color::RGB::Util;
    require Module::Load::Util;
    require String::Pad;

    my %args = @_;
    my $width = $args{width} // 80;

    my $theme = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>'ColorTheme'}, $args{theme});
    my @item_names = $theme->list_items;

    my $reset = Color::ANSI::Util::ansi_reset();
    for my $item_name (@item_names) {
        my $empty_bar = " " x $width;
        my $color0 = $theme->get_item_color($item_name);
        my $color_summary = ref $color0 eq 'HASH' && defined($color0->{summary}) ?
            String::Pad::pad($color0->{summary}, $width, "center", " ", 1) : undef;

        my $fg_color_code = ref $color0 eq 'HASH' ? ($color0->{ansi_fg} ? $color0->{ansi_fg} : $color0->{fg}) : $color0;
        my $bg_color_code = ref $color0 eq 'HASH' ? ($color0->{ansi_bg} ? $color0->{ansi_bg} : $color0->{bg}) : undef;
        die "Error in code for color item '$item_name': at least one of bgcolor or fgcolor must be defined"
            unless defined $fg_color_code || defined $bg_color_code;
        my $color_code = $fg_color_code // $bg_color_code;

        my $fg_color_name = !defined($fg_color_code) ? "undef" : _is_rgb_code($fg_color_code) ? "rgb:$fg_color_code" : _ansi_code_to_color_name($fg_color_code);
        my $bg_color_name = !defined($bg_color_code) ? "undef" : _is_rgb_code($bg_color_code) ? "rgb:$bg_color_code" : _ansi_code_to_color_name($bg_color_code);
        my $color_name = $fg_color_name // $bg_color_name;

        my $text_bar  = String::Pad::pad(
            "$item_name ($fg_color_name on $bg_color_name)",
            $width, "center", " ", 1);

        my $bar;
        if ($color_name =~ /^rgb:/) {
            my $bartext_color = Color::RGB::Util::rgb_is_dark($fg_color_code // 'ffffff') ? "ffffff" : "000000";
            $bar = join(
                "",
                Color::ANSI::Util::ansibg($color_code), $empty_bar, $reset, "\n",
                Color::ANSI::Util::ansibg($color_code), Color::ANSI::Util::ansifg($bartext_color), $text_bar, $reset, "\n",
                defined $color_summary ? (
                    Color::ANSI::Util::ansibg($color_code), Color::ANSI::Util::ansifg($bartext_color), $color_summary, $reset, "\n",

                ) : (),
                Color::ANSI::Util::ansibg($color_code), $empty_bar, $reset, "\n",
                $empty_bar, "\n",
            );
        } else {
            # color is ansi
            $bar = join(
                "",
                ($fg_color_code // '').($bg_color_code // ''), $empty_bar, $reset, "\n",
                ($fg_color_code // '').($bg_color_code // ''), $text_bar, $reset, "\n",
                defined $color_summary ? (
                    ($fg_color_code // '').($bg_color_code // ''), $color_summary, $reset, "\n",
                ) : (),
                $empty_bar, "\n",
            );
        }
        print $bar;
    }
    [200];
}

$SPEC{list_color_theme_items} = {
    v => 1.1,
    args => {
        theme => {
            schema => 'perl::modname_with_optional_args*',
            req => 1,
            pos => 0,
            cmdline_aliases => {m=>{}},
        },
    },
};
sub list_color_theme_items {
    require Module::Load::Util;

    my %args = @_;

    my $theme = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>'ColorTheme'}, $args{theme});
    my @item_names = $theme->list_items;
    [200, "OK", \@item_names];
}

1;
# ABSTRACT: CLI utilities related to color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ColorThemeUtils - CLI utilities related to color themes

=head1 VERSION

This document describes version 0.011 of App::ColorThemeUtils (from Perl distribution App-ColorThemeUtils), released on 2021-08-08.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-color-theme-items>

=item * L<list-color-theme-modules>

=item * L<show-color-theme-swatch>

=back

=head1 FUNCTIONS


=head2 list_color_theme_items

Usage:

 list_color_theme_items(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<theme>* => I<perl::modname_with_optional_args>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_color_theme_modules

Usage:

 list_color_theme_modules(%args) -> [$status_code, $reason, $payload, \%result_meta]

List ColorTheme modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 show_color_theme_swatch

Usage:

 show_color_theme_swatch(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<theme>* => I<perl::colortheme::modname_with_optional_args>

=item * B<width> => I<posint> (default: 80)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ColorThemeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ColorThemeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ColorThemeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorTheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
