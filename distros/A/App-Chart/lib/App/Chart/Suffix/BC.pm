# Barcelona Stock Exchange setups.

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

package App::Chart::Suffix::BC;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_barcelona = App::Chart::TZ->new
  (name     => __('Barcelona'),
   # only Madrid for Spain in the Olson database
   choose   => [ 'Europe/Barcelona', 'Europe/Madrid' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.BC');
$timezone_barcelona->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_Barcelona Stock Exchange Home Page'),
   desc => __('Open web browser at the Barcelona Stock Exchange home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   (es => 'http://www.borsabcn.es',
    en => 'http://www.borsabcn.es/bolsabcn/navegacion.nsf/vweb/p_eng?OpenDocument'));

1;
__END__
