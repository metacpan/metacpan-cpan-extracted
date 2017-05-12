use strict;
# Shamelessly stolen from DateTime::Format::MySQL - Thanks Dave
use Test::More tests => 6;
use DateTime::Format::Oracle;

my $class = 'DateTime::Format::Oracle';

my $dt = DateTime->new(
    year   => 2000,
    month  => 5,
    day    => 6,
    hour   => 15,
    minute => 23,
    second => 44,
    time_zone => 'UTC',
);

my %tests = (
    '2000-05-06 15:23:44'              => 'YYYY-MM-DD HH24:MI:SS',
    '2000-05-06 15:23:44 UTC'          => 'YYYY-MM-DD HH24:MI:SS TZR',
    '06-May-00'                        => 'DD-Mon-RR',
    '06-May-00 03.23.44.000000 PM'     => 'DD-Mon-RR HH.MI.SSXFF AM',
    '06-May-00 03.23.44.000000 PM UTC' => 'DD-Mon-RR HH.MI.SSXFF AM TZR',
    'Saturday, 06 May 2000'            => 'DAY, DD Mon YYYY',
);

foreach my $result (keys %tests) {
    my $nls_format = $tests{$result};
    local $ENV{NLS_DATE_FORMAT} = $nls_format;
    is($class->format_date($dt), $result, "format_date $nls_format");
}

