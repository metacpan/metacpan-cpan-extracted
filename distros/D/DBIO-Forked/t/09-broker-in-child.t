use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use IO::Select;

# OFFLINE test: the AccessBroker in the forked child (karr k15).
#
# WHY: Model A gets its AccessBroker support for nothing -- the child runs the
# owner sync storage, and that storage asks the broker again for the
# connection it opens (ADR 0002). t/06 shows the good case: the broker
# answers, the child connects with that answer. What the same mechanism does
# when the broker is NOT a constant was untested, and each case is a question
# an operator will ask:
#
#   1. the broker has nothing to give the child -- the lease ran out, the
#      vault is sealed. The Future must fail with what the broker (or core,
#      for it) said, and the child must not quietly connect with the connect
#      info the parent had.
#   2. the broker rotates its credentials. Core refuses a transaction through
#      such a broker; the refusal is raised by the sync txn_begin, which under
#      Model A runs in the child. It must come back as a failed Future -- and
#      queries outside a transaction must go on working.
#   3. the lease has expired and the child refreshes it. The child is a copy:
#      what it fetched dies with it. Every forked query reads the vault again,
#      and the parent's broker is none the wiser -- until the parent refreshes
#      on its own. That is Model A (no pool, no shared state) and no defect;
#      it is recorded here because it decides how often a vault is asked.
#   4. a *_async call inside a txn_do_async body, over core's storage: the POD
#      only says it "would fork again". What that means for the transaction:
#      the nested query runs on a connection of its own that never saw BEGIN.
#
# WHAT RUNS FOR REAL: fork + pipe + Storable, DBIO::Forked::Storage and its
# Future, core's DBIO::Schema, ResultSet and DBIO::Storage::DBI as the owner
# (broker attach, _verify_pid, _connect, txn_do, select, the cursor), core's
# DBIO::AccessBroker::Vault in sections 2 and 3.
# THE SUBSTITUTIONS: no DBD -- DBI->connect returns a fake handle whose one
# result row is [ pid, user ]: the process the statement ran in and the user
# its connection logged in as. No vault -- the Vault broker reads its secret
# from a stub. Both report what they do on a pipe every process shares, so the
# parent sees what a child did even when the child's answer is an error.

use DBI ();
use DBIO::Schema;
use DBIO::Core;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::Forked;

plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243)'
  unless DBIO::Storage::Async->can('_takes_broker_connect_options');

alarm 60;

# --- the report pipe: one line per event, written by whichever process the
# --- event happens in. A line is far below PIPE_BUF, so it arrives whole.
pipe(my $REPORT_R, my $REPORT_W) or die "pipe: $!";

sub report {
  my $line = join(' ', @_) . "\n";
  my $written = syswrite($REPORT_W, $line);
  die "report: $!" unless defined $written && $written == length $line;
}

# Everything reported since the last call, by any process, in order:
# { what, pid, args }.
sub reported {
  my $select = IO::Select->new($REPORT_R);
  my $text   = '';
  while ($select->can_read(0)) {
    sysread($REPORT_R, my $chunk, 65536) or last;
    $text .= $chunk;
  }
  return map {
    my ($what, $pid, @args) = split ' ', $_;
    { what => $what, pid => $pid, args => \@args };
  } split /\n/, $text;
}

sub of { my $what = shift; grep { $_->{what} eq $what } @_ }

# --- the owner: core's sync storage and a schema with one source.
{
  package T::Probe::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ForkedProbe => __PACKAGE__);

  package T::Probe::Result::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw( id name ));
  __PACKAGE__->set_primary_key('id');

  package T::Probe::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::Probe::Storage');
  __PACKAGE__->register_class(Artist => 'T::Probe::Result::Artist');
}

