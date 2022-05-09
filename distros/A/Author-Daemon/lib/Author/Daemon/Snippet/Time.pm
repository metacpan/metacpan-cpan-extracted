package Author::Daemon::Snippet::Time;

use v5.28;
use warnings;
use strict;
use experimental 'signatures';

sub new ($class) {
    my $self = {
        'month_as_short' => [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ],
        'day_as_short' => [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thr', 'Fri', 'Sat' ]
    };

    bless $self, $class;
    return $self;
}

sub better_localtime ( $self, $template = undef ) {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    # Create a place to store our object
    my $time_object = {
        'second'           => sprintf( "%02d", $sec ),
        'minute'           => sprintf( "%02d", $min ),
        'hour'             => sprintf( "%02d", $hour ),
        'month_day'        => sprintf( "%02d", $mday + 1 ),
        'month_short'      => $self->{'month_as_short'}->[$mon],
        'month'            => sprintf( "%02d", $mon + 1 ),
        'year'             => $year + 1900,
        'weekday'          => $wday ? $wday : 7,
        'weekday_as_short' => $self->{'day_as_short'}->[$wday],
        'year_day'         => sprintf( "%03d", $yday + 1 )
    };

    # Do we have a template?
    if ($template) {
        my $check_forward = sub ( $name = '' ) {
            defined $time_object->{$name}
              ? $time_object->{$name}
              : '__' . $name . '__';
        };
        $template =~ s#__([a-z_]+)__#$check_forward->($1)#ge;
    }

    return $template;
}


1;
