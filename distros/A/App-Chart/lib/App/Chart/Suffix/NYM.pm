# New York Mercantile Exchange setups.

# Copyright 2006, 2007, 2008, 2009 Kevin Ryde

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

package App::Chart::Suffix::NYM;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $pred = App::Chart::Sympred::Regexp->new (qr/\.(NYM|CMX)$/);
App::Chart::TZ->newyork->setup_for_symbol ($pred);

$App::Chart::Yahoo::latest_pred->add ($pred);
$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink - contract specs

App::Chart::Weblink->new
  (pred => $pred,
   name => __('NYMEX _Contract Specifications'),
   desc => __('Open web browser at the NYMEX/COMEX contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.nymex.com/'
       . URI::Escape::uri_escape (App::Chart::symbol_commodity ($symbol))
         . '_spec.aspx';
   });

#------------------------------------------------------------------------------
# barchart

App::Chart::Barchart::commodity_mung
  ($pred,
   # COMEX - no transforms
   # "HG" high grade copper
   # "GC" gold
   # "SI" silver
   # "AL" aluminium
   'QS' => 'AM',  # asian gold

   # NYMEX - no transformations
   # "CL" light sweet crude
   # "HU" gasoline
   # "HO" heating oil
   # "NG" henry hub natural gas
   # "PA" palladium
   # "PL" platinum
   # "PN" propane
   # "QG" e-miNY henry hub natural gas
   # "QL" CAPP central appalacian coal
   # "QM" e-miNY light sweet crude
   # "SC" brent crude - dublin
   #
   # "GR" north west gasoil - dublin
   # "SA" brent calendar swap futures - clearport new york
   #
   # don't know what barchart "F0" heating oil / crude and "F5"
   # unleaded / crude are really
  );

# (set! barchart-suffix-delay-alist (cons* '(".CMX" . 30)
# 					 '(".NYM" . 30)
# 					 barchart-suffix-delay-alist))


# This was some bits to make the timezone come out as London (and
# previously Dublin) for some relevant symbols.  But www.nymex.com doesn't
# make it clear (as of March 2007) what's where, so leave it all as New
# York for now.

# NYMEX symbols trading in London
#
# http://www.nymex.com/press_releas.aspx?id=pr20050825c
#     Aug 05 press release - brent crude + northwest gasoil
#
# (define (nymex-london-symbol? symbol)
#   (and (nymex-symbol? symbol)
#        (member (chart-symbol-commodity symbol)
# 	       '("GR"  # gasoil
# 		 "BB"  # brent crude
# 		 ))))
# (symbol-timezone! nymex-london-symbol?  (_ "London")    timezone-london)

# Contracts trading open-outcry in London (currently Brent Crude @samp{SC} and
# Northwest Europe Gasoil @samp{GR}) have that as their home timezone for the
# watchlist etc, everything else is New York.
# @c xSYMBOL: SC.NYM
# @c xSYMBOL: GR.NYM




1;
__END__
