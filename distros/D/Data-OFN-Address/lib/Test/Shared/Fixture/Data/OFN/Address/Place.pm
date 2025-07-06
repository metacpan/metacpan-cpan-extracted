package Test::Shared::Fixture::Data::OFN::Address::Place;

use base qw(Data::OFN::Address);
use strict;
use warnings;

use Class::Utils qw(split_params);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	my ($object_params_ar) = split_params(['id'], @params);
	@params = (
		@{$object_params_ar},
		'address_place' => 'https://linked.cuzk.cz/resource/ruian/adresni-misto/16135661',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
