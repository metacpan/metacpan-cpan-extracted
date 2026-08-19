use v5.36;

package Protocol::HAP::SRP;
our $VERSION = '0.1.0';

# Prefer the GMP backend. The 3072-bit modular exponentiation of
# SRP is impractically slow in the pure-Perl Calc backend. It
# takes seconds per operation, and far more under emulation.
# 'try' falls back to Calc silently when Math::BigInt::GMP is
# not installed. Thus the module stays correct everywhere.
use Math::BigInt try => 'GMP';
use Digest::SHA qw(sha512);
use Protocol::HAP::Crypto;
use Protocol::HAP::SetupCode qw(normalize_setup_code);

# SRP-6a implementation for HAP
# The module uses the 3072-bit group from RFC 5054.

# The group is HAP policy, not a primitive. HAP-Pairing names this
# group and no other, so the constants live with the protocol that
# chose them and not with the cryptography that computes over them.
our $N_3072 = pack( 'H*',
	      'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
	    . '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
	    . 'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
	    . 'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
	    . 'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D'
	    . 'C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F'
	    . '83655D23DCA3AD961C62F356208552BB9ED529077096966D'
	    . '670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
	    . 'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9'
	    . 'DE2BCBF6955817183995497CEA956AE515D2261898FA0510'
	    . '15728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64'
	    . 'ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7'
	    . 'ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6B'
	    . 'F12FFA06D98A0864D87602733EC86A64521F2B18177B200C'
	    . 'BBE117577A615D6C770988C0BAD946E208E24FA074E5AB31'
	    . '43DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF' );
our $g = 5;

# N_len: Length of N in bytes (3072 bits / 8 = 384 bytes)
use constant N_LEN => 384;

# _bigint_to_bytes($bigint, $length = undef) - Convert BigInt to bytes
# The function removes the '0x' prefix from as_hex(). It pads
# the bytes to a fixed length if the caller gives $length.
sub _bigint_to_bytes ( $bigint, $length = undef )
{
	my $hex = $bigint->as_hex();
	$hex =~ s/^0x//;    # Remove the 0x prefix

	# Make the number of hex digits even
	$hex = '0' . $hex if length($hex) % 2;

	my $bytes = pack( 'H*', $hex );

	# Pad with zeros on the left if the caller gives a length
	if ( defined $length && length($bytes) < $length ) {
		$bytes = ( "\x00" x ( $length - length($bytes) ) ) . $bytes;
	}

	return $bytes;
}

sub new ( $class, %args )
{

	my $self = bless {
		username => $args{username} // 'Pair-Setup',
		password => normalize_setup_code( $args{password} )
		    // $args{password},

		# The RFC 5054 3072-bit group. The exchange methods fill
		# in the session state as it becomes known.
		N => Math::BigInt->from_hex(
			unpack( 'H*', $Protocol::HAP::SRP::N_3072 )
		),
		g => Math::BigInt->new($Protocol::HAP::SRP::g),
	}, $class;

	return $self;
}

sub generate_salt ($self)
{
	$self->{salt} = Protocol::HAP::Crypto->random_bytes(16);
	return $self->{salt};
}

sub compute_verifier ( $self, $salt = undef )
{
	$salt //= $self->{salt};

	# x = H(salt | H(username | ":" | password))
	my $inner   = sha512( $self->{username} . ':' . $self->{password} );
	my $x_bytes = sha512( $salt . $inner );
	my $x       = Math::BigInt->from_hex( unpack( 'H*', $x_bytes ) );

	# v = g^x mod N
	# bmodpow mutates its invocant. Thus work on a copy of g.
	my $v = $self->{g}->copy->bmodpow( $x, $self->{N} );

	$self->{v} = $v;
	return $v;
}

sub generate_server_public ($self)
{

	# Generate a random b (256 bits)
	my $b_bytes = Protocol::HAP::Crypto->random_bytes(32);
	$self->{b} = Math::BigInt->from_hex( unpack( 'H*', $b_bytes ) );

	# k = H(N | PAD(g))
	# PAD(g) pads g to the same length as N (384 bytes for 3072-bit)
	my $N_bytes  = _bigint_to_bytes( $self->{N} );
	my $N_len    = length($N_bytes);
	my $g_padded = _bigint_to_bytes( $self->{g}, $N_len );
	my $k_bytes  = sha512( $N_bytes . $g_padded );
	my $k        = Math::BigInt->from_hex( unpack( 'H*', $k_bytes ) );

	# B = (k*v + g^b) mod N
	# bmodpow mutates its invocant. Thus work on a copy of g.
	my $B =
	    ( $k * $self->{v} +
		    $self->{g}->copy->bmodpow( $self->{b}, $self->{N} ) )
	    % $self->{N};

	$self->{B} = $B;
	return $B;
}

