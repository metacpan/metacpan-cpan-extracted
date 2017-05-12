#!/usr/bin/perl -W
package AI::MicroStructure::planet;
use strict;
use AI::MicroStructure::List;
our @ISA = qw( AI::MicroStructure::List );
our @List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;

__DATA__
# names
celestial_body
daystar
entity
evening_star
gas_giant
heavenly_body
hesperus
inferior_planet
jovian_planet
lucifer
major_planet
morning_star
natural_object
object
outer_planet
phosphorus
physical_entity
physical_object
planet
superior_planet
terrestrial_planet
unit
vesper
whole
