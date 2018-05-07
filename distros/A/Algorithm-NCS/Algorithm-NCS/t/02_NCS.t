use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Algorithm::NCS;
require_ok('Algorithm::NCS');
subtest 'NCS basic examples' => sub { 
    is( ncs('',''),                    0,      'test NCS source and target empty');
    is( ncs('four',''),                0,      'test NCS four ""');
    is( ncs('','four'),                0,      'test NCS "" four');
    is( ncs('a','x'),                  0,      'test NCS a x');
    is( ncs('aa','x'),                 0,      'test NCS aa x');
    is( ncs('a','xx'),                 0,      'test NCS a xx');
    is( ncs('aa','xx'),                0,      'test NCS aa xx');
    is( ncs('abf','xxsdcd'),           0,      'test NCS abf, xxsdcd');
    is( ncs('aasdcd','xbf34872'),      0,      'test NCS aasdcd, xbf34872');
    is( ncs('a','x'),                  0,      'test NCS a x');
    is( ncs('x','x'),                  1,      'test NCS x x');
    is( ncs('a','xa'),                 1,      'test NCS a xa');
    is( ncs('ax','x'),                 1,      'test NCS ax x');
    is( ncs('xx','x'),                 1,      'test NCS xx x');
    is( ncs('x','xx'),                 1,      'test NCS x xx');
    is( ncs('xx','xx'),                3,      'test NCS xx xx');
    is( ncs(111,11),                   3,      'test NCS numbers');
    is( ncs('abcdxx','xx'),            3,      'test NCS abcdxx, xx');
    is( ncs('abcdxx','xxz'),           3,      'test NCS abcdxx, xxz');
    is( ncs('xx','abcdxx'),            3,      'test NCS xx, abcdxx');
    is( ncs('four','for'),             4,      'test NCS insertion');
    is( ncs('four','four'),           10,      'test NCS matching');
    is( ncs('four','fourth'),         10,      'test NCS deletion');
    is( ncs('four','fuor'),            3,      'test NCS (no) transposition');
    is( ncs('four','fxxr'),            2,      'test NCS substitution');
    is( ncs('four','FOuR'),            1,      'test NCS case');
    is( ncs('EXTRA TETRAHEDRA','TETRAHEDRAL HEADER'), 55,  'test NCS capitals');
    is( ncs('xxx' x 10000,'xxa' x 500),                                         1500,      'test larger source and target');
    is( ncs('ineffective common efforts','self-finance comes ineffective'),       66,      'test NCS documentation');
    is( ncs('mathematical informatics','informatics for mathematics'),            66,      'test NCS documentation');
    is( ncs( 12345356,  34512356 ),12,  'test NCS with digits');
    is( ncs('MONOrkOne','OrkMONOne'), 13, 'trap test');
};



done_testing();
1;


__END__
