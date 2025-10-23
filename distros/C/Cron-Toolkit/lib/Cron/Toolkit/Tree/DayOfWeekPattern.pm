package Cron::Toolkit::Tree::DayOfWeekPattern;
use strict;
use warnings;
use parent 'Cron::Toolkit::Tree::LeafPattern';
use Carp qw(croak);
use Cron::Toolkit::Tree::Utils qw(num_to_ordinal);
my %day_names = (1=>'Sunday', 2=>'Monday', 3=>'Tuesday', 4=>'Wednesday', 5=>'Thursday', 6=>'Friday', 7=>'Saturday');

sub to_english {
    my ($self) = @_;
    if ($self->{type} eq 'nth') {
        my ($day, $nth) = $self->{value} =~ /(\d+)#(\d+)/;
        return num_to_ordinal($nth) . " " . $day_names[$day] . " of every month";
    } elsif ($self->{type} eq 'single') {
        return "every " . $day_names[$self->{value}];
    }
    return $self->SUPER::to_english();
}

1;
