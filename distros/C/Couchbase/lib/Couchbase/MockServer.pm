package Couchbase::MockServer;
use strict;
use warnings;
use IO::Socket::INET;
use Socket;
use POSIX qw(:errno_h :signal_h :sys_wait_h);
use Log::Fu { level => "warn" };
use Data::Dumper;
use Time::HiRes qw(sleep);

my $SYMLINK = "CouchbaseMock_PLTEST.jar";
our $INSTANCE;

use Class::XSAccessor {
    constructor => '_real_new',
    accessors => [qw(
        pid
        jarfile
        nodes
        buckets
        vbuckets
        harakiri_socket
        port
    )]
};
# This is the couchbase mock server, it will attempt to download, spawn, and
# otherwise control the java-based CouchbaseMock server.


sub _accept_harakiri {
    my $self = shift;
    $self->harakiri_socket->blocking(0);
    my $begin_time = time();
    my $max_wait = 5;
    my $got_accept = 0;

    while(time - $begin_time < $max_wait) {
        my $sock = $self->harakiri_socket->accept();
        if($sock) {
            $sock->blocking(1);
            $self->harakiri_socket($sock);
            $got_accept = 1;
            log_info("Got harakiri connection");
            my $buf = "";
            $self->harakiri_socket->recv($buf, 100, 0);
            if(defined $buf) {
                my ($port) = ($buf =~ /(\d+)/);
                $self->port($port);
            } else {
                die("Couldn't get port");
            }
            last;
        } else {
            sleep(0.1);
        }
    }
    if(!$got_accept) {
        die("Could not establish harakiri control connection");
    }
}

sub _do_run {
    my $self = shift;
    my @command;
    push @command, "java", "-jar", $self->jarfile;

    my $buckets_arg = "--buckets=";

    foreach my $bucket (@{$self->buckets}) {
        my ($name,$password,$type) = @{$bucket}{qw(name password type)};
        $name ||= "";
        $password ||= "";
        $type ||= "";
        if($type && $type ne "couchbase" && $type ne "memcache") {
            die("type for bucket must be either 'couchbase' or 'memcache'");
        }
        my $spec = join(":", $name, $password, $type);
        $buckets_arg .= $spec . ",";
    }

    $buckets_arg =~ s/,$//g;

    push @command, $buckets_arg;

    push @command, "--port=0";

    if($self->nodes) {
        push @command, "--nodes=" . $self->nodes;
    }

    my $sock = IO::Socket::INET->new(Listen => 5);
    $self->harakiri_socket($sock);
    my $port = $self->harakiri_socket->sockport;
    log_infof("Listening on %d for harakiri", $port);
    push @command, "--harakiri-monitor=localhost:$port";

    my $pid = fork();

    if($pid) {
        #Parent: setup harakiri monitoring socket
        sleep(0.05);
        if(waitpid($pid, WNOHANG) > 0) {
            die("Child process died prematurely");
        }
        log_info("Launched CouchbaseMock PID=$pid");
        #$self->pid(getpgrp($pid));
        $self->pid($pid);
        $self->_accept_harakiri();
    } else {

        setpgrp(0, 0);
        log_warnf("Executing %s", join(" ", @command));
        exec(@command);
        warn"exec @command failed: $!";
        exit(1);
    }
}

sub new {
    my ($cls,%opts) = @_;
    if($INSTANCE) {
        log_warn("Returning cached instance");
        return $INSTANCE;
    }

    unless(exists $opts{jarfile}) {
        die("Must have path to JAR");
    }
    my $o = $cls->_real_new(%opts);
    my $file = $o->jarfile;
    if(!-e $file) {
        die("Cannot find $file");
    }

    $o->_do_run();
    $INSTANCE = $o;
    return $o;
}

sub GetInstance {
    my $cls = shift;
    return $INSTANCE;
}

sub suspend_process {
    my $self = shift;
    my $pid = $self->pid;
    return unless defined $pid;
    kill SIGSTOP, -(getpgrp($pid));
}
sub resume_process {
    my $self = shift;
    my $pid = $self->pid;
    return unless defined $pid;
    kill SIGCONT, -(getpgrp($pid));
}

sub failover_node {
    my ($self,$nodeidx,$bucket_name) = @_;
    $bucket_name ||= "default";
    my $cmd = "failover,$nodeidx,$bucket_name\n";
    log_warn($cmd);
    $self->harakiri_socket->send($cmd, 0) or die "Couldn't send";
}

sub respawn_node {
    my ($self,$nodeidx,$bucket_name) = @_;
    $bucket_name ||= "default";
    my $cmd = "respawn,$nodeidx,$bucket_name\n";
    log_warn($cmd);
    $self->harakiri_socket->send($cmd, 0) or die "Couldn't send";
}

sub DESTROY {
    my $self = shift;
    return unless $self->pid;
    kill SIGTERM, $self->pid;
    log_debugf("Waiting for process to terminate");
    waitpid($self->pid, 0);
    log_infof("Reaped PID %d, status %d", $self->pid, $? >> 8);

}

1;
