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
            "Ê¿À®°ìÏ»Ç¯°ì·îÆó¶åÆü°ì°ì»ş»Í¶åÊ¬»°»ÍÉÃ" =>
                [ FORMAT_KANJI, FORMAT_ERA, 0, 0, 0 ],
            "Ê¿À®½½Ï»Ç¯°ì·îÆó½½¶åÆü½½°ì»ş»Í½½¶åÊ¬»°½½»ÍÉÃ" =>
                [ FORMAT_KANJI_WITH_UNIT, FORMAT_ERA, 0, 0, 0 ],
            "Ê¿À®£±£¶Ç¯£±·î£²£¹Æü£±£±»ş£´£¹Ê¬£³£´ÉÃ" =>
                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0 ],
            "Ê¿À®16Ç¯1·î29Æü11»ş49Ê¬34ÉÃ" =>
                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
            "Ê¿À®£±£¶Ç¯£±·î£²£¹Æü£±£±»ş£´£¹Ê¬£³£´ÉÃÌÚÍËÆü" =>
                [ FORMAT_ZENKAKU, FORMAT_ERA, 0, 0, 0, 1 ],
            "Ê¿À®16Ç¯1·î29Æü11»ş49Ê¬34ÉÃ" =>
                [ FORMAT_ROMAN, FORMAT_ERA, 0, 0, 0 ],
            "2004Ç¯1·î29Æü11»ş49Ê¬34ÉÃ" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 0, 0, 0 ],
            "À¾Îñ2004Ç¯1·î29Æü11»ş49Ê¬34ÉÃ" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 0 ],
            "À¾Îñ2004Ç¯1·î29Æü¸áÁ°11»ş49Ê¬34ÉÃ" =>
                [ FORMAT_ROMAN, FORMAT_GREGORIAN, 1, 0, 1 ],
            "À¾ÎñÆó¡»¡»»ÍÇ¯°ì·îÆó¶åÆü°ì°ì»ş»Í¶åÊ¬»°»ÍÉÃ" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
            "Æó¡»¡»»ÍÇ¯°ì·îÆó½½¶åÆü½½°ì»ş»Í½½¶åÊ¬»°½½»ÍÉÃ" =>
                [ FORMAT_KANJI_WITH_UNIT, FORMAT_GREGORIAN, 0, 0, 0 ],
        }
    ],
    [
        DateTime->new(year => -2004, month => 1, day => 29, hour => 11, minute => 49, second => 34),
        {
            "-Æó¡»¡»»ÍÇ¯°ì·îÆó¶åÆü°ì°ì»ş»Í¶åÊ¬»°»ÍÉÃ" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 0, 0, 0 ],
            "À¾Îñ-Æó¡»¡»»ÍÇ¯°ì·îÆó¶åÆü°ì°ì»ş»Í¶åÊ¬»°»ÍÉÃ" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 0, 0 ],
            "µª¸µÁ°À¾ÎñÆó¡»¡»»ÍÇ¯°ì·îÆó¶åÆü°ì°ì»ş»Í¶åÊ¬»°»ÍÉÃ" =>
                [ FORMAT_KANJI, FORMAT_GREGORIAN, 1, 1, 0 ],
        }
    ]
            
);

my($dt, $str, $fmt);
foreach my $param (@params) {
    $fmt = DateTime::Format::Japanese->new(input_encoding => 'euc-jp', output_encoding => 'euc-jp');
    
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

