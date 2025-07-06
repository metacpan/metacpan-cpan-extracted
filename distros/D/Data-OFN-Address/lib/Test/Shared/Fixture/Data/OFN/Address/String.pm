package Test::Shared::Fixture::Data::OFN::Address::String;

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
		'text' => [
			Data::Text::Simple->new(
				'lang' => 'cs',
				'text' => decode_utf8('Pod Panskou strání 262/12, Chvojkonosy, 33205 Lysostírky'),
			),
		],
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
