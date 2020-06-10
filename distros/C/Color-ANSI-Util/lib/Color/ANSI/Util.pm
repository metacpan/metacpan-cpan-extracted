package Color::ANSI::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'Color-ANSI-Util'; # DIST
our $VERSION = '0.164'; # VERSION

use 5.010001;
use strict;
use warnings;

use Color::RGB::Util qw(rgb_diff);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       ansi16_to_rgb
                       rgb_to_ansi16
                       rgb_to_ansi16_fg_code
                       ansi16fg
                       rgb_to_ansi16_bg_code
                       ansi16bg

                       ansi256_to_rgb
                       rgb_to_ansi256
                       rgb_to_ansi256_fg_code
                       ansi256fg
                       rgb_to_ansi256_bg_code
                       ansi256bg

                       rgb_to_ansi24b_fg_code
                       ansi24bfg
                       rgb_to_ansi24b_bg_code
                       ansi24bbg

                       rgb_to_ansi_fg_code
                       ansifg
                       rgb_to_ansi_bg_code
                       ansibg

                       ansi_reset
               );

our %SPEC;

my %ansi16 = (
    0  => '000000',
    1  => '800000',
    2  => '008000',
    3  => '808000',
    4  => '000080',
    5  => '800080',
    6  => '008080',
    7  => 'c0c0c0',
    8  => '808080',
    9  => 'ff0000',
    10 => '00ff00',
    11 => 'ffff00',
    12 => '0000ff',
    13 => 'ff00ff',
    14 => '00ffff',
    15 => 'ffffff',
);
my @revansi16;
for my $idx (sort {$a<=>$b} keys %ansi16) {
    push @revansi16, [$ansi16{$idx}, $idx];
}

