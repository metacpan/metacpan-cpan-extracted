# Tokyo Commodities Exchange (TOCOM) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Suffix::TOCOM;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $pred = App::Chart::Sympred::Suffix->new ('.TOCOM');
App::Chart::TZ->tokyo->setup_for_symbol ($pred);

# (source-help! tocom-symbol?
# 	      (__p('manual-node','Tokyo Commodities Exchange')))


#-----------------------------------------------------------------------------
# weblinks - contract specs
#
# eg. http://www.tocom.or.jp/guide/youkou/gold/index.html
#     http://www.tocom.or.jp/jp/guide/youkou/crude_oil/index.html
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('TOCOM _Contract Specifications'),
   desc => __('Open web browser at the Tokyo Commodities Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     my $code = lc($commodity);
     $code =~ s/ /_/g;
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (en => '',
                                                  ja => 'jp/');
     return "http://www.tocom.or.jp/${lang}guide/youkou/$code/index.html";
   });

1;
__END__
