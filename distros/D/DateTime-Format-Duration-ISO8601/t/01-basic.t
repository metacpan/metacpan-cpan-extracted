#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use DateTime::Duration;
use DateTime::Format::Duration::ISO8601;

sub test_parse {
    my %args = @_;

    subtest "parse $args{str}" => sub {
        my $f = DateTime::Format::Duration::ISO8601->new;
        my $d;
        eval {
            $d = $f->parse_duration($args{str});
        };
        my $err = $@;
        if ($args{dies}) {
            ok($err, "dies") or return;
            if (ref $args{dies} eq 'Regexp') {
                like($err, $args{dies}, "die message");
            }
            return;
        } else {
            ok(!$err, "does not die") or do {
                diag "err = $err";
                return;
            };
        }
        if ($args{result}) {
            my $dmp = { %$d };
            for (keys %$dmp) {
                delete $dmp->{$_} unless
                    /\A(days|minutes|months|nanoseconds|seconds)\z/;
            }
            is_deeply($dmp, $args{result}) or diag explain $dmp;
        }
    };
}

subtest "format" => sub {
    my $f = DateTime::Format::Duration::ISO8601->new;

    is($f->format_duration(DateTime::Duration->new()),
       "PT0H0M0S", 'empty duration');
    is($f->format_duration(DateTime::Duration->new(years=>1)),
       "P1Y", 'one year');
    is($f->format_duration(DateTime::Duration->new(hours=>2)),
       "PT2H", 'two hours');
    is($f->format_duration(DateTime::Duration->new(years=>1, months=>2, weeks=>2, days=>7+4, hours=>5, minutes=>6, seconds=>7, nanoseconds=>800_000_000)),
       "P1Y2M25DT5H6M7.8S", 'all duration fields');
    eval { $f->format_duration("123") };
    ok $@ =~ m[not a DateTime::Duration instance], 'invalid dt arg';
};

subtest "parse" => sub {
    test_parse(
        str => 'P1Y1M1DT1H1M1.000000001S',

        result => {
            days => 1,
            minutes => 61,
            months => 13,
            nanoseconds => 1,
            seconds => 1,
        },
    );
    test_parse(
        str => 'P13MT61M',

        result => {
            days => 0,
            minutes => 61,
            months => 13,
            nanoseconds => 0,
            seconds => 0,
        },
    );
    test_parse(
        str => 'PT0S',

        result => {
            days => 0,
            months => 0,
            minutes => 0,
            nanoseconds => 0,
            seconds => 0,
        },
    );
    test_parse(
        str => 'abc',

        dies => qr[abc.*not a valid],
    );
    test_parse(
        str => 'RP1Y',

        dies => qr[repetitions are not supported],
    );
};

subtest "on_error" => sub {
    my $error;

    eval {
        DateTime::Format::Duration::ISO8601->new(
            on_error => sub { $error = shift }
        )->parse_duration('xyz');
    };

    ok defined $error, 'error set via on_error callback';
    ok $error =~ m[xyz.*not a valid], 'parse failure error callback message';
};

done_testing;
