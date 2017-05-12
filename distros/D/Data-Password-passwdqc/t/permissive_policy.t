use strict;
use Test::More;
use Data::Password::passwdqc;

my $pwdqc = Data::Password::passwdqc->new(min => [undef, 12, 8, 6, 5]);

my $password = $pwdqc->generate_password;
ok(defined $password, 'password generated');

ok($pwdqc->validate_password('arrive+greece7glove'));
ok($pwdqc->validate_password('cheek6mirror_Wheat', ''));

ok(!$pwdqc->validate_password('joke_river7Pale', '5joke_6river7Pale'));
is($pwdqc->reason, 'is based on the old one');

ok(!$pwdqc->validate_password('cheek6mirror_Wheat', 'cheek6mirror_Wheat'));
is($pwdqc->reason, 'is the same as the old one');

ok(!$pwdqc->validate_password('', 'cheek6mirror_Wheat'));
is($pwdqc->reason, 'too short');

ok($pwdqc->validate_password('@W2!3M'));

ok($pwdqc->validate_password('|apr2010'));

ok($pwdqc->validate_password('morgan22<'));

ok($pwdqc->validate_password('AAAAbbbb1111@@@@'));

ok(!$pwdqc->validate_password('%+whitehat'));
is($pwdqc->reason, 'not enough different characters or classes for this length');

done_testing;
