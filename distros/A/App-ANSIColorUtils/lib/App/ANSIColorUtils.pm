package App::ANSIColorUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-18'; # DATE
our $DIST = 'App-ANSIColorUtils'; # DIST
our $VERSION = '0.011'; # VERSION

our %SPEC;

$SPEC{show_ansi_color_table} = {
    v => 1.1,
    summary => 'Show a table of ANSI codes & colors',
    args => {
        width => {
            schema => ['str*', in=>[8, 16, 256]],
            default => 8,
            cmdline_aliases => {
                8   => {is_flag=>1, summary => 'Shortcut for --width=8'  , code => sub { $_[0]{width} = 8 }},
                16  => {is_flag=>1, summary => 'Shortcut for --width=16' , code => sub { $_[0]{width} = 16 }},
                256 => {is_flag=>1, summary => 'Shortcut for --width=256', code => sub { $_[0]{width} = 256 }},
            },
        },
    },
};
sub show_ansi_color_table {
    require Color::ANSI::Util;

    my %args = @_;

    my $width = $args{width};

    my @rows;
    for (0 .. $width - 1) {
        push @rows, {
            code => $_,
            color=>
                $_ < 8   ? sprintf("\e[%dm%s\e[0m", 30+$_, "This is ANSI color #$_") :
                $_ < 16  ? sprintf("\e[1;%dm%s\e[0m", 30+$_-8, "This is ANSI color #$_") :
                           sprintf("\e[38;5;%dm%s\e[0m", $_, "This is ANSI color #$_"),
        };
    }
    [200, "OK", \@rows];
}

