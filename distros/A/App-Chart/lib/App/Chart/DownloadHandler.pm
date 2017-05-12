# Download data handlers.

# Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2016 Kevin Ryde

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

package App::Chart::DownloadHandler;
use 5.010;
use strict;
use warnings;
use sort 'stable'; # lexical in 5.10
use Carp;
use Encode;
use Encode::Locale;  # for coding system "locale"
use List::Util qw(min max);
use List::MoreUtils;
use POSIX::Wide;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;

use constant DEBUG => 0;


#------------------------------------------------------------------------------

our @handler_list = ();

sub new {
  my ($class, %self) = @_;
  $self{'pred'} or croak __PACKAGE__,": missing pred";
  $self{'proc'} or croak __PACKAGE__,": missing proc";
  App::Chart::Sympred::validate ($self{'pred'});

  my $self = bless \%self, $class;
  push @handler_list, $self;

  $self{'name'} ||= do { my ($package,$filename,$line) = caller();
                         "$package:"
                           . Glib::filename_to_unicode($filename)
                             . ":$line" };

  # highest priority first and 'stable' above for order added for equals
  @handler_list
    = sort { ($b->{'priority'}||0) <=> ($a->{'priority'}||0) }
      @handler_list;

  return $self;
}

sub name {
  my ($self) = @_;
  return $self->{'name'};
}

#------------------------------------------------------------------------------

sub handlers_for_symbol {
  my ($class, $symbol) = @_;
  App::Chart::symbol_setups ($symbol);
  if (DEBUG) { print "total ", scalar(@handler_list), " handlers\n"; }
  return grep { $_->match($symbol) } @handler_list;
}

#------------------------------------------------------------------------------

sub match {
  my ($self, $symbol) = @_;
  return $self->{'pred'}->match($symbol);
}

#------------------------------------------------------------------------------

sub download {
  my ($self, $symbol_list) = @_;
  if (DEBUG) { print "Download ",@$symbol_list,"\n"; }
  if (! @$symbol_list) { return; }

  if (my $key = $self->{'recheck_key'}) {
    my $recheck_seconds = 86400 * $self->{'recheck_days'};
    my ($timestamp_lo, $timestamp_hi)
      = App::Chart::Download::timestamp_range ($recheck_seconds);

    my $min_timestamp = '9999';
    my $any_wanted = 0;
    foreach my $symbol (@$symbol_list) {
      my $symbol_timestamp = App::Chart::Database->read_extra ($symbol, $key);
      if (defined $symbol_timestamp
          && $symbol_timestamp ge $timestamp_lo
          && $symbol_timestamp le $timestamp_hi) {
        if (DEBUG) { print "recheck not for $symbol: $symbol_timestamp\n"; }
        $min_timestamp = List::Util::minstr($min_timestamp, $symbol_timestamp);
      } else {
        if (DEBUG) { print "recheck want $symbol: $symbol_timestamp\n"; }
        $any_wanted = 1;
        last;
      }
    }

    if (! $any_wanted) {
      my $t = App::Chart::Download::timestamp_to_timet ($min_timestamp)
        + $recheck_seconds;
      my $fmt = $App::Chart::option{'d_fmt'} . ' %H:%M';
      my $datetime = POSIX::Wide::strftime ($fmt, localtime($t));
      App::Chart::Download::verbose_message
          (__x("{name}: next check {datetime}",
               name     => $self->name,
               datetime => $datetime));
      return;
    }
  }

  App::Chart::Download::verbose_message ($self->name, @$symbol_list);
  App::Chart::Download::status ($self->name);

  my $tsproc = $self->{'available_tdate_by_symbol'};
  {
    my $avail;
    if (my $tproc = $self->{'available_tdate'}) {
      $avail = $tproc->();
    }
    if (my $tproc = $self->{'available_date_time'}) {
      my ($iso_date, $time) = $tproc->();
      $avail = App::Chart::Download::iso_to_tdate_floor ($iso_date);
    }
    if (defined $avail) {
      $tsproc = sub { return $avail };
    }
  }
  if ($tsproc) {
    my @new;
    foreach my $symbol (@$symbol_list) {
      my $avail = $tsproc->($symbol);
      my $start = App::Chart::Download::start_tdate_for_update ($symbol);
      if ($avail >= $start) {
        push @new, $symbol;
      } else {
        App::Chart::Download::verbose_message
            (__x('{symbol} already got data to {date}',
                 symbol => $symbol,
                 date => App::Chart::Download::tdate_range_string ($avail)));
      }
    }
    $symbol_list = \@new;
  }
  if (! @$symbol_list) { return; }

  my $proc = $self->{'proc'};
  my @symbol_groups;

  if ($self->{'by_commodity'}) {
    require Tie::IxHash;
    my %byc;
    tie %byc, 'Tie::IxHash';
    foreach my $symbol (@$symbol_list) {
      my $commodity = App::Chart::symbol_commodity ($symbol);
      push @{$byc{$commodity}}, $symbol;
    }
    @symbol_groups = [ values %byc ];

  } elsif (my $max_symbols = $self->{'max_symbols'}) {
    my $i = 0;
    @symbol_groups = List::MoreUtils::part
      {int(($i++) / $max_symbols)} @$symbol_list;

  } else {
    @symbol_groups = ($symbol_list);
  }

  if (! eval {
    foreach my $symbol_group (@symbol_groups) {
      if ($self->{'proc_with_self'}) {
        $proc->($self, $symbol_group);
      } else {
        $proc->($symbol_group);
      }
    }
    1;
  }) {
    my $err = $@;
    unless (utf8::is_utf8($err)) { $err = Encode::decode('locale',$err); }
    $err = App::Chart::collapse_whitespace ($err);
    App::Chart::Download::download_message ("Download error: $err\n");
    return 0;
  }
  return 1;
}

