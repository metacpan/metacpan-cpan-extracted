# Caracas Stock Exchange setups.

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

package App::Chart::Suffix::CR;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_caracas = App::Chart::TZ->new
  (name     => __('Caracas'),
   choose   => [ 'America/Caracas' ],
   fallback => 'VET+4:30');

# Indexes:
#   ^VEDOW
#   ^VEDOWD
#   ^DWVE
#   ^DWVED
#   ^DWVET
#   ^DWVEDT
#
my $pred_indexes = App::Chart::Sympred::Regexp->new (qr/^\^(DW)?VE/);

# There's a couple like IBC.CR which show up in an index search (for
# caracas) at yahoo, but no actual data it seems (as of March 2007).
# Dunno what quote delay would apply, leave App::Chart::Yahoo default 20 mins.
#
my $pred_shares = App::Chart::Sympred::Suffix->new ('.CR');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_caracas->setup_for_symbol ($pred_any);

# Dunno

#------------------------------------------------------------------------------
# weblink - only home page for now
#

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Caracas Stock Exchange'),
   desc => __('Open web browser at the Caracas Stock Exchange home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   (es => 'http://www.bolsadecaracas.com',
    en => 'http://www.bolsadecaracas.com/eng/index.jsp'));

1;
__END__
