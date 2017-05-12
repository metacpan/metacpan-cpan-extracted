#!/usr/bin/perl

package Crypt::Random::Source::Weak::SSLeay;
use Moose;

extends qw(
	Crypt::Random::Source::Weak
	Crypt::Random::Source::SSLeay
);

sub get {
	my ( $self, $n ) = @_;
	Net::SSLeay::RAND_pseudo_bytes(my $buf, $n);
	return $buf;
}

__PACKAGE__

__END__
