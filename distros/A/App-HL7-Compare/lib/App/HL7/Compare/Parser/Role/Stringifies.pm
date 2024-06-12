package App::HL7::Compare::Parser::Role::Stringifies;
$App::HL7::Compare::Parser::Role::Stringifies::VERSION = '0.004';
use v5.10;
use strict;
use warnings;

use Moo::Role;

requires qw(
	to_string
);

1;

