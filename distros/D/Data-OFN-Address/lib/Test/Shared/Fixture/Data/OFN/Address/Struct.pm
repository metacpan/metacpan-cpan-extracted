package Test::Shared::Fixture::Data::OFN::Address::Struct;

use base qw(Data::OFN::Address);
use strict;
use warnings;

use Class::Utils qw(split_params);
use Data::Text::Simple;
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	my ($object_params_ar) = split_params(['id'], @params);
	@params = (
		@{$object_params_ar},
		'house_number' => 12,
		'house_number_type' => decode_utf8('č.p.'),
		'municipality_name' => [
			Data::Text::Simple->new(
				'lang' => 'cs',
				'text' => decode_utf8('Horní Datová'),
			),
		],
		# XXX not standard, what about it?
		'note' => decode_utf8('dole u řeky'),
		'psc' => '33101',
		'street_name' => [
			Data::Text::Simple->new(
				'lang' => 'cs',
				'text' => decode_utf8('Hlavní'),
			),
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
