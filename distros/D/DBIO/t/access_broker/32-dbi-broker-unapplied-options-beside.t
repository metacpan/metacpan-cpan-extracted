# ABSTRACT: A sync storage does not connect with a parameter beside its broker that it would not apply
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k307; maintainer's decision 2026-10-06). The twin of
# 31-dbi-broker-unapplied-parameters.t, for the hash BESIDE the broker:
#
#   MyApp::Schema->connect($broker, { async => 'ev', sslmode => 'require' })
#
# The ev transport refuses a parameter of its client given there. The owning
# sync storage did not: it normalised the hash beside the broker like any
# attribute hash, merged what it does not consume into the DBI attributes of
# the broker's answer, and DBD::Pg does not read a lowercase attribute it does
# not know. The dbh was opened without sslmode, and nothing said so.
#
# WHY: the same loss as in a hash answer, by the other door, so the same
# yardstick and the same moment. A key beside the broker passes when the
# storage consumes it or when it is the name of a DBI attribute -- an
# uppercase first letter, private_, dbi_, dbd_, or the prefix of the DBD the
# ANSWER's DSN names, since that is the DBD the attributes go to. Anything
# else cannot be told from a parameter of the database client. The storage
# throws where it would open its own connection without it, and not before:
# what stands beside the broker may be for an async backend.
#
# What this file claims:
#   1. A key beside the broker that is neither consumed nor the name of a DBI
#      attribute configures the storage -- with and without an async mode,
#      whatever shape the broker answers in -- and stops the storage's own
#      connection: the first one and every later one, attached directly or
#      through a HostBound view, by the generic and by a driver storage. The
#      error says the parameter stands beside the broker, names the broker
#      class and the NAMES, all of them, never a value -- not the
#      parameter's, not one of the answer -- and DBI->connect is not called.
#   2. The DBD is the one the current answer's DSN names: its prefix passes,
#      another DBD's does not, and an answer that moves to another DBD is
#      judged by that one.
#   3. What may stand beside a broker still reaches DBI->connect, or the
#      storage, as before: DBI attributes, the storage's and the SQL maker's
#      options, async, pool_size, ignore_version; a key set to undef or to
#      the empty string, which names no parameter.
#   4. The error says where the parameter belongs: in the broker's answer --
#      the DBI form with it inside the DSN, or an answer by the storage that
#      asks. It does not name a dsn key in a hash answer.
#   5. With an async mode the options are the backend's to take or refuse: a
#      transport that takes connect options beside a broker is handed them,
#      and the owner's own dbh -- its first access -- throws.
#   6. A parameter in the hash answer is named first, as the answer's
#      (31-dbi-broker-unapplied-parameters.t); the one beside the broker once
#      the answer is free of them.
#   7. Beside a broker that answers a code reference (dbh_maker) every key the
#      storage does not consume itself throws (karr k310; maintainer's
#      decision 2026-10-09): the code opens the connection, and the storage
#      applies no DBI attribute and no client parameter to it. Checked before
#      the answer is set against the options.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; a fake driver storage registered for the DBD name 'ExampleP' (in
# DBI's prefix registry as examplep_, and no DBIO driver's); an async mode
# whose backend records the connect info it is handed; no DBD is loaded and no
# database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ExampleP => __PACKAGE__);
}

# A transport that takes connect options beside a broker, and records what it
# is handed.
{
  package T::TakingBackend;
  use base 'DBIO::Storage::Async';
  sub new { my ($class, $schema) = @_; bless { schema => $schema }, $class }
  sub transport_capabilities { 'broker_connect_options' }
  sub connect_info { my $self = shift; $self->{connect_info} = shift if @_; $self->{connect_info} }
  sub disconnect { 1 }
}

T::Driver::Storage->register_async_mode(k307loop => 'T::TakingBackend');

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

is scalar('DBI'->driver_prefix('DBD::ExampleP')), 'examplep_',
  'premise: DBI knows the prefix of DBD::ExampleP without loading it';
is scalar('DBI'->driver_prefix('DBD::K307Fake')), undef,
  'premise: and none for DBD::K307Fake';

my ($USER, $PASSWORD) = ('k307-user', 'k307-secret');
# every value of an answer and of an option in this file
my $VALUE = qr/k307-(?:user|secret|db|host|value)|dbi:ExampleP|dbi:K307Fake/;

my $DSN   = 'dbi:ExampleP:dbname=k307-db;host=k307-host';
my %LOGIN = (user => $USER, password => $PASSWORD);

sub dbi_form { [ $DSN, $USER, $PASSWORD, {} ] }

