#!/usr/bin/perl -W
package AI::MicroStructure::planets;
use strict;
use AI::MicroStructure::List;
our @ISA = qw( AI::MicroStructure::List );
our @List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;

__DATA__
# names
celestial_body
entity
heavenly_body
natural_object
object
physical_entity
physical_object
planet
unit
whole
