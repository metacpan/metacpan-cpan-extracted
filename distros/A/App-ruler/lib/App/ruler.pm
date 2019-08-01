package App::ruler;

our $DATE = '2019-07-30'; # DATE
our $VERSION = '0.060'; # VERSION

use feature 'say';
use strict 'subs', 'vars';
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       ruler
               );

our %SPEC;

my $term_width;
if (eval { require Term::Size; 1 }) {
    ($term_width, undef) = Term::Size::chars(*STDOUT{IO});
} else {
    $term_width = 80;
}

sub _colored {
    require Term::ANSIColor;
    Term::ANSIColor::colored(@_);
}

$SPEC{ruler} = {
    v => 1.1,
    summary => 'Print horizontal ruler on the terminal',
    args_rels => {
        'choose_one&' => [
            #[qw/color random_color/],
        ],
    },
    args => {
        length => {
            schema => ['int*', min=>0],
            cmdline_aliases => {l=>{}},
        },
        background_pattern => {
            schema => ['str*', min_len=>1],
            default => '-',
            cmdline_aliases => {bg=>{}},
        },
        background_color => {
            schema => ['str*'],
        },

        major_tick_every => {
            schema => ['int*', min=>1],
            default => 10,
            cmdline_aliases => {N=>{}},
        },
        major_tick_character => {
            schema => ['str', max_len=>1],
            default => '|',
            cmdline_aliases => {M=>{}},
        },
        major_tick_color => {
            schema => ['str*'],
        },

        minor_tick_every => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        minor_tick_character => {
            schema => ['str', max_len=>1],
            default => '.',
            cmdline_aliases => {m=>{}},
        },
        minor_tick_color => {
            schema => ['str*'],
        },

        number_every => {
            schema => ['int*', min=>0], # 0 means do not draw
            default => 10,
        },
        number_start => {
            schema => ['int*', min=>0],
            default => 10,
        },
        number_format => {
            schema => ['str*'],
            default => '%d',
            cmdline_aliases => {f=>{}},
        },
        number_color => {
            schema => ['str*'],
        },
    },
    examples => [
        {
            summary => 'Default ruler (dash + number every 10 characters)',
            args => {},
        },
        {
            summary => 'White ruler with red marks and numbers',
            args => {
                background_color => "black on_white",
                minor_tick_character => '',
                major_tick_color => "red on_white",
                number_color => "bold red on_white",
            },
        },
    ],
};
sub ruler {
    my %args = @_;

    my $ruler_len = $args{length} // $term_width;
    my $use_color;

    # draw background
    my $bgpat = $args{background_pattern} // '-';
    my $ruler = $bgpat x (int($ruler_len / length($bgpat)) + 1);
    if ($args{background_color}) {
        $use_color++;
        $ruler = _colored($ruler, $args{background_color});
    }

    # draw minor ticks
    my $mintickchar = $args{minor_tick_character} // '.';
    if ($args{minor_tick_color} && length($mintickchar)) {
        $use_color++;
        $mintickchar = _colored($mintickchar, $args{minor_tick_color});
    }
    if (length $mintickchar) {
        my $every = $args{minor_tick_every} // 1;
        for (1..$ruler_len) {
            if ($_ % $every == 0) {
                if ($use_color) {
                    require Text::ANSI::Util;
                    $ruler = Text::ANSI::Util::ta_substr($ruler, $_-1, 1, $mintickchar);
                } else {
                    substr($ruler, $_-1, 1) = $mintickchar;
                }
            }
        }
    }

    # draw major ticks
    my $majtickchar = $args{major_tick_character} // '|';
    if ($args{major_tick_color} && length($majtickchar)) {
        $use_color++;
        $majtickchar = _colored($majtickchar, $args{major_tick_color});
    }
    if (length $majtickchar) {
        my $every = $args{major_tick_every} // 10;
        for (1..$ruler_len) {
            if ($_ % $every == 0) {
                if ($use_color) {
                    require Text::ANSI::Util;
                    $ruler = Text::ANSI::Util::ta_substr($ruler, $_-1, 1, $majtickchar);
                } else {
                    substr($ruler, $_-1, 1) = $majtickchar;
                }
            }
        }
    }

    # draw numbers
    {
        no warnings; # e.g. when sprintf('', $_)
        my $numevery = $args{number_every} // 10;
        last unless $numevery > 0;
        my $numstart = $args{number_start} // 10;
        my $fmt = $args{number_format} // '%d';
        $use_color++ if $args{number_color};
        for ($numstart..$ruler_len) {
            if ($_ % $numevery == 0) {
                my $num = sprintf($fmt, $_);
                my $num_len;
                if ($args{number_color}) {
                    $num = _colored($num, $args{number_color});
                    require Text::ANSI::Util;
                    $num_len = Text::ANSI::Util::ta_length($num);
                } else {
                    $num_len = length($num);
                }
                if ($use_color) {
                    require Text::ANSI::Util;
                    $ruler = Text::ANSI::Util::ta_substr($ruler, $_, $num_len, $num);
                } else {
                    substr($ruler, $_, $num_len) = $num;
                }
            }
        }
    }

    # final clip
    if ($use_color) {
        require Text::ANSI::Util;
        $ruler = Text::ANSI::Util::ta_substr($ruler, 0, $ruler_len);
    } else {
        $ruler = substr($ruler, 0, $ruler_len);
    }
    $ruler .= "\n"
        unless $ruler_len == ($^O =~ /Win32/ ? $term_width-1 : $term_width);

    [200, "OK", $ruler];
}

