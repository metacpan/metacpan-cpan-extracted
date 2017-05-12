
use strict;
use Test::More tests => 15;
use Test::Exception;

#Test 1
use_ok('Business::DK::CPR', qw(validate validateCPR));

#Test 2
ok(validate(1501721111), 'Ok, generated');

#Test 2
ok(validateCPR(1501721111), 'Ok, generated');

#Test 3
dies_ok {validate()} 'no arguments';

#Test 4
dies_ok {validate(123456789)} 'too short, 9';

#Test 5
dies_ok {validate(12345678901)} 'too long, 11';

#Test 6
dies_ok {validate('abcdefg1')} 'unclean';

#Test 7
dies_ok {validate(0)} 'zero';

#Test 8-14
my $birthday = '150172';

my $i = 0;
while ($i < 7) {
    my $cpr = $birthday . sprintf('%04d', $i);
    ok(! validate($cpr), "invalid CPR: $cpr");
    $i++;
}

