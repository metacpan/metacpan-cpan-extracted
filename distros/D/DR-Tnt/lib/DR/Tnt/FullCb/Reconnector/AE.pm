use utf8;
use strict;
use warnings;

package DR::Tnt::FullCb::Reconnector::AE;
use Mouse;
use DR::Tnt::Dumper;
use DR::Tnt::LowLevel::Connector::AE;
use DR::Tnt::LowLevel;
use AnyEvent;

has fcb     => is => 'ro', isa => 'Object', weak_ref => 1;
has timer   => is => 'rw', isa => 'Maybe[Any]';

sub _tmr_cb {
    my ($self) = @_;
    sub {
        $self->timer(undef);
        return unless $self->fcb;
        return unless $self->fcb->state eq 'pause';
        $self->fcb->_log(info => 'Reinit connection');
        $self->fcb->restart(sub {
            my ($state) = @_;
            $self->fcb->request(ping => sub {  }) if $state eq 'OK';
        });
    }
}

sub event {
    my ($self, $event, $old_event) = @_;
    return unless defined $self->fcb->reconnect_interval;

    if ($event eq 'pause') {
        return if $self->timer;
        my $timer = AE::timer
                $self->fcb->reconnect_interval,
                0,
                $self->_tmr_cb
        ;
        $self->timer($timer);
        return;
    }
}

sub check_pause { 0 }

has ll  =>
    is          => 'ro',
    isa         => 'DR::Tnt::LowLevel',
    lazy        => 1,
    builder     => sub {
        my ($self) = @_;
        DR::Tnt::LowLevel->new(
            host            => $self->fcb->host,
            port            => $self->fcb->port,
            user            => $self->fcb->user,
            password        => $self->fcb->password,
            connector_class => 'DR::Tnt::LowLevel::Connector::AE',
            utf8            => $self->fcb->utf8,
        );
    };

sub _restart {
    my ($self, $cb) = @_;
    goto \&$cb;
}

__PACKAGE__->meta->make_immutable;
