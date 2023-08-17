package Beekeeper::Service::Supervisor;

use strict;
use warnings;

our $VERSION = '0.10';

use Beekeeper::Client;

# Show errors from perspective of caller
$Carp::Internal{(__PACKAGE__)}++;


sub restart_pool {
    my ($class, %args) = @_;

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');

    $client->send_notification(
        method => '_bkpr.supervisor.restart_pool',
        params => \%args,
    );
}

sub restart_workers {
    my ($class, %args) = @_;

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');

    $client->send_notification(
        method => '_bkpr.supervisor.restart_workers',
        params => \%args,
    );
}

sub get_workers_status {
    my ($class, %args) = @_;

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');
    my $timeout = delete $args{'timeout'};

    my $resp = $client->call_remote(
        method  => '_bkpr.supervisor.get_workers_status',
        params  => \%args,
        timeout => $timeout,
    );

    return $resp->result;
}

sub get_workers_status_async {
    my ($class, %args) = @_;

    my $on_success = delete $args{'on_success'};
    my $on_error   = delete $args{'on_error'};

    unless ($on_error) {
        my ($file, $line) = (caller)[1,2];
        $on_error = sub { die $_[0]->message . " at $file line $line\n"; };
    }

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');
    my $timeout = delete $args{'timeout'};

    $client->call_remote_async(
        method     => '_bkpr.supervisor.get_workers_status',
        params     => \%args,
        timeout    => $timeout,
        on_success => $on_success,
        on_error   => $on_error,
    );
}

sub get_services_status {
    my ($class, %args) = @_;

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');
    my $timeout = delete $args{'timeout'};

    my $resp = $client->call_remote(
        method  => '_bkpr.supervisor.get_services_status',
        params  => \%args,
        timeout => $timeout,
    );

    return $resp->result;
}

sub get_services_status_async {
    my ($class, %args) = @_;

    my $on_success = delete $args{'on_success'};
    my $on_error   = delete $args{'on_error'};

    unless ($on_error) {
        my ($file, $line) = (caller)[1,2];
        $on_error = sub { die $_[0]->message . " at $file line $line\n"; };
    }

    my $client = Beekeeper::Client->instance;
    my $guard = $client->__use_authorization_token('BKPR_ADMIN');
    my $timeout = delete $args{'timeout'};

    $client->call_remote_async(
        method     => '_bkpr.supervisor.get_services_status',
        params     => \%args,
        timeout    => $timeout,
        on_success => $on_success,
        on_error   => $on_error,
    );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::Supervisor - Worker pool supervisor

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

  my $status = Beekeeper::Service::Supervisor->get_services_status(
      host => '.*',
      pool => '.*',
      pool => '.*',
  );
  
  print "$_: $status->{$_}->{load}\n" foreach keys %$status;
  
  Beekeeper::Service::Supervisor->get_services_status(
      on_success => sub {
          my ($status) = @_;
          print "$_: $status->{$_}->{load}\n" foreach keys %$status;
      },
      on_error => sub {
          my ($error) = @_;
          die $error->message;
      },
  );

=head1 DESCRIPTION

A Supervisor worker is created automatically in every worker pool.

It keeps a shared table of the performance metrics of every worker connected to
every broker, and routinely measures the CPU and memory usage of local workers.

These metrics can be queried using the methods provided by this module or using
the command line client L<bkpr-top>.

=head3 Reported performance metrics

=over

=item nps

Number of received notifications per second.

=item cps

Number of processed calls per second.

=item err

Number of errors per second generated while handling calls or notifications.

=item mem

Resident non shared memory size in KiB. This is roughly equivalent to the value
of C<RES> minus C<SHR> displayed by C<top>.

=item cpu

Percentage of CPU load (100 indicates a full utilization of one core thread).

=item load

Percentage of busy time (100 indicates no idle time).

Note that workers can have a high load with very little CPU usage when being
blocked by synchronous operations (like slow SQL queries, for example).

Due to inaccuracies of measurement the actual maximum may be slightly below 100.

=back

=head1 METHODS

=head3 get_services_status ( %filters )

Returns the aggregate performance metrics of all active services.

Services can be filtered by C<host>, C<pool> and  C<class>.

=head3 get_workers_status ( %filters )

Returns the individual performance metrics of every worker of all active services.

Services can be filtered by C<host>, C<pool> and  C<class>.

=head3 get_services_status_async ( %filters, on_success => $cb, on_error => $cb )

Asynchronous version of C<get_services_status> method.

Callbacks C<on_success> and C<on_error> must be coderefs and will receive respectively 
L<Beekeeper::JSONRPC::Response> and L<Beekeeper::JSONRPC::Error> objects as arguments.

=head3 get_workers_status_async ( %filters, on_success => $cb, on_error => $cb )

Asynchronous version of C<get_workers_status> method.

=head1 SEE ALSO
 
L<bkpr-top>, L<bkpr-restart>, L<Beekeeper::Service::Supervisor::Worker>.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2023 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