# $self->server_public_bytes():
#	Return B as it goes on the wire: N_LEN bytes, zero-padded on
#	the left.
#
#	About one B in 256 is small enough that its natural encoding
#	is 383 bytes. A caller that packs the number itself sends a
#	short public key, and the controller computes u over different
#	bytes than the accessory does. The pairing then fails at M4,
#	for one attempt in 256, with no diagnosis. Thus the padding
#	belongs here, beside N_LEN, and not at the call site.
sub server_public_bytes ($self)
{
	return unless defined $self->{B};

	return _bigint_to_bytes( $self->{B}, N_LEN );
}

sub compute_session_key ( $self, $A_bytes )
{
	my $A = Math::BigInt->from_hex( unpack( 'H*', $A_bytes ) );

	# Security: make sure that A mod N != 0. This is an SRP-6a
	# requirement per HAP-Pairing.md §2.6. A malicious
	# controller can send A = 0, N, or 2N to make the shared
	# secret predictable and thus bypass authentication.
	return if ( $A % $self->{N} )->is_zero();

	$self->{A} = $A;

	# u = H(PAD(A) | PAD(B))
	# Pad both A and B to N_LEN per HAP-Pairing.md §2.6 and the
	# SRP-6a spec.
	my $A_padded = _bigint_to_bytes( $self->{A}, N_LEN );
	my $B_padded = _bigint_to_bytes( $self->{B}, N_LEN );
	my $u_bytes  = sha512( $A_padded . $B_padded );
	my $u        = Math::BigInt->from_hex( unpack( 'H*', $u_bytes ) );

	# S = (A * v^u)^b mod N
	# bmodpow mutates its invocant. Thus work on a copy of v.
	# The multiplication result is a fresh object. It is safe
	# to mutate.
	my $S =
	    ( $self->{A} * $self->{v}->copy->bmodpow( $u, $self->{N} ) )
	    ->bmodpow( $self->{b}, $self->{N} );

	$self->{S} = $S;

	# K = H(S)
	my $S_bytes = _bigint_to_bytes($S);
	$self->{K} = sha512($S_bytes);

	return $self->{K};
}

sub verify_client_proof ( $self, $M1_client )
{

	# M1 = H(H(N) XOR H(g) | H(username) | salt | A | B | K)
	# Use the string xor operator. v5.36 enables the 'bitwise'
	# feature. Under that feature, plain ^ is numeric-only.
	my $N_hash = sha512( _bigint_to_bytes( $self->{N} ) );
	my $g_hash = sha512( _bigint_to_bytes( $self->{g} ) );
	my $xor    = $N_hash ^. $g_hash;

	my $user_hash = sha512( $self->{username} );

	# M1 = H(H(N) XOR H(g) | H(I) | s | PAD(A) | PAD(B) | K)
	# Pad A and B to N_LEN per HAP-Pairing.md §2.5.
	my $A_bytes = _bigint_to_bytes( $self->{A}, N_LEN );
	my $B_bytes = _bigint_to_bytes( $self->{B}, N_LEN );

	my $M1 =
	    sha512(   $xor
		    . $user_hash
		    . $self->{salt}
		    . $A_bytes
		    . $B_bytes
		    . $self->{K} );

	$self->{M1} = $M1;

	return $M1 eq $M1_client;
}

sub generate_server_proof ($self)
{

	# M2 = H(PAD(A) | M1 | K)
	# Pad A to N_LEN per HAP-Pairing.md §2.6.
	my $A_bytes = _bigint_to_bytes( $self->{A}, N_LEN );
	my $M2      = sha512( $A_bytes . $self->{M1} . $self->{K} );

	$self->{M2} = $M2;

	return $M2;
}

# $self->session_key():
#	Return the shared session key K (64 bytes).
sub session_key ($self)
{
	return $self->{K};
}

