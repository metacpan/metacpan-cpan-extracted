#!/usr/bin/perl
use strict;
use lib '.', '../lib';
use Data::Tools;
use Data::Tools::Crypto::Symmetric;
use Crypt::AuthEnc::ChaCha20Poly1305 qw( chacha20poly1305_encrypt_authenticate );
use Crypt::PRNG qw( random_bytes );
use Encode qw( encode decode );
use Time::HiRes qw( time );

##############################################################################

my $TESTS = 0;
my $FAILS = 0;

sub ok
{
  my $res  = shift;
  my $desc = shift;

  $TESTS++;
  $FAILS++ unless $res;

  # TAP, so that "make test" and prove can run this file as well as a human
  printf "%sok %d - %s\n", $res ? '' : 'not ', $TESTS, $desc;

  return $res;
}

# returns true only for an Exception::Sink boom() whose message matches $expect,
# so that an unrelated death (i.e. a raw croak from the crypto layer) does not
# silently pass for a missing boom() guard
sub boomed
{
  my $code   = shift;
  my $expect = shift;

  eval { $code->() };

  return 0 unless $@;
  return 0 unless ref( $@ ) =~ /^Exception::Sink/;
  return 0 unless "$@" =~ /^BOOM:/;
  return 0 if defined $expect and "$@" !~ /$expect/;

  return 1;
}

# renders a scalar for test output without spilling raw bytes to the tty
sub vis
{
  my $s = shift;

  return 'undef' unless defined $s;
  return "''"    unless length $s;

  my $v = join '', map { my $o = ord; $o >= 32 && $o < 127 ? chr( $o ) : sprintf( '\x{%x}', $o ) } split //, $s;
  $v = substr( $v, 0, 40 ) . '...' if length( $v ) > 43;

  return $v;
}

##############################################################################

my $KEY  = 'k' x 32;
my $KEY2 = 'j' x 32;

my $NONCE_LEN = 12;
my $TAG_LEN   = 16;
my $FLAG_LEN  = 1;  # 'b' binary / 'u' utf8 marker prepended to the plaintext
my $OVERHEAD  = $NONCE_LEN + $TAG_LEN + $FLAG_LEN;

print "# -- construction and key validation\n";

my $c = Data::Tools::Crypto::Symmetric->new( $KEY );
ok( ref( $c ) eq 'Data::Tools::Crypto::Symmetric', 'new() returns object' );
ok( $c->isa( 'Data::Tools::Crypto' ), 'inherits Data::Tools::Crypto' );

ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( undef      ) }, 'not defined' ), 'undef key rejected'        );
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( ''         ) }, 'not defined or empty' ), 'empty key rejected' );
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( 'k' x 31   ) }, 'key size'    ), 'short key (31) rejected'   );
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( 'k' x 33   ) }, 'key size'    ), 'long key (33) rejected'    );
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( 'k' x 16   ) }, 'key size'    ), 'aes-sized key (16) rejected' );

# utf8-flagged but latin1-representable key must be accepted and downgraded
my $utf8_key = 'k' x 31 . "\xe9";
utf8::upgrade( $utf8_key );
ok( ! boomed( sub { Data::Tools::Crypto::Symmetric->new( $utf8_key ) } ), 'downgradeable utf8 key accepted' );

# key with real wide characters is 32 chars but not 32 bytes, must be rejected
my $wide_key = 'k' x 31 . "\x{263a}";
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( $wide_key ) }, 'key' ), 'wide-char key rejected' );

# options are honoured or refused, never silently ignored -- none are known yet
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( $KEY, NONSENSE => 1 ) }, 'unknown option' ),
    'unknown option refused by new()' );
ok( boomed( sub { Data::Tools::Crypto::Symmetric->new( $KEY )->reinit( $KEY2, NONSENSE => 1 ) }, 'unknown option' ),
    'unknown option refused by reinit()' );

##############################################################################
#
#  plaintext variations
#
#  perl only sets the utf8 flag when it has to, so a latin1-range literal is
#  NOT flagged unless upgraded explicitly. the contract under test is that
#  encrypt/decrypt is fully transparent: the value, the character length and
#  the utf8 flag all come back exactly as they went in.
#
##############################################################################

