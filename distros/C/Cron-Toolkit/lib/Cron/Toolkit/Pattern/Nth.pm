package Cron::Toolkit::Pattern::Nth;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';
use Cron::Toolkit::Utils qw(:all);

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{dow} = $args{dow};
    $self->{nth} = $args{nth};
    return $self;
}

sub type {
   return 'nth';
}

sub match {
    my ($self, $value, $tm) = @_;
    my $target_dow = $self->{dow};
    my $nth        = $self->{nth};
    my $dom        = $tm->day_of_month;

    my $count = 0;
    for my $d (1 .. $dom - 1) {
        $count++ if $tm->with_day_of_month($d)->day_of_week == $target_dow;
    }

    return 0 unless $tm->day_of_week == $target_dow;
    return $count + 1 == $nth;
}

sub to_english {
   my ($self) = @_;
   my $day = $DAY_NAMES{ $self->{dow} };
   my $nth = num_to_ordinal( $self->{nth} );
   return "on the $nth $day";
}

1;
