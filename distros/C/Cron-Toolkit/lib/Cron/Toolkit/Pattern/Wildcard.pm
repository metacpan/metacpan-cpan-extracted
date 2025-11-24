package Cron::Toolkit::Pattern::Wildcard;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'wildcard';
}

sub match {
   return 1;
}

sub to_english {
   my $self = shift;
   return 'every ' . $self->english_unit;
}

1;
