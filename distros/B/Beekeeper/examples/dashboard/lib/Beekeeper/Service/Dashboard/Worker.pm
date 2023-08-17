package 
    Beekeeper::Service::Dashboard::Worker;   # hide from PAUSE

use strict;
use warnings;

our $VERSION = '0.10';

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::Worker::Extension::RemoteSession;
use Beekeeper::Service::Supervisor;
use Beekeeper::Service::LogTail;
use Beekeeper::Config;

use AnyEvent;
use JSON::XS;
use Scalar::Util 'weaken';
use Digest::SHA 'sha256_hex';
use Fcntl qw(:DEFAULT :flock);
use Time::HiRes;

use constant AVERAGE => 0;
use constant MAXIMUM => 1;
use constant TOTAL   => 2;
use constant COUNT   => 3;
use constant TSTAMP  => 0;
use constant STATS   => 1;


sub authorize_request {
    my ($self, $req) = @_;

    # Explicitly authorize the login method
    return BKPR_REQUEST_AUTHORIZED if $req->{method} eq 'bkpr.dashboard.login';

    # Require an user logged in for any other request
    return unless $self->get_authentication_data;

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my ($self) = @_;

    my $config = Beekeeper::Config->read_config_file( 'dashboard.config.json' );
    $self->{config} = $config || {};

    unless ($config) {
        log_warn "Couldn't read config file 'dashboard.config.json'";
    }

    unless ($config && $config->{users} && %{$config->{users}}) {
        log_warn "No users defined into config file 'dashboard.config.json'";
    }

    $self->accept_remote_calls(
        'bkpr.dashboard.login'    => 'login',
        'bkpr.dashboard.services' => 'service_stats',
        'bkpr.dashboard.logs'     => 'log_tail',
    );

    $self->_init_collector;

    log_info "Ready";
}

sub on_shutdown {
    my ($self) = @_;

    $self->_save_state;

    log_info "Stopped";
}

sub stop_working {
    my ($self) = @_;

    delete $self->{collect_tmr};
    delete $self->{consolidate_5s_tmr};
    delete $self->{consolidate_1m_tmr};

    $self->SUPER::stop_working;
}

sub login {
    my ($self, $params) = @_;

    my $username = $params->{username};
    my $password = $params->{password};

    AUTH: {

        last unless defined $username;
        last unless defined $password;

        my $users_cfg = $self->{config}->{users};
        my $pwd_hash  = sha256_hex('Dashboard'.$username.$password);

        last unless $users_cfg;
        last unless $users_cfg->{$username};
        last unless $users_cfg->{$username}->{'password'};
        last unless $users_cfg->{$username}->{'password'} eq $pwd_hash;

        # Set authentication data and assign an address to the user
        $self->set_authentication_data( $username );
        $self->bind_remote_session( address => "frontend.dashboard-$username" );

        return 1;
    }

    Beekeeper::JSONRPC::Error->request_not_authenticated;
}

sub service_stats {
    my ($self, $params, $req) = @_;

    my $resol = $params->{'resolution'} || '1s';
    my $count = $params->{'count'}      || 1;
    my $class = $params->{'class'};
    my $after = $params->{'after'};

    $req->deflate_response;

    my $stats = $self->{"services_$resol"} or die "Invalid resolution";

    my $idx = @$stats - $count;
    $idx = 0 if $idx < 0;

    if ($after) {
        my $min = $idx;
        my $new_data;
        for (my $i = @$stats - 1; $i >= 0; $i--) {
            last if $stats->[$i]->[TSTAMP] <= $after;
            last if $i < $min;
            $new_data = $i;
        }
        return [] unless $new_data;
        $idx = $new_data;
    }

    unless ($class) {
        return [ @$stats[$idx..(@$stats - 1)] ];
    }

    my @svc_stats;

    foreach my $st (@$stats[$idx..(@$stats - 1)]) {
        next unless exists $st->[STATS]->{$class};
        push @svc_stats, [ $st->[TSTAMP], $st->[STATS]->{$class} ];
    }

    return \@svc_stats;
}

sub log_tail {
    my ($self, $params, $req) = @_;

    my %filters;

    foreach my $filter (qw'service count level after host pool message') {
        next unless $params->{$filter};
        $filters{$filter} = $params->{$filter};
    }

    $req->async_response;
    $req->deflate_response;

    Beekeeper::Service::LogTail->tail_async(
        %filters,
        on_success => sub {
            my ($resp) = @_;
            $req->send_response( $resp->result );
        },
        on_error => sub {
            my ($resp) = @_;
            $req->send_response( $resp );
        },
    );
}


