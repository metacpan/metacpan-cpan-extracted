use strict;
use warnings;

use Test::More;

use Catalyst::Plugin::Session;

can_ok('Catalyst::Plugin::Session', qw/sessionid session session_delete_reason/);

done_testing;
