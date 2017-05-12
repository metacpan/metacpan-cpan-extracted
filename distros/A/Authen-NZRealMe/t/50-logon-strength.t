#!perl -T

use Test::More;

use_ok('Authen::NZRealMe');


my $class = Authen::NZRealMe->class_for('logon_strength');
is($class, 'Authen::NZRealMe::LogonStrength');

my $s1 = $class->new;
isa_ok($s1, 'Authen::NZRealMe::LogonStrength');
is($s1->urn, &Authen::NZRealMe::LogonStrength::STRENGTH_LOW);
is($s1->score, 10);

my $s2 = $class->new('low');
isa_ok($s2, 'Authen::NZRealMe::LogonStrength');
is($s2->urn, &Authen::NZRealMe::LogonStrength::STRENGTH_LOW);

eval { $s1->assert_match('low'); };
is($@, '', "'low' matches ('low')");

eval { $s1->assert_match('low', 'exact'); };
is($@, '', "'low' matches ('low', 'exact')");

eval { $s1->assert_match('low', 'minimum'); };
is($@, '', "'low' matches ('low', 'minimum')");

$s2 = $class->new('mod');
is($s2->urn, &Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE);

eval { $s2->assert_match('mod'); };
is($@, '', "'mod' matches ('mod')");

eval { $s2->assert_match('mod', 'exact'); };
is($@, '', "'mod' matches ('mod', 'exact')");

eval { $s2->assert_match('mod', 'minimum'); };
is($@, '', "'mod' matches ('mod', 'minimum')");

eval { $s2->assert_match('low', 'minimum'); };
is($@, '', "'mod' matches ('low', 'minimum')");


$s2 = $class->new('sms');
is($s2->urn, &Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE_SMS);

eval { $s2->assert_match('sms', 'exact'); };
is($@, '', "'sms' matches ('sms', 'exact')");

eval { $s2->assert_match('sms', 'minimum'); };
is($@, '', "'sms' matches ('sms', 'minimum')");

eval { $s2->assert_match('mod', 'minimum'); };
is($@, '', "'sms' matches ('mod', 'minimum')");

eval { $s2->assert_match('low', 'minimum'); };
is($@, '', "'sms' matches ('low', 'minimum')");

eval { $s2->assert_match('mod', 'exact'); };    # <- this is the weird one
is($@, '', "'sms' matches ('mod', 'exact')");


$s2 = $class->new('sid');
is($s2->urn, &Authen::NZRealMe::LogonStrength::STRENGTH_MODERATE_SID);

eval { $s2->assert_match('sid', 'exact'); };
is($@, '', "'sid' matches ('sid', 'exact')");

eval { $s2->assert_match('sid', 'minimum'); };
is($@, '', "'sid' matches ('sid', 'minimum')");

eval { $s2->assert_match('mod', 'minimum'); };
is($@, '', "'sid' matches ('mod', 'minimum')");

eval { $s2->assert_match('low', 'minimum'); };
is($@, '', "'sid' matches ('low', 'minimum')");

eval { $s2->assert_match('mod', 'exact'); };    # <- this is the weird one
is($@, '', "'sid' matches ('mod', 'exact')");


# Now check some that should fail

$@ = '';
eval { $s1->assert_match('mod', 'exact'); };
like("$@", qr/Invalid logon strength/, "'low' fails ('mod', 'exact')");

$@ = '';
eval { $s1->assert_match('sms', 'exact'); };
like("$@", qr/Invalid logon strength/, "'low' fails ('sms', 'exact')");

$@ = '';
eval { $s1->assert_match('sid', 'exact'); };
like("$@", qr/Invalid logon strength/, "'low' fails ('sid', 'exact')");

$s2 = $class->new('sms');

$@ = '';
eval { $s2->assert_match('low', 'exact'); };
like("$@", qr/Invalid logon strength/, "'sms' fails ('low', 'exact')");

$@ = '';
eval { $s2->assert_match('sid', 'exact'); };
like("$@", qr/Invalid logon strength/, "'sms' fails ('sid', 'exact')");

$@ = '';
eval { $s2->assert_match('sid', 'minimum'); };
like("$@", qr/Invalid logon strength/, "'sms' fails ('sid', 'minimum')");

$s2 = $class->new('sid');

$@ = '';
eval { $s2->assert_match('low', 'exact'); };
like("$@", qr/Invalid logon strength/, "'sid' fails ('low', 'exact')");

$@ = '';
eval { $s2->assert_match('sms', 'exact'); };
like("$@", qr/Invalid logon strength/, "'sid' fails ('sms', 'exact')");

$@ = '';
eval { $s2->assert_match('sms', 'minimum'); };
like("$@", qr/Invalid logon strength/, "'sid' fails ('sms', 'minimum')");


$@ = '';
eval { $s2->assert_match('sms', 'close'); };
like("$@", qr/Unrecognised password strength match type/,
    "'close' is not a valid match type");

done_testing();

