package Coro::PatchSet::Handle;

use strict;
use Coro::Handle;

our $VERSION = '0.13';

package # hide it from cpan
	Coro::Handle;

sub new_from_fh {
	my $class = shift;
	my $fh = shift or return;
	open my $self, '+<&', $fh or return;
	
	tie *$self, 'Coro::Handle::FH', fh => $fh, @_;
	
	bless $self, ref $class ? ref $class : $class
}

package # hide it from cpan
	Coro::Handle::FH;

sub READ {
	my $len = $_[2];
	my $ofs = $_[3];
	my $res;

	# first deplete the read buffer
	if (length $_[0][3]) {
		my $l = length $_[0][3];
		
		if ($l <= $len) {
			substr ($_[1], $ofs) = $_[0][3]; $_[0][3] = "";
			return $l;
		} else {
			substr ($_[1], $ofs) = substr ($_[0][3], 0, $len);
			substr ($_[0][3], 0, $len) = "";
			return $len;
		}
	}
	
	while() {
		my $r = sysread $_[0][0], $_[1], $len, $ofs;
		if (defined $r) {
			$len -= $r;
			$ofs += $r;
			$res += $r;
			last;
		} elsif ($! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
			last;
		}
		last if $_[0][8] || !&readable;
	}
	
	$res
}

1;

__END__

=pod

=head1 NAME

Coro::PatchSet::Handle - fix Coro::Handle as much as possible

=head1 SYNOPSIS

    use Coro::PatchSet::Handle;
    # or
    # use Coro::PatchSet 'handle';
    use Coro;
    
    async { ... }

=head1 PATCHES

=head2 new_from_fh

Coro::Handle::new_from_fh creates tied handle. In the current implementation it ties Glob which is not a real file
handle. So things like IO::Handle::new_from_fd doesn't work with such tied handle. After this patch tied handle 
will be a real filehandle (duplicate of original filehandle) and new_from_fd will work as expected. See
t/07_handle_new_from_fd.t

=head2 sysread()

In the current Coro::Handle implementation sysread($buf, $len) will always try to read $len bytes. So if we have
some slow socket that sent you $len-1 bytes and 1 more byte after 10 minutes, Coro::Handle will wait this 1 byte
for 10 minutes (or until error/socket closing). But this behaviour is not compatible with sysread() on system sockets,
which Coro::Handle tries to emulate. After this patch sysread will behave like sysread on system sockets. It will read
>= 1 and <= $len bytes for you. Bytes readed count may be less than $len if sysread() may not read it without blocking.
But will always be >= 1 (if there was no error or socket closing). So in the situation above sysread will read $len-1
bytes and return. See t/05_handle_read.t

=head1 SEE ALSO

L<Coro::PatchSet>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
