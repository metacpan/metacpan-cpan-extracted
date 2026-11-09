use strict;
use warnings;
use Test::More;

# OFFLINE, karr k100: a NUL byte in a connection parameter is REFUSED, naming
# the parameter and never its value.
#
# WHY: the conninfo string reaches EV::Pg as a C string, so libpq reads up to
# the NUL and every parameter behind it is lost -- and with the hash order of
# conninfo_string, whether sslmode=require stands in front of or behind the cut
# value is chance. A connection that silently lacks its TLS setting must not
# open; the base driver's DBIO::PostgreSQL::Util::quote_dsn_value refuses NUL
# for the same reason. Held for every way a value gets in:
#
#   1. a hash value (conninfo_string, escape_conninfo);
#   2. a value of a dbi:Pg: DSN, and the user and password beside it;
#   3. a broker's answer, at the pool spawn;
#   4. controls: values without NUL are rendered as before.

BEGIN {
  package EV::Pg;
  our @NEW;
  sub new { my ($class, %args) = @_; push @NEW, \%args; bless {}, $class }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::AccessBroker::Static;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::ConnectInfo qw( conninfo_string escape_conninfo dbi_to_conninfo );

my $EV = 'DBIO::PostgreSQL::EV::Storage';
my $VAL = "k100-value\0 sslmode=disable";
my $LEAK = qr/k100-value|sslmode=disable|k100-pw/;

sub refusal_ok {
  my ($code, $key, $name) = @_;
  my $err = eval { $code->(); 1 } ? '' : "$@";
  like $err, qr/\bNUL\b/, "$name: refused";
  like $err, qr/\Q$key\E/, "$name: names the key '$key'";
  unlike $err, $LEAK, "$name: quotes no value";
}

# 1. hash values
refusal_ok(sub { conninfo_string({ host => $VAL, sslmode => 'require' }) },
  'host', 'conninfo_string');
refusal_ok(sub { escape_conninfo($VAL, 'dbname') }, 'dbname', 'escape_conninfo with a key');
ok !eval { escape_conninfo("a\0b"); 1 }, 'escape_conninfo without a key refuses too';

# 2. DSN
refusal_ok(sub { dbi_to_conninfo([ "dbi:Pg:dbname=app;host=k100-value\0x", 'u', 'p' ]) },
  'host', 'DSN value');
refusal_ok(sub { dbi_to_conninfo([ "dbi:Pg:dbname=app;host='k100-value\0x'", 'u', 'p' ]) },
  'host', 'quoted DSN value');
refusal_ok(sub { dbi_to_conninfo([ 'dbi:Pg:dbname=app', "u\0k100-value", 'p' ]) },
  'user', 'user beside the DSN');
refusal_ok(sub { dbi_to_conninfo([ 'dbi:Pg:dbname=app', 'u', "k100-pw\0" ]) },
  'password', 'password beside the DSN');

# 3. broker answer, at the spawn
my $broker = DBIO::AccessBroker::Static->new(
  host => "k100-value\0 sslmode=disable", dbname => 'app', username => 'u', password => 'k100-pw',
);
my $s = $EV->new(undef);
@EV::Pg::NEW = ();
# core asks the broker when it is attached, so the refusal may come with
# connect_info or with the spawn; either way before anything reaches EV::Pg.
my $err = eval {
  $s->connect_info([ $broker ]);
  my $f = $s->pool->acquire;
  $f->is_failed ? ($f->failure)[0] : '';
} // "$@";
like "$err", qr/\bNUL\b/, 'broker answer: refused at the spawn';
like "$err", qr/\bhost\b/, 'broker answer: names the key';
unlike "$err", $LEAK, 'broker answer: quotes no value';
is scalar(@EV::Pg::NEW), 0, 'broker answer: nothing reached EV::Pg';

# 4. controls
is conninfo_string({ host => 'db1', sslmode => 'require' }) =~ /sslmode=require/ ? 1 : 0, 1,
  'a value without NUL is rendered';
is escape_conninfo("a b"), "'a b'", 'escape_conninfo unchanged';
is_deeply dbi_to_conninfo([ 'dbi:Pg:dbname=app;host=db1', 'u', 'p' ])->[0],
  { dbname => 'app', host => 'db1', user => 'u', password => 'p' }, 'DSN without NUL read as before';

done_testing;
