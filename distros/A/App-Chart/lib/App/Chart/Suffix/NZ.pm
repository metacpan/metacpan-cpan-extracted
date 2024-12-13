# New Zealand Stock Exchange setups.

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2017, 2018, 2024 Kevin Ryde

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

package App::Chart::Suffix::NZ;
use 5.006;
use strict;
use warnings;
use JSON;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Database;
use App::Chart::Google;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::DividendsPage;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

# uncomment this to run the ### lines
# use Smart::Comments;


our $timezone_newzealand = App::Chart::TZ->new
  (name     => __('New Zealand'),
   choose   => [ 'Pacific/Auckland' ],
   fallback => 'NST-12');

# http://au.finance.yahoo.com/nzindices
#     ^NZ50
#     ^NZC50
#     ^NZ10G
#     ^NZMGC
#     ^NZGI
#     ^NZSCG
#     ^NZ50G
#     ^NZ30G
my $pred_shares = App::Chart::Sympred::Suffix->new ('.NZ');
my $pred_any = App::Chart::Sympred::Regexp->new (qr/^\^NZ|\.NZ$/);
$timezone_newzealand->setup_for_symbol ($pred_any);

App::Chart::setup_source_help
  ($pred_any, __p('manual-node','New Zealand Stock Exchange'));

# See http://www.nzx.com/markets/key-dates/trading-hours
# pre-open 9am-10am, trading 10am-5pm, adjust 5:30pm, then enquiry
# NZAX shares are only 10am to 4:30pm, but don't worry about that
# (yahoo-quote-lock! newzealand-symbol?
# 		   #,(hms->seconds 9 0 0) #,(hms->seconds 17 30 0))
# Yahoo index values based on last trades, so they should only update
# during trading 10am to 5pm.
# (yahoo-quote-lock! yahoo-index-symbol-newzealand?
# 		   #,(hms->seconds 10 0 0) #,(hms->seconds 17 0 0))

$App::Chart::Google::google_web_pred->add ($pred_shares);


#------------------------------------------------------------------------------
# weblink - NZX company info
#
# Eg. https://www.nzx.com/markets/NZSX/securities/FBU
# 
# cf top by value traded,
# https://www.nzx.com/markets/NZSX/securities/values

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('NZX _Company Information'),
   desc => __('Open web browser at the New Zealand Stock Exchange page for this stock'),
   proc => sub {
     my ($symbol) = @_;
     return 'https://www.nzx.com/markets/NZSX/securities/'
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });


#------------------------------------------------------------------------------
# Dividends
#
# This uses the dividend page at
# 
#     https://www.nzx.com/markets/NZSX/dividends
#     
# The dividend table is buried in a JSON data structure in <script>
# so as minimise the number browsers which will display it.
# As of Sept 2024 the page was about 100 kbytes with 50 dividends
# (declared or to be paid).
# So set to weekly downloads.
#
use constant DIVIDENDS_URL =>
  'https://www.nzx.com/markets/NZSX/dividends';

App::Chart::DownloadHandler::DividendsPage->new
  (name         => __('NZX dividends'),
   pred         => $pred_shares,
   url          => DIVIDENDS_URL,
   parse        => \&dividends_parse,
   key          => 'NZ-dividends',
   recheck_days => 7,
   # low priority so prices fetched first
   priority => -10);

