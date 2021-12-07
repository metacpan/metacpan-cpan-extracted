package DataStructure::OrderedSet;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use feature 'signatures';
no warnings 'experimental::signatures';

# Empty, except for the synonym roles. This is only a declaration of a role that
# can be used by other data-structures. In the future this might be a Role::Tiny
# role.

use parent qw(DataStructure::Set);

1;
