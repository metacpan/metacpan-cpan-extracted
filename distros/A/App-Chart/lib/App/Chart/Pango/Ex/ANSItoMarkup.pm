# sit on unmatched partial esc[30m etc




# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Pango::Ex::ANSItoMarkup;
use 5.008;
use strict;
use warnings;

my %shorthand = ('<span weight=bold'        => 'b',
                 '<span style=italic'       => 'i',
                 '<span strikethrough=true' => 's',
                 '<span underline=single'   => 'u');

my @colour = ('black',
              'red',
              'green',
              'yellow',
              'blue',
              'magenta',
              'cyan',
              'white');

use constant { _A_FOREGROUND    => 0,
               _A_BACKGROUND    => 1,
               _A_STRIKETHROUGH => 2,
               _A_STYLE         => 3,
               _A_UNDERLINE     => 4,
               _A_WEIGHT        => 5,
               _A_RISE          => 6,
             };

sub new {
  my ($class) = @_;
  return bless { attr => [],
               }, $class;
}

sub convert {
  my ($class_or_self, $str) = @_;
  my $self = (ref $class_or_self ? $class_or_self : $class_or_self->new);

  my $attr = $self->{'attr'};
  if (defined (my $prev = delete $self->{'previous'})) {
    $str = $prev . $str;
  }

  defined (my $pos = index ($str, "\e"))
    or return $str;

  pos($str) = $pos;
  my $ret = substr ($str, 0, $pos);

  while ($str =~ /\G
                  (                 # $1 whole esc+text
                    (?:\e(          # $2 after esc
                      \[([0-9;]*)   # $3 SGR numbers
                      m
                    |
                      [KL])?)?
                  ([^\e]*))          # $4 plain text after
                 /gx) {
    my $part = $4;
    if (defined $3) {
      foreach my $num (split /;/, $3) {
        if ($num == 0) {
          @$attr = ();

        } elsif ($num == 1) {
          # bold
          $attr->[_A_WEIGHT] = 'weight=bold';

        } elsif ($num == 2) {
          # faint, or dark, or something
          $attr->[_A_WEIGHT] = 'weight=light';

        } elsif ($num == 3) {
          # italic
          $attr->[_A_STYLE] = 'style=italic';

        } elsif ($num == 4) {
          # single underline
          $attr->[_A_UNDERLINE] = 'underline=single';

          # 5 slow blink
          # 6 fast blink
          #    nothing for these in pango

          # 7 "negative image", reverse video
          #    would kinda need to know what the normal colours are

          # 8 concealed
          #    does this mean invisible?

        } elsif ($num == 9) {
          $attr->[_A_STRIKETHROUGH] = 'strikethrough=true';

          # 10 primary font
          # 11 first alternative font
          # ...
          # 19 ninth alternative font
          # 20 fraktur gothic

        } elsif ($num == 21) {
          # double underline
          $attr->[_A_UNDERLINE] = 'underline=double';

        } elsif ($num == 22) {
          # normal colour/intensity, ie. neither bold nor faint
          $attr->[_A_WEIGHT] = undef;

        } elsif ($num == 23) {
          # not italic
          $attr->[_A_STYLE] = undef;

        } elsif ($num == 24) {
          # not underlined
          $attr->[_A_UNDERLINE] = undef;

          # 25 not blinking
          #     nothing for blinking in pango
          # 26 reserved (for proportional spacing)
          # 27 positive image, ie. not reverse video
          # 28 revealled chars, ie. not concealed

        } elsif ($num == 29) {
          # not strikethrough
          $attr->[_A_STRIKETHROUGH] = undef;

        } elsif ($num >= 30 && $num <= 37) {
          $attr->[_A_FOREGROUND] = 'foreground=' . $colour[$num-30];

          # 38 reserved (for foreground colour)

        } elsif ($num == 39) {
          # default foreground colour
          $attr->[_A_FOREGROUND] = undef;

        } elsif ($num >= 40 && $num <= 47) {
          $attr->[_A_BACKGROUND] = 'background=' . $colour[$num-40];

          # 48 reserved (for background colour)

        } elsif ($num == 49) {
          # default background colour
          $attr->[_A_BACKGROUND] = undef;

          # 50 reserved (for cancelling 26 proportional spacing)
          # 51 framed
          # 52 encircled
          # 53 overlined
          #     no overline in pango markup
          # 54 not framed or encircled
          # 55 not overlined
          # 56-59 reserved
          # 60 ideogram underline right side line
          # 61 ideogram double underline right side line
          # 62 ideogram overline left side line
          # 63 ideogram double overline left side
          # 64 ideogram stress
          # 65 ideogram normal, ie. undo 60-64
        }
      }
    } elsif (defined $2) {
      # sub/sup rise 5000, meaning 0.5 em, same as pango-markup.c does for
      # <sub>, <sup> shorthands
      if ($2 eq 'K') {
        # PLD partial line down subscript or cancel superscript
        $self->{'rise'} -= 5000;

      } elsif ($2 eq 'L') {
        # PLU partial line up superscript or cancel subscript
        $self->{'rise'} += 5000;
      }
      $attr->[_A_RISE] = (($self->{'rise'}||0) == 0 ? undef
                          : "rise=".$self->{'rise'});

    } else {
      $part = $1;
    }

    my $span = join (' ', '<span', grep {defined} @$attr);
    if ($span eq '<span') {
      # no markup at all
      $ret .= $part;
    } elsif (my $short = $shorthand{$span}) {
      $ret .= "<$short>$part</$short>";
    } else {
      $ret .= "$span>$part</span>";
    }
  }
  return $ret;
}

# print __PACKAGE__->convert("\eKsub\eLn\eZorm\e[1mxyz\e[0mabc\e[30mxyz\e[0m");

1;
__END__
