package App::ANSIColorUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'App-ANSIColorUtils'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

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

    my @rows;
    my $j = -1;
    for my $name (@{ $args{colors} }) {
        $j++;
        my $code;
        if ($name =~ /\A[0-9A-fa-f]{6}\z/) {
            $code = $name;
        } else {
            $code = $codes->{$name}; defined $code or die "Unknown color name '$name'";
        }
        my $ansifg = Color::ANSI::Util::ansifg($code);
        my $ansibg = Color::ANSI::Util::ansibg($code);
        push @rows, {
            name => $name,
            rgb_code => $code,
            ansi_fg_code => Data::Dmp::dmp($ansifg),
            ansi_bg_code => Data::Dmp::dmp($ansibg),
            fg =>
                $ansifg . "This is text with foreground color $name (#$code)" . Color::ANSI::Util::ansi_reset(1) . "\n" .
                $ansifg . "\e[1m" . "This is text with foreground color $name (#$code) + BOLD" . Color::ANSI::Util::ansi_reset(1) . "\n",
            bg => $ansibg . Color::ANSI::Util::ansifg(Color::RGB::Util::rgb_is_light($code) ? "000000":"ffffff") . "This is text with background color $name (#$code)" . Color::ANSI::Util::ansi_reset(1),
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

This document describes version 0.009 of App::ANSIColorUtils (from Perl distribution App-ANSIColorUtils), released on 2021-01-20.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<ansi16-to-rgb>

=item * L<ansi256-to-rgb>

=item * L<rgb-to-ansi-bg-code>

=item * L<rgb-to-ansi-fg-code>

=item * L<rgb-to-ansi16>

=item * L<rgb-to-ansi16-bg-code>

=item * L<rgb-to-ansi16-fg-code>

=item * L<rgb-to-ansi24b-bg-code>

=item * L<rgb-to-ansi24b-fg-code>

=item * L<rgb-to-ansi256>

=item * L<rgb-to-ansi256-bg-code>

=item * L<rgb-to-ansi256-fg-code>

=item * L<show-ansi-color-table>

=item * L<show-assigned-rgb-colors>

=item * L<show-colors>

=item * L<show-colors-from-scheme>

=item * L<show-rand-rgb-colors>

=item * L<show-text-using-color-gradation>

=back

=head1 FUNCTIONS


=head2 show_ansi_color_table

Usage:

 show_ansi_color_table(%args) -> [status, msg, payload, meta]

Show a table of ANSI codes & colors.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<width> => I<str> (default: 8)


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_assigned_rgb_colors

Usage:

 show_assigned_rgb_colors(%args) -> [status, msg, payload, meta]

Take arguments, pass them through assign_rgb_color(), show the results.

C<assign_rgb_color()> from L<Color::RGB::Util> takes a string, produce SHA1
digest from it, then take 24bit from the digest as the assigned color.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=item * B<tone> => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_colors

Usage:

 show_colors(%args) -> [status, msg, payload, meta]

Show colors specified in argument as text with ANSI colors.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<colors>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_colors_from_scheme

Usage:

 show_colors_from_scheme(%args) -> [status, msg, payload, meta]

Show colors from a Graphics::ColorNames scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<perl::colorscheme::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_rand_rgb_colors

Usage:

 show_rand_rgb_colors(%args) -> [status, msg, payload, meta]

Produce N random RGB colors using rand_rgb_colors() and show the results.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<light_color> => I<bool> (default: 1)

=item * B<n>* => I<posint>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_text_using_color_gradation

Usage:

 show_text_using_color_gradation(%args) -> [status, msg, payload, meta]

Print text using gradation between two colors.

Examples:

=over

=item * Example #1:

 show_text_using_color_gradation(text => "Hello, world", color1 => "blue", color2 => "pink");

Result:

 [undef, "0000ff", undef, {}]

=back

This can be used to demonstrate 24bit color support in terminal emulators.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color1> => I<color::rgb24> (default: "ffff00")

=item * B<color2> => I<color::rgb24> (default: "0000ff")

=item * B<text> => I<str>

If unspecified, will show a bar of '=' across the terminal.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ANSIColorUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ANSIColorUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-ANSIColorUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
