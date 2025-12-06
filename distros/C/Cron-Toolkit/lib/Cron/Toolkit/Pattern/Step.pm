package Cron::Toolkit::Pattern::Step;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'step';
}

sub match {
   my ($self, $value) = @_;
   my $step = $self->{children}[1]{value};
   return 0 if $step <= 0;
   my $base = $self->{children}[0];

   if ( $base->type eq 'wildcard' ) {
      return $value % $step == 0 ? 1 : 0;
   }
   elsif ( $base->type eq 'single' ) {
      return $value >= $base->value && ( $value - $base->value ) % $step == 0 ? 1 : 0;
   }
   elsif ( $base->type eq 'range' ) {
      my $min = $base->{children}[0]{value};
      my $max = $base->{children}[1]{value};
      return $value >= $min && $value <= $max && ( $value - $min ) % $step == 0 ? 1 : 0;
   }
   return 0;
}

sub to_english {
   my ($self) = @_;

   my $step = $self->{children}[1]{value};
   my $base = $self->{children}[0];
   my $rv = "every $step " . $self->english_unit;
   $rv .= 's' unless $step == 1;

   if ( $base->type eq 'range' ) {
      my $from = $base->{children}[0]->english_value;
      my $to   = $base->{children}[1]->english_value;
      $rv .= " from $from to $to";
   }
   elsif ($base->type eq 'single') {
      $rv .= ' starting ';
      $rv .= $base->field_type =~ /^second|minute|hour$/ ? 'at ' : 'on ';
      $rv .= $base->english_value;
   }
   return $rv;
}

1;