1;
# ABSTRACT: Print horizontal ruler on the terminal

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ruler - Print horizontal ruler on the terminal

=head1 VERSION

This document describes version 0.060 of App::ruler (from Perl distribution App-ruler), released on 2019-07-30.

=head1 TIPS

To see background pattern, disable minor ticking by using C<< -m '' >>.

To disable numbering, set number format to an empty string: C<< -f '' >> or C<<
--number-every 0 >>.

=head1 FUNCTIONS


=head2 ruler

Usage:

 ruler(%args) -> [status, msg, payload, meta]

Print horizontal ruler on the terminal.

Examples:

=over

=item * Default ruler (dash + number every 10 characters):

 ruler();

Result:

 ".........|10.......|20.......|30.......|40.......|50.......|60.......|70.......|80.......|90.......|100......|110......|120......|130......|140......|150......|160......|170......|180......|19"

=item * White ruler with red marks and numbers:

 ruler(
 background_color     => "black on_white",
   major_tick_color     => "red on_white",
   minor_tick_character => "",
   number_color         => "bold red on_white"
 );

Result:

 "\e[30;47m---------\e[0m\e[31;47m|\e[0m\e[1;31;47m10\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m20\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m30\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m40\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m50\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m60\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m70\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m80\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m90\e[0m\e[30;47m-------\e[0m\e[31;47m|\e[0m\e[1;31;47m100\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m110\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m120\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m130\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m140\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m150\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m160\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m170\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m180\e[0m\e[30;47m------\e[0m\e[31;47m|\e[0m\e[1;31;47m19\e[0m"

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<background_color> => I<str>

=item * B<background_pattern> => I<str> (default: "-")

=item * B<length> => I<int>

=item * B<major_tick_character> => I<str> (default: "|")

=item * B<major_tick_color> => I<str>

=item * B<major_tick_every> => I<int> (default: 10)

=item * B<minor_tick_character> => I<str> (default: ".")

=item * B<minor_tick_color> => I<str>

=item * B<minor_tick_every> => I<int> (default: 1)

=item * B<number_color> => I<str>

=item * B<number_every> => I<int> (default: 10)

=item * B<number_format> => I<str> (default: "%d")

=item * B<number_start> => I<int> (default: 10)

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ruler>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ruler>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ruler>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<hr> (L<App::hr>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