$SPEC{show_colors} = {
    v => 1.1,
    summary => 'Show colors specified in argument as text with ANSI colors',
    args => {
        colors => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'color',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
};
sub show_colors {
    require Color::ANSI::Util;
    require Graphics::ColorNamesLite::All;
    #require String::Escape; # ugly: \x1b...
    require Data::Dmp;

    my $codes = $Graphics::ColorNamesLite::All::NAMES_RGB_TABLE;

    my %args = @_;

    my @colornames;
    my @colorcodes;
    if ($args{_colors_hash}) {
        @colornames  = sort keys %{ $args{_colors_hash} };
        @colorcodes = map { $args{_colors_hash}{$_} } @colornames;
    } else {
        @colornames = @colorcodes = @{ $args{colors} };
    }

    my @rows;
    for my $j (0 .. $#colornames) {
        my $colorname = $colornames[$j];
        my $colorcode = $colorcodes[$j];
        unless ($colorcode =~ /\A[0-9A-fa-f]{6}\z/) {
            $colorcode = $codes->{$colorcode}; defined $colorcode or die "Unknown color name '$colorcode'";
        }
        my $ansifg = Color::ANSI::Util::ansifg($colorcode);
        my $ansibg = Color::ANSI::Util::ansibg($colorcode);
        push @rows, {
            name => $colorname,
            rgb_code => $colorcode,
            ansi_fg_code => Data::Dmp::dmp($ansifg),
            ansi_bg_code => Data::Dmp::dmp($ansibg),
            fg =>
                $ansifg . "This is text with foreground color $colorname (#$colorcode)" . Color::ANSI::Util::ansi_reset(1) . "\n" .
                $ansifg . "\e[1m" . "This is text with foreground color $colorname (#$colorcode) + BOLD" . Color::ANSI::Util::ansi_reset(1) . "\n",
            bg => $ansibg . Color::ANSI::Util::ansifg(Color::RGB::Util::rgb_is_light($colorcode) ? "000000":"ffffff") . "This is text with background color $colorname (#$colorcode)" . Color::ANSI::Util::ansi_reset(1),
        };
    }
    [200, "OK", \@rows];
}

$SPEC{show_colors_from_scheme} = {
    v => 1.1,
    summary => 'Show colors from a Graphics::ColorNames scheme',
    args => {
        scheme => {
            schema => 'perl::colorscheme::modname*',
            req => 1,
            pos => 0,
        },
    },
};
sub show_colors_from_scheme {
    my %args = @_;
    my $mod = "Graphics::ColorNames::$args{scheme}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $table = $mod->NamesRgbTable;
    show_colors(colors => [sort keys %$table]);
}

$SPEC{show_colors_from_theme} = {
    v => 1.1,
    summary => 'Show colors from a ColorTheme scheme',
    args => {
        theme => {
            schema => 'perl::colortheme::modname_with_optional_args*',
            req => 1,
            pos => 0,
        },
    },
    links => [
        {url=>'prog:show-color-theme-swatch'},
    ],
};
sub show_colors_from_theme {
    require Module::Load::Util;

    my %args = @_;
    my $mod = $args{theme}; $mod = "ColorTheme::$mod" unless $mod =~ /^ColorTheme::/;
    my $theme = Module::Load::Util::instantiate_class_with_optional_args($mod);

    my @item_names = $theme->list_items;
    my %colors;
    for my $item ($theme->list_items) {
        my $k = $item;
        my $v = $theme->get_item_color($item);
        if (ref $v) {
            $k = "$k (hash or coderef)";
            $v = "ffffff";
        }
        $colors{$k} = $v;
    }
    show_colors(_colors_hash =>\%colors);
}

$SPEC{show_assigned_rgb_colors} = {
    v => 1.1,
    summary => 'Take arguments, pass them through assign_rgb_color(), show the results',
    description => <<'_',

`assign_rgb_color()` from <pm:Color::RGB::Util> takes a string, produce SHA1
digest from it, then take 24bit from the digest as the assigned color.

_
    args => {
        strings => {
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        tone => {
            schema => ['str*', in=>['light', 'dark']],
            cmdline_aliases => {
                light => {is_flag=>1, summary=>'Shortcut for --tone=light', code=>sub { $_[0]{tone} = 'light' }},
                dark  => {is_flag=>1, summary=>'Shortcut for --tone=dark' , code=>sub { $_[0]{tone} = 'dark'  }},
            },
        },
    },
};
sub show_assigned_rgb_colors {
    require Color::ANSI::Util;
    require Color::RGB::Util;

    my %args = @_;

    my $tone = $args{tone} // '';
    my $strings = $args{strings};

    my @rows;
    for (0 .. $#{ $strings }) {
        my $str = $strings->[$_];
        my $rgb =
            $tone eq 'light' ? Color::RGB::Util::assign_rgb_light_color($str) :
            $tone eq 'dark'  ? Color::RGB::Util::assign_rgb_dark_color($str) :
            Color::RGB::Util::assign_rgb_color($str);
        push @rows, {
            number => $_+1,
            string => $str,
            color  => sprintf("%s%s\e[0m", Color::ANSI::Util::ansifg($rgb), "'$str' is assigned color #$rgb"),
            "light?" => Color::RGB::Util::rgb_is_light($rgb),
        };
    }
    [200, "OK", \@rows, {"table.fields" => [qw/number string color light?/]}];
}

$SPEC{show_rand_rgb_colors} = {
    v => 1.1,
    summary => 'Produce N random RGB colors using rand_rgb_colors() and show the results',
    args => {
        n => {
            schema => 'posint*',
            req => 1,
            pos => 0,
        },
        light_color => {
            schema => 'bool',
            default => 1,
            cmdline_aliases => {
                light_or_dark_color => {is_flag=>1, code=>sub { $_[0]{light_color} = undef }},
                dark_color          => {is_flag=>1, code=>sub { $_[0]{light_color} = 0 }},
            },
        },
    },
};
sub show_rand_rgb_colors {
    require Color::ANSI::Util;
    require Color::RGB::Util;

    my %args = @_;
    my $n = $args{n};

    my @colors = Color::RGB::Util::rand_rgb_colors({
        light_color => $args{light_color},
    }, $n);
    my @rows;
    for (1 .. $n) {
        my $color = $colors[$_-1];
        push @rows, {
            number => $_,
            color  => sprintf("%s      %s      \e[0m",
                              Color::ANSI::Util::ansifg(Color::RGB::Util::rgb_is_dark($color) ? "ffffff" : "000000").
                                    Color::ANSI::Util::ansibg($color),
                              "#".$color),
        };
    }
    [200, "OK", \@rows, {"table.fields" => [qw/number color/]}];
}

$SPEC{show_text_using_color_gradation} = {
    v => 1.1,
    summary => 'Print text using gradation between two colors',
    description => <<'_',

This can be used to demonstrate 24bit color support in terminal emulators.

_
    args => {
        text => {
            schema => ['str*', min_len=>1],
            pos => 0,
            description => <<'_',

If unspecified, will show a bar of '=' across the terminal.

_
        },
        color1 => {
            schema => 'color::rgb24*',
            default => 'ffff00',
        },
        color2 => {
            schema => 'color::rgb24*',
            default => '0000ff',
        },
    },
    examples => [
        {
            args => {color1=>'blue', color2=>'pink', text=>'Hello, world'},
            test => 0,
            'x.doc_show_result'=>0,
        },
    ],
};
sub show_text_using_color_gradation {
    require Color::ANSI::Util;
    require Color::RGB::Util;
    require Term::Size;

    my %args = @_;

    my $color1 = $args{color1};
    my $color2 = $args{color2};

    my $text = $args{text};
    $text //= do {
        my $width = $ENV{COLUMNS} // (Term::Size::chars(*STDOUT{IO}))[0] // 80;
        "X" x $width;
    };
    my $len = length $text;
    my $i = 0;
    for my $c (split //, $text) {
        $i++;
        my $color = Color::RGB::Util::mix_2_rgb_colors($color1, $color2, $i/$len);
        print Color::ANSI::Util::ansifg($color), $c;
    }
    print "\n\e[0m";

    [200];
}

1;
# ABSTRACT: Utilities related to ANSI color

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ANSIColorUtils - Utilities related to ANSI color

=head1 VERSION

This document describes version 0.011 of App::ANSIColorUtils (from Perl distribution App-ANSIColorUtils), released on 2025-03-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item 1. L<ansi16-to-rgb>

=item 2. L<ansi256-to-rgb>

=item 3. L<rgb-to-ansi-bg-code>

=item 4. L<rgb-to-ansi-fg-code>

=item 5. L<rgb-to-ansi16>

=item 6. L<rgb-to-ansi16-bg-code>

=item 7. L<rgb-to-ansi16-fg-code>

=item 8. L<rgb-to-ansi24b-bg-code>

=item 9. L<rgb-to-ansi24b-fg-code>

=item 10. L<rgb-to-ansi256>

=item 11. L<rgb-to-ansi256-bg-code>

=item 12. L<rgb-to-ansi256-fg-code>

=item 13. L<show-ansi-color-table>

=item 14. L<show-assigned-rgb-colors>

=item 15. L<show-colors>

=item 16. L<show-colors-from-scheme>

=item 17. L<show-colors-from-theme>

=item 18. L<show-rand-rgb-colors>

=item 19. L<show-text-using-color-gradation>

=back

=head1 FUNCTIONS


=head2 show_ansi_color_table

Usage:

 show_ansi_color_table(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show a table of ANSI codes & colors.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<width> => I<str> (default: 8)

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



=head2 show_assigned_rgb_colors

Usage:

 show_assigned_rgb_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Take arguments, pass them through assign_rgb_color(), show the results.

C<assign_rgb_color()> from L<Color::RGB::Util> takes a string, produce SHA1
digest from it, then take 24bit from the digest as the assigned color.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

(No description)

=item * B<tone> => I<str>

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



=head2 show_colors

Usage:

 show_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show colors specified in argument as text with ANSI colors.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<colors>* => I<array[str]>

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



=head2 show_colors_from_scheme

Usage:

 show_colors_from_scheme(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show colors from a Graphics::ColorNames scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<perl::colorscheme::modname>

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



=head2 show_colors_from_theme

Usage:

 show_colors_from_theme(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show colors from a ColorTheme scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<theme>* => I<perl::colortheme::modname_with_optional_args>

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



=head2 show_rand_rgb_colors

Usage:

 show_rand_rgb_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

Produce N random RGB colors using rand_rgb_colors() and show the results.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<light_color> => I<bool> (default: 1)

(No description)

=item * B<n>* => I<posint>

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



=head2 show_text_using_color_gradation

Usage:

 show_text_using_color_gradation(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print text using gradation between two colors.

Examples:

=over

=item * Example #1:

 show_text_using_color_gradation(text => "Hello, world", color1 => "blue", color2 => "pink");

Result:

 [200, undef, undef, {}]

=back

This can be used to demonstrate 24bit color support in terminal emulators.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color1> => I<color::rgb24> (default: "ffff00")

(No description)

=item * B<color2> => I<color::rgb24> (default: "0000ff")

(No description)

=item * B<text> => I<str>

If unspecified, will show a bar of '=' across the terminal.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ANSIColorUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ANSIColorUtils>.

=head1 SEE ALSO

L<App::RGBColorUtils>

L<App::GraphicsColorNamesUtils>

L<App::ColorThemeUtils>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ANSIColorUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
