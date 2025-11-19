use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Encode qw( encode decode );
use Crypt::SecretBuffer qw( secret UTF8 ISO8859_1 UTF16LE UTF16BE HEX MATCH_NEGATE MATCH_MULTI );

subtest constructors => sub {
   my $buf= secret("abcdef");
   is $buf->span,
      object {
         call pos => 0;
         call len => 6;
         call length => 6;
         call lim => 6;
         call buf => $buf;
         call buffer => $buf;
         call encoding => ISO8859_1;
      },
      'full buffer span';

   is $buf->span->clone,
      object {
         call pos => 0;
         call len => 6;
         call length => 6;
         call lim => 6;
         call buf => $buf;
         call buffer => $buf;
         call encoding => ISO8859_1;
      },
      'full buffer span clone';

   is $buf->span(1,-1),
      object { call pos => 1; call len => 4; call lim => 5; },
      'span using negative pos and len';

   is $buf->span(pos => 1, lim => 5),
      object { call pos => 1; call len => 4; call lim => 5; },
      'using attribute names';

   is( Crypt::SecretBuffer::Span->new(buf => secret(""), pos => 2, len => 2, encoding => 'UTF8'),
      object {
         call buf => object { call length => 0; };
         call pos => 0;
         call len => 0;
         call encoding => UTF8;
      },
      'class constructor, all attributes, pos truncated' );

   my $s= Crypt::SecretBuffer::Span->new(buf => secret("abcdefgh"), pos => -4, len => -1);
   is $s,
      object {
         call buf => object { call length => 8; };
         call pos => 4;
         call lim => 7;
         call len => 3;
         call encoding => ISO8859_1;
      },
      'class constructor, negative pos';

   $s->encoding(UTF8);
   is $s->clone(pos => -3),
      object {
         call pos => 5;
         call lim => 7;
         call len => 2;
         call buf => object { call length => 8; };
         call encoding => UTF8;
      },
      'clone with negative pos override';

   is $s->clone(-3),
      object {
         call pos => 5;
         call lim => 7;
         call len => 2;
         call buf => object { call length => 8; };
         call encoding => UTF8;
      },
      'clone with positional negative pos override';

   is $s->clone(len => 1),
      object { call pos => 4; call lim => 5; call len => 1; },
      'clone with new len';

   is $s->clone(len => 5),
      object { call pos => 4; call lim => 8; call len => 4; },
      'clone with len that gets truncated';

   is $s->clone(lim => 8),
      object { call pos => 4; call lim => 8; call len => 4; },
      'clone with new lim';

   $s->pos(1);
   $s->lim(7);
   is $s->len, 6, 'pos/lim modified, len updated';
   $s->encoding(UTF8);
   is $s->encoding, UTF8, 'encoding changed to enum';

   is $buf->span(2,3,UTF8)->subspan(1),
      object {
         call pos => 3;
         call len => 2;
         call lim => 5;
         call encoding => UTF8;
      },
      'sub-span adds pos and preserves encoding';

   is $buf->span(2,3)->subspan(-2, -1),
      object {
         call pos => 3;
         call lim => 4;
         call len => 1;
      },
      'sub-span negative indices relative to parent span';
};

subtest starts_with => sub {
   my $s= secret("abc123def")->span;
   ok( $s->starts_with('a'), 'starts_with character' );
   ok( $s->starts_with('ab'), 'starts_with string' );
   ok( !$s->starts_with('b'), 'doesnt start with char' );
   ok( $s->starts_with(qr/[a-z]/), 'starts with char class' );
   ok( $s->starts_with(qr/[a-z]+/), 'starts with char class repeated' );
   ok( !$s->starts_with(qr/[0-9]/), 'doesnt start with digit' );

   my $x= "\x{100}\x{200}\x{300}";
   utf8::encode($x);
   # ascii doesn't take effect until attempting to scan chars, so this works
   $s= secret($x)->span(encoding => 'ASCII');
   # it will fail because ASCII is strict 7-bit
   ok !eval{ $s->starts_with(qr/[a]/); 1 }, 'ASCII dies on 0x80..0xFF';
   note $@;
   # it will return a byte of the UTF8 encoding
   $s->encoding(ISO8859_1);
   ok $s->starts_with(qr/[\xC4]/), 'starts with byte';
   # it will decode the character
   $s->encoding('UTF-8');
   ok $s->starts_with(qr/[\x{100}]/), 'starts with utf-8 char';
};

