# US pink sheets setups.

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

package App::Chart::Suffix::PK;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;


my $pred = App::Chart::Sympred::Suffix->new ('.PK');
App::Chart::TZ->newyork->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - Pink Sheets web site

App::Chart::Weblink->new
  (pred => $pred,
   name => __('Pink Sheets _Company Information'),
   desc => __('Open web browser at the Pink Sheets page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.pinksheets.com/quote/company_profile.jsp?symbol='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });


1;
__END__
