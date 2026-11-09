use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::EV::Future;
use DBIO::MySQL::EV::Pool;

alarm 30;

# OFFLINE, karr k66. EV::MariaDB 0.08 starts a connect only when given a host
# or a user; given neither, its handle stays unconnected and calls back neither
# on_connect nor on_error, so an acquire waiting for it would never resolve.
# The pool refuses such connect info -- and anything that is no hash, since
# EV::MariaDB takes no connection string either -- at once and loudly, naming
# shapes and keys, never a value (karr k76).
#
# The fake handle is what EV::MariaDB does for connect info it cannot connect
# from: it never calls back. Without the refusal the acquire stays pending.

my @MADE;
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; push @MADE, {@_}; return bless {}, 'NeverCallsBack' };
}

sub pool_for {
  my ($conninfo) = @_;
  return DBIO::MySQL::EV::Pool->new(
    conninfo     => $conninfo,
    size         => 1,
    future_class => 'DBIO::MySQL::EV::Future',
    on_error     => sub { },
  );
}

# --- the predicate -------------------------------------------------------------

ok(DBIO::MySQL::EV::Pool->_mysql_connectable({ host => 'h' }), 'a host is connectable');
ok(DBIO::MySQL::EV::Pool->_mysql_connectable({ user => 'u' }), 'a user is connectable');
ok !DBIO::MySQL::EV::Pool->_mysql_connectable({ database => 'd', password => 'secret' }),
  'database and password alone are not';
ok !DBIO::MySQL::EV::Pool->_mysql_connectable('host=h'), 'a string is not';

# --- the pool ------------------------------------------------------------------

for my $case (
  [ 'no host and no user' => { database => 'd', password => 'topsecret' } ],
  [ 'an empty hash'       => {} ],
  [ 'a connection string' => 'host=h;user=u;password=topsecret' ],
) {
  my ($label, $conninfo) = @$case;
  @MADE = ();
  my $pool = pool_for($conninfo);
  my $f = $pool->acquire;
  ok $f->is_ready, "$label: acquire is settled at once, not pending";
  ok $f->is_failed, "$label: ... and failed";
  like scalar $f->failure, qr/cannot connect from the connect info.*host or a user/s,
    "$label: ... saying what is missing";
  unlike scalar $f->failure, qr/topsecret/, "$label: ... and quoting no password";
  is scalar @MADE, 0, "$label: no handle was made";
}

@MADE = ();
{
  my $pool = pool_for({ host => 'h', password => 'x' });
  ok !eval { $pool->_create_connection('host=h'); 1 }, '_create_connection croaks on a string';
  like $@, qr/a plain string/, '... naming the shape';
}

done_testing;
