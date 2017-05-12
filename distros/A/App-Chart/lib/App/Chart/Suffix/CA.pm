# Cairo and Alexandria Stock Exchange setups.

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

package App::Chart::Suffix::CA;
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


my $timezone_cairo = App::Chart::TZ->new
  (name     => __('Cairo'),
   choose   => [ 'Africa/Cairo' ],
   fallback => 'EET-2');

# ^CASE30
# ^CCSI
# ^DJEG20
# ^DJEG20E
# ^DJEG20D
# ^DJEG20T
# ^DJEG20ET
# ^DJEG20DT
# ^DWEG -- dow/wiltshire egypt
#
my $pred_indexes = App::Chart::Sympred::Regexp->new (qr/^\^(CASE|CC|D[JW]EG)/);

# Eg. CASE30.CA, but perhaps nothing else as of March 2007
my $pred_shares = App::Chart::Sympred::Suffix->new ('.CA');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_cairo->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - only home page for now
#

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_CASE Home Page'),
   desc => __('Open web browser at the Cairo and Alexandria Stock Exchange home page'),
   url  => App::Chart::Glib::Ex::MoreUtils::lang_select
   (ar => 'http://www.egyptse.com',
    en => 'http://www.egyptse.com/index.asp'));

1;
__END__
