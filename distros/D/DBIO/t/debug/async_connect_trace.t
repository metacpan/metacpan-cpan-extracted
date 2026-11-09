use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;
use DBIO::Storage::Statistics;

# The statements of the connect and disconnect actions on a pool connection are
# traced like those of the sync path (ADR 0025 addendum, karr k405): in the
# fingerprint form of the statement text (***[sha256:<8 hex>] for a secret), from
# level 1 on, query_start before and query_end after the statement; level 0
# traces nothing. The row queries of a connect_call_* (dbio_rows) are not
# traced and still return their rows.

{
  package T405C::Owner;
  use base 'DBIO::Test::Storage';

  sub connect_call_ask_rows {
    my ($self) = @_;
    $self->{asked} = $self->_pool_connect_rows('SELECT secret FROM vault WHERE token = ?', 'tok');
  }
}

{
  package T405C::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { 'DBIO::Future::Immediate' }

  sub _run_pool_connect_statement {
    my ($self, $conn, $sql, $attrs, @bind) = @_;
    push @{ $self->{ran} }, [ $sql, $attrs, @bind ];
    return [ [ 'row-value' ] ] if ref $attrs eq 'HASH' && $attrs->{dbio_rows};
    return;
  }
}

{
  package T405C::Schema;
  use base 'DBIO::Schema';
}

T405C::Schema->storage_type('+T405C::Owner');
my $schema = T405C::Schema->connect(sub { });
$schema->storage(T405C::Owner->new($schema));
my $owner = $schema->storage;

my $secret = 'hunter2-Passphrase';
$owner->on_connect_do([ "SET PASSWORD = '$secret'", 'SELECT 1' ]);
$owner->on_disconnect_do([ "SET PASSWORD = '$secret'" ]);

my $out = '';
open my $fh, '>', \$out or die;
my @ended;
{
  package T405C::Stats;
  our @ISA = ('DBIO::Storage::Statistics');
  sub query_end { my $s = shift; push @ended, $_[0]; $s->SUPER::query_end(@_) }
}
my $stats = T405C::Stats->new;
$stats->debugfh($fh);
$owner->debugobj($stats);

my $backend = T405C::Backend->new($schema);
$backend->_owner_storage($owner);
$owner->_async_context_owner_token($backend->_context_owner_token);

sub run {
  my ($level, $what) = @_;
  $backend->{debug} = $level;
  $backend->{ran}   = [];
  $out = '';
  @ended = ();
  $backend->$what('conn');
}

for my $what (qw(_setup_pool_connection _teardown_pool_connection)) {
  run(0, $what);
  is $out, '', "$what: level 0 traces nothing";
  ok scalar(@{ $backend->{ran} }), "$what: the statements ran";

  for my $level (1, 2) {
    run($level, $what);
    my @prints = $out =~ /SET PASSWORD = \*\*\*\[sha256:([0-9a-f]{8})\]/g;
    is scalar(@prints), 1, "$what, level $level: the secret statement is traced as its fingerprint";
    unlike $out, qr/\Q$secret\E/, "$what, level $level: the secret is not in the trace";
    is scalar(grep { /^SET PASSWORD = \*\*\*\[sha256:$prints[0]\]$/ } @ended), 1,
      "$what, level $level: query_end follows with the same text";
    unlike join("\n", @ended), qr/\Q$secret\E/, "$what, level $level: query_end carries no secret";
    my ($wire) = grep { $_->[0] =~ /PASSWORD/ } @{ $backend->{ran} };
    like $wire->[0], qr/\Q$secret\E/, "$what, level $level: the statement on the wire is unchanged";
  }
}

# a row query of a connect_call_* is not traced and returns its rows
{
  $owner->on_connect_call('ask_rows');
  $owner->on_connect_do([]);
  run(2, '_setup_pool_connection');
  is $out, '', 'a dbio_rows query is not traced';
  is_deeply \@ended, [], 'and has no query_end';
  is_deeply $owner->{asked}, [ [ 'row-value' ] ], 'it returns the rows of the runner';
}

done_testing;