sub check_roundtrip
{
  my $ptext = shift;
  my $desc  = shift;

  my $ctext = eval { $c->encrypt( $ptext ) };
  if( $@ )
    {
    ok( 0, "roundtrip: $desc -- encrypt died: " . ( split /\n/, $@ )[ 0 ] );
    return;
    }

  my $back = $c->decrypt( $ctext );

  unless( ok( defined $back && $back eq $ptext, "roundtrip: $desc" ) )
    {
    printf "#      in  %s\n", vis( $ptext );
    printf "#      out %s\n", vis( $back  );
    return;
    }

  ok( utf8::is_utf8( $back ) == utf8::is_utf8( $ptext ), "utf8 flag preserved: $desc" );
  ok( length( $back ) == length( $ptext ),               "length preserved: $desc"    );

  # ciphertext is sized by the encoded byte length, not the character length
  my $bytes = utf8::is_utf8( $ptext ) ? length( encode( 'UTF-8', $ptext ) ) : length( $ptext );
  ok( length( $ctext ) == $bytes + $OVERHEAD,            "ciphertext overhead: $desc" );
}

print "# -- plaintext variations: non-utf8 (byte strings)\n";

my $all_bytes = join '', map { chr } 0 .. 255;

my @binary = (
             [ ''                       , 'empty string'                 ],
             [ 'a'                      , 'single ascii byte'            ],
             [ "\x00"                   , 'single NUL byte'              ],
             [ 'hello, world'           , 'plain ascii text'             ],
             [ "\x00\xff\x80\x00binary" , 'mixed binary with NULs'       ],
             [ $all_bytes               , 'all 256 byte values'          ],
             [ $all_bytes x 40          , 'all 256 byte values x40'      ],
             [ "caf\xc3\xa9"            , 'bytes that are valid utf8'    ],
             [ "\xff\xfe"               , 'bytes that are invalid utf8'  ],
             [ "\xed\xa0\x80"           , 'bytes encoding a surrogate'   ],
             [ "\xc3"                   , 'truncated utf8 lead byte'     ],
             [ random_bytes( 10000 )    , '10k random binary'            ],
             );

for my $t ( @binary )
  {
  my ( $ptext, $desc ) = @$t;
  ok( ! utf8::is_utf8( $ptext ), "test input is unflagged: $desc" );
  check_roundtrip( $ptext, $desc );
  }

print "# -- plaintext variations: utf8 (character strings)\n";

my $upgraded_empty = '';            utf8::upgrade( $upgraded_empty );
my $upgraded_ascii = 'plain ascii'; utf8::upgrade( $upgraded_ascii );
my $upgraded_latin = "caf\x{e9}";   utf8::upgrade( $upgraded_latin );

my @chars = (
            [ $upgraded_empty                  , 'flagged empty string'        ],
            [ $upgraded_ascii                  , 'flagged ascii only'          ],
            [ $upgraded_latin                  , 'latin1 range characters'     ],
            [ "\x{100}\x{1ff}"                 , 'latin extended-a'            ],
            [ "\x{263a}"                       , 'BMP symbol'                  ],
            [ "\x{4e2d}\x{6587}\x{5b57}"       , 'CJK'                         ],
            [ "\x{0410}\x{0431}\x{0432}"       , 'cyrillic'                    ],
            [ "\x{05d0}\x{05d1}"               , 'hebrew (rtl)'                ],
            [ "\x{1f600}\x{1f4a9}"             , 'astral plane (emoji)'        ],
            [ "e\x{0301}a\x{030a}"             , 'combining marks'             ],
            [ "\x{fffd}"                       , 'replacement char itself'     ],
            [ "a\x{263a}b\x{1f600}c"           , 'mixed ascii and wide'        ],
            [ "\x{263a}" x 5000                , '5k wide characters'          ],
            [ "\x{0}\x{263a}\x{0}"             , 'wide with embedded NULs'     ],
            );

for my $t ( @chars )
  {
  my ( $ptext, $desc ) = @$t;
  ok( utf8::is_utf8( $ptext ), "test input is flagged: $desc" );
  check_roundtrip( $ptext, $desc );
  }

print "# -- plaintext variations: malformed / boundary codepoints\n";

