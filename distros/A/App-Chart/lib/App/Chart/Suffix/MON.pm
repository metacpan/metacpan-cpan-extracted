# Montreal Exchange (MX) setups and data downloading.   -*- coding: latin-1 -*-

# Copyright 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Suffix::MON;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_montreal = App::Chart::TZ->new
  (name     => __('Montreal'),
   choose   => [ 'America/Montreal' ],
   fallback => 'EST+5');

my $pred = App::Chart::Sympred::Suffix->new ('.MON');
$timezone_montreal->setup_for_symbol ($pred);

# (source-help! mx-symbol? __p('manual-node','Montreal Exchange'))


#------------------------------------------------------------------------------
# weblink - contract specs
#
# eg. http://www.m-x.ca/produits_taux_int_cgb_en.php
#     http://www.m-x.ca/produits_indices_sxf_en.php
# The sector indexes SXA,SXB,SXH,SXY are all on the one sxa page.
#
#

# this table is the equity index contracts, the rest default to being an
# interest rate contract (BAX, OBX, ONX, CTZ, CGB, OGB).
#
my %mx_equity_index_commodities
  = ('SXF' => 'indices_sxf',
     'SXA' => 'indices_sxa',
     'SXB' => 'indices_sxa',
     'SXH' => 'indices_sxa',
     'SXY' => 'indices_sxa');

App::Chart::Weblink->new
  (pred => $pred,
   name => __('MX _Contract Specifications'),
   desc => __('Open web browser at the Montreal Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     my $page = $mx_equity_index_commodities{$commodity}
       || "taux_int_\L$commodity";
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (en => 'en',
                                                  fr => 'fr');
     return "http://www.m-x.ca/produits_${page}_$lang.php";
   });


#-----------------------------------------------------------------------------
# download - data
#
# This uses the end-of-day download page at
#
#     http://www.m-x.ca/nego_fin_jour_en.php
#
# which results in a download like the following for 12 Jun 06 to 20 Jun 06
#
#     http://www.m-x.ca/nego_cotes_csv.php?symbol=CGB&jj=12&mm=06&aa=06&jjF=23&mmF=06&aaF=06
#

my $want_heading = 'Date;ClassSymbol;ClassType;UnderlyingSymbol;ExtSymbol;StrikePrice;ExpiryDate;CallPut;RootSymbol;InsSymbol;InsType;UpdateTime;LastTradeTime;BidPrice;AskPrice;BidSize;AskSize;LastPrice;Volume;PrevClosePrice;NetChange;OpeningPrice;HighPrice;LowPrice;TotalValue;NbOfTrades;SettlementPrice;OpenInterest;ImpliedVolatility';

sub daily_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  # html <!-- comments --> seen Aug 07
  $content =~ s/<!--.*?-->//sg;

  # quotes in headings lines
  $content =~ s/\"//g;
  $content =~ s/\r//g;

  # strip 'CGBfr12007-07-03' from headings lines seen in Jul07
  $content =~ s/^CGBfr1[0-9][0-9][0-9][0-9]-?[0-9][0-9]-?[0-9][0-9](Date.*)/$1/g;
  my @lines = split /\n/, $content;
  { my $line = shift @lines;
    if ($line ne $want_heading) {
      die "MX data unrecognised headings: $line";
    }
  }
  @lines = grep {$_ ne $want_heading} @lines;

  my @data = ();
  my $h = { source        => __PACKAGE__,
            currency      => 'CND',
            data          => \@data };

  foreach my $line (@lines) {
    my ($date, $class, $commodity, $underlying, $symbol,
        $strike, $expiry_date, $call_put, $root_symbol, $ins_symbol, $ins_type,
        $update_time, $last_trade_time,
        $bid, $ask, $bid_size, $ask_size, $last,
        $volume, $prev_close, $change, $open, $high, $low,
        $total_value, $num_trades, $settle, $openint,
        $volatility)
      = split /;/, $line;

    push @data, { symbol      => "$symbol.MON",
                  date        => $date, # eg. 2005-06-24 ISO already
                  # contracts continue to appear for a few days after
                  # expiry, use this date to exclude
                  expiry_date => $expiry_date,
                  open        => $open,
                  high        => $high,
                  low         => $low,
                  close       => $settle,
                  volume      => $volume,
                  openint     => $openint,
                };
  }
  return $h;
}
1;
__END__
