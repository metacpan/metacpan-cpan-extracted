package Beekeeper::Service::Sinkhole::Worker;

use strict;
use warnings;

our $VERSION = '0.05';

use AnyEvent::Impl::Perl;
use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::JSONRPC::Error;
use JSON::XS;


sub authorize_request {
    my ($self, $req) = @_;

    if ($req->{method} eq '_bkpr.sinkhole.unserviced_queues') {

        return unless $self->__has_authorization_token('BKPR_SYSTEM');
    }

    # All requests will be rejected by reject_job 
    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    $self->{Draining} = {};

    $self->accept_notifications(
        '_bkpr.sinkhole.unserviced_queues' => 'on_unserviced_queues',
    );

    my $local_bus = $self->{_BUS}->{bus_role};

    # Watch the Supervisor data traffic in order to stop rejecting
    # requests as soon as a worker handling these becomes online

    $self->{_BUS}->subscribe(
        topic      => "msg/$local_bus/_sync/workers/set",
        on_publish => sub {
            my ($payload_ref, $properties) = @_;
            $self->on_worker_status( decode_json($$payload_ref)->[1] );
        }
    );
}

sub log_handler {
    my $self = shift;

    # Use pool's logfile
    $self->SUPER::log_handler( foreground => 1 );
}

sub on_unserviced_queues {
    my ($self, $params) = @_;

    my $queues = $params->{queues};
 
    foreach my $queue (@$queues) {

        # Nothing to do if already draining $queue
        next if $self->{Draining}->{$queue};

        # As no one is processing requests, respond these with errors
        $self->{Draining}->{$queue} = 1;

        my $local_bus = $self->{_BUS}->{bus_role};
        log_error "Draining unserviced req/$local_bus/$queue";

        $self->accept_remote_calls( "$queue.*" => 'reject_job' );
    }
}

sub on_worker_status {
    my ($self, $status) = @_;

    return unless ($status->{queue});

    return if ($status->{class} eq 'Beekeeper::Service::Sinkhole::Worker');

    foreach my $queue (@{$status->{queue}}) {

        # Nothing to do if not draining queue
        next unless $self->{Draining}->{$queue};

        # A worker servicing a previously unserviced queue has just become
        # online, so do not respond with errors anymore
        delete $self->{Draining}->{$queue};

        my $local_bus = $self->{_BUS}->{bus_role};
        log_warn "Stopped draining req/$local_bus/$queue";

        $self->stop_accepting_calls( "$queue.*" );
    }
}

sub reject_job {
    my ($self, $params, $req) = @_;

    # Just return a JSONRPC error response

    if ($req->get_auth_tokens) {
        # When client provided some kind of authentication tell him the truth
        # about the service being down. Otherwise the one trying to fix the 
        # issue may be deceived into looking for auth/permissions problems
        return Beekeeper::JSONRPC::Error->method_not_available;
    }
    else {
        return Beekeeper::JSONRPC::Error->request_not_authorized;
    }
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::Service::Sinkhole::Worker - Handle unserviced call topics

=head1 VERSION
 
Version 0.05

=head1 DESCRIPTION

In the case of all workers of a given service being down, all requests sent to
the service will timeout as no one is serving them. This may cause a serious
disruption in the application, as any other service depending of the broken
one will halt too for the duration of the timeout.

In order to mitigate this situation all Sinkhole workers will be notified by
the Supervisor when unserviced topics are detected, making these to respond 
immediately to all requests with an error response. Then callers will quickly 
receive an error response instead of timing out.

As soon as a worker of the downed service becomes online again the Sinkhole
workers will stop rejecting requests.

A Sinkhole worker is created automatically in every worker pool, and it can 
handle around 500 req/s. Extra workers can simply be declared into config file.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
