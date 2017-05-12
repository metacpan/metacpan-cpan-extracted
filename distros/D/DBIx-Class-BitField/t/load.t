use Test::More tests => 3;

use lib qw(t/lib);

use_ok 'DBIx::Class::BitField';

use_ok 'Schema';

ok Schema->connect;

