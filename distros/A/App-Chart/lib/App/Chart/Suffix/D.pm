# Dusseldorf Stock Exchange setups.

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

package App::Chart::Suffix::D;

use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_dusseldorf = App::Chart::TZ->new
  (name     => __('Dusseldorf'),
   choose   => [ 'Europe/Dusseldorf', 'Europe/Berlin' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.D');
$timezone_dusseldorf->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_Dusseldorf Stock Exchange Home Page'),
   desc => __('Open web browser at the Dusseldorf Stock Exchange home page'),
   # German only, apparently
   url  => 'http://www.boerse-duesseldorf.de');


1;
__END__
