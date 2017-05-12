# Copyright 2007, 2008, 2009, 2011, 2015 Kevin Ryde

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


# Stuck at Aug 2008, so unused for now ...


# Float offers the following formats,
#
#     http://www.float.com.au/scgi-bin/prod/dl.cgi
#
#
# traded=on     - only symbols which have trades
# csv=on        - zip file in csv format
# ticker=XX,YY  - symbols to get
# format=metastock     - prices in dollars, date yymmdd [default]
#     	  fcharts       - prices in dollars, date yymmdd
#     	  stockeasy     - prices in dollars, date yyyymmdd
#     	  ezychart      - prices in cents, date yymmdd
#     	  insighttrader - prices in dollars, date mm/dd/yy, space separated,
#                        volume in 100s
#     	  maus          - prices in cents, date mm/dd/yy, space separated
# volume=1             - full volume value
#        10            - in tens
#        100           - in hundreds
#        1000          - in thousands
#
# It doesn't seem to work to set options for a .zip download, it ends up
# with the default.  That default might be meant to be "metastock", though
# it has a 4-digit year like stockeasy.  Ezychart would be the most compact
# (no decimal points in most prices, and no century on the date).
#
# The .zip files contain only one archive element, so in theory gzip is
# supposed to be able to handle them, but it complains about CRC error, so
# only using unzip for now.  Zlib is another possiblity, if the zip header
# can be understood.


package App::Chart::Float;
use strict;
use warnings;
use Carp;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::TZ;

my $pred = App::Chart::Sympred::Suffix->new ('.AX');

# today's data is finalized at 9:15pm sydney time (weekdays)
sub available_tdate {
  App::Chart::Download::tdate_today_after
      (21,15, App::Chart::TZ->sydney);
}

#------------------------------------------------------------------------------

# C<$zipstr> is a string of bytes which are the contents of a ".zip" file.
# Unzip and return the first member as a string of bytes, or return undef if
# no members.
#
sub unzip_one {
  my ($zipstr) = @_;

  require Archive::Zip;
  my $zip = Archive::Zip->new;

  require IO::String;
  my $io = IO::String->new ($zipstr);
  $zip->readFromFileHandle ($io);

  my @members = $zip->members();
  my $first = $members[0];
  return undef if (! defined $first);

  return $first->contents;
}
#
# Even if _isSeekable gets the right answer :scalar is opened as IO::Handle
# not IO::Seekable ...
#
#   require IO::Handle;
#   require IO::Seekable;
#   *Archive::Zip::Archive::_isSeekable = sub { print "yes\n"; 1; };
#   open my $io, '<', \$zipstr or die;


sub yyyymmdd_to_iso {
  my ($str) = @_;
  if (length ($str) != 8) { croak "yyyymmdd_to_iso: bad string length: $str"; }
  return substr ($str, 0,4) . '-' .
         substr ($str, 4,2) . '-' .
         substr ($str, 6,2);
}

sub tdate_to_yyyymmdd {
  my ($tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  return sprintf ('%04d%02d%02d', $year, $month, $day);
}

sub zip_parse {
  my ($url, $resp) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            currency        => 'AUD',
            prefer_decimals => 2,
            #             cover_pred      => $pred,
            #             cover_date      =>
            data            => \@data };

  my $body = $resp->decoded_content (charset=>'none',raise_error=>1);
  $h->{'cost_value'} = length ($body);

  # unknown symbol or no data for a particular date gives a zip file with no
  # members
  $body = unzip_one ($body);
  if (! $body) { return undef; }

  my $max_date = tdate_to_yyyymmdd (available_tdate());

  foreach my $line (App::Chart::Download::split_lines($body)) {
    my ($symbol, $date, $open, $high, $low, $close, $volume)
      = split (/,/, $line);
    next if ($date gt $max_date);

    $date = yyyymmdd_to_iso ($date);
    $symbol .= '.AX';

    push @data, { symbol => $symbol,
                  date   => $date,
                  open   => $open,
                  high   => $high,
                  low    => $low,
                  close  => $close,
                  volume => $volume };
  }
  return $h;
}


#-----------------------------------------------------------------------------
# download - by each symbol
#
# This uses the download of all data for a symbol like
#
#     http://www.float.com.au/download/BHP.zip
#
# An unknown symbol produces an empty file, or a .zip containing an empty
# file.
#
# Some old data, like 1997 in http://www.float.com.au/download/SGW.zip, is
# not in date order.

sub indiv_download {
  my @symbol_list = @_;

  foreach my $symbol (@symbol_list) {
    my $filename = App::Chart::symbol_sans_suffix($symbol) . '.zip';
    App::Chart::Download::status
        (__x('Float.com.au data {filename}', filename => $filename));

    my $url = 'http://www.float.com.au/download/'
      . URI::Escape::uri_escape($filename);
    my $resp = App::Chart::Download->get ($url);
    my $h = zip_parse ($url, $resp);
    if ($h) {
      $h->{'last_download'} = 1;
      $h->{'cost_key'} = 'float-indiv-zip';
      App::Chart::Download::write_daily_group ($h);
    }
  }
}


