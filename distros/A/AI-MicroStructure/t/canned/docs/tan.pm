#!/usr/bin/perl -W
package AI::MicroStructure::tan;
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
circular_function
entity
function
map
mapping
mathematical_function
mathematical_relation
relation
single-valued_function
tan
tangent
trigonometric_function
