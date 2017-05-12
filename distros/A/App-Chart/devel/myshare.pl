#!/usr/bin/perl -w

# Print quotes.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


=head1 NAME

myshare.pl -- print stock and commodity price quotes

=head1 SYNOPSIS

myshare.pl [symbol...]

DESCRIPTION

Print a quote line for each given symbol, or for the favourites list if no
symbols.  Curses colours show up and down changes in green and red, if the
terminal supports that.  The format is similar to the watchlist inside
Emacs.

=cut

use strict;
use warnings;
use Number::Format;
use Data::Dumper;
use App::Chart::Latest;

my $numf = Number::Format->new
  (-thousands_sep   => '');  # not enough room in 80 columns for thousands


my %tput_setaf_colours = ( black   => 0,
                           red     => 1,
                           green   => 2,
                           yellow  => 3,
                           blue    => 4,
                           magenta => 5,
                           cyan    => 6,
                           white   => 7 );
my %tput_setf_colours  = ( black   => 0,
                           blue    => 1,
                           green   => 2,
                           cyan    => 3,
                           red     => 4,
                           magenta => 5,
                           yellow  => 6,
                           white   => 7 );
sub tput_colour {
  my ($colour) = @_;
  my $code = $tput_setaf_colours{$colour} || die "unknown colour: $colour\n";
  if (! tput ("setaf", $code)) {
    $code = $tput_setf_colours{$colour} || die "unknown colour: $colour\n";
    tput ("setf", $code);
  }
}

sub print_one {
  my ($symbol) = @_;
  my $latest = App::Chart::Latest->get ($symbol);
  my $colour;
  if ($latest->{'inprogress'}) {
    $colour = 'cyan';
  } elsif ($latest->{'change'} && $latest->{'change'} > 0) {
    $colour = 'green';
  } elsif ($latest->{'change'} && $latest->{'change'} < 0) {
    $colour = 'red';
  }

  $colour = undef;
  if ($colour) {
    tput_colour ($colour);
  }

  my $note = $latest->{'note'} || $latest->{'month'} || '';
  my $slash = (defined $latest->{'bid'}
               && defined $latest->{'offer'}
               && $latest->{'bid'} > $latest->{'offer'}
               ? 'x' : '/');
  my $datetime = $latest->short_datetime();

  format STDOUT =
@<<<<<<<<@>>>>>>@@<<<<<< @>>>>>> @>>>>> @>>>>>> @>>>>>> @>>>>>>> @>>>>>>
  $latest->{'symbol'}||'', $latest->{'bid'}||'', $slash, $latest->{'offer'}||'', $latest->{'last'}||'', $latest->{'change'}||'', $latest->{'low'}||'', $latest->{'high'}||'', $latest->{'volume'}||'', $datetime, $note
.
  write;
  if ($colour) {
    tput ('sgr0');
  }
}

print
"Symbol        bid/offer    last  change    low    high    volume    when\n";



# (define got-symbol-list '())

# # display new arrivals progressively
# #
# (notify-connect 'latest-update
#   (lambda (this-symbol-list)
#     (set! this-symbol-list
# 	  (remove latest-in-progress? this-symbol-list))
#     (set! got-symbol-list (append this-symbol-list got-symbol-list))
#     (let more ()
#       (if (not (null? symbol-list))
# 	  (let ((symbol (first symbol-list)))
# 	    (if (member symbol got-symbol-list)
# 		(begin
# 		  (set! symbol-list (cdr symbol-list))
# 		  (one symbol)
# 		  (more))))))))

# (c-main-enq! latest-request-symbols symbol-list)

my @symbol_list = ('TEL.NZ', 'BHP.AX', 'BBW.AX');

foreach my $symbol (@symbol_list) {
  print_one ($symbol);
}
exit 0;
