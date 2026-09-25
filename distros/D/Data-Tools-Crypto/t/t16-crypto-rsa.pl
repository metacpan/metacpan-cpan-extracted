#!/usr/bin/perl
use strict;
use lib '.', '../lib';
use Data::Tools;
use Data::Tools::Crypto::RSA;
use Crypt::PK::RSA;
use Crypt::PRNG qw( random_bytes );
use Encode qw( encode_utf8 );
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

sub make_key
{
  my $bits = shift || 2048;

  my $pk = Crypt::PK::RSA->new;
  $pk->generate_key( $bits / 8, 65537 );

  return $pk;
}

##############################################################################

# the symmetric layer under the wrapped key costs nonce + tag + flag
my $SYM_OVERHEAD = 12 + 16 + 1;

my $pk      = make_key( 2048 );
my $MODULUS = $pk->size();                        # 256 bytes for a 2048-bit key
my $PRIV    = $pk->export_key_pem( 'private' );   # PEM text, not a ref
my $PUB     = $pk->export_key_pem( 'public'  );
my $OVERHEAD = $MODULUS + $SYM_OVERHEAD;

print "# -- construction and key validation\n";

my $c = Data::Tools::Crypto::RSA->new( $PRIV );
ok( ref( $c ) eq 'Data::Tools::Crypto::RSA', 'new() returns object' );
ok( $c->isa( 'Data::Tools::Crypto' ),  'inherits Data::Tools::Crypto' );

ok( boomed( sub { Data::Tools::Crypto::RSA->new( undef ) }, 'not defined' ), 'undef key rejected' );

# a key perl holds as characters cannot be fed to the crypto layer as bytes.
# note that PEM data is normally passed as a scalar REF, so the guard has to
# look through the ref -- utf8::is_utf8() on a reference is always false
my $wide_key = "-----BEGIN RSA PRIVATE KEY-----\x{263a}";
ok( boomed( sub { Data::Tools::Crypto::RSA->new( $wide_key ) }, 'UTF-8' ),
    'wide-char key rejected' );

# a utf8-flagged but downgradeable key is ordinary byte data and must work
my $up_key = $PRIV; utf8::upgrade( $up_key );
my $up_obj = eval { Data::Tools::Crypto::RSA->new( $up_key ) };
ok( ! $@ && $up_obj && $up_obj->decrypt( $up_obj->encrypt( 'x' ) ) eq 'x',
    'downgradeable utf8 key accepted and usable' );

# malformed key material is a caller error and must boom like the others, not
# die with a raw croak from the crypto layer
ok( boomed( sub { Data::Tools::Crypto::RSA->new( 'not a key at all' ) }, 'invalid or unsupported RSA key' ),
    'garbage key material refused' );
ok( boomed( sub { Data::Tools::Crypto::RSA->new( "-----BEGIN RSA PRIVATE KEY-----\nAAAA\n-----END RSA PRIVATE KEY-----\n" ) },
            'invalid or unsupported RSA key' ),
    'truncated PEM refused' );

# the key is PEM text; a reference must be refused with a clear message rather
# than confusing the crypto layer, and a file name is the caller's business
ok( boomed( sub { Data::Tools::Crypto::RSA->new( \$PRIV ) }, 'not a .*reference' ),
    'scalar ref to PEM rejected, text expected' );
ok( boomed( sub { Data::Tools::Crypto::RSA->new( { } ) }, 'not a .*reference' ),
    'hash ref rejected' );

print "# -- key forms accepted\n";

ok( defined eval { Data::Tools::Crypto::RSA->new( $PRIV ) }, 'private key PEM text accepted' );
ok( defined eval { Data::Tools::Crypto::RSA->new( $PUB  ) }, 'public key PEM text accepted'  );

# PEM text must never be mistaken for a file name, which is what happens when
# it is handed to Crypt::PK::RSA unwrapped
ok( defined eval { Data::Tools::Crypto::RSA->new( $PRIV ) }, 'multi-line PEM text not taken as a file name' );

