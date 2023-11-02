package App::HL7::Compare::Parser::Role::PartOfMessage;
$App::HL7::Compare::Parser::Role::PartOfMessage::VERSION = '0.003';
use v5.10;
use strict;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Standard qw(InstanceOf);
use Carp qw(croak);
use Moo::Role;

has param 'msg_config' => (
	isa => InstanceOf ['App::HL7::Compare::Parser::MessageConfig'],
	builder => '_build_msg_config_or_error',
);

sub _build_msg_config_or_error
{
	my ($self) = @_;

	my $builder = '_build_msg_config';
	return $self->$builder if $self->can($builder);
	croak 'Parameter msg_config is required';
}

1;

