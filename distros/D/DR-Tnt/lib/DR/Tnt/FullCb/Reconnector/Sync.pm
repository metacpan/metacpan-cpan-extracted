use utf8;
use strict;
use warnings;

package DR::Tnt::FullCb::Reconnector::Sync;
use Mouse;
use Time::HiRes;
use DR::Tnt::LowLevel::Connector::Sync;
use DR::Tnt::LowLevel;

has fcb => is => 'ro', isa => 'Object', weak_ref => 1;
has pause_started =>
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    writer  => '_set_pause_started';

sub event {
    my ($self, $state, $old_state) = @_;
    return unless $self->fcb;
    return unless defined $self->fcb->reconnect_interval;
    if ($state eq 'pause' and $old_state ne 'pause') {
        $self->_set_pause_started(Time::HiRes::time);
        return;
    }
}

sub _restart {
    my ($self, $cb, $cbc) = @_;

    $cb->();
    while ($cbc->()) {
        $cb->();
    }
}

sub check_pause {
    my ($self) = @_;
    return unless $self->fcb;
    return unless defined $self->fcb->reconnect_interval;
    my $now = Time::HiRes::time;
    my $pause = $self->fcb->reconnect_interval - ($now - $self->pause_started);
    Time::HiRes::sleep $pause if $pause > 0;
    $self->_set_pause_started(Time::HiRes::time);
}

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
            connector_class => 'DR::Tnt::LowLevel::Connector::Sync',
            utf8            => $self->fcb->utf8,
        );
    };

__PACKAGE__->meta->make_immutable;

