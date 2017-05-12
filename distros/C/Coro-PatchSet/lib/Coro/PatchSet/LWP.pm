package Coro::PatchSet::LWP;

use strict;
use Coro::Select;
BEGIN {
	eval {
		*IO::Socket::SSL::tie = *IO::Socket::SSL::untie = sub{}; # prevent overriding of our tie mechanism
		require IO::Socket::SSL;
	};
	# for those who want to use LWP::Protocol::socks
	$IO::Socket::Socks::SOCKET_CLASS = Coro::LWP::Socket::;
}
use Coro::LWP;
use Coro::PatchSet::Handle;
use Coro::PatchSet::Socket;

our $VERSION = '0.13';

for (@Net::HTTP::ISA, @Net::FTP::ISA, @Net::NTTP::ISA) {
	$_ = Coro::LWP::Socket::
		if $_ eq IO::Socket::INET6:: || $_ eq IO::Socket::IP::;
}

$IO::Socket::SSL::ISA[0] = Coro::LWP::Socket:: if IO::Socket::SSL->can('new');

1;

__END__

=pod

=head1 NAME

Coro::PatchSet::LWP - fix Coro::LWP as much as possible

=head1 SYNOPSIS

    # load Coro::PatchSet::LWP before Coro::LWP or instead of Coro::LWP!
    use Coro::PatchSet::LWP;
    # or
    # use Coro::PatchSet 'lwp';
    use Coro;
    use LWP;
    
    async { warn LWP::UserAgent->new->get('http://example.org')->status_line }

=head1 PATCHES

=head2 support for IO::Socket::INET6 and IO::Socket::IP

Nowadays LWP may use IO::Socket::INET6 or IO::Socket::IP as socket class instead of IO::Socket::INET.
But Coro::LWP substitutes only IO::Socket::INET. So your LWP may become blocking because will still
use blocking IO::Socket::INET6 or IO::Socket::IP. This patch fixes this. But note, it will not add
IPv6 support for LWP, because  Coro::Socket is still IPv4 only. See t/09_lwp_socket_class.t

=head2 coro compatible support for https

Coro::LWP doesn't do any special hacks about https, so https connections still blocks coro threads.
This patch fixes this problem, but don't forget to load it before IO::Socket::SSL, so C<use> it as early as
possible.

=head2 loading other necessary patches

This patch will also load other necessary patches: Coro::PatchSet::Handle and Coro::PatchSet::Socket

=head1 SEE ALSO

L<Coro::PatchSet>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