print "# -- wire format\n";

my $ct = $c->encrypt( 'hello' );
ok( length( $ct ) == length( 'hello' ) + $OVERHEAD,
    "ciphertext is modulus + $SYM_OVERHEAD + payload ($OVERHEAD + n)" );
ok( length( $c->encrypt( '' ) ) == $OVERHEAD, "empty plaintext yields exactly $OVERHEAD bytes" );

# the wrapped key must differ every time, a reused symmetric key would be fatal
my %wrapped;
$wrapped{ substr( $c->encrypt( 'same plaintext' ), 0, $MODULUS ) }++ for 1 .. 200;
ok( scalar( keys %wrapped ) == 200, '200 messages produce 200 distinct wrapped keys' );

my %payloads;
$payloads{ $c->encrypt( 'same plaintext' ) }++ for 1 .. 200;
ok( scalar( keys %payloads ) == 200, 'same plaintext never yields same ciphertext' );

# distinct wrapped bytes prove nothing on their own, RSA-OAEP is randomised and
# would produce different output even for a constant key. unwrap them and check
# the symmetric keys themselves, reuse across messages would be catastrophic
my %skeys;
for ( 1 .. 100 )
  {
  my $w = substr( $c->encrypt( 'same plaintext' ), 0, $MODULUS );
  $skeys{ $pk->decrypt( $w, 'oaep', 'SHA256' ) }++;
  }
ok( scalar( keys %skeys ) == 100, '100 messages use 100 distinct symmetric keys' );
ok( ! grep( { length( $_ ) != 32 } keys %skeys ), 'every wrapped symmetric key is 32 bytes' );

##############################################################################
#
#  plaintext variations
#
#  RSA alone can only carry keysize-2*hashsize-2 bytes (190 on a 2048-bit key
#  with SHA256). hybrid encryption must lift that entirely, and must inherit
#  the utf8 transparency of Crypto::Symmetric underneath.
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

  unless( ok( defined $ctext, "encrypt returned data: $desc" ) )
    {
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

  my $bytes = utf8::is_utf8( $ptext ) ? length( encode_utf8( $ptext ) ) : length( $ptext );
  ok( length( $ctext ) == $bytes + $OVERHEAD,            "ciphertext overhead: $desc" );
}

print "# -- plaintext sizes RSA alone could never carry\n";

for my $n ( 0, 1, 189, 190, 191, 1000, 100_000 )
  {
  check_roundtrip( 'x' x $n, "$n bytes" );
  }

print "# -- plaintext variations: non-utf8 (byte strings)\n";

my $all_bytes = join '', map { chr } 0 .. 255;

my @binary = (
             [ "\x00"                   , 'single NUL byte'              ],
             [ "\x00\xff\x80\x00binary" , 'mixed binary with NULs'       ],
             [ $all_bytes               , 'all 256 byte values'          ],
             [ "caf\xc3\xa9"            , 'bytes that are valid utf8'    ],
             [ "\xff\xfe"               , 'bytes that are invalid utf8'  ],
             [ "\xed\xa0\x80"           , 'bytes encoding a surrogate'   ],
             [ random_bytes( 10000 )    , '10k random binary'            ],
             );

for my $t ( @binary )
  {
  my ( $ptext, $desc ) = @$t;
  ok( ! utf8::is_utf8( $ptext ), "test input is unflagged: $desc" );
  check_roundtrip( $ptext, $desc );
  }

print "# -- plaintext variations: utf8 (character strings)\n";

my $upgraded_ascii = 'plain ascii'; utf8::upgrade( $upgraded_ascii );
my $upgraded_latin = "caf\x{e9}";   utf8::upgrade( $upgraded_latin );

