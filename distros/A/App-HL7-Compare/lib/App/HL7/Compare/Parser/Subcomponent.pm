package App::HL7::Compare::Parser::Subcomponent;
$App::HL7::Compare::Parser::Subcomponent::VERSION = '0.004';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Standard qw(Str);

has field 'value' => (
	isa => Str,
	lazy => 1,
);

with qw(
	App::HL7::Compare::Parser::Role::Part
	App::HL7::Compare::Parser::Role::RequiresInput
	App::HL7::Compare::Parser::Role::Stringifies
);

sub _build_value
{
	my ($self) = @_;

	# TODO: unescape HL7 parts
	return $self->consume_input;
}

sub to_string
{
	my ($self) = @_;

	# TODO: escape HL7 parts
	return $self->value;
}

1;

