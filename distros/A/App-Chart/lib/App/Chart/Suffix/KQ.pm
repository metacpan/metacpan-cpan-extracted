# KOSDAQ setups.

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

package App::Chart::Suffix::KQ;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;
use App::Chart::Suffix::KS;


my $pred = App::Chart::Sympred::Suffix->new ('.KQ');
$App::Chart::Suffix::KS::timezone_seoul ->setup_for_symbol ($pred);


#------------------------------------------------------------------------------
# weblink - company info
#
# Full link is
#     http://english.kosdaq.com/enterprise/center/center.jsp?code=052300&codeInFocus=052300&selFocus=enterprise%2Fcenter%2Fcenter.jsp&x=0&y=0
#
# but it's enough to give
#     http://english.kosdaq.com/enterprise/center/center.jsp?code=052300
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('KOSDAQ _Company Information'),
   desc => __('Open web browser at the KOSDAQ Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (ko => 'www',
                                                              en => 'english');
     return
       "http://$lang.kosdaq.com/enterprise/center/center.jsp?code=$symbol";
   });

1;
__END__
