use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k331 (finding 2 of the 2026-10-08 async review, k275). _run_crud derives
# the Future of insert/update/delete (and select_single, and select under
# software_limit) from the one the transport's query seam returns, with
# ->then. With Future.pm that derived Future is a sequence the transport's own
# Future holds only weakly; its caller is its only holder. A caller that does
# not keep it -- a pooled insert_async in void context, a statement dropped
# inside a pipeline batch whose coderef waits for nothing but the sync --
# freed it on the spot, and Future.pm said so when the answer came: "lost a
# sequence Future", once per statement. karr k292 closed the same hole for a
# transaction context's statements; _run_crud is where these two are derived.
#
# The claims, for the pooled runner and for a pipeline batch alike:
#
#   * a statement nobody keeps still runs: its SQL went to the wire, and its
#     answer arrives without a warning;
#   * the Future is let go of once answered, whether it was answered or
#     failed -- nothing is retained for good;
#   * a caller that does keep the Future gets the same value (or the same
#     error) as before: retaining it changes nothing for a holder.
#
# Mock only: a fake wire whose Futures are settled by the test.

{
  package K331::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]->{_next_id} }, 'K331::Conn' }
}

{
  package K331::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{fc} }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K331::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  # What a transport's query seam hands back: a ->then sequence off a Future
  # the wire keeps and the test settles later.
  sub _wire {
    my ($self, $sql) = @_;
    my $fc = $self->future_class;
    push @{ $self->{captured} }, $sql;
    my $source = $fc->new;
    push @{ $self->{held} }, $source;
    return $source->then(sub { return $fc->new->done(@_) });
  }

  sub _query_async        { $_[0]->_wire($_[1]) }
  sub _query_async_pinned { $_[0]->_wire($_[2]) }

  sub _pipeline_enter { 1 }
  sub _pipeline_sync  { $_[0]->future_class->new->done }
  sub _pipeline_exit  { 1 }

  # Answer everything the wire holds; a defined {fail} fails it instead.
  sub answer_held {
    my ($self) = @_;
    while (my $source = shift @{ $self->{held} || [] }) {
      defined $self->{fail} ? $source->fail($self->{fail}) : $source->done([ 1 ]);
    }
    return;
  }
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub new_backend {
  my ($fc) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K331::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->{fc} = $fc;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  return $backend;
}

my %call = (
  insert => sub { $_[0]->insert_async('artist', { name => 'x' }) },
  update => sub { $_[0]->update_async('artist', { name => 'y' }, { artistid => 1 }) },
  delete => sub { $_[0]->delete_async('artist', { artistid => 1 }) },
  select_single => sub {
    $_[0]->select_single_async('artist', ['artistid'], { artistid => 1 }, {})
  },
  select_software_limit => sub {
    $_[0]->select_async('artist', ['artistid'], {}, { rows => 1, software_limit => 1 })
  },
);

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { diag 'Future.pm not installed: the class the bug shows under is not run' }

for my $fc (@future_classes) {
  for my $road (qw(pooled pipeline)) {
    for my $op (sort keys %call) {
      for my $fails (0, 1) {
        my $l = "$fc, $road, $op" . ($fails ? ', the answer fails' : '');
        my $backend = new_backend($fc);
        $backend->{fail} = "the wire failed\n" if $fails;

        my ($weak, $batch);
        my $drop = sub {
          my ($target) = @_;
          my $f = $call{$op}->($target);
          weaken($weak = $f);        # the test's own reference is weak
          return;                    # ... and $f goes: nobody keeps it
        };
        if ($road eq 'pooled') {
          $drop->($backend);
        }
        else {
          $batch = $backend->pipeline(sub { $drop->($_[0]); return 1 });
        }

        is scalar @{ $backend->{captured} }, 1, "$l: the statement went to the wire";
        ok defined $weak, "$l: its Future is still there, nobody keeping it";
        is_deeply [ splice @warnings ], [], "$l: nothing warned while it is in flight";

        $backend->answer_held;
        is_deeply [ splice @warnings ], [], "$l: its answer arrives: nothing warns";
        ok !defined $weak, "$l: ... and its Future is let go of";
      }
    }
  }

  # A caller that keeps the Future gets its value, and is not affected.
  {
    my $l = "$fc, a caller that keeps the Future";
    my $backend = new_backend($fc);
    my $f = $call{update}->($backend);
    $backend->answer_held;
    ok $f->is_ready, "$l: it is answered";
    is scalar(() = $f->get), 1, "$l: ... with its one value";
    is_deeply [ splice @warnings ], [], "$l: nothing warned";

    $backend->{fail} = "the wire failed\n";
    my $g = $call{insert}->($backend);
    $backend->answer_held;
    eval { $g->get; 1 };
    like $@, qr/the wire failed/,
      "$l: a failure still reaches the holder, with its error";
    is_deeply [ splice @warnings ], [], "$l: nothing warned";
  }
}

done_testing;
