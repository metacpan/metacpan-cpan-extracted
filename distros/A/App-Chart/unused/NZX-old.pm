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

#------------------------------------------------------------------------------
# dividends from HTML table
#
# This uses the dividend page at
#
use constant DIVIDENDS_URL =>
  'https://www.nzx.com/markets/NZSX/dividends';

App::Chart::DownloadHandler::DividendsPage->new
  (name     => __('NZX dividends'),
   pred     => $pred_shares,
   url      => DIVIDENDS_URL,
   parse    => \&dividends_parse,
   key      => 'NZ-dividends',
   # low priority so prices fetched first
   priority => -10);

sub dividends_parse {
  my ($resp) = @_;
  ### NZ dividends_parse() ...
  
  # note: want wide-chars for HTML::TableExtract parse
  my $body = $resp->decoded_content (raise_error => 1);
  ### $body

  my @dividends = ();
  my $h = { source          => __PACKAGE__,
            resp            => $resp,
            dividends       => \@dividends,
            copyright_key   => 'NZ-dividends-copyright',
            copyright       => 'http://www.nzx.com/terms',
            date_format     => 'dmy', # dates like "27 Sep 2018"
            prefer_decimals => 2,
          };

  # Column "Dividend Period" for "interim" or "final" not very interesting.
  # FIXME: what's the "Supp." column?
  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers   => ['Code',
                   'Ex',
                   'Payable',
                   'Amount',
                   'Currency',
                   'Imputation' ]);

  $te->parse($body);
  if (! $te->tables) {
    die "NZX dividend table not matched";
  }

  foreach my $ts ($te->tables) {
    foreach my $row ($ts->rows) {
      my ($symbol, $ex_date, $pay_date, $amount, $currency, $imput)
        = @$row;
      push @dividends,
        dividend_parse ($symbol, $ex_date,$pay_date,$amount, $currency,$imput);
    }
  }
  my $count = scalar(@dividends);
  App::Chart::Download::verbose_message ("NZX dividends total $count found");
  return $h;
}

sub dividend_parse {
  my ($symbol, $ex_date,$pay_date,$amount, $currency,$imput) = @_;
  ### NZ dividend_parse(): @_

  # leading and trailing whitespace
  $symbol = App::Chart::collapse_whitespace($symbol);
  $amount = App::Chart::collapse_whitespace ($amount);
  $imput  = App::Chart::collapse_whitespace ($imput);
  $currency = App::Chart::collapse_whitespace ($currency);

  foreach ($amount, $imput) {
    # eg. "3.900c" with c for cents, or latin-1 0xA2 cents symbol
    if (s/ *[c\xA2]$//) {
      $_ = App::Chart::Download::cents_to_dollars ($_);
    }
    # discard trailing zeros, when a whole number of cents
    $_ = App::Chart::Download::trim_decimals ($_, 2);
  }

  # foreign like AUD or GBP turned into merely a note
  my $note;
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

  return { symbol     => "$symbol.NZ",
           ex_date    => $ex_date,
           pay_date   => $pay_date,
           amount     => $amount,
           imputation => $imput,
           note       => $note };
}

