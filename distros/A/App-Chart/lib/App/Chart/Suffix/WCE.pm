# Winnipeg Commodity Exchange (WCE) setups.

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

package App::Chart::Suffix::WCE;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_winnipeg = App::Chart::TZ->new
  (name     => __('Winnipeg'),
   choose   => [ 'America/Winnipeg' ],
   fallback => 'CST+6');

my $pred = App::Chart::Sympred::Suffix->new ('.WCE');
$timezone_winnipeg->setup_for_symbol ($pred);

$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);

#------------------------------------------------------------------------------
# weblink - contract specs
#
# When there's no specs for a given symbol the page served is the main
# list of available contracts,
#
#   http://www.wce.ca/ContractsMarketInfo.aspx?first=contractspecifications
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('WCE _Contract Specifications'),
   desc => __('Open web browser at the Winnipeg Commodity Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.wce.ca/ContractsMarketInfo.aspx?first=contractspecifications&Commodity='
       . URI::Escape::uri_escape (App::Chart::symbol_commodity ($symbol));
   });


1;
__END__
