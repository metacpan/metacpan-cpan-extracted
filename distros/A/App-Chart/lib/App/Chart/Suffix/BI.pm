# Bilbao Stock Exchange setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Suffix::BI;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_bilbao = App::Chart::TZ->new
  (name     => __('Bilbao'),
   # no separate Bilbao in Olson database
   choose   => [ 'Europe/Bilbao', 'Europe/Madrid' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.BI');
$timezone_bilbao->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...
# haven't found any actual .BI on yahoo except 20.BI index

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_Bilbao Stock Exchange Home Page'),
   desc => __('Open web browser at the Bilbao Stock Exchange home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   (en => 'http://www.bolsabilbao.es',
    eu => 'http://www.bolsabilbao.es/bolsa/eu/html/home-eu.html',
    es => 'http://www.bolsabilbao.es/bolsa/es/html/home-es.html',
    fr => 'http://www.bolsabilbao.es/bolsa/fr/html/home-fr.html'));


1;
__END__