sub refused_beside {
  my ($broker_class, @names) = @_;
  my $names = join ', ', @names;
  return qr/A DBI storage does not apply parameter\(s\) given beside AccessBroker \Q$broker_class\E \(\Q$names\E\)/;
}

# The attribute hash DBI->connect was handed last, without the storage's own
# defaults.
sub connect_attrs {
  my %attrs = %{ $CONNECTS[-1][3] || {} };
  delete @attrs{qw( AutoCommit PrintError RaiseError ShowErrorStatement )};
  return \%attrs;
}

my @BOTH   = ('DBIO::Storage::DBI', 'T::Driver::Storage');
my @DRIVER = ('T::Driver::Storage');   # a dbname needs the storage of a driver

# ---------------------------------------------------------------------------
# 1. Configured, and no connection of the storage's own.
# ---------------------------------------------------------------------------
# label => [ storage classes, the broker's answer ]
my %ANSWER = (
  'the DBI form'            => [ \@BOTH,   \&dbi_form ],
  'a hash with a dsn'       => [ \@BOTH,   sub { { dsn => $DSN, %LOGIN } } ],
  'a hash with a dbname'    => [ \@DRIVER, sub { { dbname => 'k307-db', host => 'k307-host', %LOGIN } } ],
);

# label => [ the hash beside the broker, the names the error gives ]
my %BESIDE = (
  'sslmode' => [
    { sslmode => 'k307-value' }, [ 'sslmode' ] ],
  'sslmode and an async mode' => [
    { async => 'immediate', sslmode => 'k307-value' }, [ 'sslmode' ] ],
  'several client parameters, among what may stand beside a broker' => [
    { sslmode => 'k307-value', connect_timeout => 'k307-value', application_name => 'k307-value',
      RaiseError => 1, examplep_trace => 1, private_tag => 'x', quote_names => 1,
      on_connect_do => [ 'SELECT 1' ], pool_size => 3, ignore_version => 1 },
    [ qw( application_name connect_timeout sslmode ) ] ],
  'the prefix of another DBD' => [
    { pg_enable_utf8 => 'k307-value' }, [ 'pg_enable_utf8' ] ],
);

for my $answer_label (sort keys %ANSWER) {
  my ($classes, $answer) = @{ $ANSWER{$answer_label} };

  for my $class (@$classes) {
    for my $beside_label (sort keys %BESIDE) {
      my ($beside, $names) = @{ $BESIDE{$beside_label} };
      my $t = "$class, $beside_label beside a broker answering $answer_label";

      {
        my $storage = $class->new(undef);
        local @CONNECTS;
        lives_ok { $storage->connect_info([ T::ScriptBroker->new($answer), { %$beside } ]) }
          "$t: connect_info configures the storage";
        throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', @$names),
          "$t: its own connection throws, naming the broker class and the names";
        unlike "$@", $VALUE, "$t: naming no value, of the options or of the answer";
        throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', @$names),
          "$t: every connection after it throws the same";
        is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
      }

      {
        my $storage = $class->new(undef);
        my $view = T::ScriptBroker->new($answer)->for_host('k307-host-replica');
        local @CONNECTS;
        lives_ok { $storage->connect_info([ $view, { %$beside } ]) }
          "$t, through a HostBound view: connect_info configures the storage";
        throws_ok { $storage->_connect } refused_beside('DBIO::AccessBroker::HostBound', @$names),
          "$t, through a HostBound view: its own connection throws, naming the view and the same names";
        unlike "$@", $VALUE, "$t, through a HostBound view: naming no value";
        is scalar @CONNECTS, 0, "$t, through a HostBound view: DBI->connect is not called";
      }
    }
  }
}

# The way a caller meets it: the first access to the dbh.
{
  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&dbi_form), { sslmode => 'k307-value' } ]);
  local @CONNECTS;
  throws_ok { $storage->dbh } refused_beside('T::ScriptBroker', 'sslmode'),
    'the first access to the dbh throws';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called';
}

# ---------------------------------------------------------------------------
# 2. The DBD is the one the current answer's DSN names.
# ---------------------------------------------------------------------------
for my $class (@BOTH) {
  my $other = sub { [ 'dbi:K307Fake:dbname=k307-db', $USER, $PASSWORD, {} ] };

  my $storage = $class->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&dbi_form, \&dbi_form, $other), { examplep_trace => 1 } ]);
  local @CONNECTS;
  lives_ok { $storage->_connect }
    "$class, an attribute of the answer's DBD beside the broker: connects";
  is_deeply connect_attrs(), { examplep_trace => 1 }, "$class: ... and reaches DBI->connect";
  throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', 'examplep_trace'),
    "$class: once the answer names another DBD, the same key is none of that DBD's, and the connection throws";
  is scalar @CONNECTS, 1, "$class: ... without another DBI->connect";
}

