use strict;
use warnings;

use Test::More;
use Data::Random qw( rand_time );


# Test default w/ no params
test_range();

# Test min option
test_range('4:0:0');

# Test max option
test_range(undef, '4:0:0');

# Test min + max options
test_range('9:0:0', '10:0:0');

# Test min + max options using "now"
{
    # Technically, the clock could roll over to a new second between these two statements.
    # But I don't think I'm going to worry about it unless we see a failure here from CPAN Testers.
    my $time = rand_time( min => 'now', max => 'now' );
    my ( $hour, $min, $sec ) = ( localtime() )[ 2, 1, 0 ];

    my ( $new_hour, $new_min, $new_sec ) = split ( /\:/, $time );

    ok($new_hour == $hour && $new_min == $min && $new_sec == $sec, "random time constrained to a second works");
}

done_testing;


sub test_range
{
    my ($min, $max) = @_;
    my $min_secs = defined $min ? _to_secs($min) : 0;
    my $max_secs = defined $max ? _to_secs($max) : _to_secs('23:59:59');

    my @args;
    push @args, min => $min if defined $min;
    push @args, max => $max if defined $max;

    # Running once for every possible value doesn't actually guarantee that we will _get_ every
    # possible value, of course, since it's a randomly generated time.  Running 10 times for every
    # possible value pretty much guarantees that, but it also takes forever.  So let's run 10x in
    # the case of automated testers (like CPAN Testers), and just half that many otherwise (to keep
    # installs speedy).
    my $num_tests = $max_secs - $min_secs + 1;
    $num_tests *= $ENV{AUTOMATED_TESTING} ? 10 : .5;

    my $num_errors = 0;
    my $test_name = "all randomly generated values within range";
    for ( 1..$num_tests )
    {
        my $time = rand_time(@args);
        my $secs = _to_secs($time);

        unless (defined $secs && $min_secs <= $secs && $secs <= $max_secs)
        {
            fail($test_name);
            diag "time out of range: $time";
            ++$num_errors;
        }
    }

    pass($test_name) unless $num_errors;
}


sub _to_secs {
    my $time = shift;

    my ( $hour, $min, $sec ) = split ( /\:/, $time );

    return undef if ( $hour > 23 ) || ( $hour < 0 );
    return undef if ( $min > 59 )  || ( $min < 0 );
    return undef if ( $sec > 59 )  || ( $sec < 0 );

    return $hour * 3600 + $min * 60 + $sec;
}
