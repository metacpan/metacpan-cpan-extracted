#!/usr/bin/env perl
use 5.016;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use File::Temp qw(tempdir);

use lib 'lib';
use AmberDB;
use AmberDB::Date;

# 1. Direct AmberDB::Date instantiation & OOP Accessors
subtest 'AmberDB::Date standalone OOP accessors' => sub {
    plan tests => 14;

    my $date = AmberDB::Date->new( language => 'tr' );
    isa_ok( $date, 'AmberDB::Date' );

    ok( $date->year =~ /^\d{4}$/, 'year returns 4-digit year' );
    ok( $date->month =~ /^\d{2}$/, 'month returns 2-digit month' );
    ok( $date->day =~ /^\d{2}$/, 'day returns 2-digit day' );
    ok( $date->hour =~ /^\d{2}$/, 'hour returns 2-digit hour' );
    ok( $date->minute =~ /^\d{2}$/, 'minute returns 2-digit minute' );
    ok( $date->second =~ /^\d{2}$/, 'second returns 2-digit second' );

    is( $date->day_id, $date->year . $date->month . $date->day, 'day_id matches YYYYMMDD' );
    is( $date->second_id, $date->day_id . $date->hour . $date->minute . $date->second, 'second_id matches YYYYMMDDHHMMSS' );

    ok( defined $date->date_str && length($date->date_str), 'str returns formatted string' );
    ok( defined $date->date_short && length($date->date_short), 'short returns formatted date' );
    ok( defined $date->only_time && length($date->only_time), 'only_time returns formatted time' );

    # Backward compatibility hash access
    is( $date->{day_id}, $date->day_id, 'Direct hash access $date->{day_id} works transparently' );
    is( $date->{second_id}, $date->second_id, 'Direct hash access $date->{second_id} works transparently' );
};

# 2. Custom epoch calculations via accessors
subtest 'Custom epoch calculations on accessors' => sub {
    plan tests => 4;

    my $date = AmberDB::Date->new();
    # 2026-01-01 00:00:00 UTC/Local
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(1767225600);
    my $expected_day_id = sprintf( "%04d%02d%02d", $year + 1900, $mon + 1, $mday );

    is( $date->day_id(1767225600), $expected_day_id, 'day_id(custom_epoch) returns correct ID' );
    is( $date->year(1767225600), $year + 1900, 'year(custom_epoch) returns correct year' );
    ok( defined $date->date_str(1767225600), 'str(custom_epoch) returns formatted string' );
    ok( defined $date->date_short(1767225600), 'short(custom_epoch) returns formatted short date' );
};

# 3. AmberDB instance mixin accessors & $adb->get_date()
subtest 'AmberDB instance mixin date accessors' => sub {
    plan tests => 8;

    my $temp_dir = tempdir( CLEANUP => 1 );
    my $adb = AmberDB->new( path => { dbase_dir => $temp_dir } );
    isa_ok( $adb, 'AmberDB' );

    # Method calls directly on $adb
    ok( defined $adb->day_id && length($adb->day_id) == 8, '$adb->day_id returns 8-digit day_id' );
    ok( defined $adb->second_id && length($adb->second_id) == 14, '$adb->second_id returns 14-digit second_id' );
    ok( defined $adb->year && length($adb->year) == 4, '$adb->year returns 4-digit year' );
    ok( defined $adb->date_str && length($adb->date_str), '$adb->date_str returns formatted string' );

    # $adb->get_date() returns blessed AmberDB::Date object
    my $date_obj = $adb->get_date();
    isa_ok( $date_obj, 'AmberDB::Date' );
    is( $date_obj->day_id, $adb->day_id, '$date_obj->day_id matches $adb->day_id' );

    # Backward compatibility with $adb->{date}
    is( $adb->{date}->{day_id}, $adb->day_id, '$adb->{date}->{day_id} matches $adb->day_id' );
};

