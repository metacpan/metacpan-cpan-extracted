# Hong Kong Stock Exchange (HKEX) setups.

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

package App::Chart::Suffix::HK;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

my $timezone_hongkong = App::Chart::TZ->new
  (name     => __('Hong Kong'),
   choose   => [ 'Asia/Hong_Kong' ],
   fallback => 'HKT-8');

my $pred_shares = App::Chart::Sympred::Suffix->new ('.HK');

# ^HSI hang seng index
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^H');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_hongkong->setup_for_symbol ($pred_any);


#------------------------------------------------------------------------------
# weblink - company info
#

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('HKEX _Company Information'),
   desc => __('Open web browser at the Hong Kong Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     # extra "0" in the ID for the web page over what Yahoo uses
     return 'http://www.hkex.com.hk/invest/index.asp?id=company/profile_page_e.asp?WidCoID=0'
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol))
         . '&WidCoAbbName=&Month=&langcode=e';
   });

1;
__END__
