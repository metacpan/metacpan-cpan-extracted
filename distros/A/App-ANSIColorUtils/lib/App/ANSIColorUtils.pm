package App::ANSIColorUtils;

our $DATE = '2019-08-20'; # DATE
our $VERSION = '0.006'; # VERSION

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

This document describes version 0.006 of App::ANSIColorUtils (from Perl distribution App-ANSIColorUtils), released on 2019-08-20.

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



=head2 show_text_using_color_gradation

Usage:

 show_text_using_color_gradation(%args) -> [status, msg, payload, meta]

Print text using gradation between two colors.

Examples:

=over

=item * Example #1:

 show_text_using_color_gradation(text => "Hello, world", color1 => "blue", color2 => "pink"); # -> undef

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ANSIColorUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
