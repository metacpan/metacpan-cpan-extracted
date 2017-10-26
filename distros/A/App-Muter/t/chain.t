#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Test::More;

use IO::Scalar;
use App::Muter;

eval { require Test::NoWarnings; };

App::Muter::Registry->instance->load_backends();

test_run_pattern('hex', "\x00A7\x80", '00413780', 'basic hex');

test_run_pattern('base64', '',        '',             'base64 empty data');
test_run_pattern('base64', 'abcdefg', 'YWJjZGVmZw==', 'base64 pattern 1');
test_run_pattern('base64', 'hij',     'aGlq',         'base64 pattern 2');
test_run_pattern('base64', "klmn\n",  'a2xtbgo=',     'base64 pattern 3');
test_run_pattern('base64', 'aa?',     'YWE/',         'base64 pattern 4');
test_run_pattern('base64', 'bc>',     'YmM+',         'base64 pattern 5');

test_run_pattern('base64(yui)', '', '', 'base64(yui) empty data');
test_run_pattern('base64(yui)', 'abcdefg', 'YWJjZGVmZw--',
    'base64(yui) pattern 1');
test_run_pattern('base64(yui)', 'hij',    'aGlq',     'base64(yui) pattern 2');
test_run_pattern('base64(yui)', "klmn\n", 'a2xtbgo-', 'base64(yui) pattern 3');
test_run_pattern('base64(yui)', 'aa?',    'YWE_',     'base64(yui) pattern 4');
test_run_pattern('base64(yui)', 'bc>',    'YmM.',     'base64(yui) pattern 5');

test_run_pattern('url64', '',        '',           'url64 empty data');
test_run_pattern('url64', 'abcdefg', 'YWJjZGVmZw', 'url64 pattern 1');
test_run_pattern('url64', 'hij',     'aGlq',       'url64 pattern 2');
test_run_pattern('url64', "klmn\n",  'a2xtbgo',    'url64 pattern 3');
test_run_pattern('url64', 'aa?',     'YWE_',       'url64 pattern 4');
test_run_pattern('url64', 'bc>',     'YmM-',       'url64 pattern 5');

test_run_pattern('uri', '',          '',                'uri empty data');
test_run_pattern('uri', 'test text', 'test%20text',     'uri pattern 1');
test_run_pattern('uri', 'test/?^t~', 'test%2F%3F%5Et~', 'uri pattern 2');
test_run_pattern('uri', '+',         '%2B',             'uri pattern 3');
test_run_pattern('uri(lower)', '', '', 'uri lower empty data');
test_run_pattern('uri(lower)', 'test text', 'test%20text',
    'uri lower pattern 1');
test_run_pattern('uri(lower)', 'test/?^t~', 'test%2f%3f%5et~',
    'uri lower pattern 2');
test_run_pattern('form', '',          '',                'form empty data');
test_run_pattern('form', 'test text', 'test+text',       'form pattern 1');
test_run_pattern('form', 'test/?^t~', 'test%2F%3F%5Et~', 'form pattern 2');
test_run_pattern('form', '+',         '%2B',             'form pattern 3');
test_run_pattern('form', ' ',         '+',               'form pattern 4');
test_run_pattern('form(lower)', 'test /?^t~', 'test+%2f%3f%5et~', 'form multi');

test_run_chain(
    'hex',              "\x01\x23\x45\x67\x89\xab\xcd\xef",
    '0123456789abcdef', 'simple hex pattern'
);
test_run_chain(
    'hex(lower)',       "\x01\x23\x45\x67\x89\xab\xcd\xef",
    '0123456789abcdef', 'simple hex pattern'
);
test_run_chain(
    'hex(upper)',       "\x01\x23\x45\x67\x89\xab\xcd\xef",
    '0123456789ABCDEF', 'simple hex pattern (upper)'
);
test_run_chain(
    'base16',           "\x01\x23\x45\x67\x89\xab\xcd\xef",
    '0123456789ABCDEF', 'simple base16 pattern'
);

