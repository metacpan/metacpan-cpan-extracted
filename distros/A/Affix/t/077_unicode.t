use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;
$|++;
my $lib = compile_ok(<<~'');
    #include "std.h"
    DLLEXPORT const char *echo_str(const char *s) { return s; }
    DLLEXPORT int str_len(const char *s) { return s ? (int)strlen(s) : -1; }
//ext: .c

#
subtest 'ASCII string roundtrip' => sub {
    my $echo = wrap( $lib, 'echo_str', [String], String );
    my $len  = wrap( $lib, 'str_len',  [String], Int32 );
    is $echo->("Hello, World!"), "Hello, World!", 'ASCII string roundtrip';
    is $len->("Hello"),          5,               'strlen correct for ASCII';
    is $len->(""),               0,               'strlen correct for empty string';
};
#
subtest 'UTF-8 byte roundtrip' => sub {
    my $echo = wrap( $lib, 'echo_str', [String], String );
    my $len  = wrap( $lib, 'str_len',  [String], Int32 );

    # Affix passes strings as raw bytes through FFI
    # 2-byte UTF-8: é (U+00E9) = 0xC3 0xA9
    my $two_byte = "café";
    utf8::encode($two_byte);
    my $got = $echo->($two_byte);
    is $got, $two_byte, '2-byte UTF-8 bytes roundtrip';

    # 3-byte UTF-8: 中国 (U+4E2D U+56FD)
    my $three_byte = "中国";
    utf8::encode($three_byte);
    $got = $echo->($three_byte);
    is $got, $three_byte, '3-byte UTF-8 bytes roundtrip';

    # Mixed ASCII and multibyte
    my $mixed = "Hello 世界";
    utf8::encode($mixed);
    $got = $echo->($mixed);
    is $got, $mixed, 'Mixed ASCII + multibyte bytes roundtrip';

    # Verify byte lengths (strlen counts bytes, not characters)
    is $len->($two_byte),   length($two_byte),   'byte length correct for 2-byte UTF-8';
    is $len->($three_byte), length($three_byte), 'byte length correct for 3-byte UTF-8';
};
#
subtest 'Empty string roundtrip' => sub {
    my $echo = wrap( $lib, 'echo_str', [String], String );
    is $echo->(""), "", 'Empty string roundtrip';
};
#
subtest 'String encoding roundtrip via encode/decode' => sub {
    my $echo = wrap( $lib, 'echo_str', [String], String );

    # Encode Perl string to UTF-8 bytes, pass through C, decode back
    my $input = "café 中国 🎉";
    utf8::encode($input);
    my $output = $echo->($input);
    utf8::decode($output);
    is $output, "café 中国 🎉", 'Full encode/C/decode roundtrip preserves Unicode';
};
#
subtest 'str_len counts bytes not characters' => sub {
    my $len = wrap( $lib, 'str_len', [String], Int32 );
    my $str = "café";
    utf8::encode($str);
    is $len->($str), 5, 'café has 5 bytes (2+1+1+1), not 4 characters';
    $str = "中国";
    utf8::encode($str);
    is $len->($str), 6, '中国 has 6 bytes (3+3), not 2 characters';
};
done_testing;
