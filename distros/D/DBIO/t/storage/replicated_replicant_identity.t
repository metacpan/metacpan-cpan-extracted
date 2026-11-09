# ABSTRACT: The master's user and password never become a replicant's DBI attributes
use strict;
use warnings;

use Test::More;
use Test::Warn;

use DBIO::Test;

# OFFLINE (karr k248). DBIO::Replicated keeps the options the master was
# connected with and merges them into every replicant's options hash, under the
# replicant's own. Of the keys naming the master's connection it dropped only
# dsn. A master given in hash form -- { dsn, user, password, ... } -- therefore
# handed its user and password on, and a replicant given in DBI form --
# [ $dsn, $user, $pass, \%attrs ] -- takes that hash as its DBI attributes: the
# master's password went to the replicant's DBI->connect as a DBI attribute,
# beside the replicant's own credentials. A master naming dbname, host or port
# handed those on the same way. A short DBI-form replicant -- [ $dsn ] or
# [ $dsn, $user ] -- was worse off: the options hash was appended straight
# after it, into a credential's place, so DBI->connect got the master's options
# (its password among them) as the replicant's user or password, and none of
# them took effect.
#
# A replicant given in hash form reads user and password from that hash as
# its credentials. There the master's are an inheritance, not a leak, and they
# stay one (DBIx::Class heritage): a hash-form replicant naming no credentials
# connects as the master does.
#
# What this file claims:
#   1. a DBI-form replicant under a hash-form master connects with the
#      credentials in its positions -- its own, or none; the master's are not
#      filled in, and a short one ([ $dsn ], [ $dsn, $user ]) no longer gets
#      the master's options hash in a credential's place -- and no key naming
#      a connection (dsn, user, password, dbh_maker, dbname, host, port) is
#      among its DBI attributes or in the connect info it was handed;
#   2. the master's other options -- on_connect_do, quote_names, DBI
#      attributes -- still reach it, under its own;
#   3. a hash-form replicant with its own user and password keeps its own; one
#      naming none inherits the master's; neither gets the master's dsn,
#      dbname, host, port or dbh_maker;
#   4. the same holds under every other master form -- a hash-form master
#      with dbh_maker, a DBI-form master with two attribute hashes, a coderef
#      master;
#   5. a replicant with its own dbh_maker inherits no credentials, so nothing
#      is handed to it that the dbh_maker path would have to ignore (no "were
#      ignored" warning).
#
# THE SUBSTITUTIONS: DBIO::Test::Storage backends (dbi:Test DSNs, coderefs
# that are never called).

my @IDENTITY = qw( dsn user password dbh_maker dbname host port );
my @SERVER   = qw( dsn dbh_maker dbname host port );

sub replicated_storage {
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => {
      '+DBIO::Replicated::Storage' => {
        backend_storage_class => 'DBIO::Test::Storage',
        balancer_type         => 'DBIO::Replicated::Balancer::First',
      },
    },
  );
  return $schema->storage;
}

# Which of @keys are among the DBI attributes the replicant hands DBI->connect.
sub in_dbi_attributes {
  my ($replicant, @keys) = @_;
  my $attrs = $replicant->storage->_dbio_connect_attributes || {};
  return [ grep { exists $attrs->{$_} } @keys ];
}

# Which of @keys are in the connect info the replicant was handed.
sub in_connect_info {
  my ($replicant, @keys) = @_;
  my @hashes = grep { ref $_ eq 'HASH' } @{ $replicant->storage->_connect_info };
  return [ grep { my $k = $_; grep { exists $_->{$k} } @hashes } @keys ];
}

my $on_connect = [ 'SET search_path TO app' ];
my %master_options = (
  on_connect_do => $on_connect,
  quote_names   => 1,
  PrintWarn     => 0,
);

my %hash_master = (
  dsn      => 'dbi:Test:master',
  user     => 'master_user',
  password => 'master_pass',
  %master_options,
);

# A hash-form master that also names its server's parts beside its dsn.
my %hash_master_parts = (
  %hash_master,
  dbname => 'app',
  host   => 'master.db',
  port   => 5432,
);

# ---------------------------------------------------------------------------
# 1 + 2. Hash-form master, DBI-form replicant.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ { %hash_master_parts } ]);

  my ($with_attrs, $without_attrs, $user_only, $bare) = $rstorage->connect_replicants(
    [ 'dbi:Test:rep_one', 'rep_user', 'rep_pass', { RaiseError => 1 } ],
    [ 'dbi:Test:rep_two', 'rep_user', 'rep_pass' ],
    [ 'dbi:Test:rep_three', 'rep_user' ],
    [ 'dbi:Test:rep_four' ],
  );

  for my $case (
    [ 'with its own attribute hash', $with_attrs,    [ 'rep_user', 'rep_pass' ] ],
    [ 'without one',                 $without_attrs, [ 'rep_user', 'rep_pass' ] ],
    [ 'with a user only',            $user_only,     [ 'rep_user', '' ]         ],
    [ 'with no credentials at all',  $bare,          [ '', '' ]                 ],
  ) {
    my ($name, $replicant, $credentials) = @$case;
    my $dbi = $replicant->storage->_dbi_connect_info;

    is_deeply [ @{$dbi}[1, 2] ], $credentials,
      "DBI-form replicant $name connects with the credentials in its positions";
    is_deeply in_dbi_attributes($replicant, @IDENTITY), [],
      '... none naming a connection is among its DBI attributes';
    is_deeply in_connect_info($replicant, @IDENTITY), [],
      '... nor in the connect info it was handed';
    ok !( grep { defined && !ref && $_ eq 'master_pass' } map { ref eq 'HASH' ? values %$_ : $_ } @$dbi ),
      "... the master's password is nowhere in what DBI->connect gets";
    is $dbi->[3]{PrintWarn}, 0,
      "... the master's DBI attributes still reach it";
    is $replicant->storage->on_connect_do, $on_connect,
      '... its on_connect_do';
    is $replicant->storage->_sql_maker_opts->{quote_names}, 1,
      '... its quote_names';
  }

  is $with_attrs->storage->_dbi_connect_info->[3]{RaiseError}, 1,
    "the replicant's own DBI attributes are kept";
}

