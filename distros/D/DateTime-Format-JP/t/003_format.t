# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use lib './lib';
    use DateTime::Format::JP;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use utf8;
my $fmt = DateTime::Format::JP->new( debug => $DEBUG );
isa_ok( $fmt, 'DateTime::Format::JP', 'object' );
BAIL_OUT( "Unable to get an DateTime::Format::JP object: ", DateTime::Format::JP->error ) if( !defined( $fmt ) );

subtest "format roman numbers to kanji" => sub
{
    my $tests =
    [
        { test => 2321, expect => '二千三百二十一' },
        { test => 1192, expect => '千百九十二' },
        { test => 2020, expect => '二千二十' },
        { test => 2021, expect => '二千二十一' },
        { test => 2001, expect => '二千一' },
        { test => 2000, expect => '二千' },
        { test => 321, expect => '三百二十一' },
        { test => 320, expect => '三百二十' },
        { test => 301, expect => '三百一' },
        { test => 300, expect => '三百' },
        { test => 110, expect => '百十' },
        { test => 40, expect => '四十' },
        { test => 42, expect => '四十二' },
        { test => 5, expect => '五' },
    ];

    for my $def ( @$tests )
    {
        is( $fmt->romaji_to_kanji( $def->{test} ), $def->{expect}, "$def->{test} -> $def->{expect}" );
        # print( STDERR "-" x 20, "\n" );
    }
};

subtest "format roman numbers to full width" => sub
{
    my $tests =
    [
        { test => 2321, expect => '２３２１' },
        { test => 2020, expect => '２０２０' },
        { test => 2021, expect => '２０２１' },
        { test => 2001, expect => '２００１' },
        { test => 2000, expect => '２０００' },
        { test => 321, expect => '３２１' },
        { test => 320, expect => '３２０' },
        { test => 301, expect => '３０１' },
        { test => 300, expect => '３００' },
        { test => 40, expect => '４０' },
        { test => 42, expect => '４２' },
        { test => 5, expect => '５' },
    ];

    for my $def ( @$tests )
    {
        is( $fmt->romaji_to_zenkaku( $def->{test} ), $def->{expect}, "$def->{test} -> $def->{expect}" );
        # print( STDERR "-" x 20, "\n" );
    }
};

