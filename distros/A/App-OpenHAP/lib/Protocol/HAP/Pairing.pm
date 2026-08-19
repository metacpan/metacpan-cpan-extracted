use v5.36;

package Protocol::HAP::Pairing;
our $VERSION = '0.1.0';

use Protocol::HAP;
use Protocol::HAP::TLV;
use Protocol::HAP::SRP;
use Protocol::HAP::Crypto;

use Protocol::HAP::SetupCode qw(normalize_setup_code);

# TLV Types for pairing
use constant {
	kTLVType_Method        => 0x00,
	kTLVType_Identifier    => 0x01,
	kTLVType_Salt          => 0x02,
	kTLVType_PublicKey     => 0x03,
	kTLVType_Proof         => 0x04,
	kTLVType_EncryptedData => 0x05,
	kTLVType_State         => 0x06,
	kTLVType_Error         => 0x07,
	kTLVType_RetryDelay    => 0x08,
	kTLVType_Certificate   => 0x09,
	kTLVType_Signature     => 0x0A,
	kTLVType_Permissions   => 0x0B,
	kTLVType_FragmentData  => 0x0C,
	kTLVType_FragmentLast  => 0x0D,
	kTLVType_SessionID     => 0x0E,
	kTLVType_Flags         => 0x13,
	kTLVType_Separator     => 0xFF,
};

# Error codes
use constant {
	kTLVError_Unknown        => 0x01,
	kTLVError_Authentication => 0x02,
	kTLVError_Backoff        => 0x03,
	kTLVError_MaxPeers       => 0x04,
	kTLVError_MaxTries       => 0x05,
	kTLVError_Unavailable    => 0x06,
	kTLVError_Busy           => 0x07,
};

# Maximum failed authentication attempts before lockout (per HAP-Pairing.md §8)
use constant MAX_AUTH_ATTEMPTS => 100;

sub new ( $class, %args )
{
	my $pin = normalize_setup_code( $args{pin} ) // die "PIN required";

	# The store is required. The attempt counter of HAP-Pairing.md
	# §8 needs persistence; a silent in-memory fallback would fail
	# open after a restart.
	my $store = $args{store} // die "store required";

	my $self = bless {
		pin            => $pin,
		store          => $store,
		logger         => $args{logger} // Protocol::HAP->null_logger,
		accessory_ltsk => $args{accessory_ltsk},
		accessory_ltpk => $args{accessory_ltpk},

		# The pairing lock and the attempt counter are instance
		# state. Two servers in one process must not share a
		# lock or a counter.
		pairing_in_progress => 0,
		pairing_session_id  => undef,

		# Restore the persisted attempt counter so the limit
		# survives restarts (HAP-Pairing.md §8)
		failed_auth_attempts => $store->get_auth_attempts,
	}, $class;

	return $self;
}

# $self->clear_pairing_state($session):
#	Reset the pairing lock. The server calls this after successful
#	pairing or on connection close.
sub clear_pairing_state ( $self, $session = undef )
{
	# Clear the state only if this session owns the lock or
	# the caller gives no session
	if (       !defined $session
		|| !defined $self->{pairing_session_id}
		|| $self->{pairing_session_id} == $session )
	{
		$self->{pairing_in_progress} = 0;
		$self->{pairing_session_id}  = undef;
	}

	return;
}

# $self->reset_auth_attempts:
#	Reset the failed authentication counter. The server calls this
#	after the SRP proof verification succeeds. Administrative
#	actions also call it.
sub reset_auth_attempts ($self)
{
	$self->{failed_auth_attempts} = 0;
	$self->{store}->set_auth_attempts(0);

	return;
}