test_run_pattern('base32', '',      '',         'empty base32 pattern');
test_run_pattern('base32', 'f',     'MY======', 'base32 pattern 1');
test_run_pattern('base32', 'fo',    'MZXQ====', 'base32 pattern 2');
test_run_pattern('base32', 'foo',   'MZXW6===', 'base32 pattern 3');
test_run_pattern('base32', 'foob',  'MZXW6YQ=', 'base32 pattern 4');
test_run_pattern('base32', 'fooba', 'MZXW6YTB', 'base32 pattern 5');
test_run_pattern('base32', 'foobar', 'MZXW6YTBOI======', 'base32 pattern 6');
test_run_pattern('base32', ' ',      'EA======',         'base32 pattern 7');
test_run_pattern('base32', '  ',     'EAQA====',         'base32 pattern 8');
test_run_pattern('base32', '   ',    'EAQCA===',         'base32 pattern 9');
test_run_pattern('base32', '    ',   'EAQCAIA=',         'base32 pattern 10');
test_run_pattern('base32', '     ',  'EAQCAIBA',         'base32 pattern 11');
test_run_pattern('base32', '      ', 'EAQCAIBAEA======', 'base32 pattern 12');

test_run_pattern('vis', '',            '',            'empty vis pattern');
test_run_pattern('vis', 'abcdef',      'abcdef',      'vis pattern 1');
test_run_pattern('vis', "a b\tc\ndef", "a b\tc\ndef", 'vis pattern 2');
test_run_pattern('vis(space)', "a b\tc\ndef", "a\\040b\tc\ndef",
    'vis pattern 3');
test_run_pattern('vis(sp)',  "a b\tc\ndef", "a\\040b\tc\ndef", 'vis pattern 4');
test_run_pattern('vis(tab)', "a b\tc\ndef", "a b\\^Ic\ndef",   'vis pattern 5');
test_run_pattern('vis(nl)',  "a b\tc\ndef", "a b\tc\\^Jdef",   'vis pattern 6');
test_run_pattern('vis(sp,tab)', "a b\tc\ndef", "a\\040b\\^Ic\ndef",
    'vis pattern 7');
test_run_pattern('vis(white)', "a b\tc\ndef", "a\\040b\\^Ic\\^Jdef",
    'vis pattern 8');
test_run_pattern('vis(cstyle)', "a b\tc\ndef", "a b\tc\ndef", 'vis pattern 9');
test_run_pattern('vis(cstyle,white)', "a b\tc\ndef", "a\\sb\\tc\\ndef",
    'vis pattern 10');
test_run_pattern(
    'vis(cstyle,white)',        "a\x00b\x00\x002c\x00\ndef",
    "a\\0b\\0\\0002c\\0\\ndef", 'vis pattern 11'
);
test_run_pattern(
    'vis(cstyle,white)',         "a\x00b\x00\x00\x008c\x00\ndef",
    "a\\0b\\0\\0\\08c\\0\\ndef", 'vis pattern 12'
);
test_run_pattern('vis(cstyle)', "\x00A7\x80", "\\0A7\\M^@",   'vis pattern 13');
test_run_pattern('vis(octal)',  "\x00A7\x80", "\\000A7\\200", 'vis pattern 14');
test_run_pattern(
    'vis,cstyle,white',          "a\x00b\x00\x00\x008c\x00\ndef",
    "a\\0b\\0\\0\\08c\\0\\ndef", 'vis pattern 15'
);
test_run_pattern(
    'vis,cstyle,white', "\x07\x08\x09\x0a\x0b\x0c\x0d\x20",
    '\a\b\t\n\v\f\r\s', 'vis pattern 16'
);

test_run_pattern(
    'quotedprintable',  "A=B\n.\nDone",
    'A=3DB=0A.=0ADone', 'quotedprintable pattern 1'
);
test_run_pattern(
    'quotedprintable(smtp)', "A=B\n.\nDone",
    'A=3DB=0A=2E=0ADone',    'quotedprintable pattern 2'
);
test_run_pattern(
    'quotedprintable(smtp)',
    "A=\nFrom \nDone",
    'A=3D=0A=46rom =0ADone',
    'quotedprintable pattern 3'
);
test_run_pattern(
    'quotedprintable',
    "A=\n.\nFrom \nDone",
    'A=3D=0A.=0AFrom =0ADone',
    'quotedprintable pattern 4'
);

