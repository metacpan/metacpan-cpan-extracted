#!/usr/bin/perl -W
package AI::MicroStructure::atom;
use strict;
use AI::MicroStructure::List;
our @ISA = qw( AI::MicroStructure::List );
our @List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;

__DATA__
# names
abstract_entity
abstraction
atom
carbon_atom
component
component_part
constituent
entity
free_radical
hydrogen_atom
isotope
matter
monad
part
physical_entity
portion
radical
relation
substance
