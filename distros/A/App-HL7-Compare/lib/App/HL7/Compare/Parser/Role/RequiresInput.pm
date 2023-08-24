package App::HL7::Compare::Parser::Role::RequiresInput;
$App::HL7::Compare::Parser::Role::RequiresInput::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Standard qw(Str);
use App::HL7::Compare::Exception;
use Moo::Role;

has param 'input' => (
	isa => Str,
	writer => -hidden,
	predicate => -hidden,
	clearer => -hidden,
);

sub consume_input
{
	my ($self) = @_;

	App::HL7::Compare::Exception->raise('input already consumed')
		unless $self->_has_input;

	my $input = $self->input;
	$self->_clear_input;

	return $input;
}

1;

