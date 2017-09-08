package App::RemoteCommand::SSH;
use strict;
use warnings;
use Net::OpenSSH;
use IO::Pty;
use App::RemoteCommand::LineBuffer;

sub _ssh {
    my ($self, $host) = @_;
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
            -o => "LogLevel=ERROR",
        ],
    );
}

sub new {
    my ($class, $host) = @_;
    bless {
        host => $host,
        ssh => undef,
        cmd => [],
        at_exit => undef,
    }, $class;
}

for my $attr (qw(fh pid type buffer host at_exit sudo)) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        @_ ? $self->{$attr} = shift : $self->{$attr};
    };
}

sub error {
    my $self = shift;
    $self->{ssh} ? $self->{ssh}->error : undef;
}

sub add {
    my ($self, $cmd) = @_;
    push @{$self->{cmd}}, $cmd;
}

sub cancel {
    my $self = shift;
    @{$self->{cmd}} = ();
}

sub delete_fh {
    my $self = shift;
    delete $self->{fh};
}

sub start {
    my $self = shift;
    $self->{ssh} = $self->_ssh($self->{host});
}

sub is_ready {
    my $self = shift;
    $self->{ssh}->wait_for_master(1);
}

sub master_pid {
    my $self = shift;
    $self->{ssh}->get_master_pid;
}

sub master_exited {
    my $self = shift;
    $self->{ssh}->master_exited;
}

sub next {
    my $self = shift;
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
        $self->{sudo} = undef;
        $self->{pid} = $pid;
        $self->{fh} = $fh;
        $self->{type} = $type;
        $self->{buffer} = App::RemoteCommand::LineBuffer->new if $fh;
        return $self;
    } else {
        delete $self->{$_} for qw(pid fh type buffer sudo);
        return;
    }
}

1;
