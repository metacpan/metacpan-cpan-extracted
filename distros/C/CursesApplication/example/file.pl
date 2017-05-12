#!/usr/bin/perl -w
#
# file.pl -- Curses::Application demo script
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: file.pl,v 0.1 2002/11/14 19:39:37 corliss Exp corliss $
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

use strict;
use vars qw($VERSION);
use Curses::Application;

#####################################################################
#
# Set up the environment
#
#####################################################################

($VERSION) = (q$Revision: 0.1 $ =~ /(\d+(?:\.(\d+))+)/) || '0.1';

my $app = Curses::Application->new({
  FOREGROUND    => 'white',
  BACKGROUND    => 'blue',
  CAPTIONCOL    => 'yellow',
  TITLEBAR      => 1,
  CAPTION       => "Curses::Application File Utility v$VERSION",
  MAINFORM      => { Main  => 'MainFrm' },
  INPUTFUNC     => \&myscankey,
  });
my ($f, $w, $rv);
my ($cw, $l, @tmp, $d, @tmp2);

#####################################################################
#
# Program Logic starts here
#
#####################################################################

# Get the current working directory
chomp($d = `pwd`);

# Create the MainFrm early, since we need to adjust a few parameters
# of the ListBoxes (cwd entries and geometry)
$cw = int(($app->maxyx)[1] / 2) - 2;
$l = ($app->maxyx)[0] - 5;
$app->createForm(qw(Main MainFrm));
$w = $app->getForm('Main')->getWidget('lstSource');
@tmp = @{$w->getField('COLWIDTHS')};
$tmp[0] = $cw - 16;
@tmp2 = loaddir($d);
$w->setField(
  CAPTION     => "Source: $d",
  LINES       => $l - 1,
  COLUMNS     => $cw,
  LISTITEMS   => [@tmp2],
  COLWIDTHS   => [@tmp],
  CWD         => $d,
  );
$w = $app->getForm('Main')->getWidget('lstDest');
$w->setField(
  CAPTION     => "Dest: $d",
  X           => $cw + 2,
  LINES       => $l - 1,
  COLUMNS     => $cw,
  LISTITEMS   => [@tmp2],
  COLWIDTHS   => [@tmp],
  CWD         => $d,
  );

# Start the input loop
$app->execute;

exit 0;

#####################################################################
#
# Subroutines follow here
#
#####################################################################

sub myscankey {
  # Same thing as the standard scankey provided by Curses::Widgets, 
  # except that we want to update our clock regularly.
  #
  # Usage:  $key = myscankey($mwh);

  my $mwh = shift;
  my $key = -1;

  while ($key eq -1) {
    clock();
    $key = $mwh->getch
  };

  return $key;
}

sub clock {
  # Updates the clock in the titlebar
  #
  # Usage:  clock();

  my $time = scalar localtime;
  my $x = ($app->maxyx)[1] - length($time);
  my $caption = substr($app->getField('CAPTION'), 0, $x);

  $caption .= ' ' x ($x - length($caption)) . $time;
  $app->titlebar($caption);
}

sub quit {
  # Queries the user if they really want to quit
  #
  # Usage:  quit();

  $rv = dialog('Quit Application?', BTN_YES | BTN_NO, 
    'Are you sure you want to quit?', qw(white red yellow));
  exit 0 unless ($rv);
}

sub loaddir {
  # Returns a sort list of list, with each sublist being a file
  # and its attributes.
  #
  # Usage:  @entries = loaddir($dir);

  my $dir = shift;
  my ($e, @rv);

  if (opendir(DIR, $dir)) {
    while (defined($e = readdir(DIR))) { push(@rv, $e) };
    closedir(DIR);
    @rv = map { [$_, sizer(-s "$dir/$_"), transmode("$dir/$_")] } 
      sort @rv;
  }

  return @rv;
}

sub sizer {
  # Massages the passed size to use the metric abbreviations.
  #
  # Usage:  $size = sizer($size);

  my $size = shift || 0;
  my @suffixes = qw(B K M G); # Bytes, Kilobytes, Megabytes, Gigabytes
  my $l = length($size);
  my $indx = 0;
  my $p;

  # Find the byte prefix
  while ($l > 3) {
    ++$indx;
    $l -= 3;
  }
  $size /= 1024 ** $indx if $indx > 0;

  # Find the sprintf argument
  if ($l >= 2) {
    $p = "\% 3d$suffixes[$indx]";
  } else {
    $p = "\%1.1f$suffixes[$indx]";
  }

  return sprintf($p, $size);
}

