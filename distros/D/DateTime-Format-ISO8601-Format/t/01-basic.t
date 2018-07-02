#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DateTime;
use DateTime::Format::ISO8601::Format;

subtest "all" => sub {
    local $ENV{PERL_DATETIME_DEFAULT_TZ};

    my $dt_floating      = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3);
    my $dt_floating_frac = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, nanosecond=>0.456e9);
    my $dt_utc           = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, time_zone=>'UTC');
    my $dt_sometz        = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, time_zone=>'Asia/Jakarta');

    subtest "new()" => sub {
        dies_ok { DateTime::Format::ISO8601::Format->new(foo=>1) } "unknown attr -> dies";
        dies_ok { DateTime::Format::ISO8601::Format->new(time_zone=>"Foo") } "unknown time zone -> dies";
    };

    subtest "format_date()" => sub {
        subtest "defaults" => sub {
            my $format = DateTime::Format::ISO8601::Format->new;
            is($format->format_date($dt_floating), "2018-06-23");
            is($format->format_date($dt_floating_frac), "2018-06-23");
            is($format->format_date($dt_utc), "2018-06-23");
            is($format->format_date($dt_sometz), "2018-06-23");
        };

        subtest "attr: time_zone" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(time_zone => 'Asia/Jakarta');
            is($format->format_date($dt_floating), "2018-06-23");
            is($format->format_date($dt_floating_frac), "2018-06-23");
            is($format->format_date($dt_utc), "2018-06-24");
            is($format->format_date($dt_sometz), "2018-06-23");
        };
    };

    subtest "format_time()" => sub {
        subtest "defaults" => sub {
            my $format = DateTime::Format::ISO8601::Format->new;
            is($format->format_time($dt_floating), "19:02:03");
            is($format->format_time($dt_floating_frac), "19:02:03.456");
            is($format->format_time($dt_utc), "19:02:03Z");
            is($format->format_time($dt_sometz), "19:02:03+07:00");
        };

        subtest "attr: time_zone=Asia/Jakarta" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(time_zone => 'Asia/Jakarta');
            is($format->format_time($dt_floating), "19:02:03+07:00");
            is($format->format_time($dt_floating_frac), "19:02:03.456+07:00");
            is($format->format_time($dt_utc), "02:02:03+07:00");
            is($format->format_time($dt_sometz), "19:02:03+07:00");
        };

        subtest "attr: time_zone=UTC" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(time_zone => 'UTC');
            is($format->format_time($dt_floating), "19:02:03Z");
            is($format->format_time($dt_floating_frac), "19:02:03.456Z");
            is($format->format_time($dt_utc), "19:02:03Z");
            is($format->format_time($dt_sometz), "12:02:03Z");
        };

        subtest "attr: second_precision=3" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(second_precision=>3);
            is($format->format_time($dt_floating), "19:02:03.000");
            is($format->format_time($dt_floating_frac), "19:02:03.456");
            is($format->format_time($dt_utc), "19:02:03.000Z");
            is($format->format_time($dt_sometz), "19:02:03.000+07:00");
        };
    };

    subtest "format_datetime()" => sub {
        subtest "defaults" => sub {
            my $format = DateTime::Format::ISO8601::Format->new;
            is($format->format_datetime($dt_floating), "2018-06-23T19:02:03");
            is($format->format_datetime($dt_floating_frac), "2018-06-23T19:02:03.456");
            is($format->format_datetime($dt_utc), "2018-06-23T19:02:03Z");
            is($format->format_datetime($dt_sometz), "2018-06-23T19:02:03+07:00");
        };

        subtest "attr: time_zone=Asia/Jakarta" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(time_zone => 'Asia/Jakarta');
            is($format->format_datetime($dt_floating), "2018-06-23T19:02:03+07:00");
            is($format->format_datetime($dt_floating_frac), "2018-06-23T19:02:03.456+07:00");
            is($format->format_datetime($dt_utc), "2018-06-24T02:02:03+07:00");
            is($format->format_datetime($dt_sometz), "2018-06-23T19:02:03+07:00");
        };

        subtest "attr: time_zone=UTC" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(time_zone => 'UTC');
            is($format->format_datetime($dt_floating), "2018-06-23T19:02:03Z");
            is($format->format_datetime($dt_floating_frac), "2018-06-23T19:02:03.456Z");
            is($format->format_datetime($dt_utc), "2018-06-23T19:02:03Z");
            is($format->format_datetime($dt_sometz), "2018-06-23T12:02:03Z");
        };

        subtest "attr: second_precision=3" => sub {
            my $format = DateTime::Format::ISO8601::Format->new(second_precision=>3);
            is($format->format_datetime($dt_floating), "2018-06-23T19:02:03.000");
            is($format->format_datetime($dt_floating_frac), "2018-06-23T19:02:03.456");
            is($format->format_datetime($dt_utc), "2018-06-23T19:02:03.000Z");
            is($format->format_datetime($dt_sometz), "2018-06-23T19:02:03.000+07:00");
        };
    };
};

DONE_TESTING:
done_testing;
