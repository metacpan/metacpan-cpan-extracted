package App::ReslirpTunnel::Loop;

use strict;
use warnings;
use POSIX;

use parent 'App::ReslirpTunnel::Logger';

sub new {
    my ($class, %logger_args) = @_;
    my $self = bless {}, $class;
    $self->_init_logger(%logger_args,
                       log_prefix => 'ReslirpTunnel::Loop');
    return $self;
}

sub hexdump { unpack "H*", $_[0] }

sub run {
    my ($self, $tap_handle, $ssh_handle, $ssh_err_handle) = @_;
    $self->_log(debug => "tap_handle: $tap_handle, ssh_handle: $ssh_handle, ssh_err_handle: $ssh_err_handle");

    my $pid = fork();
    if (defined $pid and $pid == 0) {
        eval {
            # We use a double eval because we want to catch any
            # errors, even those due to a failed logging call!
            eval {
                # We close everything but the TAP, SSH, SSH error and log handles
                my @keep_fhs = ($tap_handle, $ssh_handle, $ssh_err_handle);
                my $log_fh = eval { $self->{log}{adapter}{fh} };
                push @keep_fhs, $log_fh if defined $log_fh;

                $self->_close_fds_but(@keep_fhs);
                $self->_init_signal_handlers();
                eval {
                    $self->_log(debug => 'looping...');
                    $self->_loop($tap_handle, $ssh_handle, $ssh_err_handle);
                };
                if ($@) {
                    $self->_log(error => "IO loop failed", $@);
                }
            };
            if ($@) {
                $self->_log(error => "Error setting up loop", $@);
            };
        };
        POSIX::_exit(0);
    }
    elsif (not defined $pid) {
        $self->_log(error => "Fork failed", $!);
        return;
    }
    $self->{pid} = $pid;
    return $pid;
}

sub _init_signal_handlers {
    my $self = shift;
    my $signal_count = 0;
    $self->{signal_handler} //= sub { $signal_count++ };
    $self->{signal_count_ref} //= \$signal_count;
    $SIG{INT} = $self->{signal_handler};
    $SIG{TERM} = $self->{signal_handler};
}

sub _close_fds_but {
    my ($self, @keep_fhs) = @_;
    my @keep_fds = map fileno($_), @keep_fhs;

    $self->_log(debug => "Keeping fds: @keep_fds");
    my $max_fd = POSIX::sysconf(POSIX::_SC_OPEN_MAX) || 1024;
    for my $fd (3 .. $max_fd) {
        POSIX::close($fd)
            unless grep { $fd == $_ } @keep_fds;
    }
}

sub _loop {
    my ($self, $tap_handle, $ssh_handle, $ssh_err_handle) = @_;

    my $tap2ssh_buff = '';
    my $ssh2tap_buff = '';
    my $err_buff = '';
    my $pkt_buff;
    my $max_buff_size = 65*1025;  # 10KB buffer

    my $tap_fd = fileno($tap_handle);
    my $ssh_fd = fileno($ssh_handle);
    my $err_fd = fileno($ssh_err_handle);

    my $err_open = 1;
    my $tunnel_closed;
    my $close_later;
    my $err_close_time_limit;

    while ($err_open and not ${$self->{signal_count_ref}}) {
        my $ssh2tap_pkt_len;
        my $rfds = '';
        my $wfds = '';
        my $efds = $rfds;

        vec($rfds, $err_fd, 1) = 1;
        unless ($close_later) {
            vec($rfds, $ssh_fd, 1) = 1 if length($ssh2tap_buff) < $max_buff_size;
            vec($rfds, $tap_fd, 1) = 1 if length($tap2ssh_buff) < $max_buff_size;

            if (length($ssh2tap_buff) >= 2) {
                $ssh2tap_pkt_len = unpack("n", $ssh2tap_buff);
                if (length($ssh2tap_buff) >= $ssh2tap_pkt_len + 2) {
                    vec($wfds, $tap_fd, 1) = 1;
                }
            }
            if (length($tap2ssh_buff) > 0) {
                vec($wfds, $ssh_fd, 1) = 1;
            }
        }

        my $nfound = select($rfds, $wfds, $efds, 15);
        next if $nfound <= 0;

        if (vec($rfds, $err_fd, 1)) {
            my $n = sysread($ssh_err_handle, $err_buff, $max_buff_size, length($err_buff));
            if (!defined $n) {
                $self->_warn("Read from SSH error channel failed", $!);
            }
            elsif ($n == 0) {
                $self->_log(info => "SSH error channel closed");
                $close_later++;
            }
            else {
                while ($err_buff =~ s/^(.*)\n//) {
                    next if $1 =~ /^\s*$/;
                    $self->_log(info => "Remote stderr", $1);
                }
                while (length($err_buff) >= 1500) {
                    $self->_log(ingo => "Remote stderr", substr($err_buff, 0, 1500)." (truncated)");
                    substr($err_buff, 0, 1500) = '';
                }
            }
        }

        if (vec($rfds, $ssh_fd, 1)) {
            my $n = sysread($ssh_handle, $ssh2tap_buff, $max_buff_size, length($ssh2tap_buff));
            if (!defined $n) {
                $self->_warn("Read from SSH failed", $!);
            }
            elsif ($n == 0) {
                $self->_warn("SSH closed connection");
                $close_later++;
            }
        }

        if (vec($rfds, $tap_fd, 1)) {
            my $n = sysread($tap_handle, $pkt_buff, $max_buff_size);
            if (!defined $n) {
                $self->_warn("Read from TAP failed", $!);
            }
            elsif ($n == 0) {
                $self->_warn("TAP closed connection");
                $close_later++;
            }
            else {
                $tap2ssh_buff .= pack("n", $n) . $pkt_buff;
            }
        }

        if (vec($wfds, $ssh_fd, 1)) {
            my $n = syswrite($ssh_handle, $tap2ssh_buff, length($tap2ssh_buff));
            if (!defined $n) {
                $self->_warn("Write to SSH failed", $!);
            }
            elsif ($n == 0) {
                $self->_warn("SSH closed connection");
                $close_later++;
            }
            else {
                substr($tap2ssh_buff, 0, $n) = '';
            }
        }

        if(vec($wfds, $tap_fd, 1)) {
            if (not defined $ssh2tap_pkt_len or length($ssh2tap_buff) < $ssh2tap_pkt_len + 2) {
                $self->_log(warn => "Unexpected write flag for TAP");
            }
            else {
                my $n = syswrite($tap_handle, substr($ssh2tap_buff, 2, $ssh2tap_pkt_len));
                # In any case, we remove the packet from the buffer. The TCP/IP magic!
                substr($ssh2tap_buff, 0, $ssh2tap_pkt_len + 2) = '';
                if (!defined $n) {
                    $self->_warn("Write to TAP failed", $!);
                }
                elsif ($n == 0) {
                    $self->_warn("TAP closed", $!);
                    $close_later++;
                }
            }
        }

        if ($close_later) {
            $self->_log(debug => "Closing tap and ssh sockets");
            close($tap_handle);
            close($ssh_handle);
            $tunnel_closed++;
            undef $close_later;
            $err_close_time_limit = time + 10;
        }

        if ($tunnel_closed and time > $err_close_time_limit) {
            $self->_log(debug => "Closing error socket");
            close($ssh_err_handle);
            $err_open = 0;
        }
        $err_open-- if $tunnel_closed;
    }
}

1;
