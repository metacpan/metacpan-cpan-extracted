package App::ColorThemeUtils;

our $DATE = '2019-02-02'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_color_theme_modules} = {
    v => 1.1,
    summary => 'List color theme modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_theme_modules {
    require PERLANCAR::Module::List;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = PERLANCAR::Module::List::list_modules(
        "", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        next unless $mod =~ /::ColorTheme::/;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{list_color_themes} = {
    v => 1.1,
    args => {
        module => {
            schema => 'perl::modname*',
            pos => 0,
            tags => ['category:filtering'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_themes {
    no strict 'refs';
    require Color::ANSI::Util;
    require PERLANCAR::Module::List;

    my %args = @_;

    my @mods;
    if (defined $args{module}) {
        push @mods, $args{module};
    } else {
        my $mods = PERLANCAR::Module::List::list_modules(
            "", {list_modules => 1, recurse => 1});
        for my $mod (sort keys %$mods) {
            next unless $mod =~ /::ColorTheme::/;
            push @mods, $mod;
        }
    }

    my @res;
    my %resmeta;
    for my $mod (@mods) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $themes = \%{"$mod\::color_themes"};
        for my $name (sort keys %$themes) {
            my $colors = $themes->{$name}{colors};
            my $colorbar = "";
            for my $colorname (sort keys %$colors) {
                my $color = $colors->{$colorname};
                $colorbar .= join(
                    "",
                    (length $colorbar ? "" : ""),
                    ref($color) || !length($color) ? ("   ") :
                        (
                            Color::ANSI::Util::ansibg($color),
                            "   ",
                            "\e[0m",
                        ),
                );
            }
            if ($args{detail}) {
                push @res, {
                    module => $mod,
                    name   => $name,
                    colors => $colorbar,
                };
            } else {
                push @res, "$mod\::$name";
            }
        }
    }

    if ($args{detail}) {
        $resmeta{'table.fields'} = [qw/module name colors/];
    }

    [200, "OK", \@res, \%resmeta];
}

1;
# ABSTRACT: CLI utilities related to color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ColorThemeUtils - CLI utilities related to color themes

=head1 VERSION

This document describes version 0.002 of App::ColorThemeUtils (from Perl distribution App-ColorThemeUtils), released on 2019-02-02.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-color-theme-modules>

=item * L<list-color-themes>

=back

=head1 FUNCTIONS


=head2 list_color_theme_modules

Usage:

 list_color_theme_modules(%args) -> [status, msg, payload, meta]

List color theme modules.

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


=head2 list_color_themes

Usage:

 list_color_themes(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<module> => I<perl::modname>

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

L<Color::Theme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