subtest "format_datetime" => sub
{
    use utf8;
    my $dt = DateTime->new(
        year  => 2021,
        month => 7,
        day   => 12,
        hour  => 14,
        minute=> 15,
        second=> 20,
        time_zone => 'Asia/Tokyo',
    );
    my $tests =
    [
        { params => { pattern => '%c', debug => $DEBUG }, expect => "令和3年7月12日午後2:15:20" },
        { params => { pattern => '%c', zenkaku => 1, debug => $DEBUG }, expect => "令和３年７月１２日午後２：１５：２０" },
        { params => { pattern => '%c', traditional => 1, debug => $DEBUG }, expect => "令和3年7月12日午後2時15分20秒" },
        { params => { pattern => '%c', zenkaku => 1, traditional => 1, debug => $DEBUG }, expect => "令和３年７月１２日午後２時１５分２０秒" },
        { params => { pattern => '%c', kanji_number => 1, debug => $DEBUG }, expect => "令和三年七月十二日午後二時十五分二十秒" },
        { params => { pattern => '%a', debug => $DEBUG }, expect => "月" },
        { params => { pattern => '%A', debug => $DEBUG }, expect => "月曜日" },
        { params => { pattern => '%b', debug => $DEBUG }, expect => "7月" },
        { params => { pattern => '%B', debug => $DEBUG }, expect => "７月" },
        { params => { pattern => '%h', debug => $DEBUG }, expect => "七月" },
        { params => { pattern => '%C', debug => $DEBUG }, expect => "20" },
        { params => { pattern => '%d', debug => $DEBUG }, expect => "12" },
        { params => { pattern => '%d', zenkaku => 1, debug => $DEBUG }, expect => "１２" },
        { params => { pattern => '%d', kanji_number => 1, debug => $DEBUG }, expect => "十二" },
        # Exactly same as the 3 above, but using an alias
        { params => { pattern => '%e', debug => $DEBUG }, expect => "12" },
        { params => { pattern => '%e', zenkaku => 1, debug => $DEBUG }, expect => "１２" },
        { params => { pattern => '%e', kanji_number => 1, debug => $DEBUG }, expect => "十二" },
        # %D -> %E%y年%m月%d日
        { params => { pattern => '%D', debug => $DEBUG }, expect => "令和3年7月12日" },
        { params => { pattern => '%D', zenkaku => 1, debug => $DEBUG }, expect => "令和３年７月１２日" },
        { params => { pattern => '%D', kanji_number => 1, debug => $DEBUG }, expect => "令和三年七月十二日" },
        { params => { pattern => '%E', debug => $DEBUG }, expect => "令和" },
        { params => { pattern => '%F', debug => $DEBUG }, expect => "2021年7月12日" },
        { params => { pattern => '%F', zenkaku => 1, debug => $DEBUG }, expect => "２０２１年７月１２日" },
        { params => { pattern => '%F', kanji_number => 1, debug => $DEBUG }, expect => "二〇二一年七月十二日" },
        { params => { pattern => '%g', debug => $DEBUG }, expect => "21" },
        { params => { pattern => '%G', debug => $DEBUG }, expect => "2021" },
        { params => { pattern => '%H', debug => $DEBUG }, expect => "14" },
        { params => { pattern => '%H', traditional => 1, debug => $DEBUG }, expect => "14時" },
        { params => { pattern => '%H', zenkaku => 1, debug => $DEBUG }, expect => "１４" },
        { params => { pattern => '%H', traditional => 1, zenkaku => 1, debug => $DEBUG }, expect => "１４時" },
        { params => { pattern => '%H', kanji_number => 1, debug => $DEBUG }, expect => "十四時" },
        { params => { pattern => '%I', debug => $DEBUG }, expect => "2" },
        { params => { pattern => '%I', zenkaku => 1, debug => $DEBUG }, expect => "２" },
        { params => { pattern => '%I', kanji_number => 1, debug => $DEBUG }, expect => "二" },
        { params => { pattern => '%j', debug => $DEBUG }, expect => 193 },
        { params => { pattern => '%m', debug => $DEBUG }, expect => 7 },
        { params => { pattern => '%m', zenkaku => 1, debug => $DEBUG }, expect => "７" },
        { params => { pattern => '%m', kanji_number => 1, debug => $DEBUG }, expect => "七" },
        { params => { pattern => '%M', debug => $DEBUG }, expect => 15 },
        { params => { pattern => '%M', traditional => 1, debug => $DEBUG }, expect => "15分" },
        { params => { pattern => '%M', zenkaku => 1, debug => $DEBUG }, expect => "１５" },
        { params => { pattern => '%M', traditional => 1, zenkaku => 1, debug => $DEBUG }, expect => "１５分" },
        { params => { pattern => '%M', kanji_number => 1, debug => $DEBUG }, expect => "十五分" },
        { params => { pattern => '%p', debug => $DEBUG }, expect => "午後" },
        { params => { pattern => '%P', debug => $DEBUG }, expect => "午後" },
        # %r -> %p%I:%M:%S
        { params => { pattern => '%r', debug => $DEBUG }, expect => "午後2:15:20" },
        { params => { pattern => '%r', zenkaku => 1, debug => $DEBUG }, expect => "午後２：１５：２０" },
        # %R -> %H:%M
        { params => { pattern => '%R', debug => $DEBUG }, expect => "14:15" },
        { params => { pattern => '%R', zenkaku => 1, debug => $DEBUG }, expect => "１４：１５" },
        { params => { pattern => '%s', debug => $DEBUG }, expect => "1626066920" },
        { params => { pattern => '%s', zenkaku => 1, debug => $DEBUG }, expect => "１６２６０６６９２０" },
        { params => { pattern => '%S', debug => $DEBUG }, expect => 20 },
        { params => { pattern => '%S', traditional => 1, debug => $DEBUG }, expect => "20秒" },
        { params => { pattern => '%S', zenkaku => 1, debug => $DEBUG }, expect => "２０" },
        { params => { pattern => '%S', zenkaku => 1, traditional => 1, debug => $DEBUG }, expect => "２０秒" },
        { params => { pattern => '%S', kanji_number => 1, debug => $DEBUG }, expect => "二十秒" },
        # %T -> %H:%M:%S
        { params => { pattern => '%T', debug => $DEBUG }, expect => "14:15:20" },
        { params => { pattern => '%T', zenkaku => 1, debug => $DEBUG }, expect => "１４：１５：２０" },
        { params => { pattern => '%U', debug => $DEBUG }, expect => 28 },
        { params => { pattern => '%U', zenkaku => 1, debug => $DEBUG }, expect => "２８" },
        { params => { pattern => '%u', debug => $DEBUG }, expect => 1 },
        { params => { pattern => '%u', zenkaku => 1, debug => $DEBUG }, expect => "１" },
        { params => { pattern => '%w', debug => $DEBUG }, expect => 1 },
        { params => { pattern => '%w', zenkaku => 1, debug => $DEBUG }, expect => "１" },
        { params => { pattern => '%W', debug => $DEBUG }, expect => 28 },
        { params => { pattern => '%W', zenkaku => 1, debug => $DEBUG }, expect => "２８" },
        # 令和3年7月12日
        { params => { pattern => '%x', debug => $DEBUG }, expect => "令和3年7月12日" },
        { params => { pattern => '%x', zenkaku => 1, debug => $DEBUG }, expect => "令和３年７月１２日" },
        { params => { pattern => '%x', kanji_number => 1, debug => $DEBUG }, expect => "令和三年七月十二日" },
        { params => { pattern => '%X', debug => $DEBUG }, expect => "午後2:15:20" },
        { params => { pattern => '%X', zenkaku => 1, debug => $DEBUG }, expect => "午後２：１５：２０" },
        { params => { pattern => '%X', traditional => 1, debug => $DEBUG }, expect => "午後2時15分20秒" },
        { params => { pattern => '%X', kanji_number => 1, debug => $DEBUG }, expect => "午後二時十五分二十秒" },
        { params => { pattern => '%y', debug => $DEBUG }, expect => 3 },
        { params => { pattern => '%y', zenkaku => 1, debug => $DEBUG }, expect => "３" },
        { params => { pattern => '%y', kanji_number => 1, debug => $DEBUG }, expect => "三" },
        { params => { pattern => '%Y', debug => $DEBUG }, expect => 2021 },
        { params => { pattern => '%Y', zenkaku => 1, debug => $DEBUG }, expect => "２０２１" },
        { params => { pattern => '%Y', kanji_number => 1, debug => $DEBUG }, expect => "二〇二一" },
        { params => { pattern => '%z', debug => $DEBUG }, expect => "+0900" },
        { params => { pattern => '%z', zenkaku => 1, debug => $DEBUG }, expect => "＋０９００" },
        { params => { pattern => '%z', kanji_number => 1, debug => $DEBUG }, expect => "＋〇九〇〇" },
        { params => { pattern => '%Z', debug => $DEBUG }, expect => "JST" },
    ];
    for my $def ( @$tests )
    {
        my $fmt = DateTime::Format::JP->new( %{$def->{params}} );
        is( $fmt->format_datetime( $dt ), $def->{expect}, "$def->{params}->{pattern} -> $def->{expect}" );
        # print( STDERR "-" x 20, "\n" );
    }
};

done_testing();

__END__

