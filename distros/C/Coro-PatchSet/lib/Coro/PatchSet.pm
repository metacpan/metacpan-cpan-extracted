package Coro::PatchSet;

use strict;
use Carp;

our $VERSION = '0.13';

my %known_classes = (
	socket => 'Coro/PatchSet/Socket.pm',
	handle => 'Coro/PatchSet/Handle.pm',
	lwp    => 'Coro/PatchSet/LWP.pm',
);

sub import {
	my ($class, @import) = @_;
	
	unless (@import) {
		@import = keys %known_classes;
	}
	
	for my $class (@import) {
		$class = lc $class;
		
		unless (exists $known_classes{$class}) {
			croak "doesn't know how to patch `$class'";
		}
		
		if ($class eq 'lwp' && @_ == 1) {
			# Net::HTTP and others may be not installed
			eval { require $known_classes{$class} }
		}
		else {
			require $known_classes{$class};
		}
	}
}

1;

__END__

=pod

=head1 NAME

Coro::PatchSet - fix Coro as much as possible

=head1 SYNOPSIS

    use Coro::PatchSet;
    
    #or
    
    use Coro::PatchSet 'socket';
    
    #or
    
    use Coro::PatchSet qw'socket handle';

=head1 DESCRIPTION

This distribution contains set of submodules each of which patches some known bugs from submodule with the same name
from Coro distribution. Read documentation for each submodule to know which bugs it will fix for you.
Use this module as first example in the L</SYNOPSIS> section and it will load all patches. Or you can specify which
patches you want to load, like in the second and third examples. Or you can directly use one of submodule.

=head1 WHY

Coro is great. But unfortunately its author is very unresponsive. I didn't receive any answer for my emails with
reports and patches, not from personal emails, nor from AnyEvent mail list. So it is easier for me to collect all
fixes in one place and use when I need it.

=head1 COMPATIBILITY

In general it should work with latest Coro versions. But in fact you should run tests from this package to know is it
works for you. So, try to install it and if this will ok, then it is probably compatible with your Coro distribution.

=head1 SEE ALSO

L<Coro::PatchSet::Socket>, L<Coro::PatchSet::Handle>, L<Coro::PatchSet::LWP>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
