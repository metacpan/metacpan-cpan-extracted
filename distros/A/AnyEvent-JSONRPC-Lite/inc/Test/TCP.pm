#line 1
package Test::TCP;
use strict;
use warnings;
use 5.00800;
our $VERSION = '1.13';
use base qw/Exporter/;
use IO::Socket::INET;
use Test::SharedFork 0.12;
use Test::More ();
use Config;
use POSIX;
use Time::HiRes ();
use Carp ();

our @EXPORT = qw/ empty_port test_tcp wait_port /;

# process does not die when received SIGTERM, on win32.
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

# get a empty port on 49152 .. 65535
# http://www.iana.org/assignments/port-numbers
sub empty_port {
    my $port = do {
        if (@_) {
            my $p = $_[0];
            $p = 49152 unless $p =~ /^[0-9]+$/ && $p < 49152;
            $p;
        } else {
            50000 + int(rand()*1000);
        }
    };

    while ( $port++ < 60000 ) {
        next if _check_port($port);
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        );
        return $port if $sock;
    }
    die "empty port not found";
}

sub test_tcp {
    my %args = @_;
    for my $k (qw/client server/) {
        die "missing madatory parameter $k" unless exists $args{$k};
    }
    my $server = Test::TCP->new(
        code => $args{server},
        port => $args{port} || empty_port(),
    );
    $args{client}->($server->port, $server->pid);
    undef $server; # make sure
}

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub wait_port {
    my $port = shift;

    my $retry = 100;
    while ( $retry-- ) {
        return if _check_port($port);
        Time::HiRes::sleep(0.1);
    }
    die "cannot open port: $port";
}

# ------------------------------------------------------------------------- 
# OO-ish interface

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    Carp::croak("missing mandatory parameter 'code'") unless exists $args{code};
    my $self = bless {
        auto_start => 1,
        _my_pid    => $$,
        %args,
    }, $class;
    $self->{port} = Test::TCP::empty_port() unless exists $self->{port};
    $self->start()
      if $self->{auto_start};
    return $self;
}

sub pid  { $_[0]->{pid} }
sub port { $_[0]->{port} }

sub start {
    my $self = shift;
    if ( my $pid = fork() ) {
        # parent.
        $self->{pid} = $pid;
        Test::TCP::wait_port($self->port);
        return;
    } elsif ($pid == 0) {
        # child process
        $self->{code}->($self->port);
        # should not reach here
        if (kill 0, $self->{_my_pid}) { # warn only parent process still exists
            warn("[Test::TCP] Child process does not block(PID: $$, PPID: $self->{_my_pid})");
        }
        exit 0;
    } else {
        die "fork failed: $!";
    }
}

sub stop {
    my $self = shift;

    return unless defined $self->{pid};
    return unless $self->{_my_pid} == $$;

    # This is a workaround for win32 fork emulation's bug.
    #
    # kill is inherently unsafe for pseudo-processes in Windows
    # and the process calling kill(9, $pid) may be destabilized
    # The call to Sleep will decrease the frequency of this problems
    #
    # SEE ALSO:
    #   http://www.gossamer-threads.com/lists/perl/porters/261805
    #   https://rt.cpan.org/Ticket/Display.html?id=67292
    Win32::Sleep(0) if $^O eq "MSWin32"; # will relinquish the remainder of its time slice

        kill $TERMSIG => $self->{pid};

    Win32::Sleep(0) if $^O eq "MSWin32"; # will relinquish the remainder of its time slice


    local $?; # waitpid modifies original $?.
    LOOP: while (1) {
        my $kid = waitpid( $self->{pid}, 0 );
        if ($^O ne 'MSWin32') { # i'm not in hell
            if (POSIX::WIFSIGNALED($?)) {
                my $signame = (split(' ', $Config{sig_name}))[POSIX::WTERMSIG($?)];
                if ($signame =~ /^(ABRT|PIPE)$/) {
                    Test::More::diag("your server received SIG$signame");
                }
            }
        }
        if ($kid == 0 || $kid == -1) {
            last LOOP;
        }
    }
    undef $self->{pid};
}

sub DESTROY {
    my $self = shift;
    local $@;
    $self->stop();
}

1;
__END__

=encoding utf8

#line 406
