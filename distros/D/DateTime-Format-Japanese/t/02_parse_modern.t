#!perl
use strict;
use Test::More (tests => 121);
use Encode;
BEGIN
{
    use_ok("DateTime::Format::Japanese");
}

my @params = (
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü",
        DateTime->new(year => 2004, month => 1, day => 3)
    ],
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü¸áÁ°£µ»ş",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5)
    ],
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü¸áÁ°£µ»ş£³£°Ê¬",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30)
    ],
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü¸áÁ°£µ»ş£³£°Ê¬£²£¹ÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30, second => 29)
    ],
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü¸á¸å£µ»ş£³£°Ê¬£²£¹ÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 17, minute => 30, second => 29)
    ],
    [
        "Ê¿À®£±£¶Ç¯£±·î£³Æü¸á¸å£µ»ş£³£°Ê¬£²£¹ÉÃÅÚÍËÆü",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 17, minute => 30, second => 29)
    ],
    [
        "Ê¿À®½½Ï»Ç¯°ì·î»°Æü",
        DateTime->new(year => 2004, month => 1, day => 3)
    ],
    [
        "Ê¿À®½½Ï»Ç¯°ì·î»°Æü¸áÁ°¸Ş»ş",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5)
    ],
    [
        "Ê¿À®½½Ï»Ç¯°ì·î»°Æü¸áÁ°¸Ş»ş»°¡»Ê¬",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30)
    ],
    [
        "Ê¿À®½½Ï»Ç¯°ì·î»°Æü¸áÁ°¸Ş»ş»°¡»Ê¬Æó¶åÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30, second => 29)
    ],
    [
        "Ê¿À®°ìÏ»Ç¯°ì·î»°Æü¸á¸å¸Ş»ş»°¡»Ê¬Æó¶åÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 17, minute => 30, second => 29)
    ],
    [
        "Ê¿À®16Ç¯1·î3Æü",
        DateTime->new(year => 2004, month => 1, day => 3)
    ],
    [
        "Ê¿À®16Ç¯1·î3Æü¸áÁ°5»ş",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5)
    ],
    [
        "Ê¿À®16Ç¯1·î3Æü¸áÁ°5»ş30Ê¬",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30)
    ],
    [
        "Ê¿À®16Ç¯1·î3Æü¸áÁ°5»ş30Ê¬29ÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 5, minute => 30, second => 29)
    ],
    [
        "Ê¿À®16Ç¯1·î3Æü¸á¸å5»ş30Ê¬29ÉÃ",
        DateTime->new(year => 2004, month => 1, day => 3, hour => 17, minute => 30, second => 29)
    ],
    [
        "1989Ç¯3·î7Æü",
        DateTime->new(year => 1989, month => 3, day => 7)
    ],
    [
        "1989Ç¯3·î7Æü13»ş",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13)
    ],
    [
        "1989Ç¯3·î7Æü13»ş37Ê¬",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13, minute => 37)
    ],
    [
        "1989Ç¯3·î7Æü13»ş37Ê¬18ÉÃ",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13, minute => 37, second => 18)
    ],
    [
        "°ì¶åÈ¬¶åÇ¯»°·î¼·Æü",
        DateTime->new(year => 1989, month => 3, day => 7)
    ],
    [
        "°ì¶åÈ¬¶åÇ¯»°·î¼·Æü°ì»°»ş",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13)
    ],
    [
        "°ì¶åÈ¬¶åÇ¯»°·î¼·Æü°ì»°»ş»°½½¼·Ê¬",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13, minute => 37)
    ],
    [
        "°ì¶åÈ¬¶åÇ¯»°·î¼·Æü°ì»°»ş»°½½¼·Ê¬½½È¬ÉÃ",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13, minute => 37, second => 18)
    ],
    [
        "À¾Îñ1989Ç¯3·î7Æü13»ş37Ê¬18ÉÃ",
        DateTime->new(year => 1989, month => 3, day => 7, hour => 13, minute => 37, second => 18)
    ],
    [
        "µª¸µÁ°1989Ç¯3·î7Æü",
        DateTime->new(year => -1989, month => 3, day => 7)
    ],
    [
        "µª¸µÁ°1989Ç¯3·î7Æü13»ş",
        DateTime->new(year => -1989, month => 3, day => 7, hour => 13)
    ],
    [
        "µª¸µÁ°1989Ç¯3·î7Æü13»ş37Ê¬",
        DateTime->new(year => -1989, month => 3, day => 7, hour => 13, minute => 37)
    ],
    [
        "µª¸µÁ°1989Ç¯3·î7Æü13»ş37Ê¬18ÉÃ",
        DateTime->new(year => -1989, month => 3, day => 7, hour => 13, minute => 37, second => 18)
    ],
    [
        "µª¸µÁ°À¾Îñ1989Ç¯3·î7Æü13»ş37Ê¬18ÉÃ",
        DateTime->new(year => -1989, month => 3, day => 7, hour => 13, minute => 37, second => 18)
    ],
);

my $dt;
my $format = DateTime::Format::Japanese->new(input_encoding => 'euc-jp');
foreach my $param (@params) {
    $dt = eval { $format->parse_datetime($param->[0]) };
    ok($dt);
    SKIP:{
        skip("parse_datetime raised exception or didn't return a DateTime object: $@", 1) if !$dt;
        is( $dt->compare($param->[1]), 0, "Test parse_datetime($param->[0]) = " . $param->[1]->datetime);
    }
}

$format->input_encoding('shiftjis');
foreach my $param (@params) {
	$param->[0] = Encode::encode('shiftjis', Encode::decode('euc-jp', $param->[0]));
    $dt = eval { $format->parse_datetime($param->[0]) };
    ok($dt);
    SKIP:{
        skip("parse_datetime raised exception or didn't return a DateTime object: $@", 1) if !$dt;
        is( $dt->compare($param->[1]), 0, "Test parse_datetime($dt) = " . $param->[1]->datetime);
    }
}