my @chars = (
            [ $upgraded_ascii            , 'flagged ascii only'      ],
            [ $upgraded_latin            , 'latin1 range characters' ],
            [ "\x{263a}"                 , 'BMP symbol'              ],
            [ "\x{4e2d}\x{6587}\x{5b57}" , 'CJK'                     ],
            [ "\x{0410}\x{0431}"         , 'cyrillic'                ],
            [ "\x{1f600}\x{1f4a9}"       , 'astral plane (emoji)'    ],
            [ "e\x{0301}a\x{030a}"       , 'combining marks'         ],
            [ "a\x{263a}b\x{1f600}c"     , 'mixed ascii and wide'    ],
            [ "\x{263a}" x 5000          , '5k wide characters'      ],
            );

for my $t ( @chars )
  {
  my ( $ptext, $desc ) = @$t;
  ok( utf8::is_utf8( $ptext ), "test input is flagged: $desc" );
  check_roundtrip( $ptext, $desc );
  }

print "# -- malformed / boundary codepoints\n";

# perl can hold these but strict UTF-8 cannot represent them. as with
# Crypto::Symmetric they must survive unchanged, never be silently replaced
for my $t ( [ "\x{d800}"  , 'lone high surrogate'   ],
            [ "\x{ffff}"  , 'noncharacter U+FFFF'   ],
            [ "\x{10ffff}", 'noncharacter U+10FFFF' ],
            [ "\x{110000}", 'beyond unicode range'  ] )
  {
  my ( $ptext, $desc ) = @$t;

  my $ctext = eval { $c->encrypt( $ptext ) };

  if( $@ )
    {
    ok( boomed( sub { $c->encrypt( $ptext ) } ), "$desc: refused explicitly" );
    next;
    }

  my $back = $c->decrypt( $ctext );
  ok( defined $back && $back eq $ptext, "$desc: carried through unchanged" )
    or printf "#      U+%04X came back as U+%04X\n", ord( $ptext ), defined $back && length $back ? ord( $back ) : 0;
  }

print "# -- byte form and character form stay distinct\n";

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

my $flagged_ct = $c->encrypt( 'payload' );
utf8::upgrade( $flagged_ct );
ok( boomed( sub { $c->decrypt( $flagged_ct ) }, 'utf8' ), 'utf8-flagged cryptotext rejected' );

print "# -- authentication\n";

my $auth_ct = $c->encrypt( 'secret message' );

# the wrapped key, the symmetric nonce, the payload and the tag must all be
# covered -- a flip anywhere must fail, never return partial data
my %region = (
             'wrapped key'      => 0,
             'wrapped key end'  => $MODULUS - 1,
             'symmetric nonce'  => $MODULUS + 2,
             'payload'          => $MODULUS + 12 + 16 + 2,
             'tag'              => $MODULUS + 12 + 2,
             );

for my $r ( sort keys %region )
  {
  my $pos = $region{ $r };
  my $bad = $auth_ct;
  substr( $bad, $pos, 1 ) = chr( ord( substr( $bad, $pos, 1 ) ) ^ 1 );

  ok( ! defined $c->decrypt( $bad ), "tampered $r rejected" );
  }

ok( ! defined $c->decrypt( substr( $auth_ct, 0, length( $auth_ct ) - 1 ) ), 'truncated ciphertext rejected' );
ok( ! defined $c->decrypt( $auth_ct . 'x' ),                                'extended ciphertext rejected' );

print "# -- short input\n";

ok( ! defined $c->decrypt( '' ),                        'empty cryptotext rejected'        );
ok( ! defined $c->decrypt( 'x' x $MODULUS ),            'wrapped key only, no payload rejected' );
ok( ! defined $c->decrypt( 'x' x ( $MODULUS - 1 ) ),    'shorter than modulus rejected'    );
ok( ! defined $c->decrypt( 'x' x ( $OVERHEAD - 1 ) ),   'below minimum length rejected'    );

print "# -- wrong key\n";

