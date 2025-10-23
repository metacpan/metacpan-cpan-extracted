package Cron::Toolkit::Tree::RangePattern;
use strict;
use warnings;
use parent 'Cron::Toolkit::Tree::CompositePattern';
use Carp qw(croak);
use Cron::Toolkit::Tree::Utils qw(num_to_ordinal);

sub to_english {
    my ($self, $field_type) = @_;
    my ($start, $end) = $self->get_children;
    my $start_desc = num_to_ordinal($start->{value});
    my $end_desc = num_to_ordinal($end->{value});
    return "$start_desc through $end_desc" if $field_type eq 'dom';
    return "$start->{value}-$end->{value}";
}

1;
