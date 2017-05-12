# Stock Exchange of Thailand setups.

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

package App::Chart::Suffix::BK;
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


my $timezone_bangkok = App::Chart::TZ->new
  (name     => __('Bangkok'),
   choose   => [ 'Asia/Bangkok' ],
   fallback => 'ICT-7');

# Indexes:
#   ^THDOW
#   ^THDOWD
#   ^DWTH
#   ^DWTHD
#   ^DWTHT
#   ^DWTHTD
# old ^SETI seems gone
#
my $pred_indexes = App::Chart::Sympred::Regexp->new (qr/^\^(DW)?TH/);

# .BK seems gone as of Mar 2007
my $pred_shares = App::Chart::Sympred::Suffix->new ('.BK');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_bangkok->setup_for_symbol ($pred_any);

# @item
# @item @nisamp{.BK} @tab Thailand
# @cindex @code{.BK}
# @cindex Stock Exchange of Thailand
# @cindex SET
# @cindex Thailand
# @tab Stock Exchange of Thailand (SET) @*
# @uref{http://www.set.or.th/en/index.html}

#------------------------------------------------------------------------------
# weblink - only home page for now
#

# only home page for now ...
App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_SET Home Page'),
   desc => __('Open web browser at the Stock Exchange of Thailand home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   ('th' => 'http://www.set.or.th',
    'en' => 'http://www.set.or.th/en/index.html'));

1;
__END__