sub available_tdate_for_symbol {
  my ($self, $symbol) = @_;

  if (my $tsproc = $self->{'available_tdate_by_symbol'}) {
    return $tsproc->($symbol);

  } elsif (my $tproc = $self->{'available_tdate'}) {
    return $tproc->();

  } else {
    return undef;
  }
}

1;
__END__

# =for stopwords Eg tdate upto
# 
# =head1 NAME
# 
# App::Chart::DownloadHandler -- database download handler objects
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::DownloadHandler;
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::DownloadHandler->new (key=>value,...) >>
# 
# Create and register a new data download handler.  The return is a
# C<App::Chart::DownloadHandler> object, though usually this is not of interest
# (only all the handlers later with C<handlers_for_symbol> below).  Eg.
# 
#     my $pred = App::Chart::Sympred::Suffix->new ('.NZ');
# 
#     sub my_download {
#       my ($symbol_list_ref) = @_;
#       ...
#     }
# 
#     App::Chart::DownloadHandler->new
#       (pred => $pred,
#        proc => \&my_download);
# 
# The mandatory keys are
# 
#     pred      App::Chart::Sympred
#     proc      subroutine to call
# 
# The optional keys are
# 
#     available_tdate            subroutine returning data tdate
#     available_tdate_by_symbol  subroutine, taking a symbol
# 
# C<available_tdate> returns the tdate of the newest data available from this
# source.  C<available_tdate_by_symbol> similarly, but it's passed the stock
# symbol; this can be used if availability is symbol-dependent.  In either
# case the download procedures check what's available against where the
# prospective symbols are already upto, and don't call C<proc> at all unless
# there should be new data.
# 
# =item C<< App::Chart::DownloadHandler->handlers_for_symbol ($symbol) >>
# 
# Return a list of C<App::Chart::DownloadHandler> objects which are the available
# latest quote download handlers for C<$symbol>.  This is an empty list if
# there's nothing available for C<$symbol>.
# 
# =item C<< $handler->match ($symbol) >>
# 
# Return true if C<$handler> is for use on C<$symbol>.
# 
# =item C<< $handler->download ($symbol_list) >>
# 
# Run C<$handler> on the symbols in C<$symbol_list> (an array reference).
# Those symbols must have already been checked as being for use with
# C<$handler>.
# 
# =back
