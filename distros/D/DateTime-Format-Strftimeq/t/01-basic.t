#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DateTime;
use DateTime::Format::Strftimeq;

subtest "all" => sub {
    local $ENV{PERL_DATETIME_DEFAULT_TZ};

    my $dt1 = DateTime->new(year=>2019, month=>11, day=>19);
    my $dt2 = DateTime->new(year=>2019, month=>11, day=>24);

    subtest "new()" => sub {
        dies_ok { DateTime::Format::Strftimeq->new(foo=>1) } "unknown attr -> dies";
        dies_ok { DateTime::Format::Strftimeq->new(time_zone=>"Foo") } "unknown time zone -> dies";
    };

    subtest "format_datetime()" => sub {
        subtest "defaults" => sub {
            my $format = DateTime::Format::Strftimeq->new(format=>'%Y-%m-%d%( $_->day_of_week == 7 ? "su" : "" )q');
            is($format->format_datetime($dt1), "2019-11-19");
            is($format->format_datetime($dt2), "2019-11-24su");
        };
        # XXX test time_zone option
    };
};

DONE_TESTING:
done_testing;
