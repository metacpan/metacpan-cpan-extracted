package Cron::Toolkit::Pattern::StepValue;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'step_value';
}

sub match {
    my ($self, $value) = @_;
    return $value == $self->value ? 1 : 0;
}

1;