# ---------------------------------------------------------------------------
# 3. What may stand beside a broker (control).
# ---------------------------------------------------------------------------
# label => [ the hash beside the broker, what of it DBI->connect gets as
# attributes ]
my %CARRIED = (
  'nothing' => [ {}, {} ],
  "DBI's own attributes" => [
    { LongReadLen => 4096, FetchHashKeyName => 'NAME_lc' },
    { LongReadLen => 4096, FetchHashKeyName => 'NAME_lc' } ],
  "an attribute with the DBD's prefix" => [
    { examplep_trace => 1 }, { examplep_trace => 1 } ],
  'private_, dbi_ and dbd_ attributes' => [
    { private_app_tag => 'x', dbi_connect_method => 'connect', dbd_verbose => 2 },
    { private_app_tag => 'x', dbi_connect_method => 'connect', dbd_verbose => 2 } ],
  "the storage's options" => [
    { on_connect_do => [ 'SELECT 1' ], auto_savepoint => 1, unsafe => 1, cursor_class => 'DBIO::Storage::DBI::Cursor' }, {} ],
  "the SQL maker's options" => [
    { quote_names => 1, name_sep => '.' }, {} ],
  'an async mode and pool_size' => [
    { async => 'immediate', pool_size => 3 }, {} ],
  'pool_size without a mode' => [
    { pool_size => 3 }, { pool_size => 3 } ],
  'ignore_version' => [
    { ignore_version => 1 }, {} ],
  'a client parameter set to undef or to the empty string' => [
    { sslmode => undef, connect_timeout => '' }, { sslmode => undef, connect_timeout => '' } ],
);

for my $class (@BOTH) {
  for my $label (sort keys %CARRIED) {
    my ($beside, $attrs) = @{ $CARRIED{$label} };
    my $t = "$class, $label beside the broker";

    my $storage = $class->new(undef);
    local @CONNECTS;
    lives_ok {
      $storage->connect_info([ T::ScriptBroker->new(\&dbi_form), { %$beside } ]);
      $storage->_connect;
    } "$t: connects";
    is_deeply [ @{ $CONNECTS[0] || [] }[0 .. 2] ], [ $DSN, $USER, $PASSWORD ],
      "$t: ... to the DSN the broker answered, with its credentials";
    is_deeply connect_attrs(), $attrs, "$t: ... and DBI->connect gets what it got before";
  }
}

{
  my $on_connect = [ 'SELECT 1' ];
  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&dbi_form), {
    on_connect_do => $on_connect, quote_names => 0, ignore_version => 1, async => 'immediate',
  } ]);
  is $storage->on_connect_do, $on_connect, 'on_connect_do beside the broker is the storage option';
  is $storage->_sql_maker_opts->{quote_names}, 0, 'quote_names beside the broker is the SQL maker option';
  is $storage->_dbio_connect_attributes->{ignore_version}, 1, 'ignore_version beside the broker stays introspectable';
  is $storage->_async_mode, 'immediate', 'async beside the broker is the mode';
}

# ---------------------------------------------------------------------------
# 4. The error says where the parameter belongs.
# ---------------------------------------------------------------------------
{
  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&dbi_form), { sslmode => 'k307-value' } ]);
  throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', 'sslmode'),
    'a parameter beside the broker';
  like "$@", qr/the broker's to answer.* the DBI form .* inside the DSN .* or by the storage that asks \(connect_info_for_storage\)/s,
    "... belongs in the broker's answer: the DBI form with it inside the DSN, or an answer by the storage that asks";
  unlike "$@", qr/dsn\s*=>/, '... and the error names no dsn key in a hash answer';
  unlike "$@", qr/answered connect info with parameter/, '... nor takes it for a parameter of the answer';
}

