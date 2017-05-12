#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

package main;
use strict;
use warnings;
use Test::More tests => 3;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  require App::Chart::Timebase::Days;
  require App::Chart::Series::OHLCVI;
  my $timebase_days = App::Chart::Timebase::Days->new_from_iso ('1970-01-05');
  my $parent = MyOHLCVI->new
    (timebase => $timebase_days,
     hi => 4,
     arrays => { closes  => [  1,  2 , 3,  2,  1 ],
                 volumes => [ 11, 12, 13, 14, 15 ] },
     array_aliases => { values => 'closes' },
     name => 'Foo',
    );

  {
    my $obv = $parent->OBV;
    $obv->fill (0, $obv->hi);
    is_deeply ($obv->values_array, [ 0, 12, 25, 11, -4 ]);
  }
  {
    my $obv = $parent->OBV;
    $obv->fill ($obv->hi, $obv->hi);
    $obv->fill (0, $obv->hi);
    is_deeply ($obv->values_array, [ 4, 16, 29, 15, 0 ]);
  }
}

{
  my $timebase_days = App::Chart::Timebase::Days->new_from_iso ('1970-01-05');
  my $parent = MyOHLCVI->new
    (timebase => $timebase_days,
     hi => 3,
     arrays => { closes  => [ undef, undef, undef, undef ],
                 volumes => [ 11, 12, 13, 14 ] },
     array_aliases => { values => 'closes' },
     name => 'Foo',
    );

  my $obv = $parent->OBV;
  $obv->fill (0, $obv->hi);
  is_deeply ($obv->values_array, [ undef, undef, undef, undef ]);
}


exit 0;
