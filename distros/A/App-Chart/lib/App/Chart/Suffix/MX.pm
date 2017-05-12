# Mexico Stock Exchange (BMV) setups.

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

package App::Chart::Suffix::MX;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


our $timezone_mexico = App::Chart::TZ->new
  (name     => __('Mexico City'),
   choose   => [ 'America/Mexico_City' ],
   fallback => 'CST+6');

# ^MXX ipc
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^MX');
my $pred_shares = App::Chart::Sympred::Suffix->new ('.MX');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_mexico->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_BMV Home Page'),
   desc => __('Open web browser at the Mexico Stock Exchange home page'),
   url  => 'http://www.bmv.com.mx');


1;
__END__