my %ansi256 = (
    %ansi16,

    16 => '000000',  17 => '00005f',  18 => '000087',  19 => '0000af',  20 => '0000d7',  21 => '0000ff',
    22 => '005f00',  23 => '005f5f',  24 => '005f87',  25 => '005faf',  26 => '005fd7',  27 => '005fff',
    28 => '008700',  29 => '00875f',  30 => '008787',  31 => '0087af',  32 => '0087d7',  33 => '0087ff',
    34 => '00af00',  35 => '00af5f',  36 => '00af87',  37 => '00afaf',  38 => '00afd7',  39 => '00afff',
    40 => '00d700',  41 => '00d75f',  42 => '00d787',  43 => '00d7af',  44 => '00d7d7',  45 => '00d7ff',
    46 => '00ff00',  47 => '00ff5f',  48 => '00ff87',  49 => '00ffaf',  50 => '00ffd7',  51 => '00ffff',
    52 => '5f0000',  53 => '5f005f',  54 => '5f0087',  55 => '5f00af',  56 => '5f00d7',  57 => '5f00ff',
    58 => '5f5f00',  59 => '5f5f5f',  60 => '5f5f87',  61 => '5f5faf',  62 => '5f5fd7',  63 => '5f5fff',
    64 => '5f8700',  65 => '5f875f',  66 => '5f8787',  67 => '5f87af',  68 => '5f87d7',  69 => '5f87ff',
    70 => '5faf00',  71 => '5faf5f',  72 => '5faf87',  73 => '5fafaf',  74 => '5fafd7',  75 => '5fafff',
    76 => '5fd700',  77 => '5fd75f',  78 => '5fd787',  79 => '5fd7af',  80 => '5fd7d7',  81 => '5fd7ff',
    82 => '5fff00',  83 => '5fff5f',  84 => '5fff87',  85 => '5fffaf',  86 => '5fffd7',  87 => '5fffff',
    88 => '870000',  89 => '87005f',  90 => '870087',  91 => '8700af',  92 => '8700d7',  93 => '8700ff',
    94 => '875f00',  95 => '875f5f',  96 => '875f87',  97 => '875faf',  98 => '875fd7',  99 => '875fff',
    100 => '878700', 101 => '87875f', 102 => '878787', 103 => '8787af', 104 => '8787d7', 105 => '8787ff',
    106 => '87af00', 107 => '87af5f', 108 => '87af87', 109 => '87afaf', 110 => '87afd7', 111 => '87afff',
    112 => '87d700', 113 => '87d75f', 114 => '87d787', 115 => '87d7af', 116 => '87d7d7', 117 => '87d7ff',
    118 => '87ff00', 119 => '87ff5f', 120 => '87ff87', 121 => '87ffaf', 122 => '87ffd7', 123 => '87ffff',
    124 => 'af0000', 125 => 'af005f', 126 => 'af0087', 127 => 'af00af', 128 => 'af00d7', 129 => 'af00ff',
    130 => 'af5f00', 131 => 'af5f5f', 132 => 'af5f87', 133 => 'af5faf', 134 => 'af5fd7', 135 => 'af5fff',
    136 => 'af8700', 137 => 'af875f', 138 => 'af8787', 139 => 'af87af', 140 => 'af87d7', 141 => 'af87ff',
    142 => 'afaf00', 143 => 'afaf5f', 144 => 'afaf87', 145 => 'afafaf', 146 => 'afafd7', 147 => 'afafff',
    148 => 'afd700', 149 => 'afd75f', 150 => 'afd787', 151 => 'afd7af', 152 => 'afd7d7', 153 => 'afd7ff',
    154 => 'afff00', 155 => 'afff5f', 156 => 'afff87', 157 => 'afffaf', 158 => 'afffd7', 159 => 'afffff',
    160 => 'd70000', 161 => 'd7005f', 162 => 'd70087', 163 => 'd700af', 164 => 'd700d7', 165 => 'd700ff',
    166 => 'd75f00', 167 => 'd75f5f', 168 => 'd75f87', 169 => 'd75faf', 170 => 'd75fd7', 171 => 'd75fff',
    172 => 'd78700', 173 => 'd7875f', 174 => 'd78787', 175 => 'd787af', 176 => 'd787d7', 177 => 'd787ff',
    178 => 'd7af00', 179 => 'd7af5f', 180 => 'd7af87', 181 => 'd7afaf', 182 => 'd7afd7', 183 => 'd7afff',
    184 => 'd7d700', 185 => 'd7d75f', 186 => 'd7d787', 187 => 'd7d7af', 188 => 'd7d7d7', 189 => 'd7d7ff',
    190 => 'd7ff00', 191 => 'd7ff5f', 192 => 'd7ff87', 193 => 'd7ffaf', 194 => 'd7ffd7', 195 => 'd7ffff',
    196 => 'ff0000', 197 => 'ff005f', 198 => 'ff0087', 199 => 'ff00af', 200 => 'ff00d7', 201 => 'ff00ff',
    202 => 'ff5f00', 203 => 'ff5f5f', 204 => 'ff5f87', 205 => 'ff5faf', 206 => 'ff5fd7', 207 => 'ff5fff',
    208 => 'ff8700', 209 => 'ff875f', 210 => 'ff8787', 211 => 'ff87af', 212 => 'ff87d7', 213 => 'ff87ff',
    214 => 'ffaf00', 215 => 'ffaf5f', 216 => 'ffaf87', 217 => 'ffafaf', 218 => 'ffafd7', 219 => 'ffafff',
    220 => 'ffd700', 221 => 'ffd75f', 222 => 'ffd787', 223 => 'ffd7af', 224 => 'ffd7d7', 225 => 'ffd7ff',
    226 => 'ffff00', 227 => 'ffff5f', 228 => 'ffff87', 229 => 'ffffaf', 230 => 'ffffd7', 231 => 'ffffff',

    232 => '080808', 233 => '121212', 234 => '1c1c1c', 235 => '262626', 236 => '303030', 237 => '3a3a3a',
    238 => '444444', 239 => '4e4e4e', 240 => '585858', 241 => '606060', 242 => '666666', 243 => '767676',
    244 => '808080', 245 => '8a8a8a', 246 => '949494', 247 => '9e9e9e', 248 => 'a8a8a8', 249 => 'b2b2b2',
    250 => 'bcbcbc', 251 => 'c6c6c6', 252 => 'd0d0d0', 253 => 'dadada', 254 => 'e4e4e4', 255 => 'eeeeee',
);
my @revansi256;
for my $idx (sort {$a<=>$b} keys %ansi256) {
    push @revansi256, [$ansi256{$idx}, $idx];
}

