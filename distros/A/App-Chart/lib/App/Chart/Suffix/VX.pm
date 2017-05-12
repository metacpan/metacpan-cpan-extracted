# Virt-X exchange setups.

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

package App::Chart::Suffix::VX;

use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::Suffix::SW;
use App::Chart::Yahoo;

my $pred = App::Chart::Sympred::Suffix->new ('.VX');
$App::Chart::Suffix::SW::timezone_switzerland->setup_for_symbol ($pred);

# .VX not listed in http://finance.yahoo.com/exchanges as of July 2008,
# guess same as .SW
App::Chart::Yahoo::setup_quote_delay_alias ($pred, '.SW');


#------------------------------------------------------------------------------
# weblink - only the home page for now ...
#
# virt-x.com company info pages are based on ISIN codes, not the symbol,
# would need to extract that to do web links (if haven't already got it in
# the database info)
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_Virt-X Home Page'),
   desc => __('Open web browser at the Virt-X Stock Exchange home page'),
   url  => 'http://www.virt-x.com/index.html');


1;
__END__