# 4. Helper method suite
subtest 'Helper method conversions' => sub {
    plan tests => 4;

    my $date = AmberDB::Date->new();
    is( $date->str2dateid('2026-08-22'), '20260822', 'str2dateid converts YYYY-MM-DD' );
    is( $date->str2dateid('22/08/2026'), '20260822', 'str2dateid converts DD/MM/YYYY' );
    is( $date->dateid2str('20260822'), '22/08/2026', 'dateid2str converts dayid' );

    my @days = $date->day_range('20260801', '20260805');
    is_deeply( \@days, [qw(20260801 20260802 20260803 20260804 20260805)], 'day_range returns 5 days' );
};

# 5. Argument-aware caching and memoization suite
subtest 'Argument-aware caching and memoization' => sub {
    plan tests => 14;

    my $date = AmberDB::Date->new();

    # get_date caching
    my $d1 = $date->get_date(1700000000);
    my $d2 = $date->get_date(1700000000);
    is( $d1, $d2, 'get_date returns cached object for same epoch' );

    my $d3 = $date->get_date(1700000001);
    isnt( $d1, $d3, 'get_date returns new object for different epoch' );

    # str2dateid cache
    is( $date->str2dateid('2026-09-17'), '20260917', 'str2dateid parses date' );
    ok( exists $date->{_date}{str2dateid}{'2026-09-17'}, 'str2dateid cached in _date_cache' );

    # dateid2str cache
    is( $date->dateid2str('20260917'), '17/09/2026', 'dateid2str formats date' );
    ok( exists $date->{_date}{dateid2str}{'20260917'}, 'dateid2str cached in _date_cache' );

    # day_range cache
    my @r1 = $date->day_range('20260901', '20260903');
    my @r2 = $date->day_range('20260901', '20260903');
    is_deeply( \@r1, \@r2, 'day_range returns identical list' );
    ok( exists $date->{_date}{day_range}{'20260901:20260903'}, 'day_range cached by start:end key' );

    # dateid2week cache
    my ( $w1 ) = $date->dateid2week('20260917');
    ok( exists $date->{_date}{dateid2week}{'20260917'}, 'dateid2week cached by dateid' );

    # offset2date cache
    my $off = $date->offset2date('2D');
    ok( exists $date->{_date}{offset2date}{ $date->day_id . ':2D' }, 'offset2date cached by day_id:offset' );

    # AmberDB mixin caching
    my $adb = AmberDB->new( path => { dbase_dir => '.' } );
    my $adb_day1 = $adb->day_id;
    my $adb_day2 = $adb->day_id;
    is( $adb_day1, $adb_day2, '$adb->day_id memoized' );
    ok( exists $adb->{_date}, '$adb->_date_cache exists' );

    # reset_date
    $adb->reset_date;
    is( scalar(keys %{ $adb->{_date} }), 0, 'reset_date empties _date_cache on $adb' );
    my $adb_day3 = $adb->day_id;
    is( $adb_day1, $adb_day3, '$adb->day_id recomputed after cache clear' );
};

# 6. Instance time anchoring and consistency suite
subtest 'Instance time anchoring and consistency' => sub {
    plan tests => 6;

    my $date = AmberDB::Date->new();
    ok( defined $date->{time}, '$date->{time} anchored upon creation' );
    my $initial_epoch = $date->{time};
    is( $date->epoch, $initial_epoch, '$date->epoch matches $date->{time}' );

    # Calling custom epoch does not mutate instance time
    my $custom_d = $date->get_date(1600000000);
    is( $date->{time}, $initial_epoch, '$date->{time} untouched after get_date(custom_epoch)' );
    is( $custom_d->{time}, 1600000000, 'Custom date object has requested epoch' );

    # AmberDB instance consistency
    my $adb = AmberDB->new( path => { dbase_dir => '.' } );
    ok( defined $adb->{time}, '$adb->{time} anchored at initialization' );
    my $adb_time = $adb->{time};
    is( $adb->epoch, $adb_time, '$adb->epoch returns consistent $adb->{time}' );
};

done_testing();