# Patterns from TCL testsuite.  Public domain.
my @patterns = qw(
    AA====== AE====== AI====== AM======
    AQ====== AU====== AY====== A4======
    BA====== BE====== BI====== BM======
    BQ====== BU====== BY====== B4======
    CA====== CE====== CI====== CM======
    CQ====== CU====== CY====== C4======
    DA====== DE====== DI====== DM======
    DQ====== DU====== DY====== D4======
    EA====== EE====== EI====== EM======
    EQ====== EU====== EY====== E4======
    FA====== FE====== FI====== FM======
    FQ====== FU====== FY====== F4======
    GA====== GE====== GI====== GM======
    GQ====== GU====== GY====== G4======
    HA====== HE====== HI====== HM======
    HQ====== HU====== HY====== H4======
    IA====== IE====== II====== IM======
    IQ====== IU====== IY====== I4======
    JA====== JE====== JI====== JM======
    JQ====== JU====== JY====== J4======
    KA====== KE====== KI====== KM======
    KQ====== KU====== KY====== K4======
    LA====== LE====== LI====== LM======
    LQ====== LU====== LY====== L4======
    MA====== ME====== MI====== MM======
    MQ====== MU====== MY====== M4======
    NA====== NE====== NI====== NM======
    NQ====== NU====== NY====== N4======
    OA====== OE====== OI====== OM======
    OQ====== OU====== OY====== O4======
    PA====== PE====== PI====== PM======
    PQ====== PU====== PY====== P4======
    QA====== QE====== QI====== QM======
    QQ====== QU====== QY====== Q4======
    RA====== RE====== RI====== RM======
    RQ====== RU====== RY====== R4======
    SA====== SE====== SI====== SM======
    SQ====== SU====== SY====== S4======
    TA====== TE====== TI====== TM======
    TQ====== TU====== TY====== T4======
    UA====== UE====== UI====== UM======
    UQ====== UU====== UY====== U4======
    VA====== VE====== VI====== VM======
    VQ====== VU====== VY====== V4======
    WA====== WE====== WI====== WM======
    WQ====== WU====== WY====== W4======
    XA====== XE====== XI====== XM======
    XQ====== XU====== XY====== X4======
    YA====== YE====== YI====== YM======
    YQ====== YU====== YY====== Y4======
    ZA====== ZE====== ZI====== ZM======
    ZQ====== ZU====== ZY====== Z4======
    2A====== 2E====== 2I====== 2M======
    2Q====== 2U====== 2Y====== 24======
    3A====== 3E====== 3I====== 3M======
    3Q====== 3U====== 3Y====== 34======
    4A====== 4E====== 4I====== 4M======
    4Q====== 4U====== 4Y====== 44======
    5A====== 5E====== 5I====== 5M======
    5Q====== 5U====== 5Y====== 54======
    6A====== 6E====== 6I====== 6M======
    6Q====== 6U====== 6Y====== 64======
    7A====== 7E====== 7I====== 7M======
    7Q====== 7U====== 7Y====== 74======
);

foreach my $i (0 .. 255) {
    use bytes;
    my $byte = chr($i);
    test_run_pattern('base32',   $byte, $patterns[$i], "base32 byte $i");
    test_run_pattern('identity', $byte, $byte,         "identity byte $i");
}

test_run_pattern('base32hex', '',      '',         'empty b32hex pattern');
test_run_pattern('base32hex', 'f',     'CO======', 'b32hex pattern 1');
test_run_pattern('base32hex', 'fo',    'CPNG====', 'b32hex pattern 2');
test_run_pattern('base32hex', 'foo',   'CPNMU===', 'b32hex pattern 3');
test_run_pattern('base32hex', 'foob',  'CPNMUOG=', 'b32hex pattern 4');
test_run_pattern('base32hex', 'fooba', 'CPNMUOJ1', 'b32hex pattern 5');
test_run_pattern('base32hex', 'foobar', 'CPNMUOJ1E8======', 'b32hex pattern 6');

# Test cases from the ascii85 Ruby gem.
test_run_pattern('ascii85', '',       '',         'empty ascii85 pattern');
test_run_pattern('ascii85', ' ',      '<~+9~>',   'ascii85 pattern 1');
test_run_pattern('ascii85', "\0",     '<~!!~>',   'ascii85 pattern 2');
test_run_pattern('ascii85', "\0" x 2, '<~!!!~>',  'ascii85 pattern 3');
test_run_pattern('ascii85', "\0" x 3, '<~!!!!~>', 'ascii85 pattern 4');
test_run_pattern('ascii85', "\0" x 4, '<~z~>',    'ascii85 pattern 5');
test_run_pattern('ascii85', "\0" x 5, '<~z!!~>',  'ascii85 pattern 6');
test_run_pattern('ascii85', "A\0\0\0\0", '<~5l^lb!!~>',   'ascii85 pattern 7');
test_run_pattern('ascii85', "A",         '<~5l~>',        'ascii85 pattern 8');
test_run_pattern('ascii85', "AB",        '<~5sb~>',       'ascii85 pattern 9');
test_run_pattern('ascii85', "ABC",       '<~5sdp~>',      'ascii85 pattern 10');
test_run_pattern('ascii85', "ABCD",      '<~5sdq,~>',     'ascii85 pattern 11');
test_run_pattern('ascii85', "ABCDE",     '<~5sdq,70~>',   'ascii85 pattern 12');
test_run_pattern('ascii85', "ABCDEF",    '<~5sdq,77I~>',  'ascii85 pattern 13');
test_run_pattern('ascii85', "ABCDEFG",   '<~5sdq,77Kc~>', 'ascii85 pattern 14');
test_run_pattern('ascii85', "ABCDEFGH", '<~5sdq,77Kd<~>', 'ascii85 pattern 15');
test_run_pattern('ascii85', "ABCDEFGHI", '<~5sdq,77Kd<8H~>',
    'ascii85 pattern 16');