sub transmode {
  # Returns a string showing the entry permissions (a la ls -l)
  #
  # Usage:  $mode = transmode($file);

  my $file = shift;
  my $stat = (stat($file))[2];
  my $mode = defined $stat ? sprintf('%04o', $stat & 07777) : '0000';
  my @ebits = qw(r w x);
  my @bits = (4, 2, 1);
  my ($digit, $i, $rv);

  # Translate last three octets
  foreach $digit (split(//, substr($mode, 1))) {
    for ($i = 0; $i < @bits; $i++) {
      $rv .= $digit & $bits[$i] ? $ebits[$i] : '-';
    }
  }

  # Check if it's a link
  if (-l $file) {
    $rv = "l$rv";

  # Or a directory
  } elsif (-d _) {
    $rv = "d$rv";

  # Or a block device
  } elsif (-b _) {
    $rv = "b$rv";

  # Or a character device
  } elsif (-c _) {
    $rv = "c$rv";

  # Or a socket
  } elsif (-S _) {
    $rv = "s$rv";

  # Or a pipe
  } elsif (-p _) {
    $rv = "p$rv";

  } else {
    $rv = "-$rv";
  }

  # Check for sticky bits
  substr($rv, 3, 1) = 's' if -u _;
  substr($rv, 6, 1) = 's' if -g _;
  substr($rv, 9, 1) = 't' if -k _;

  return $rv;
}

sub chgdir {
  # Changes the current directory as per the selected entry in
  # the list box.
  #
  # Usage:  chgdir();

  my $w = shift;
  my ($pos, $items, $cwd, $caption) = 
    $w->getField(qw(CURSORPOS LISTITEMS CWD CAPTION));

  return if $$items[$pos][0] eq '.';

  if (-d $$items[$pos][0] || -d "$cwd/$$items[$pos][0]") {
    if ($$items[$pos][0] eq '..') {
      $cwd =~ s#/[^/]+/?$##;
      $cwd = '/' if $cwd eq '';
    } else {
      $cwd .= "/$$items[$pos][0]";
    }

    $caption =~ s/^(\w+: ).+$/$1$cwd/;
    $w->setField(
      LISTITEMS   => [loaddir($cwd)],
      CWD         => $cwd,
      CAPTION     => $caption,
      );
  } else {
    return 0;
  }
}

sub srcexit {
  # Keeps the focus on the listbox.
  #
  # Usage:  srcexit($form, $key);

  my $f = shift;
  my $key = shift;
  my $w = $f->getWidget('lstSource');

  if ($key eq "\n") {
    chgdir($w);
    $f->setField(DONTSWITCH => 1);
  }
}

sub destexit {
  # Keeps the focus on the listbox.
  #
  # Usage:  srcexit($form, $key);

  my $f = shift;
  my $key = shift;
  my $w = $f->getWidget('lstDest');

  if ($key eq "\n") {
    chgdir($w);
    $f->setField(DONTSWITCH => 1);
  }
}

__DATA__

%forms = (
  MainFrm     => {
    TABORDER        => [qw(Menu lstSource lstDest)],
    FOCUSED         => 'lstSource',
    WIDGETS         => {
      Menu            => {
        TYPE            => 'Menu',
        MENUS           => {
          MENUORDER       => [qw(File)],
          File            => {
            ITEMORDER       => [qw(Exit)],
            Exit            => \&main::quit,
            },
          },
        },
      lstSource       => {
        TYPE            => 'ListBox::MultiColumn',
        COLUMNS         => 20,
        LINES           => 10,
        Y               => 1,
        X               => 0,
        CAPTION         => 'Source',
        MULTISEL        => 1,
        SELECTEDCOL     => 'red',
        HEADERS         => [qw(filename size perm)],
        COLWIDTHS       => [20, 4, 10],
        HEADERFGCOL     => 'white',
        HEADERBGCOL     => 'cyan',
        BIGHEADER       => 1,
        FOCUSSWITCH     => "\n\t",
        CWD             => '',
        OnExit          => \&main::srcexit,
        },
      lstDest         => {
        TYPE            => 'ListBox::MultiColumn',
        COLUMNS         => 20,
        LINES           => 10,
        Y               => 1,
        X               => 20,
        CAPTION         => 'Destination',
        MULTISEL        => 0,
        SELECTEDCOL     => 'red',
        HEADERS         => [qw(filename size perm)],
        COLWIDTHS       => [20, 4, 10],
        HEADERFGCOL     => 'white',
        HEADERBGCOL     => 'cyan',
        BIGHEADER       => 1,
        FOCUSSWITCH     => "\n\t",
        CWD             => '',
        OnExit          => \&main::destexit,
        },
      },
    },
  );

