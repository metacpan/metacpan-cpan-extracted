#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

{
  package MyOHLCVI;
  use strict;
  use warnings;
  use base 'App::Chart::Series';

  sub new {
    my $class = shift;
    my $series = $class->SUPER::new (@_);
  }
  sub fill_part {
  }
}

package main;
use strict;
use warnings;
use Test::More 0.82 tests => 6;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  require App::Chart::Timebase::Days;
  require App::Chart::Series::OHLCVI;
  my $timebase_days = App::Chart::Timebase::Days->new_from_iso ('1970-01-05');
  my $daily = MyOHLCVI->new
    (timebase => $timebase_days,
     hi => 4,
     arrays => { opens => [ 1, 2, 3, 4, 5 ],
                 highs => [ undef, undef, undef, undef, undef ],
                 lows  => [ undef, undef, undef, undef, undef ],
                 closes => [ undef, 7, 8, undef, 15 ],
                 volumes => [ 100, undef, 200, 100, 100 ],
                 openints => [ 100, undef, 200, 100, 150 ] },
     array_aliases => { values => 'closes' },
    );
  # diag explain $daily;

  my $weekly = $daily->collapse('Weeks');
  $weekly->fill (0,0);
  # diag 'weekly=', explain $weekly;
  is_deeply ($weekly->array('opens'),  [ 1 ]);
  is_deeply ($weekly->array('highs'),  [ 15 ]);
  is_deeply ($weekly->array('lows'),   [ 1 ]);
  is_deeply ($weekly->array('closes'), [ 15 ]);
  is_deeply ($weekly->array('volumes'), [ 500 ]);
  is_deeply ($weekly->array('openints'), [ 150 ]);
}

exit 0;
