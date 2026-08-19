use v5.36;

package Protocol::HAP::Session;
our $VERSION = '0.1.0';

use Protocol::HAP;
use Protocol::HAP::Crypto;

sub new ( $class, %args )
{
	# The id is required, and the server allocates it from an
	# instance counter. The id is not the descriptor: the kernel
	# gives a closed descriptor to the next connection, so a
	# subscription that a purge missed would arrive at whoever
	# inherits the number. A counter never repeats.
	my $id = $args{id} // die 'session id required';

	my $self = bless {
		id            => $id,
		logger        => $args{logger} // Protocol::HAP->null_logger,
		encrypted     => 0,
		verified      => 0,
		controller_id => undef,

		# Session keys. Pair-verify sets them.
		encrypt_key => undef,
		decrypt_key => undef,

		# Counters for nonce generation
		encrypt_count => 0,
		decrypt_count => 0,

		# Temporary pairing state
		pairing_state => {},

		# The event keys this connection subscribed to. The
		# server deletes them one by one when the connection
		# closes, instead of sweeping every key it holds.
		subscriptions => {},
	}, $class;

	return $self;
}

# $self->id:
#	The key that the server files this session under.
sub id ($self)
{
	return $self->{id};
}

sub set_encryption ( $self, $encrypt_key, $decrypt_key )
{

	$self->{encrypt_key}   = $encrypt_key;
	$self->{decrypt_key}   = $decrypt_key;
	$self->{encrypted}     = 1;
	$self->{encrypt_count} = 0;
	$self->{decrypt_count} = 0;
	$self->{logger}->debug('Session encryption enabled');
}

sub encrypt ( $self, $data )
{

	return $data unless $self->{encrypted};

	my $encrypted = '';

	# HAP encrypts data in chunks. The AAD contains the length.
	while ( length($data) > 0 ) {
		my $chunk  = substr( $data, 0, 1024, '' );
		my $length = length($chunk);

		# The AAD is the 2-byte length in little-endian
		my $aad = pack( 'v', $length );

		# The nonce is 4 bytes zero + 8 bytes counter
		# (little-endian)
		my $nonce = pack( 'x[4]Q<', $self->{encrypt_count}++ );

		my ( $ciphertext, $tag ) =
		    Protocol::HAP::Crypto->chacha20poly1305_encrypt(
			$self->{encrypt_key},
			$nonce, $chunk, $aad );

		# Frame format: length (2 bytes) + ciphertext + tag (16 bytes)
		$encrypted .= $aad . $ciphertext . $tag;
	}

	return $encrypted;
}

sub decrypt ( $self, $data )
{

	return $data unless $self->{encrypted};

	my $decrypted = '';
	my $pos       = 0;

	# HAP decrypts data in frames. A truncated frame is an
	# error. A frame that claims more than 1024 bytes of
	# plaintext is also an error (HAP-Encryption.md §9).
	while ( $pos < length($data) ) {

		# Read the frame header (2-byte length)
		return if $pos + 2 > length($data);
		my $length = unpack( 'v', substr( $data, $pos, 2 ) );
		my $aad    = substr( $data, $pos, 2 );
		$pos += 2;

		return if $length > 1024;

		# Read the ciphertext and the tag
		return if $pos + $length + 16 > length($data);
		my $ciphertext = substr( $data, $pos, $length );
		$pos += $length;
		my $tag = substr( $data, $pos, 16 );
		$pos += 16;

		# The nonce is 4 bytes zero + 8 bytes counter
		# (little-endian)
		my $nonce = pack( 'x[4]Q<', $self->{decrypt_count}++ );

		my $plaintext =
		    Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$self->{decrypt_key}, $nonce, $ciphertext, $tag, $aad );

		return unless defined $plaintext;
		$decrypted .= $plaintext;
	}

	return $decrypted;
}

sub is_encrypted ($self)
{
	return $self->{encrypted};
}

sub is_verified ($self)
{
	return $self->{verified};
}

sub set_verified ( $self, $controller_id )
{
	$self->{verified}      = 1;
	$self->{controller_id} = $controller_id;
	$self->{logger}
	    ->debug( 'Session verified for controller: %s', $controller_id );

	return;
}

sub controller_id ($self)
{
	return $self->{controller_id};
}

1;
