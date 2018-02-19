# make test
# perl Makefile.PL; make; perl -Iblib/lib t/35_subarr.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 8;
my @a=qw(e1 e2 e3 e4 e5);

#perl>=5.14
#ok_str( join("+",subarr(@a,1,2)),       'e2+e3' );
#ok_str( join("+",subarr(@a,-2,2)),      'e4+e5' );
#ok_str( join("+",subarr(@a,-2)),        'e4+e5' );
#ok_str( join("+",subarr(@a,-1)),        'e5'    );
#ok_str( join("+",subarr(@a,-100)),      'e1+e2+e3+e4+e5' );
#ok_str( join("+",subarr(@a,1,1000)),    'e2+e3+e4+e5'    );
#ok_str( join("+",subarr(@a,-100,1000)), 'e1+e2+e3+e4+e5' );
#ok_str( join("+",subarr\@a,-100,1000 ), 'e1+e2+e3+e4+e5' );

#perl<5.14
ok_str( join("+",subarr(\@a,1,2)),       'e2+e3' );
ok_str( join("+",subarr(\@a,-2,2)),      'e4+e5' );
ok_str( join("+",subarr(\@a,-2)),        'e4+e5' );
ok_str( join("+",subarr(\@a,-1)),        'e5'    );
ok_str( join("+",subarr(\@a,-100)),      'e1+e2+e3+e4+e5' );
ok_str( join("+",subarr(\@a,1,1000)),    'e2+e3+e4+e5'    );
ok_str( join("+",subarr(\@a,-100,1000)), 'e1+e2+e3+e4+e5' );
ok_str( join("+",subarr(\@a,-100,1000) ), 'e1+e2+e3+e4+e5' );
