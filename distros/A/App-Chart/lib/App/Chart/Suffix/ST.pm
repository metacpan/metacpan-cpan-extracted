# Stockholm Stock Exchange setups.

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

package App::Chart::Suffix::ST;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


our $timezone_stockholm = App::Chart::TZ->new
  (name     => __('Stockholm'),
   choose   => [ 'Europe/Stockholm' ],
   fallback => 'CET-1');

my $pred_shares  = App::Chart::Sympred::Suffix->new ('.ST');
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^OMX');

my $pred_any = App::Chart::Sympred::Any->new ($pred_shares, $pred_indexes);
$timezone_stockholm->setup_for_symbol ($pred_any);


# http://omxgroup.com/nordicexchange/Abouttrading/tradinginformation/tradinghours/
# Equities from 9:00, bulletin board reporting to 18:00
#
# (yahoo-quote-lock! stockholm-symbol?
# 		   #,(hms->seconds 9 0 0) #,(hms->seconds 18 0 0))


1;
__END__
