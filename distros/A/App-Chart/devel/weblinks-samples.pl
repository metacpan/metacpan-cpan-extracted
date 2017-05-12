#!/usr/bin/perl -w

# Copyright 2006, 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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


# Usage: ./weblinks-samples.pl
#
# Check weblink URLs for various symbols.  The URLs are checked by making a
# "HEAD" request, so there's no great amount downloaded, except for a couple
# of data sources which may do extra downloading to find the link
# (eg. .BEN).
#
# Because this program does online interaction it's not run by "make
# check".
#
# Misfeatures:
#
# finance.yahoo.com gives a page with a message for an unknown symbol, so a
# HEAD is not much good there.
#

use strict;
use warnings;
use App::Chart::Weblink;

my %attempted_urls;

print <<'HERE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body>
<p>
HERE

my $errors = '';

sub attempt {
  my @symbol_list = @_;
  my $langs = [ undef ];
  if (ref $symbol_list[0]) {
    $langs = shift @symbol_list;
  }

  foreach my $lang (@$langs) {
    local $ENV{'LANGUAGE'} = $lang;
    foreach my $symbol (@symbol_list) {
      my @weblinks = App::Chart::Weblink->links_for_symbol ($symbol);
      if (! @weblinks) {
        $errors .= "No weblinks for $symbol\n";
        next;
      }
      foreach my $weblink (@weblinks) {

        my $name = $weblink->name;
        my $url = $weblink->url ($symbol);
        if (! defined $url) { next; }

        # finance.yahoo.com gives a page with a message for an unknown
        # symbol, so no point checking it
        if ($url =~ /finance\.yahoo\.com/) { next; }

        if ($attempted_urls{$url}) { next; }
        $attempted_urls{$url} = 1;

        print "<br> <a href=\"$url\">$symbol $name</a>\n";
      }
    }
  }
}

# london
attempt ('TSCO.L', 'BLT.L', 'TPSD.IL');

  # nybot-info
  #   (let ((nybot-specs-list (@@ (chart nybot) nybot-specs-list)))
  #     (for-each (lambda (elem)
  # 		(attempt (string-append (first (car elem)) '.NYBOT')))
  # 	      nybot-specs-list))

  # nybot
attempt ('CC.NYB');

# cbot-info
#   (let ((cbot-specs-list (@@ (chart cbot) cbot-specs-list)))
#     (for-each (lambda (elem)
# 		(attempt (string-append (first (car elem)) '.CBOT')))
# 	      cbot-specs-list))

# hamburg
attempt ('OEL.HM');

# cbot
attempt ('O.CBT');

# casablanca
attempt (['fr','en'], 'MNG.CAS');

# cme
attempt ('SP.CME');

# thailand
attempt ('^THDOW', '^DJTH');

# santiago
attempt (['en','es'], '^CLDOW');

# mgex
attempt ('MW.MGEX', 'IC.MGEX');

# amsterdam
attempt ('^AEX');

# cairo
attempt (['ar','en'], '^CCSI');

# brussels
attempt (['en','fr'], '^BFX');

# vienna
attempt (['de','en'], 'WST.VI', '^ATX');

# colombo
attempt ('^CSE');

# virtx
attempt ('BAER.VX');

# bilbao
attempt (['en','eu','es','fr'], '20.BI');

# karachi
attempt ('^KSE');

# phillipine
attempt ('^PSI');

# prague
attempt (['cs','en'], '^PX50');

# australia
attempt ('NAB.AX','PCAPA.AX','NABHA.AX','AEQCA.AX');

# oslo
attempt (['no','en'], 'PLUS.OL');

# tokyo
attempt (['ja','en'], '^N225');  # Nikkei 225

# korea
attempt (['en','ko'],
         '052300.KQ',  # Digilant FEF (DFEF)
         '003660.KS'); # Korea Cement

# india
attempt ('SESAGOA.NS');  # Sesa Goa

# bombay
attempt ('532401.BO',  # Vijaya Bank
         '^BSESN');    # SENSEX index

# nymex
attempt ('GC.CMX',  # gold
         'CL.NYM',  # crude
         'CLZ11.NYM', # light sweet crude
         'HU.NYM',    # gasoline
         'HO.NYM',    # heating oil
         'NG.NYM',    # henry hub natural gas
         'PA.NYM',    # palladium
         'PL.NYM',    # platinum
         'PN.NYM',    # propane
         'QG.NYM',    # e-miNY henry hub natural gas
         'QL.NYM',    # CAPP central appalacian coal
         'QM.NYM',    # e-miNY light sweet crude
         'BB.NYM'    # brent bullet swap - london
        );

