package App::ReslirpTunnel::ElevatedSlave;

use strict;
use warnings;

use POSIX;
use Fcntl qw(:mode);
use Socket;
use Socket::MsgHdr;
use IO::Socket::UNIX;
use App::ReslirpTunnel::RPC;

use parent 'App::ReslirpTunnel::Logger';

use constant TUNSETIFF => 0x400454ca;  # Define constant for TUNSETIFF
use constant IFF_TAP   => 0x0002;
use constant IFF_NO_PI => 0x1000;

sub _create_tap {
    my ($self, $tap_device) = @_;
    $self->_log(debug => "Opening device $tap_device");
    sysopen(my $tap_fd, "/dev/net/tun", O_RDWR) or $self->_die("Cannot open /dev/net/tun", $!);
    my $ifr = pack("Z16 s", $tap_device, IFF_TAP | IFF_NO_PI);
    ioctl($tap_fd, TUNSETIFF, $ifr) or $self->_die("ioctl TUNSETIFF failed", $!);
    return $tap_fd;
}

sub _create_tap__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device} or $self->_die("Device name is required");
    my $tap_fd = $self->_create_tap($tap_device);
    {status => "ok", fd => $tap_fd }
}

sub _do_system {
    my $self = shift;
    $self->_log(debug => "Running command", "@_");
    if (system(@_) == 0) {
        return { status => "ok" };
    }
    $self->_die("Command @_ failed",  "rc=".($? >> 8));
}

sub _screen_reset__rpc { shift->_do_system("reset") }

sub _device_up__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device};
    $self->_do_system("ip", "link", "set", "dev", $tap_device, "up");
}

sub _device_addr_add__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device};
    my $addr = $request->{addr};
    my $mask = $request->{mask};
    $self->_do_system("ip", "addr", "add", "$addr/$mask", "dev", $tap_device);
}

sub _start_dnsmasq__rpc {
    my ($self, $request) = @_;
    my $mapping = $request->{net_mapping};
    my $forward = $request->{forward_dns};
    my $user = $request->{user} // 'nobody';
    my $group = $request->{group} // 'nogroup';
    my $pid_fn = $request->{pid_fn} // '';
    my $log_fn = $request->{log_fn};

    my @args = ('dnsmasq',
                '--pid-file='.$pid_fn,
                '--log-facility='.$log_fn,
                '--user='.$user,
                '--group='.$group,
                '--no-hosts',
                '--no-resolv',
                '--bind-interfaces',
                '--except-interface=lo',
                '--log-queries',
                '--server=',
                '--no-dhcp-interface=*');

    for my $domain (keys %$mapping) {
        push @args, "--address=/$domain/$_" for @{$mapping->{$domain}};
    }

    for my $domain (keys %$forward) {
        push @args, "--server=/$domain/$_" for @{$forward->{$domain}};
    }

    my $r = $self->_do_system(@args);

    # Wait for the pid file to appear
    for (1..100) {
        if (open my $fh, '<', $pid_fn) {
            my $line = <$fh>;
            if ($line =~ /^(\d+)\n/) {
                return { %$r, pid => $1 }
            }
        }
        select (undef, undef, undef, 0.1);
    }

    $self->_die("Failed to start dnsmasq, cannot read PID file at $pid_fn");
}

sub _resolvectl_domain__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device};
    my $domain = $request->{domain};
    $self->_do_system("resolvectl", "domain", $tap_device, "~$domain");
}

sub _resolvectl_dns__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device};
    my $dns = $request->{dns};
    $self->_do_system("resolvectl", "dns", $tap_device, $dns);
}

sub _route_add__rpc {
    my ($self, $request) = @_;
    my $tap_device = $request->{device};
    my $net = $request->{net};
    my $gw = $request->{gw};
    $self->_do_system("ip", "route", "add", $net, "via", $gw, "dev", $tap_device);
}

sub _bye__rpc {
    return { status => "bye" }
}

sub _hello__rpc {
    return { status => "ok" }
}

sub _run {
    my $self = shift;

    while (1) {
        $self->_log(debug => "Waiting for request");
        my $request = $self->{rpc}->recv_packet();

        my $cmd = $request->{cmd};
        $self->_log(debug => "Received request: $cmd");
        my $method = "_${cmd}__rpc";
        my ($r, $fd);
        eval {
            $r = $self->$method($request->{args}) // {};
            $r->{status} //= "ok";
            $fd = delete $r->{fd};
            if (defined $fd) {
                $r->{fd_follows} = 1;
            }
        };
        if ($@) {
            $r = { status => "error", error => $@ };
        }
        $self->{rpc}->send_packet($r);
        if (defined $fd) {
            $self->{rpc}->send_fd($fd);
        }
        $self->_log(debug => "Request completed with status $r->{status}");
        last if ($r->{status} eq 'bye');
    }
    $self->_log(info => "Bye bye!");
}

sub new {
    my ($class, %args) = @_;
    my $self = { socket => $args{socket} };
    bless $self, $class;

    $self->_init_logger(log_level => $args{log_level},
                        log_to_stderr => $args{log_to_stderr},
                        log_file => $args{log_file},
                        log_uid => $args{log_uid},
                        log_prefix => "ReslirpTunnel::ElevatedSlave");

    $self->{rpc} = App::ReslirpTunnel::RPC->new($args{socket});
    $self->_log(info => "Evalated slave started");
    $self
}

sub _init_logger {
    my ($self, %args) = @_;
    # We need to open a different log file for the elevated slave as
    # we are running under a different user (root) and don't have
    # permission to write to the user's log file.

    $args{log_file} =~ s/((?:\.[^\.]+)?)$/.elevated$1/ if defined $args{log_file};
    $self->SUPER::_init_logger(%args);
}

sub _hex2arg {
    my $hex = shift;
    my $arg = pack("H*", $hex);
    # warn "$hex --> $arg\n";
    utf8::decode($arg);
    return $arg;
}

sub start {
    # Recover socket from the file descriptor passed by the parent
    POSIX::dup2(1, 3);
    POSIX::dup2(2, 1);

    $SIG{INT} = 'IGNORE';

    # Detach from the controlling terminal
    POSIX::setsid();

    my $pid = fork;
    if (defined $pid and $pid == 0) {
        my $socket = IO::Socket::UNIX->new_from_fd(3, "r+")
            or die "Failed to create socket: $!";

        my $dont_close_stdio = _hex2arg(shift @main::ARGV);
        my $log_level = _hex2arg(shift @main::ARGV);
        my $log_to_stderr = _hex2arg(shift @main::ARGV);
        my $log_file = ($log_to_stderr ? undef : _hex2arg(shift @main::ARGV));
        my $log_uid = ($log_to_stderr ? undef : _hex2arg(shift @main::ARGV));

        unless ($dont_close_stdio) {
            open STDIN, '<', '/dev/null';
            open STDOUT, '>', '/dev/null';
            open STDERR, '>', '/dev/null' unless $log_to_stderr;
        }

        my $server = __PACKAGE__->new(socket => $socket,
                                      dont_close_stdio => $dont_close_stdio,
                                      log_level => $log_level,
                                      log_to_stderr => $log_to_stderr,
                                      log_file => $log_file,
                                      log_uid => $log_uid);
        $server->_run();
    }
    POSIX::_exit(0);
}
1;
