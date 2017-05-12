# Ljubljana Stock Exchange (LJSE) setups.

# Copyright 2006, 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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


package App::Chart::Suffix::LJ;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::DownloadHandler::IndivChunks;
use App::Chart::LatestHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_ljubljana = App::Chart::TZ->new
  (name     => __('Ljubljana'),
   choose   => [ 'Europe/Ljubljana' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.LJ');
$timezone_ljubljana->setup_for_symbol ($pred);


# (source-help! ljubljana-symbol?
# 	      __p('manual-node','Ljubljana Stock Exchange'))


#-----------------------------------------------------------------------------
# weblink - company info
#
# eg.
# Slovenian: http://www.ljse.si/cgi-bin/jve.cgi?SecurityID=DRKR&doc=818
# English:   http://www.ljse.si/cgi-bin/jve.cgi?SecurityID=DRKR&doc=3131
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('LJSE _Company Information'),
   desc => __('Open web browser at the Ljubljana Stock Exchange information page for this company'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (en => '3131',
                                                  sl => '818');
     return "http://www.ljse.si/cgi-bin/jve.cgi?SecurityID=$symbol&doc=$lang";
   });


#-----------------------------------------------------------------------------
# latest
#
# This uses the text file at
#
#     http://www.ljse.si/cgi-bin/jve.cgi?doc=2111
#
# which is
#
use constant BTS_URL => 'http://www.ljse.si/datoteke/BTStecajEUR.txt';
#
# The charset isn't specified in the http headers nor the file format specs
# but it's codepage 1250.  The server provides ETag and Last-Modified.
#
# The symbols in each file are cached, so it's usually possible to go
# straight to the right one.  If some symbols aren't where expected then
# both are downloaded to recheck.
#

App::Chart::LatestHandler->new
  (pred => $pred,
   available_tdate => \&available_tdate,
   proc => \&latest_download);

# per specs pdf file, available around 16:30 each day
sub available_tdate {
  App::Chart::Download::tdate_today_after (16,30, $timezone_ljubljana);
}

sub latest_download {
  my ($symbol_list) = @_;

  App::Chart::Download::status (__('LJSE price file'));
  my $resp = App::Chart::Download->get (BTS_URL,
                                       url_tags_key => 'LJ-BTStecajEUR');
  if (! $resp->is_success) {
    return; # 304 not modified
  }
  App::Chart::Download::write_latest_group (bts_parse ($resp));
}

my ($L0010, $L0020);

sub bts_parse {
  my ($resp) = @_;

  my @data = ();
  my $h = { source       => __PACKAGE__,
            url_tags_key => 'LJ-BTStecajEUR',
            resp         => $resp,
            currency     => 'EUR',
            date_format  => 'dmy',
            suffix       => '.TSP',
            data         => \@data };
  # charset not specified, but is codepage 1250
  my $content = $resp->decoded_content (raise_error => 1,
                                        default_charset => 'cp1250');
  $content =~ s/\r//g;

  # 0001 file format marker
  #   $content =~ /^ 0001 110 /
  #     or die 'Ljubljana: BTS file missing 0001 id line';

  # my $date = txt_to_date ($content);

  foreach my $line (split /\n+/, $content) {
    my $elem;

    if ($line =~ /^ 0010 /) {
      # index
      $L0010 ||= make_parser (code           => 4,
                              symbol         => 8,
                              name           => 40,
                              close          => '15.',
                              change         => '15.',
                              percent_change => '15.');

      $elem = $L0010->($line);
      $elem->{'symbol'} = '^' . $elem->{'symbol'};

    } elsif ($line =~ /^ 0020 /) {
      # stock
      $L0020 ||= make_parser (code             => 4,
                              tier             => 4,
                              type             => 4,
                              symbol           => 8,
                              isin             => 20,
                              name             => 40,
                              dividend         => '15.',
                              note_num         => 10,
                              average_price    => '15.',
                              change           => '15.',
                              percent_change   => '15.',
                              last_date        => 10,
                              bid              => '15.',
                              offer            => '15.',
                              high             => '15.',
                              low              => '15.',
                              open             => '15.',
                              close            => '15.',
                              volume           => 12,
                              volume_offmarket => 12,
                              turnover         => 12,
                              turnover_bas     => 12,
                              IF_1             => 15,
                              IF_2             => 15,
                              IF_percent       => 15,
                              note             => 10,
                              shares_issued    => 12,
                              dividend_date    => 10,
                              p_e              => 10,
                              principle        => 20,
                              interest         => 20,
                              coupon_num       => 5,
                              market_discount  => 15,
                              name_and_city    => 80,
                              trading_mode     => 5,
                              market_maker_cont => 5,
                              transactions      => 15,
                              num_units         => 15,
                              turnover_nonblock => 15);
      $elem = $L0020->($line);

      # bid/offer -1 for market order
      if ($elem->{'bid'}   eq '-1') { delete $elem->{'bid'}; }
      if ($elem->{'offer'} eq '-1') { delete $elem->{'offer'}; }

      # empty when no trades, show 0 instead of letting it go undef in
      # crunch_h() as if no data
      if ($elem->{'volume'} eq '') {
        $elem->{'volume'} = 0;
      }

      # dividend date is empty, apparently, otherwise would show "ex" as note
      #
      # other notes:
      # A - cross
      # B - block trades
      # o - utilized tax allowance
      # S - temporary suspension
      # Z - temporary halt
      # * - 10% limit move
      # NP - data not received
      # D - shareholders meeting will decide dividend
      # V - interim dividend
      # Q - P/E calculated prev year, without Q two years before
      #
      if ($elem->{'note'} =~ /Z/ || $elem->{'note'} =~ /S/) {
        $elem->{'halt'} = 1;
      }
      if ($elem->{'note'} =~ /\*/) {
        if ($elem->{'change'} >= 0) {
          $elem->{'limit_up'} = 1;
        } else {
          $elem->{'limit_down'} = 1;
        }
      }
      if ($elem->{'note'} =~ /D/) {
        $elem->{'dividend_to_be_advised'} = 1;
      }
    }

    if ($elem) {
      $elem->{'symbol'} .= '.LJ';

      # as of May 2007 the change field is empty, but the change % field is
      # supplied
      if ($elem->{'close'} ne ''
          && exists $elem->{'change'} && $elem->{'change'} eq '') {
        $elem->{'change'} = percent_change_to_change
          ($elem->{'close'}, $elem->{'percent_change'});
      }
      push @data, { %$elem };
    }
  }
  return $h;
}

sub make_parser {
  my @desc = @_;
  my @field_list;
  my @space_list;
  my @decimal_list;
  my $format = '';
  my $i = 0;
  while (@desc) {
    my $space_field = "space_$i";
    push @field_list, $space_field;
    push @space_list, $space_field;
    $i++;
    $format .= 'A1';

    my $field = shift @desc;
    push @field_list, $field;
    my $width = shift @desc;
    if ($width =~ s/\.$//) { push @decimal_list, $field; }
    $format .= "A$width";
  }
  return sub {
    my ($line) = @_;
    my %elem;
    @elem{@field_list} = unpack $format, $line;
    foreach (values %elem) {
      s/^ +//;
      s/ +$//;
    }
    foreach my $field (@decimal_list) {
      $elem{$field} =~ tr/,/./;
    }
    foreach (delete @elem{@space_list}) {
      $_ eq '' or die "LJSE: bad fixed with separator on $line";
    }
    return \%elem;
  };
}

# pick out the "0002" trading day from a .txt file
sub txt_to_date {
  my ($content) = @_;
  $content =~ /^ 0002 ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]) /m
    or die 'Ljubljana: txt file missing 0002 date line';
  return "$3-$2-$1";
}

