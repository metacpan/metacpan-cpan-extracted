# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Aviation::Report;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

   my $DEBUG = 0;

   my @in = (
   "METAR KIAD 081055Z AUTO COR 21019G27KT 1/2SM R04R/3000FT -SN FG SCT011 OVC015 01/M02 A2945 RMK AO2 TSB25 PK WND 19029/16 SLP045 T00081016=",
   "METAR KSBP 231447Z 00000KT 25SM CAVOK SKC 05/04 A3027=",
   "METAR KPIT 211151Z 25009KT 1 1/2SM -SN FEW021 BKN027 OVC035 M12/M15 A3014 RMK AO2 SLP236 8/546 P0000 60000 T11171150 11106 21131 51016=",
   "SPECI KPIT 211151Z 25009KT 1 1/2SM -SN FEW021 BKN027 OVC035 M12/M15 A3014 RMK AO2 SLP236 8/546 P0000 60000 T11171150 11106 21131 51016 FC=", 
   "SPECI KPIT 211151Z 25009KT 1 1/2SM -SN FEW021 BKN027 OVC035 M12/M15 A3014 RMK VIRGA SW LTGIC TS=",
   "METAR KPIT 091730Z 15005KT P5SM HZ FEW020 WS010/31022KT FM1930 30015G25KT 3SM SHRA OVC015 TEMPO 2022 1/2SM +TRSA OVC008CBVV200 FM0100 27008KT 5SM SHRA BKN020 OVC040 PROB40 0407 1SM -RA BR FM1015 18005KT 6SM -SHRA OVC020 BECMG 1315 P6SM NSW SKC=", 
   "ZCZC SFOTAFPRB\
TTAA00 KLAX 062300\
TAF\
KPRB 062325Z 070024 24012G20KT P6SM BKN180\
     FM0200 32010G20KT P6SM SKC\
     FM0500 VRB03KT P6SM SKC\
     FM2000 32010KT P6SM SKC=");

   my $i=2;

   foreach (@in) {
      my $out='';
      if ($out = decode_METAR_TAF($_, 0)) {
         print "ok";
      }
      else {
         print "not ok";
      }
      print ' ', $i++, "\n";
      print $out if $DEBUG;
   }
__END__
