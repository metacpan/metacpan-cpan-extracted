#!/usr/bin/perl -w
# object tests
use Test::More skip_all => 'tests require db';
#use Test::More tests => 27;

use lib qw/t/;
use strict;
use Address;

my @attribute_names = qw/StreetNumber StreetAddress Town City County/;
my @lc_attribute_names = map(lc,@attribute_names);

# get address object (tests 1..1)
my $address = Address->create({StreetNumber => 108,
                               StreetAddress => ['Rose Court','Cross St'],
                               Town=>'Berkhamsted',
                               County=>'Hertfordshire'});
isa_ok( $address, 'Address', 'get Address object');

# String attributes (tests 2..10)
is($address->StreetNumber,108,'get string');
is($address->streetnumber,108,'get string');
is($address->get_StreetNumber,108,'get string');
is($address->get_streetnumber,108,'get string (lowercase)');
ok(breakme('$address->get_StreetNumber(109)'), 'attempt to set string using ro method');
ok($address->set_StreetNumber(109), 'set using wo method');
is($address->get_StreetNumber,109,'get string');
ok($address->StreetNumber(110), 'set string using rw method');
is($address->get_StreetNumber,110,'get string again');

warn "\ntests 2..10 done\n";

# Array Attributes (tests 11..19)
warn "foo\n";
ok(eq_array([$address->StreetAddress],['Rose Court','Cross St'],'set array'));
is($address->get_StreetAddress('0'),'Rose Court','set array part 1');
is($address->get_StreetAddress(1),'Cross St','set array apart 2');
ok($address->push_StreetAddress('Another Road'),'push into array');
is($address->get_StreetAddress(2),'Another Road','get array part 3');
ok($address->insert_StreetAddress(1,'Yet Another Road'),'insert into array');
warn "foo\n";
ok(eq_array([$address->StreetAddress],['Rose Court','Yet Another Road','Cross St','Another Road'],'amended array'));
ok($address->delete_StreetAddress(1),'delete part 1 of array');
warn "foo\n";
ok(eq_array([$address->StreetAddress],['Rose Court','Cross St','Another Road'],'amended array post delete'));


warn "\ntests 11..19 done\n";

# Array Attributes (tests 20..23)
ok($address->Dictionary(foo=>'bar'),'set dictionary using rw method');
ok(eq_hash({$address->Dictionary},{foo=>'bar'}), 'Dictionary');
is($address->Dictionary('foo'),'bar','dictionary entry at index foo');
ok($address->Dictionary_contains('foo'),'dictionary contains');
ok($address->insert_Dictionary(ub=>'40',p=>'45'),'insert into dictionary');
ok(eq_array([sort($address->Dictionary_keys)],[sort(qw/foo ub p/)]), 'dictionary keys');
ok(eq_array([sort($address->Dictionary_values)],[sort(qw/40 45 bar/)]), 'dictionary values');

warn "\ntests 20..26 done\n";

# Object persistance (tests 27..27)
ok($address->update);

# breakme - returns failure of provided code
# called as breakme(qq{code here gets eval'd});
# returns 1 if code breaks succsefully, 0 if code fails to break
sub breakme {
    eval shift; # Do you expect me to talk? No, Mr Bond I expect you to die!
    warn "Bond has escaped! and he's taken the girl!" unless ($@);
    return $@;
}
