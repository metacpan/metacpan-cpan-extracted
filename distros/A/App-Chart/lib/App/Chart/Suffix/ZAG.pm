# Zagreb Stock Exchange (ZSE) setups.     -*- coding: utf-8 -*-

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

package App::Chart::Suffix::ZAG;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_zagreb = App::Chart::TZ->new
  (name     => __('Zagreb'),
   choose   => [ 'Europe/Zagreb' ],
   fallback => 'CET-1');

my $pred = App::Chart::Sympred::Suffix->new ('.ZAG');
$timezone_zagreb->setup_for_symbol ($pred);

# App::Chart::setup_source_help
#   ($pred, __p('manual-node','Zagreb Stock Exchange'));


#------------------------------------------------------------------------------
# weblink - company info
#
# eg. in Croatian and English,
# http://www.zse.hr/security.php?ticker=DLKV-M-704A&languageId=HR
# http://www.zse.hr/security.php?ticker=DLKV-M-704A&languageId=EN

App::Chart::Weblink->new
  (pred => $pred,
   name => __('ZSE _Company Information'),
   desc => __('Open web browser at the Zagreb Stock Exchange information page for this company'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = URI::Escape::uri_escape(App::Chart::symbol_sans_suffix($symbol));
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (hr => 'HR',
                                                  en => 'EN');
     return "http://www.zse.hr/security.php?ticker=$symbol&languageId=$lang";
   });



1;
__END__
