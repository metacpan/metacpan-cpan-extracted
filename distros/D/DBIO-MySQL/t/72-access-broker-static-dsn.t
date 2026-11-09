use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Util ();
use DBIO::AccessBroker::Static;

# karr k69 -- a DBIO::AccessBroker::Static on the SYNC storage of both schema
# components: the exact DSN DBI->connect is handed, and where the connection's
# parts do not go.
#
# WHY IT MATTERS. A Static broker answers connection parameters -- dbname,
# host, port, user, password -- and names no driver. Core builds the DSN from
# them, for the DBD the storage class is registered for, in a form the driver
# storage may replace (_connect_params_dsn, core ADR 0057). This dist replaces
# nothing: it takes core's default, dbi:<DBD>:dbname=...;host=...;port=..., on
# the strength of two things nothing in this dist ran until now:
#
#   * which DBD the DSN names. The parts name none, so the storage class the
#     schema component pinned is all there is to go by: the DBD it is
#     registered for. Everywhere else in this dist the class does NOT decide
#     the DBD -- the DSN does (karr k60) -- and DBIO::MySQL::Storage::MariaDB
#     is a subclass of the class registered for 'mysql'. A MariaDB component
#     that pinned the parent, or a registry that answered the parent's DBD for
#     the subclass, would connect through DBD::mysql without a word.
#   * that both DBDs read that form. They document database=; dbname= is a
#     synonym each one's DSN parser knows.
#
# And the parts must be in the DSN and NOWHERE ELSE. Until core k239 host and
# port reached DBI->connect as attributes. In these two DBDs an attribute of
# that name is not inert, and they disagree about it (read from the dr::connect
# of DBD::mysql 4.055 and DBD::MariaDB 1.24): DBD::MariaDB lays the attribute
# hash OVER the parsed DSN, so an attribute host wins; DBD::mysql parses the
# DSN INTO the attribute hash, so the DSN's host wins and the attribute is used
# only where the DSN names none. The same connect info would name two servers,
# depending on the DBD.
#
# What this file claims:
#   1. all three parts: DBI->connect gets exactly
#      dbi:mysql:dbname=...;host=...;port=... under load_components('MySQL')
#      and dbi:MariaDB:... under load_components('MySQL::MariaDB'), the
#      broker's user and password as its second and third argument, and no
#      part of the connection among the attributes;
#   2. a part the broker does not have is left out of the DSN, never sent
#      empty;
#   3. a dbname that is a whole DSN is the DSN, unchanged -- the one way a
#      Static broker reaches the other DBD under either component. The storage
#      class stays the component's, the handle is the DSN's DBD's;
#   4. the connection is this dist's like any other: the handle comes up with
#      auto-reconnect on and has it switched off, under the name its DBD gives
#      the attribute (this dist's ADR 0005, karr k59);
#   5. connect options beside the broker ( connect($broker, \%options) ) reach
#      DBI->connect as attributes, the parts still do not, and an auto-reconnect
#      asked for there is honoured;
#   6. the DSN of claim 1 is one each installed DBD's own DSN parser reads
#      database, host and port out of.
#
# FULLY OFFLINE. The one substitution is DBI->connect: it records its arguments
# and hands out a fake handle of the DBD the DSN names, which comes up with that
# DBD's auto-reconnect ON (DBD::mysql does that under MOD_PERL or
# GATEWAY_INTERFACE; t/64 has the handle that is strict about attribute names).
# The schema component, the storage, the built-in broker and core's connect
# path -- connect_info, the DSN building, _connect, _run_connection_actions --
# run for real. Claim 6 calls the installed DBDs' Perl-side parsers and is
# skipped for a DBD that is not installed.
#
# NOT PROVEN HERE: that a server accepts the connection (live only). The
# refusals around the DSN -- host or port beside a whole-DSN dbname, a ';' in a
# part, a storage that is no driver's -- and the broker being asked again for
# every connection are core's, pinned in core's t/access_broker/.

# Each DBD's prefix for its private attributes, spelled out here: the
# expectation must not be derived from the table under test.
my %PREFIX = ( mysql => 'mysql_', MariaDB => 'mariadb_' );