# VALUE is a string like "1234.50" which is a latest index value, and
# change-% is a string like "-0.09" which is a percentage change from the
# previous index value.  Return a change amount as a string in points
# instead of percentage.
#
sub percent_change_to_change {
  my ($value, $percent_change) = @_;
  my $decimals = App::Chart::count_decimals ($value);

  # value = prev * (1 + change%/100)
  # so       prev = value * 100/(100+change%)
  # want     change = value - prev
  # which is change = value * (1 - 100/(100+change%))
  #                 = value * -change% / (100+change%)
  #                 = value * change% / (100+change%)
  #
  return sprintf '%.*f', $decimals,
    $value * $percent_change / ($percent_change + 100);
}


#-----------------------------------------------------------------------------
# download - individual
#
# This uses the data archives at
#
#     http://www.ljse.si/cgi-bin/jve.cgi?doc=2069
#
# which gives a csv download like
#
#     http://www.ljse.si/cgi-bin/jve.cgi?sid=cUg7wt8bhOKsEJiy&doc=2137&date1=02.07.2007&date2=04.07.2007&IndexCode=SBI20&SecurityId=ACLG&x=53&y=10
#
# "sid" is a session id of some sort, it works to drop it and the x and y.
# The "csv" option isn't shown on the web page any more, but still works.
# Thus,
#
#     http://www.ljse.si/cgi-bin/jve.cgi?doc=2137&date1=02.07.2007&date2=04.07.2007&IndexCode=SBI20&SecurityId=ACLG&csv=1
#
# When there's no trading days in the requested range (public holidays),
# the file obtained is empty.

