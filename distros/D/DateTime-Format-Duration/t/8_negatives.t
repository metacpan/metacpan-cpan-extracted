
use warnings;

use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;

#########################

use Test::More tests=>5;

$strf = DateTime::Format::Duration->new(
    base => DateTime->new( year=> 2003 ),
    pattern => '%F %r',
);

@tests = (
    { # 1 & 2
        pattern     =>  '%P%F %r',
        duration => {
            years   =>  2,
            months  =>  1,
            days    => 22,
            hours   => 11,
            minutes => -9,
        },
        diagnostic => 0,
        expect          => '0002-01-22 10:51:00',
        expect_duration => '-0002-01-22 11:09:00',
        title           => 'Mixed values with minor negative value',
    },
    { # 3 & 4
        pattern     =>  '%P%F %r',
        duration => {
            minutes => -1,
        },
        diagnostic => 0,
        expect          => '-0000-00-00 00:01:00',
        expect_duration => '-0000-00-00 00:01:00',
        title           => 'Single negative value',
    },
    { # 5 & 6
        pattern     =>  '%P%F %r',
        duration => {
            years   =>  -2,
            months  =>  1,
            days    => 22,
            hours   => 11,
            minutes => -9,
        },
        diagnostic => 0,
        expect     => '-0001-10-05 13:09:00',
        expect_duration => '-0002-01-22 11:09:00',
        title           => 'Mixed values with minor and major negatives',
    },
    { # 7 & 8
        pattern     =>  '%P%F %r',
        duration => {
            years   =>  -2,
            months  =>  -1,
            days    => -22,
            hours   => -11,
            minutes =>  -9,
        },
        diagnostic => 0,
        expect     => '-0002-01-22 11:09:00',
        expect_duration => '-0002-01-22 11:09:00',
        title           => 'All negative values',
    },
    { # 7 & 8
        pattern     =>  '%P%F %r',
        duration => {
            years   =>  2,
            months  =>  1,
            days    => 22,
            hours   => 11,
            minutes =>  9,
        },
        diagnostic => 0,
        expect     => '0002-01-22 11:09:00',
        expect_duration => '0002-01-22 11:09:00',
        title           => 'All positive values',
    },
);

foreach my $test (@tests) {
    $test->{title} ||= $test->{pattern};
    $strf->set_pattern( $test->{pattern} );
    $strf->{diagnostic} = 1 if $test->{diagnostic};
    is(
        $strf->format_duration_from_deltas( %{$test->{duration}} ),
        $test->{expect},
        $test->{title}
    ) or diag( "Failed on " . $test->{pattern} . "\n" .
               "Got: " . Dump( $test->{duration} ));
    $strf->{diagnostic} = 0;
}

sub Dump {
    eval{
        require Data::Dumper
    };
    return "<Couldn't load Data::Dumper>" if $@;
    return Data::Dumper::Dumper(@_)
}


