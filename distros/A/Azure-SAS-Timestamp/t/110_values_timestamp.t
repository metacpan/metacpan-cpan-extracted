use Test::More;
use Azure::SAS::Timestamp;
use Time::Piece;
use DateTime;

my $epoch = new_ok( 
    'Azure::SAS::Timestamp', 
    [ 1589119719 ],
    'Epoch Stamp'
);

is( $epoch->sas_time, 
    '2020-05-10T14:08:39Z', 
    'Epoch stamp "1589119719" converted to "2020-05-10T14:08:39Z"' 
);

my $str_with_z = new_ok( 
    'Azure::SAS::Timestamp', 
    [ '2020-05-10T14:12:04Z' ],
    "Timestamp ending with a \"Z\""
);

is( $str_with_z->sas_time, 
    '2020-05-10T14:12:04Z', 
    'String "2020-05-10T14:12:04Z" converted to "2020-05-10T14:12:04Z"' 
);

my $str_with_utc = new_ok(
    'Azure::SAS::Timestamp',
    [ '2020-05-10T14:12:04UTC' ],
    'Timestamp ending with "UTC"'
);

is( $str_with_utc->sas_time,
    '2020-05-10T14:12:04Z',
    'String "2020-05-10T14:12:04UTC" converted to "2020-05-10T14:12:04Z"'
);


my $without_seconds = new_ok(
    'Azure::SAS::Timestamp',
    [ '2020-05-10T13:12UTC' ],
    'Timestamp witout seconds and with "UTC"'
);

is( $without_seconds->sas_time,
    '2020-05-10T13:12:00Z',
    'String "2020-05-10T13:12UTC" converted to "2020-05-10T13:12:00Z"'
);


my $tp  = Time::Piece->strptime( '2020-05-10T13:12:00', '%Y-%m-%dT%T');
my $from_timepiece = new_ok(
    'Azure::SAS::Timestamp',
    [ $tp ],
    'Timestamp from Time::Piece object'
);

is( $from_timepiece->sas_time,
    '2020-05-10T13:12:00Z',
    'Time::Piece object converted correctly'
);


my $dt = DateTime->new(
    year   => 2020,
    month  => 5,
    day    => 10,
    hour   => 13,
    minute => 12,
    second => 0
);
my $from_datetime = new_ok(
    'Azure::SAS::Timestamp',
    [ $dt ],
    'Timestamp from DateTime object'
);
is( $from_datetime->sas_time,
    '2020-05-10T13:12:00Z',
    'DateTime object converted correctly'
);




done_testing;
