package App::ReslirpTunnel;

our $VERSION = '0.02';

use strict;
use warnings;

use JSON;
use Socket;
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4);
use Path::Tiny;
use File::XDG;
use POSIX;
use Net::OpenSSH;

use parent 'App::ReslirpTunnel::Logger';

use App::ReslirpTunnel::Butler;
use App::ReslirpTunnel::Loop;

sub new {
    my ($class, %args) = @_;
    my $self = { args => \%args };
    bless $self, $class;
    return $self;
}

sub go {
    my $self = shift;

    eval {
        $self->_init_xdg;
        $self->_init_time;
        $self->_init_logger;
        $self->_log(info => "Starting ReslirpTunnel");
        $self->_set_signal_handlers;
        $self->_init_config;
        $self->_init_butler;
        $self->_init_ssh;
        $self->_send_to_background;
        $self->_init_tap_device;
        $self->_init_reslirp;
        $self->_init_loop;
        $self->_config_forward_dns;
        $self->_config_net_mappings;
        $self->_init_dnsmasq;
        $self->_init_resolver_rules;
        $self->_init_routes;
        $self->_wait_for_something;
        $self->_log(info => "Terminating ReslirpTunnel");
    };
    if ($@) {
        die "Something went wrong: $@\n";
    }
    $self->_kill_everything;
}

sub _init_xdg {
    my $self = shift;
    my $app_name = $self->{args}{app_name} or die "App name missing, unable to initialize XDG helper";
    $self->{xdg} = File::XDG->new(name => $app_name, path_class => 'Path::Tiny');
}

sub _init_time {
    my $self = shift;
    $self->{timestamp} = POSIX::strftime("%Y%m%dT%H%M%SZ", gmtime);
}

sub _init_logger {
    my $self = shift;
    my $level = $self->{args}{log_level};
    my $log_to_stderr = $self->{args}{log_to_stderr};
    my $fn = $self->{args}{log_file};
    unless (defined $fn) {
        my $parent_dir = $self->{xdg}->state_home->child('logs')->mkdir;
        $fn = $parent_dir->child($self->{timestamp}.".reslirp-tunnel.log");
        eval {
            my $sl = $parent_dir->child('latest.reslirp-tunnel.log');
            unlink $sl if -e $sl;
            symlink $fn, $sl;
        };
    }
    $self->SUPER::_init_logger(log_level => $level, log_to_stderr => $log_to_stderr, log_file => $fn);
}

sub _set_signal_handlers {
    my $self = shift;
    my $signal_count = 0;
    $self->{signal_count_ref} = \$signal_count;
    $self->{signal_handler} = sub {
        $signal_count++;
        $self->_log(info => "Signal received, count: $signal_count");
    };

    $SIG{INT} = $self->{signal_handler};
    $SIG{TERM} = $self->{signal_handler};
}

