package Cron::Toolkit::Pattern::Range;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{wrapped} = $args{wrapped} // 0;
    return $self;
}

sub type {
   return 'range';
}

sub match {
    my ($self, $value, $tm) = @_;
    my $min = $self->{children}[0]{value};
    my $max = $self->{children}[1]{value};
    if ($self->field_type eq 'dow' && $self->{wrapped}) {
        # Wrapped range: e.g. 6-2 = 6,7,1,2
        return $value >= $min || $value <= $max;
    }
    return $value >= $min && $value <= $max;
}

sub to_english {
   my ($self) = @_;
   my $from = $self->{children}[0]->english_value; 
   my $to   = $self->{children}[1]->english_value; 
   return "every " . $self->english_unit . " from $from to $to";
}

1;
