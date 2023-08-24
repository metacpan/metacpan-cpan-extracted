package App::HL7::Compare::Parser::Component;
$App::HL7::Compare::Parser::Component::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;

use App::HL7::Compare::Parser::Subcomponent;

with qw(
	App::HL7::Compare::Parser::Role::Partible
	App::HL7::Compare::Parser::Role::Part
	App::HL7::Compare::Parser::Role::RequiresInput
);

sub part_separator
{
	my ($self) = @_;

	return $self->msg_config->subcomponent_separator;
}

sub _build_parts
{
	my ($self) = @_;

	return $self->split_and_build($self->consume_input, 'App::HL7::Compare::Parser::Subcomponent');
}

1;