sub _init_config {
    my $self = shift;
    my $args = $self->{args};

    $self->{run_in_foreground} = $args->{run_in_foreground} // 0;
    $self->{dont_close_stdio} = $args->{dont_close_stdio} // 0;

    $self->{remote_host} = $args->{remote_host};
    $self->{remote_port} = $args->{remote_port};

    $self->{remote_network} = $args->{remote_network} // '10.0.2.0';
    is_ipv4($self->{remote_network}) or $self->_die("Invalid remote network address, $self->{remote_network}");

    $self->{remote_netmask} = $self->_parse_netmask($args->{remote_netmask} // 24);
    $self->{remote_dns} = $self->_parse_ip($args->{remote_dns});
    $self->{remote_gw} = $self->_parse_ip($args->{remote_gw});
    $self->{local_ip} = $self->_parse_ip($args->{local_ip});
}

sub _parse_netmask {
    my ($self, $netmask) = @_;
    ($netmask =~ /^\d+$/ && $netmask >= 1 && $netmask <= 31) or $self->_die("Invalid netmask", $netmask);
    return $netmask;
}

sub _parse_ip {
    my ($self, $ip) = @_;
    my $network = $self->{remote_network};
    my $netmask = $self->{remote_netmask};
    if ($ip =~ /^\d+$/) {
        $ip = $network =~ s/\d+$/$ip/r;
    }
    is_ipv4($ip) or $self->_die("Invalid IP address", $ip);

    my $ip_int = __ip_to_int($ip);
    my $net_int = __ip_to_int($network);
    my $bitmask = ~0 << (32 - $netmask);

    unless (($ip_int & $bitmask) == ($ip_int & $bitmask)) {
        $self->_die("IP address $ip is not inside remote network $network/$netmask");
    }

    return $ip;
}

sub __ip_to_int {
    my $ip = shift;
    return unpack("N", pack("C*", split(/\./, $ip)));
}

sub _init_butler {
    my $self = shift;
    my $butler = $self->{butler} = App::ReslirpTunnel::Butler->new(dont_close_stdio => $self->{dont_close_stdio},
                                                                 log_level => $self->{log_level},
                                                                 log_to_stderr => $self->{log_to_stderr},
                                                                 log_file => $self->{log_file});

    $butler->start or $self->_die("Failed to start butler");
    $butler->hello
        or $self->_die("Failed to say hello to butler");
    $self->_log(info => "Elevated slave process started and ready");
}

sub _send_to_background {
    my $self = shift;
    return if $self->{run_in_foreground};

    $self->_log(info => "Moving to background");
    POSIX::setsid();

    my $pid = fork // $self->_die("Unable to move process into the background", $!);
    if ($pid == 0) {
        $SIG{INT} = $self->{signal_handler};
        $SIG{TERM} = $self->{signal_handler};

        unless ($self->{dont_close_stdio}) {
            open STDIN, '<', '/dev/null';
            open STDOUT, '>', '/dev/null';
            open STDERR, '>', '/dev/null' unless $self->{log_to_stderr};
        }

        $self->{log_prefix} = "ReslirpTunnel::Child";

        return 1; # Return in the child!!!
    }
    else {
        eval {
            syswrite STDERR, "$0 moved to background, PID: $pid\n";
            $self->_log(debug => "First process exiting");
        };

        POSIX::_exit(0);
    }
}

sub _init_ssh {
    my $self = shift;
    my $host = $self->{remote_host} // $self->_die("No remote host specified");
    my $port = $self->{remote_port};
    my $user = $self->{remote_user};
    my $cmd = $self->{args}{ssh_command};
    my $more_args = $self->{args}{more_ssh_args};
    my @args = (host => $host);
    push @args, (port => $port) if defined $port;
    push @args, (user => $user) if defined $user;
    push @args, (ssh_cmd => $cmd) if defined $cmd;
    push @args, (master_opts => $more_args) if defined $more_args;
    $self->{ssh} = my $ssh = Net::OpenSSH->new(@args);
    $ssh->error and
         $self->_die("Unable to connect to remote host", $ssh->error);
    $self->{remote_os} = $self->{args}{remote_os} // $self->_autodetect_remote_os //
        $self->_die("No remote OS specified and unable to autodetect it");
    $self->{remote_shell} = $self->{args}{remote_shell} // $self->_autodetect_remote_shell //
        $self->_die("No remote shell specified and unable to autodetect it");

    my $ssh_master_pid = $self->{ssh}->get_master_pid;
    $self->_log(debug => "SSH master PID", $ssh_master_pid);
    $self->{ssh_master_pid} = $ssh_master_pid;
}

sub _autodetect_remote_os {
    my $self = shift;
    my $ssh = $self->{ssh};
    my $out = $ssh->capture('echo %COMSPEC%');
    my $looks_like_unix = $out =~ /^\%COMSPEC\%$/m;
    if ($looks_like_unix) {
        $self->_log(debug => "Looks like a Unix-like system, let's check it further...");
        my $uname = lc $ssh->capture('uname -s');
        if ($uname =~ /^(Linux|Darwin|FreeBSD|OpenBSD|NetBSD|DragonFly|MidnightBSD|AIX|HP-UX|SunOS|IRIX|OSF1|SCO_SV|QNX)$/i) {
            $self->_log(info => "Remote OS identified as Linux/UNIX ($1)");
            return 'unix';
        }
    }
    else {
        $self->_log(debug => "Looks like Windows, let's check it further...");
        my $ver = $ssh->capture('ver');
        if ($ver =~ /^(Microsoft Windows \[Version.*\])/m) {
            $self->_log(info => "Remote OS identified as Windows ($1)");
            return 'windows';
        }
    }
    $self->_warn("Unable to autodetect remote OS");
    return;
}

sub _autodetect_remote_shell {
    my $self = shift;
    if ($self->{remote_os} eq 'windows') {
        return $self->{remote_shell} = 'windows';
    }
    my $ssh = $self->{ssh};
    my $out = $ssh->capture('echo $SHELL') or return "sh";
    chomp($out);
    return Path::Tiny->new($out)->basename;
}

sub _init_tap_device {
    my $self = shift;
    my $butler = $self->{butler};
    my $device = $self->{tap_device} = $self->{args}{device} // $self->_find_unused_tap_device;
    $self->{tap_fh} = $butler->create_tap($device);
    $butler->device_up($device)
        or $self->_die("Failed to bring up tap device $device");

    my $host = $self->{local_ip};
    my $mask = $self->{remote_netmask};
    $butler->device_addr_add($device, $host, $mask)
        or $self->_die("Failed to add address $host/$mask to tap device $device");
    $self->_log(info => "Tap device $device created and configured");
    1;
}

sub _init_reslirp {
    my $self = shift;
    my $ssh = $self->{ssh};
    my $cmd = $self->{reslirp_command} = $self->{args}{reslirp_command} // $self->_autodetect_reslirp_command;
    my @args = @{$self->{args}{more_reslirp_args}};
    $self->_log(info => "Starting remote reSLIRP process");
    $self->_log(debug => "Remote command: $cmd @args");
    my ($socket, undef, $stderr, $pid) = $ssh->open_ex({stderr_pipe => 1,
                                                        stdinout_socket => 1},
                                                       $cmd, @args);
    $self->{reslirp_socket} = $socket;
    $self->{reslirp_stderr} = $stderr;
    $self->{reslirp_pid} = $pid;
    $pid or $self->_die("Failed to start reSLIRP process");
    $self->_log(info => "reSLIRP process started");
}

sub _autodetect_reslirp_command {
    my $self = shift;
    if ($self->{remote_os} eq 'windows') {
        return 'C:\Program Files\reSLIRP\reslirp.exe';
    }
    return "reslirp";
}

sub _find_unused_tap_device {
    my $self = shift;
    my $n = 0;
    for my $n (0..100) {
        my $device = "tap$n";
        -e "/dev/$device" or return $device;
    }
    $self->_die("Unable to find an unused tap device");
}

sub _config_forward_dns {
    my $self = shift;
    $self->{forward_dns} //= {};
    $self->{forward_ipv4} //= {};
    $self->_config_forward_dns_ssh;
}

sub _config_forward_dns_ssh {
    my $self = shift;
    for my $record (@{$self->{args}{forward_dns_ssh}}) {
        $self->_log(debug => "Retrieving iface DNS servers using remote shell");
        my $domain = $record->{domain};
        my $iface = $record->{iface};
        my $method = "_resolve_remote_iface_dns__". (($self->{remote_os} eq 'windows') ? 'windows' : 'unix');
        if (my @addrs = $self->$method($iface)) {
            $self->_log(debug => "DNS servers for remote iface $iface", join(", ", @addrs));
            for my $addr (@addrs) {
                push @{$self->{forward_dns}{$domain} //= []}, $addr;
                $self->{forward_ipv4}{"$addr/32"} = 1;
            }
        }
        else {
            $self->_warn("Failed to retrieve DNS servers using remote shell, ignoring domain", $record->{domain});
        }
    }
}

sub _resolve_remote_iface_dns__unix {
    my $self = shift;
    $self->_warn('Retrieving by iface DNS servers using the shell on remote Unix hosts is not implemented yet');
    ()
}

sub _resolve_remote_iface_dns__windows {
    my ($self, $iface) = @_;
    my $ssh = $self->{ssh};

    my $out = $ssh->capture({remote_shell=> 'MSWin'}, 'powershell', '-Command', "Get-DnsClientServerAddress | ConvertTo-Json");
    my @addrs;
    eval {
        for my $record (@{decode_json($out)}) {
            if ($record->{InterfaceAlias} eq $iface and
                $record->{AddressFamily} eq '2') {
                push @addrs, @{$record->{ServerAddresses}};
            }
        }
    };
    unless (@addrs) {
        $self->_warn("Failed to parse JSON output from DnsClientServerAddress", $@);
        $self->_log(debug => "Output was", $out);
    }
    return @addrs;
}


sub _config_net_mappings {
    my $self = shift;
    $self->{net_mapping} //= {};
    $self->{forward_ipv4} //= {};
    $self->_config_net_mappings_net;
    $self->_config_net_mappings_direct;
    $self->_config_net_mappings_local;
    $self->_config_net_mappings_dns;
    $self->_config_net_mappings_ssh;
}

sub _config_net_mappings_net {
    my $self = shift;
    for my $record (@{$self->{args}{route_nets}}) {
        my $addr = $record->{addr};
        my $mask = $record->{mask};
        if ($self->_validate_ipv4($addr) and $self->_validate_netmask($mask)) {
            $self->{forward_ipv4}{"$addr/$mask"} = 1;
        }
        else {
            $self->_warn("Ignoring invalid network", "$addr/$mask");
        }
    }
}

sub _config_net_mappings_direct {
    my $self = shift;
    for my $record (@{$self->{args}{route_hosts}}) {
        my $addrs = $record->{addrs} // [];
        $self->{forward_ipv4}{"$_/32"} = 1 for @$addrs;
        if (defined (my $host = $record->{host})) {
            if ($self->_validate_domain_name($host)) {
                push @{$self->{net_mapping}{$host} //= []}, @$addrs;
            }
            else {
                $self->_warn("Ignoring host with invalid name", $host);
            }
        }
    }
}

sub _config_net_mappings_local {
    my $self = shift;
    for my $host (@{$self->{args}{route_hosts_local}}) {
        my $addr;
        if (is_ipv4($host)) {
            $self->{forward_ipv4}{"$host/32"} = 1;
        }
        elsif ($self->_validate_domain_name($host)) {
            my $good;
            my ($err, @records) = Socket::getaddrinfo($host);
            unless ($err) {
                for my $record (@records) {
                    if ($record->{family} == AF_INET) {
                        my (undef, $packed_ip) = sockaddr_in($record->{addr});
                        my $addr = inet_ntoa($packed_ip);
                        push @{$self->{net_mapping}{$host} //= []}, $addr;
                        $self->{forward_ipv4}{"$addr/32"} = 1;
                        $good = 1;
                    }
                }
            }
            $good or $self->_warn("Failed to resolve host, ignoring it", $host);
        }
        else {
            $self->_warn("Ignoring host with invalid name", $host);
        }
    }
}

sub _validate_ipv4 {
    my ($self, $ipv4) = @_;
    is_ipv4($ipv4) and return 1;
    $self->_log(debug => "Bad IPv4", $ipv4);
    return undef;
}

sub _validate_netmask {
    my ($self, $mask) = @_;
    $mask =~ /\d+/ and $mask >= 1 and $mask <= 32 and return 1;
    $self->_log(debug => "Bad netmask", $mask);
    return undef;
}

sub _validate_domain_name {
    my ($self, $domain) = @_;
    is_hostname($domain, {'domain_private_tld' => 1}) and return 1;
    $self->_log(debug => "Bad domain", $domain);
    return undef;
}

sub _config_net_mappings_dns {
    my $self = shift;
    my $route_hosts = $self->{args}{route_hosts_dns};
    if (@$route_hosts) {
        my $dns = Net::DNS::Resolver->new(nameservers => [$self->{remote_dns}], recurse => 1);
        for my $host (@$route_hosts) {
            if ($self->_validate_domain_name($host)) {
                my $good;
                $self->_log(debug => "Resolving $host using remote DNS");
                my $query = $dns->query($host, 'A');
                if ($query) {
                    for my $rr ($query->answer) {
                        if ($rr->type eq 'A') {
                            my $addr = $rr->address;
                            push @{$self->{net_mapping}{$host} //= []}, $addr;
                            $self->{forward_ipv4}{"$addr/32"} = 1;
                            $good = 1;
                        }
                    }
                }
                $good or $self->_warn("Failed to resolve host using remote DNS, ignoring it", $host);
            }
            else {
                $self->_warn("Ignoring host with invalid name", $host);
            }
        }
    }
}

sub _config_net_mappings_ssh {
    my $self = shift;
    my $route_hosts = $self->{args}{route_hosts_ssh};
    for my $host (@$route_hosts) {
        if ($self->_validate_domain_name($host)) {
            $self->_log(debug => "Resolving $host using remote shell");
            my $method = "_resolve_remote_host_with_shell__" . (($self->{remote_os} eq 'windows') ? 'windows' : 'unix');
            my @addrs = $self->$method($host);
            for my $addr (@addrs) {
                push @{$self->{net_mapping}{$host} //= []}, $addr;
                $self->{forward_ipv4}{"$addr/32"} = 1;
            }
            @addrs or $self->_warn("Failed to resolve host using remote DNS, ignoring it", $host);
        }
        else {
            $self->_warn("Ignoring host with invalid name", $host);
        }
    }
}

sub _resolve_remote_host_with_shell__unix {
    my $self = shift;
    $self->_warn('Resolving using the shell on remote Unix hosts is not implemented yet');
    ()
}

sub _resolve_remote_host_with_shell__windows {
    my ($self, $host) = @_;
    my $ssh = $self->{ssh};

    my $out = $ssh->capture({remote_shell=> 'MSWin'}, 'powershell', '-Command', "Resolve-DnsName $host | ConvertTo-Json");
    my @addrs;
    eval {
        my $records = decode_json($out);
        my @names = $host;
        for my $r (@$records) {
            push @names, $r->{NameHost} if $r->{Type} == 5;
        }
        for my $r (@$records) {
            push @addrs, $r->{IP4Address} if $r->{Type} == 1
        }
        return @addrs
    };
    unless (@addrs) {
        $self->_warn("Failed to parse JSON output from Resolve-DnsName", $@);
        $self->_log(debug => "Output was", $out);
    }
    return @addrs;
}

sub _init_dnsmasq {
    my $self = shift;
    my $net_mapping = $self->{net_mapping};
    my $forward_dns = $self->{forward_dns};

    if (%$net_mapping or %$forward_dns) {
        $self->_log(info => "Starting dnsmasq");

        my $pid_parent_dir = $self->{xdg}->state_home->child('dnsmasq')->mkdir;
        my $pid_fn = $pid_parent_dir->child($self->{timestamp}.".dnsmasq.pid");
        my $latest_fn = $pid_parent_dir->child("latest.dnsmasq.pid");
        unlink $latest_fn if -e $latest_fn;
        symlink $pid_fn, $latest_fn;
        my $log_fn = $self->{xdg}->state_home->child('logs')->mkdir->child($self->{timestamp}.".dnsmasq.log");
        my $butler = $self->{butler};
        my $user_name = $self->_get_user_name;
        my $group_name = $self->_get_group_name;
        my $pid = $self->{dnsmasq_pid} = $butler->start_dnsmasq(device => $self->{tap_device},
                                                                net_mapping => $net_mapping,
                                                                forward_dns => $forward_dns,
                                                                user => $user_name,
                                                                group => $group_name,
                                                                pid_fn => "$pid_fn",
                                                                log_fn => "$log_fn");
        if ($pid) {
            $self->_log(debug => "dnsmasq PID", $pid);
        }
        else {
            $self->_warn("dnsmasq failed to start correctly, no PID found");
        }
    }
    else {
        $self->_log(debug => 'dnsmasq not required');
    }
}

sub _init_resolver_rules {
    my $self = shift;
    my @domains = ( keys(%{$self->{net_mapping}}),
                    keys(%{$self->{forward_dns}}) );
    if(@domains) {
        $self->_log(info => "Setting up resolver rules");
        my $butler = $self->{butler};
        my $device = $self->{tap_device};
        my $local_ip = $self->{local_ip};
        $butler->resolvectl_dns(device => $device, dns => $local_ip);
        for my $domain (@domains) {
            $butler->resolvectl_domain(device => $device, domain => $domain);
        }
    }
}

sub _init_routes {
    my $self = shift;
    my $forward = $self->{forward_ipv4};
    if (%$forward) {
        $self->_log(info => "Setting up routes");
        my $butler = $self->{butler};
        for my $net (keys %$forward) {
            $butler->route_add(net => $net, gw => $self->{remote_gw}, device => $self->{tap_device});
        }
    }
}

sub _get_user_name {
    my $self = shift;
    my $user = getpwuid($<);
    return $user if $user;

    $self->_warn("Failed to get user name, using 'nobody'");
    return 'nobody';
}

sub _get_group_name {
    my $self = shift;
    my $group = getgrgid($();
    return $group if $group;

    $self->_warn("Failed to get group name, using 'nogroup'");
    return 'nogroup'
}

sub _init_loop {
    my $self = shift;

    my $loop = App::ReslirpTunnel::Loop->new(log_level => $self->{log_level},
                                           log_to_stderr => $self->{log_to_stderr},
                                           log_file => $self->{log_file});

    my $pid = $loop->run($self->{tap_fh}, $self->{reslirp_socket}, $self->{reslirp_stderr})
        //$self->_die("Failed to start IO loop process");

    $self->_log(info => "IO loop process started, PID: $pid");
    $self->{loop_pid} = $pid;
}

sub _find_process_by_pid {
    my ($self, $pid) = @_;
    for my $process (qw(reslirp loop dnsmasq)) {
        my $process_pid = $self->{"${process}_pid"};
        if (defined $process_pid) {
            return $process if $self->{"${process}_pid"} == $pid;
        }
    }
    return;
}

sub _wait_for_something {
    my $self = shift;
    $self->_log(debug => "Waiting for some child to exit");
    while (not ${$self->{signal_count_ref}}) {
        my $kid = waitpid(-1, WNOHANG);
        if ($kid <= 0) {
            # $self->_log(debug => "waitpid", $kid);
            $self->_log(debug => "waitpid failed", $!) if $kid < 0;
            select undef, undef, undef, 5;
        }
        else {
            $self->_log(debug => "process $kid exited, rc", $? >> 8);
            for my $proc (qw(reslirp loop ssh_master)) {
                my $proc_pid = $self->{"${proc}_pid"};
                if (defined $proc_pid and $kid == $proc_pid) {
                    $self->_log(info => "Process $proc (PID: $kid) finished");
                    delete $self->{"${proc}_pid"};

                    $self->{ssh}->master_exited if $proc eq 'ssh_master';
                    return;
                }
            }
            $self->_warn("Unknown process with PID $kid finished");
        }
    }
}

sub _kill_everything {
    my $self = shift;
    $self->_log(debug => "killing everything!");
    my @signals = (0, 0, 15, 15, 15, 9, 9, 9);

    if (defined(my $ssh = $self->{ssh})) {
        $ssh->disconnect;
        delete $self->{ssh_master_pid};
    }

    for my $process (qw(loop reslirp dnsmasq)) {
        my $pid = $self->{"${process}_pid"} // next;
        $self->_log(debug => "Waiting for process $process (PID: $pid) to finish");
        if (kill(0 => $pid) > 0) {
            for my $signal (@signals) {
                my $kid = waitpid($pid, WNOHANG);
                if ($kid == $pid) {
                    $self->_log(debug => "Process $process exited and captured", $?);
                    last;
                }
                sleep 1;
                $self->_log(debug => "Sending signal $signal to process $pid");
                kill $signal => $pid;
            }
        }
        else {
            $self->_log(debug => "Cannot send signals to process $pid");
            last;
        }
    }
    $self->_log(info => "All processes finished");
}

1;
__END__

=head1 NAME

App::ReslirpTunnel - A wrapper for the reslirp-tunnel application

=head1 DESCRIPTION

C<App::ReslirpTunnel> provides the C<reslirp-tunnel> application,
which allows one to establish a network tunnel through an SSH
connection, terminated in L<reSLIRP|https://github.com/salva/reslirp>.

This application handles all necessary initialization, configuration, and
the underlying communication processes required to maintain the tunnel.

The module is not intended for direct use, as it serves solely as a wrapper
for the underlying reslirp-tunnel application functionality.

=head1 BUGS AND SUPPORT

To report bugs or request features, please visit the GitHub repository
at L<https://github.com/salva/p5-App-ReslirpTunnel>.

=head1 SEE ALSO

L<reslirp-tunnel>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
