# Copyright 2008, 2009, 2010, 2011, 2015, 2016, 2023 Kevin Ryde

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

package App::Chart::Suffix::TSP;
use 5.006;
use strict;
use warnings;
no warnings 'once';
use List::Util qw(min max);
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::FinanceQuote;
use App::Chart::IntradayHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant DEBUG => 0;


my $pred = App::Chart::Sympred::Suffix->new ('.TSP');

# FIXME: is east coast right?
App::Chart::TZ->newyork->setup_for_symbol ($pred);

App::Chart::setup_source_help
  ($pred, __p('manual-node','Thrift Savings Plan'));

App::Chart::FinanceQuote->setup (pred => $pred,
                                 suffix => '.TSP',
                                 modules => ['TSP'],
                                 method => 'tsp');


#------------------------------------------------------------------------------
# weblink

# only home page, per "Linkage to the TSP Web Site" requirement
App::Chart::Weblink->new
  (pred => $pred,
   name => __('_TSP Home Page'),
   desc => __('Open web browser at the US Government Thrift Savings Plan'),
   proc  => sub {
     require Finance::Quote::TSP;
     return $Finance::Quote::TSP::TSP_MAIN_URL;
   });


#-----------------------------------------------------------------------------
# download
#
# This uses the historical prices page
#     https://www.tsp.gov/share-price-history/
#
# The site won't even speak to you without a right User-Agent header.
# This is recent site breakage, as it was happy with anything in the past.
# Here follow Finance::Quote::TSP which uses the following,
#
use constant TSP_USER_AGENT => 
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Safari/537.36';
#
# The download button is URL parameters after a base:
#
use constant TSP_SHARE_PRICES_URL =>
  'https://www.tsp.gov/data/fund-price-history.csv';
#
# The parameters on the page are buried in some unhelpful script, eg.
# 
#     https://www.tsp.gov/data/fund-price-history.csv?startdate=$2023-01-01&enddate=2023-02-01&Lfunds=1&InvFunds=1&download=1
#
# The check boxes select individual funds for the display but seem to have
# effect on the download, so the download gets all funds at once, in the
# date range.
#
# Seems no limit to the size of the date range.  In the past there it was 30
# days per request (and had made it 20 business days here).  Data used to go
# back to 2003-06-02.
#
# --------
#   Old POST:
#   https://www.tsp.gov/InvestmentFunds/FundPerformance/index.html
#   reloaded=1&startdate=04%2F27%2F2015&enddate=06%2F02%2F2015&fundgroup=L2020&fundgroup=G&fundgroup=C&whichButton=CSV
#
#   Old POST:
#   startdate=20030801&enddate=20031128&submit=Retrieve+Share+Prices&prev=0&next=30&whichButton=CSV
# 
#   Old page (now 403 redirects):
#   https://www.tsp.gov/investmentfunds/shareprice/sharePriceHistory.shtml

App::Chart::DownloadHandler->new
  (name            => __('TSP'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   proc            => \&download);

# 18:55 still showing prev
# 20:22 showing today
sub available_tdate {
  App::Chart::Download::tdate_today_after
      (20,0, App::Chart::TZ->newyork);
}

sub download {
  my ($symbol_list) = @_;

  my $avail_tdate = available_tdate();
  my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);

  if ($lo_tdate > $avail_tdate) {
    App::Chart::Download::verbose_message
        (__('TSP nothing further expected yet'));
    return;
  }

  # ask for extra in case available_tdate() is a bit short
  $avail_tdate += 2;

  my $resp = get_chunk ($symbol_list, $lo_tdate, $avail_tdate);
  my $h = parse ($resp);
  $h->{'last_download'} = 1;
  App::Chart::Download::write_daily_group ($h);
}

sub backto {
  my ($symbol_list, $backto_tdate) = @_;
  my $hi_tdate = App::Chart::Download::start_tdate_for_backto (@$symbol_list);
  my $resp = get_chunk ($backto_tdate, $hi_tdate);
  my $h = parse ($resp);
  App::Chart::Download::write_daily_group ($h);
}

# return a HTTP::Response for data $lo_tdate to $hi_tdate, inclusive
sub get_chunk {
  my ($symbol_list, $lo_tdate, $hi_tdate) = @_;

  App::Chart::Download::status
      (__x('TSP data {date_range}',
           date_range =>
           App::Chart::Download::tdate_range_string ($lo_tdate, $hi_tdate)));

  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);
  my $startdate = sprintf "%04d-%02d-%02d", $lo_year, $lo_month, $lo_day;
  my $enddate   = sprintf "%04d-%02d-%02d", $hi_year, $hi_month, $hi_day;

  return App::Chart::Download->get
    (TSP_SHARE_PRICES_URL
     . "?startdate=$startdate&enddate=$enddate&Lfunds=1&InvFunds=1&download=1",
     user_agent => TSP_USER_AGENT);
}

