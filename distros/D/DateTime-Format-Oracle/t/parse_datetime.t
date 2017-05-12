use strict;
use Test::More tests => 4 * 7; # strings * methods

use DateTime::Format::Oracle;

my $class = 'DateTime::Format::Oracle';

my %tests = (
    '2003-02-15' => {
        format    => 'YYYY-MM-DD',
        year      => 2003,
        month     => 2,
        day       => 15,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'floating',
    },
    '15-FEB-03' => {
        format    => 'DD-MON-RR',
        year      => 2003,
        month     => 2,
        day       => 15,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'floating',
    },
    '2003-02-15 14:39:06' => {
        format    => 'YYYY-MM-DD HH24:MI:SS',
        year      => 2003,
        month     => 2,
        day       => 15,
        hour      => 14,
        minute    => 39,
        second    => 6,
        time_zone => 'floating',
    },
    '15-FEB-03 02.39.06.167901 PM' => {
        format    => 'DD-MON-RR HH.MI.SSXFF AM',
        year      => 2003,
        month     => 2,
        day       => 15,
        hour      => 14,
        minute    => 39,
        second    => 6,
        time_zone => 'floating',
    },
    # time zone parsing seems to not work in DateTime::Format::Builder
    #'2003-02-15 14:39:06 AMERICA/NEW_YORK' => {
    #    format    => 'YYYY-MM-DD HH24:MI:SS TZR',
    #    year      => 2003,
    #    month     => 2,
    #    day       => 15,
    #    hour      => 14,
    #    minute    => 39,
    #    second    => 6,
    #    time_zone => 'America/New_York',
    #},
    #'15-FEB-03 02.39.06.167901 PM AMERICA/NEW_YORK' => {
    #    format    => 'DD-MON-RR HH.MI.SSXFF AM TZR',
    #    year      => 2003,
    #    month     => 2,
    #    day       => 15,
    #    hour      => 14,
    #    minute    => 39,
    #    second    => 6,
    #    time_zone => 'America/New_York',
    #},
);

foreach my $string (keys %tests) {
    my $params = $tests{$string};
    my $nls_format = delete $params->{format};
    local $ENV{NLS_DATE_FORMAT} = $nls_format;
    my $dt;
    eval { $dt = $class->parse_date($string) };
    if ($@) {
        warn "failed to parse date '$string' via format '$nls_format' (" . $class->current_date_format . ")";
        next;
    }
    foreach my $method (keys %$params) {
        if ($method eq 'time_zone') {
            is($dt->$method->name, $params->{$method}, "$nls_format $method");
        } else {
            is($dt->$method, $params->{$method}, "$nls_format $method");
        }
    }
}

