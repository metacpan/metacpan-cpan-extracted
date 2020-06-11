package App::ColorThemeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'App-ColorThemeUtils'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

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
        "", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        next unless $mod =~ /(\A|::)ColorTheme::/;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{show_color_theme_swatch} = {
    v => 1.1,
    args => {
        theme => {
            schema => 'perl::modname_with_optional_args*',
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
};
sub show_color_theme_swatch {
    require Color::ANSI::Util;
    require Color::RGB::Util;
    require Module::Load::Util;
    require String::Pad;

    my %args = @_;
    my $width = $args{width} // 80;

    my $theme = Module::Load::Util::instantiate_class_with_optional_args($args{theme});
    my @item_names = $theme->list_items;

    my $reset = Color::ANSI::Util::ansi_reset();
    for my $item_name (@item_names) {
        my $empty_bar = " " x $width;
        my $color0 = $theme->get_item_color($item_name);
        my $color_summary = ref $color0 eq 'HASH' && defined($color0->{summary}) ?
            String::Pad::pad($color0->{summary}, $width, "center", " ", 1) : undef;
        my $fg_color = ref $color0 eq 'HASH' ? $color0->{fg} : $color0;
        my $bg_color = ref $color0 eq 'HASH' ? $color0->{bg} : undef;
        my $color = $fg_color // $bg_color;
        my $text_bar  = String::Pad::pad(
            "$item_name (".($fg_color // "-").(defined $bg_color ? " on $bg_color" : "").")",
            $width, "center", " ", 1);
        my $bartext_color = Color::RGB::Util::rgb_is_dark($color) ? "ffffff" : "000000";
        my $bar = join(
            "",
            Color::ANSI::Util::ansibg($color), $empty_bar, $reset, "\n",
            Color::ANSI::Util::ansibg($color), Color::ANSI::Util::ansifg($bartext_color), $text_bar, $reset, "\n",
            defined $color_summary ? (
                Color::ANSI::Util::ansibg($color), Color::ANSI::Util::ansifg($bartext_color), $color_summary, $reset, "\n",

            ) : (),
            Color::ANSI::Util::ansibg($color), $empty_bar, $reset, "\n",
            $empty_bar, "\n",
        );
        print $bar;
    }
    [200];
}

1;
# ABSTRACT: CLI utilities related to color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ColorThemeUtils - CLI utilities related to color themes

=head1 VERSION

This document describes version 0.008 of App::ColorThemeUtils (from Perl distribution App-ColorThemeUtils), released on 2020-06-11.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-color-theme-modules>

=item * L<show-color-theme-swatch>

=back

=head1 FUNCTIONS


=head2 list_color_theme_modules

Usage:

 list_color_theme_modules(%args) -> [status, msg, payload, meta]

List ColorTheme modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_color_theme_swatch

Usage:

 show_color_theme_swatch(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<theme>* => I<perl::modname_with_optional_args>

=item * B<width> => I<posint> (default: 80)


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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