my $other = Data::Tools::Crypto::RSA->new( make_key( 2048 )->export_key_pem( 'private' ) );
ok( ! defined $other->decrypt( $auth_ct ), 'ciphertext from another keypair rejected' );

print "# -- public and private key roles\n";

my $pubo = Data::Tools::Crypto::RSA->new( $PUB );
my $pub_ct = $pubo->encrypt( 'from the public key' );
ok( defined $pub_ct,                                 'public key can encrypt'  );
ok( $c->decrypt( $pub_ct ) eq 'from the public key', 'private key decrypts it' );

# a public key holds only the modulus and the public exponent, so it can do the
# public operations (encrypt, verify) but not the private ones (decrypt, sign).
# asking it for a private operation is a configuration error, not a data one,
# so it must boom rather than return the undef that means "data did not verify"
ok( boomed( sub { $pubo->decrypt( $pub_ct ) }, 'private key required' ),
    'public-only key booms on decrypt, not undef' );
ok( boomed( sub { $pubo->sign( 'x' ) }, 'private key required' ),
    'public-only key booms on sign, not undef' );

ok( $c->is_private()     == 1, 'is_private() true for a private key'  );
ok( $pubo->is_private()  == 0, 'is_private() false for a public key'  );

# the private key embeds the public part, so it can do all four operations
my $priv_sig = $c->sign( 'both ways' );
ok( defined $c->encrypt( 'both ways' ), 'private key can encrypt'  );
ok( $c->verify( 'both ways', $priv_sig ), 'private key can verify' );
ok( $pubo->verify( 'both ways', $priv_sig ), 'public key can verify' );

# the undef signal stays reserved for data-dependent failure
my $tampered_ct = $c->encrypt( 'x' );
substr( $tampered_ct, 5, 1 ) = chr( ord( substr( $tampered_ct, 5, 1 ) ) ^ 1 );
ok( ! defined $c->decrypt( $tampered_ct ),
    'tampered ciphertext still returns undef, distinct from the config error' );

print "# -- undef arguments\n";

ok( boomed( sub { $c->encrypt( undef ) }, 'plaintext not defined'  ), 'encrypt( undef ) booms' );
ok( boomed( sub { $c->decrypt( undef ) }, 'cryptotext not defined' ), 'decrypt( undef ) booms' );

print "# -- reinit\n";

my $c2     = Data::Tools::Crypto::RSA->new( $PRIV );
my $before = $c2->encrypt( 'payload' );
$c2->reinit( make_key( 2048 )->export_key_pem( 'private' ) );
ok( ! defined $c2->decrypt( $before ), 'reinit with new key invalidates old ciphertext' );
ok( $c2->decrypt( $c2->encrypt( 'payload' ) ) eq 'payload', 'reinit leaves object working' );
ok( boomed( sub { $c2->reinit( undef ) }, 'not defined' ), 'reinit validates key too' );

# reinit clears all state first, a rejected reinit leaves the object without a
# key by design, until a later reinit succeeds
my $c3    = Data::Tools::Crypto::RSA->new( $PRIV );
my $c3_ct = $c3->encrypt( 'old key' );
for my $t ( [ sub { $c3->reinit( undef ) },                'undef key'      ],
            [ sub { $c3->reinit( $PRIV, NONSENSE => 1 ) }, 'unknown option' ],
            [ sub { $c3->reinit( $PRIV, HASH => 'BOGUS' ) }, 'invalid hash' ] )
  {
  my ( $code, $desc ) = @$t;

  $c3->reinit( $PRIV );
  eval { $code->() };
  my $back = eval { $c3->decrypt( $c3_ct ) };
  ok( ! defined $back, "reinit refused for $desc clears the previous key" );
  }

$c3->reinit( $PRIV );
ok( $c3->decrypt( $c3_ct ) eq 'old key', 'successful reinit after a failed one restores a working object' );