# $resp is a HTTP::Response object, return a hashref of data
sub parse {
  my ($resp, $symbol_list) = @_;

  # From 1 Jul 2008 prices are 4 decimal places, and old data is padded with
  # zeros.  Could prefer_decimals to strip them, but may as well leave at
  # current precision.
  #
  my @data = ();
  my $h = { source      => __PACKAGE__,
            currency    => 'USD',
            date_format => 'ymd',
            suffix      => '.TSP',
            data        => \@data };

  my $content = $resp->decoded_content (raise_error=>1);
  ### $content

  my @lines = App::Chart::Download::split_lines ($content);
  my ($date, @symbols) = split /,/, $lines[0];
  lc($date) eq 'date'
    or die 'TSP csv doesn\'t start with "date": ', $lines[0];
  shift @lines;
  ### @symbols

  # "L Income" becomes uppercase "LINCOME.TSP" (documented in chart.texi
  # that way)
  @symbols = map { my $symbol = $_;
                   $symbol =~ s/ Fund//i;
                   $symbol =~  s/ //g;
                   "\U$symbol.TSP" }
    @symbols;
  ### @symbols
  $symbol_list //= \@symbols;
  my %symbol_list = map {$_ => 1} @$symbol_list;

  foreach my $line (@lines) {
    my ($date, @prices) = split /,/, $line;
    foreach my $c (0 .. $#prices) {
      my $symbol = $symbols[$c];
      next unless exists $symbol_list{$symbol};
      push @data, { symbol => $symbol,
                    date   => $date,
                    close  => $prices[$c],
                  };
    }
  }
  if (DEBUG) {
    require List::Util;
    print "min date ",List::Util::minstr(map {$_->{'date'}} @data),"\n";
    print "max date ",List::Util::maxstr(map {$_->{'date'}} @data),"\n";
  }
  return $h;
}

1;
__END__



# Finance::Quote::TSP no longer has a %TSP_FUND_NAMES table.
#
# # $symbol is like "L2050.TSP", return a name from the table in
# # Finance::Quote::TSP, or undef if unknown.  The names table there is not a
# # documented feature, so guard with an eval.
# #
# sub symbol_to_name {
#   my ($symbol) = @_;
#   # eg. "TSPL2050" or "TSPGFUND"
#   $symbol = 'TSP'.App::Chart::symbol_sans_suffix($symbol);
#   return eval {
#     require Finance::Quote::TSP;
#     $Finance::Quote::TSP::TSP_FUND_NAMES{$symbol}
#       || $Finance::Quote::TSP::TSP_FUND_NAMES{$symbol.'FUND'}
#   };
# }




# Old code parsing HTML table.
# {
#   my ($resp) = @_;
# 
#   # From 1 Jul 2008 prices are 4 decimal places, and old data is padded with
#   # zeros.  Could prefer_decimals to strip them, but may as well leave at
#   # current precision.
#   #
#   my @data = ();
#   my $h = { source      => __PACKAGE__,
#             currency    => 'USD',
#             date_format => 'mdy',
#             suffix      => '.TSP',
#             data        => \@data };
# 
#   my $content = $resp->decoded_content (raise_error=>1);
#   ### $content
# 
#   require HTML::TableExtract;
#   my $te = HTML::TableExtract->new (headers => [qr/^Date$/i],
#                                     keep_headers => 1,
#                                     slice_columns => 0);
#   $te->parse($content);
#   my $ts = $te->first_table_found();
#   #### $ts
#   if (! $ts) { die 'TSP price table not found'; }
# 
#   my $rows = $ts->rows();
#   my $lastrow = $#$rows;
#   my $lastcol = $#{$rows->[0]};
# 
#   my @symbol = map { my $symbol = $_;
#                      $symbol =~ s/ Fund//i;
#                      $symbol =~  s/ //g;
#                      # upper case for "LINCOME.TSP" (documented in
#                      # chart.texi that way)
#                      $symbol eq 'Date' ? undef : "\U$symbol.TSP" } @{$rows->[0]};
# 
#   require Finance::Quote::TSP;
#   my @name = map { my $key = $_;
#                    $key =~  s/ //g;
#                    $Finance::Quote::TSP::TSP_FUND_NAMES{"TSP$key"} }
#     @{$rows->[0]};
# 
#   foreach my $r (1 .. $lastrow) {
#     my $row = $rows->[$r];
#     if (DEBUG) { require Data::Dumper;
#                  print Data::Dumper::Dumper($row); }
#     my $date = $row->[0];
# 
#     foreach my $c (1 .. $lastcol) {
#       my $price = $row->[$c];
# 
#       push @data, { symbol => $symbol[$c],
#                     name   => $name[$c],
#                     date   => $date,
#                     close  => $price,
#                   };
#     }
#   }
#   if (DEBUG) {
#     require List::Util;
#     print "min date ",List::Util::minstr(map {$_->{'date'}} @data),"\n";
#     print "max date ",List::Util::maxstr(map {$_->{'date'}} @data),"\n";
#   }
#   return $h;
# }
