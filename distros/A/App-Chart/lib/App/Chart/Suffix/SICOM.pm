# Singapore Commodities Exchange (SICOM) setups.

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

package App::Chart::Suffix::SICOM;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $pred = App::Chart::Sympred::Suffix->new ('.SICOM');
App::Chart::TZ->tokyo->setup_for_symbol ($pred);

# (source-help! sicom-symbol?
# 	      __p('manual-node','Singapore Commodities Exchange'))


#------------------------------------------------------------------------------
# weblink - contract specifications
#
# These links are as per the home page and they open in a frame.  The
# individual pages are http://www.sicom.com.sg/robusta.htm etc.

my %specs = ('RS' => 'http://www.sicom.com.sg/index_sub.asp?content=rss1',
             'RT' => 'http://www.sicom.com.sg/index_sub.asp?content=rss3',
             'TF' => 'http://www.sicom.com.sg/index_sub.asp?content=tsr20',
             'RI' => 'http://www.sicom.com.sg/index_sub.asp?content=rss3index',
             'CF' => 'http://www.sicom.com.sg/index_sub.asp?content=robusta');

App::Chart::Weblink->new
  (pred => $pred,
   name => __("SICOM _Contract Specifications"),
   desc => __("Open web browser at the Singapore Commodities Exchange contract specifications for this commodity"),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     return $specs{$commodity};
   });

1;
__END__
