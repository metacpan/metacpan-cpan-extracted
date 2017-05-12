
package CHI::Driver::Ping;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Fcntl;
use Errno;
use FileHandle;
use IO::Handle;
use Socket;
use Time::HiRes;
use POSIX;

use Fcntl qw(:flock SEEK_END);


use Carp 'croak';

extends 'CHI::Driver';

use 5.006;
our $VERSION = '0.00000001';

use constant ICMP_ECHOREPLY   => 0; # ICMP packet types
use constant ICMP_UNREACHABLE => 3; # ICMP packet types
use constant ICMP_ECHO        => 8;
use constant ICMP_STRUCT      => "C2 n3 A"; # Structure of a minimal ICMP packet
use constant SUBCODE          => 0; # No ICMP subcode for ECHO and ECHOREPLY
use constant ICMP_FLAGS       => 0; # No special flags for send or recv
use constant ICMP_PORT        => 0; # No port with ICMP

=head1 NAME

CHI::Driver::Ping - Cache data in the Ether.

=head1 SYNOPSIS

  use CHI;

  $< == 0 or exec 'sudo', $0, @ARGV; # sending ICMPs requires root priv

  system 'sysctl', '-w', 'net.ipv4.icmp_ratelimit=100000';

  my $cache = CHI->new( driver => 'Ping', ip => 74.125.73.105 ); # google IP

=head1 DESCRIPTION

Tap into the Ether.  Optimize for CPU or storage?  Fuck that.

If you thought the Cloud was awesome, just wait until you try
storing your data in the Ether.

Inspired by Delay Line Memory, L<http://en.wikipedia.org/wiki/Delay_line_memory>, 
this modules stores data by transmitting it through a medium known to have a
delay and waiting for it to come back again, whereupon it both returns it and
retransmits it out again.

It seems rather pointless and silly to bother with spinning metal oxide 
covered platters or billions of tiny capacitors when data can be stored
in the air between the Earth and sattelites, in ordinary copper wire, 
and in easy to extrude lengths of glass fiber.

=head1 ATTRIBUTES

=over

=item ip

Who to send all of the ICMP ECHOPINGs to.

=item namespace

Not currently used (XXX).

=back

=head1 TODO

CIDR block of hosts to use, or a list, or something.  Even better, scan the network
for hosts that are up and build this dynamically.  For extra points, find hosts with
a lot of hops to them.

namespace. XXX.

remove. XXX.

purge. XXX.

=head1 BUGS

=item 0.00000001

Initial; github dev version.
Requires root privilege.

=head1 Authors

L<CHI::Driver::Ping> by Scott Walters (scott@slowass.net) with suggestions from 
Brock Wilcox (awwaiid@thelackthereof.org).

Uses code stolen from L<Net::Ping> by bbb@cpan.org (Rob Brown), colinm@cpan.org (Colin McMillen),
bronson@trestle.com (Scott Bronson), karrer@bernina.ethz.ch (Andreas Karrer),
pmarquess@bfsec.bt.co.uk (Paul Marquess), and mose@ns.ccsn.edu (Russell Mosemann).
These folks shall remain blameless for my actions.

=head1 COPYRIGHT & LICENSE

Copyright (c) Scott Walters (scrottie) 2011

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

has 'table_prefix' => ( is => 'rw', isa => 'Str', default => 'chi_', );

has 'proto_num' => ( is => 'rw' );

has 'pid' => ( is => 'rw' );  # not currently used; Net::Ping looked at this PID returned with the ECHOPING; we don't, yet XXX

has 'fh' => ( is => 'rw' );

has 'seq' => ( is => 'rw', default => 0 );

has 'ip' => ( is => 'rw', default => '127.0.0.1' );

# has 'daemon_pid' => ( is => 'rw', );
sub daemon_pid {
    my $self = shift;
    our $daemon_pid;  # process global
    $daemon_pid = shift if @_;
    $daemon_pid;
}

has 'i_am_daemon' => ( is => 'rw', );

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;
    croak("icmp ping requires root privilege") if ($> and $^O ne 'VMS' and $^O ne 'cygwin');
    $self->proto_num( (getprotobyname('icmp'))[2] || croak("Can't get icmp protocol by name") );
    $self->pid( $$ & 0xffff );           # Save lower 16 bits of pid
    $self->fh( FileHandle->new() );
    socket($self->fh, PF_INET, SOCK_RAW, $self->proto_num) or croak "icmp socket error - $!";
    # $SIG{CHLD} = sub { wait };
    $SIG{CHLD} = 'IGNORE';
    $self->launch_daemon;
}

