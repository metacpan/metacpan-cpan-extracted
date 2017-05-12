#!perl

use 5.010001;
use strict;
use warnings;

use DateTime::Format::Alami::ID;
use Test::More 0.98;

my $p = DateTime::Format::Alami::ID->new;

subtest "options for parse_datetime" => sub {
    my $str = "19-6-11, 21-6-11, 20-6-11";
    my $tz = 'Asia/Jakarta';

    #subtest "time_zone" => sub {
    #    my $res = $p->parse_datetime('19-6-11 pukul 5 pagi', {time_zone=>'Asia/Jakarta'});
    #};

    subtest "format=DateTime" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz});
        is(ref($res), "DateTime");
        is($res->ymd, "2011-06-19");
    };

    subtest "format=verbatim" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim'});
        is($res, "19-6-11");
    };

    subtest "format=epoch" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'epoch'});
        is($res, 1308416400);
    };

    subtest "format=combined" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'combined'});
        is(ref($res), "HASH");
        is($res->{DateTime}->ymd, "2011-06-19");
        is($res->{verbatim}, "19-6-11");
        is($res->{epoch}, 1308416400);
        $res->{m}{o_dayint}   = 19;
        $res->{m}{o_monthint} = 6;
        $res->{m}{o_yearint}  = 11;
        is($res->{pattern}, 'p_dateymd');
        is($res->{pos}, 0);
        is($res->{uses_time}, 0);
    };

    #subtest "prefers" => sub {
    #};

    subtest "returns=last" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim', returns=>'last'});
        is($res, "20-6-11");
    };

    subtest "returns=earliest" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim', returns=>'earliest'});
        is($res, "19-6-11");
    };

    subtest "returns=latest" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim', returns=>'latest'});
        is($res, "21-6-11");
    };

    subtest "returns=all" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim', returns=>'all'});
        is_deeply($res, ["19-6-11", "21-6-11", "20-6-11"]);
    };

    subtest "returns=all_cron" => sub {
        my $res = $p->parse_datetime($str, {time_zone => $tz, format=>'verbatim', returns=>'all_cron'});
        is_deeply($res, ["19-6-11", "20-6-11", "21-6-11"]);
    };
};

subtest "options for parse_datetime_duration" => sub {
    require DateTime::Format::Duration::ISO8601;
    my $str = "2 hari. 5detik. 3 jam 4 menit.";
    my $pdur = DateTime::Format::Duration::ISO8601->new;

    subtest "format=Duration" => sub {
        my $res = $p->parse_datetime_duration($str);
        is(ref($res), "DateTime::Duration");
        is($pdur->format_duration($res), "P2D");
    };

    subtest "format=verbatim" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim'});
        is($res, "2 hari");
    };

    subtest "format=seconds" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'seconds'});
        is($res, 2*86400);
    };

    subtest "format=combined" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'combined'});
        is(ref($res), "HASH");
        is($pdur->format_duration($res->{Duration}), "P2D");
        is($res->{verbatim}, "2 hari");
        is($res->{seconds}, 2*86400);
        $res->{m}{odur_dur}   = '2 hari';
        is($res->{pattern}, 'pdur_dur');
        is($res->{pos}, 0);
    };

    subtest "returns=last" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim', returns=>'last'});
        is($res, "3 jam 4 menit");
    };

    subtest "returns=smallest" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim', returns=>'smallest'});
        is($res, "5detik");
    };

    subtest "returns=largest" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim', returns=>'largest'});
        is($res, "2 hari");
    };

    subtest "returns=all" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim', returns=>'all'});
        is_deeply($res, ["2 hari", "5detik", "3 jam 4 menit"]);
    };

    subtest "returns=all_sorted" => sub {
        my $res = $p->parse_datetime_duration($str, {format=>'verbatim', returns=>'all_sorted'});
        is_deeply($res, ["5detik", "3 jam 4 menit", "2 hari"]);
    };
};

done_testing;
