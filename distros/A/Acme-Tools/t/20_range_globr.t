# make test
# perl Makefile.PL; make; perl -Iblib/lib t/20_range_globr.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 7+15;

ok_ref([range(11)],     [0,1,2,3,4,5,6,7,8,9,10], 'range(11)' );
ok_ref([range(2,11)],   [2,3,4,5,6,7,8,9,10],     'range(2,11)' );
ok_ref([range(11,2,-1)],[11,10,9,8,7,6,5,4,3],    'range(11,2,-1)' );
ok_ref([range(2,11,3)], [2,5,8],                  'range(2,11,3)' );
ok_ref([range(11,2,-3)],[11,8,5],                 'range(11,2,-3)' );
ok_ref([range(2,11,1,0.1)],      [2, 3, 4.1, 5.3,  6.6,  8,   9.5       ],'range(2,11,1,0.1)');
ok_ref([range(2,11,1,0.1,-0.01)],[2, 3, 4.1, 5.29, 6.56, 7.9, 9.3, 10.75],'range(2,11,1,0.1,-0.01)');

sub ok_globr {
  my($g,$e,$c)=@_;
  my @g=globr($g);
  $g=join" ",@g;
  $e=join" ",@$e;
  my $ok=$g eq $e && !defined$c || $c==@g;
  ok( $ok, "globr $_[0]  -->  $e" );
  print "got:      $g\n" and
  print "expected: $e\n" if not $ok;
}
ok_globr( "X{a,b,c}Y",              [qw/XaY XbY XcY/] );
ok_globr( "X{a,b,c}Y",              [glob("X{a,b,c}Y")] );
ok_globr( "X{a..c}Y",               [glob("X{a,b,c}Y")] );
ok_globr( "X{a..c..2}Y",            [glob("X{a,c}Y")] );
ok_globr( "{01..10}",               [qw/01 02 03 04 05 06 07 08 09 10/] );
ok_globr( "{01..10..2}",            [qw/01 03 05 07 09/] );
ok_globr( "{1..10}",                [1..10] );
ok_globr( "{01..03..1}{00..99..5}", [grep/[05]$/,"0100".."0399"], 300/5 );
ok_globr( "XY{a..d..2}Z",           [qw/XYaZ XYcZ/] );
ok_globr( "X{aa..bz..13}Z",         [qw/XaaZ XanZ XbaZ XbnZ/] );
ok_globr( "X{bz..aa..13}Z",         [qw/XbzZ XbmZ XazZ XamZ/] );
ok_globr( "X{10..02..3}.",          [glob "X{10,07,04}."] );
ok_globr( "X{10..02..-3}.",         [glob "X{10,07,04}."] );
ok_globr( "X{-10..-6}.",            [glob "X{-10,-9,-8,-7,-6}."] );
ok_globr( "X{-10..-6..2}.",         [glob "X{-10,-8,-6}."] );
#ok_globr( "X{-10..-06}.",          [glob "X{-10,-07}."] ); #not ok yet

#deglob... #basisdatarapport-poengekv

#print join(" ",globr "*")."\n"; #hm