# these are scalars perl can hold but strict UTF-8 cannot represent. the module
# must either carry them through unchanged or refuse them loudly -- silently
# substituting U+FFFD corrupts the caller's data with no way to detect it
my @malformed = (
                [ "\x{d800}"  , 'lone high surrogate'      ],
                [ "\x{dfff}"  , 'lone low surrogate'       ],
                [ "\x{fffe}"  , 'noncharacter U+FFFE'      ],
                [ "\x{ffff}"  , 'noncharacter U+FFFF'      ],
                [ "\x{fdd0}"  , 'noncharacter U+FDD0'      ],
                [ "\x{10fffe}", 'noncharacter U+10FFFE'    ],
                [ "\x{10ffff}", 'noncharacter U+10FFFF'    ],
                [ "\x{110000}", 'beyond unicode range'     ],
                );

for my $t ( @malformed )
  {
  my ( $ptext, $desc ) = @$t;

  my $ctext = eval { $c->encrypt( $ptext ) };

  if( $@ )
    {
    # refusing outright is acceptable, as long as it is an explicit boom
    ok( boomed( sub { $c->encrypt( $ptext ) } ), "$desc: refused explicitly" );
    next;
    }

  my $back = $c->decrypt( $ctext );

  ok( defined $back && $back eq $ptext, "$desc: carried through unchanged (not silently replaced)" )
    or printf "#      U+%04X came back as U+%04X\n", ord( $ptext ), defined $back && length $back ? ord( $back ) : 0;
  }

print "# -- byte form and character form stay distinct\n";

# the same logical content as characters and as utf8 bytes must not converge
my $as_chars = "caf\x{e9}"; utf8::upgrade( $as_chars );
my $as_bytes = "caf\xc3\xa9";

my $r_chars = $c->decrypt( $c->encrypt( $as_chars ) );
my $r_bytes = $c->decrypt( $c->encrypt( $as_bytes ) );

ok( defined $r_chars && $r_chars eq $as_chars && utf8::is_utf8( $r_chars ),
    'character string returns as characters' );
ok( defined $r_bytes && $r_bytes eq $as_bytes && ! utf8::is_utf8( $r_bytes ),
    'byte string returns as bytes' );
ok( length( $r_chars ) == 4 && length( $r_bytes ) == 5,
    'chars and bytes forms stay distinct (4 chars vs 5 bytes)' );

# ciphertext is always binary, feeding a utf8-flagged scalar back in must boom
my $flagged_ct = $c->encrypt( 'payload' );
utf8::upgrade( $flagged_ct );
ok( boomed( sub { $c->decrypt( $flagged_ct ) }, 'utf8' ), 'utf8-flagged cryptotext rejected' );

print "# -- malformed authenticated payloads\n";

# forge payloads that pass authentication but carry a broken internal format,
# to exercise the decrypt-side flag handling. this needs the raw cipher and the
# same key, so the tag verifies and decrypt() reaches its own parsing
sub forge
{
  my $payload = shift;

  my $nonce = random_bytes( $NONCE_LEN );
  my ( $ctext, $tag ) = chacha20poly1305_encrypt_authenticate( $KEY, $nonce, undef, $payload );

  return $nonce . $ctext . $tag;
}

ok( defined $c->decrypt( forge( "b\xff\xfe" ) ), 'b-flag with non-utf8 bytes accepted' );
ok( $c->decrypt( forge( 'bhello' ) ) eq 'hello', 'b-flag payload strips flag correctly' );
ok( $c->decrypt( forge( 'b' ) ) eq '',           'b-flag with empty payload gives empty string' );
ok( $c->decrypt( forge( 'u' ) ) eq '',           'u-flag with empty payload gives empty string' );

# a u-flagged payload carrying invalid utf8 can only come from forging or from
# corruption upstream; it must not die, the data is already authenticated
my $bad_utf8 = eval { $c->decrypt( forge( "u\xff\xfe" ) ) };
ok( ! $@ && defined $bad_utf8,          'u-flag with invalid utf8 does not die'          );
ok( ! $@ && utf8::is_utf8( $bad_utf8 ), 'u-flag with invalid utf8 still returns characters' );

# unknown flag bytes currently fall through to the binary path
my $unknown = eval { $c->decrypt( forge( 'xhello' ) ) };
ok( ! $@ && defined $unknown, 'unknown flag byte does not die' );

# an authenticated but completely empty payload has no flag byte at all
ok( ! defined $c->decrypt( forge( '' ) ), 'authenticated empty payload rejected by length guard' );

print "# -- nonce randomness\n";

