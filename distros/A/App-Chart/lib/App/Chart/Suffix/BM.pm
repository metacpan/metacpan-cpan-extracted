# Bremen Stock Exchange setups.

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

package App::Chart::Suffix::BM;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;


my $timezone_bremen = App::Chart::TZ->new
  (name     => __('Bremen'),
   # no separate entry for Bremen in the Olson database
   choose   => [ 'Europe/Bremen', 'Europe/Berlin' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.BM');
$timezone_bremen->setup_for_symbol ($pred);

1;
__END__
