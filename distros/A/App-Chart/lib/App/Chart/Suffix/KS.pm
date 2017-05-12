# Korea Stock Exchange setups.

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

package App::Chart::Suffix::KS;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


our $timezone_seoul = App::Chart::TZ->new
  (name     => __('Seoul'),
   choose   => [ 'Asia/Seoul' ],
   fallback => 'KST-9');

# Indexes:
#   ^KS11
#
# and avoid clash with ^KSE in karachi.pm
#
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^KS1');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.KS');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_seoul->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...
#
# Only the home page for now.  The symbol lookup at the web site doesn't
# seem to work as of March 2007.

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Korea Stock Exchange Home Page'),
   desc => __('Open web browser at the Korea Stock Exchange home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   (ko => 'http://www.kse.or.kr/index.html',
    en => 'http://eng.krx.co.kr/index.html'));


1;
__END__
