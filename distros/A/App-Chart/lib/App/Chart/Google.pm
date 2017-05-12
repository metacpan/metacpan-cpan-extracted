# Copyright 2008, 2009, 2010, 2012, 2015, 2016 Kevin Ryde

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


package App::Chart::Google;
use 5.006;
use strict;
use warnings;
use Carp;
use List::Util qw (min max);
use POSIX ();
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler::IndivChunks;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


our $google_pred = App::Chart::Sympred::Any->new;
our $google_web_pred = App::Chart::Sympred::Any->new;

# overridden by specific nodes
# App::Chart::setup_source_help
#   ($google_pred, __p('manual-node','Google Finance'));



#-----------------------------------------------------------------------------
# web link - basic quote page
#
# Eg. http://www.google.com/finance?q=BHP.AX
# Probably not for prefs etc.

App::Chart::Weblink->new
  (pred => $google_web_pred,
   name => __('_Google Stock Page'),
   desc => __('Open web browser at the Google Finance page for these shares'),
   proc => sub {
     my ($symbol) = @_;

     my $suffix = App::Chart::symbol_suffix ($symbol);
     if ($suffix eq '.AX') {
       $symbol = 'ASX:' . App::Chart::symbol_sans_suffix($symbol);
     } elsif ($suffix eq '.NZ') {
       $symbol = 'NZE:' . App::Chart::symbol_sans_suffix($symbol);
     }

     return ('http://www.google.com/finance?q=' 
             . URI::Escape::uri_escape($symbol));
   });


#-----------------------------------------------------------------------------
# download
#
# This uses the historical prices page like
#
#     http://www.google.com/finance/historical?q=AAPL
#
# which used to have a CSV link like
#
#     http://www.google.com/finance/historical?cid=22144&startdate=Aug+15%2C+2008&enddate=Aug+14%2C+2009&output=csv
#
# but maybe now is only the HTML.  No data available for ASX prefs apparently.
#

App::Chart::DownloadHandler::IndivChunks->new
  (name       => __('Google'),
   pred       => $google_pred,
   available_tdate_by_symbol => \&daily_available_tdate,
   available_tdate_extra     => 1,
   url_func   => \&daily_url,
   parse      => \&daily_parse,
   chunk_size => 500);

sub daily_available_tdate {
  my ($symbol) = @_;
  return App::Chart::Download::tdate_today_after
    (18,0, App::Chart::TZ->for_symbol ($symbol));
}

my @month_to_Mmm = qw(0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

# making: http://www.google.com/finance/historical?cid=22144&startdate=Feb+13%2C+2008&enddate=Oct+6%2C+2008&output=csv
sub daily_url {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;
  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);

  return 'http://www.google.com/finance/historical?q='
    . URI::Escape::uri_escape($symbol)
      . '&startdate='
        . $month_to_Mmm[$lo_month] . '+' . $lo_day . '%2C+' . $lo_year
          . '&enddate='
            . $month_to_Mmm[$hi_month] . '+' . $hi_day . '%2C+' . $hi_year
              . '&output=csv';
}

sub daily_parse {
  my ($symbol, $resp) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,
            date_format     => 'ymd', # eg. '3-Oct-08'
            data            => \@data };

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  if ($line_list[0] !~ /^Date,Open,High,Low,Close,Volume/i) {
    die "Google: unrecognised daily data headings: " . $line_list[0];
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $open, $high, $low, $close, $volume)
      = split (/,/, $line);

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

1;
__END__
