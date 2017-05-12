# Swiss Stock Exchange (SWX) setups.

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

package App::Chart::Suffix::SW;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::Yahoo;


our $timezone_switzerland = App::Chart::TZ->new
  (name     => __('Switzerland'),
   choose   => [ 'Europe/Zurich' ],
   fallback => 'CET-1');

# http://au.finance.yahoo.com/intlindices
# ^SSMI - SMI
# and note not hitting ^SSEC (in SS.pm)
#
my $pred = App::Chart::Sympred::Regexp->new (qr/^\^SSM|\.SW$/);

$timezone_switzerland->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...
#
# swx.com company info pages are based on ISIN codes, not the symbol, would
# need to extract that to do web links (if haven't already got it in the
# database info)
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_SWX Home Page'),
   desc => __('Open web browser at the Swiss Stock Exchange home page'),
   url  => 'http://www.swx.com');


1;
__END__
