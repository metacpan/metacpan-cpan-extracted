package Coro::PatchSet::Socket;

use strict;
use Coro::Socket;

our $VERSION = '0.13';

package # hide it from cpan
	Coro::Socket;

sub new {
	my ($class, %arg) = @_;
	
	$arg{Proto} ||= 'tcp';
	defined ($arg{Type}) or $arg{Type} = $arg{Proto} eq "tcp" ? SOCK_STREAM : SOCK_DGRAM;
	
	socket my $fh, PF_INET, $arg{Type}, _proto ($arg{Proto})
		or return;
	
	my $self = bless Coro::Handle->new_from_fh (
		$fh,
		timeout       => $arg{Timeout},
		forward_class => $arg{forward_class},
		partial       => $arg{partial},
	), $class
		or return;
	
	$self->configure (\%arg)
}

sub configure {
	my ($self, $arg) = @_;
	
	$arg->{LocalHost} ||= delete $arg->{LocalAddr};
	$arg->{PeerHost}  ||= delete $arg->{PeerAddr};
	
	${*$self}{io_socket_timeout} = $arg->{Timeout};
	
	my @sa;
	eval {
		if ($arg->{ReuseAddr}) {
			$self->setsockopt (SOL_SOCKET, SO_REUSEADDR, 1)
				or croak "setsockopt(SO_REUSEADDR): $!";
		}
		
		if ($arg->{ReusePort}) {
			$self->setsockopt (SOL_SOCKET, SO_REUSEPORT, 1)
				or croak "setsockopt(SO_REUSEPORT): $!";
		}
		
		if ($arg->{Broadcast}) {
			$self->setsockopt (SOL_SOCKET, SO_BROADCAST, 1)
				or croak "setsockopt(SO_BROADCAST): $!";
		}
		
		if ($arg->{SO_RCVBUF}) {
			$self->setsockopt (SOL_SOCKET, SO_RCVBUF, $arg->{SO_RCVBUF})
				or croak "setsockopt(SO_RCVBUF): $!";
		}
		
		if ($arg->{SO_SNDBUF}) {
			$self->setsockopt (SOL_SOCKET, SO_SNDBUF, $arg->{SO_SNDBUF})
				or croak "setsockopt(SO_SNDBUF): $!";
		}
		
		if ($arg->{LocalPort} || $arg->{LocalHost}) {
			@sa = _sa($arg->{LocalHost} || "0.0.0.0", $arg->{LocalPort} || 0, $arg->{Proto});
			$self->bind ($sa[0])
				or croak "bind($arg->{LocalHost}:$arg->{LocalPort}): $!";
		}
		
		if ($arg->{PeerHost}) {
			@sa = _sa ($arg->{PeerHost}, $arg->{PeerPort}, $arg->{Proto});
		}
	};
	if (my $err = $@) {
		$err =~ s/\s+at\s+.+?line\s+\d+\.//;
		$@ = $err;
		return;
	}
	
	if ($arg->{PeerHost}) {
		for (@sa) {
			$! = 0;
			if ($self->connect ($_)) {
				next unless writable $self;
				$! = unpack "i", $self->getsockopt (SOL_SOCKET, SO_ERROR);
			}
			
			$! or return $self;
			
			$!{ECONNREFUSED} or $!{ENETUNREACH} or $!{ETIMEDOUT} or $!{EHOSTUNREACH}
				or last;
		}
		
		return;
	}
	
	if (exists $arg->{Listen}) {
		$self->listen ($arg->{Listen})
			or return;
	}
	
	$self
}

1;

__END__

=pod

=head1 NAME

Coro::PatchSet::Socket - fix Coro::Socket as much as possible

=head1 SYNOPSIS

    use Coro::PatchSet::Socket;
    # or
    # use Coro::PatchSet 'socket';
    use Coro;
    
    async { ... }

=head1 PATCHES

=head2 timeout

In the current Coro::Socket implementation internal C<io_socket_timeout> variable is not defined. But this variable
exists in the IO::Socket::INET objects, which Coro::Socket tries to emulate. And many modules relies on the value of this
variable. One of this is LWP::UserAgent, so without this variable timeout in the LWP requests will not work. This patch
defines this variable with the value specified in the C<Timeout> constructor option. See t/03_socket_timeout.t

=head2 connect

In the current Coro::Socket implementation Coro::Socket->new(PeerAddr => $a, PeerPort => $p) always returns Coro::Socket object,
even if connection was not successfull. But in fact it should return undef if fail occured. So, after this patch Coro::Socket
constructor will always return proper value. See t/04_socket_connect.t

=head2 inheritance

In the current Coro::Socket implementation Coro::Socket handles PeerAddr argument in the constructor. This is not compatible
with IO::Socket::INET implementation where all arguments handled inside configure(). Because of this some classes inherited
from Coro::Socket which defines PeerAddr only inside configure() may not work. See t/06_socket_inherit.t

=head2 return instead of croak

Coro::Socket has many C<... or croak> statements. And your C<new Coro::Socket> may die when it should return false. For example
when it will not be able to resolve host it will die instead of return false. This is not how IO::Socket::INET works. So, this
patch will change the behavior to expected. See t/10_bad_host_name_no_croak.t

=head1 SEE ALSO

L<Coro::PatchSet>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
