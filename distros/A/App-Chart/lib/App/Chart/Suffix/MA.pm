# Madrid Stock Exchange setups.

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

package App::Chart::Suffix::MA;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


our $timezone_madrid = App::Chart::TZ->new
  (name     => __('Madrid'),
   choose   => [ 'Europe/Madrid' ],
   fallback => 'CET-1');

# Indexes:
#   ^SMSI
# and not ^SML - S&P small 600
#
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^SMS');

# .MA  main
# .MC  CATS
# .MF  fixed interest
my $pred_shares = App::Chart::Sympred::Regexp->new (qr/\.M[ACF]$/);

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_madrid->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Madrid Stock Exchange Home Page'),
   desc => __('Open web browser at the Madrid Stock Exchange home page'),
   url  => 'http://www.bolsamadrid.es');

1;
__END__
