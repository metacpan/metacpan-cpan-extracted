# bug #67064

use strict;
use warnings;

use DateTime;
use DateTime::Incomplete;
use Test::More;

# 7am in America/Sao_Paulo (UTC-03)
# Note we need to specify up to nanosecond - otherwise previous() will return an hour like 07:59:59.999999
my $dti = DateTime::Incomplete->new(
    hour       => 7,
    minute     => 0,
    second     => 0,
    nanosecond => 0,
    time_zone  => 'America/Sao_Paulo'
);

# 2011-03-29T00:00:00 UTC
my $dt =
  DateTime->new( year => 2011, month => 03, day => 29, time_zone => 'UTC' );

{

    # when is it next 7am in Brazil?  ... should be 10am UTC.
    my $next   = $dti->next($dt);
    my $dt_str = $next->datetime . " " . $next->time_zone->name;
    print "# $dt_str\n";
    is( $dt_str, "2011-03-29T10:00:00 UTC", 'result timezone is UTC' );

    $dt_str = $dt->datetime . " " . $dt->time_zone->name;
    print "# $dt_str\n";
    is( $dt_str, "2011-03-29T00:00:00 UTC", '$dt is the same' );
}

{

    # when is it previous 7am in Brazil?  ... should be 10am UTC.
    my $previous = $dti->previous($dt);
    my $dt_str   = $previous->datetime . " " . $previous->time_zone->name;
    print "# $dt_str\n";
    is( $dt_str, "2011-03-28T10:00:00 UTC", 'result timezone is UTC' );

    $dt_str = $dt->datetime . " " . $dt->time_zone->name;
    print "# $dt_str\n";
    is( $dt_str, "2011-03-29T00:00:00 UTC", '$dt is the same' );
}

done_testing;

