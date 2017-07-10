# Montreal Exchange (MX) setups and data downloading.   -*- coding: latin-1 -*-

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2017 Kevin Ryde

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


# Not working yet.
# Pages exist.


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

# uncomment this to run the ### lines
use Smart::Comments;


my $timezone_montreal = App::Chart::TZ->new
  (name     => __('Montreal'),
   choose   => [ 'America/Montreal',
                 # There was some balls-up in the IANA data or something
                 # which lost Montreal from the Olson database in some
                 # GNU/Linux distros.  Is Toronto about the same, or close
                 # enough for times affected by this lossage?
                 'America/Toronto' ],
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
# which results in a download like the following for 1 Jul 17 to 5 Jul 17
#
#     https://www.m-x.ca/nego_fin_jour_en.php?=o&symbol=&o=&f=CGB&from=2017-07-01&to=2017-07-05&dnld=Download
#

App::Chart::DownloadHandler::IndivChunks->new
  (name       => __('Montreal'),
   pred       => $pred,
   available_tdate_by_symbol => \&daily_available_tdate,
   url_func   => \&daily_url,
   parse      => \&daily_parse,
   chunk_size => 120);   # maximum 6 months = 130 weekdays

sub daily_available_tdate {
  my ($symbol) = @_;
  return App::Chart::Download::tdate_today_after
    (18,0, App::Chart::TZ->for_symbol ($symbol));
}

sub daily_url {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;

  # http redirects to https, so go straight to that
  # "Display" is up to 5 days, "Download" is up to 6 months

  return "https://www.m-x.ca/nego_fin_jour_en.php?=o&symbol=&o="
    . "&f="    . App::Chart::symbol_sans_suffix($symbol)
    . "&from=" . App::Chart::tdate_to_iso($lo_tdate)
    . "&to="   . App::Chart::tdate_to_iso($hi_tdate)
    . "&dnld=Download";
}

sub split_line {
  my ($line) = @_;
  my @ret;
  while ($line =~ m{<t[hd]>(.*?)</t[hd]>}g) {
    push @ret, $1;
  }
  return @ret;
}

sub daily_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  # lines like
  # <tr><th>Date</th><th>Class Symbol</th>...
  my @lines = split /\n/, $content;
  @lines = grep /^<tr>/, @lines;

  # 'InstrumentSymbol' includes month like CGBU17

  my @headings;
  {
    my $headings = shift @lines // die "MX data no headings line";
    ### $headings
    @headings = split_line($headings);
    foreach (@headings) { s/[ .]+//g; }
    ### @headings
  }
  my @data = ();
  my $h = { source        => __PACKAGE__,
            currency      => 'CND',
            data          => \@data };

  foreach my $line (@lines) {
    ### $line
    my %hash;
    @hash{@headings} = split_line($line);
    ### %hash

    # my ($date, $class, $commodity, $underlying, $symbol,
    #     $strike, $expiry_date, $call_put, $root_symbol, $ins_symbol, $ins_type,
    #     $update_time, $last_trade_time,
    #     $bid, $ask, $bid_size, $ask_size, $last,
    #     $volume, $prev_close, $change, $open, $high, $low,
    #     $total_value, $num_trades, $settle, $openint,
    #     $volatility)
    #   = split /;/, $line;


    push @data, { symbol      => $hash{'ClassSymbol'} . '.MON',
                  date        => $hash{'Date'}, # eg. 2005-06-24 ISO already
                  expiry_date => $hash{'ExpiryDate'},
                  open        => $hash{'OpenPrice'},
                  high        => $hash{'HighPrice'},
                  low         => $hash{'LowPrice'},
                  close       => $hash{'SettlementPrice'},
                  volume      => $hash{'Volume'},
                  openint     => $hash{'OpenInterest'},

                  bid         => $hash{'BidPrice'},
                  offer       => $hash{'AskPrice'},
                  last        => $hash{'LastPrice'},
                  last_time   => $hash{'LastTradeTime'},
                  change      => $hash{'NetChange'},
                };
  }
  return $h;
}
1;
__END__
