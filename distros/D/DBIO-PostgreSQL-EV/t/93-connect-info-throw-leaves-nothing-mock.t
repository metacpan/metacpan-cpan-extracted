use strict;
use warnings;
use Test::More;

# OFFLINE, karr k88 (core k273, k283, k293): a connect_info that throws leaves
# nothing of the connect_info before it -- measured wider than t/71 section 3,
# which holds four ways of throwing.
#
# The transport overrides connect_info. Core's own throws, and this transport's
# refusals, can come from anywhere in it, and the pool size, the options and
# the attributes beside a broker of the PREVIOUS call must not survive any of
# them: a pool built afterwards would be sized, optioned and connected by a
# call that was replaced. Measured: for every way below, after every kind of
# previous state, the storage is in the state a fresh storage is in after the
# same throwing call -- the pool slot, the stored connect info, conninfo, pool
# size, options, what stood beside a broker, and the broker. And a valid call
# after it gets the default pool size, not the earlier one.
#
# One slot is not compared: core's _storage_options is written by core's
# normaliser only and read by nothing, here or in core; a stale one is
# harmless today (noted on karr k88).

use DBIO::PostgreSQL::EV::Storage;
use DBIO::AccessBroker::Static;
use Scalar::Util ();

my $EV = 'DBIO::PostgreSQL::EV::Storage';

{
  package T93::EmptyBroker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for { {} }
}

{
  package T93::DbiBroker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for {
    return [ 'dbi:Pg:dbname=d;host=h', 'u', 'p', { pool_size => 5, RaiseError => 1 } ];
  }
}

sub broker { DBIO::AccessBroker::Static->new(dbname => 'brk', host => 'h', username => 'u', password => 'p') }

# The states a storage can be in before the throwing call; the pool is built.
my @BEFORE = (
  [ 'static connect info with a pool of 3 and options',
    sub { [ { dbname => 'a', pool_size => 3, application_name => 'earlier' }, { quote_names => 1 } ] } ],
  [ 'a broker with a pool of 4 and DBD attributes beside it',
    sub { [ broker(), { pool_size => 4, RaiseError => 1 } ] } ],
  [ 'a bare broker',
    sub { [ broker() ] } ],
);

my @THROWS = (
  [ 'a coderef',                                  sub { [ sub { 1 } ] } ],
  [ 'a conninfo string with user and password',   sub { [ 'host=x dbname=y', 'user', 'pass' ] } ],
  [ 'another driver\'s DSN',                      sub { [ 'dbi:mysql:dbname=x', 'u', 'p' ] } ],
  [ 'options that are no hash',                   sub { [ { dbname => 'x' }, 'notahash' ] } ],
  [ 'a libpq parameter beside a broker',          sub { [ broker(), { sslmode => 'require' } ] } ],
  [ 'a broker whose answer is empty',             sub { [ bless({}, 'T93::EmptyBroker') ] } ],
  [ 'pool_size in the answer and beside the broker disagree',
                                                  sub { [ bless({}, 'T93::DbiBroker'), { pool_size => 3 } ] } ],
);

# What is left of a call, minus what is random or not ours to judge.
sub state_of {
  my ($s) = @_;
  my %state = map { $_ => $s->{$_} } qw( _conninfo _pool_size _opts );
  $state{connect_info} = $s->{connect_info} ? 'set' : 'none';
  $state{pool}       = $s->{pool} ? 'built' : 'none';
  $state{beside}     = [ sort keys %{ $s->{_access_broker_call_attributes} || {} } ];
  $state{broker}     = Scalar::Util::blessed($s->access_broker) // 'none';
  $state{broker_conninfo_provider} = $s->_conninfo_provider ? 'set' : 'none';
  return \%state;
}

sub throw_of {
  my ($s, $info) = @_;
  return eval { $s->connect_info($info); 1 } ? 'lived' : 'threw';
}

for my $before (@BEFORE) {
  my ($blabel, $bbuild) = @$before;
  for my $throw (@THROWS) {
    my ($tlabel, $tbuild) = @$throw;
    my $label = "$blabel, then $tlabel";

    my $s = $EV->new(undef);
    $s->connect_info($bbuild->());
    $s->pool;

    my $fresh = $EV->new(undef);
    my $fresh_result = throw_of($fresh, $tbuild->());

    is throw_of($s, $tbuild->()), $fresh_result, "$label: the call is refused as on a fresh storage";
    is_deeply state_of($s), state_of($fresh),
      "$label: nothing of the call before is left -- the storage is as a fresh one is after it";

    # A valid call after it: the default pool size, not the earlier one.
    $s->connect_info([ { dbname => 'later' } ]);
    is $s->pool->max_size, 5, "$label: a valid call after it gets the default pool size";
  }
}

done_testing;