our @CONNECTS;   # every DBI->connect: { dsn, user, password, attrs, dbh }

{
  package K69::SyncDBH;

  sub FETCH { $_[0]{ $_[1] } }
  sub STORE { $_[0]{ $_[1] } = $_[2] }
  sub ping { 1 }
  sub do { 1 }   # the sql_mode statement of every connect (karr k120)
  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    die DBIO::Util::mask_connect_secrets(
      'fake DBI: no fake for a DSN of ' . ($dsn // 'undef') . "\n", [ $dsn, $user, $password ])
      unless defined $dbd && $PREFIX{$dbd};

    # The DBD's own state first, the connect attributes on top.
    my $dbh = bless {
      Driver => { Name => $dbd },
      Active => 1,
      $PREFIX{$dbd} . 'auto_reconnect' => 1,
      %{ $attrs || {} },
    }, 'K69::SyncDBH';
    push @CONNECTS, {
      dsn      => $dsn,
      user     => $user,
      password => $password,
      attrs    => { %{ $attrs || {} } },
      dbh      => $dbh,
    };
    return $dbh;
  };
}

{
  package K69::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K69::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- helpers -----------------------------------------------------------------

sub static_broker {
  return DBIO::AccessBroker::Static->new(username => 'app', password => 's3cret', @_);
}

# Connect $schema_class with the connect arguments given -- a broker, or a
# broker and options -- and open its connection. Returns the schema and the
# one DBI->connect that took.
sub connected {
  my ($schema_class, @connect) = @_;
  @CONNECTS = ();
  my $schema = $schema_class->connect(@connect);
  $schema->storage->ensure_connected;
  return ($schema, $CONNECTS[-1]);
}

# The keys of a connection's parts that turned up among the DBI attributes.
sub parts_among_attrs {
  my ($attrs) = @_;
  return [ grep { exists $attrs->{$_} } qw( dsn dbname database host port user username password ) ];
}

my %SEEN_DSN;   # DBD => the DSN of claim 1, for claim 6

for my $case (
  # the component, its storage class, the DBD its DSNs name
  [ 'K69::MySQLSchema',   'DBIO::MySQL::Storage',          'mysql'   ],
  [ 'K69::MariaDBSchema', 'DBIO::MySQL::Storage::MariaDB', 'MariaDB' ],
) {
  my ($schema_class, $storage_class, $dbd) = @$case;
  my $label     = $schema_class;
  my $reconnect = $PREFIX{$dbd} . 'auto_reconnect';

  # -------------------------------------------------------------------------
  # 1 + 4. All three parts.
  # -------------------------------------------------------------------------
  {
    my ($schema, $c) = connected($schema_class,
      static_broker(dbname => 'appdb', host => 'db.example', port => 3307));

    is scalar(@CONNECTS), 1, "$label: a Static broker opens one connection";
    is $c->{dsn}, "dbi:$dbd:dbname=appdb;host=db.example;port=3307",
      "$label: ... with the DSN of its own DBD, dbname, host and port inside it";
    is_deeply [ @{$c}{qw( user password )} ], [ 'app', 's3cret' ],
      "$label: ... and the broker's user and password as DBI->connect's own";
    is_deeply parts_among_attrs($c->{attrs}), [],
      "$label: ... no part of the connection is a DBI attribute";
    is ref($schema->storage), $storage_class,
      "$label: ... on the storage class the component pinned";

    is $c->{dbh}{$reconnect}, 0,
      "$label: the handle came up with $reconnect on and has it switched off";

    $SEEN_DSN{$dbd} = $c->{dsn};
  }

  # -------------------------------------------------------------------------
  # 2. Parts the broker does not have. Static answers them as undef; an empty
  #    host= or port= in the DSN would be a host the DBD looks up.
  # -------------------------------------------------------------------------
  for my $partial (
    [ [ dbname => 'appdb' ],                       'dbname=appdb',                 'only a dbname' ],
    [ [ dbname => 'appdb', host => 'db.example' ], 'dbname=appdb;host=db.example', 'no port'       ],
    [ [ host => 'db.example', port => 3307 ],      'host=db.example;port=3307',    'no dbname'     ],
    [ [ dbname => 'appdb', host => '', port => undef ], 'dbname=appdb',
      'an empty host and an undef port' ],
  ) {
    my ($parts, $tail, $what) = @$partial;
    my (undef, $c) = connected($schema_class, static_broker(@$parts));

    is $c->{dsn}, "dbi:$dbd:$tail", "$label: $what -- the DSN carries what was given, nothing empty";
    is_deeply parts_among_attrs($c->{attrs}), [], "$label: ... and still no part among the attributes";
  }

  # -------------------------------------------------------------------------
  # 3 + 4. A dbname that is a whole DSN, of either DBD. The handle is that
  #        DBD's, and auto-reconnect is switched off under ITS name.
  # -------------------------------------------------------------------------
  for my $dsn_dbd (qw( mysql MariaDB )) {
    my $dsn = "dbi:$dsn_dbd:database=appdb;host=db.example;port=3307;$PREFIX{$dsn_dbd}connect_timeout=5";
    my ($schema, $c) = connected($schema_class, static_broker(dbname => $dsn));

    is $c->{dsn}, $dsn, "$label: a dbname that is a whole dbi:$dsn_dbd: DSN is the DSN, unchanged";
    is_deeply parts_among_attrs($c->{attrs}), [], "$label: ... no part among the attributes";
    is ref($schema->storage), $storage_class,
      "$label: ... the storage class is still the component's";
    is $c->{dbh}{Driver}{Name}, $dsn_dbd, "$label: ... and the handle is DBD::$dsn_dbd\'s";
    is $c->{dbh}{ $PREFIX{$dsn_dbd} . 'auto_reconnect' }, 0,
      "$label: ... with $PREFIX{$dsn_dbd}auto_reconnect switched off -- named by the handle's DBD";
  }

  # -------------------------------------------------------------------------
  # 5. Options beside the broker.
  # -------------------------------------------------------------------------
  {
    my (undef, $c) = connected($schema_class,
      static_broker(dbname => 'appdb', host => 'db.example', port => 3307),
      { $reconnect => 1 },
    );

    is $c->{dsn}, "dbi:$dbd:dbname=appdb;host=db.example;port=3307",
      "$label: options beside the broker leave the DSN as it was";
    is $c->{attrs}{$reconnect}, 1,
      "$label: ... a DBD attribute among them is an attribute of the connect";
    is_deeply parts_among_attrs($c->{attrs}), [],
      "$label: ... and the parts are still not";
    is $c->{dbh}{$reconnect}, 1,
      "$label: ... an auto-reconnect asked for beside the broker is honoured";
  }
}

# ---------------------------------------------------------------------------
# 6. The form is one the DBDs read. DBI hands a driver the DSN without its
#    dbi:<DBD>: prefix; each DBD's connect parses that with the parser called
#    here (DBD::mysql::dr::connect with exactly these arguments).
# ---------------------------------------------------------------------------

my %PARSER = (
  mysql => sub {
    my %parts;
    DBD::mysql->_OdbcParse($_[0], \%parts, [qw( database host port )]);
    return \%parts;
  },
  MariaDB => sub { DBD::MariaDB->parse_dsn($_[0]) },
);
my %PARSER_METHOD = ( mysql => '_OdbcParse', MariaDB => 'parse_dsn' );

for my $dbd (sort keys %PARSER) {
  SKIP: {
    skip "DBD::$dbd is not installed", 1
      unless eval "require DBD::$dbd; 1";
    skip "DBD::$dbd has no $PARSER_METHOD{$dbd}", 1
      unless "DBD::$dbd"->can($PARSER_METHOD{$dbd});

    (my $driver_dsn = $SEEN_DSN{$dbd}) =~ s/\Adbi:\w+://;
    is_deeply $PARSER{$dbd}->($driver_dsn),
      { database => 'appdb', host => 'db.example', port => 3307 },
      "DBD::$dbd\'s own parser reads database, host and port out of $SEEN_DSN{$dbd}";
  }
}

done_testing;
