# Buenos Aires Stock Exchange setups.

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

package App::Chart::Suffix::BA;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;

our $timezone_buenos_aires = App::Chart::TZ->new
  (name     => __('Buenos Aires'),
   choose   => [ 'America/Argentina/Buenos_Aires' ],
   fallback => 'ART+3');

# ^MERV
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^MER');
my $pred_shares = App::Chart::Sympred::Suffix->new ('.BA');

my $pred_any = App::Chart::Sympred::Any->new ($pred_shares, $pred_indexes);
$timezone_buenos_aires->setup_for_symbol ($pred_any);

1;
__END__
