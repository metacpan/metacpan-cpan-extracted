#!/usr/bin/perl -W
package AI::MicroStructure::antimatter;
use strict;
use AI::MicroStructure::List;
our @ISA = qw( AI::MicroStructure::List );
our @List = qw( @{$structures{$structure}} );
__PACKAGE__->init();
1;

__DATA__
# names
antimatter
entity
matter
physical_entity