my $ptext = 'same plaintext every time';
my %seen;
my $same = 0;
for ( 1 .. 1000 )
  {
  my $ctext = $c->encrypt( $ptext );
  $seen{ substr( $ctext, 0, $NONCE_LEN ) }++;
  $same++ if $ctext eq $c->encrypt( $ptext );
  }
ok( scalar( keys %seen ) == 1000, '1000 encrypts produce 1000 distinct nonces' );
ok( $same == 0, 'same plaintext never yields same ciphertext' );

# the PRNG must reseed across fork, otherwise forked workers sharing one key
# would emit the same nonce, which breaks ChaCha20-Poly1305 completely
if( $^O =~ /win/i )
  {
  print "#      (fork nonce check skipped on $^O)\n";
  }
else
  {
  pipe( my $rd, my $wr );
  my @kids;
  for my $i ( 1 .. 4 )
    {
    my $pid = fork();
    if( ! defined $pid ) { last; }
    if( ! $pid )
      {
      print $wr unpack( 'H*', substr( $c->encrypt( 'x' ), 0, $NONCE_LEN ) ) . "\n";
      exit 0;
      }
    push @kids, $pid;
    }
  close $wr;
  waitpid( $_, 0 ) for @kids;
  my @nonces = <$rd>;
  chomp @nonces;
  my %uniq;
  $uniq{ $_ }++ for @nonces;
  ok( @nonces == 4 && keys( %uniq ) == 4, 'forked children produce distinct nonces' );
  }

print "# -- authentication\n";

my $ct = $c->encrypt( 'secret message' );

# flip one bit in each region: nonce, ciphertext body, tag
my %region = (
             'nonce'      => 0,
             'ciphertext' => $NONCE_LEN + 2,
             'tag'        => length( $ct ) - 1,
             );

for my $r ( sort keys %region )
  {
  my $pos = $region{ $r };
  my $bad = $ct;
  substr( $bad, $pos, 1 ) = chr( ord( substr( $bad, $pos, 1 ) ) ^ 1 );

  ok( ! defined $c->decrypt( $bad ), "tampered $r rejected" );
  }

ok( ! defined $c->decrypt( substr( $ct, 0, length( $ct ) - 1 ) ), 'truncated ciphertext rejected' );
ok( ! defined $c->decrypt( $ct . 'x' ),                           'extended ciphertext rejected' );

print "# -- short input\n";

ok( ! defined $c->decrypt( '' ),                      'empty cryptotext rejected' );
ok( ! defined $c->decrypt( 'x' x ( $OVERHEAD - 1 ) ), 'cryptotext below minimum length rejected' );

# an empty plaintext still carries the flag byte, so it is exactly $OVERHEAD
my $empty_ct = $c->encrypt( '' );
ok( length( $empty_ct ) == $OVERHEAD, "empty plaintext yields exactly $OVERHEAD bytes" );
my $empty_pt = $c->decrypt( $empty_ct );
ok( defined $empty_pt && $empty_pt eq '', 'empty plaintext decrypts to defined empty string' );

print "# -- wrong key\n";

my $c2 = Data::Tools::Crypto::Symmetric->new( $KEY2 );
ok( ! defined $c2->decrypt( $ct ), 'ciphertext from another key rejected' );

print "# -- undef arguments\n";

ok( boomed( sub { $c->encrypt( undef ) }, 'plaintext not defined'  ), 'encrypt( undef ) booms' );
ok( boomed( sub { $c->decrypt( undef ) }, 'cryptotext not defined' ), 'decrypt( undef ) booms' );

print "# -- reinit\n";

my $c3 = Data::Tools::Crypto::Symmetric->new( $KEY );
my $before = $c3->encrypt( 'payload' );
$c3->reinit( $KEY2 );
ok( ! defined $c3->decrypt( $before ),        'reinit with new key invalidates old ciphertext' );
ok( $c2->decrypt( $c3->encrypt( 'payload' ) ) eq 'payload', 'reinit key matches independent object' );
ok( boomed( sub { $c3->reinit( 'too short' ) }, 'key size' ), 'reinit validates key too' );

