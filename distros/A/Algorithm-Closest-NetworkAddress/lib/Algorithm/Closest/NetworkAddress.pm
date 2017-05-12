package Algorithm::Closest::NetworkAddress;

use 5.008004;
use strict;
use warnings;
use Carp;

our $VERSION = '0.1';

use Class::Struct;
struct 'Algorithm::Closest::NetworkAddress' => {
	network_address_list => '@',
	};


sub measure {
	my $self = shift;
	my ($a, $b) = @_;
	my @a = split('\.', $a);
	my @b = split('\.', $b);
	if ($a =~ /^\d+\.\d+\.\d+\.\d+$/) {
		return _recursive_match(\@a, \@b, 0);
	} else {
		@a = reverse @a;
		@b = reverse @b;
		return _recursive_match(\@a, \@b, 0);
	}
}

sub _recursive_match {
	my ($y, $z, $level) = @_;
	my $a = shift @$y;
	my $b = shift @$z;
	if (defined $a && defined $b && $a eq $b) {
		return _recursive_match($y, $z, $level+1);
	} else {
		return $level;
	}
}


=head1 NAME

Algorithm::Closest::NetworkAddress - finds the closest network address from a defined list

=head1 DESCRIPTION

Given a network address (IP address or fully qualified DNS name) and a list of other
addresses, will return the name with the closest match. "Closest" is
defined as exactly the same tuple from the back (for DNS names) or
from the front (for IP addresses).

=head1 METHODS

=head2 Algorithm::Closest::NetworkAddress->new(network_address_list => ["mon.der.altinity", "mon.lon.altinity", "mon.ny.altinity", "10.20.30.40"]);

Creates an object containing the list of addresses to compare against

=head2 $self->compare($network_address)

Will find the best match in the network_address_list for the network_address specified.
Returns the network address that best matches.

=cut

sub compare {
	my ($self, $target) = @_;
	carp "Must specify a target" unless defined $target;
	my $best_na;
	my $best_level = 0;
	foreach my $na (@{$self->network_address_list}) {
		my $r = $self->measure($na, $target);
		if ($r > $best_level) {
			$best_level = $r;
			$best_na = $na;
		}
	}
	return $best_na || 0;
}

=head1 AUTHOR

Ton Voon C<ton.voon@altinity.com>

=head1 COPYRIGHT

Copyright 2006 Altinity Limited

=head1 LICENSE

GPL

=cut

1;