package Protocol::HAP::SRP::Client;
our $VERSION = '0.1.0';

# The imports of the accessory package above do not reach this one:
# Perl imports into a package, not into a file.
use Digest::SHA              qw(sha512);
use Protocol::HAP::SetupCode qw(normalize_setup_code);

# The controller role of the same exchange (HAP-Pairing.md §2.5). It
# reuses the group, the N_LEN padding rule, and the byte conversion
# of the accessory role above, so the two sides cannot drift. One
# module holds both, and the conformance vectors exercise them
# against each other.

# One definition of the padding rule: the accessory package's.
use constant N_LEN => Protocol::HAP::SRP::N_LEN;

sub _b2i ($bytes)
{
	return Math::BigInt->from_hex( unpack( 'H*', $bytes ) );
}

sub new ( $class, %args )
{
	my $password = normalize_setup_code( $args{password} )
	    // $args{password};

	my $self = bless {
		username => $args{username} // 'Pair-Setup',
		password => $password,

		N => _b2i($Protocol::HAP::SRP::N_3072),
		g => Math::BigInt->new($Protocol::HAP::SRP::g),
	}, $class;

	return $self;
}

# $self->compute_public():
#	Generate the ephemeral secret a and return the padded public
#	value A = g^a mod N (384 bytes).
sub compute_public ($self)
{
	my $a_bytes = Protocol::HAP::Crypto->random_bytes(32);
	$self->{a} = _b2i($a_bytes);
	$self->{A} = $self->{g}->copy->bmodpow( $self->{a}, $self->{N} );

	return Protocol::HAP::SRP::_bigint_to_bytes( $self->{A}, N_LEN );
}

# $self->compute_proof($salt, $B_bytes):
#	Complete the client side with the server's salt and public
#	key B. Derive the session key K and return the client proof
#	M1. Return undef if B mod N == 0, which is a bogus server
#	value.
sub compute_proof ( $self, $salt, $B_bytes )
{
	die 'SRP: compute_public not called' unless defined $self->{A};

	# The accessory package's byte conversion, under a short name
	# for the formulas below
	my $i2b = \&Protocol::HAP::SRP::_bigint_to_bytes;

	my $N = $self->{N};
	my $g = $self->{g};
	my $B = _b2i($B_bytes);

	return if ( $B % $N )->is_zero();

	# u = H(PAD(A) | PAD(B))
	my $u =
	    _b2i( sha512( $i2b->( $self->{A}, N_LEN ) . $i2b->( $B, N_LEN ) ) );

	# x = H(s | H(I ":" P)), k = H(N | PAD(g))
	my $x = _b2i(
		sha512( $salt . sha512("$self->{username}:$self->{password}") )
	);
	my $k = _b2i( sha512( $i2b->($N) . $i2b->( $g, N_LEN ) ) );

	# S = (B - k*g^x)^(a + u*x) mod N
	my $gx   = $g->copy->bmodpow( $x, $N );
	my $base = ( $B - ( $k * $gx ) ) % $N;
	my $S    = $base->bmodpow( $self->{a} + $u * $x, $N );

	$self->{K} = sha512( $i2b->($S) );

	# M1 = H(H(N) xor H(g) | H(I) | s | PAD(A) | PAD(B) | K)
	$self->{M1} =
	    sha512( ( sha512( $i2b->($N) ) ^. sha512( $i2b->($g) ) )
		. sha512( $self->{username} )
		    . $salt
		    . $i2b->( $self->{A}, N_LEN )
		    . $i2b->( $B,         N_LEN )
		    . $self->{K} );

	return $self->{M1};
}

# $self->verify_server_proof($M2):
#	Check the server proof M2 = H(PAD(A) | M1 | K).
sub verify_server_proof ( $self, $M2 )
{
	die 'SRP: compute_proof not called' unless defined $self->{M1};

	my $expected =
	    sha512(   Protocol::HAP::SRP::_bigint_to_bytes( $self->{A}, N_LEN )
		    . $self->{M1}
		    . $self->{K} );

	return $expected eq ( $M2 // '' );
}

# $self->session_key():
#	Return the shared session key K (64 bytes).
sub session_key ($self)
{
	return $self->{K};
}

1;
