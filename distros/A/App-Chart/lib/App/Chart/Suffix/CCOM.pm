# Central Japan Commodity Exchange setups. -*- coding: shift_jis -*-

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


package App::Chart::Suffix::CCOM;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


# think GBL bund, GBM bobl and GBS schatz which traded on european time now
# delisted
#
my $pred = App::Chart::Sympred::Suffix->new ('.CCOM');
App::Chart::TZ->tokyo->setup_for_symbol ($pred);

# (source-help! ccom-symbol?
# 	      (__p('manual-node','Central Japan Commodity Exchange'))


#------------------------------------------------------------------------------
# weblink - contract specs
#
# eg. http://www.c-com.or.jp/public_html_e/guide/kerosene.php

my %weblink_mung = ('ferrousscrap' => 'scrap',
                    'rubberindex'  => 'rubberIndex');
my %weblink_ja_mung = ('gasoline' => 'gas',
                       'kerosene' => 'heating',
                       'gasoil'   => 'diesel',
                       'eggs'     => 'egg');
App::Chart::Weblink->new
  (pred => $pred,
   name => __('C-COM _Contract Specifications'),
   desc => __('Open web browser at the Central Japan Commodities Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     my $code = lc(App::Chart::symbol_commodity($symbol));
     $code =~ s/ //g;
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (ja => '',
                                                  en => '_e');
     $code = $weblink_mung{$code} // $code;
     if ($lang eq '') { $code = $weblink_ja_mung{$code} // $code; }
     return "http://www.c-com.or.jp/public_html$lang/guide/$code.php";
   });


1;
__END__
