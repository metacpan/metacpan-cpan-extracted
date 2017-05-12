package App::Iops;
BEGIN {
  $App::Iops::VERSION = '0.006';
}

=head1 NAME

App::Iops - Show process I/O operations

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  iops [options]

      --pid [pid]
      --help

=head1 DESCRIPTION

Summarize a process's I/O operations in real time.

Attach to an existing process:

  $ iops -p 3251
  read /dev/random...............................
  write /var/log/message..
  close /dev/random

=head1 API

Methods are still subject to change.

=head2 new

Returns a new object.

=over

=item help

  use App::Iops;
  App::Iops->new( 'help' )->run;

Prints the help and exits. This is very side-effectful. This might
throw exceptions.

=item pid => $pid

  use App::Iops;
  App::Iops->new( pid => $a_pid )->run;

Associates a process id to attach to.

=back

=head2 run

Actually executes whatever action was requested.

=head1 THANKS TO

Thanks to the following people:

=over

=item Alan Haggai Alavi

=back

=cut

use strict;

use English '-no_match_vars';
use Getopt::Long ();
use Pod::Usage ();

sub new {
    my $class = shift;
    my $self = {
        pid        => undef,
        strace_pid => undef,
        strace_fh  => undef,
        files      => {},
        prev       => '',
        @_
    };
    bless $self, $class;

    $self->_read_arguments( @_ );

    return $self;
}

sub run {
    my $self = shift;

    if ($self->{help}) {
        Pod::Usage::pod2usage(
            -exitval => 0,
            -verbose => 2,
        );
    }
    else {
        $self->_proc_readlinks;
        $self->_open_strace_pid;
        $self->_watch_iops;
    }

    # NEVER REACHED
    return;
}

sub _watch_iops {
    my ($self) = @_;

    $OUTPUT_AUTOFLUSH = -t STDOUT;

    local $/ = "\n";
    while ( my $iop = readline $self->{strace_fh} ) {
        chomp $iop;

        my ( $op, $fd, $fn );
        if ( ( $fd ) = $iop =~ /^close\(([0-9]+)/ ) {
            $self->{files}{$fd} ||= readlink( "/proc/$self->{pid}/fd/$fd" );
            $self->_iop( 'close ' . ( defined $self->{files}{$fd} ? $self->{files}{$fd} : $fd ) );
            delete $self->{files}{$fd};
        }
        elsif ( ( $op, $fd ) = $iop =~ /^(\w+)\(([0-9]+)/ ) {
            $fn = $self->{files}{$fd} ||= readlink( "/proc/$self->{pid}/fd/$fd" );
            my $color = $op eq 'read' ? "\e[33m" : "\e[31m";
            $self->_iop( "$color$op\e[0m " . ( defined $fn ? $fn : $fd ) );
        }
        elsif ( ( $op, $fn ) = $iop =~ /^(\w+)\("([^"]+)/ ) {
            $self->_iop( "$op $fn" );
        }
    }

    return;
}

sub _read_arguments {
    my $self = shift;

    local @ARGV = @_;
    Getopt::Long::GetOptions(
        $self,
        'help',
        'pid=i',
    )
      or Pod::Usage::pod2usage(
          -exitval => 2,
          -verbose => 2,
      );
    if (@ARGV) {
        Pod::Usage::pod2usage(
            -exitval => 2,
            -verbose => 2,
        );
    }

    return;
}

sub _proc_readlinks {
    my ($self) = @_;

    opendir FD, "/proc/$self->{pid}/fd"
      or die "Can't open /proc/$self->{pid}/fd: $ERRNO";
    my %files;
    for ( readdir FD ) {
        next if $_ eq '.' || $_ eq '..';

        my $link = readlink "/proc/$self->{pid}/fd/$_";
        if ( ! defined $link ) {
            $link = $_;
        }
        $files{$_} = $link;
    }
    closedir FD;

    $self->{files} = \ %files;

    return;
}

sub _open_strace_pid {
    my ($self) = @_;

    my @strace_cmd = (
        'strace',
            '-e' => 'trace=file,close,read,write',
            '-o' => '|cat',
            '-s' => 0,
            '-p' => $self->{pid},
            '-q',
    );
    my $strace_pid = open my ($strace_fh), '-|', @strace_cmd;
    if ( ! $strace_pid ) {
        die "Can't [@strace_cmd]: $ERRNO";
    }

    $self->{strace_fh}  = $strace_fh;
    $self->{strace_pid} = $strace_pid;

    return;
}

sub _iop {
    my ($self, $text) = @_;

    if ( $text eq $self->{prev} ) {
        print '.';
    }
    else {
        print "\n$text";
        $self->{prev} = $text;
    }
    return;
}

'We make an average of 257 cups a day on Tuesdays but volume is
trending downwards because with the onset of of warmer weather
customers begin ordering more cold, non-coffee based drinks such as
iced tea. The espresso to drip ratio is approximately 1.67 to 1
suggesting that ...';