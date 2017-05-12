use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak
    skip_unless_riak => { -as => 'skip_without_riak' },
    'riak_transport';

skip_without_riak;

my $t = riak_transport;
isa_ok $t, 'Data::Riak';

ok !__PACKAGE__->can('skip_unless_riak');
ok !__PACKAGE__->can('skip_unless_leveldb_backend');

done_testing;
