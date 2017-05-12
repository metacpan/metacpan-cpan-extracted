use strict;

use lib qw(../../inc ../inc ./inc);

use Test::More tests => 11;

BEGIN {
  use_ok('AFS::Monitor', qw(error_message constant));
}

# Some very basic tests first:

sub foo { return &AFS::Monitor::RX_CALL_CLEARED }

# test error_message
is(error_message(267274), 'Unknown code pt 10 (267274)', 'Return Code 267274');

# test subroutine returning a constant
is(foo(42,17), 64, 'Sub Foo returns constant (2 args)');
is(foo(42), 64, 'Sub Foo returns constant (1 arg)');
is(foo(), 64, 'Sub Foo returns constant (no args)');

# test constant
is(constant('RX_CONN_DESTROY_ME'), 2, 'Constant RX_CONN_DESTROY_ME');
is(constant('RX_CONN_DESTROY_ME', 2), 2, 'Constant RX_CONN_DESTROY_ME with argument');
isnt(constant('zzz'), 2, 'Unknown Constant zzz');

# test AUTOLOAD running function "constant"
is(&AFS::Monitor::RX_CONN_DESTROY_ME, 2, 'AutoLoad Constant RX_CONN_DESTROY_ME');


# Now some more AFS function tests:

use AFS::Monitor;
can_ok('AFS::Monitor', qw(rxdebug));

my $servers = 'afs02.slac.stanford.edu';
my $port    = 7001;
my $rxdeb   = rxdebug(version => 1,
                      servers => $servers,
                      port    => $port
                     );
ok(defined $rxdeb->{version}, 'version');