sub _init_collector {
    my ($self) = @_;
    weaken($self);

    $self->_load_state;

    $self->{services_1s}  ||= [];
    $self->{services_5s}  ||= [];
    $self->{services_2m}  ||= [];
    $self->{services_15m} ||= [];
    $self->{services_1h}  ||= [];

    my $now  = Time::HiRes::time;
    my $msec = $now - int($now);

    my $offs_1s  = $msec;
    my $offs_5s  = $now % 5  + $msec;
    my $offs_1m  = $now % 60 + $msec;

    $self->{collect_tmr} = AnyEvent->timer( 
        after    => 1 - $offs_1s,
        interval => 1,
        cb => sub {
            Beekeeper::Service::Supervisor->get_services_status_async(
                on_success => sub {
                    my ($resp) = @_;
                    $self->_collect_stats( $resp->result );
                },
                on_error => sub {
                    my ($error) = @_;
                    log_warn $error->message;
                },
            );
        },
    );

    $self->{consolidate_5s_tmr} = AnyEvent->timer( 
        after    => 5 - $offs_5s,
        interval => 5,
        cb => sub {

            # 1 hour in 5 sec resolution
            $self->_consolidate(
                from   => $self->{services_1s},
                into   => $self->{services_5s},
                period => 5,
                keep   => 60 * 60/5, # 720
            );
        },
    );

    $self->{consolidate_1m_tmr} = AnyEvent->timer( 
        after    => 60 - $offs_1m,
        interval => 60,
        cb => sub {

            # 1 day in 2 min resolution
            $self->_consolidate(
                from   => $self->{services_5s},
                into   => $self->{services_2m},
                period => 2 * 60,
                keep   => 24 * 60/2, # 720
            );

            # 1 week in 15 min resolution
            $self->_consolidate(
                from   => $self->{services_2m},
                into   => $self->{services_15m},
                period => 15 * 60,
                keep   => 7 * 24 * 60/15, # 672
            );

            # 1 month in 1 hour resolution 
            $self->_consolidate(
                from   => $self->{services_15m},
                into   => $self->{services_1h},
                period => 60 * 60,
                keep   => 31 * 24, # 744
            );
        },
    );
}

sub _collect_stats {
    my ($self, $stats) = @_;

    my $now = int( time );
    my $global = { load => 0 };

    foreach my $class (keys %$stats) {
        foreach my $metric (keys %{$stats->{$class}}) {

            my $val = $stats->{$class}->{$metric};

            $stats->{$class}->{$metric} = [ $val, $val ];

            if ($metric eq 'load') {
                # Global load is the load of the most stressed service
                next unless $global->{load} < $val;
                $global->{load} = $val;
            }
            else {
                $global->{$metric} += $val;
            }
        }
    }

    foreach my $metric (keys %$global) {
        my $val = sprintf("%.2f", $global->{$metric});
        $global->{$metric} = [ $val, $val ];
    }

    $stats->{'_global'} = $global;

    my $services_1s = $self->{services_1s};
    push @$services_1s, [ $now, $stats ];

    # 10 min in 1 sec resolution
    shift @$services_1s if (@$services_1s >= 10 * 60);
}