#-----------------------------------------------------------------------------
# download - by whole day files
#
# This uses the day files like
#
#     http://www.float.com.au/download/20050909.zip
#     http://www.float.com.au/download/20050909.txt
#
# The .zip is the .txt compressed.  A .csv is also available, but it's
# bigger and the only difference is "" quotes on the fields.
#
# On a public holiday like http://www.float.com.au/download/20060414.zip
# the txt file is empty, or the zip file contains no files (no files at
# all, not even an empty txt file).
#
# Sometimes the server has got stuck or something, with no new data for a
# while.  When that happens current days are empty files too.  Give up after
# a few of those.


# return a url string like "http://www.float.com.au/download/20050909.zip"
sub daily_url {
  my ($tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  return sprintf ('http://www.float.com.au/download/%04d%02d%02d.zip',
                  $year, $month, $day);
}

sub daily_download {
  my ($lo, $hi) = @_;
  my $empties = 0;

  foreach my $tdate ($lo .. $hi) {
    App::Chart::Download::status
        (__x('Float.com.au data {date}',
             date => App::Chart::Download::tdate_range_string ($tdate)));
    my $url = daily_url($tdate);
    my $resp = App::Chart::Download->get($url);
    my $h = zip_parse ($url, $resp);
    if ($h) {
      $empties = 0;
      $h->{'whole_day'} = '.AX';
      $h->{'cost_key'} = 'float-wholeday-zip';
      App::Chart::Download::write_daily_group ($h);
    } else {
      $empties++;
      if ($empties >= 5) {
        App::Chart::Download::download_message
            (__x('Float too many empty days, giving up'));
        last;
      }
    }
  }
}


#-----------------------------------------------------------------------------
# download
#
# The download chooses between
#    - float whole-day update files (possible zipped)
#    - float individual historical files (possibly zipped)
#
# To update many ASX shares the whole-day files are best, or for just a few
# then the individual files are best.  A mixture is used too, if there's a
# few symbols that are quite a bit behind then they'll be done
# individually, and the balance with whole-day.
#
# The main problem with the whole-day file is how many entries it has,
# about 4500 as of Jan 2007.  There's about 1600 companies (a lot of them
# small caps), the rest is warrants on the majors, and a few prefs or bonds
# on various.

App::Chart::DownloadHandler->new
  (name            => __('Float'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   proc            => \&download,
   priority        => 20); # before 2nd commsec, and before yahoo

sub download {
  my ($symbol_list) = @_;
  App::Chart::Download::status (__('Float.com.au strategy'));

  my $avail = available_tdate();

  require App::Chart::DownloadCost;
  my ($whole_tdate, @indiv_list) = App::Chart::DownloadCost::by_day_or_by_symbol
    (available_tdate  => $avail,
     symbol_list      => $symbol_list,
     indiv_cost_key     => 'float-indiv-zip',
     indiv_cost_default => 30000, # depending when first listed
     whole_cost_key     => 'float-wholeday-zip',
     whole_cost_default => 45000); # Sep 2007

  App::Chart::Download::verbose_message
      (__x('Float whole days from {date} after indiv {symbols}',
           date => App::Chart::tdate_to_iso($whole_tdate),
           symbols => join(' ', @indiv_list)));

  foreach my $symbol (@indiv_list) { indiv_download ($symbol); }
  daily_download ($whole_tdate, $avail);
}

1;
__END__


# ---------------------------------------------------------------------------
# Omitted while stuck at August 2008 ...
#
# @node Float, Finance Quote, Commonwealth Securities, Data Sources
# @section Float
# @cindex @code{float.com.au}
# 
# @uref{http://www.float.com.au}
# 
# @cindex Australian Stock Exchange
# @cindex ASX
# Float provides the following ASX data (@pxref{Australian Stock Exchange}),
# 
# @itemize
# @item
# Daily data for shares, warrants and indices back to 1997.  Each day's data is
# available from 9:15pm (Sydney time).
# @end itemize
# 
# The home page invites use of the data download while the float database is
# being built, subject to a disclaimer at
# 
# @quotation
# @uref{http://www.float.com.au/scgi-bin/prod/terms.cgi}
# @end quotation
# 
# Float is preferred over Yahoo for daily data, because it's available sooner,
# and if you have lots of ASX symbols then whole-day files can be used, which
# are faster than a separate download for every stock.
# 
# Preliminary data for each day is available from Float at 5pm (Sydney time) but
# is updated until 9pm, so Chart deliberately doesn't download until 9:15pm.
# 
# See also @ref{Commonwealth Securities}.


