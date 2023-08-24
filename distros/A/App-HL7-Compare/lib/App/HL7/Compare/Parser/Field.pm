package App::HL7::Compare::Parser::Field;
$App::HL7::Compare::Parser::Field::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;

use App::HL7::Compare::Parser::Component;

with qw(
	App::HL7::Compare::Parser::Role::Partible
	App::HL7::Compare::Parser::Role::Part
	App::HL7::Compare::Parser::Role::RequiresInput
);

sub part_separator
{
	my ($self) = @_;

	return $self->msg_config->component_separator;
}

sub _build_parts
{
	my ($self) = @_;

	return $self->split_and_build($self->consume_input, 'App::HL7::Compare::Parser::Component');
}

1;

