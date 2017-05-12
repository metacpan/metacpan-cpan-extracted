use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok 'Business::Hours' }

{
    my $hours = Business::Hours->new();
    is(ref($hours), 'Business::Hours');
    # how many business hours were there in the first week.
    my $hours_span = $hours->for_timespan(Start => '0', End => ( (86400 * 7) - 1));
    is(ref($hours_span), 'Set::IntSpan');

    # Are there 45 working hours

    is(cardinality $hours_span, (45 * 60 * 60));
}

{
    my $hours = Business::Hours->new();
    is(ref($hours), 'Business::Hours');
    # how many business hours were there in the first week.
    my $seconds = $hours->between( 0, ( (86400 * 7) - 1 ) );
    ok( $seconds, "Got seconds" );

    # Are there 45 working hours
    is( $seconds, (45 * 60 * 60) );
}

{
    my $hours = Business::Hours->new();
    my $time;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my $starttime;

    # pick a date that's during business hours
    $starttime = 0;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    while ($wday == 0  || $wday == 6) {
	$starttime += ( 24 * 60 * 60);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    }
    while ( $hour < 9 || $hour >= 18 ) {
	$starttime += ( 4 * 60);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    }

    $time = $hours->first_after( $starttime );
    is($time, ( $starttime ));

    # pick a date that's not during business hours
    $starttime = 0;
    my ($xsec,$xmin,$xhour,$xmday,$xmon,$xyear,$xwday,$xyday,$xisdst) = localtime($starttime);
    while ( $xwday != 0 ) {
	$starttime += ( 24 * 60 * 60);
	($xsec,$xmin,$xhour,$xmday,$xmon,$xyear,$xwday,$xyday,$xisdst) = localtime($starttime);
    }

    $time = $hours->first_after( $starttime );
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    is($wday, $xwday+1);
    is($hour, 9);
    is($min, 0);
    is($sec, 0);
}


{
    my $hours = Business::Hours->new();

    my ($start, $time, $span);
    # pick a date that's during business hours
    $start = (20 * 60 * 60);
    $time = $hours->add_seconds( $start, 30 * 60);
    $span = $hours->for_timespan(Start => $start, End => $time);

    # the first second is a business second, too
    is(cardinality $span, (30 * 60)+1);

    # pick a date that's not during business hours
    $start = 0;
    $time = $hours->add_seconds( $start, 30 * 60);
    $span = $hours->for_timespan(Start => $start, End => $time);

    # the first second is a business second, too
    is(cardinality $span, (30 * 60)+1);
}

{
    my %BUSINESS_HOURS = (
			  0 => {
			      Name  => 'Sunday',
			      Start => undef,
			      End   => undef,
			  },
			  1 => {
			      Name  => 'Monday',	
			      Start => '9:00',
			      End   => '18:00',
			      Breaks => [
					 {
					     Start => '13:00',
					     End   => '14:00',
					 },
					 ],
			  },
			  2 => {
			      Name  => 'Tuesday', 
			      Start => '9:00',
			      End   => '18:00',
			      Breaks => [
					 {
					     Start => '13:00',
					     End   => '14:00',
					 },
					 ],
			  },
			  3 => {
			      Name  => 'Wednesday',
			      Start => '9:00',
			      End   => '18:00',
			      Breaks => [
					 {
					     Start => '13:00',
					     End   => '14:00',
					 },
					 ],
			  },
			  4 => {
			      Name  => 'Thursday',
			      Start => '9:00',
			      End   => '18:00',
			      Breaks => [
					 {
					     Start => '13:00',
					     End   => '14:00',
					 },
					 ],
			  },
			  5 => {
			      Name  => 'Friday',
			      Start => '9:00',
			      End   => '18:00',
			      Breaks => [
					 {
					     Start => '13:00',
					     End   => '14:00',
					 },
					 ],
			  },
			  6 => {
			      Name  => 'Saturday',
			      Start => undef,
			      End   => undef,
			  });
    my $hours = Business::Hours->new();
    $hours->business_hours(%BUSINESS_HOURS);
    is(ref($hours), 'Business::Hours');
    # how many business hours were there in the first week.
    my $hours_span = $hours->for_timespan(Start => '0', End => ( (86400 * 7) - 1));
    is(ref($hours_span), 'Set::IntSpan');

    # Are there 40 working hours

    is(cardinality $hours_span, (40 * 60 * 60));
}

