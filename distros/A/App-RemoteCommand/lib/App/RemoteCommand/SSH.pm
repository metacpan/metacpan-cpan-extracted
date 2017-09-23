package App::RemoteCommand::SSH;
use strict;
use warnings;
use App::RemoteCommand::Util qw(DEBUG logger);
use Net::OpenSSH;
use IO::Pty;

sub _ssh {
    my ($self, $host) = @_;
    my $loglevel = DEBUG ? "error" : "quiet";
    Net::OpenSSH->new($host,
        async => 1,
        strict_mode => 0,
        timeout => 5,
        kill_ssh_on_timeout => 1,
        master_setpgrp => 1,
        master_opts => [
            -o => "ConnectTimeout=5",
            -o => "StrictHostKeyChecking=no",
            -o => "UserKnownHostsFile=/dev/null",
            -o => "LogLevel=$loglevel",
        ],
    );
}

use constant STATE_TODO          => 1;
use constant STATE_CONNECTING    => 2;
use constant STATE_CONNECTED     => 3;
use constant STATE_DISCONNECTING => 4;
use constant STATE_DONE          => 5;

sub new {
    my ($class, $host) = @_;
    bless {
        host => $host,
        ssh => undef,
        cmd => [],
        at_exit => undef,
        state => STATE_TODO,
        exit => -1,
        current => undef,
        sudo => undef,
    }, $class;
}

sub add {
    my ($self, $cmd) = @_;
    push @{$self->{cmd}}, $cmd;
}

sub at_exit {
    my $self = shift;
    @_ ? $self->{at_exit} = shift : $self->{at_exit};
}

sub cancel {
    my ($self, $signal) = @_;

    DEBUG and logger "CANCEL %s, state %s", $self->host, $self->{state};

    if ($self->{state} == STATE_TODO) {
        $self->{state} == STATE_DONE;
    } elsif ($self->{state} == STATE_CONNECTING) {
        @{$self->{cmd}} = ();
        undef $self->{at_exit};
    } elsif ($self->{state} == STATE_CONNECTED) {
        @{$self->{cmd}} = ();
        if ($signal
            and $self->{current}
            and $self->{current}{type} eq "cmd"
            and my $pid = $self->{current}{pid}
        ) {
            DEBUG and logger "SEND SIG$signal %s, pid %s", $self->host, $pid;
            kill $signal => $pid;
        }
    } elsif ($self->{state} == STATE_DISCONNECTING) {
        # nop
    } elsif ($self->{state} == STATE_DONE) {
        # nop
    } else {
        die;
    }
}

sub error {
    my $self = shift;
    ($self->{ssh} && $self->{ssh}->error) || $self->{_error};
}

sub host {
    my $self = shift;
    $self->{host};
}

sub exit {
    my $self = shift;
    $self->{exit};
}

sub one_tick {
    my ($self, %args) = @_;

    my $exit_pid  = $args{pid};
    my $exit_code = $args{exit};
    my $select    = $args{select};

    my $ssh = $self->{ssh};

    if ($ssh and $exit_pid and $ssh->get_master_pid and $exit_pid == $ssh->get_master_pid) {
        DEBUG and logger "FAIL %s, master process exited unexpectedly", $self->host;
        $ssh->master_exited;
        $self->{exit} = $exit_code;
        $self->{_error} = $self->{ssh}->error || "master process exited unexpectedly";
        $self->{state} = STATE_DONE;
        undef $self->{ssh};
    }

    if ($self->{state} == STATE_TODO) {
        DEBUG and logger "CONNECT %s", $self->host;
        $ssh = $self->{ssh} = $self->_ssh($self->{host});
        $self->{state} = STATE_CONNECTING;
    }

    if ($self->{state} == STATE_CONNECTING) {
        my $master_state = $ssh->wait_for_master(1);
        if ($master_state) {
            DEBUG and logger "CONNECTED %s", $self->host;
            $self->{state} = STATE_CONNECTED;
        } elsif (!defined $master_state) {
            # still connecting...
            return 1;
        } else {
            DEBUG and logger "FAIL TO CONNECT %s", $self->host;
            $self->{exit} = -1;
            $self->{_error} = $self->{ssh}->error || "master process exited unexpectedly";
            $self->{state} = STATE_DONE;
            undef $self->{ssh};
        }
    }

    if ($self->{state} == STATE_CONNECTED) {
        if (!$self->{current} or $exit_pid && $self->{current} && $self->{current}{pid} == $exit_pid) {

            if ($self->{current}) {
                DEBUG and logger "FINISH %s, pid %d, type %s, exit %d",
                    $self->host, $exit_pid, $self->{current}{type}, $exit_code;
                if ($self->{current}{type} eq "cmd") {
                    $self->{exit} = $exit_code;
                }
            }

            my ($cmd, $type);
            if (@{$self->{cmd}}) {
                $cmd = shift @{$self->{cmd}};
                $type = "cmd";
            } elsif ($self->{at_exit}) {
                $cmd = delete $self->{at_exit};
                $type = "at_exit";
            }

            if ($cmd) {
                my $ssh = $self->{ssh};
                my ($pid, $fh) = $cmd->($ssh);
                if ($pid) {
                    DEBUG and logger "START %s, pid %d, type %s", $self->host, $pid, $type;
                    $self->{current} = {pid => $pid, type => $type};
                    $select->add(pid => $pid, fh => $fh, host => $self->host) if $fh;
                    return 1;
                }
                # save error
                $self->{_error} = $self->{ssh}->error;
            }

            undef $self->{current};
            DEBUG and logger "DISCONNECTING %s", $self->host;
            $ssh->disconnect(0); # XXX block disconnect
            $self->{state} = STATE_DISCONNECTING;
        } else {
            return 1;
        }
    }

    if ($self->{state} == STATE_DISCONNECTING) {
        my $master_state = $ssh->wait_for_master(1);
        if (defined $master_state && !$master_state) {
            DEBUG and logger "DISCONNECTED %s", $self->host;
            $self->{state} = STATE_DONE;
            undef $self->{ssh};
        } else {
            return 1;
        }
    }

    if ($self->{state} == STATE_DONE) {
        DEBUG and logger "DONE %s", $self->host;
        return;
    }

    die;
}

1;
