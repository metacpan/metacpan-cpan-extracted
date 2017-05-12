# Copenhagen Stock Exchange setups.

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

package App::Chart::Suffix::CO;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_copenhagen = App::Chart::TZ->new
  (name     => __('Copenhagen'),
   choose   => [ 'Europe/Copenhagen' ],
   fallback => 'CET-1');

# ^KFX index
my $pred_all    = App::Chart::Sympred::Regexp->new (qr/^\^KF|\.CO$/);
my $pred_shares = App::Chart::Sympred::Suffix->new ('.CO');

$timezone_copenhagen->setup_for_symbol ($pred_all);

# http://omxgroup.com/nordicexchange/Abouttrading/tradinginformation/tradinghours/
# Equities from 9:00 or 9:15, bonds from 8:00 or 8:30
# Closing 16:50 or with further call to 17:00, bulletin board to 17:30
#
# (yahoo-quote-lock! copenhagen-symbol?
# 		   #,(hms->seconds 8 0 0) #,(hms->seconds 17 30 0))
# (yahoo-quote-lock! yahoo-index-symbol-copenhagen?
# 		   #,(hms->seconds 8 0 0) #,(hms->seconds 17 0 0))



#------------------------------------------------------------------------------
# weblink - only the home page for now ... and it redirects to OMX Nordic

App::Chart::Weblink->new
  (pred => $pred_all,
   name => __('_Copenhagen Stock Exchange Home Page'),
   desc => __('Open web browser at the Copenhagen Stock Exchange home page'),
   url  => 'http://www.xcse.dk');


1;
__END__
