#!perl
use 5.014;
use strict;
use warnings;
use Test2::V0;
use Feature::Compat::Try;
use Encode qw(decode encode);
use MHFS::Util qw(space2us escape_html escape_html_noquote shell_escape get_printable_utf8 read_text_file_lossy read_text_file write_text_file write_text_file_lossy decode_utf_8 parse_ipv4 write_file read_file fold_case);

plan 103;

is(space2us('hello world'), 'hello_world');

my $unsafe_chars = q|"'<>/|;
is(${escape_html($unsafe_chars)}, '&quot;&#x27;&lt;&gt;&#x2F;');
is(${escape_html_noquote($unsafe_chars)}, q|"'&lt;&gt;/|);

is(shell_escape(q|it's|), q|it'"'"'s|);

{
    my $message = 'valid ip parses';
    try {
        is(parse_ipv4('8.8.8.8'), 8 | (8 << 8) | (8 << 16) | (8 << 24), $message);
        is(parse_ipv4('255.255.255.255'), 0xFFFFFFFF, $message);
    } catch ($e) {
        fail($message);
    }
}
{
    my $message = 'invalid ip fails to parse';
    try {
        parse_ipv4('255.255.255.2551');
        fail($message);
    } catch ($e) {
        pass($message);
    }
    try {
        parse_ipv4('256.255.255.255');
        fail($message);
    } catch ($e) {
        pass($message);
    }
}

{
    my @valid = (
        # valid range in 1-4 byte sequences
        "\x00",
        "\x7F",
        "\xC2\x80",
        "\xDF\xBF",
        "\xE0\xA0\x80",
        "\xEF\xBF\xBF",
        "\xF0\x90\x80\x80",
        "\xF7\xBF\xBF\xBF",
        # high and low surrogate ranges
        "\xED\xA0\x80",
        "\xED\xAF\xBF",
        "\xED\xB0\x80",
        "\xED\xBF\xBF",
    );
    my @overlong = (
        # overlong ranges
        "\xC0\x80",
        "\xC1\xBF",
        "\xE0\x80\x80",
        "\xE0\x9F\xBF",
        "\xF0\x80\x80\x80",
        "\xF0\x8F\xBF\xBF",
    );
    my @toolong = (
        "\xF8\x80\x80\x80\x80",
        "\xF8\x88\x80\x80\x80"
    );
    # truncated, without and with additional input
    my @truncated = (
        # bytes, expected bytelength
        ["\xC2", 1],
        ["\xC2A", 1],
        ["\xE0\xA0", 2],
        ["\xE0\xA0A", 2],
        ["\xF0\x90\x80", 3],
        ["\xF0\x90\x80A", 3],
    );

    # test format:
    # [bytes, bytelength, is_replacement, [, codepoint]]
    my @tests;
    foreach my $valid (@valid) {
        push @tests, [$valid, length($valid), 0, ord(decode('utf8', $valid, Encode::LEAVE_SRC))];
    }
    foreach my $overlong (@overlong) {
        push @tests, [$overlong, length($overlong), 1, ord(decode('utf8', $overlong, Encode::LEAVE_SRC))];
    }
    foreach my $toolong (@toolong) {
        push @tests, [$toolong, 1, 1];
    }
    foreach my $truncated (@truncated) {
        my @test = (@$truncated, 1);
        push @tests, \@test;
    }

    foreach my $test (@tests) {
        my ($bytes, $bytelength, $is_replacement, $codepoint) = @$test;
        my $display = uc(unpack("H*", $bytes));
        my $peeked = MHFS::Util::_peek_utf8_codepoint($bytes);
        my $message = "_peek_utf8_codepoint $display ". ($is_replacement ? 'is' : 'isnt'). ' U+FFFD';
        $is_replacement ? is($peeked->{codepoint}, 0xFFFD, $message) : isnt($peeked->{codepoint}, 0xFFFD, $message);
        is($peeked->{bytelength}, $bytelength, "_peek_utf8_codepoint $display bytelength is as expected");
        if (defined $codepoint) {
            is($peeked->{codepoint}, $codepoint, "_peek_utf8_codepoint $display codepoint matches decode(utf8)");
        }
    }
}

{
    my $result = MHFS::Util::surrogatepairtochar("\x{D83C}", "\x{DF84}");
    is(ord($result), 0x1F384, "Converting surrogate pair for $result (U+1F384)");
}
{
    my $result = MHFS::Util::surrogatepairtochar("\x{D800}", "\x{DC00}");
    is(ord($result), 0x10000, 'First possible surrogate pair combination');
}
{
    my $result = MHFS::Util::surrogatepairtochar("\x{DBFF}", "\x{DFFF}");
    is(ord($result), 0x10FFFF, 'Last possible surrogate pair combination');
}

{
    my $result = MHFS::Util::surrogatecodepointpairtochar(0xD83C, 0xDF84);
    is(ord($result), 0x1F384, "Converting surrogate pair for $result (U+1F384)");
}
{
    my $result = MHFS::Util::surrogatecodepointpairtochar(0xD800, 0xDC00);
    is(ord($result), 0x10000, 'First possible surrogate pair combination');
}
{
    my $result = MHFS::Util::surrogatecodepointpairtochar(0xDBFF, 0xDFFF);
    is(ord($result), 0x10FFFF, 'Last possible surrogate pair combination');
}

{
    my $result = get_printable_utf8('A'.chr(0xFF).'B');
    is($result, 'A'.chr(0xFFFD).'B', 'Valid invalid valid');
}
{
    my $result = get_printable_utf8("A\xED\xA0\xBC\xED\xBE\x84B");
    is($result, 'A'.chr(0x1F384).'B', 'Valid low surrogate high surrogate valid');
}
{
    # verify truncated sequences are replaced as expected
    my @tests = (
        ["\xC2", chr(0xFFFD)],
        ["\xC2A", chr(0xFFFD).'A'],
        ["\xE0\xA0", chr(0xFFFD)],
        ["\xE0\xA0A", chr(0xFFFD).'A'],
        ["\xF0\x90\x80", chr(0xFFFD)],
        ["\xF0\x90\x80A", chr(0xFFFD).'A'],
    );
    foreach my $test (@tests) {
        my $display = uc(unpack("H*", $test->[0]));
        is(get_printable_utf8($test->[0]), $test->[1], "get_printable_utf8 truncated sequences decode as expected");
    }
}

{
    my $fname = 'test_read_text_file.txt';
    if(open(my $fh, '>:raw', $fname)) {
        print $fh 'A'.chr(0xFF).'B';
        close($fh);
        my $text = do {
            local $SIG{__WARN__} = sub {};
            read_text_file_lossy($fname)
        };
        is($text,  'A'.chr(0xFFFD).'B', 'read_text_file_lossy Valid invalid valid');
        my $message = 'read_text_file throws on invalid file';
        try {
            read_text_file($fname);
            fail($message);
        } catch ($e) {
            pass($message);
        }
        unlink($fname);
    }
}

{
    my $fname = 'test_write_text_file.txt';
    my $message = 'write_text_file throws on invalid text';
    my $input = "A\x{D800}B";
    try {
        {
            local $SIG{__WARN__} = sub {};
            write_text_file($fname, $input);
        }
        fail($message);
    } catch ($e) {
        pass($message);
    }
    unlink($fname);
    try {
        {
            local $SIG{__WARN__} = sub {};
            write_text_file_lossy($fname, $input);
        }
        my $text = read_text_file($fname);
        is($text,  'A'.chr(0xFFFD).'B', 'write_text_file_lossy Valid invalid valid');
    } catch ($e) {
        fail("write_text_file_lossy does not crash");
    }
    unlink($fname);
}

{
    my $str = 'A'.chr(0xFF).'B';
    my $bytes = encode('UTF-8', $str, Encode::FB_CROAK | Encode::LEAVE_SRC);
    try {
        my $bcopy = $bytes;
        is(decode_utf_8($bytes), $str, 'string decodes to original string');
        is($bytes, $bcopy, "decode_utf_8 doesn't modify original string");
    } catch ($e) {
        fail('decode_utf_8 decodes valid string without crashing')
    }
}
{
    my $str = "A\x{D800}B";
    my $bytes = encode('utf8', $str, Encode::FB_CROAK | Encode::LEAVE_SRC);
    my $bcopy = $bytes;
    my $message = 'decode_utf_8 throws on invalid string';
    try {
        decode_utf_8($bytes);
        fail($message);
    } catch ($e) {
        pass($message);
        is($bytes, $bcopy, "decode_utf_8 doesn't modify original string");
    }
}

{
    my $scalar = chr(0xFF);
    my $filename = 'test_write_file.txt';
    my $message = 'Write 0xFF works';
    try {
        write_file($filename, $scalar);
        my $readback = read_file($filename);
        is($readback, $scalar, $message);
    } catch ($e) {
        fail($message);
    }
    unlink($filename);
    $message = 'Write (UTF8) 0xFF works';
    utf8::upgrade($scalar);
    try {
        no warnings 'MHFS::Util';
        write_file($filename , $scalar);
        my $readback = read_file($filename);
        is($readback, "\xC3\xBF", $message);
    } catch ($e) {
        fail($message);
    }
    unlink($filename);
}

{
    is(fold_case('HARAMBE'), 'harambe', 'fold_case works');
}
