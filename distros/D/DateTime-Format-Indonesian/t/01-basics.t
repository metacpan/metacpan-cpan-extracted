#!perl

use 5.010;
use DateTime;
use DateTime::Format::Indonesian;
use Test::More 0.98;
use Test::Exception;

my $fmt = DateTime::Format::Indonesian->new;

{
    local $DateTime::Format::Indonesian::_Current_Dt = DateTime->new(
        day=>30, month=>7, year=>2013);
    is($fmt->parse_datetime("17 agt 2013")->ymd, "2013-08-17");
    is($fmt->parse_datetime("17-may-2013")->ymd, "2013-05-17", "sep=dash, en");
    is($fmt->parse_datetime("17/mei/2013")->ymd, "2013-05-17", "sep=slash");
    is($fmt->parse_datetime("7 agustus 2013")->ymd, "2013-08-07", "long name");
    is($fmt->parse_datetime("17-may, 2013")->ymd, "2013-05-17", "year comma");
    ok(!$fmt->parse_datetime("x"), "invalid ()");
    dies_ok { $fmt->parse_datetime("10 steven 2013") }
        "invalid (unknown month)";
}

DONE_TESTING:
done_testing;
