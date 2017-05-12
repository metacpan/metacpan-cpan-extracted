# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::DownloadHandler::IndivChunks;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::DownloadHandler';
use App::Chart;
use App::Chart::Download;


sub new {
  my ($class, %options) = @_;
  $options{'name'} or croak "missing name for ".__PACKAGE__;
  $options{'chunk_size'} or croak "missing chunk_size for ".__PACKAGE__;
  $options{'url_func'} or croak "missing chunk_size for ".__PACKAGE__;

  return $class->SUPER::new (%options,
                             proc => \&indivchunks_download,
                             backto => \&backto,
                             proc_with_self => 1);
}

sub indivchunks_download {
  my ($self, $symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    my $avail_tdate = $self->available_tdate_for_symbol ($symbol)
      + ($self->{'available_tdate_extra'} || 0);
    my $lo_tdate = App::Chart::Download::start_tdate_for_update ($symbol);
    my $empty_count = 0;

    if ($lo_tdate > $avail_tdate) {
      App::Chart::Download::verbose_message
          (__x("{name} nothing further expected yet for {symbol}",
               name => $self->{'name'},
               symbol => $symbol));
      next;
    }

    while ($lo_tdate <= $avail_tdate) {
      my $hi_tdate = min ($lo_tdate + $self->{'chunk_size'} - 1, $avail_tdate);

      App::Chart::Download::status
          ($self->{'name'}, __('data'),
           $symbol,
           App::Chart::Download::tdate_range_string ($lo_tdate, $hi_tdate));

      my $url = $self->{'url_func'}->($symbol, $lo_tdate, $hi_tdate);
      my $resp = App::Chart::Download->get ($url, allow_404 => 1);

      my $h;
      if ($resp->is_success) {
        $h = $self->{'parse'}->($symbol, $resp);
      } else {
        $h = { data => [] };
      }

      if ($hi_tdate == $avail_tdate) {
        $h->{'last_download'} = 1;
      }

      if (! @{$h->{'data'}}) {
        $empty_count++;
        if ($empty_count >= 2) {
          $h->{'last_download'} = 1;
        }
      } else {
        $empty_count = 0;
      }

      App::Chart::Download::write_daily_group ($h);

      # FIXME: This works badly for recently listed shares where there can
      # be a lot of empty chunks until current ... maybe should download
      # "backto" from newest to oldest ...
      #
      #       if ($empty_count >= 2) {
      #         App::Chart::Download::verbose_message
      #             (__x("{name} two empty chunks, end of data for {symbol}",
      #                  name => $self->{'name'},
      #                  symbol => $symbol));
      #         last;
      #       }
      $lo_tdate = $hi_tdate + 1;
    }
  }
}

sub backto {
  my ($self, $symbol_list, $backto_tdate) = @_;

  foreach my $symbol (@$symbol_list) {
    my $hi_tdate = App::Chart::Download::start_tdate_for_backto ($symbol);
    my $empty_count = 0;

    while ($hi_tdate >= $backto_tdate) {
      my $lo_tdate = $hi_tdate - $self->{'chunk_size'} + 1;

      App::Chart::Download::status
          ($self->{'name'}, __('data'),
           App::Chart::Download::tdate_range_string ($lo_tdate, $hi_tdate));

      my $url = $self->{'url_func'}->($symbol, $lo_tdate, $hi_tdate);
      my $resp = App::Chart::Download->get ($url, allow_404 => 1);

      my $h;
      if ($resp->is_success) {
        $h = $self->{'parse'}->($symbol, $resp);
      } else {
        $h = { data => [] };
      }

      if (! @{$h->{'data'}}) {
        $empty_count++;
        if ($empty_count >= 2) {
          App::Chart::Download::verbose_message
              (__x("{name} apparent limit of data for {symbol}",
                   name => $self->{'name'},
                   symbol => $symbol));
          last;
        }
      } else {
        $empty_count = 0;
      }
      App::Chart::Download::write_daily_group ($h);

      $hi_tdate = $lo_tdate - 1;
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::DownloadHandler::IndivChunks -- individual symbols in date range chunks
# 
# =for test_synopsis my ($pred)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::DownloadHandler::IndivChunks;
#  App::Chart::DownloadHandler::IndivChunks-> new
#      (name  => __('FooEX'),
#       pred  => $pred,
#       url_func => \&my_url,
#       parse    => \&my_page_parser);
# 
# =head1 DESCRIPTION
# 
# This module downloads and processes daily data in date range chunks for one
# symbol at a time.  This is the style required for Yahoo Finance for
# instance.
# 
# =head1 SEE ALSO
# 
# L<App::Chart::DownloadHandler>
# 
# =cut
