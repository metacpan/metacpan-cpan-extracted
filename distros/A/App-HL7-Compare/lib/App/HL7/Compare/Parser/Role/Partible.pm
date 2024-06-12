package App::HL7::Compare::Parser::Role::Partible;
$App::HL7::Compare::Parser::Role::Partible::VERSION = '0.004';
use v5.10;
use strict;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Standard qw(ArrayRef ConsumerOf);
use List::Util qw(first);
use App::HL7::Compare::Exception;
use Moo::Role;

has field 'parts' => (
	isa => ArrayRef [ConsumerOf ['App::HL7::Compare::Parser::Role::Part']],
	lazy => 1,
);

with qw(
	App::HL7::Compare::Parser::Role::Stringifies
	App::HL7::Compare::Parser::Role::PartOfMessage
);

requires qw(
	part_separator
	_build_parts
);

sub to_string
{
	my ($self) = @_;

	my $parts = $self->parts;
	return '' unless @{$parts} > 0;

	return join $self->part_separator, map { $_->to_string } @{$parts};
}

sub _trimmed
{
	my ($self, $value) = @_;

	$value =~ s/\A\s+//;
	$value =~ s/\s+\z//;
	return $value;
}

sub split_and_build
{
	my ($self, $string_to_split, $class_to_build) = @_;

	my @parts = map { $self->_trimmed($_) } split quotemeta($self->part_separator), $string_to_split, -1;

	App::HL7::Compare::Exception->raise("empty value for $class_to_build in: <$string_to_split>")
		if @parts == 0;

	return [
		map {
			$class_to_build->new(
				msg_config => $self->msg_config,
				number => $_ + 1,
				input => $parts[$_],
			)
		} grep {
			length $parts[$_] > 0
		} 0 .. $#parts
	];
}

1;