sub dividends_parse {
  my ($resp) = @_;
  ### NZ dividends_parse() ...

  my @dividends = ();
  my $h = { source          => __PACKAGE__,
            resp            => $resp,
            dividends       => \@dividends,
            copyright_key   => 'NZ-dividends-copyright',
            copyright       => 'https://www.nzx.com/meta-pages/terms-of-use',
            date_format     => 'ymd', # ISO 2024-09-09
            prefer_decimals => 2,
          };

  # note: want wide-chars for HTML::TableExtract parse
  my $content = $resp->decoded_content (raise_error => 1);
  $content =~ /<script id="__NEXT_DATA__".*?>(.*?)<\/script>/i
    or die "NZX dividends cannot find JSON table";
  my $str = $1;
  my $json = JSON::from_json($1) // {};

  my $props           = $json->{'props'} // {};
  my $pageProps       = $props->{'pageProps'} // {};
  my $data            = $pageProps->{'data'} // {};

  # marketInstruments array of hashrefs like
  #   "code" : "AFI",
  #   "isin" : "AU000000AFI5",
  #   "name" : "Australian Foundation Investment Company Limited Ord Shares",
  #   "currencyCode" : "NZD",
  # Maps "isin" to exchange "code".
  # "name" is longer than want to display, so stay with Yahoo "shortname".
  #
  my $marketInstruments = $data->{'marketInstruments'} // [];
  my %isin_to_symbol;
  foreach my $href (@$marketInstruments) {
    my $isin = $href->{'isin'} // next;
    my $code = $href->{'code'} // next;
    $isin_to_symbol{$isin} = "$code.NZ";
  }
  # print JSON->new->pretty->encode($marketInstruments), "\n"; exit 0;

  my $marketDividends = $data->{'marketDividends'}
    // die "NZX dividends parse failed";
  # print JSON->new->pretty->encode($marketDividends), "\n"; exit 0;

  # eg. "amount" : "23.000000000",
  #     "currencyCode" : "NZD",
  #     "imputationCreditAmount" : "0.08166667",
  #     "baseQuantity" : "100",
  #     "expectedDate" : 1724673600
  #     "payableDate"  : 1727352000,
  #     "supplementaryAmount" : "0.03705882",
  # Dates are Unix seconds since 1970 GMT and in NZ timezone is
  # midnight on the relevant date.
  #
  foreach my $href (@$marketDividends) {
    my $isin = $href->{'isin'};
    my $symbol = $isin_to_symbol{$href->{'isin'}}
      // die "NZX dividends, no symbol for ISIN $isin";

    my $amount = App::Chart::Download::trim_decimals
      (App::Chart::Download::cents_to_dollars($href->{'amount'}),
       2);
    my $imput  = $href->{'imputationCreditAmount'};
    my $ex_date  = $timezone_newzealand->iso_date($href->{'expectedDate'});
    my $pay_date = $timezone_newzealand->iso_date($href->{'payableDate'});

    # Dividends not in NZD shown just as note.
    # Can have AUD for dual-listed Aust/NZ shares, eg. DOW.AX = DOW.NZ
    # In the past had some GBP.
    my $note;
    my $currency = $href->{'currencyCode'} // '';
    if ($currency ne 'NZD') {
      if ($imput ne '' && $imput != 0) {
        $note = "$amount + $imput $currency";
      } else {
        $note = "$amount $currency";
      }
      $note = App::Chart::collapse_whitespace ($note);
      $amount = undef;
      $imput = undef;
    }

    push @dividends, { symbol     => $symbol,
                       ex_date    => $ex_date,
                       pay_date   => $pay_date,
                       amount     => $amount,
                       imputation => $imput,
                       note       => $note,
                     };
  }
  my $count = scalar(@dividends);
  App::Chart::Download::verbose_message ("NZX dividends total $count found");
  return $h;
}

sub dividend_parse {
  my ($symbol, $ex_date,$pay_date,$amount, $currency,$imput) = @_;
  ### NZ dividend_parse(): @_

  # leading and trailing whitespace

  foreach ($amount, $imput) {
    # eg. "3.900c" with c for cents, or latin-1 0xA2 cents symbol
    if (s/ *[c\xA2]$//) {
      $_ =  ($_);
    }
    # discard trailing zeros, when a whole number of cents
    $_ = App::Chart::Download::trim_decimals ($_, 2);
  }

  # foreign like AUD or GBP turned into merely a note

  return ;
}

#------------------------------------------------------------------------------

# (String quoting for parsing of <script> in HTML to get crumb.)
# undo javascript string backslash quoting in STR, per
#
#     https://developer.mozilla.org/en/JavaScript/Guide/Values,_Variables,_and_Literals#String_Literals
#
# Encode::JavaScript::UCS does \u, but not the rest
#
# cf Java as such not quite the same:
#   unicode: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#100850
#   strings: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#101089
#
my %javascript_backslash = ('b' => "\b",   # backspace
                            'f' => "\f",   # formfeed
                            'n' => "\n",   # newline
                            'r' => "\r",
                            't' => "\t",   # tab
                            'v' => "\013", # vertical tab
                           );
sub javascript_string_unquote {
  my ($str) = @_;
  $str =~ s{\\(?:
              ((?:[0-3]?[0-7])?[0-7]) # $1 \377 octal latin-1
            |x([0-9a-fA-F]{2})        # $2 \xFF hex latin-1
            |u([0-9a-fA-F]{4})        # $3 \uFFFF hex unicode
            |(.)                      # $4 \n etc escapes
            )
         }{
           (defined $1 ? chr(oct($1))
            : defined $4 ? ($javascript_backslash{$4} || $4)
            : chr(hex($2||$3)))   # \x,\u hex
         }egx;
  return $str;
}


#------------------------------------------------------------------------------

1;
__END__
