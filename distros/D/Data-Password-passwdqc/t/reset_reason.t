use strict;
use Test::More;
use Data::Password::passwdqc;

my $pwdqc = Data::Password::passwdqc->new;

ok(!$pwdqc->reason);

$pwdqc->validate_password('boomer');

is($pwdqc->reason, 'too short');

my $password = $pwdqc->generate_password;

ok(!$pwdqc->reason);

done_testing;
