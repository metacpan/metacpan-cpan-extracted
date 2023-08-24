package App::HL7::Compare::Parser::Message;
$App::HL7::Compare::Parser::Message::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Types::Standard qw(Bool);

use App::HL7::Compare::Parser::Segment;
use App::HL7::Compare::Parser::MessageConfig;

has param 'skip_MSH' => (
	isa => Bool,
	default => sub { 1 },
);

with qw(
	App::HL7::Compare::Parser::Role::PartOfMessage
	App::HL7::Compare::Parser::Role::Partible
	App::HL7::Compare::Parser::Role::RequiresInput
);

sub part_separator
{
	my ($self) = @_;

	return $self->msg_config->segment_separator;
}

sub _build_parts
{
	my ($self) = @_;

	my $input = $self->consume_input;
	$self->msg_config->from_MSH($input);

	my $parts = $self->split_and_build($input, 'App::HL7::Compare::Parser::Segment');
	@{$parts} = grep { $_->name ne 'MSH' } @{$parts}
		if $self->skip_MSH;

	my %last_seen;
	foreach my $item (@{$parts}) {
		$item->set_number(++$last_seen{$item->name});
	}

	return $parts;
}

sub _build_msg_config
{
	my ($self) = @_;

	return App::HL7::Compare::Parser::MessageConfig->new;
}

1;

