#!/usr/bin/perl -W
package AI::MicroStructure::quad;
use strict;
use AI::MicroStructure::List;
our @ISA = qw( AI::MicroStructure::List );
our @List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;

__DATA__
# names
area
artefact
artifact
construction
entity
object
physical_entity
physical_object
quad
quadrangle
structure
unit
whole
