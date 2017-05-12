#!perl
use strict;
use Test::More (tests => 27);
BEGIN
{
    use_ok("DateTime::Format::Japanese", ':constants');
}
use Encode;

my @params = (
    [
        DateTime->new(year => 2004, month => 1, day => 29, hour => 11, minute => 49, second => 34),
        {
            "平成一六年一月二九日一一時四九分三四秒" =>
                [ FORMAT_KANJI, FORMAT_ERA, 0, 0, 0 ],
            "平成十六年一月二十九日十一時四十九分三十四秒" =>
                [ FORMAT_KANJI_WITH_UNIT, FORMAT_ERA, 0, 0, 0 ],
            "平成１６年１月２９日１１時４９分３４秒" =>
                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0 ],
            "平成16年1月29日11時49分34秒" =>
                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
            "平成１６年１月２９日１１時４９分３４秒木曜日" =>
                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0, 1 ],
            "平成16年1月29日11時49分34秒" =>
                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
            "2004年1月29日11時49分34秒" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 0, 0, 0 ],
            "西暦2004年1月29日11時49分34秒" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 0 ],
            "西暦2004年1月29日午前11時49分34秒" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 1 ],
            "西暦二〇〇四年一月二九日一一時四九分三四秒" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
            "二〇〇四年一月二十九日十一時四十九分三十四秒" =>
                [ FORMAT_KANJI_WITH_UNIT, FORMAT_GREGORIAN, 0, 0, 0 ],
        }
    ],
    [
        DateTime->new(year => -2004, month => 1, day => 29, hour => 11, minute => 49, second => 34),
        {
            "-二〇〇四年一月二九日一一時四九分三四秒" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 0, 0, 0 ],
            "西暦-二〇〇四年一月二九日一一時四九分三四秒" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
            "紀元前西暦二〇〇四年一月二九日一一時四九分三四秒" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 1, 0 ],
        }
    ]
            
);

my($dt, $str, $fmt);
foreach my $param (@params) {
    $fmt = DateTime::Format::Japanese->new(input_encoding => 'utf-8', output_encoding => 'utf-8');
    
    while (my($expected, $args) = each %{$param->[1]}) {
        $fmt->number_format($args->[0]);
        $fmt->year_format($args->[1]);
        $fmt->with_gregorian_marker($args->[2]);
        $fmt->with_bc_marker($args->[3]);
        $fmt->with_ampm_marker($args->[4]);
        $fmt->with_day_of_week($args->[5]);
        $str = eval{ $fmt->format_datetime($param->[0]) };

        is($str, $expected, "Test " . $param->[0]->datetime . " = " . $expected . ($@ ? " $@" : ''));

        $dt = $fmt->parse_datetime($str);
        is($param->[0]->compare($dt), 0, "Test parsing back result");
    }
}