# --- the handle DBI->connect returns, and its statements. Every connection
# --- has a name of its own (pid.serial), so two of them in one process, or
# --- one inherited across a fork, can be told apart.
{
  package T::Probe::STH;
  sub new { my ($class, $dbh) = @_; bless { dbh => $dbh, rows => [] }, $class }
  sub bind_param { 1 }
  sub execute {
    my $self = shift;
    main::report(execute => $$, $self->{dbh}{conn});
    $self->{rows} = [ [ $$, $self->{dbh}{user} ] ];
    return 1;
  }
  sub fetchall_arrayref { my $rows = $_[0]{rows}; $_[0]{rows} = []; $rows }
  sub fetchrow_array    { my $row = shift @{ $_[0]{rows} }; $row ? @$row : () }
  sub finish            { 1 }

  package T::Probe::DBH;
  my $serial = 0;
  sub new {
    my ($class, $user) = @_;
    bless {
      Active     => 1,
      AutoCommit => 1,
      RaiseError => 1,
      Driver     => { Name => 'ForkedProbe' },
      user       => $user,
      conn       => "$$." . ++$serial,
    }, $class;
  }
  sub FETCH          { $_[0]{ $_[1] } }
  sub ping           { 1 }
  sub prepare        { T::Probe::STH->new($_[0]) }
  sub prepare_cached { T::Probe::STH->new($_[0]) }
  sub begin_work     { main::report(begin  => $$, $_[0]{conn}); $_[0]{AutoCommit} = 0; 1 }
  sub commit         { main::report(commit => $$, $_[0]{conn}); $_[0]{AutoCommit} = 1; 1 }
  sub rollback       { $_[0]{AutoCommit} = 1; 1 }
  sub disconnect     { $_[0]{Active} = 0; 1 }
}

{
  no warnings qw(redefine once);
  *DBI::connect = sub {
    my (undef, $dsn, $user) = @_;
    my $dbh = T::Probe::DBH->new($user);
    main::report(connect => $$, $dbh->{conn}, $user);
    return $dbh;
  };
}

# A broker that answers until it is told it has run dry -- a lease that is
# gone, a vault that is sealed. A forked child inherits it in that state.
{
  package T::DryBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answers => 0, dry => '' }, shift }
  sub is_transaction_safe { 1 }
  sub connect_info_for {
    my $self = shift;
    die "the vault is sealed\n" if $self->{dry} eq 'throws';
    return undef                if $self->{dry} eq 'answers nothing';
    return [ 'dbi:ForkedProbe:dbname=app', 'user_' . ++$self->{answers}, 'p', {} ];
  }
}

# What DBIO::AccessBroker::Vault reads its secret from. Every read is a new
# lease, named after its number in this process and the process that took it.
{
  package T::StubVault;
  sub new { bless { reads => 0 }, shift }
  sub read_secret {
    my ($self, $path) = @_;
    my $n = ++$self->{reads};
    main::report(vault => $$, $n);
    return { username => "lease${n}_taken_by_$$", password => 'p' };
  }
}

sub vault_schema {
  my $vault  = T::StubVault->new;
  my $broker = DBIO::AccessBroker::Vault->new(
    vault          => $vault,
    dsn            => 'dbi:ForkedProbe:dbname=app',
    cred_path      => 'database/creds/app',
    ttl            => 3600,
    refresh_margin => 0,
  );
  my $schema = T::Probe::Schema->connect($broker, { async => 'forked' });
  return ($schema, $broker, $vault);
}

sub no_children_ok {
  my ($name) = @_;
  is waitpid(-1, WNOHANG), -1, $name;
}

sub in_child_ok {
  my ($pid, $name) = @_;
  ok defined $pid && $pid =~ /^\d+\z/ && $pid != $$, $name;
}

# The one row of a forked SELECT, through core's ResultSet -- all_async is
# select_async plus the inflation -- as [ pid it ran in, user it ran as ].
sub forked_select {
  my ($schema) = @_;
  my @rows = $schema->resultset('Artist')->all_async->get;
  die 'expected one row, got ' . scalar @rows unless @rows == 1;
  return [ $rows[0]->id, $rows[0]->name ];
}