sub DEMOLISH {
    my $self = shift;
    kill 9, $self->daemon_pid if $self->daemon_pid;
    $self->daemon_pid( 0 );
}

sub remove {
    my ( $self, $key, ) = @_;
    $self->store( $key, 'delete' );
    return;
}

sub clear { 
    my $self = shift;
    # XXX this will be a fun one; clear the entire cache
    return;
}

sub get_keys {
    my ( $self ) = @_;
    # XXX this will be a fun one
}

sub get_namespaces { croak 'not supported' }

sub store {

    my $self = shift;
    my $key = shift;
    my $value = shift;

    my $ip = $self->ip();

# warn "ip: $ip";

    my ($saddr,             # sockaddr_in with port and ip
        $msg,               # ICMP packet to send
      );

# XXXXXXXXXXX
#    # at construction instead XXX on the other hand, it's possible that we were sharing a daemon with another process and it exited and they killed it
#    if( ! $self->i_am_daemon and ( ! $self->daemon_pid or ! kill 0, $self->daemon_pid ) ) {
#        $self->launch_daemon;
#    }

    my $data = join '', $key, chr(0), $value;

    $self->seq( ( $self->seq() + 1) % 65536 );   # Increment sequence
    my $checksum = 0; 
    $msg = pack( ICMP_STRUCT . length( $data ), ICMP_ECHO, SUBCODE, $checksum, $self->pid, $self->seq, $data );
    $checksum = $self->checksum($msg);
    $msg = pack( ICMP_STRUCT . length( $data ), ICMP_ECHO, SUBCODE, $checksum, $self->pid, $self->seq, $data );
    $saddr = sockaddr_in(ICMP_PORT, inet_aton( $self->ip ) );
    send($self->fh, $msg, ICMP_FLAGS, $saddr); # Send the message

}

sub fetch {

    my $self = shift;
    my $key = shift;
    my $mode = shift() || 0;

    local $SIG{USR1} = sub { use Carp; Carp::cluck "USR1"; };
  
#warn "XXX got mode: $mode";
    my $delete_mode = 1 if $mode eq 'delete';  # don't retransmit this packet once we see it
    my $forever_mode = 1 if $mode eq 'forever'; # daemonize; don't return
  
    # at construction instead; XXX on the other hand as above
    # 30589 pts/1    R+     0:13 t/CHIDriverTests-Ping.t: perl echo ping daemon: perl echo ping daemon: perl echo ping daemon: perl echo ping daemon... why the fuck am I seeing this?

# XXXXXXXX
#    if( ! $self->daemon_pid and ! $forever_mode and ! $self->i_am_daemon ) {
#        # ^--- launch_daemon calls this back again in turn; don't call them back or we'll loop forever
#        $self->launch_daemon;
#    }

    if( ! $forever_mode and $self->daemon_pid ) {
        # XXX this is dangerous; a semaphore would be better; STOPing them, there's a risk that we've stopped them while 
        # they're in middle of processing the packet that we want; try to work around that
        # XXX also, a semaphore is not adequate; multiple processes might be accessing the same cache; need multiple-up-multiple-down
        kill SIGSTOP, $self->daemon_pid; # XXX test result
    }
  
    fcntl($self->fh, F_SETFL, fcntl($self->fh, F_GETFL, 0) | O_NONBLOCK) or die "fcntl: $!";
  
    my $start_time = Time::HiRes::time;
# warn "start_time $start_time";
    my $return_value;
  
    while(1) {
        if( ! $forever_mode and Time::HiRes::time - $start_time > 2) {
            # ^------ here is also where we exit in failure
            kill SIGCONT, $self->daemon_pid if $self->daemon_pid;
            return; 
        }
        my $recv_msg = "";
        my $from_pid = -1;
        my $from_seq = -1;
        my $from_saddr = recv($self->fh, $recv_msg, 1500, ICMP_FLAGS); # sockaddr_in of sender
        if( $! == Errno::EAGAIN ) {
            kill SIGCONT, $self->daemon_pid if $self->daemon_pid; # just in case they're in middle of processing the packet we want; XXX test result
            Time::HiRes::sleep(0.2);
            kill SIGSTOP, $self->daemon_pid if $self->daemon_pid; # XXX test result
            next;
        }
        my $from_port;         # Port packet was sent from
        my $from_ip;           # Packed IP of sender
        ($from_port, $from_ip) = sockaddr_in($from_saddr);
        (my $from_type, my $from_subcode) = unpack("C2", substr($recv_msg, 20, 2));
        if ($from_type == ICMP_ECHOREPLY) {
            ($from_pid, $from_seq) = unpack("n3", substr($recv_msg, 24, 4, ''));
            if( length $recv_msg >= 28 ) {
# warn "raw message: $recv_msg";
                substr $recv_msg, 0, 24, '';
                my $i = index $recv_msg, chr(0);
                my $key2 = substr $recv_msg, 0, $i;
                my $value = substr $recv_msg, $i+1;
                $return_value = $value if ! $forever_mode and $key eq $key2;  # don't return yet but remember what to return
                $self->store( $key2, $value ) unless $delete_mode; 
                if( $return_value ) {
                    # ^----- only ever gets set if we aren't in $forever_mode
                    if( $self->daemon_pid ) {
                        kill SIGCONT, $self->daemon_pid;
                    }
                    return $return_value if $return_value;               # <----- here is where we return successfully
                }
# warn "found it: $value";
# return ($key, $value); # XXXX
            }
        }
    }
}