# every operation on an object whose reinit failed must boom, not crash inside
# the crypto layer and not return undef/false, which would look like bad data
my $c3_sig = $c3->sign( 'signed' );
eval { $c3->reinit( undef ) };
my %c3_ops = (
             'encrypt'    => sub { $c3->encrypt( 'x' )                },
             'decrypt'    => sub { $c3->decrypt( $c3_ct )             },
             'sign'       => sub { $c3->sign( 'x' )                   },
             'verify'     => sub { $c3->verify( 'signed', $c3_sig )   },
             'is_private' => sub { $c3->is_private()                  },
             'freeze'     => sub { $c3->freeze( { a => 1 } )          },
             );
for my $op ( sort keys %c3_ops )
  {
  ok( boomed( $c3_ops{ $op }, 'object state is undefined' ), "$op on a failed reinit object booms" );
  }

print "# -- other key sizes\n";

for my $bits ( 1024, 4096 )
  {
  my $k  = make_key( $bits );
  my $o  = Data::Tools::Crypto::RSA->new( $k->export_key_pem( 'private' ) );
  my $p  = 'payload ' x 500;   # far beyond what RSA alone could carry
  my $r  = eval { $o->decrypt( $o->encrypt( $p ) ) };

  ok( ! $@ && defined $r && $r eq $p, "$bits-bit key roundtrips a 4k payload" );
  ok( length( $o->encrypt( 'x' ) ) == $k->size() + $SYM_OVERHEAD + 1,
      "$bits-bit key overhead is modulus (" . $k->size() . ") + $SYM_OVERHEAD" );
  }

print "# -- keys too small to wrap the symmetric key\n";

# OAEP carries k-2*hashsize-2 bytes and must fit the 32 byte symmetric key, so
# with SHA256 the modulus must be at least 32+64+2 = 98 bytes (784 bits).
# an undersized key must be refused at reinit, never fail silently at encrypt
my $SKEY_LEN = 32;   # symmetric key size used by the module
my $NEED     = $SKEY_LEN + 2 * 32 + 2;

for my $bits ( 512, 768, 784, 1024 )
  {
  my $small = eval { my $p = Crypt::PK::RSA->new; $p->generate_key( $bits / 8, 65537 ); $p };
  next unless $small;

  my $pem = $small->export_key_pem( 'private' );

  if( $bits / 8 >= $NEED )
    {
    my $o = eval { Data::Tools::Crypto::RSA->new( $pem ) };
    ok( ! $@ && $o && defined $o->encrypt( 'x' ), "$bits-bit key (k=" . ( $bits / 8 ) . ") accepted and usable" );
    }
  else
    {
    ok( boomed( sub { Data::Tools::Crypto::RSA->new( $pem ) }, 'too small' ),
        "$bits-bit key (k=" . ( $bits / 8 ) . ") refused at reinit, needs $NEED" );
    }
  }

print "# -- options are honoured or refused, never ignored\n";

ok( boomed( sub { Data::Tools::Crypto::RSA->new( $PRIV, NONSENSE => 1 ) }, 'unknown option' ),
    'unknown option refused' );
ok( boomed( sub { Data::Tools::Crypto::RSA->new( $PRIV, PADDING => 'pkcs1' ) }, 'unknown option' ),
    'unsupported PADDING option refused rather than ignored' );
ok( boomed( sub { Data::Tools::Crypto::RSA->new( $PRIV, HASH => 'BOGUS' ) }, 'invalid or unknown hash' ),
    'invalid HASH refused' );

for my $h ( qw( SHA1 SHA256 SHA512 ) )
  {
  my $o = eval { Data::Tools::Crypto::RSA->new( $PRIV, HASH => $h ) };
  my $r = $@ ? undef : eval { $o->decrypt( $o->encrypt( "payload $h" ) ) };
  ok( defined $r && $r eq "payload $h", "HASH => $h is actually used and roundtrips" );
  }

