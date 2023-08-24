package App::HL7::Compare::Parser::Segment;
$App::HL7::Compare::Parser::Segment::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Standard qw(Str);

use App::HL7::Compare::Parser::Field;

has field 'name' => (
	isa => Str,
	writer => -hidden,
);

with qw(
	App::HL7::Compare::Parser::Role::Partible
	App::HL7::Compare::Parser::Role::RequiresInput
	App::HL7::Compare::Parser::Role::Part
);

sub part_separator
{
	my ($self) = @_;

	return $self->msg_config->field_separator;
}

sub _build_parts
{
	my ($self) = @_;

	return $self->split_and_build($self->consume_input, 'App::HL7::Compare::Parser::Field');
}

sub BUILD
{
	my ($self, $args) = @_;

	my $input = $self->consume_input;
	my ($name, $rest) = split quotemeta($self->part_separator), $input, 2;
	$self->_set_name($name);
	$self->_set_input($rest);
}

1;

