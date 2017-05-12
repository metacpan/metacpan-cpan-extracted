use Test::More tests => 1;
use strict;
use warnings;

use Crypt::GCM;

can_ok('Crypt::GCM', qw(new tag aad set_iv encrypt decrypt));

