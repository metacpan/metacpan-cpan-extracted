use warnings;
use strict;

use Test::More tests => 16;

BEGIN { use_ok "Authen::DecHpwd", qw(vms_username); }

is vms_username(''), undef;
is vms_username('a'), 'A';
is vms_username('A'), 'A';
is vms_username('AbC'), 'ABC';
is vms_username('a!'), undef;
is vms_username('a '), undef;
is vms_username('!a'), undef;
is vms_username(' a'), undef;
is vms_username('a b'), undef;
is vms_username('a_b'), 'A_B';
is vms_username('a$b'), 'A$B';
is vms_username('0'), '0';
is vms_username('abc123'), 'ABC123';
is vms_username('abcdefghijklmnopqrstuvwxyz01234'),
	'ABCDEFGHIJKLMNOPQRSTUVWXYZ01234';
is vms_username('abcdefghijklmnopqrstuvwxyz012345'), undef;

1;
