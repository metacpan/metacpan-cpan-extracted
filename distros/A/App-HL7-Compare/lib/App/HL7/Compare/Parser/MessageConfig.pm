package App::HL7::Compare::Parser::MessageConfig;
$App::HL7::Compare::Parser::MessageConfig::VERSION = '0.003';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Common::String qw(StrLength);
use Carp qw(croak);

has param 'segment_separator' => (
	isa => StrLength [1, 2],
	writer => 1,
	default => sub { "\n" },
);

has option 'field_separator' => (
	isa => StrLength [1, 1],
	writer => 1,
);

has option 'component_separator' => (
	isa => StrLength [1, 1],
	writer => 1,
);

has option 'repetition_separator' => (
	isa => StrLength [1, 1],
	writer => 1,
);

has option 'escape_character' => (
	isa => StrLength [1, 1],
	writer => 1,
);

has option 'subcomponent_separator' => (
	isa => StrLength [1, 1],
	writer => 1,
);

sub from_MSH
{
	my ($self, $input) = @_;
	$input =~ s/\AMSH//;

	my @order = qw(
		field_separator
		component_separator
		repetition_separator
		escape_character
		subcomponent_separator
	);

	croak 'Not enough input to read message control characters'
		unless length $input >= @order;

	my @characters = split //, substr $input, 0, scalar @order;
	foreach my $field (@order) {
		my $setter = "set_$field";
		my $predicate = "has_$field";

		my $character = shift @characters;
		next if $self->$predicate;
		$self->$setter($character);
	}
}

1;

