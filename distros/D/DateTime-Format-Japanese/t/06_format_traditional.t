#!perl
use strict;
use Test::More (tests => 55);
BEGIN
{
    use_ok("DateTime::Format::Japanese::Traditional", ':constants');
}
use Encode;

my @params = (
    [
        DateTime::Calendar::Japanese->new(
            era_name => DateTime::Calendar::Japanese::Era::HEISEI(),
            era_year => 15,
            month    => 6,
            day      => 14,
            hour     => 3,
            hour_quarter => 2
        ),
        {
            "平成一五年六月一四日巳二つ刻" =>
                [ FORMAT_KANJI, FORMAT_NUMERIC_MONTH, 0 ],
            "平成十五年六月十四日巳二つ刻" =>
                [ FORMAT_KANJI_WITH_UNIT, FORMAT_NUMERIC_MONTH, 0 ],
            "平成１５年６月１４日巳２つ刻" =>
                [ FORMAT_ZENKAKU, FORMAT_NUMERIC_MONTH, 0 ],
            "平成15年6月14日巳2つ刻" =>
                [ FORMAT_ROMAN, FORMAT_NUMERIC_MONTH, 0 ],
            "平成一五年水無月一四日巳二つ刻" =>
                [ FORMAT_KANJI, FORMAT_WAREKI_MONTH, 0 ],
            "旧暦平成一五年水無月一四日巳二つ刻" =>
                [ FORMAT_KANJI, FORMAT_WAREKI_MONTH, 1 ],

#            "平成一六年一月二九日一一時四九分三四秒" =>
#                [ FORMAT_KANJI, FORMAT_ERA, 0, 0, 0 ],
#            "平成十六年一月二十九日十一時四十九分三十四秒" =>
#                [ FORMAT_KANJI_WITH_UNIT, FORMAT_ERA, 0, 0, 0 ],
#            "平成１６年１月２９日１１時４９分３４秒" =>
#                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0 ],
#            "平成16年1月29日11時49分34秒" =>
#                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
#            "平成１６年１月２９日１１時４９分３４秒木曜日" =>
#                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0, 1 ],
#            "平成16年1月29日11時49分34秒" =>
#                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
#            "2004年1月29日11時49分34秒" =>
#                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 0, 0, 0 ],
#            "西暦2004年1月29日11時49分34秒" =>
#                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 0 ],
#            "西暦2004年1月29日午前11時49分34秒" =>
#                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 1 ],
#            "西暦二〇〇四年一月二九日一一時四九分三四秒" =>
#                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
#            "二〇〇四年一月二十九日十一時四十九分三十四秒" =>
#                [ FORMAT_KANJI_WITH_UNIT, FORMAT_GREGORIAN, 0, 0, 0 ],
        }
    ],
#    [
#        DateTime->new(year => -2004, month => 1, day => 29, hour => 11, minute => 49, second => 34),
#        {
#            "-二〇〇四年一月二九日一一時四九分三四秒" =>
#                [ FORMAT_KANJI, FORMAT_GREGORIAN, 0, 0, 0 ],
#            "西暦-二〇〇四年一月二九日一一時四九分三四秒" =>
#                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
#            "紀元前西暦二〇〇四年一月二九日一一時四九分三四秒" =>
#                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 1, 0 ],
#        }
#    ]
            
);

my($dt, $str, $fmt);
foreach my $param (@params) {
    $fmt = DateTime::Format::Japanese::Traditional->new();
    
    while (my($expected, $args) = each %{$param->[1]}) {
        $fmt->number_format($args->[0]);
        $fmt->month_format($args->[1]);
        $fmt->with_traditional_marker($args->[2]);
        $str = $fmt->format_datetime($param->[0]);

        is($str, $expected, "Test $expected");

        $dt = $fmt->parse_datetime($str);

        is($param->[0]->cycle, $dt->cycle);
        is($param->[0]->cycle_year, $dt->cycle_year);
        is($param->[0]->era->id, $dt->era->id);
        is($param->[0]->era_year, $dt->era_year);
        is($param->[0]->month, $dt->month);
        is($param->[0]->day, $dt->day);
        is($param->[0]->hour, $dt->hour);
        is($param->[0]->hour_quarter, $dt->hour_quarter);
    }
}

