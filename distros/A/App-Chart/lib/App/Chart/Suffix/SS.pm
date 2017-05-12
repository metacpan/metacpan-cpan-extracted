# Shanghai Stock Exchange setups.

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

package App::Chart::Suffix::SS;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $timezone_shanghai = App::Chart::TZ->new
  (name     => __('Shanghai'),
   choose   => [ 'Asia/Shanghai' ],
   fallback => 'CST-8');

# http://au.finance.yahoo.com/intlindices
# ^SSEC shanghai composite
#
# except it doesn't work with the quotes.csv, it redirects to 000001.SS by
# some magic, so the latter should be used apparently
#
# and note not hitting ^SSMI (in SW.pm)
#
my $pred_indexes = App::Chart::Sympred::Prefix->new ('^SSE');
my $pred_shares = App::Chart::Sympred::Suffix->new ('.SS');

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_shanghai->setup_for_symbol ($pred_any);

# http://www.sse.com.cn/sseportal/en_us/ps/about/tcs.shtml
# 9:15 to 9:25 pricing, 9:30-11:30 and 13:00-15:00 trading
#
# (yahoo-quote-lock! $pred_shares
# 		   #,(hms->seconds 9 15 0) #,(hms->seconds 15 0 0))


#-----------------------------------------------------------------------------
# web links - indices

# not sure about this, but think all indices begin with 0
my $index_pred = App::Chart::Sympred::Regexp->new (qr/^0.*\.SS$/);

App::Chart::Weblink->new
  (pred => $index_pred,
   name => __('SSE _Index Information'),
   desc => __('Open web browser at the Shanghai Stock Exchange page for this index'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     return "http://www.sse.com.cn/sseportal/en_us/ps/ggxx/zsjbxx.jsp?indexName=&indexCode=$symbol";
   });

1;
__END__
