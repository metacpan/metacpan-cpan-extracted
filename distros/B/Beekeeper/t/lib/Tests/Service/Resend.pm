package Tests::Service::Resend;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Time::HiRes 'sleep';

=pod

=head1 Test worker

Simple worker used to test Beekeeper framework.

=cut

sub on_startup {
    my $self = shift;

    $self->accept_notifications(
        'test.pause'  => 'pause',
        'test.wakeup' => 'wakeup',
        'test.resume' => 'resume',
    );

    $self->accept_jobs(
        'test.sleep'  => 'sleeep',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return REQUEST_AUTHORIZED;
}

sub sleeep {
    my ($self, $params) = @_;

    sleep $params;

    1;
}

sub pause {
    my ($self, $params) = @_;

    $self->stop_accepting_notifications('test.pause','test.resume');

    $self->stop_accepting_jobs('test.*');
}

sub wakeup {
    my ($self, $params) = @_;

    $self->accept_notifications(
        'test.resume' => 'resume',
    );
}

sub resume {
    my ($self, $params) = @_;

    $self->accept_notifications(
        'test.pause' => 'pause',
    );

    $self->accept_jobs(
        'test.sleep'  => 'sleeep',
    );
}

1;
