# Singapore Stock Exchange setups.

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

package App::Chart::Suffix::SI;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

our $timezone_singapore = App::Chart::TZ->new
  (name     => __('Singapore'),
   choose   => [ 'Asia/Singapore' ],
   fallback => 'SGT-8');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.SI');

# ^STI straits times
# and not ^STOXX
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^STI');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_singapore->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only home page for now
#

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('SGX _Home Page'),
   desc => __('Open web browser at the Singapore Stock Exchange home page'),
   url  => 'http://www.sgx.com');

1;
__END__
