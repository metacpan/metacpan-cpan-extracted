package Cron::Toolkit::Pattern::NearestWeekday;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';
use Cron::Toolkit::Utils qw(num_to_ordinal);

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{dom} = $args{dom};
    return $self;
}

sub type {
   return 'nearest_weekday';
}

sub match {
   my ( $self, undef, $tm ) = @_;
   my $day = $self->{dom};
   my $dom           = $tm->day_of_month;
   my $dow           = $tm->day_of_week;
   my $days_in_month = $tm->length_of_month;
   return 0 if $day < 1 || $day > $days_in_month;
   my $target_tm  = $tm->with_day_of_month($day);
   my $target_dow = $target_tm->day_of_week;

   if ( $target_dow >= 2 && $target_dow <= 5) {
      return $dom == $day ? 1 : 0;
   }
   my $before     = $target_tm->minus_days(1);
   my $after      = $target_tm->plus_days(1);
   my $before_dow = $before->day_of_week;
   my $after_dow  = $after->day_of_week;
   if ( $before_dow >= 1 && $before_dow <= 5 && $dom == $day - 1 ) {
      return 1;
   }
   if ( $after_dow >= 1 && $after_dow <= 5 && $dom == $day + 1 && $day + 1 <= $days_in_month ) {
      return 1;
   }
   return 0;
}

sub to_english {
   my $self = shift;
   return "on the nearest weekday to the " . num_to_ordinal($self->{dom});
}

1;


