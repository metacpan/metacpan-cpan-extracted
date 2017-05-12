# Copyright 2008, 2009, 2010, 2015 Kevin Ryde

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

package App::Chart::Suffix::FQ;
use 5.010;
use strict;
use warnings;
use Carp 'carp','croak';
use List::Util qw(min max);
use List::MoreUtils;
use Locale::TextDomain 'App-Chart';

use App::Chart::Download;
use App::Chart::LatestHandler;
use App::Chart::Sympred;
use App::Chart::Weblink;

use constant DEBUG => 0;

my $pred = App::Chart::Sympred::Suffix->new ('.FQ');


#-----------------------------------------------------------------------------
# specifics

{ my $tsp_pred = App::Chart::Sympred::Suffix->new ('.tsp.FQ');
  App::Chart::TZ->newyork->setup_for_symbol ($tsp_pred);

  # only home page, per their "Linkage to the TSP Web Site"
  App::Chart::Weblink->new
      (pred => $tsp_pred,
       name => __('_TSP Home Page'),
       desc => __('Open web browser at the US Government Thrift Savings Plan'),
       proc  => sub {
         eval { require Finance::Quote::TSP }
           && $Finance::Quote::TSP::TSP_MAIN_URL;
       });
}

{ my $usfed_pred = App::Chart::Sympred::Suffix->new ('.usfedbonds.FQ');
  App::Chart::Weblink->new
      (pred => $usfed_pred,
       name => __('_Fed Bonds Home Page'),
       desc => __('Open web browser at the US Treasury Federal Bonds site'),
       # $TREASURY_MAINURL is private
       url  => 'http://www.publicdebt.treas.gov/');
}

#-----------------------------------------------------------------------------

App::Chart::LatestHandler->new
  (pred => $pred,
   proc => \&latest_download);

my $FQ_re = qr/\.([^.]+)\.FQ$/p;

sub fq_symbol_method {
  my ($symbol) = @_;
  $symbol =~ $FQ_re or croak "Not an FQ symbol '$symbol'";
  return $1;
}
sub fq_symbol_sans_suffix {
  my ($symbol) = @_;
  $symbol =~ $FQ_re or croak "Not an FQ symbol '$symbol'";
  return ${^PREMATCH};
}

sub latest_download {
  my ($symbol_list) = @_;

  # split by method, preserving order among methods
  # ENHANCE-ME: could preserve order for "separate request" sources, just
  # join up the multiple request ones
  require Tie::IxHash;
  my %sm;
  tie %sm, 'Tie::IxHash';
  foreach my $symbol (@$symbol_list) {
    $symbol =~ $FQ_re or croak "Not an FQ symbol: $symbol";
    $symbol = ${^PREMATCH};
    my $method = $1;
    push @{$sm{$method}}, $symbol;
  }

  foreach my $method (keys %sm) {
    my $symbol_list = $sm{$method};
    if (DEBUG) { require Data::Dumper;
                 print "method $method ",
                   Data::Dumper->Dumper([$symbol_list],['symbol_list']); }

    App::Chart::Download::status
        (__x('Finance::Quote {method} {symbol_range}',
             method => $method,
             symbol_range => App::Chart::Download::symbol_range_string ($symbol_list)));

    my $q = quoter_for_method ($method);
    my $quotes = $q->fetch ($method, @$symbol_list);
    my $h = quotes_to_group (".$method.FQ", $symbol_list, $quotes);

    App::Chart::Download::write_latest_group ($h);
  }
}

# Return a Finance::Quote->new object, hopefully able to fetch $method.
#
# If FQ_LOAD_QUOTELET and/or the defaults don't offer $method then it's
# attempted with method_to_modules() below added.
#
# It'd be possible to try method_to_modules() first, and that would normally
# load much less code than the defaults, but it might also miss something in
# the defaults, or grab something no wanted, so start with the defaults and
# only then search further.
#
sub quoter_for_method {
  my ($method) = @_;
  require Finance::Quote;
  my $q = Finance::Quote->new;
  if (! List::Util::first {$_ eq $method} $q->sources) {
    my @modules = method_to_modules ($method);
    if (DEBUG) { require Data::Dumper;
                 print "FQ attempt method='$method' in ",
                   Data::Dumper->new([\@modules],['modules'])->Dump; }
    if (@modules) {
      ## no critic (RequireCheckingReturnValueOfEval)
      eval { Finance::Quote->new (@modules) };
      $q = Finance::Quote->new;
    }
  }
  return $q;
}

