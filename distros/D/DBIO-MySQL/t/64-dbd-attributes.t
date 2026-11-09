use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# karr k59 -- the sync storage names its DBD-private attributes by the DBD that
# owns the handle, not by its own class.
#
# WHY IT MATTERS. Auto-reconnect is the silent way to lose a transaction: the
# DBD rebuilds a dropped session underneath an open transaction, the work
# carries on in autocommit on a fresh connection, and nothing raises (this
# dist's ADR 0005). So it is switched off on every connect unless the caller
# set it. But the attribute has two names: mysql_auto_reconnect under DBD::mysql,
# mariadb_auto_reconnect under DBD::MariaDB. The storage class does not tell you
# which one applies. load_components('MySQL') pins DBIO::MySQL::Storage for EVERY
# DSN, so a dbi:MariaDB: DSN runs the parent class on a DBD::MariaDB handle, and
# dbio-mysql-ev connects exactly that way. k57 spelled the DBD::mysql name in the
# parent. DBD::MariaDB dies on a FETCH of any mysql_* attribute, so every such
# connect died with "Unknown attribute mysql_auto_reconnect". The insertid read
# had the same flaw one step later: mysql_insertid died at the first
# auto-increment INSERT.
#
# FULLY OFFLINE. The one substitution is the DBD: DBI->connect is replaced for
# each case and hands out a fake handle. Like a real DBI handle it is a tied
# hash, so every $dbh->{attr} in the storage reaches the fake as a FETCH or
# STORE, and the fake logs it. It behaves as each real DBD does (measured
# 2026-09-26 against MySQL 8.0.30 with DBD::MariaDB 1.24 and DBD::mysql 4.055):
# DBD::MariaDB dies on a FETCH of a mysql_* attribute, and DBD::mysql answers
# undef for a mariadb_* one. It comes up with auto-reconnect ON. DBD::mysql
# does that by itself under MOD_PERL or GATEWAY_INTERFACE. DBD::MariaDB 1.24
# does not, and the storage must not depend on that. The connect runs through
# the real schema component, storage and core connect path.

my %PREFIX = ( mysql => 'mysql_', MariaDB => 'mariadb_' );