# a ciphertext wrapped under one hash must not be readable under another
my $h256 = Data::Tools::Crypto::RSA->new( $PRIV, HASH => 'SHA256' );
my $h512 = Data::Tools::Crypto::RSA->new( $PRIV, HASH => 'SHA512' );
ok( ! defined $h512->decrypt( $h256->encrypt( 'x' ) ), 'ciphertext is specific to the configured hash' );

print "# -- sign / verify\n";

my $signer   = Data::Tools::Crypto::RSA->new( $PRIV );
my $verifier = Data::Tools::Crypto::RSA->new( $PUB  );

my $msg = 'a signed message';
my $sig = $signer->sign( $msg );

ok( defined $sig && length( $sig ) == $MODULUS, 'sign() returns a signature of modulus size' );
ok( $verifier->verify( $msg, $sig ),            'public key verifies the signature'         );
ok( ! $verifier->verify( $msg . 'x', $sig ),    'altered message fails verification'        );

my $bad_sig = $sig;
substr( $bad_sig, 10, 1 ) = chr( ord( substr( $bad_sig, 10, 1 ) ) ^ 1 );
ok( ! $verifier->verify( $msg, $bad_sig ),   'altered signature fails verification'   );
ok( ! $verifier->verify( $msg, 'garbage' ),  'garbage signature fails, does not croak' );

# a signature from another keypair must not verify
my $stranger = Data::Tools::Crypto::RSA->new( make_key( 2048 )->export_key_pem( 'private' ) );
ok( ! $verifier->verify( $msg, $stranger->sign( $msg ) ), 'signature from another keypair fails' );

ok( boomed( sub { $verifier->sign( $msg ) }, 'private key required' ),
    'public-only key booms on sign' );

ok( boomed( sub { $signer->sign( undef ) },        'plaintext not defined' ), 'sign( undef ) booms'        );
ok( boomed( sub { $signer->verify( undef, $sig ) },'plaintext not defined' ), 'verify( undef, sig ) booms' );
ok( boomed( sub { $signer->verify( $msg, undef ) },'signature not defined' ), 'verify( msg, undef ) booms' );

my $u_sig = $sig; utf8::upgrade( $u_sig );
ok( boomed( sub { $signer->verify( $msg, $u_sig ) }, 'utf8' ), 'utf8-flagged signature rejected' );

# signing covers the utf8 marker too, so a character string and its byte form
# must not share a signature
my $w_chars = "sm\x{263a}ile";
my $w_bytes = "sm\xe2\x98\xbaile";
my $w_sig   = $signer->sign( $w_chars );
ok( $verifier->verify( $w_chars, $w_sig ),   'wide-char message signs and verifies'          );
ok( ! $verifier->verify( $w_bytes, $w_sig ), 'byte form does not share the char form signature' );

# signing and encryption are independent
ok( $signer->decrypt( $signer->encrypt( 'x' ) ) eq 'x', 'encrypt/decrypt unaffected by signing' );

print "# -- freeze/thaw (inherited Data::Tools::Crypto API)\n";

# a structure far larger than RSA alone could ever encrypt
my $struct = {
             name => 'test',
             list => [ 1, 2, 3 ],
             nest => { deep => { deeper => 'value' } },
             utf8 => "\x{263a} \x{4e2d}\x{6587} \x{1f600}",
             bulk => { map { $_ => "value $_ " . ( 'x' x 100 ) } 1 .. 500 },
             };

for my $enc ( '', '_hex', '_base64', '_base64url' )
  {
  my $freeze = "freeze$enc";
  my $thaw   = "thaw$enc";

  next unless ok( $c->can( $freeze ) && $c->can( $thaw ), "base class provides $freeze/$thaw" );

  my $frozen = eval { $c->$freeze( $struct ) };
  if( $@ or ! defined $frozen )
    {
    ok( 0, "$freeze() failed: " . ( $@ ? ( split /\n/, $@ )[ 0 ] : 'returned undef' ) );
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
      && $thawed->{ 'utf8' } eq $struct->{ 'utf8' }
      && $thawed->{ 'bulk' }{ 500 } eq $struct->{ 'bulk' }{ 500 },
      "$freeze/$thaw roundtrip on a 500-key structure" );
  }

