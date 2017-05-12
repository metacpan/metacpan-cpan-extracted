use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("DateTime::Calendar::Japanese");
}

eval {
    DateTime::Calendar::Japanese->from_object(
        object => DateTime->new(year => 2007,month => 10,day => 9,hour => 12, time_zone => 'Asia/Tokyo')
    );
};
ok( !$@, "No failures (" . ($@ || 'OK') . ")");

eval {
    DateTime::Calendar::Japanese->from_object(
        object => DateTime->new(year => 2007,month => 10,day => 10,hour => 12, time_zone => 'Asia/Tokyo')
    );
};
ok( !$@, "No failures (" . ($@ || 'OK') . ")");