sub _consolidate {
    my ($self, %args) = @_;

    my $stats_src  = $args{'from'};
    my $stats_dest = $args{'into'};
    my $period     = $args{'period'};
    my $keep       = $args{'keep'};
    my $since;

    if (@$stats_dest) {
        # Update last consolidated period
        $since = $stats_dest->[-1]->[TSTAMP];
        return if $stats_src->[-1]->[TSTAMP] < $since;
        pop @$stats_dest;
    }
    elsif (@$stats_src) {
        # Consolidate all data available
        $since = $stats_src->[0]->[TSTAMP];
        $since -= $since % $period;
    }
    else {
        return;
    }

    my $since_idx;
    my $now = int( time );

    for (my $i = @$stats_src - 1; $i >= 0; $i--) {
        last if $stats_src->[$i]->[TSTAMP] < $since;
        $since_idx = $i;
    }

    for (my $start = $since; $start <= $now; $start += $period) {

        my $end = $start + $period - 1;
        $end = $now if ($end > $now);

        my $cons = {};

        for (my $i = $since_idx; $i < @$stats_src; $i++) {

            my $data_point = $stats_src->[$i];

            if ($data_point->[TSTAMP] < $start) {
                next;
            }
            if ($data_point->[TSTAMP] > $end) {
                last;
            }

            my $stats = $data_point->[STATS];

            foreach my $class (keys %$stats) {
                foreach my $metric (keys %{$stats->{$class}}) {

                    my $src = $stats->{$class}->{$metric};
                    my $dest = $cons->{$class}->{$metric} ||= [];

                    $dest->[TOTAL] += $src->[AVERAGE];
                    $dest->[COUNT]++;

                    $dest->[MAXIMUM] = 0 unless defined $dest->[MAXIMUM];
                    if ($src->[MAXIMUM] > $dest->[MAXIMUM]) {
                        $dest->[MAXIMUM] = $src->[MAXIMUM];
                    }
                }
            }
        }

        foreach my $class (keys %$cons) {
            foreach my $metric (keys %{$cons->{$class}}) {

                my $dest = $cons->{$class}->{$metric};

                my ($total, $count) = splice(@$dest, TOTAL, COUNT);

                $dest->[MAXIMUM] = sprintf("%.2f", $dest->[MAXIMUM]);
                $dest->[AVERAGE] = sprintf("%.2f", $total / $count);
            }
        }

        $cons->{global}->{load}->[MAXIMUM] = 0;
        $cons->{global}->{load}->[AVERAGE] = 0;

        foreach my $class (keys %$cons) {

            next if ($class eq '_global');

            if ($cons->{global}->{load}->[MAXIMUM] < $cons->{$class}->{load}->[MAXIMUM]) {
                $cons->{global}->{load}->[MAXIMUM] = $cons->{$class}->{load}->[MAXIMUM];
            }
            if ($cons->{global}->{load}->[AVERAGE] < $cons->{$class}->{load}->[AVERAGE]) {
                $cons->{global}->{load}->[AVERAGE] = $cons->{$class}->{load}->[AVERAGE];
            }
        }

        push @$stats_dest, [ $start, $cons ];
    }

    if (@$stats_dest > $keep) {
        # Discard old data
        shift @$stats_dest;
    }
}

sub _save_state {
    my ($self) = @_;

    my $pool_id = $self->{_WORKER}->{pool_id};
    ($pool_id) = ($pool_id =~ m/^([\w-]+)$/); # untaint
    my $tmp_file = "/tmp/beekeeper-dashboard-$pool_id-stats.dump";

    # Avoid stampede when several workers are exiting simultaneously
    return if (-e $tmp_file && (stat($tmp_file))[9] == time());

    # Lock file because several workers may try to write simultaneously to it
    sysopen(my $fh, $tmp_file, O_RDWR|O_CREAT) or return;
    flock($fh, LOCK_EX | LOCK_NB) or return;
    truncate($fh, 0) or return;

    print $fh encode_json([
        $self->{services_1s},
        $self->{services_5s},
        $self->{services_2m},
        $self->{services_15m},
        $self->{services_1h},
    ]);

    close($fh);
}

sub _load_state {
    my ($self) = @_;

    my $pool_id = $self->{_WORKER}->{pool_id};
    ($pool_id) = ($pool_id =~ m/^([\w-]+)$/); # untaint
    my $tmp_file = "/tmp/beekeeper-dashboard-$pool_id-stats.dump";

    return unless (-e $tmp_file);

    local($/);
    open(my $fh, '<', $tmp_file) or die "Couldn't read $tmp_file: $!";
    my $data = <$fh>;
    close($fh);

    local $@;
    my $dump = eval { decode_json($data) };
    return if $@;

    $self->{services_1s}  = $dump->[0];
    $self->{services_5s}  = $dump->[1];
    $self->{services_2m}  = $dump->[2];
    $self->{services_15m} = $dump->[3];
    $self->{services_1h}  = $dump->[4];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::Dashboard::Worker - Dashboard backend service

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the backend service of the Beekeeper dashboard. In order to use the dashboard
run this service and put C<dashboard.html> and associated .css and .js files into a
publicly accessible web server.

Dashboard workers must be declared into config file C<pool.config.json>:

  [
      {
          "pool_id" : "myapp",
          "bus_id"  : "backend-1",
          "workers" : {
              "Beekeeper::Service::Dashboard::Worker" : { "worker_count" : 1 },
               ...
          },
      },
  ]

Dashboard users must be declared into config file C<dashboard.config.json>:

  {
      "users": {
          "admin": { "password": "eea8d7042107a675..." },
          "guest": { "password": "60c8d0904b5deb4c..." },
      },
  }

Use the following command to hash passwords of dashboard users:

  echo "Username:" && read U && echo "Password:" && read -s P && echo -n "Dashboard$U$P" | shasum -a 256 && U= P=

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