# Return a list of modules which seem likely candidates for $method.
#
# The return is ready to pass to Finance::Quote->new, so it doesn't have a
# "Finance::Quote::" prefix, so for instance $method "tsp" might give just
# "TSP".
#
# This is meant to automatically pickup modules not in the defaults or in
# FQ_LOAD_QUOTELET.  It can't cope with fallbacks offering extra sources for
# a given country etc, but it's much easier than adding to the env var
# whenever you install a new add-on.
#
sub method_to_modules {
  my ($method) = @_;

  # 'ftportfolios_direct' -> FTPortfolios.pm
  # 'seb_funds' -> SEB.pm
  # 'unionfunds' -> Union.pm
  # 'aex_options' -> AEX.pm
  # 'aex_futures' -> AEX.pm
  # 'stockhousecanada_fund' -> StockHouseCanada.pm
  $method =~ s/(_direct|_futures|_options|_?funds?)$//;

  require Module::Find;
  my @modules = Module::Find::findsubmod ('Finance::Quote');
  foreach (@modules) { s/^Finance::Quote::// }
  return grep /^\Q$method/i, @modules;
}

sub quotes_to_group {
  my ($symbol_suffix, $symbol_list, $quotes) = @_;
  if (DEBUG) { require Data::Dumper;
               print Data::Dumper::Dumper($quotes); }

  my @data = ();
  my $h = { source => __PACKAGE__,
            data   => \@data };
  foreach my $symbol (@$symbol_list) {

    my $last = $quotes->{$symbol,'last'};
    my $high = $quotes->{$symbol,'high'};
    my $low = $quotes->{$symbol,'low'};
    my $change = $quotes->{$symbol,'net'};

    # Finance::Quote::Fidelity version 1.05 gives 'price' rather than 'last'
    if (! defined $last) {
      my $price = $quotes->{$symbol,'price'};
      if (defined $price) {
        $last = $price;
      }
    }

    # Try making $change from 'close' (the previous close) and 'last'.
    #
    if (defined $last && ! defined $change) {
      my $prev = $quotes->{$symbol,'close'};
      if (defined $prev) {
        $change = decimal_subtract ($last, $prev);
      }
    }

    # Try making $change from 'p_change' and 'last'.
    #
    # $prev * (100 + $p_change) / 100 == $last
    # $prev == $last * 100 / (100 + $p_change)
    # $change == $last - $prev
    #         == $last - $last * 100 / (100 + $p_change)
    #         == $last * (1 - 100 / (100 + $p_change))
    #         == $last * $p_change / (100 + $p_change)
    #
    if (defined $last && ! defined $change) {
      my $p_change = $quotes->{$symbol,'p_change'};
      if (defined $p_change) {
        $change = $last * $p_change / (100 + $p_change);
        $change = sprintf ('%.*f', App::Chart::count_decimals($last), $change);
      }
    }

    # Separate high/low in for instance Finance::Quote::ZA
    # But Yahoo methods give just 'day_range'.
    #
    if (! defined $high) {
      my $day_range = $quotes->{$symbol,'day_range'};
      if (defined $day_range) {
        if ($day_range =~ /^([0-9.]+)-([0-9.]+)$/) {
          $high = $1;
          $low = $2;
        } else {
          carp "Unrecognised $symbol 'day_range': $day_range";
        }
      }
    }

    # Not needed any more
    #     my $volume = $quotes->{$symbol,'volume'};
    #     # Try approximating $volume from 'dollar_volume' and 'last'.
    #     # dollar_volume given by Finance::Quote::Casablanca
    #     #
    #     if ($last && ! defined $volume) {
    #       my $dollar_volume = $quotes->{$symbol,'dollar_volume'};
    #       if (defined $dollar_volume) {
    #         $volume = int ($dollar_volume / $last + 0.5); # round to nearest
    #       }
    #     }

    my $errormsg;
    if (! $quotes->{$symbol,'success'}) {
      $errormsg = $quotes->{$symbol,'errormsg'};
      if (! defined $errormsg) {
        if (List::MoreUtils::any {/^$symbol$;/} keys %$quotes) {
          $errormsg = __('Unknown error');
        } else {
          $errormsg = __('No data from FQ method');
        }
      }
    }

    # If 'ex_div' is yahoo style then it needs munging ...
    # $quotes->{$symbol,'div'},
    # $quotes->{$symbol,'ex_div'},

    push @data, { symbol   => $symbol . $symbol_suffix,
                  name     => $quotes->{$symbol,'name'},

                  quote_date => $quotes->{$symbol,'isodate'},
                  quote_time => $quotes->{$symbol,'time'},
                  bid        => $quotes->{$symbol,'bid'},
                  offer      => $quotes->{$symbol,'ask'},

                  last_date  => $quotes->{$symbol,'isodate'},
                  last_time  => $quotes->{$symbol,'time'},
                  open       => $quotes->{$symbol,'open'},
                  high       => $high,
                  low        => $low,
                  last       => $last,
                  change     => $change,

                  volume     => $quotes->{$symbol,'volume'},
                  currency   => $quotes->{$symbol,'currency'},
                  error      => $errormsg,

                  # various of mine
                  copyright  => $quotes->{$symbol,'copyright_url'},
                };
  }
  if (DEBUG) { require Data::Dumper;
               print Data::Dumper::Dumper($h); }
  return $h;
}

# Return the difference $x - $y, done as a "decimal" subtract, so retaining
# as many decimal places there are on $x and $y.
# It's done with some sprint %f fakery, not actual decimal arithmetic, but
# that's close enough for 4 decimal place currencies.
sub decimal_subtract {
  my ($x, $y) = @_;
  my $decimals = max (App::Chart::count_decimals($x),
                      App::Chart::count_decimals($y));
  return sprintf ('%.*f', $decimals, $x - $y);
}

1;
__END__
