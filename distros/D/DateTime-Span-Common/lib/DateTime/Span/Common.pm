package DateTime::Span::Common;

our $VERSION = '0.03';

use Moose;
use Moose::Util::TypeConstraints;

subtype 'DayName'
      => as Str
      => where {
	  /Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday/ ;
         };


has 'week_start_day' => (isa => 'DayName', is => 'rw', default => 'Sunday') ;

use DateTime;
use DateTime::Span;

sub set_eod {
    my($self, $dt)=@_;

    $dt->set(hour => 23, minute => 59,  second => 59);
}

# now, but with HH:MM::SS = 23:59:59
sub DateTime::nowe {

    my $now = DateTime->now;
    set_eod(undef, $now);

}

sub DateTime::Span::datetimes {
    my ($datetime_span)=@_;

    ($datetime_span->start, $datetime_span->end);
}

sub DateTime::Span::from_array {
    my ($self, $start,$end)=@_;

    #warn "$start , $end";

    DateTime::Span->from_datetimes( start => $start, end => $end ) ;
}


sub today {

    my $now = DateTime->nowe;
    my $sod = DateTime->now->truncate(to => 'day');


    DateTime::Span->from_datetimes( start => $sod, end => $now ) ;
}

sub yesterday {
    my $t = today;

    my @a = map { $_->subtract(days => 1) } ($t->datetimes) ;
    
    DateTime::Span->from_array(@a);
}

sub this_week {
    my($self)=@_;

    my $now = DateTime->nowe;
    my $sow = DateTime->now->truncate(to => 'day');

    return today if $sow->day_name eq $self->week_start_day ;

    while ($sow->day_name ne $self->week_start_day) {

	$sow->subtract(days => 1) ;

    }

    DateTime::Span->from_datetimes( start => $sow, end => $now ) ;
}

sub last_week {
    my ($self)=@_;

    my ($sow, undef) = $self->this_week->datetimes;
   
    my $eow = $sow->clone;

    $sow->subtract(days => 7) ;

    $eow->subtract(days => 1) ;
    $eow->set(hour => 23, minute => 59, second => 59);


    DateTime::Span->from_datetimes( start => $sow, end => $eow ) ;
}

sub this_month {

    my ($self)=@_;

    my ($som, $nowe) = $self->today->datetimes;
   
    $som->set(day => 1);

    DateTime::Span->from_datetimes( start => $som, end => $nowe ) ;
}

sub this_year {
    my($self)=@_;

    my ($soy, $nowe) = $self->this_month->datetimes;
   
    $soy->set(day => 1, month => 1);

    DateTime::Span->from_datetimes( start => $soy, end => $nowe ) ;
}

sub last_year {
    my($self)=@_;

    my ($soy, $eoy) = $self->this_year->datetimes;
   
    $soy->subtract(years => 1);

    $eoy->subtract(years => 1);
    $eoy->set(month => 12, day => 31);

    DateTime::Span->from_datetimes( start => $soy, end => $eoy ) ;
}


1; # End of DateTime::Span::Common
