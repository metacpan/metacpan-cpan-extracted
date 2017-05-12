#!/usr/bin/perl

package Crypt::Random::Source::Strong::SSLeay;
use Moose;

use Net::SSLeay ();

extends qw(
	Crypt::Random::Source::Strong
	Crypt::Random::Source::SSLeay
);

sub get {
	my ( $self, $n ) = @_;
	Net::SSLeay::RAND_pseudo_bytes(my $buf, $n);
	return $buf;
}

__PACKAGE__

__END__