App::Chart::DownloadHandler::IndivChunks->new
  (name            => __('Yahoo'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   url_func        => \&podatki_url,
   parse           => \&podatki_parse,
   chunk_size      => 2500);

# return a url string, as per the examples shown above
sub podatki_url {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;

  my $index = ($symbol =~ /^\^/);
  $symbol =~ s/^\^//;
  $symbol = App::Chart::symbol_sans_suffix ($symbol);
  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);

  return sprintf 'http://www.ljse.si/cgi-bin/jve.cgi?doc=2137&date1=%02d.%02d.%04d&date2=%02d.%02d.%04d&IndexCode=%s&SecurityId=%s&csv=1',
     $lo_day, $lo_month, $lo_year,
     $hi_day, $hi_month, $hi_year,
     ($index ? $symbol : ''),   # index symbol, or empty
     ($index ? 'X' : $symbol);  # share symbol, or dummy
}

sub podatki_parse {
  my ($symbol, $resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);
  my $index = ($symbol =~ /^\^/); # if an index symbol

  my @data = ();
  my $h = { source        => __PACKAGE__,
            currency      => 'EUR',
            date_format   => 'mdy',  # eg. 'Jul 28. 2006'
            # last_download => 1,
            data          => \@data };

  foreach my $line (split /\n/, $content) {
    my ($date, $index_price, $stock_price) = split /;/, $line;
    push @data, { date   => $date,
                  symbol => $symbol,
                  close  => ($index ? $index_price : $stock_price) };
  }
  return $h;
}

1;
__END__



# @c ---------------------------------------------------------------------------
# @c @node Ljubljana Stock Exchange
# @c @section Ljubljana Stock Exchange
# @c @cindex Ljubljana stock exchange
# @c @cindex Slovenia
# @c 
# @c @uref{http://www.ljse.si}
# @c 
# @c LJSE provides
# @c 
# @c @itemize
# @c @item
# @c Quotes at the end of each day for stocks, indices and bonds.
# @c @item
# @c Historical average prices for stocks and indices.
# @c @end itemize
# @c 
# @c The LJSE website information is for non-commercial use only.  See the terms at
# @c 
# @c @quotation
# @c @uref{http://www.ljse.si/cgi-bin/jve.cgi?doc=1506}
# @c @end quotation
# @c 
# @c @cindex @code{.LJ}
# @c In Chart LJSE stock symbols have a @samp{.LJ} suffix, for instance
# @c @samp{ACLG.LJ} for ACH d.d., and similarly bonds like @samp{RS62.LJ}.  Indexes
# @c have a @samp{^} prefix, for instance @samp{^SBI20.LJ} for the Slovenian 20.
# @c All prices are in Euros (having converted from Slovenian Tolar in January
# @c 2007).
# @c @c SYMBOL: ACLG.LJ
# @c @c SYMBOL: RS62.LJ
# @c 
# @c The data archive downloads only give average daily prices.  The whole-day
# @c files (which are used for quotes) have high/low ranges and trading volume, but
# @c at 160k per day it would be too much to download them for a past few years
# @c data.


