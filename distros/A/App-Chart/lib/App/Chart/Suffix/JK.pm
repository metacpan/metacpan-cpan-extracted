# Jakarta Stock Exchange setups.

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

package App::Chart::Suffix::JK;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

my $timezone_jakarta = App::Chart::TZ->new
  (name     => __('Jakarta'),
   choose   => [ 'Asia/Jakarta' ],
   fallback => 'WIT-7');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.JK');

# ^JKSE composite
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^JK');

my $pred_any = App::Chart::Sympred::Any->new ($pred_shares, $pred_indexes);
$timezone_jakarta->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Jakarta Stock Exchange Home Page'),
   desc => __('Open web browser at the Jakarta Stock Exchange home page'),
   url  => 'http://www.jsx.co.id');


1;
__END__
