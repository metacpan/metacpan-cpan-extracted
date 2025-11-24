package Cron::Toolkit::Pattern::Single;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'single';
}

sub match {
    my ($self, $value) = @_;
    return $value == $self->value ? 1 : 0;
}

sub to_english {
   my ($self) = @_;
   my $rv = $self->english_value;
   $rv = $self->field_type . " " . $rv if $self->field_type =~ /^second|minute|hour$/;
   return $rv;
}

1;
