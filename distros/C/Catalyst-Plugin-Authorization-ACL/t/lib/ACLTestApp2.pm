package ACLTestApp2;

use strict;
use warnings;
no warnings 'uninitialized';

use Catalyst qw/
  Authorization::ACL
/;

__PACKAGE__->setup;

__PACKAGE__->deny_access("/");

__PACKAGE__->allow_access("/bar");

__PACKAGE__;
