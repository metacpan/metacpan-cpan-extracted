package DateTimeX::Lite;
use strict;

sub month_0 { $_[0]->{local_c}{month} - 1 }
sub mon_0 { goto &month_0 };
sub quarter_0 { $_[0]->{local_c}{quarter} - 1 }

sub day_of_month_0 { $_[0]->{local_c}{day} - 1 }
*day_0  = \&day_of_month_0;
*mday_0 = \&day_of_month_0;

sub day_of_week_0 { $_[0]->{local_c}{day_of_week} - 1 }
*wday_0 = \&day_of_week_0;
*dow_0  = \&day_of_week_0;

sub day_of_quarter_0 { $_[0]->day_of_quarter - 1 }
*doq_0 = \&day_of_quarter_0;

sub day_of_year_0 { $_[0]->{local_c}{day_of_year} - 1 }
*doy_0 = \&day_of_year_0;

sub hour_12_0 { $_[0]->hour % 12 }

1;