$SPEC{ansi16_to_rgb} = {
    v => 1.1,
    summary => 'Convert ANSI-16 color to RGB',
    description => <<'_',

Returns 6-hexdigit, e.g. 'ff00cc'.

_
    args => {
        color => {
            schema => 'color::ansi16*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'color::rgb24*',
    },
    result_naked => 1,
};
sub ansi16_to_rgb {
    my ($input) = @_;

    if ($input =~ /^\d+$/) {
        if ($input >= 0 && $input <= 15) {
            return $ansi16{$input + 0}; # to remove prefix zero e.g. "06"
        } else {
            die "Invalid ANSI 16-color number '$input'";
        }
    } elsif ($input =~ /^(?:(bold|bright) \s )?(black|red|green|yellow|blue|magenta|cyan|white)$/ix) {
        my ($bold, $col) = (lc($1 // ""), lc($2));
        my $i;
        if ($col eq 'black') {
            $i = 0;
        } elsif ($col eq 'red') {
            $i = 1;
        } elsif ($col eq 'green') {
            $i = 2;
        } elsif ($col eq 'yellow') {
            $i = 3;
        } elsif ($col eq 'blue') {
            $i = 4;
        } elsif ($col eq 'magenta') {
            $i = 5;
        } elsif ($col eq 'cyan') {
            $i = 6;
        } elsif ($col eq 'white') {
            $i = 7;
        }
        $i += 8 if $bold;
        return $ansi16{$i};
    } else {
        die "Invalid ANSI 16-color name '$input'";
    }
}

sub _rgb_to_indexed {
    my ($rgb, $table) = @_;

    my ($smallest_diff, $res);
    for my $e (@$table) {
        my $diff = rgb_diff($rgb, $e->[0], 'hsv_hue1');
        # exact match, return immediately
        return $e->[1] if $diff == 0;
        if (!defined($smallest_diff) || $smallest_diff > $diff) {
            $smallest_diff = $diff;
            $res = $e->[1];
        }
    }
    return $res;
}

$SPEC{ansi256_to_rgb} = {
    v => 1.1,
    summary => 'Convert ANSI-256 color to RGB',
    args => {
        color => {
            schema => 'color::ansi256*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'color::rgb24',
    },
    result_naked => 1,
};
sub ansi256_to_rgb {
    my ($input) = @_;

    $input += 0;
    exists($ansi256{$input}) or die "Invalid ANSI 256-color index '$input'";
    $ansi256{$input};
}

$SPEC{rgb_to_ansi16} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-16 color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'color::ansi16*',
    },
    result_naked => 1,
};
sub rgb_to_ansi16 {
    my ($input) = @_;
    _rgb_to_indexed($input, \@revansi16);
}

$SPEC{rgb_to_ansi256} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-256 color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'color::ansi256*',
    },
    result_naked => 1,
};
sub rgb_to_ansi256 {
    my ($input) = @_;
    _rgb_to_indexed($input, \@revansi256);
}

