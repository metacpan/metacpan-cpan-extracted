# !!! long way from working ...


# LIFFE setups.

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Suffix::LIFFE;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $pred = App::Chart::Sympred::Suffix->new ('.LIFFE');
App::Chart::TZ->london->setup_for_symbol ($pred);

$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink - contract specs

# FIXME: but LON, PAR, AMS in weblink ...

App::Chart::Weblink->new
  (pred => $pred,
   name => __("LIFFE _Contract Specifications"),
   desc => __("Open web browser at the LIFFE contract specifications for this commodity."),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (en => 'EN',
                                                  fr => 'FR',
                                                  nl => 'NL',
                                                  pt => 'PT');
     return "http://www.euronext.com/trader/contractspecifications/derivative/wide/contractspecifications-2864-$lang.html?euronextCode=$commodity-PAR-FUT";
   });

1;
__END__
