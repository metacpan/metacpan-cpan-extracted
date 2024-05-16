use v5.26;
use warnings;

use Test2::V0;

use experimental qw(signatures);

use Authorization::AccessControl qw(acl);

acl->grant(User => 'read');

ok(
  warns {
    acl->grant(User => 'read')
  },
  'warns on duplicate'
);

ok(
  !warns {
    acl->role('admin')->grant(User => 'read')
  },
  'different role means not dupe'
);

acl->role('admin')->grant(User => 'write');
ok(
  warns {
    acl->role('admin')->grant(User => 'write')
  },
  'warns on duplicate with role'
);

done_testing;
