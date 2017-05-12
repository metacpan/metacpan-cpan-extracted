#!/usr/bin/perl

package Crypt::Random::Source::SSLeay;
use Moose;

extends qw(Crypt::Random::Source::Base);

use Net::SSLeay ();

our $VERSION = "0.02";

sub rank { 200 }

sub available { 1 }

sub seed {
	# RAND_add is documented but not implemented
	#my ( $self, @stuff ) = @_;
	#NET::SSLeay::RAND_add($_, length, 0) for @stuff;
}

__END__

=pod

=head1 NAME

Crypt::Random::Source::SSLeay - L<Net::SSLeay> support for
L<Crypt::Random::Source>

=head1 SYNOPSIS

	use Crypt::Random::Source::Strong::SSLeay;

	my $src = Crypt::Random::Source::Strong::SSLeay->new;

	my $random = $src->get(1024);

=head1 DESCRIPTION

This module implements L<Net::SSLeay> based random number generation for
L<Crypt::Random::Source>.

L<Net::SSLeay> does not wrap the SSL api, and C<RAND_bytes> is documented as
being cryptographically strong, so L<Crypt::Random::Source::Strong::SSLeay> is
also provided (as opposed to the other OpenSSL based sources).

=head1 METHODS

=over 4

=item get

Get 10 random or pseudorandom bytes (depending on strength) from
L<Net::SSLeay>.

=item seed

Currently unimplemented, but L<Net::SSLeay> documents C<RAND_add>. Might be
added in the future.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
