# ABSTRACT: A broker-backed replicant gets the master's connect options beside its broker
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util 'refaddr';

use DBIO::Test;
use DBIO::AccessBroker;

# OFFLINE (karr k246). DBIO::Replicated merges the connect options the master
# was given -- DBI attributes, on_connect_do, quote_names, ... -- into every
# replicant's options hash, under the replicant's own. A replicant whose
# connection comes from an AccessBroker got none of them: it was passed on as
# [ $broker ] alone, since merging into the broker would shred the object. A
# replicant given as [ $broker, \%options ] (the form ADR 0030 addendum II,
# karr k243, gave a broker-backed connection its options in) was shredded:
# its broker was merged into a plain hash, and it connected from the broker's
# internals instead of the broker.
#
# What this file claims:
#   1. a replicant given as [ $broker ] ends up with the master's storage
#      options, SQL maker options and DBI attributes, exactly as a DSN
#      replicant does;
#   2. a replicant's own options beside its broker win over the master's, as
#      a DSN replicant's own hash does;
#   3. given as [ $broker, \%options ], the replicant keeps its broker;
#   4. the master's options naming the connection itself (a hash-form master's
#      user and password) stay behind -- which database, and as whom, is the
#      replicant broker's answer;
#   5. with no master options, the replicant is handed its broker alone;
#   6. the options beside a broker master reach broker replicants too;
#   7. a broker followed by anything but one options hash is refused.
#
# THE SUBSTITUTIONS: DBIO::Test::Storage backends (dbi:Test DSNs); brokers
# answering a dbi:Test DSN.

{
  package T::DSNBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { dsn => $_[1] }, $_[0] }
  sub connect_info_for { [ $_[0]->{dsn}, 'broker_user', 'broker_pass', {} ] }
}

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

# What a replicant's storage made of its connect info.
sub settings_of {
  my ($replicant) = @_;
  my $storage = $replicant->storage;
  my %attrs = %{ $storage->_dbi_connect_info->[3] || {} };
  return {
    on_connect_do => $storage->on_connect_do,
    quote_names   => $storage->_sql_maker_opts->{quote_names},
    attributes    => \%attrs,
  };
}

my $on_connect = [ 'SET search_path TO app' ];
my %master_options = (
  on_connect_do => $on_connect,
  quote_names   => 1,
  PrintWarn     => 0,
);

# ---------------------------------------------------------------------------
# 1. [ $broker ]: the master's options, as a DSN replicant gets them.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ 'dbi:Test:master', '', '', { %master_options } ]);

  my $broker = T::DSNBroker->new('dbi:Test:rep_broker');
  my ($dsn_rep, $broker_rep) = $rstorage->connect_replicants(
    [ 'dbi:Test:rep_dsn', '', '' ],
    [ $broker ],
  );

  is refaddr($broker_rep->storage->access_broker), refaddr($broker),
    'the broker-backed replicant consumed its broker';
  is $broker_rep->storage->on_connect_do, $on_connect,
    "it has the master's on_connect_do";
  is $broker_rep->storage->_sql_maker_opts->{quote_names}, 1,
    "... the master's quote_names";
  is $broker_rep->storage->_dbi_connect_info->[3]{PrintWarn}, 0,
    "... the master's DBI attributes";
  is_deeply settings_of($broker_rep), settings_of($dsn_rep),
    '... exactly what the DSN replicant has';
  is $broker_rep->storage->_dbi_connect_info->[0], 'dbi:Test:rep_broker',
    "... and connects where its broker answers";
}

# ---------------------------------------------------------------------------
# 2 + 3. [ $broker, \%options ]: its own options win, and it keeps its broker.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ 'dbi:Test:master', '', '', { %master_options } ]);

  my $broker = T::DSNBroker->new('dbi:Test:rep_broker');
  my ($dsn_rep, $broker_rep) = $rstorage->connect_replicants(
    [ 'dbi:Test:rep_dsn', '', '', { PrintWarn => 1 } ],
    [ $broker, { PrintWarn => 1 } ],
  );

  is refaddr($broker_rep->storage->access_broker), refaddr($broker),
    'given with options, the replicant keeps its broker';
  is $broker_rep->storage->_dbi_connect_info->[0], 'dbi:Test:rep_broker',
    '... and connects where it answers';
  is $broker_rep->storage->_dbi_connect_info->[3]{PrintWarn}, 1,
    "its own option wins over the master's";
  is $broker_rep->storage->on_connect_do, $on_connect,
    "... the master's others still reach it";
  is_deeply settings_of($broker_rep), settings_of($dsn_rep),
    '... exactly as for a DSN replicant with the same option';
}

# ---------------------------------------------------------------------------
# 4. The master's options naming the connection stay behind.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ {
    dsn => 'dbi:Test:master', user => 'master_user', password => 'master_pass',
    %master_options,
  } ]);

  my $broker = T::DSNBroker->new('dbi:Test:rep_broker');
  my $broker_rep;
  lives_ok { ($broker_rep) = $rstorage->connect_replicants([ $broker ]) }
    "a hash-form master's user and password do not go beside the broker";
  is $broker_rep->storage->_dbi_connect_info->[1], 'broker_user',
    '... the replicant connects as its broker answers';
  is $broker_rep->storage->on_connect_do, $on_connect,
    "... with the master's other options";
}

# ---------------------------------------------------------------------------
# 5. No master options: the broker alone.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ 'dbi:Test:master', '', '' ]);

  my $broker = T::DSNBroker->new('dbi:Test:rep_broker');
  my ($broker_rep) = $rstorage->connect_replicants([ $broker ]);
  is_deeply $broker_rep->storage->_connect_info, [ $broker ],
    'no master options: the replicant is handed its broker alone';
}

# ---------------------------------------------------------------------------
# 6. A broker master's options.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  my $master_broker = T::DSNBroker->new('dbi:Test:master');
  $rstorage->connect_info([ $master_broker, { %master_options } ]);

  is refaddr($rstorage->master->storage->access_broker), refaddr($master_broker),
    'the master consumed its broker';

  my ($broker_rep) = $rstorage->connect_replicants([ T::DSNBroker->new('dbi:Test:rep_broker') ]);
  is $broker_rep->storage->on_connect_do, $on_connect,
    "the options beside the master's broker reach a broker replicant";
  is $broker_rep->storage->_dbi_connect_info->[3]{PrintWarn}, 0,
    '... its DBI attributes too';
}

# ---------------------------------------------------------------------------
# 7. Malformed.
# ---------------------------------------------------------------------------
{
  my $rstorage = replicated_storage();
  $rstorage->connect_info([ 'dbi:Test:master', '', '', { %master_options } ]);
  my $broker = T::DSNBroker->new('dbi:Test:rep_broker');

  throws_ok { $rstorage->connect_replicants([ $broker, { PrintWarn => 1 }, { RaiseError => 1 } ]) }
    qr/A broker-backed replicant takes \[ \$broker \] or \[ \$broker, \\%options \]/,
    'a broker followed by two hashes is refused';
  throws_ok { $rstorage->connect_replicants([ $broker, 'dbi:Test:x' ]) }
    qr/A broker-backed replicant takes/,
    '... and so is a broker followed by a string';
}

done_testing;
