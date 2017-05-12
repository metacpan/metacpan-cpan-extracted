use strict;
use Test::More;
use Data::Password::passwdqc;
use POSIX qw(INT_MAX);

my $pwdqc = Data::Password::passwdqc->new(min => [undef, 24, 11, 9, 8]);
is_deeply($pwdqc->min, [INT_MAX, 24, 11, 9, 8]);

$pwdqc->min([undef, 12, 8, 6, 5]);
is_deeply($pwdqc->min, [INT_MAX, 12, 8, 6, 5]);

$pwdqc->min([undef, undef, 8, 6, 5]);
is_deeply($pwdqc->min, [INT_MAX, INT_MAX, 8, 6, 5]);

$pwdqc->min([undef, undef, undef, undef, undef]);
is_deeply($pwdqc->min, [INT_MAX, INT_MAX, INT_MAX, INT_MAX, INT_MAX]);

$pwdqc = Data::Password::passwdqc->new;
is($pwdqc->similar_deny, 1);

$pwdqc->similar_deny(!1);
is($pwdqc->similar_deny, 0);

$pwdqc->similar_deny(!0);
is($pwdqc->similar_deny, 1);

$pwdqc->similar_deny(undef);
is($pwdqc->similar_deny, 0);

done_testing;
