
use strict;
use Test::More tests => 16;
use Test::Exception;

#Test 1
use_ok('Business::DK::CPR', qw(validate2007));

#Test 2
ok(validate2007(1501729996), 'Ok');

is(2, validate2007(1501729996), 'Ok');

is(1, validate2007(1501729995), 'Ok');

#Test 3
dies_ok {validate2007()} 'no arguments';

#Test 4
dies_ok {validate2007(123456789)} 'too short, 9';

#and you can ignore the:
#Use of uninitialized value $controlnumber in substr at /Users/jonasbn/develop/svn-CPAN-logicLAB/BDKCPR/lib/Business/DK/CPR.pm line XXX.

#Test 5
dies_ok {validate2007(12345678901)} 'too long, 11';

#Test 6
dies_ok {validate2007('abcdefg1')} 'unclean';

#Test 7
dies_ok {validate2007(0)} 'zero';

#Test 8-14
my $birthday = '150172';

my $i = 0;
while ($i < 7) {
    my $cpr = $birthday . sprintf('%04d', $i);
    ok(! validate2007($cpr), "invalid CPR: $cpr");
    $i++;
}