$SPEC{rgb_to_ansi16_fg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-16 color escape sequence to change foreground color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi16_fg_code {
    my ($input) = @_;

    my $res = _rgb_to_indexed($input, \@revansi16);
    return "\e[" . ($res >= 8 ? ($res+30-8) . ";1" : ($res+30)) . "m";
}

sub ansi16fg  { goto &rgb_to_ansi16_fg_code  }

$SPEC{rgb_to_ansi16_bg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-16 color escape sequence to change background color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi16_bg_code {
    my ($input) = @_;

    my $res = _rgb_to_indexed($input, \@revansi16);
    return "\e[" . ($res >= 8 ? ($res+40-8) : ($res+40)) . "m";
}

sub ansi16bg  { goto &rgb_to_ansi16_bg_code  }

$SPEC{rgb_to_ansi256_fg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-256 color escape sequence to change foreground color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi256_fg_code {
    my ($input) = @_;

    my $res = _rgb_to_indexed($input, \@revansi16);
    return "\e[38;5;${res}m";
}

sub ansi256fg { goto &rgb_to_ansi256_fg_code }

$SPEC{rgb_to_ansi256_bg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI-256 color escape sequence to change background color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi256_bg_code {
    my ($input) = @_;

    my $res = _rgb_to_indexed($input, \@revansi16);
    return "\e[48;5;${res}m";
}

sub ansi256bg { goto &rgb_to_ansi256_bg_code }

$SPEC{rgb_to_ansi24b_fg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI 24bit-color escape sequence to change foreground color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi24b_fg_code {
    my ($rgb) = @_;

    return sprintf("\e[38;2;%d;%d;%dm",
                   hex(substr($rgb, 0, 2)),
                   hex(substr($rgb, 2, 2)),
                   hex(substr($rgb, 4, 2)));
}

sub ansi24bfg { goto &rgb_to_ansi24b_fg_code }

$SPEC{rgb_to_ansi24b_bg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI 24bit-color escape sequence to change background color',
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi24b_bg_code {
    my ($rgb) = @_;

    return sprintf("\e[48;2;%d;%d;%dm",
                   hex(substr($rgb, 0, 2)),
                   hex(substr($rgb, 2, 2)),
                   hex(substr($rgb, 4, 2)));
}

sub ansi24bbg { goto &rgb_to_ansi24b_bg_code }

our $_use_termdetsw = 1;
our $_color_depth; # cache, can be set during testing
sub _color_depth {
    unless (defined $_color_depth) {
        {
            if (exists $ENV{NO_COLOR}) {
                $_color_depth = 0;
                last;
            }
            if (defined $ENV{COLOR} && !$ENV{COLOR}) {
                $_color_depth = 0;
                last;
            }
            if (defined $ENV{COLOR_DEPTH}) {
                $_color_depth = $ENV{COLOR_DEPTH};
                last;
            }
            if ($_use_termdetsw) {
                eval { require Term::Detect::Software };
                if (!$@) {
                    $_color_depth = Term::Detect::Software::detect_terminal_cached()->{color_depth};
                    last;
                }
            }
            # simple heuristic
            if ($ENV{KONSOLE_DBUS_SERVICE}) {
                $_color_depth = 2**24;
                last;
            }
            # safe value
            $_color_depth = 16;
        }
    };
    $_color_depth;
}

$SPEC{rgb_to_ansi_fg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI color escape sequence to change foreground color',
    description => <<'_',

Autodetect terminal capability and can return either empty string, 16-color,
256-color, or 24bit-code.

Color depth used is determined by `COLOR_DEPTH` environment setting or from
<pm:Term::Detect::Software> if that module is available. In other words, this
function automatically chooses rgb_to_ansi{24b,256,16}_fg_code().

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi_fg_code {
    my ($rgb) = @_;
    my $cd = _color_depth();
    if ($cd >= 2**24) {
        rgb_to_ansi24b_fg_code($rgb);
    } elsif ($cd >= 256) {
        rgb_to_ansi256_fg_code($rgb);
    } elsif ($cd >= 16) {
        rgb_to_ansi16_fg_code($rgb);
    } else {
        "";
    }
}

sub ansifg { goto &rgb_to_ansi_fg_code }

$SPEC{rgb_to_ansi_bg_code} = {
    v => 1.1,
    summary => 'Convert RGB to ANSI color escape sequence to change background color',
    description => <<'_',

Autodetect terminal capability and can return either empty string, 16-color,
256-color, or 24bit-code.

Which color depth used is determined by `COLOR_DEPTH` environment setting or
from <pm:Term::Detect::Software> if that module is available). In other words,
this function automatically chooses rgb_to_ansi{24b,256,16}_bg_code().

_
    args => {
        color => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub rgb_to_ansi_bg_code {
    my ($rgb) = @_;
    my $cd = _color_depth();
    if ($cd >= 2**24) {
        rgb_to_ansi24b_bg_code($rgb);
    } elsif ($cd >= 256) {
        rgb_to_ansi256_bg_code($rgb);
    } else {
        rgb_to_ansi16_bg_code($rgb);
    }
}

sub ansibg { goto &rgb_to_ansi_bg_code }

sub ansi_reset {
    my $conditional = shift;
    if ($conditional) {
        my $cd = _color_depth();
        return "" if $cd < 16;
    }
    "\e[0m";
}

1;
# ABSTRACT: Routines for dealing with ANSI colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::ANSI::Util - Routines for dealing with ANSI colors

=head1 VERSION

This document describes version 0.164 of Color::ANSI::Util (from Perl distribution Color-ANSI-Util), released on 2020-06-09.

=head1 SYNOPSIS

 use Color::ANSI::Util qw(
     ansifg
     ansibg
 );

 say ansifg("f0c010"); # => "\e[33;1m" (on 16-color terminal)
                       # => "\e[38;5;11m" (on 256-color terminal)
                       # => "\e[38;2;240;192;16m" (on 24-bit-color terminal)

 say ansibg("ff5f87"); # => "\e[47m" (on 16-color terminal)
                       # => "\e[48;5;7m" (on 256-color terminal)
                       # => "\e[48;2;255;95;135m" (on 24-bit-color terminal)

There are a bunch of other exportable functions too, mostly for converting
between RGB and ANSI color (16/256/24bit color depth).

=head1 DESCRIPTION

This module provides routines for dealing with ANSI colors. The two main
functions are C<ansifg> and C<ansibg>. With those functions, you can specify
colors in RGB and let it output the correct ANSI color escape code according to
the color depth support of the terminal (whether 16-color, 256-color, or 24bit).
There are other functions to convert RGB to ANSI in specific color depths, or
reverse functions to convert from ANSI to RGB codes.

Keywords: xterm, xterm-256color, terminal

=head1 BUGS/NOTES

Algorithm for finding closest indexed color from RGB color currently not very
efficient. Probably can add some threshold square distance, below which we can
shortcut to the final answer.

=head1 FUNCTIONS


=head2 ansi16_to_rgb

Usage:

 ansi16_to_rgb($color) -> color::rgb24

Convert ANSI-16 color to RGB.

Returns 6-hexdigit, e.g. 'ff00cc'.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::ansi16>


=back

Return value:  (color::rgb24)



=head2 ansi256_to_rgb

Usage:

 ansi256_to_rgb($color) -> color::rgb24

Convert ANSI-256 color to RGB.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::ansi256>


=back

Return value:  (color::rgb24)



=head2 rgb_to_ansi16

Usage:

 rgb_to_ansi16($color) -> color::ansi16

Convert RGB to ANSI-16 color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (color::ansi16)



=head2 rgb_to_ansi16_bg_code

Usage:

 rgb_to_ansi16_bg_code($color) -> str

Convert RGB to ANSI-16 color escape sequence to change background color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi16_fg_code

Usage:

 rgb_to_ansi16_fg_code($color) -> str

Convert RGB to ANSI-16 color escape sequence to change foreground color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi24b_bg_code

Usage:

 rgb_to_ansi24b_bg_code($color) -> str

Convert RGB to ANSI 24bit-color escape sequence to change background color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi24b_fg_code

Usage:

 rgb_to_ansi24b_fg_code($color) -> str

Convert RGB to ANSI 24bit-color escape sequence to change foreground color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi256

Usage:

 rgb_to_ansi256($color) -> color::ansi256

Convert RGB to ANSI-256 color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (color::ansi256)



=head2 rgb_to_ansi256_bg_code

Usage:

 rgb_to_ansi256_bg_code($color) -> str

Convert RGB to ANSI-256 color escape sequence to change background color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi256_fg_code

Usage:

 rgb_to_ansi256_fg_code($color) -> str

Convert RGB to ANSI-256 color escape sequence to change foreground color.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi_bg_code

Usage:

 rgb_to_ansi_bg_code($color) -> str

Convert RGB to ANSI color escape sequence to change background color.

Autodetect terminal capability and can return either empty string, 16-color,
256-color, or 24bit-code.

Which color depth used is determined by C<COLOR_DEPTH> environment setting or
from L<Term::Detect::Software> if that module is available). In other words,
this function automatically chooses rgb_to_ansi{24b,256,16}I<bg>code().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)



=head2 rgb_to_ansi_fg_code

Usage:

 rgb_to_ansi_fg_code($color) -> str

Convert RGB to ANSI color escape sequence to change foreground color.

Autodetect terminal capability and can return either empty string, 16-color,
256-color, or 24bit-code.

Color depth used is determined by C<COLOR_DEPTH> environment setting or from
L<Term::Detect::Software> if that module is available. In other words, this
function automatically chooses rgb_to_ansi{24b,256,16}I<fg>code().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$color>* => I<color::rgb24>


=back

Return value:  (str)


=head2 ansi16fg($rgb) => STR

Alias for rgb_to_ansi16_fg_code().

=head2 ansi16bg($rgb) => STR

Alias for rgb_to_ansi16_bg_code().

=head2 ansi256fg($rgb) => STR

Alias for rgb_to_ansi256_fg_code().

=head2 ansi256bg($rgb) => STR

Alias for rgb_to_ansi256_bg_code().

=head2 ansi24bfg($rgb) => STR

Alias for rgb_to_ansi24b_fg_code().

=head2 ansi24bbg($rgb) => STR

Alias for rgb_to_ansi24b_bg_code().

=head2 rgb_to_ansi_fg_code($rgb) => STR

=head2 ansifg($rgb) => STR

Alias for rgb_to_ansi_fg_code().

=head2 ansibg($rgb) => STR

Alias for rgb_to_ansi_bg_code().

=head2 ansi_reset( [ $conditional ])

Returns "\e[0m", which is the ANSI escape sequence to reset color. Normally you
print this sequence after you print colored text.

If C<$conditional> is set to true, then ansi_reset() will return "" if color is
disabled.

=head1 ENVIRONMENT

=head2 NO_COLOR

Can be used to explicitly disable color. See L<https://no-color.org> for more
details.

Observed by: ansi{fg,bg}.

=head2 COLOR => bool

Can be used to explicitly disable color by setting it to 0.

Observed by: ansi{fg,bg}.

=head2 COLOR_DEPTH => INT

Can be used to explicitly set color depth instead of trying to detect
appropriate color depth.

Observed by: ansi{fg,bg}.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-ANSI-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-ANSI-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-ANSI-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::ANSIColor>

L<http://en.wikipedia.org/wiki/ANSI_escape_code>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
