use v5.26;
use warnings;

use Test2::V0;

use ok 'Authorization::AccessControl';

use ok 'Authorization::AccessControl', qw(acl);

use ok 'Authorization::AccessControl::Grant';

use ok 'Authorization::AccessControl::Dispatch';

use ok 'Authorization::AccessControl::Request';

done_testing;
