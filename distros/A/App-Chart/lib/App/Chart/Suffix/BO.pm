# Bombay Stock Exchange (BSE) setups.

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

package App::Chart::Suffix::BO;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_bombay = App::Chart::TZ->new
  (name     => __('Bombay'),
   # or calcutta as no separate entry for Bombay in the Olson database
   choose   => [ 'Asia/Bombay', 'Asia/Calcutta', 'Asia/Kolkata' ],
   fallback => 'IST-5:30');

# ^BSESN bse sensitive
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^BSE');
my $pred_shares = App::Chart::Sympred::Suffix->new ('.BO');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_bombay->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - BSE company info
#
# Eg. http://www.bseindia.com/qresann/comp_info.asp?scrip_cd=532401
#

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('BSE _Company Information'),
   desc => __('Open web browser at the Bombay Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     # there's links on this page to results, announcements, quote, etc
     return 'http://www.bseindia.com/qresann/comp_info.asp?scrip_cd='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });

1;
__END__