# reinit clears all state first, a rejected reinit leaves the object without a
# key by design, until a later reinit succeeds
my $c4    = Data::Tools::Crypto::Symmetric->new( $KEY );
my $c4_ct = $c4->encrypt( 'old key' );
for my $t ( [ sub { $c4->reinit( 'bad key' ) },          'bad key'        ],
            [ sub { $c4->reinit( $KEY2, NONSENSE => 1 ) }, 'unknown option' ] )
  {
  my ( $code, $desc ) = @$t;

  $c4->reinit( $KEY );
  eval { $code->() };
  my $back = eval { $c4->decrypt( $c4_ct ) };
  ok( ! defined $back, "reinit refused for $desc clears the previous key" );
  }

$c4->reinit( $KEY );
ok( $c4->decrypt( $c4_ct ) eq 'old key', 'successful reinit after a failed one restores a working object' );

# every operation on an object whose reinit failed must boom, not crash inside
# the crypto layer and not return undef, which would look like bad data
eval { $c4->reinit( 'bad key' ) };
ok( boomed( sub { $c4->encrypt( 'x' )    }, 'object state is undefined' ), 'encrypt on a failed reinit object booms' );
ok( boomed( sub { $c4->decrypt( $c4_ct ) }, 'object state is undefined' ), 'decrypt on a failed reinit object booms' );
ok( boomed( sub { $c4->thaw_hex( 'aa' )  }, 'object state is undefined' ), 'inherited base API on a failed reinit object booms' );

print "# -- freeze/thaw (inherited Data::Tools::Crypto API)\n";

my $struct = {
             name => 'test',
             list => [ 1, 2, 3 ],
             nest => { deep => { deeper => 'value' } },
             utf8 => "\x{263a} \x{4e2d}\x{6587} \x{1f600}",
             };

for my $enc ( '', '_hex', '_base64', '_base64url' )
  {
  my $freeze = "freeze$enc";
  my $thaw   = "thaw$enc";

  next unless ok( $c->can( $freeze ) && $c->can( $thaw ), "base class provides $freeze/$thaw" );

  my $frozen = eval { $c->$freeze( $struct ) };
  if( $@ )
    {
    ok( 0, "$freeze() failed: " . ( split /\n/, $@ )[ 0 ] );
    next;
    }

  my $thawed = eval { $c->$thaw( $frozen ) };
  if( $@ )
    {
    ok( 0, "$thaw() failed: " . ( split /\n/, $@ )[ 0 ] );
    next;
    }

  ok( $thawed->{ 'name' } eq 'test'
      && $thawed->{ 'list' }[ 2 ] == 3
      && $thawed->{ 'nest' }{ 'deep' }{ 'deeper' } eq 'value'
      && $thawed->{ 'utf8' } eq $struct->{ 'utf8' },
      "$freeze/$thaw roundtrip" );
  }

# encoded forms must be safe to carry as text
my $hex = $c->freeze_hex( $struct );
ok( $hex =~ /^[0-9a-f]+$/,  'freeze_hex output is hex only'            );
my $b64u = $c->freeze_base64url( $struct );
ok( $b64u =~ /^[A-Za-z0-9_-]+$/, 'freeze_base64url output is url-safe' );
my $b64 = $c->freeze_base64( $struct );
ok( $b64 !~ /\n/, 'freeze_base64 output has no newlines' );

# data which does not decrypt must make thaw return undef like decrypt does,
# not die inside decode_json()
for my $enc ( '', '_hex', '_base64', '_base64url' )
  {
  my $freeze = "freeze$enc";
  my $thaw   = "thaw$enc";

  my $frozen = $c->$freeze( $struct );
  my $res    = eval { $c2->$thaw( $frozen ) };
  ok( ! $@ && ! defined $res, "$thaw() with the wrong key returns undef, does not die" );
  }

for my $junk ( [ '', 'x' x 200 ], [ '_hex', 'zz' ], [ '_base64', '!!!!' ], [ '_base64url', 'AAAA' ] )
  {
  my ( $enc, $data ) = @$junk;
  my $thaw = "thaw$enc";

  my $res = eval { $c->$thaw( $data ) };
  ok( ! $@ && ! defined $res, "$thaw() on garbage returns undef, does not die" );
  }

print "# -- encoded encrypt/decrypt (inherited Data::Tools::Crypto API)\n";

# the encoded forms must be exactly as transparent as the raw ones, and must
# report data which does not decrypt with undef, not an exception
my $enc_chars = "caf\x{e9} \x{263a}";
my $enc_bytes = "\x00\xff\x80 binary";