subtest ends_with => sub {
   my $s= secret("abc123def")->span;
   ok( $s->ends_with('f'), 'ends_with character' );
   ok( $s->ends_with('ef'), 'ends_with string' );
   ok( !$s->ends_with('a'), 'doesnt end with char' );
   ok( $s->ends_with(qr/[a-z]/), 'ends with char class' );
   ok( $s->ends_with(qr/[a-z]+/), 'ends with char class repeated' );
   ok( !$s->ends_with(qr/[0-9]/), 'doesnt end with digit' );

   # This tests the reverse decoding of various encodings
   $s= $s->buf;
   ok( $s->span(encoding => HEX)->ends_with(qr/[\xEF]/), 'parse hex in reverse' );
   $s= secret(encode('UTF-8', "123\x{123}"));
   ok( $s->span(encoding => UTF8)->ends_with(qr/[\x{123}]/), 'parse utf8 2-byte in reverse' );
   $s= secret(encode('UTF-8', "123\x{1234}"));
   ok( $s->span(encoding => UTF8)->ends_with(qr/[\x{1234}]/), 'parse utf8 3-byte in reverse' );
   $s= secret(encode('UTF-8', "123\x{12345}"));
   ok( $s->span(encoding => UTF8)->ends_with(qr/[\x{12345}]/), 'parse utf8 4-byte in reverse' );
   $s= secret(encode('UTF-16LE', "123\x{1234}"));
   ok( $s->span(encoding => UTF16LE)->ends_with(qr/[\x{1234}]/), 'parse utf-16le in reverse' );
   $s= secret(encode('UTF-16LE', "123\x{12345}"));
   ok( $s->span(encoding => UTF16LE)->ends_with(qr/[\x{12345}]/), 'parse utf-16le surrogates in reverse' );
   $s= secret(encode('UTF-16BE', "123\x{1234}"));
   ok( $s->span(encoding => UTF16BE)->ends_with(qr/[\x{1234}]/), 'parse utf-16be in reverse' );
   $s= secret(encode('UTF-16BE', "123\x{12345}"));
   ok( $s->span(encoding => UTF16BE)->ends_with(qr/[\x{12345}]/), 'parse utf-16be surrogates in reverse' );
};

subtest parse => sub {
   my $s= secret("name=val")->span;
   is $s->parse("="), undef, 'no = anchored at start';
   is $s->parse(qr/[a-z]+/), object { call pos => 0; call len => 4; }, 'parse name';
   is $s->parse("="), object { call pos => 4; call len => 1; }, 'parse =';
   is $s, object { call pos => 5; call len => 3; }, 'remaining value';

   $s= $s->buf->span;
   is $s->parse('=', MATCH_NEGATE|MATCH_MULTI), object { call pos => 0; call len => 4; }, 'parse name by MATCH_NEGATE =';

   $s= secret("1=2==3=4")->span;
   is $s->rparse('==', MATCH_NEGATE|MATCH_MULTI), object { call pos => 5; call len => 3; }, 'parse value by reverse MATCH_NEGATE =';
   is $s, object { call pos => 0; call len => 5; }, 'remianing buffer';
};

subtest trim => sub {
   my $buf= secret(" 1\r\n2\t3\r\n");
   is $buf->span->trim,
      object {
         call pos => 1;
         call len => 6;
      },
      'trim whole buffer';
   is $buf->span(2, 6)->trim,
      object {
         call pos => 4;
         call len => 3;
      },
      'trim sub-span';
   # ltrim
   is $buf->span->ltrim,
      object {
         call pos => 1;
         call len => 8;
      },
      'ltrim';
   is $buf->span->rtrim,
      object {
         call pos => 0;
         call len => 7;
      },
      'rtrim';
};

subtest copy_iso8859 => sub {
   my $s= secret("abcdef")->span;
   is $s->copy,
      object {
         call stringify => '[REDACTED]';
         call length => 6;
         call sub { shift->span->starts_with("abcdef") } => T;
      },
      'copy';
   my $str;
   $s->copy_to($str);
   is( $str, "abcdef", "copy to scalar" );
   my $buf= secret("");
   $s->copy_to($buf);
   is $buf,
      object {
         call stringify => '[REDACTED]';
         call length => 6;
         call sub { shift->span->starts_with("abcdef") } => T;
      },
      'copy to secret';

   # Try to specify something out of bounds
   $s->buf->length(4);
   is( $s->length, 6, 'span is 6 bytes' );
   ok( !eval { $s->copy }, 'copy died' );
   like( $@, qr/ends beyond buffer/, 'error message' );
};

subtest copy_widechar => sub {
   my $unicode= "\0\x{10}\x{100}\x{1000}\x{10000}\x{10FFFD}";

   my $utf8= encode('UTF-8', $unicode);
   my $buf= '';
   secret($utf8)->span(encoding => UTF8)->copy_to($buf);
   is( $buf, $unicode, 'round trip through UTF-8' )
      or note map escape_nonprintable($_)."\n", $utf8, $buf;

   my $utf16le= encode('UTF-16LE', $unicode);
   $buf= '';
   secret($utf16le)->span(encoding => UTF16LE)->copy_to($buf);
   is( $buf, $unicode, 'round trip through UTF-16LE' )
      or diag explain $buf;

   my $utf16be= encode('UTF-16BE', $unicode);
   $buf= '';
   secret($utf16be)->span(encoding => UTF16BE)->copy_to($buf);
   is( $buf, $unicode, 'round trip through UTF-16BE' )
      or diag explain $buf;
};

subtest copy_hex => sub {
   my $s= secret("\x01\x02\x03");
   is( $s->span->copy(encoding => HEX),
      object {
         call sub { shift->span->starts_with("010203") }, T;
         call length => 6;
      },
      'convert to hex' );

   $s= secret("010203");
   is( $s->span(encoding => HEX)->copy(encoding => ISO8859_1),
      object {
         call sub { shift->span->starts_with("\x01\x02\x03") }, T;
         call length => 3;
      },
      'convert from hex' );
};

done_testing;
