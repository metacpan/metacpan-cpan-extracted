# make test
# perl Makefile.PL; make; perl -Iblib/lib t/20_range_globr.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 7+8;

ok_ref([range(11)],     [0,1,2,3,4,5,6,7,8,9,10], 'range(11)' );
ok_ref([range(2,11)],   [2,3,4,5,6,7,8,9,10],     'range(2,11)' );
ok_ref([range(11,2,-1)],[11,10,9,8,7,6,5,4,3],    'range(11,2,-1)' );
ok_ref([range(2,11,3)], [2,5,8],                  'range(2,11,3)' );
ok_ref([range(11,2,-3)],[11,8,5],                 'range(11,2,-3)' );
ok_ref([range(2,11,1,0.1)],      [2, 3, 4.1, 5.3,  6.6,  8,   9.5       ],'range(2,11,1,0.1)');
ok_ref([range(2,11,1,0.1,-0.01)],[2, 3, 4.1, 5.29, 6.56, 7.9, 9.3, 10.75],'range(2,11,1,0.1,-0.01)');


sub check_globr { my$g;ok( ($g=join(" ",@{shift()})) eq join(" ",@{shift()}),    'globr - '.$g ) }
check_globr( [globr("X{a,b,c}Y")], [qw/XaY XbY XcY/] );
check_globr( [globr("X{a,b,c}Y")],
  	     [glob("X{a,b,c}Y")] );
check_globr( [globr("X{a..c}Y")],
	     [glob("X{a,b,c}Y")] );
check_globr( [globr("X{a..c..2}Y")],
	     [glob("X{a,c}Y")] );
check_globr( [globr("{01..10..2}")], [qw/01 03 05 07 09/] );
check_globr( [globr "{1..10}" ], [1..10] );
check_globr( [globr "{01..03..1}{00..99..5}" ], [grep/[05]$/,"0100".."0399"] );
check_globr( [globr "XY{a..d..2}Z" ],[qw/XYaZ XYcZ/] );
#print join(" ",globr("X{01..10..2}Y"))."\n";
#print join(" ",globr("X{01..10..1}Y"))."\n";
#print join(" ",globr "X{01..10..1}Y")."\n";
#print join(" ",globr "*")."\n";
#print join(" ", globr "X{aa..bz..13}Z")."\n"; #XaaZ XanZ XbaZ XbnZ

