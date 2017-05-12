use warnings;
use strict;

use Test::More tests => 17;

BEGIN { use_ok "Authen::DecHpwd", qw(vms_password); }

is vms_password(''), undef;
is vms_password('a'), 'A';
is vms_password('A'), 'A';
is vms_password('AbC'), 'ABC';
is vms_password('a!'), undef;
is vms_password('a '), undef;
is vms_password('!a'), undef;
is vms_password(' a'), undef;
is vms_password('a b'), undef;
is vms_password('a_b'), 'A_B';
is vms_password('a$b'), 'A$B';
is vms_password('0'), '0';
is vms_password('abc123'), 'ABC123';
is vms_password('abcdefghijklmnopqrstuvwxyz01234'),
	'ABCDEFGHIJKLMNOPQRSTUVWXYZ01234';
is vms_password('abcdefghijklmnopqrstuvwxyz012345'),
	'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
is vms_password('abcdefghijklmnopqrstuvwxyz0123456'), undef;

1;