# ---------------------------------------------------------------------------
# 0. Control: a broker that answers. The fixture, before anything is claimed
#    with it.
# ---------------------------------------------------------------------------
{
  my $broker = T::DryBroker->new;
  my $schema = T::Probe::Schema->connect($broker, { async => 'forked' });
  $schema->storage->ensure_connected;
  my ($parent_connect) = of(connect => reported());

  my $row = eval { forked_select($schema) };
  is $@, '', 'control: a forked SELECT through an answering broker works';
  in_child_ok($row->[0], 'control: it ran in a child');

  my @connects = of(connect => reported());
  is scalar @connects, 1, 'control: the child opened one connection';
  is $connects[0]{pid}, $row->[0], '... its own';
  is $connects[0]{args}[1], $row->[1], '... and the SELECT ran as the user of that connection';
  isnt $row->[1], $parent_connect->{args}[1], '... a later answer of the broker than the parent\'s';
  no_children_ok('control: reaped');
}

# ---------------------------------------------------------------------------
# 1. The broker has nothing to give the child.
# ---------------------------------------------------------------------------
for my $case (
  [ 'answers nothing', qr/AccessBroker T::DryBroker answered no connect info \(undef\)/ ],
  [ 'throws',          qr/the vault is sealed/ ],
) {
  my ($how, $refusal) = @$case;

  my $broker = T::DryBroker->new;
  my $schema = T::Probe::Schema->connect($broker, { async => 'forked' });
  $schema->storage->ensure_connected;      # the parent has a connection, and connect info to go with it
  reported();
  $broker->{dry} = $how;

  # Nothing is refused at the call: the parent asks the broker nothing.
  my $f = $schema->resultset('Artist')->all_async;

  my @rows = eval { $f->get };
  like $@, $refusal, "broker $how: get throws what was said in the child";
  like $@, qr/never with the connect info of an earlier one/,
    '... core\'s refusal, word for word' if $how eq 'answers nothing';
  ok $f->is_failed, "broker $how: the Future is failed";
  is_deeply \@rows, [], "broker $how: no rows";

  is scalar(of(connect => reported())), 0,
    "broker $how: the child opened no connection -- not with the parent's connect info either";
  no_children_ok("broker $how: the child was reaped");
}

# ---------------------------------------------------------------------------
# 2. A broker that rotates its credentials: no transaction, CRUD goes on.
# ---------------------------------------------------------------------------
{
  delete local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS};   # core's override; would lift the refusal

  my ($schema, $broker) = vault_schema();
  die 'fixture: the Vault broker is expected to rotate and to be unsafe for transactions'
    unless $broker->has_rotating_credentials && !$broker->is_transaction_safe;
  $schema->storage->ensure_connected;
  reported();

  my $unsafe = qr/Refusing to start a transaction with unsafe AccessBroker DBIO::AccessBroker::Vault: credential rotation can break transactional consistency/;

  my $f = eval { $schema->storage->txn_do_async(sub { report(body => $$); return 'ran' }) };
  is $@, '', 'rotating broker: txn_do_async itself does not throw';
  isa_ok $f, 'DBIO::Forked::Future', 'rotating broker: the answer';
  ok !eval { $f->get; 1 }, 'rotating broker: get throws';
  like $@, $unsafe, '... core\'s refusal of a transaction through an unsafe broker';
  ok $f->is_failed, '... as a failed Future';

  my @seen = reported();
  is scalar(of(body  => @seen)), 0, 'rotating broker: the transaction body never ran';
  is scalar(of(begin => @seen)), 0, 'rotating broker: no BEGIN was sent, in any process';
  no_children_ok('rotating broker: the refused child was reaped');

  ok !eval { $schema->storage->txn_do(sub { 1 }); 1 } && $@ =~ $unsafe,
    'the same refusal the sync txn_do gives in the parent';

  my $row = eval { forked_select($schema) };
  is $@, '', 'rotating broker: a forked SELECT outside a transaction still works';
  in_child_ok($row->[0], '... in a child');
  is $row->[1], "lease1_taken_by_$$", '... as the user of the lease the parent holds';
  no_children_ok('rotating broker: reaped');
}

