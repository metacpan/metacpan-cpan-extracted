use strict;
use lib '../lib';
use Test::More tests => 1;

use base qw(Class::DBI);
BEGIN { use_ok 'Class::DBI::Plugin::FastDelete' }
