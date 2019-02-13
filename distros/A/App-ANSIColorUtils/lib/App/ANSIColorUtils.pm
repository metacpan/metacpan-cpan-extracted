package App::ANSIColorUtils;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.004'; # VERSION

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

1;
# ABSTRACT: Utilities related to ANSI color

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ANSIColorUtils - Utilities related to ANSI color

=head1 VERSION

This document describes version 0.004 of App::ANSIColorUtils (from Perl distribution App-ANSIColorUtils), released on 2019-02-13.

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