# ---------------------------------------------------------------------------
# 3. A refresh in the child never reaches the parent.
# ---------------------------------------------------------------------------
{
  my ($schema, $broker, $vault) = vault_schema();
  $schema->storage->ensure_connected;
  my $parent_lease = "lease1_taken_by_$$";

  my @seen = reported();
  is scalar(of(vault => @seen)), 1, 'the parent read the vault once, for its own connection';
  is $broker->_current_username, $parent_lease, '... and holds that lease';

  # While the lease is good a child has no reason to ask the vault.
  my $row = forked_select($schema);
  @seen = reported();
  is $row->[1], $parent_lease, 'lease good: the child connects with the lease it inherited';
  is scalar(of(vault => @seen)), 0, 'lease good: nobody reads the vault';

  # The lease runs out -- by setting the expiry the broker compares the clock
  # with, not by waiting for it.
  $broker->_expires_at(time - 1);
  ok $broker->needs_refresh, 'the lease has expired';

  # Three queries at once, collected afterwards.
  my @futures = map { $schema->resultset('Artist')->all_async } 1 .. 3;
  my @rows    = map { my ($r) = $_->get; [ $r->id, $r->name ] } @futures;
  @seen = reported();

  my %child = map { $_->[0] => 1 } @rows;
  is scalar(keys %child), 3, 'lease expired: three queries, three children';
  ok !$child{$$}, '... none of them this process';

  my @reads = of(vault => @seen);
  is scalar @reads, 3, 'lease expired: the vault was read three times -- once per forked query';
  is_deeply [ sort map { $_->{pid} } @reads ], [ sort keys %child ],
    '... by each child for itself';
  is_deeply [ map { $_->[1] } @rows ], [ map { "lease2_taken_by_$_->[0]" } @rows ],
    '... and each child ran as the user of the lease IT took';

  is $vault->{reads}, 1, 'the parent has still read the vault once';
  is $broker->_current_username, $parent_lease, 'the parent still holds the expired lease';
  ok $broker->needs_refresh, '... and still considers it expired: the next query will read again';

  # Only a refresh in the parent ends it: its children inherit the new lease.
  $schema->storage->disconnect;
  $schema->storage->ensure_connected;
  reported();
  is $vault->{reads}, 2, 'the parent reconnects: it reads the vault itself, once';

  $row  = forked_select($schema);
  @seen = reported();
  is $row->[1], "lease2_taken_by_$$", 'afterwards a child connects with the lease the parent took';
  is scalar(of(vault => @seen)), 0, '... and reads nothing';

  no_children_ok('refresh: every child reaped');
}

# ---------------------------------------------------------------------------
# 4. A *_async call inside a txn_do_async body, over core's storage.
#
# Recorded, not endorsed: the POD tells the caller not to. Nothing stops it.
# ---------------------------------------------------------------------------
{
  my $broker = DBIO::AccessBroker::Static->new(
    host => 'db.example', dbname => 'appdb', username => 'app', password => 's3cret',
  );
  my $schema = T::Probe::Schema->connect($broker, { async => 'forked' });
  $schema->storage->ensure_connected;
  reported();

  my $got = eval {
    $schema->storage->txn_do_async(sub {
      my $nested = forked_select($schema);     # *_async, from within the transaction
      return { body_pid => $$, nested_pid => $nested->[0] };
    })->get;
  };
  is $@, '', 'a *_async call in a txn_do_async body is not refused';

  my ($body, $nested) = @{ $got || {} }{qw( body_pid nested_pid )};
  in_child_ok($body,   'the body ran in a child');
  in_child_ok($nested, 'the nested query ran in a child, too');
  isnt $nested, $body, '... a third process, forked from within the transaction';

  my @seen     = reported();
  my ($begin)  = of(begin   => @seen);
  my ($commit) = of(commit  => @seen);
  my ($query)  = of(execute => @seen);

  is $begin->{pid}, $body, 'BEGIN was sent by the child the body runs in';
  is $commit && $commit->{args}[0], $begin->{args}[0], '... and COMMIT on the same connection';
  isnt $query->{args}[0], $begin->{args}[0],
    'the nested statement ran on a connection of its own, not the one the transaction is on';
  is scalar(grep { $_->{args}[0] eq $query->{args}[0] } of(begin => @seen)), 0,
    '... which never saw BEGIN: the nested query is outside the transaction';

  no_children_ok('nested: this process is left with nothing to reap');
}

done_testing;
