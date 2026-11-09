use strict;
use warnings;
use Test::More;

# OFFLINE test: connect info in the single-hash form on the future_io
# transport (karr k66).
#
# WHY. connect({ dsn => ..., user => ..., password => ..., mysql_connect_timeout
# => 7, async => 'future_io' }) is DBIx::Class's hash form: every key but dsn,
# user and password is a DBD attribute, and the owning sync storage connects
# with it (DBIO::Storage::DBI::_normalize_connect_info). The transport's
# _normalize_conninfo handed the hash on untouched, so the pool and listen
# connections were opened without the flat attributes -- the silent difference
# between owner and pool that k64 closed for the DBI form.
#
# Claims:
#   1. flat keys of the hash form reach the pool AND the listen connection,
#      the very values the owner connects with, nothing DBIO-private;
#   2. pool_size in the hash sizes the pool and stays out of the DBD;
#   3. a nested attrs hash in the hash form is read too, and wins over a flat
#      key of the same name;
#   4. the transport's own shapes are untouched: [ \%conninfo, \%opts ] and
#      the one-element form with a dsn key but no flat keys beside it connect
#      as they did, a hash with dbh_maker is not reshaped.
# SUBSTITUTION: DBI->connect records its arguments. The real DBDs are live
# (t/127).

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; require DBIO::MySQL::Storage::MariaDB::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::MariaDB ();

our @CONNECTS;
{
  package K66::DBH;
  sub new { my ($class, $dbd) = @_; bless { Active => 1, Driver => { Name => $dbd } }, $class }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { 1 }
}
{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return K66::DBH->new($dbd);
  };
}
{
  package K66::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  package K66::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

my %FLAVOUR = (
  mysql   => { schema => 'K66::MySQLSchema',   async => 'DBIO::MySQL::Storage::Async',
               sync => 'DBIO::MySQL::Storage',         timeout => 'mysql_connect_timeout',
               multi => 'mysql_multi_statements',   reconnect => 'mysql_auto_reconnect' },
  MariaDB => { schema => 'K66::MariaDBSchema', async => 'DBIO::MySQL::Storage::MariaDB::Async',
               sync => 'DBIO::MySQL::Storage::MariaDB', timeout => 'mariadb_connect_timeout',
               multi => 'mariadb_multi_statements', reconnect => 'mariadb_auto_reconnect' },
);
my %FORCED = (AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1);

sub spawn       { my ($s) = @_; @CONNECTS = (); $s->pool->acquire->get; return $CONNECTS[-1] }
sub open_listen { my ($s) = @_; @CONNECTS = (); $s->_listen_open->get; return $CONNECTS[-1] }

for my $flavour (qw( mysql MariaDB )) {
  my $f = $FLAVOUR{$flavour};
  my ($timeout, $multi, $reconnect) = @{$f}{qw( timeout multi reconnect )};
  my $dsn = "dbi:$flavour:dbname=appdb";

  {
    my $schema = $f->{schema}->connect({
      dsn => $dsn, user => 'u', password => 'p',
      $timeout => 7, $multi => 1, pool_size => 2,
      async => 'future_io', on_connect_do => [ 'SET @k66 = 1' ], quote_names => 1,
    });
    my $owner = $schema->storage->_dbi_connect_info->[3];
    is_deeply [ @{$owner}{ $timeout, $multi } ], [ 7, 1 ],
      "$flavour: the owner connects with the flat attributes";

    my $async = $schema->storage->async;
    my $want  = [ $dsn, 'u', 'p', { $timeout => 7, $multi => 1, %FORCED, $reconnect => 0 } ];
    is_deeply spawn($async), $want,
      '... and a pool connection gets the very same, nothing DBIO-private';
    is_deeply open_listen($async), $want, '... and the listen connection';
    is $async->pool->max_size, 2, '... pool_size in the hash sizes the pool';
  }

  {
    my $s = $f->{async}->new(undef);
    $s->connect_info([ { dsn => $dsn, user => 'u', password => 'p',
                         $timeout => 30, $multi => 1, attrs => { $timeout => 7 } } ]);
    is_deeply spawn($s),
      [ $dsn, 'u', 'p', { $timeout => 7, $multi => 1, %FORCED, $reconnect => 0 } ],
      "$flavour: nested attrs are read, and win over a flat key";
  }

  {
    my $s = $f->{async}->new(undef);
    $s->connect_info([ { dsn => $dsn, user => 'u', password => 'p', attrs => { $timeout => 7 } }, { } ]);
    is_deeply spawn($s), [ $dsn, 'u', 'p', { $timeout => 7, %FORCED, $reconnect => 0 } ],
      "$flavour: the transport's own [ \\%conninfo, \\%opts ] form is unchanged";

    $s = $f->{async}->new(undef);
    $s->connect_info([ { dsn => $dsn, user => 'u', password => 'p' } ]);
    is_deeply spawn($s), [ $dsn, 'u', 'p', { %FORCED, $reconnect => 0 } ],
      '... and a hash with nothing but dsn, user, password connects bare';

    my $maker = sub { 1 };
    my $info  = [ { dbh_maker => $maker, extra => 1 } ];
    is_deeply $f->{async}->new(undef)->_normalize_conninfo($info), $info,
      '... and a hash with a dbh_maker is not reshaped';
  }
}

done_testing;