my %enc_charset = (
                  '_hex'       => qr/^[0-9a-f]+$/,
                  '_base64'    => qr/^[A-Za-z0-9+\/=]+$/,
                  '_base64url' => qr/^[A-Za-z0-9_-]+$/,
                  );

for my $enc ( '_hex', '_base64', '_base64url' )
  {
  my $encrypt = "encrypt$enc";
  my $decrypt = "decrypt$enc";

  for my $t ( [ $enc_chars, 'character string' ], [ $enc_bytes, 'byte string' ] )
    {
    my ( $ptext, $desc ) = @$t;

    my $ctext = $c->$encrypt( $ptext );
    ok( defined $ctext && $ctext =~ $enc_charset{ $enc }, "$encrypt output charset: $desc" );

    my $back = $c->$decrypt( $ctext );
    ok( defined $back && $back eq $ptext && utf8::is_utf8( $back ) == utf8::is_utf8( $ptext ),
        "$encrypt/$decrypt roundtrip keeps value and form: $desc" );
    }

  my $res = eval { $c2->$decrypt( $c->$encrypt( 'x' ) ) };
  ok( ! $@ && ! defined $res, "$decrypt with the wrong key returns undef, does not die" );
  }

print "# -- freeze/thaw of top-level scalars and arrays\n";

# freeze() documents plain scalars, numbers and arrays as well as hashes
for my $t ( [ 'plain string', 'string' ], [ 42, 'number' ], [ "\x{263a}", 'wide character string' ] )
  {
  my ( $val, $desc ) = @$t;

  my $back = eval { $c->thaw( $c->freeze( $val ) ) };
  ok( ! $@ && defined $back && $back eq $val, "freeze/thaw top-level $desc" );
  }

my $arr = eval { $c->thaw( $c->freeze( [ 1, 'two', [ 3 ] ] ) ) };
ok( ! $@ && ref( $arr ) eq 'ARRAY' && $arr->[ 1 ] eq 'two' && $arr->[ 2 ][ 0 ] == 3,
    'freeze/thaw top-level array' );

##############################################################################

print '# ' . '-' x 68 . "\n";
printf "# %d tests, %d failed\n", $TESTS, $FAILS;
print $FAILS ? "# RESULT: FAIL\n" : "# RESULT: PASS\n";

##############################################################################
#
#  speed stats -- timings only, no assertions
#
##############################################################################

print '# ' . '-' x 68 . "\n";
print "# speed stats\n";
print '# ' . '-' x 68 . "\n";

printf "# %-8s %-8s %13s %13s %11s %11s\n", 'size', 'type', 'enc calls/s', 'dec calls/s', 'enc MB/s', 'dec MB/s';

my @sizes = (
            [    1024, '1K'   , 5000 ],
            [  512000, '500K' ,  100 ],
            [ 1048576, '1M'   ,   50 ],
            );

for my $s ( @sizes )
  {
  my ( $size, $label, $count ) = @$s;

  # binary payload of exactly $size bytes, and a utf8 payload whose encoded
  # length is about $size bytes (3 bytes per BMP character)
  my $bin = random_bytes( $size );
  my $utf = "\x{263a}" x int( $size / 3 );

  for my $t ( [ $bin, 'binary' ], [ $utf, 'utf8' ] )
    {
    my ( $ptext, $type ) = @$t;

    my $bytes = utf8::is_utf8( $ptext ) ? length( encode( 'UTF-8', $ptext ) ) : length( $ptext );

    my $ctext;
    my $t0 = time();
    $ctext = $c->encrypt( $ptext ) for 1 .. $count;
    my $enc_time = time() - $t0;

    my $back;
    $t0 = time();
    $back = $c->decrypt( $ctext ) for 1 .. $count;
    my $dec_time = time() - $t0;

    printf "# %-8s %-8s %13s %13s %11.2f %11.2f\n",
           $label,
           $type,
           str_num_comma( int( $count / $enc_time ) ),
           str_num_comma( int( $count / $dec_time ) ),
           ( $count * $bytes ) / $enc_time / ( 1024 * 1024 ),
           ( $count * $bytes ) / $dec_time / ( 1024 * 1024 );
    }
  }

print '# ' . '-' x 68 . "\n";

# trailing plan, the count is only known once every test has run
print "1..$TESTS\n";

exit( $FAILS ? 1 : 0 );

##############################################################################
