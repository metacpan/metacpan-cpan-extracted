use strict;
use warnings;
use Test::More tests => 9;
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius') };

my $auth = Authen::Radius->new(Host => '127.0.0.1', Secret => 'secret', Debug => 0);
$auth->set_error('ETIMEOUT', 'test timeout');
is($auth->get_error(), 'ETIMEOUT', 'error code');
is(Authen::Radius->get_error(), 'ETIMEOUT', 'global error code');
is($auth->strerror(), 'timed out waiting for packet', 'error message');
is($auth->error_comment(), 'test timeout', 'error comment');

# called by check_pwd()
ok( $auth->clear_attributes, 'clear attributes');

is($auth->get_error(), 'ENONE', 'error was reset');
is(Authen::Radius->get_error(), 'ENONE', 'global error also reset');
