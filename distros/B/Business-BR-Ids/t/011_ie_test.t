
use Test::More tests => 46;
#use Test::More no_plan => 1;
BEGIN { use_ok('Business::BR::IE', 'test_ie') };

ok(test_ie('ac', '01.004.823/001-12'), '"01.004.823/001-12" is a correct IE/AC');

ok(!test_ie('ac', '01.004.823/001-02'), '"01.004.823/001-02" is an incorrect IE/AC');
ok(!test_ie('ac', '01.004.823/001-13'), '"01.004.823/001-13" is an incorrect IE/AC');

ok(test_ie('al', '24.000.004-8'), '"24.000.004-8" is a correct IE/AL');

ok(!test_ie('ap', '00.000.000-0'), '"00.000.000-0" is an incorrect IE/AP'); # does not begin with '03'
ok(test_ie('ap', '03.012.345-9'), '"03.012.345-9" is a correct IE/AP'); # 1st class, 03.000.001-x up to 03.017.000-x

for (qw(
 030210852
 030235103
 030172588
 030010751
 030110543
 030231159
 030221013
 030218373
 030184403
)) {
  ok(test_ie('ap', $_), "\"$_\" is a correct IE/AP");
}

# 1st class, 03.000.001-x up to 03.017.000-x
# 2nd class, 03.017.001-x up to 03.019.022-x
# 3rd class, from 03.019.023-x and on

ok(test_ie('am', '11.111.111-0'), '"11.111.111-0" is a correct IE/AM');

ok( test_ie('ba', '123456-63'), '"123456-63" is a correct IE/BA' );
ok( test_ie('ba', '612345-57'), '"612345-57" is a correct IE/BA' );

ok(test_ie('ma', '12.000.038-5'), '"12.000.038-5" is a correct IE/MA');

ok( test_ie('mg', '062.307.904/0081'), q{'062.307.904/0081' is a correct IE/MG} );

ok(test_ie('ro', '0000000062521-3'), '"0000000062521-3" is a correct IE/RO');
ok(test_ie('ro', '42360936787181'), '"42360936787181" is a correct IE/RO');
ok(!test_ie('ro', '72684661768256'), '"0000000062521-3" is an incorrect IE/RO');

ok(test_ie('rr', '24006628-1'), '"24006628-1" is a correct IE/RR');
ok(test_ie('rr', '24001755-6'), '"24001755-6" is a correct IE/RR');
ok(test_ie('rr', '24003429-0'), '"24003429-0" is a correct IE/RR');
ok(test_ie('rr', '24001360-3'), '"24001360-3" is a correct IE/RR');
ok(test_ie('rr', '24008266-8'), '"24008266-8" is a correct IE/RR');
ok(test_ie('rr', '24006153-6'), '"24006153-6" is a correct IE/RR');
ok(test_ie('rr', '24007356-2'), '"24007356-2" is a correct IE/RR');
ok(test_ie('rr', '24005467-4'), '"24005467-4" is a correct IE/RR');
ok(test_ie('rr', '24004145-5'), '"24004145-5" is a correct IE/RR');
ok(test_ie('rr', '24001340-7'), '"24001340-7" is a correct IE/RR');

ok(test_ie('pr', '123.45678-50'), '"123.45678-50" is a correct IE/PR');

ok(test_ie('sp', '110.042.490.114'), '"110.042.490.114" is a correct IE/SP');
ok(test_ie('sp', '645.095.752.110'), '"645.095.752.110" is a correct IE/SP');

ok(!test_ie('sp', '110.042.490.110'), '"110.042.490.110" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.111'), '"110.042.490.111" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.112'), '"110.042.490.112" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.113'), '"110.042.490.113" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.115'), '"110.042.490.115" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.116'), '"110.042.490.116" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.117'), '"110.042.490.117" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.118'), '"110.042.490.118" is an incorrect IE/SP');
ok(!test_ie('sp', '110.042.490.119'), '"110.042.490.119" is an incorrect IE/SP');