{
  package K59::FakeDBH::Tie;

  sub TIEHASH {
    my ($class, %args) = @_;
    return bless { %args, log => [] }, $class;
  }

  # What each real DBD does with the other one's attribute names.
  sub _foreign {
    my ($self, $key) = @_;
    my $mine = $PREFIX{ $self->{driver} };
    my ($other) = grep { $_ ne $mine } values %PREFIX;
    return 0 unless index($key, $other) == 0;
    die "DBD::MariaDB::db FETCH failed: Unknown attribute $key\n"
      if $self->{driver} eq 'MariaDB';
    return 1;
  }

  sub FETCH {
    my ($self, $key) = @_;
    push @{ $self->{log} }, $key;
    return undef if $self->_foreign($key);
    return $self->{attr}{$key};
  }

  sub STORE {
    my ($self, $key, $value) = @_;
    push @{ $self->{log} }, $key;
    $self->{attr}{$key} = $value;
  }

  sub EXISTS { exists $_[0]{attr}{ $_[1] } }
  sub DELETE { delete $_[0]{attr}{ $_[1] } }
  sub FIRSTKEY { my @k = sort keys %{ $_[0]{attr} }; $k[0] }
  sub NEXTKEY {
    my @k = sort keys %{ $_[0]{attr} };
    for my $i (0 .. $#k - 1) { return $k[ $i + 1 ] if $k[$i] eq $_[1] }
    return undef;
  }

  package K59::FakeDBH;

  sub FETCH { $_[0]->{ $_[1] } }
  sub STORE { $_[0]->{ $_[1] } = $_[2] }
  sub ping { 1 }
  sub do { 1 }   # the sql_mode statement of every connect (karr k120)
  sub disconnect { $_[0]->{Active} = 0; 1 }
}

# The DBD each case plays, and every handle it has handed out. DBI->connect is
# replaced for the whole file, so a reconnect gets a fake handle too.
our ($DRIVER, @HANDLES);
{
  no warnings 'redefine';
  *DBI::connect = sub { fake_dbh($DRIVER, $_[4]) };
}

# A fresh handle of $driver, as DBI->connect would return it: the DBD's own
# state first, then the connect attributes on top.
sub fake_dbh {
  my ($driver, $attrs) = @_;
  my %state = (
    Driver     => { Name => $driver },
    Active     => 1,
    CachedKids => {},
    $PREFIX{$driver} . 'auto_reconnect' => 1,
    $PREFIX{$driver} . 'insertid'       => 0,
  );
  %state = ( %state, %{ $attrs || {} } );
  tie my %h, 'K59::FakeDBH::Tie', driver => $driver, attr => \%state;
  my $dbh = bless \%h, 'K59::FakeDBH';
  push @HANDLES, $dbh;
  return $dbh;
}

sub log_of { tied( %{ $_[0] } )->{log} }

{
  package K59::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

# Connect K59::Schema -- load_components('MySQL'), as dbio-mysql-ev does -- with
# a dbi:$driver: DSN.
sub connect_pinned {
  my ($driver, $attrs) = @_;
  $DRIVER = $driver;
  my $schema = K59::Schema->connect("dbi:$driver:database=t", 'u', 'p', $attrs || {});
  $schema->storage->ensure_connected;
  return $schema;
}

for my $driver (qw( MariaDB mysql )) {
  my $mine = $PREFIX{$driver} . 'auto_reconnect';
  my ($other_prefix) = grep { $_ ne $PREFIX{$driver} } values %PREFIX;
  my $other = $other_prefix . 'auto_reconnect';

  note "--- dbi:$driver: under load_components('MySQL')";

  # 1. The default: off on the fresh handle, and the connect survives.
  {
    @HANDLES = ();
    my $schema = eval { connect_pinned($driver) };
    ok $schema, "dbi:$driver: load_components('MySQL') connects"
      or diag $@;
    my $storage = $schema && $schema->storage;
    SKIP: {
      skip 'no connection', 7 unless $storage;

      is ref($storage), 'DBIO::MySQL::Storage',
        '... in the pinned DBIO::MySQL::Storage, not a DBD subclass';
      is tied( %{ $HANDLES[0] } )->{attr}{$mine}, 0,
        "... $mine switched off on the fresh handle";
      ok !( grep { index($_, $other_prefix) == 0 } @{ log_of($HANDLES[0]) } ),
        "... and no $other_prefix* attribute touched";

      # 2. Every reconnect gets the same default, not only the first handle.
      $storage->disconnect;
      $storage->ensure_connected;
      is scalar(@HANDLES), 2, '... a reconnect opens a second handle';
      is tied( %{ $HANDLES[1] } )->{attr}{$mine}, 0,
        "... and $mine is off on it too";

      # 3. The insertid comes from this DBD's attribute.
      tied( %{ $HANDLES[1] } )->{attr}{ $PREFIX{$driver} . 'insertid' } = 42;
      is $storage->last_insert_id(undef, 'id'), 42,
        "... last_insert_id reads $PREFIX{$driver}insertid";
      ok !( grep { index($_, $other_prefix) == 0 } @{ log_of($HANDLES[1]) } ),
        "... still without touching a $other_prefix* attribute";
    }
  }

  # 4. An explicit value in the connect attributes is the caller's choice.
  {
    @HANDLES = ();
    my $schema = eval { connect_pinned($driver, { $mine => 1 }) };
    ok $schema, "dbi:$driver: connects with an explicit $mine => 1" or diag $@;
    is tied( %{ $HANDLES[0] } )->{attr}{$mine}, 1,
      '... and the explicit value survives the reset';
  }

  # 5. ... but only under this DBD's name. The other DBD's name does not
  #    configure this handle, so it does not stop the reset.
  #
  #    Two ways to put it there. Through the DSN, core (karr k327) refuses the
  #    name before any handle exists: DBI->connect would drop it without a
  #    trace, and a connect that "succeeds" with the caller's attribute
  #    unapplied is the worse outcome. Through a connection coderef core checks
  #    nothing (the code opens the connection); the key still reaches the
  #    storage's connect attributes, and the reset must happen: the property.
  {
    @HANDLES = ();
    my $schema = eval { connect_pinned($driver, { $other => 1 }) };
    ok !$schema, "dbi:$driver: the other DBD's $other => 1 is refused at connect";
    like $@, qr/Unknown connect attribute\(s\) '\Q$other\E'/,
      '... naming the attribute';
    is scalar(@HANDLES), 0, '... before any handle is opened';
  }
  {
    @HANDLES = ();
    $DRIVER = $driver;
    my $schema = K59::Schema->connect(
      sub { DBI->connect("dbi:$driver:database=t", 'u', 'p', { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) },
      { $other => 1 },
    );
    eval { $schema->storage->ensure_connected };
    is $@, '', "dbi:$driver: a connection coderef with the other DBD's $other => 1 connects";
    is scalar(@HANDLES), 1, '... one handle';
    is tied( %{ $HANDLES[0] } )->{attr}{$mine}, 0,
      "... which does not keep $mine on";
  }
}

# 6. A DBD this class has no names for is refused, not guessed at.
{
  @HANDLES = ();
  # Core (ADR 0059) reports a DSN of another driver than the declared storage's
  # as a driver mismatch warning; here that is the premise, so it is caught and
  # checked, not let through.
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  my $schema = eval {
    no warnings 'redefine';
    local *DBI::connect = sub {
      tie my %h, 'K59::FakeDBH::Tie', driver => 'mysql',
        attr => { Driver => { Name => 'Pg' }, Active => 1, CachedKids => {}, %{ $_[4] } };
      return bless \%h, 'K59::FakeDBH';
    };
    my $s = K59::Schema->connect('dbi:Pg:dbname=t', 'u', 'p');
    $s->storage->ensure_connected;
    $s;
  };
  ok !$schema, 'a handle of any other DBD fails the connect';
  like $@, qr/DBD::mysql and DBD::MariaDB only.*DBD::Pg/,
    '... naming the DBD it cannot serve';
  is scalar(@warned), 1, '... after core warned once about the driver mismatch';
  like $warned[0], qr/Driver mismatch for declared storage class DBIO::MySQL::Storage.*DBD::Pg/s,
    '... naming the declared storage class and the DBD the DSN leads through';
}

# 7. The future_io transport agrees with the sync storage on each DBD's
#    auto-reconnect name. It has no handle to read the DBD from when it builds
#    the connect attributes, so it asks the same table with the DBD the DSN
#    names -- on either transport class, since the class is pinned by the
#    schema component and says no more about the DBD than the sync storage
#    class does (karr k60; until then each class asked with one fixed DBD).
#    This pins the agreement, not the derivation: a transport that spelled the
#    same name as a literal would still pass here.
SKIP: {
  skip 'DBIO::Async not installed (recommends only)', 4
    unless eval {
      require DBIO::MySQL::Storage::Async;
      require DBIO::MySQL::Storage::MariaDB::Async;
      1;
    };

  for my $class (qw( DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async )) {
    for my $driver (qw( mysql MariaDB )) {
      is( $class->_mysql_auto_reconnect_attr("dbi:$driver:database=t"),
          DBIO::MySQL::Storage->_dbd_attribute($driver => 'auto_reconnect'),
        "$class, dbi:$driver: DSN: the name the sync storage uses for DBD::$driver" );
    }
  }
}

done_testing;
