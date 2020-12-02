package Database::Async::Pool;

use strict;
use warnings;

our $VERSION = '0.013'; # VERSION

=head1 NAME

Database::Async::Pool - connection manager for L<Database::Async>

=head1 DESCRIPTION

=cut

use Database::Async::Backoff;

use Future;
use Scalar::Util qw(blessed);
use Log::Any qw($log);

sub new {
    my ($class, %args) = @_;
    my $backoff = delete $args{backoff};
    unless(blessed $backoff) {
        my $type = 'exponential';
        $type = $backoff if $backoff and not ref $backoff;
        $backoff = Database::Async::Backoff->new(
            type    => $type,
            initial => 0.010,
            max     => 30,
            ($backoff && ref($backoff) ? %$backoff : ())
        )
    }
    bless {
        pending_count => 0,
        count         => 0,
        min           => 0,
        max           => 1,
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
    --$self->{count};
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

sub next_engine {
    my ($self) = @_;
    $log->tracef('Have %d ready engines to use', 0 + @{$self->{ready}});
    if(my $engine = shift @{$self->{ready}}) {
        return Future->done($engine)
    }
    push @{$self->{waiting}}, my $f = $self->new_future;
    my $total = $self->count + $self->pending_count;
    $log->tracef('Might request, current count is %d/%d (%d pending, %d active)', $total, $self->max, $self->pending_count, $self->count);
    $self->request_engine unless $total >= $self->max;
    return $f;
}

sub new_future {
    my ($self, $label) = @_;
    (
        $self->{new_future} //= sub {
            Future->new->set_label($_[1])
        }
    )->($label)
}

sub request_engine {
    my ($self) = @_;
    $log->tracef('Pool requesting new engine');
    ++$self->{pending_count};
    $self->{request_engine}->()
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

