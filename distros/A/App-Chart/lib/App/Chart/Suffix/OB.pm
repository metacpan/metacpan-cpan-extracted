# US OTC bulletin board setups.

# Copyright 2007, 2008, 2009 Kevin Ryde

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

package App::Chart::Suffix::OB;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;


my $pred = App::Chart::Sympred::Suffix->new ('.OB');
App::Chart::TZ->newyork->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - OTC BB company info

App::Chart::Weblink->new
  (pred => $pred,
   name => __('OTC BB _Company Information'),
   desc => __('Open web browser at the OTC bulletin board page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.otcbb.com/asp/info_center.asp?symbol='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });



1;
__END__