# $self->_auth_failure($message):
#	Count and persist a failed attempt (§8), log it with the
#	attempt count, and return the M4 error response: MaxTries at
#	the limit, Authentication below it.
sub _auth_failure ( $self, $message )
{
	$self->{failed_auth_attempts}++;
	$self->{store}->set_auth_attempts( $self->{failed_auth_attempts} );

	$self->{logger}->warning(
		'%s (attempt %d/%d)',
		$message, $self->{failed_auth_attempts},
		MAX_AUTH_ATTEMPTS
	);

	if ( $self->{failed_auth_attempts} >= MAX_AUTH_ATTEMPTS ) {
		return $self->_error_response( kTLVError_MaxTries, 4 );
	}
	return $self->_error_response( kTLVError_Authentication, 4 );
}

# $self->get_failed_attempts:
#	Get the current failed attempt count (for testing).
sub get_failed_attempts ($self)
{
	return $self->{failed_auth_attempts};
}

# $self->_decode_request($body, $label):
#	The decode-and-check preamble of both pairing endpoints.
#	Return the request TLV as a hash reference and the state, or
#	the empty list for a malformed TLV or a missing State
#	([HAP-TLV8 §10]).
sub _decode_request ( $self, $body, $label )
{
	my %request = Protocol::HAP::TLV::decode($body);

	unless ( defined $request{ kTLVType_State() } ) {
		$self->{logger}
		    ->warning( '%s rejected: malformed TLV request', $label );
		return;
	}

	return ( \%request, unpack( 'C', $request{ kTLVType_State() } ) );
}