# ---------------------------------------------------------------------------
# 3. Hash-form master, hash-form replicant.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ { %hash_master_parts } ]);

  my ($own, $none) = $rstorage->connect_replicants(
    { dsn => 'dbi:Test:rep_own',  user => 'rep_user', password => 'rep_pass' },
    { dsn => 'dbi:Test:rep_none' },
  );

  is_deeply [ @{ $own->storage->_dbi_connect_info }[0 .. 2] ],
    [ 'dbi:Test:rep_own', 'rep_user', 'rep_pass' ],
    'a hash-form replicant with its own user and password keeps its own';

  is_deeply [ @{ $none->storage->_dbi_connect_info }[0 .. 2] ],
    [ 'dbi:Test:rep_none', 'master_user', 'master_pass' ],
    "a hash-form replicant naming no credentials inherits the master's";

  for my $case ([ 'with its own credentials', $own ], [ 'naming none', $none ]) {
    my ($name, $replicant) = @$case;
    is_deeply in_connect_info($replicant, grep { $_ ne 'dsn' } @SERVER), [],
      "hash-form replicant $name gets none of the master's dbname, host, port or dbh_maker";
    is_deeply in_dbi_attributes($replicant, @IDENTITY), [],
      '... and nothing naming a connection is among its DBI attributes';
    is $replicant->storage->_dbi_connect_info->[3]{PrintWarn}, 0,
      "... the master's DBI attributes reach it";
    is $replicant->storage->on_connect_do, $on_connect,
      '... and its on_connect_do';
  }
}

# ---------------------------------------------------------------------------
# 4. The other master forms.
# ---------------------------------------------------------------------------
{
  my @forms = (
    [ 'a hash-form master with dbh_maker (its dsn, user and password ignored)',
      [ { %hash_master_parts, dbh_maker => sub { die 'never called' } } ] ],
    [ 'a DBI-form master with two attribute hashes',
      [ 'dbi:Test:master', 'master_user', 'master_pass',
        { PrintWarn => 0 }, { on_connect_do => $on_connect, quote_names => 1 } ] ],
    [ 'a coderef master',
      [ sub { die 'never called' }, { %master_options } ] ],
  );

  for my $form (@forms) {
    my ($name, $info) = @$form;
    my $rstorage = replicated_storage();
    {
      # the dbh_maker master warns about its own ignored dsn/user/password;
      # that warning is the master's and not what this block tests
      local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /were ignored/ };
      $rstorage->connect_info($info);
    }

    my ($dbi_rep, $hash_rep) = $rstorage->connect_replicants(
      [ 'dbi:Test:rep', 'rep_user', 'rep_pass' ],
      { dsn => 'dbi:Test:rep_hash' },
    );
    my $dbi = $dbi_rep->storage->_dbi_connect_info;

    is_deeply [ @{$dbi}[0 .. 2] ], [ 'dbi:Test:rep', 'rep_user', 'rep_pass' ],
      "$name: a DBI-form replicant connects as itself";
    is_deeply [ @{ in_dbi_attributes($dbi_rep, @IDENTITY) }, @{ in_connect_info($dbi_rep, @IDENTITY) } ], [],
      '... with nothing naming a connection among its DBI attributes or connect info';
    is $dbi->[3]{PrintWarn}, 0,
      "... the master's DBI attributes reach it";
    is $dbi_rep->storage->on_connect_do, $on_connect,
      '... and its on_connect_do';

    is $hash_rep->storage->_dbi_connect_info->[0], 'dbi:Test:rep_hash',
      '... a hash-form replicant connects to its own dsn';
    is_deeply in_connect_info($hash_rep, grep { $_ ne 'dsn' } @SERVER), [],
      "... and gets none of the master's dbname, host, port or dbh_maker";
    is_deeply in_dbi_attributes($hash_rep, @IDENTITY), [],
      '... nor anything naming a connection among its DBI attributes';
  }
}

# ---------------------------------------------------------------------------
# 5. A replicant with its own dbh_maker.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ { %hash_master } ]);

  my $replicant;
  warnings_are {
    ($replicant) = $rstorage->connect_replicants(
      { dbh_maker => sub { die 'never called' } },
    );
  } [], 'a dbh_maker replicant is handed no dsn, user or password to ignore';
  is_deeply in_connect_info($replicant, @IDENTITY), [ 'dbh_maker' ],
    '... only its own dbh_maker names its connection';
  is $replicant->storage->on_connect_do, $on_connect,
    "... and it gets the master's other options";
}

done_testing;