test_run_pattern('ascii85', "Ascii85", '<~6$$OMBfIs~>', 'ascii85 pattern 17');
test_run_pattern(
    'ascii85',
    'Antidisestablishmentarianism' =>
        '<~6#LdYA8-*rF*(i"Ch[s(D.RU,@<-\'jDJ=0/~>',
    'ascii85 pattern 18'
);

test_run_pattern('uuencode', "Cat", "#0V%T\n`\n", "uuencode pattern 1");
test_run_pattern(
    'uuencode',
    "http://www.wikipedia.org\r\n",
    "::'1T<#HO+W=W=RYW:6MI<&5D:6\$N;W)G#0H`\n`\n",
    "uuencode pattern 2"
);

test_run_pattern(
    'xml',
    q{"Hello, ol' New Jersey! <:>"},
    '&quot;Hello, ol&apos; New Jersey! &lt;:&gt;&quot;',
    'xml pattern 1'
);
test_run_pattern(
    'xml(hex)',
    q{"Hello, ol' New Jersey! <:>"},
    '&#x22;Hello, ol&#x27; New Jersey! &#x3c;:&#x3e;&#x22;',
    'xml pattern 2'
);
test_run_pattern(
    'xml(html)',
    q{"Hello, ol' New Jersey! <:>"},
    '&quot;Hello, ol&#x27; New Jersey! &lt;:&gt;&quot;',
    'xml pattern 3'
);
test_run_chain('xml(hex)', '&abc', '&#x26;abc', 'xml pattern 4');
test_run_chain('xml,hex', '&abc', '&#x26;abc',
    'xml pattern 4 (without parentheses)');

test_run_chain('-xml', '&#x00a9;', '©',           'xml decode hex');
test_run_chain('-xml', '&#xfeff;', "\xef\xbb\xbf", 'xml decode hex BOM');

test_run_chain('-hex:base64', '00413780', 'AEE3gA==', 'simple chain');

test_run_chain(
    '-hex:hash(sha256):url64',
    '616263',
    'ungWv48Bz-pBQUDeXa4iI7ADYaOWF3qctBD_YfIAFa0',
    'simple chain with consuming filter'
);

test_run_chain(
    '-hex:hash,sha256:url64',
    '616263',
    'ungWv48Bz-pBQUDeXa4iI7ADYaOWF3qctBD_YfIAFa0',
    'simple chain with no parentheses'
);

Test::NoWarnings::had_no_warnings() if $INC{'Test/NoWarnings.pm'};

done_testing;

sub test_run_pattern {
    my ($chain, $input, $output, $desc) = @_;

    subtest $desc => sub {
        test_run_chain($chain,    $input,  $output, "$desc (encoding)");
        test_run_chain("-$chain", $output, $input,  "$desc (decoding)");
    };
    return;
}

sub test_run_chain {
    my ($chain, $input, $output, $desc) = @_;

    subtest $desc => sub {
        is(run_chain($chain, $input, 1),   $output, "$desc (1-byte chunks)");
        is(run_chain($chain, $input, 2),   $output, "$desc (2-byte chunks)");
        is(run_chain($chain, $input, 3),   $output, "$desc (3-byte chunks)");
        is(run_chain($chain, $input, 4),   $output, "$desc (4-byte chunks)");
        is(run_chain($chain, $input, 16),  $output, "$desc (16-byte chunks)");
        is(run_chain($chain, $input, 512), $output, "$desc (512-byte chunks)");
        is(App::Muter::Interface::process($chain, $input),
            $output, "$desc (one-shot)");
    };
    return;
}

sub run_chain {
    my ($chain, $input, $blocksize) = @_;
    my $output = '';
    my $ifh    = IO::Scalar->new(\$input);
    my $ofh    = IO::Scalar->new(\$output);

    App::Muter::Main::run_chain($chain, 0, [$ifh], $ofh, $blocksize);

    return $output;
}
