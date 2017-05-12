#!/usr/bin/perl -W
package AI::MicroStructure::matter;
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
affair
attribute
be
cognitive_state
concern
condition
count
curiosity
entity
interest
involvement
least
matter
mental_condition
mental_state
phrasal_verb->_matter_to
psychological_condition
psychological_state
state
state_of_mind
status
thing
weigh
wonder
