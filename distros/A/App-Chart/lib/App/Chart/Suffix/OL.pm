# Oslo Stock Exchange setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A OLRTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Suffix::OL;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


our $timezone_oslo = App::Chart::TZ->new
  (name     => __('Oslo'),
   choose   => [ 'Europe/Oslo' ],
   fallback => 'CET-1');

# Indexes:
#   ^OSEAX
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^OS');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.OL');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_oslo->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - Oslo Bors company info
#
# Eg. Norwegian
#
#     http://www.oslobors.no/ob/aksje_selskapsinfo?languageID=0&p_instrid=ticker.ose.PLUG&p_period=1D&menu2show=1.1.2.4.
#
# and English
#
#     http://www.oslobors.no/ob/aksje_selskapsinfo?languageID=1&p_instrid=ticker.ose.PLUG&p_period=1D&menu2show=1.1.2.4.
#

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('Oslo Bors _Company Information'),
   desc => __('Open web browser at the Oslo Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (no => 0,
                                                              en => 1);
     return "http://www.oslobors.no/ob/aksje_selskapsinfo?languageID=$lang&p_instrid=ticker.ose.$symbol&p_period=1D&menu2show=1.1.2.4.";
   });

1;
__END__
