package App::ReslirpTunnel::Butler;

use strict;
use warnings;

use POSIX;
use Socket;
use IO::Socket::UNIX;
use Path::Tiny;
use App::ReslirpTunnel::RPC;

use parent 'App::ReslirpTunnel::Logger';
use Carp;

sub new {
    my ($class, %args) = @_;
    my $self = { dont_close_stdio => delete $args{dont_close_stdio} };
    bless $self, $class;
    $self->_init_logger(%args, log_prefix => "ReslirpTunnel::Butler");
    return $self;
}

sub start {
    shift->_start_slave();
}

sub _my_lib_path {
    my $self = shift;
    my $lib_path = Path::Tiny->new($INC{'App/ReslirpTunnel.pm'})->realpath->parent->parent;
    $self->_log(debug => 'lib_path', $lib_path);
    return $lib_path;
}

sub _arg2hex {
    my ($self, $arg) = @_;
    defined $arg or confess "arg2hex: arg is not defined";

    utf8::encode($arg);
    return join('', map { sprintf("%02x", ord($_)) } split(//, $arg));
}

sub _start_slave {
    my $self = shift;

    socketpair(my $parent_socket, my $child_socket, AF_UNIX, SOCK_STREAM, 0)
        or $self->_die("socketpair failed", $!);

    my $pid = fork();
    if (defined $pid and $pid == 0) {
        close($parent_socket);
        POSIX::dup2(fileno($child_socket), 1)
            or $self->_die("dup2 failed", $!);
        my $lib_path = $self->_my_lib_path;
        my @sudo_cmd = ("sudo", $^X, "-I".$lib_path, "-MApp::ReslirpTunnel::ElevatedSlave", "-e", "App::ReslirpTunnel::ElevatedSlave::start");
        push @sudo_cmd, $self->_arg2hex($self->{dont_close_stdio});
        push @sudo_cmd, $self->_arg2hex($self->{log_level});
        push @sudo_cmd, $self->_arg2hex($self->{log_to_stderr});
        if (not $self->{log_to_stderr}) {
            push @sudo_cmd, $self->_arg2hex($self->{log_file});
            push @sudo_cmd, $self->_arg2hex($>);
        }

        # $self->_log(debug => 'Running sudo cmd', "|".join("| |",@sudo_cmd)."|");
        $self->_log(debug => 'Running sudo cmd', "@sudo_cmd");
        exec { $sudo_cmd[0] } @sudo_cmd
            or $self->_log(error =>  "Exec failed", $!);
        POSIX::_exit(1);
    }
    elsif (not defined $pid) {
        $self->_die("Fork failed", $!);
    }
    close($child_socket);

    $self->_log(debug => "waiting for sudo process to return");
    while (1) {
        my $out_pid = waitpid($pid, 0);
        if ($out_pid == -1) {
            $self->_log(debug => "waitpid failed, retrying", $!);
            sleep 1;
        }
        elsif ($?) {
            $self->_die("sudo failed", $?);
        }
        else {
            $self->_log(debug => "sudo exited with code 0");
            $self->{rpc} = App::ReslirpTunnel::RPC->new($parent_socket);
            return 1;
        }
    }
}

sub _request {
    my ($self, $cmd, %args) = @_;
    $self->{rpc}->send_packet({cmd => $cmd, args => \%args});
    my $r = $self->{rpc}->recv_packet();
    if ($r->{status} eq 'bye') {
        $self->{rpc} = undef;
    }
    return $r
}

sub hello { shift->_request('hello') }

sub _request_check_ok {
    my ($self, $request, %args) = @_;
    my $expected_status = delete($args{expected_status}) // 'ok';
    my $r = $self->_request($request, %args);
    if ($r->{status} ne $expected_status) {
        $self->_log(debug => "request failed", "status=$r->{status}, expected=$expected_status", $r->{error});
        return;
    }
    return $r;
}

sub create_tap {
    my ($self, $device) = @_;
    $self->_log(debug => "Forwarding request for creating tap device $device");
    my $r = $self->_request_check_ok('create_tap', device => $device) // return;
    unless ($r->{fd_follows}) {
        $self->_log("protocol error", "fd expected");
        return;
    }
    my $fd = $self->{rpc}->recv_fd();

    # reopen $tap_fd as a Perl file handle
    my $tap_fh = IO::Socket::UNIX->new_from_fd($fd, "r+")
        or $self->_die("Failed to create tap file handle", $!);
    return ($tap_fh);
}

sub device_up {
    my ($self, $device) = @_;
    return $self->_request_check_ok('device_up', device => $device)
}

sub device_addr_add {
    my ($self, $device, $addr, $mask) = @_;
    return $self->_request_check_ok('device_addr_add', device => $device, addr => $addr, mask => $mask);
}

sub bye {
    my $self = shift;
    return $self->_request_check_ok('bye', expected_status => 'bye');
}

sub add_a_record {
    my($self, $name, $addr) = @_;
    return $self->_request_check_ok('add_a_record', name => $name, addr => $addr);
}

sub start_dnsmasq {
    my ($self, %args) = @_;
    my $r = $self->_request_check_ok(start_dnsmasq => %args);
    my $pid = $r->{pid} // $self->_log(warn => "Failed to get dnsmasq PID");
    return $pid;
}

sub resolvectl_dns {
    my ($self, %args) = @_;
    return $self->_request_check_ok(resolvectl_dns => %args);
}

sub resolvectl_domain {
    my ($self, %args) = @_;
    return $self->_request_check_ok(resolvectl_domain => %args)
}

sub route_add {
    my ($self, %args) = @_;
    return $self->_request_check_ok(route_add => %args);
}

sub screen_reset { shift->_request('screen_reset'); 1 }

1;