sub checksum {

    my ($class,
        $msg            # The message to checksum
        ) = @_;
    my ($len_msg,       # Length of the message
        $num_short,     # The number of short words in the message
        $short,         # One short word
        $chk            # The checksum
        );
        
    $len_msg = length($msg);
    $num_short = int($len_msg / 2);
    $chk = 0;
    foreach $short (unpack("n$num_short", $msg)) 
    {   
      $chk += $short;       
    }                                           # Add the odd byte in
    $chk += (unpack("C", substr($msg, $len_msg - 1, 1)) << 8) if $len_msg % 2;
    $chk = ($chk >> 16) + ($chk & 0xffff);      # Fold high into low
    return(~(($chk >> 16) + $chk) & 0xffff);    # Again and complement
}

sub launch_daemon {
    my $self = shift;

    our $launch_daemon_lock;
    return if $launch_daemon_lock;
    $launch_daemon_lock++;

    if(  $self->i_am_daemon ) {
        warn "that's odd; I am the daemon but somewhere decided that I should launch a daemon";
        $launch_daemon_lock--;
        return;
    }

# XXXXXXXXXXXX
    # we only need one of these fuckers
    open my $fh, '<', '/var/lock/chi-driver-ping-pid';
    flock($fh, LOCK_EX) or die "Cannot lock PID file";

    if( $fh ) {
        my $pid = readline $fh;
        if( $pid ) {
            chomp $pid;
            if( $pid =~ m/^\d+$/ and kill 0, $pid ) {
warn "XXX daemon process already exists?  why don't we know it's pid? (it's $pid, by the way)";
                $self->daemon_pid( $pid );  # update this with what we've learned
                open my $fh, '>', '/var/lock/chi-driver-ping-pid'; # but don't die
                if( $fh ) {
                    $fh->print($pid);
                }
                close $fh;
                $launch_daemon_lock--;
                return;
            }
        }
    }
    close $fh;

    if( my $pid = fork ) {
        $self->daemon_pid( $pid ); # parent
        open my $fh, '>', '/var/lock/chi-driver-ping-pid'; # but don't die
        if( $fh ) {
            $fh->print($pid);
        }
        close $fh;
    } else {
        # child
warn "XXX daemon pid started up as $$";
        open STDIN,  '</dev/null' or die "Can't open STDIN from /dev/null: [$!]\n";
        #open STDOUT, '>/dev/null' or die "Can't open STDOUT to /dev/null: [$!]\n"; # XXX
        #open STDERR, '>&STDOUT'   or die "Can't open STDERR to STDOUT: [$!]\n";
        # Change to root dir to avoid locking a mounted file system
        chdir '/'                 or die "Can't chdir to \"/\": [$!]";
        # Turn process into session leader, and ensure no controlling terminal
        # POSIX::setsid(); # no; die with the parent
        $0 = "$0: perl echo ping daemon";
        $self->i_am_daemon( 1 );
        while(1) {
            $self->fetch( undef, 'forever' ); # fetch receives and re-transmits; do this forever
        }
    }

    $launch_daemon_lock--;
} 


    
1;

__END__

