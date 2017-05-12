# National Stock Exchange of India (NSE) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2014 Kevin Ryde

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

package App::Chart::Suffix::NS;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_mumbai = App::Chart::TZ->new
  (name     => __('Mumbai'),
   # or calcutta as no separate entry for Mumbai in the Olson database
   choose   => [ 'Asia/Bombay', 'Asia/Calcutta', 'Asia/Kolkata' ],
   fallback => 'IST-5:30');

my $pred = App::Chart::Sympred::Suffix->new ('.NS');
$timezone_mumbai->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - NSE company info
#
# Eg., and normally shown in a frame,
#
# http://www.nseindia.com/marketinfo/companyinfo/eod/address.jsp?symbol=SESAGOA

App::Chart::Weblink->new
  (pred => $pred,
   name => __('NSE _Company Information'),
   desc => __('Open web browser at the National Stock Exchange of India page for this company'),
   proc => sub {
     my ($symbol) = @_;
     # there's links on this page to other info, including a current quote
     return 'http://www.nseindia.com/marketinfo/companyinfo/eod/address.jsp?symbol='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });

1;
__END__
