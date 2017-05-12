#perl Makefile.PL;make;perl -Iblib/lib t/05_distance.t
BEGIN{require 't/common.pl'}
use Test::More tests => 4;

#--oslo-rio = 10434.047 meter iflg http://www.daftlogic.com/projects-google-maps-distance-calculator.htm
my @oslo=(59.933983, 10.756037);
my @rio=(-22.97673,-43.19508);
my @london=(51.507726,-0.128079);   #1156
my @jakarta=(-6.175381,106.828176); # 10936
my @test=( ['@oslo,@rio',     10431.5],
           ['@rio, @oslo',    10431.5],
           ['@oslo,@london',   1153.6],
           ['@oslo,@jakarta', 10936.0] );
my $d; ok( between( ($d=distance(eval$$_[0])/1000)/$$_[1], 0.999, 1.001 ), "distance $$_[0], $$_[1] and $d" ) for @test;

#eval{require Geo::Direction::Distance};
#if($@ or $Geo::Direction::Distance::VERSION ne '0.0.2'){ok(1)}
#else{
#  my($aps1,$aps2,$t);
#  $t=time_fp(); distance(@oslo,@rio) for 1..100000; deb "ant pr sek = ".($aps1=100000/(time_fp()-$t))."\n";
#  $t=time_fp(); Geo::Direction::Distance::latlng2dirdist(@oslo,@rio) for 1..10000; deb "ant pr sek = ".($aps2=10000/(time_fp()-$t))."\n";
#  deb "times faster=".($aps1/$aps2)."\n";
#
#  my $d=(Geo::Direction::Distance::latlng2dirdist(@oslo,@rio))[1]/1000;
#  deb "distance=$d km  time=".(time_fp()-$t)."\n";
#  ok(between($d, 10407.748, 10407.749));
#}