my $hex = $c->freeze_hex( $struct );
ok( $hex =~ /^[0-9a-f]+$/,       'freeze_hex output is hex only'        );
my $b64u = $c->freeze_base64url( $struct );
ok( $b64u =~ /^[A-Za-z0-9_-]+$/, 'freeze_base64url output is url-safe'  );
my $b64 = $c->freeze_base64( $struct );
ok( $b64 !~ /\n/,                'freeze_base64 output has no newlines' );

# data which does not decrypt must make thaw return undef like decrypt does,
# not die inside decode_json()
for my $enc ( '', '_hex', '_base64', '_base64url' )
  {
  my $freeze = "freeze$enc";
  my $thaw   = "thaw$enc";

  my $frozen = $c->$freeze( $struct );
  my $res    = eval { $other->$thaw( $frozen ) };
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

  my $res = eval { $other->$decrypt( $c->$encrypt( 'x' ) ) };
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

print "# -- public key through the base API\n";

# freeze and the encoded encrypts work with a public key, thaw and the encoded
# decrypts are private operations and must boom like decrypt() does
my $pub_sealed = $pubo->freeze( $struct );
ok( $c->thaw( $pub_sealed )->{ 'name' } eq 'test', 'public key freeze, private key thaw' );
ok( boomed( sub { $pubo->thaw( $pub_sealed ) }, 'private key required' ),
    'thaw on a public key booms, not undef' );
ok( boomed( sub { $pubo->decrypt_base64url( $pubo->encrypt_base64url( 'x' ) ) }, 'private key required' ),
    'decrypt_base64url on a public key booms, not undef' );

print "# -- public key in X.509 SubjectPublicKeyInfo form\n";

# "BEGIN PUBLIC KEY" is what openssl writes by default, not "BEGIN RSA PUBLIC KEY"
my $x509 = $pk->export_key_pem( 'public_x509' );
my $xo   = eval { Data::Tools::Crypto::RSA->new( $x509 ) };
ok( ! $@ && $xo && ! $xo->is_private(),                   'X.509 public key PEM accepted as public' );
ok( $xo && $c->decrypt( $xo->encrypt( 'x509' ) ) eq 'x509', 'X.509 public key encrypts for the private key' );
ok( $xo && $xo->verify( 'x509 sig', $c->sign( 'x509 sig' ) ), 'X.509 public key verifies signatures' );

print "# -- HASH applies to signatures and to the key size check\n";

for my $h ( qw( SHA1 SHA512 ) )
  {
  my $hs = Data::Tools::Crypto::RSA->new( $PRIV, HASH => $h );
  my $hv = Data::Tools::Crypto::RSA->new( $PUB,  HASH => $h );
  ok( $hv->verify( 'hashed', $hs->sign( 'hashed' ) ), "HASH => $h sign/verify" );
  }

ok( ! Data::Tools::Crypto::RSA->new( $PUB, HASH => 'SHA512' )->verify( 'hashed', $c->sign( 'hashed' ) ),
    'signature is specific to the configured hash' );

# with SHA512 OAEP needs 32+2*64+2 = 162 bytes of modulus, more than 1024 bits
my $k1024 = make_key( 1024 )->export_key_pem( 'private' );
ok( boomed( sub { Data::Tools::Crypto::RSA->new( $k1024, HASH => 'SHA512' ) }, 'too small' ),
    '1024-bit key refused for SHA512, needs 162 bytes' );
ok( ! boomed( sub { Data::Tools::Crypto::RSA->new( $k1024, HASH => 'SHA256' ) } ),
    'same 1024-bit key accepted for SHA256' );

print "# -- encoded signatures\n";

my %sig_charset = (
                  '_hex'       => qr/^[0-9a-f]+$/,
                  '_base64'    => qr/^[A-Za-z0-9+\/=]+$/,
                  '_base64url' => qr/^[A-Za-z0-9_-]+$/,
                  );

for my $enc ( '_hex', '_base64', '_base64url' )
  {
  my $sign   = "sign$enc";
  my $verify = "verify$enc";

  next unless ok( $signer->can( $sign ) && $signer->can( $verify ), "RSA provides $sign/$verify" );

  my $esig = $signer->$sign( $msg );
  ok( defined $esig && $esig =~ $sig_charset{ $enc },   "$sign output charset"                       );
  ok( $verifier->$verify( $msg, $esig ),                "$verify accepts the $sign signature"        );
  ok( ! $verifier->$verify( $msg . 'x', $esig ),        "$verify rejects an altered message"         );
  ok( ! $verifier->$verify( $msg, 'AAAA' ),              "$verify on garbage is false, does not die"  );

  my $w_esig = $signer->$sign( $w_chars );
  ok( $verifier->$verify( $w_chars, $w_esig ) && ! $verifier->$verify( $w_bytes, $w_esig ),
      "$sign keeps char and byte forms distinct" );

  ok( boomed( sub { $verifier->$verify( $msg, undef ) }, 'signature not defined' ), "$verify( msg, undef ) booms" );
  ok( boomed( sub { $verifier->$sign( $msg ) },          'private key required'  ), "$sign on a public key booms"  );
  }

# an encoded signature often arrives as a character string, i.e. from JSON,
# and must still verify since the encoding itself is plain ascii
my $u_hex = $signer->sign_hex( $msg ); utf8::upgrade( $u_hex );
ok( $verifier->verify_hex( $msg, $u_hex ), 'utf8-flagged hex signature verifies' );

# the encodings carry the same signature as sign()
ok( $verifier->verify( $msg, pack( 'H*', $signer->sign_hex( $msg ) ) ), 'decoded sign_hex output verifies with verify()' );

print "# -- sign / verify edge messages\n";

my $big_msg = random_bytes( 100_000 );
ok( $verifier->verify( '', $signer->sign( '' ) ),           'empty message signs and verifies' );
ok( $verifier->verify( $big_msg, $signer->sign( $big_msg ) ), '100k binary message signs and verifies' );

##############################################################################

print '# ' . '-' x 68 . "\n";
printf "# %d tests, %d failed\n", $TESTS, $FAILS;
print $FAILS ? "# RESULT: FAIL\n" : "# RESULT: PASS\n";

##############################################################################
#
#  speed stats -- timings only, no assertions
#
#  each call costs one RSA operation plus the symmetric pass. the RSA part is
#  a fixed cost per message, so it dominates at small sizes; note that a
#  private-key operation (decrypt) is far more expensive than a public one
#
##############################################################################

print '# ' . '-' x 68 . "\n";
print "# speed stats\n";
print '# ' . '-' x 68 . "\n";

printf "# %-8s %-8s %13s %13s %11s %11s\n", 'size', 'type', 'enc calls/s', 'dec calls/s', 'enc MB/s', 'dec MB/s';

my @sizes = (
            [    1024, '1K'   , 300 ],
            [  512000, '500K' ,  50 ],
            [ 1048576, '1M'   ,  25 ],
            );

for my $s ( @sizes )
  {
  my ( $size, $label, $count ) = @$s;

  my $bin = random_bytes( $size );
  my $utf = "\x{263a}" x int( $size / 3 );

  for my $t ( [ $bin, 'binary' ], [ $utf, 'utf8' ] )
    {
    my ( $ptext, $type ) = @$t;

    my $bytes = utf8::is_utf8( $ptext ) ? length( encode_utf8( $ptext ) ) : length( $ptext );

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
