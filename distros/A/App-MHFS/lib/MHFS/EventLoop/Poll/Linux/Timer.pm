package MHFS::EventLoop::Poll::Linux::Timer v0.7.0;
use 5.014;
use strict; use warnings;
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use POSIX qw/floor/;
use Devel::Peek;
use feature 'say';
use Config;
if(index($Config{archname}, 'x86_64-linux') == -1) {
    die("Unsupported arch: " . $Config{archname});
}
use constant {
    _clock_REALTIME  => 0,
    _clock_MONOTONIC => 1,
    _clock_BOOTTIME  => 7,
    _clock_REALTIME_ALARM => 8,
    _clock_BOOTTIME_ALARM => 9,

    _ENOTTY => 25,  #constant for Linux?
};
# x86_64 numbers
require 'syscall.ph';

my $TFD_CLOEXEC = 0x80000;
my $TFD_NONBLOCK = 0x800;

sub new {
    my ($class, $evp) = @_;
    my $timerfd = syscall(SYS_timerfd_create(), _clock_MONOTONIC, $TFD_NONBLOCK | $TFD_CLOEXEC);
    $timerfd != -1 or die("failed to create timerfd: $!");
    my $timerhandle = IO::Handle->new_from_fd($timerfd, "r");
    $timerhandle or die("failed to turn timerfd into a file handle");
    my %self = ('timerfd' => $timerfd, 'timerhandle' => $timerhandle);
    bless \%self, $class;

    $evp->set($self{'timerhandle'}, \%self, POLLIN);
    $self{'evp'} = $evp;
    return \%self;
}

sub packitimerspec {
    my ($times) = @_;
    my $it_interval_sec  = int($times->{'it_interval'});
    my $it_interval_nsec = floor(($times->{'it_interval'} - $it_interval_sec) * 1000000000);
    my $it_value_sec = int($times->{'it_value'});
    my $it_value_nsec = floor(($times->{'it_value'} - $it_value_sec) * 1000000000);
    #say "packing $it_interval_sec, $it_interval_nsec, $it_value_sec, $it_value_nsec";
    return pack 'qqqq', $it_interval_sec, $it_interval_nsec, $it_value_sec, $it_value_nsec;
}

sub settime_linux {
    my ($self, $start, $interval) = @_;
    # assume start 0 is supposed to run immediately not try to cancel a timer
    $start = ($start > 0.000000001) ? $start : 0.000000001;
    my $new_value = packitimerspec({'it_interval' => $interval, 'it_value' => $start});
    my $settime_success = syscall(SYS_timerfd_settime(), $self->{'timerfd'}, 0, $new_value,0);
    ($settime_success == 0) or die("timerfd_settime failed: $!");
}

sub onReadReady {
    my ($self) = @_;
    my $nread;
    my $buf;
    while($nread = sysread($self->{'timerhandle'}, $buf, 8)) {
        if($nread < 8) {
            say "timer hit, ignoring $nread bytes";
            next;
        }
        my $expirations = unpack 'Q', $buf;
        say "Linux::Timer there were $expirations expirations";
    }
    if(! defined $nread) {
        if( ! $!{EAGAIN}) {
            say "sysread failed with $!";
        }

    }
    $self->{'evp'}->check_timers;
    return 1;
};
1;