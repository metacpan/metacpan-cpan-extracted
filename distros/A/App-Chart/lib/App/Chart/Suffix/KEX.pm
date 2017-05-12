# Kansai Commodities Exchange (KEX) setups.     -*- coding: shift_jis -*-

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2012 Kevin Ryde

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

package App::Chart::Suffix::KEX;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::IntradayHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $pred = App::Chart::Sympred::Suffix->new ('.KEX');
App::Chart::TZ->tokyo->setup_for_symbol ($pred);

# (source-help! kex-symbol?
# 	      __p('manual-node','Kansai Commodities Exchange'))

#------------------------------------------------------------------------------
# weblink - contract specifications
#

# the english pages might be slightly old, but hopefully still accurate
my %specs = ('EBI' # frozen shrimp
             => [ 'http://kanex.or.jp/yoko/yoko_ebi.html',
                  'http://kanex.or.jp/english/youkou-ebi-eng.htm' ],
             'CF'  # coffee
             => [ 'http://kanex.or.jp/yoko/yoko_coffee.html',
                  'http://kanex.or.jp/english/youkou-cafe-eng.htm' ],
             'KI'  # corn75 index
             => [ 'http://kanex.or.jp/yoko/yoko_corn_index.html',
                  'http://kanex.or.jp/english/youkou-corn-eng.htm' ],
             'CO'  # yellow corn
             => [ 'http://kanex.or.jp/yoko/yoko_corn75.html',
                  undef ],
             'RB'  # azuki beans
             => [ 'http://kanex.or.jp/yoko/yoko_azuki.html',
                  'http://kanex.or.jp/english/youkou-azuki-eng.htm' ],
             'SG'  # sugar
             => [ 'http://kanex.or.jp/yoko/yoko_sugar.html',
                  'http://kanex.or.jp/english/youkou-sugar-eng.htm' ],
             'SM'  # soybean meal # gone as of Jul07
             => [ 'http://kanex.or.jp/yoko/yoko_smeal.html',
                  undef ],
             'BR'  # broiler
             => [ 'http://kanex.or.jp/yoko/yoko_broiler.html',
                  undef ],
             'N' # non-gm soybeans
             => [ 'http://kanex.or.jp/yoko/yoko_daizu.html',
                  'http://kanex.or.jp/english/youkou-non-eng.htm' ],
             # 'RS'  # raw silk
             #   #f
             #   undef
            );

App::Chart::Weblink->new
  (pred => $pred,
   name => __("KEX _Contract Specifications"),
   desc => __("Open web browser at the Kansai Commodities Exchange contract specifications for this commodity"),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     my $elem = $specs{$commodity} || return undef;

     # selected en/ja language, but fallback to ja if the english is undef
     my $url = App::Chart::Glib::Ex::MoreUtils::lang_select (ja => $elem->[0],
                                                 en => $elem->[1])
       || $elem->[0];
     return $url;
   });


#-----------------------------------------------------------------------------
# intraday
#
# Daily data chart images are on the page
#
#     http://kanex.or.jp/market/chart.html
# translated:
#     http://translate.google.com/translate?u=http://kanex.or.jp/market/chart.html
#
# which results in images like
#
#     http://kanex.or.jp/market/img/ebi_saki.jpg
#
# or for a particular month YYMM
#
#     http://kanex.or.jp/market/img/cof_0705.jpg
#
# The commodity code parts are hard coded here, they're not quite the same
# as the download filenames.
#
# Not sure how much value there is in showing what's already available from
# the main chart graphs.


my %intraday_conv = ('EBI'=> 'ebi',  # shimp
                     'N'  => 'non',  # non-gmo soy
                     'RB' => 'rbn',  # azuki
                     'CF' => 'cof',  # coffee index
                     'KI' => 'c75',  # corn75
                     'SG' => 'sug'); # raw sugar
my $intraday_pred = App::Chart::Sympred::Proc->new
  (sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     return exists $intraday_conv{$commodity};
   });

App::Chart::IntradayHandler->new
  (pred => $intraday_pred,
   proc => \&intraday_url,
   mode => 'daily',
   name => __('_Daily'));

sub intraday_url {
  my ($self, $symbol, $mode) = @_;
  my $commodity = App::Chart::symbol_commodity ($symbol);
  App::Chart::Download::status (__x('KEX intraday {commodity}',
                                   commodity => $commodity));
  my $code = $intraday_conv{$commodity} || return;
  my ($year, $month); # = App::Chart::symbol_ymd ($symbol);
  if (defined $year) {
    return sprintf 'http://kanex.or.jp/market/img/%s_%02d%02d.jpg',
      $month, $year % 100;
  } else {
    return "http://kanex.or.jp/market/img/${code}_saki.jpg";
  }
}

1;
__END__
