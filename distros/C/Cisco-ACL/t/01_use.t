#
# $Id: 01_use.t 86 2004-06-18 20:18:01Z james $
#

use strict;
use warnings;

use Test::More tests => 2;

use_ok('Cisco::ACL');
is($Cisco::ACL::VERSION, '0.12', 'check module version');

#
# EOF
