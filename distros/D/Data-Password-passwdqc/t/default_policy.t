use strict;
use Test::More;
use Data::Password::passwdqc;

my $pwdqc = Data::Password::passwdqc->new;

my $password = $pwdqc->generate_password;
ok(defined $password, 'password generated');

ok($pwdqc->validate_password('arrive+greece7glove'));
ok($pwdqc->validate_password('cheek6mirror_Wheat', ''));

ok(!$pwdqc->validate_password('joke_river7Pale', '5joke_6river7Pale'));
is($pwdqc->reason, 'is based on the old one');

ok(!$pwdqc->validate_password('joke_river7Pale', '5joke_6river7Pale', '5joke'));
is($pwdqc->reason, 'is based on the old one');

ok(!$pwdqc->validate_password('cheek6mirror_Wheat', 'cheek6mirror_Wheat'));
is($pwdqc->reason, 'is the same as the old one');

ok(!$pwdqc->validate_password('', 'cheek6mirror_Wheat'));
is($pwdqc->reason, 'too short');

ok(!$pwdqc->validate_password('@W2!3M'));
is($pwdqc->reason, 'too short');

ok(!$pwdqc->validate_password('|apr2010'));
is($pwdqc->reason, 'based on a common sequence of characters and not a passphrase');

ok(!$pwdqc->validate_password('morgan22<'));
is($pwdqc->reason, 'based on a dictionary word and not a passphrase');

ok(!$pwdqc->validate_password('AAAAbbbb1111@@@@'));
is($pwdqc->reason, 'not enough different characters or classes for this length');

ok(!$pwdqc->validate_password('%+whitehat'));
is($pwdqc->reason, 'not enough different characters or classes for this length');

ok(!$pwdqc->validate_password('hard apple cider bagel', undef, "hard apple"));
is($pwdqc->reason, 'based on personal login information');

ok(!$pwdqc->validate_password('hard apple cider bagel', undef, undef, "hard apple"));
is($pwdqc->reason, 'based on personal login information');

ok(!$pwdqc->validate_password('joke_river7Pale', undef, 'joke_river'));
is($pwdqc->reason, 'based on personal login information');
ok(!$pwdqc->validate_password('joke_river7Pale', undef, 'jane summon', scalar reverse 'joke_river'));
is($pwdqc->reason, 'based on personal login information');

done_testing;
