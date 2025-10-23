package Cron::Toolkit::Tree::StepPattern;
use strict;
use warnings;
use parent 'Cron::Toolkit::Tree::CompositePattern';
use Carp qw(croak);

sub to_english {
    my ($self, $field_type) = @_;
    my ($base, $step_val) = $self->get_children;
    my $step_num = $step_val->{value};
    my $base_desc = $base->to_english($field_type);
    my $unit = $step_num > 1 ? $field_type . 's' : $field_type;
    return "every $step_num $unit from $base_desc";
}

1;