# ---------------------------------------------------------------------------
# 5. With an async mode.
# ---------------------------------------------------------------------------
{
  my $broker  = DBIO::AccessBroker::Static->new(
    dbname => 'k307-db', host => 'k307-host', username => $USER, password => $PASSWORD,
  );
  my $storage = T::Driver::Storage->new(undef);
  local @CONNECTS;

  lives_ok { $storage->connect_info([ $broker, { async => 'k307loop', sslmode => 'k307-value' } ]) }
    'an async mode and a client parameter beside the broker: connect_info configures the owner';
  is $storage->_async_mode, 'k307loop', '... with the mode';
  is $storage->_dbi_connect_info->[0], 'dbi:ExampleP:dbname=k307-db;host=k307-host',
    '... and the DSN built from the answer, which driver detection reads';

  my $backend = eval { $storage->async };
  isa_ok $backend, 'T::TakingBackend', '... ->async: the transport' or diag $@;
  is_deeply eval { $backend->connect_info }, [ $broker, { async => 'k307loop', sslmode => 'k307-value' } ],
    '... handed the options beside the broker, to take or to refuse';
  is scalar @CONNECTS, 0, '... and none of this called DBI->connect';

  throws_ok { $storage->dbh } refused_beside('DBIO::AccessBroker::Static', 'sslmode'),
    "the owner's own dbh, at its first access, throws";
  unlike "$@", $VALUE, '... naming no value';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called';
}

# ---------------------------------------------------------------------------
# 6. A parameter of the answer first.
# ---------------------------------------------------------------------------
{
  my $with    = sub { { dsn => $DSN, %LOGIN, sslmode => 'k307-value' } };
  my $without = sub { { dsn => $DSN, %LOGIN } };

  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new($with, $with, $without), { connect_timeout => 'k307-value' } ]);
  local @CONNECTS;
  throws_ok { $storage->_connect }
    qr/AccessBroker T::ScriptBroker answered connect info with parameter\(s\) a DBI storage does not apply \(sslmode\)/,
    "a parameter in the answer and another beside the broker: the answer's is named, as the answer's";
  throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', 'connect_timeout'),
    '... and the one beside the broker once the answer carries none';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called for either';
}

# ---------------------------------------------------------------------------
# 7. Beside a broker answering a code reference (karr k310).
# ---------------------------------------------------------------------------
# The code opens the connection, and the storage applies no connect option
# and no DBI attribute to it. What stands beside the broker and the storage
# does not consume itself would be dropped without a word, so the storage
# throws, as for any other answer. What it consumes still passes.
{
  my $maker = sub { my $made = shift; sub { { dbh_maker => sub { $$made++; T::Handle->new } } } };

  for my $class (@BOTH) {
    for my $case (
      [ 'a client parameter'  => { sslmode => 'k307-value' }, [ 'sslmode' ] ],
      [ 'a DBI attribute'     => { LongReadLen => 4096 }, [ 'LongReadLen' ] ],
      [ 'the prefix of the DBD' => { examplep_trace => 1 }, [ 'examplep_trace' ] ],
      [ 'several, among what is consumed' => {
          sslmode => 'k307-value', LongReadLen => 4096, quote_names => 1,
          on_connect_do => [ 'SELECT 1' ], pool_size => 3,
        }, [ qw( LongReadLen sslmode ) ] ],
    ) {
      my ($label, $beside, $names) = @$case;
      my $t = "$class, $label beside a broker answering a dbh_maker";

      my $made = 0;
      my $storage = $class->new(undef);
      $storage->connect_info([ T::ScriptBroker->new($maker->(\$made)), { %$beside } ]);
      local @CONNECTS;
      throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', @$names),
        "$t: its own connection throws, naming the broker class and the names";
      unlike "$@", $VALUE, "$t: naming no value";
      is $made, 0, "$t: ... and the code is not run";
      is scalar @CONNECTS, 0, "$t: ... nor is DBI->connect called";
    }

    # what the storage consumes itself, and what names no parameter
    my $made = 0;
    my $storage = $class->new(undef);
    $storage->connect_info([ T::ScriptBroker->new($maker->(\$made)), {
      on_connect_do => [ 'SELECT 1' ], quote_names => 1, async => 'immediate',
      pool_size => 3, ignore_version => 1, sslmode => undef, connect_timeout => '',
    } ]);
    local @CONNECTS;
    lives_ok { $storage->_connect } "$class, only what the storage consumes beside a dbh_maker: connects";
    is $made, 1, '... through the code';

    # the options are looked at before the answer is set against them
    my $clash = sub { { dbh_maker => sub { T::Handle->new }, LongReadLen => 1 } };
    $storage = $class->new(undef);
    my $plain = sub { { dbh_maker => sub { T::Handle->new } } };   # connect_info asks it, and sets the conflict itself
    $storage->connect_info([ T::ScriptBroker->new($plain, $clash), { LongReadLen => 2 } ]);
    throws_ok { $storage->_connect } refused_beside('T::ScriptBroker', 'LongReadLen'),
      "$class: an option beside a dbh_maker answer is refused before it is set against the answer";
  }
}

done_testing;
