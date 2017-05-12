# Milan Stock Exchange setups.

# Copyright 2005, 2006, 2007, 2008, 2009 Kevin Ryde

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

package App::Chart::Suffix::MI;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


# As of March 2007 the http://finance.yahoo.com/exchanges list doesn't
# include Milan any more, but it still seems to work.


our $timezone_milan = App::Chart::TZ->new
  (name     => __('Milan'),
   # no separate entry for Milan in Olson database
   choose   => [ 'Europe/Milan', 'Europe/Rome' ],
   fallback => 'CET-1');

# ^MIBTEL
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^MIB');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.MI');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_milan->setup_for_symbol ($pred_any);

# ;; See: http://www.borsaitaliana.it/chisiamo/mercatigestiti/orari/orarionegoziazioni.en.htm
# ;; pre-open from 8:00, trading until 17:00 main and 17:30 mot, then
# ;; after-hours 18:00 to 20:30
# (yahoo-quote-lock! milan-symbol?
# 		   #,(hms->seconds 8 0 0) #,(hms->seconds 20 30 0))


#------------------------------------------------------------------------------
# weblink - only the home page for now ...
#
# Profile links are based on ISIN, eg IT.MI
# http://www.borsaitaliana.it/bitApp/scheda.bit?target=StrumentoMTA&isin=IT0001465159&lang=en

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Milan Stock Exchange Home Page'),
   desc => __('Open web browser at the Milan Stock Exchange home page'),
   url  => 'http://www.borsaitaliana.it');


1;
__END__
