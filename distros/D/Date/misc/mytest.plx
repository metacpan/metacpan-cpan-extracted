#!/usr/bin/perl
use 5.012;
use lib 't/lib';
use MyTest;
use Benchmark qw/timethis timethese/;
use Date qw/now today date rdate :const tzset tzget/;
use Storable qw/freeze nfreeze thaw dclone/;
say "START";

die "usage $1 test_name" unless @ARGV;

my $time = (grep { $_ eq '--profile' } @ARGV) ? -100 : -1;
for (@ARGV) {
    say;
    my $sub = main->can($_);
    $sub->();
}

sub dnew {
    timethis($time, sub { Date::date() });
}

sub dparse {
    timethis($time, sub {
        Date::date("2019-01-01 00:00:00");
    });
}

sub parse {
    timethese($time, {
        date_only   => sub { MyTest::bench_parse("2019-12-04") },
        date        => sub { MyTest::bench_parse("2019-12-04 23:23:23") },
        date_mksoff => sub { MyTest::bench_parse("2019-12-04 23:23:23.12345+03:30") },
    });
}

sub rparse {
    timethese(-1, {
        min => sub { MyTest::bench_rparse("2D") },
        avg => sub { MyTest::bench_rparse("1M -2D 3h") },
        big => sub { MyTest::bench_rparse("3Y 10M 25D -15h -50m -45s") },
    });
}

sub strftime {
    say Date::now->strftime("%Y/%m/%d %H:%M:%S");
    timethis($time, sub { MyTest::bench_strftime("%Y/%m/%d %H:%M:%S") });
}

sub tzget {
    timethis($time, sub { MyTest::bench_tzget("<+01:00>-01:00") });
}

sub newrel {
    timethese(-1, {
        str => sub { rdate("1Y 2M 3D 4h 5m 6s") },
        arr => sub { rdate_ymd(1,2,3,4,5,6) },
        hash => sub { rdate_ymd(year => 1, month => 2, day => 3, hour => 4, min => 5, sec => 6) },
    });
}
 
sub hints_get {
    say MyTest::get_strict_hint();
    timethis(-1, sub { MyTest::bench_hints_get() });
    {
        use Date::strict;
        say "B=".MyTest::get_strict_hint();
        timethis(-1, sub { MyTest::bench_hints_get() });
        
        no Date::strict;
        say "B=".MyTest::get_strict_hint();
        timethis(-1, sub { MyTest::bench_hints_get() });
    }
    say MyTest::get_strict_hint();
    timethis(-1, sub { MyTest::bench_hints_get() });
}

sub stri {
    my $date = date("2019-suka");
    say "ERROR=".$date->error;
    {
        use Date::strict;
        my $date = date("2019-suka");
        say "NOT REACHED";
    }
}