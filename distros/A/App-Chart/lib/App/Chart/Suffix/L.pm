# London Stock Exchange setups.

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

package App::Chart::Suffix::L;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Download;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;


# .L london shares and .IL for "international order book" shares
my $pred_shares = App::Chart::Sympred::Regexp->new (qr/\.(L|IL)$/);

# ^FTSE etc
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^FT');

my $pred_any = App::Chart::Sympred::Any->new ($pred_shares, $pred_indexes);
App::Chart::TZ->london->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - LSE company info
#
# This includes IOB international orderbook shares, like
#
#    http://www.londonstockexchange.com/en-gb/pricesnews/prices/system/detailedprices.htm?ti=TPSD
#

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('LSE _Company Information'),
   desc => __('Open web browser at the London Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.londonstockexchange.com/en-gb/pricesnews/prices/system/detailedprices.htm?ti='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });

1;
__END__
