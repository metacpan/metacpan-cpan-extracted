package App::HL7::Compare::Parser::Role::Part;
$App::HL7::Compare::Parser::Role::Part::VERSION = '0.003';
use v5.10;
use strict;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common::Numeric qw(PositiveInt);
use Moo::Role;

has param 'number' => (
	isa => PositiveInt,
	writer => 1,
);

with qw(
	App::HL7::Compare::Parser::Role::PartOfMessage
);

1;

