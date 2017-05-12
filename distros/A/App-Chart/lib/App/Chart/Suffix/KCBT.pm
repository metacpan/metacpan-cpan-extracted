# Kansas City Board of Trade (KCBT) setups.

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

package App::Chart::Suffix::KCBT;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Suffix::MGEX;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


our $timezone_kansas = App::Chart::TZ->new
  (name     => __('Kansas City'),
   # no separate Olson entry for Kansas City
   choose   => [ 'America/Kansas_City', 'America/Chicago'],
   fallback => 'CST+6');

my $pred = App::Chart::Sympred::Suffix->new ('.KCBT');
$timezone_kansas->setup_for_symbol ($pred);

# (source-help! kcbt-symbol?
# 	      (__p('manual-node','Kansas City Board of Trade'))


$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink - contract specs

my %weblink_url = ('KW' => 'http://www.kcbt.com/contract_wheat.html',
                   'KE' => 'http://www.kcbt.com/symbols_trading_hours.html',
                   'MV' => 'http://www.kcbt.com/symbols_trading_hours.html');
App::Chart::Weblink->new
  (pred => $pred,
   name => __('KCBT _Contract Specifications'),
   desc => __('Open web browser at the Kansas City Board of Trade contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     return $weblink_url{App::Chart::symbol_commodity ($symbol)};
   });


#-----------------------------------------------------------------------------
# intraday
#
# Alternately to do it with the main App::Chart::Barchart
#     $App::Chart::Barchart::intraday_pred->add ($pred);
#

App::Chart::Suffix::MGEX::barchart_customer_intraday
  ($pred,
   'http://customer1.barchart.com/cgi-bin/mri/kcbtchart.htx?page=chart&code=mfo&org=com&crea=Y');

#  (lambda (symbol)
#    (let ((date-time (kcbt-quote-adate-time symbol)))
#      (set-first! date-time (adate->tdate (first date-time)))
#      date-time))

1;
__END__