# SandP, all links
# attempt (['es','en','pt'],
#       (for-each (lambda (elem)
# 		  (attempt (car elem)))
# 		(@@ (chart sandp) standard-and-poors-weblink-alist

# shanghai
attempt ('000010.SS');  # SSE 180 index

# M-X
attempt (['en','fr'],
         # indexes
         'SXFZ11.MON',
         'SXA.MON',
         'SXB.MON',
         'SXH.MON',
         'SXY.MON',
         # interest rates
         'BAX.MON',
         'OBX.MON',
         'ONX.MON',
         'CGZ.MON',
         'CGB.MON',
         'OGB.MON');

# ccom
attempt (['ja','en'],
         'Gasoline.CCOM',
         'Kerosene.CCOM',
         'Gas Oil.CCOM',
         'Eggs DEC 06.CCOM',
         'Ferrous Scrap.CCOM',
         'RSS3.CCOM',
         'TSR20.CCOM',
         'Nickel.CCOM',
         'Aluminium.CCOM',
         'Rubber Index.CCOM');


# lme
attempt ('COPPER 3.LME',
         'ALUMINIUM.LME',
         'ALUMINIUM ALLOY.LME',
         'LEAD.LME',
         'LMEX.LME',
         'NASAAC.LME',
         'NICKEL.LME',
         'TIN.LME',
         'ZINC.LME',
         'PP.LME',
         'LL APR 07.LME');

# kex
attempt (['en','ja'],
         'CF.KEX',
         'EBI.KEX',
         'KI JAN 06.KEX',
         'N.KEX',
         'RB.KEX',
         'RS.KEX',
         'SG.KEX',
         'BR.KEX',
         'CO.KEX',
         # 'SM.KEX' # delisted Jul07
        );

# athens
attempt ('HTO.ATH');

# bendigo
# attempt ('BTT.BEN','CAP.BEN');

# barchart comex
attempt ('HG.CMX',     # high grade copper
         'GCZ11.CMX',  # gold
         'SI.CMX',     # silver
         'AL.CMX');    # aluminium

# ljubljana
attempt (['en','sl'], 'DRKR.LJ');

# newzealand
attempt ('TEL.NZ');

# sfe
# attempt ('BB.SFE',
#          'YT MAR 07.SFE');

# sicom
attempt ('CF.SICOM',
         'RS MAY 07.SICOM',
         'RT.SICOM',
         'RI.SICOM',
         'TF AMJ 07.SICOM');

# tge
attempt (['en','ja'],
         'CO.TGE',
         'SM.TGE',
         'SB.TGE',
         'NG.TGE',
         'RB OCT 06.TGE',
         'AC.TGE',
         'RC.TGE',
         'SG.TGE',
         'SL.TGE',
         'VG.TGE');

# tocom
attempt (['en','ja'],
         'Gold.TOCOM',
         'Silver.TOCOM',
         'Platinum.TOCOM',
         'Palladium.TOCOM',
         'Aluminum.TOCOM',
         'Gasoline.TOCOM',
         'Kerosene.TOCOM',
         'Crude Oil.TOCOM',
         'Gas Oil.TOCOM',
         'Rubber Aug 2006.TOCOM');

# wce
attempt ('RS.WCE',
         'WWK06.WCE',
         'AB.WCE',
         # delisted
         'RM.WCE',
         'WF.WCE',
         'WO.WCE',
         'WP.WCE',
         'WQ.WCE');

# wtb
# attempt (['en','de'],
#          'H.WTB',
#          'F.WTB',
#          'P.WTB',
#          'XP.WTB',
#          'LPJ06.WTB',
#          'W.WTB',
#          'BX06.WTB',
#          'POTX.WTB',
#          'TAPX.WTB',
#          'WTBBPC.WTB');

# hongkong
attempt ('0013.HK');

# otcbb
attempt ('CNES.OB',
         'PCLO.OB',
         'USXP.OB');

# pinksheets
attempt ('BOREF.PK',
         'PCMC.PK');

# usa
attempt ('GM',    # NYSE
         'AUY',   # AMEX
         'AAPL'); # Nasdaq

# zagreb
# attempt (['en','hr'],
#          'PLVA-R-A.ZAG');


print "<p> Total ",scalar(keys %attempted_urls)," links\n";
if ($errors ne '') {
  print "<pre>\n$errors</pre>\n";
}
print <<'HERE';
</body>
</html>
HERE

exit 0;