sub handle_pair_setup ( $self, $body, $session )
{
	my ( $request, $state ) = $self->_decode_request( $body, 'Pair-setup' );
	return $self->_error_response( kTLVError_Unknown, 2 ) unless $request;

	my $method = unpack( 'C', $request->{ kTLVType_Method() } // "\x00" );
	$self->{logger}
	    ->debug( 'Pair-setup M%d received (method=%d)', $state, $method );

	# Validate the method (0x00 = PairSetup, 0x01 = PairSetupWithAuth)
	if ( $method != 0 && $method != 1 ) {
		return $self->_error_response( kTLVError_Unknown, 2 );
	}

	if ( $state == 1 ) {
		return $self->_pair_setup_m1_m2( $session, $method );
	}
	elsif ( $state == 3 ) {
		return $self->_pair_setup_m3_m4( $request, $session );
	}
	elsif ( $state == 5 ) {
		return $self->_pair_setup_m5_m6( $request, $session );
	}

	return $self->_error_response( kTLVError_Unknown, 2 );
}

sub _pair_setup_m1_m2 ( $self, $session, $method = 0 )
{
	# Check if the failed attempts exceed the maximum
	# (HAP-Pairing.md §8)
	if ( $self->{failed_auth_attempts} >= MAX_AUTH_ATTEMPTS ) {
		$self->{logger}
		    ->warning('Pair-setup rejected: max attempts exceeded');
		return $self->_error_response( kTLVError_MaxTries, 2 );
	}

	# Check if the accessory is already paired
	# (HAP-Pairing.md §2.4). PairSetupWithAuth (method=1)
	# permits pairing even when the accessory is already
	# paired.
	if ( $method == 0 ) {
		my $pairings = $self->{store}->load_pairings();
		if ( keys %$pairings > 0 ) {
			$self->{logger}
			    ->debug('Pair-setup rejected: already paired');
			return $self->_error_response( kTLVError_Unavailable,
				2 );
		}
	}

	# Check for a concurrent pairing attempt (HAP-Pairing.md §2.4)
	if (       $self->{pairing_in_progress}
		&& $self->{pairing_session_id} != $session )
	{
		$self->{logger}
		    ->debug('Pair-setup rejected: another pairing in progress');
		return $self->_error_response( kTLVError_Busy, 2 );
	}

	# Mark the pairing as in progress
	$self->{pairing_in_progress} = 1;
	$self->{pairing_session_id}  = $session;

	# Initialize SRP
	my $srp  = Protocol::HAP::SRP->new( password => $self->{pin} );
	my $salt = $srp->generate_salt();
	$srp->compute_verifier;
	$srp->generate_server_public();

	# Store the SRP session
	$session->{pairing_state}{srp} = $srp;

	# M2: Send the salt and the public key. The key goes out padded
	# to the length of N, which is what both sides hash.
	my $response =
	    Protocol::HAP::TLV::encode( kTLVType_State, pack( 'C', 2 ),
		kTLVType_PublicKey, $srp->server_public_bytes,
		kTLVType_Salt,      $salt, );

	return $response;
}

sub _pair_setup_m3_m4 ( $self, $request, $session )
{

	my $srp = $session->{pairing_state}{srp};
	return $self->_error_response( kTLVError_Unknown, 4 ) unless $srp;

	my $A  = $request->{ kTLVType_PublicKey() };
	my $M1 = $request->{ kTLVType_Proof() };

	# Compute the session key. It returns undef if A mod N == 0.
	my $K = $srp->compute_session_key($A);
	unless ( defined $K ) {
		return $self->_auth_failure(
			'Pair-setup M3 rejected: invalid public key A');
	}

	unless ( $srp->verify_client_proof($M1) ) {
		return $self->_auth_failure(
			'Pair-setup M3 proof verification failed');
	}

	# Successful SRP proof resets the attempt counter (§8)
	$self->reset_auth_attempts;

	# Generate the server proof
	my $M2 = $srp->generate_server_proof();
	$self->{logger}->debug('Pair-setup M3 verified, sending M4');

	# M4: Send the proof
	my $response =
	    Protocol::HAP::TLV::encode( kTLVType_State, pack( 'C', 4 ),
		kTLVType_Proof, $M2, );

	return $response;
}

sub _pair_setup_m5_m6 ( $self, $request, $session )
{

	my $srp = $session->{pairing_state}{srp};
	return $self->_error_response( kTLVError_Unknown, 6 ) unless $srp;

	my $encrypted_data = $request->{ kTLVType_EncryptedData() };

	# Derive the encryption key from the SRP session key
	my $session_key = $srp->session_key;
	my $encrypt_key = Protocol::HAP::Crypto->hkdf_sha512( $session_key,
		'Pair-Setup-Encrypt-Salt', 'Pair-Setup-Encrypt-Info', 32 );

	# Decrypt the data
	my $nonce    = pack('x[4]') . 'PS-Msg05';
	my $auth_tag = substr( $encrypted_data, -16, 16, '' );
	my $decrypted =
	    Protocol::HAP::Crypto->chacha20poly1305_decrypt( $encrypt_key,
		$nonce, $encrypted_data, $auth_tag );

	return $self->_error_response( kTLVError_Authentication, 6 )
	    unless defined $decrypted;

	# Parse the decrypted TLV
	my %inner                 = Protocol::HAP::TLV::decode($decrypted);
	my $ios_device_pairing_id = $inner{ kTLVType_Identifier() };
	my $ios_device_ltpk       = $inner{ kTLVType_PublicKey() };
	my $ios_device_signature  = $inner{ kTLVType_Signature() };

	# Verify the signature
	my $ios_device_x = Protocol::HAP::Crypto->hkdf_sha512(
		$session_key,
		'Pair-Setup-Controller-Sign-Salt',
		'Pair-Setup-Controller-Sign-Info', 32
	);
	my $ios_device_info =
	    $ios_device_x . $ios_device_pairing_id . $ios_device_ltpk;

	unless (
		Protocol::HAP::Crypto->ed25519_verify(
			$ios_device_signature, $ios_device_info,
			$ios_device_ltpk
		) )
	{
		return $self->_error_response( kTLVError_Authentication, 6 );
	}

	# Save the pairing
	$self->{store}
	    ->save_pairing( $ios_device_pairing_id, $ios_device_ltpk, 1 );
	$self->{logger}->debug( 'Pair-setup M5 verified, pairing saved for %s',
		$ios_device_pairing_id );

	# The pairing is successful. Reset the attempt counter.
	# Clear the pairing lock.
	$self->reset_auth_attempts;
	$self->{pairing_in_progress} = 0;
	$self->{pairing_session_id}  = undef;

	# Generate the accessory signature
	my $accessory_x = Protocol::HAP::Crypto->hkdf_sha512(
		$session_key,
		'Pair-Setup-Accessory-Sign-Salt',
		'Pair-Setup-Accessory-Sign-Info', 32
	);
	my $accessory_pairing_id =
	    Protocol::HAP::device_id( $self->{accessory_ltpk} );
	my $accessory_info =
	    $accessory_x . $accessory_pairing_id . $self->{accessory_ltpk};
	my $accessory_signature = Protocol::HAP::Crypto->ed25519_sign(
		$accessory_info,
		$self->{accessory_ltsk},
		$self->{accessory_ltpk} );

	# Build the response TLV
	my $response_tlv = Protocol::HAP::TLV::encode(
		kTLVType_Identifier, $accessory_pairing_id,
		kTLVType_PublicKey,  $self->{accessory_ltpk},
		kTLVType_Signature,  $accessory_signature,
	);

	# Encrypt the response
	my $response_nonce = pack('x[4]') . 'PS-Msg06';
	my ( $response_encrypted, $response_tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $encrypt_key,
		$response_nonce, $response_tlv );

	# M6: Send the encrypted data
	my $response = Protocol::HAP::TLV::encode(
		kTLVType_State,         pack( 'C', 6 ),
		kTLVType_EncryptedData, $response_encrypted . $response_tag,
	);

	return $response;
}

sub handle_pair_verify ( $self, $body, $session )
{
	my ( $request, $state ) =
	    $self->_decode_request( $body, 'Pair-verify' );
	return $self->_error_response( kTLVError_Unknown, 2 ) unless $request;

	$self->{logger}->debug( 'Pair-verify M%d received', $state );

	if ( $state == 1 ) {
		return $self->_pair_verify_m1_m2( $request, $session );
	}
	elsif ( $state == 3 ) {
		return $self->_pair_verify_m3_m4( $request, $session );
	}

	return $self->_error_response( kTLVError_Unknown, 2 );
}

sub _pair_verify_m1_m2 ( $self, $request, $session )
{

	my $ios_public_key = $request->{ kTLVType_PublicKey() };
	$self->{logger}->debug('Pair-verify M1: generating ephemeral keypair');

	# Generate the accessory ephemeral keypair
	my ( $accessory_secret, $accessory_public ) =
	    Protocol::HAP::Crypto->x25519_keypair;

	# Compute the shared secret
	my $shared_secret =
	    Protocol::HAP::Crypto->x25519_shared_secret( $accessory_secret,
		$ios_public_key );

	# Store the state for the next step
	$session->{pairing_state}{accessory_secret} = $accessory_secret;
	$session->{pairing_state}{accessory_public} = $accessory_public;
	$session->{pairing_state}{ios_public_key}   = $ios_public_key;
	$session->{pairing_state}{shared_secret}    = $shared_secret;

	# Generate the accessory info and signature
	my $accessory_pairing_id =
	    Protocol::HAP::device_id( $self->{accessory_ltpk} );
	my $accessory_info =
	    $accessory_public . $accessory_pairing_id . $ios_public_key;
	my $accessory_signature = Protocol::HAP::Crypto->ed25519_sign(
		$accessory_info,
		$self->{accessory_ltsk},
		$self->{accessory_ltpk} );

	# Build the sub-TLV
	my $sub_tlv = Protocol::HAP::TLV::encode(
		kTLVType_Identifier, $accessory_pairing_id,
		kTLVType_Signature,  $accessory_signature,
	);

	# Derive the session key and encrypt
	my $session_key = Protocol::HAP::Crypto->hkdf_sha512( $shared_secret,
		'Pair-Verify-Encrypt-Salt', 'Pair-Verify-Encrypt-Info', 32 );

	my $nonce = pack('x[4]') . 'PV-Msg02';
	my ( $encrypted, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $session_key,
		$nonce, $sub_tlv );

	# M2: Send the public key and the encrypted data
	my $response = Protocol::HAP::TLV::encode(
		kTLVType_State,         pack( 'C', 2 ),
		kTLVType_PublicKey,     $accessory_public,
		kTLVType_EncryptedData, $encrypted . $tag,
	);

	return $response;
}

sub _pair_verify_m3_m4 ( $self, $request, $session )
{

	my $encrypted_data = $request->{ kTLVType_EncryptedData() };

	my $shared_secret    = $session->{pairing_state}{shared_secret};
	my $accessory_public = $session->{pairing_state}{accessory_public};
	my $ios_public_key   = $session->{pairing_state}{ios_public_key};

	# M3 without a preceding M1 exchange is a protocol error
	return $self->_error_response( kTLVError_Unknown, 4 )
	    unless defined $shared_secret;

	# Derive the session key
	my $session_key = Protocol::HAP::Crypto->hkdf_sha512( $shared_secret,
		'Pair-Verify-Encrypt-Salt', 'Pair-Verify-Encrypt-Info', 32 );

	# Decrypt
	my $nonce    = pack('x[4]') . 'PV-Msg03';
	my $auth_tag = substr( $encrypted_data, -16, 16, '' );
	my $decrypted =
	    Protocol::HAP::Crypto->chacha20poly1305_decrypt( $session_key,
		$nonce, $encrypted_data, $auth_tag );

	return $self->_error_response( kTLVError_Authentication, 4 )
	    unless defined $decrypted;

	# Parse the inner TLV
	my %inner          = Protocol::HAP::TLV::decode($decrypted);
	my $ios_pairing_id = $inner{ kTLVType_Identifier() };
	my $ios_signature  = $inner{ kTLVType_Signature() };

	# Load the pairing
	my $pairings = $self->{store}->load_pairings();
	my $pairing  = $pairings->{$ios_pairing_id};

	return $self->_error_response( kTLVError_Authentication, 4 )
	    unless $pairing;

	# Verify the signature
	my $ios_info = $ios_public_key . $ios_pairing_id . $accessory_public;
	unless (
		Protocol::HAP::Crypto->ed25519_verify(
			$ios_signature, $ios_info, $pairing->{ltpk} ) )
	{
		return $self->_error_response( kTLVError_Authentication, 4 );
	}

	# Derive the session encryption keys. The names are from
	# the controller's point of view:
	# - Control-Read-Encryption-Key: the controller reads,
	#   the accessory encrypts
	# - Control-Write-Encryption-Key: the controller writes,
	#   the accessory decrypts
	my $encrypt_key =
	    Protocol::HAP::Crypto->hkdf_sha512( $shared_secret, 'Control-Salt',
		'Control-Read-Encryption-Key', 32 );
	my $decrypt_key =
	    Protocol::HAP::Crypto->hkdf_sha512( $shared_secret, 'Control-Salt',
		'Control-Write-Encryption-Key', 32 );

	# Set up the encrypted session
	$session->set_encryption( $encrypt_key, $decrypt_key );
	$session->set_verified($ios_pairing_id);
	$self->{logger}
	    ->debug('Pair-verify M3 verified successfully, session encrypted');

	# M4: Success
	my $response =
	    Protocol::HAP::TLV::encode( kTLVType_State, pack( 'C', 4 ), );

	return $response;
}

sub _error_response ( $self, $error_code, $state )
{

	return Protocol::HAP::TLV::encode(
		kTLVType_State, pack( 'C', $state ),
		kTLVType_Error, pack( 'C', $error_code ),
	);
}

1;
