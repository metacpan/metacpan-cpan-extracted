package Cron::Toolkit::Pattern::LastW;
use strict;
use warnings;
use parent 'Cron::Toolkit::Pattern';

sub type {
   return 'lastW';
}

sub match {
   my ($self, $value, $tm) = @_;
   my $dom           = $tm->day_of_month;
   my $days_in_month = $tm->length_of_month;
   my $candidate     = $days_in_month;
   while ( $candidate >= 1 ) {
      my $test_tm  = $tm->with_day_of_month($candidate);
      my $test_dow = $test_tm->day_of_week;
      if ( $test_dow >= 1 && $test_dow <= 5 ) {
         return $dom == $candidate ? 1 : 0;
      }
      $candidate--;
   }
   return 0;
}

sub to_english {
   return 'on the last weekday';
}

1;
