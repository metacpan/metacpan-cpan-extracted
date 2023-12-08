package Database::Async::Pool;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.019'; # VERSION

=head1 NAME

Database::Async::Pool - connection manager for L<Database::Async>

=head1 DESCRIPTION

=cut

use Database::Async::Backoff::Exponential;
use Database::Async::Backoff::None;

use Future;
use Future::AsyncAwait qw(:experimental);
use Syntax::Keyword::Try;
use Scalar::Util qw(blessed refaddr);
use List::UtilsBy qw(extract_by);
use Log::Any qw($log);

sub new {
    my ($class, %args) = @_;
    my $backoff = delete $args{backoff};
    unless(blessed $backoff) {
        my $type = 'exponential';
        $type = $backoff if $backoff and not ref $backoff;
        $backoff = Database::Async::Backoff->instantiate(
            type          => $type,
            initial_delay => 0.010,
            max_delay     => 30,
            ($backoff && ref($backoff) ? %$backoff : ())
        )
    }
    bless {
        pending_count => 0,
        count         => 0,
        min           => 0,
        max           => 1,
        attempts      => undef,
        ordering      => 'serial',
        backoff       => $backoff,
        waiting       => [],
        ready         => [],
        %args
    }, $class
}

sub min { shift->{min} }
sub max { shift->{max} }
sub count { shift->{count} }
sub pending_count { shift->{pending_count} }
sub backoff { shift->{backoff} }

sub register_engine {
    my ($self, $engine) = @_;
    --$self->{pending_count};
    ++$self->{count};
    $self
}

sub unregister_engine {
    my ($self, $engine) = @_;
    try {
        $log->tracef('Engine is removed from the pool, with %d in the queue', 0 + @{$self->{waiting}});
        my $addr = refaddr($engine);
        # This engine may have been actively processing a request, and not in the pool:
        # that's fine, we only remove if we had it.
        my $count = () = extract_by { refaddr($_) == $addr } @{$self->{ready}};
        $log->tracef('Removed %d engine instances from the ready pool', $count);
        # Any engine that wasn't in the ready queue (`count`) was out on assignment
        # and thus included in `pending_count`
        --$self->{$count ? 'count' : 'pending_count'};
        $log->infof('After cleanup we have %d count, %d pending, %d waiting', $self->{count}, $self->{pending_count}, 0 + @{$self->{waiting}});
        $self->process_pending->retain if @{$self->{waiting}};
    } catch ($e) {
        $log->errorf('Failed %s', $e);
    }
    $self
}

=head2 queue_ready_engine

Called when there's a spare engine we can put back in the pool.

=cut

sub queue_ready_engine {
    my ($self, $engine) = @_;
    $log->tracef('Engine is now ready, with %d in the queue', 0 + @{$self->{waiting}});
    return $self->notify_engine($engine) if @{$self->{waiting}};
    push @{$self->{ready}}, $engine;
    $self
}

=head2 notify_engine

We call this internally to hand an engine over to the next
waiting request.

=cut

sub notify_engine {
    my ($self, $engine) = @_;
    die 'unable to notify, we have no pending requests'
        unless my $f = shift @{$self->{waiting}};
    $f->done($engine);
    return $self;
}

=head2 next_engine

Resolves to an engine. May need to wait if there are none available.

=cut

async sub next_engine {
    my ($self) = @_;
    $log->tracef('Have %d ready engines to use', 0 + @{$self->{ready}});
    if(my $engine = shift @{$self->{ready}}) {
        return $engine;
    }
    push @{$self->{waiting}}, my $f = $self->new_future;
    await $self->process_pending;
    return await $f;
}

async sub process_pending {
    my ($self) = @_;
    my $total = $self->count + $self->pending_count;
    $log->tracef('Might request, current count is %d/%d (%d pending, %d active)', $total, $self->max, $self->pending_count, $self->count);
    await $self->request_engine unless $total >= $self->max;
    return;
}

sub new_future {
    my ($self, $label) = @_;
    (
        $self->{new_future} //= sub {
            Future->new->set_label($_[1])
        }
    )->($label)
}

async sub request_engine {
    my ($self) = @_;
    $log->tracef('Pool requesting new engine');
    ++$self->{pending_count};
    my $delay = $self->backoff->next;
    if($delay) {
        my $f = $self->loop->delay_future(
            after => $delay
        );
        CANCEL { $f->cancel }
        await $f;
    }
    my $req = $self->{request_engine}->();
    CANCEL { $req->cancel }
    await $req;
    $self->backoff->reset;
}

sub _remove_from_loop {
    my ($self, $loop) = @_;
    $_->cancel for splice @{$self->{waiting}};
    $self->unregister_engine($_) for splice @{$self->{ready}};
    return $self->next::method($loop);
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2023. Licensed under the same terms as Perl itself.

