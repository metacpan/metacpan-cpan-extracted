# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Protocol::HAP::Server;
our $VERSION = '0.1.0';

use JSON::PP;
use MIME::Base64 qw(encode_base64);
use Digest::SHA  qw(sha512);

use Protocol::HAP;
use Protocol::HAP::HTTP;
use Protocol::HAP::TLV;
use Protocol::HAP::Session;
use Protocol::HAP::Pairing;
use Protocol::HAP::Crypto;
use Protocol::HAP::Bridge;
use Protocol::HAP::Characteristic;
use Protocol::HAP::SetupCode qw(normalize_setup_code);

# Protocol::HAP::Server - the sans-IO HAP accessory-server engine.
#
# The engine consumes bytes and emits bytes. The host owns sockets,
# timers, logging, and persistence, injected through the contracts
# that Protocol/HAP.pod documents. The engine owns everything that is
# protocol: the read buffer and its bound, decryption, HTTP parsing,
# endpoint dispatch, the pairing state machines, the accessory
# database, and event delivery.

# The largest request the engine accepts: the header block plus the
# body that Content-Length declares. An unpaired client reaches
# /pair-setup, so the buffer of an unauthenticated connection needs a
# bound of its own. A HAP request is a small TLV or a short JSON
# document, so 64 KB is far above anything a controller sends.
use constant MAX_REQUEST_SIZE => 65536;

# The HAP status code for a request that arrives on an unverified
# connection [HAP-HTTP]. It is not an RFC 9110 code, so the codec does
# not know its reason phrase.
use constant STATUS_INSUFFICIENT_PRIVILEGES => 470;

# Characteristic types exempt from coalescing (HAP-HTTP.md §14):
# ProgrammableSwitchEvent (0x73), ButtonEvent (0x126),
# MotionDetected (0x22), ContactSensorState (0x6A)
use constant IMMEDIATE_EVENT_TYPES => {
	'73'  => 1,
	'126' => 1,
	'22'  => 1,
	'6A'  => 1,
};

# Event coalescing delay in seconds (HAP-HTTP.md §14)
use constant EVENT_COALESCE_DELAY => 0.250;

# _response(%args):
#	Build a response with the HAP defaults: the connection stays
#	open, because a controller sends every request of a session
#	over one connection.
sub _response (%args)
{
	my %headers = %{ $args{headers} // {} };
	$headers{Connection} //= 'keep-alive';

	return Protocol::HAP::HTTP::build_response( %args,
		headers => \%headers );
}

# _tlv_response($body):
#	A 200 response with the pairing TLV content type. Every
#	pairing and pairings-management reply uses it.
sub _tlv_response ($body)
{
	return _response(
		status  => 200,
		headers => { 'Content-Type' => 'application/pairing+tlv8' },
		body    => $body,
	);
}

# _char_status($aid, $iid, $code):
#	One per-characteristic result entry for the characteristics
#	endpoints [HAP-HTTP].
sub _char_status ( $aid, $iid, $code )
{
	return { aid => $aid + 0, iid => $iid + 0, status => $code };
}

# $class->new(%args):
#	name, pin, setup_id, category - the accessory identity.
#	store, logger, output, after, cancel, on_pairing_changed - the
#	host contracts of Protocol/HAP.pod. store and output are
#	required; after and cancel are optional, and without them the
#	host calls flush_events itself.
sub new ( $class, %args )
{
	my $pin = normalize_setup_code( $args{pin} )
	    // die 'valid pin required';
	my $store  = $args{store}  // die 'store required';
	my $output = $args{output} // die 'output required';

	my $self = bless {
		pin      => $pin,
		name     => $args{name} // 'OpenHAP Bridge',
		setup_id => $args{setup_id},         # Optional 4-char setup ID
		category => $args{category} // 2,    # Bridge

		# The host contracts
		store  => $store,
		logger => $args{logger} // Protocol::HAP->null_logger,
		output => $output,
		after  => $args{after},
		cancel => $args{cancel},
		on_pairing_changed => $args{on_pairing_changed},

		bridge  => undef,
		pairing => undef,

		accessory_ltsk => undef,
		accessory_ltpk => undef,

		# Session ids come from an instance counter. Two engines
		# in one process never share one.
		next_session_id => 1,

		event_subscriptions => {},       # Track event subscriptions
		event_queue         => {},       # Queued events for coalescing
		event_flush_timer   => undef,    # The pending flush, if any

		# utf8 mode: the codec takes and returns octets, never
		# wide-character strings. The wire carries octets, the
		# AEAD layer refuses wide characters, and Content-Length
		# counts bytes. Without this flag, a non-ASCII value
		# breaks all three.
		json => JSON::PP->new->utf8,
	}, $class;

	$self->_initialize;

	return $self;
}

sub _initialize ($self)
{
	# Load or generate the accessory identity through the store
	my ( $ltsk, $ltpk ) = $self->{store}->load_accessory_keys;
	unless ( $ltsk && $ltpk ) {
		( $ltsk, $ltpk ) = Protocol::HAP::Crypto->ed25519_keypair;
		$self->{store}->save_accessory_keys( $ltsk, $ltpk );
	}

	$self->{accessory_ltsk} = $ltsk;
	$self->{accessory_ltpk} = $ltpk;

	# Initialize the pairing handler
	$self->{pairing} = Protocol::HAP::Pairing->new(
		pin            => $self->{pin},
		store          => $self->{store},
		logger         => $self->{logger},
		accessory_ltsk => $self->{accessory_ltsk},
		accessory_ltpk => $self->{accessory_ltpk},
	);

	# Initialize the bridge
	$self->{bridge} = Protocol::HAP::Bridge->new(
		name   => $self->{name},
		logger => $self->{logger},
	);

	# Deliver device-side changes as EVENT/1.0 notifications.
	# The bridge forwards the notify_change of each bridged
	# accessory and keeps the device aid (HAP-HTTP.md §14).
	# queue_event resolves the current value itself.
	$self->{bridge}->add_event_callback(
		sub ( $aid, $iid ) {
			$self->queue_event( $aid, $iid );
		} );

	# The paired state at construction, so the first flip calls
	# on_pairing_changed
	$self->{last_paired_state} = $self->is_paired ? 1 : 0;

	return;
}

# --- the connection contract --------------------------------------------

# $self->session_open:
#	Return a new session. The host files it beside the connection
#	it belongs to; the engine never sees the descriptor.
sub session_open ($self)
{
	return Protocol::HAP::Session->new(
		id     => $self->{next_session_id}++,
		logger => $self->{logger},
	);
}

# $self->receive($session, $bytes):
#	Consume what the host read from the connection: decrypt,
#	buffer, parse, dispatch, and emit every response through the
#	output contract. The method returns 1, or undef on a fatal
#	condition - a failed decryption or an over-limit request. On
#	undef the host closes the connection.
sub receive ( $self, $session, $bytes )
{
	# Decrypt the data if the session is encrypted. Keep a
	# record of the state. Pair-verify M4 enables encryption
	# during dispatch. But the engine sends the M4 response in
	# the clear. Encryption applies only to subsequent traffic.
	my $was_encrypted = $session->is_encrypted;
	my $data          = $bytes;
	if ($was_encrypted) {
		$data = $session->decrypt($bytes);
		unless ( defined $data ) {
			$self->{logger}
			    ->warning('Decryption failed for client session');
			return;
		}
	}

	$session->{inbuf} .= $data;

	# Serve every whole request the buffer holds. A client that
	# pipelines gets an answer to each one, in order.
	while ( length $session->{inbuf} ) {
		my $length =
		    Protocol::HAP::HTTP::message_complete( $session->{inbuf},
			max_size => MAX_REQUEST_SIZE );

		# Over the limit. An unpaired client reaches
		# /pair-setup, so the buffer of an unauthenticated
		# connection needs a bound of its own.
		unless ( defined $length ) {
			$self->{logger}
			    ->warning( 'Request over %d bytes, closing',
				MAX_REQUEST_SIZE );
			return;
		}
		last if $length == 0;    # More bytes are necessary

		my $message = substr $session->{inbuf}, 0, $length, '';
		$self->_serve_request( $session, $message, $was_encrypted );
	}

	return 1;
}

# $self->session_close($session):
#	Release what the session holds: the pairing lock and its event
#	subscriptions. The host calls this when it closes the
#	connection.
sub session_close ( $self, $session )
{
	$self->{pairing}->clear_pairing_state($session);
	$self->_purge_event_subscriptions($session);

	return;
}

# $self->_serve_request($session, $message, $was_encrypted):
#	Dispatch one whole request and emit its response.
sub _serve_request ( $self, $session, $message, $was_encrypted )
{
	my $request = Protocol::HAP::HTTP::parse_request($message);
	unless ( defined $request ) {
		$self->{logger}->warning('Malformed request');
		$request =
		    { method => '', path => '', headers => {}, body => '' };
	}

	$self->{logger}
	    ->info( 'HTTP %s %s', $request->{method}, $request->{path} );

	# Dispatch the request
	my $response = $self->_dispatch( $request, $session );

	# Encrypt the response only if the session was encrypted
	# when the request arrived. See the note above.
	if ($was_encrypted) {
		$response = $session->encrypt($response);
	}

	$self->{output}->( $session, $response );

	# Tell the host if this request changed the pairing state
	$self->_notify_pairing_changed;

	return;
}

# $self->_notify_pairing_changed:
#	Call on_pairing_changed when the paired state flips. The host
#	re-advertises its mDNS TXT record [HAP-mDNS §8].
sub _notify_pairing_changed ($self)
{
	my $paired = $self->is_paired ? 1 : 0;
	return if $self->{last_paired_state} == $paired;

	$self->{last_paired_state} = $paired;
	$self->{on_pairing_changed}->($paired)
	    if $self->{on_pairing_changed};

	return;
}

# --- endpoint dispatch ----------------------------------------------------

sub _dispatch ( $self, $request, $session )
{
	my $path   = $request->{path};
	my $method = $request->{method};

	# Pairing endpoints. These need no verified session.
	if ( $path eq '/pair-setup' && $method eq 'POST' ) {
		return $self->_handle_pair_setup( $request, $session );
	}

	if ( $path eq '/pair-verify' && $method eq 'POST' ) {
		return $self->_handle_pair_verify( $request, $session );
	}

	# Identify endpoint. It is for unpaired accessories only.
	if ( $path eq '/identify' && $method eq 'POST' ) {
		return $self->_handle_identify( $request, $session );
	}

	# All other endpoints need a verified session. The 470 code
	# carries a reason phrase that only HAP defines, so the codec
	# does not know it.
	unless ( $session->is_verified ) {
		return _response(
			status      => STATUS_INSUFFICIENT_PRIVILEGES,
			status_text => 'Connection Authorization Required',
			headers => { 'Content-Type' => 'application/hap+json' },
		);
	}

	# Pairings management
	if ( $path eq '/pairings' && $method eq 'POST' ) {
		return $self->_handle_pairings( $request, $session );
	}

	# Accessory endpoints
	if ( $path eq '/accessories' && $method eq 'GET' ) {
		return $self->_handle_accessories( $request, $session );
	}

	# Remove the query string for path matching
	my $base_path = $path;
	$base_path =~ s/\?.*//;

	if ( $base_path eq '/characteristics' && $method eq 'GET' ) {
		return $self->_handle_characteristics_get( $request, $session );
	}

	if ( $base_path eq '/characteristics' && $method eq 'PUT' ) {
		return $self->_handle_characteristics_put( $request, $session );
	}

	# Timed write preparation. The spec shows POST in the
	# table, but the later text uses PUT. Accept both.
	if ( $path eq '/prepare' && ( $method eq 'PUT' || $method eq 'POST' ) )
	{
		return $self->_handle_prepare( $request, $session );
	}

	# Not found
	return _response(
		status  => 404,
		headers => { 'Content-Type' => 'text/plain' },
		body    => 'Not Found',
	);
}

sub _handle_pair_setup ( $self, $request, $session )
{
	$self->{logger}->debug('Handling pair-setup request');

	return _tlv_response( $self->{pairing}
		    ->handle_pair_setup( $request->{body}, $session ) );
}

sub _handle_pair_verify ( $self, $request, $session )
{
	$self->{logger}->debug('Handling pair-verify request');

	return _tlv_response( $self->{pairing}
		    ->handle_pair_verify( $request->{body}, $session ) );
}

sub _handle_accessories ( $self, $, $ )
{
	my $json = $self->{json}->encode( $self->{bridge}->to_json );

	return _response(
		status  => 200,
		headers => { 'Content-Type' => 'application/hap+json' },
		body    => $json,
	);
}

# $self->_resolve_char($aid, $iid):
#	The accessory-then-characteristic lookup that both
#	characteristics endpoints perform.
sub _resolve_char ( $self, $aid, $iid )
{
	my $accessory = $self->{bridge}->get_accessory($aid);
	return unless $accessory;

	return $accessory->get_characteristic($iid);
}

sub _handle_characteristics_get ( $self, $request, $ )
{
	# Parse the query string: ?id=1.11,1.13&meta=1&perms=1&type=1&ev=1
	my $query = $request->{path};
	$query =~ s/^.*\?//;
	$self->{logger}->debug( 'Reading characteristics: %s', $query );

	my %params;
	for my $pair ( split /&/, $query ) {
		my ( $key, $value ) = split /=/, $pair, 2;
		$params{$key} = $value;
	}

	my @ids           = split /,/, ( $params{id} // '' );
	my $include_meta  = $params{meta}  // 0;
	my $include_perms = $params{perms} // 0;
	my $include_type  = $params{type}  // 0;
	my $include_ev    = $params{ev}    // 0;

	my @characteristics;
	my $has_errors = 0;

	for my $id (@ids) {
		my ( $aid, $iid ) = split /\./, $id;

		my $char = $self->_resolve_char( $aid, $iid );
		unless ($char) {
			push @characteristics,
			    _char_status( $aid, $iid, -70409 );
			$has_errors = 1;
			next;
		}

		my $result = {
			aid   => $aid + 0,
			iid   => $iid + 0,
			value => $char->json_value,
		};

		# Add the optional metadata if the controller requests it
		if ($include_meta) {
			$result->{format} = $char->{format};
			$result->{unit}   = $char->{unit}
			    if defined $char->{unit};
			$result->{minValue} = $char->{min}
			    if defined $char->{min};
			$result->{maxValue} = $char->{max}
			    if defined $char->{max};
			$result->{minStep} = $char->{step}
			    if defined $char->{step};
		}

		# Add the permissions if the controller requests them
		if ($include_perms) {
			$result->{perms} = $char->{perms};
		}

		# Add the type if the controller requests it
		if ($include_type) {
			$result->{type} = $char->{type};
		}

		# Add the event status if the controller requests it
		if ($include_ev) {
			$result->{ev} = $char->events_enabled ? \1 : \0;
		}

		push @characteristics, $result;
	}

	my $json =
	    $self->{json}->encode( { characteristics => \@characteristics } );

	return _response(
		status  => $has_errors ? 207 : 200,
		headers => { 'Content-Type' => 'application/hap+json' },
		body    => $json,
	);
}

sub _handle_characteristics_put ( $self, $request, $session )
{
	$self->{logger}->debug('Writing characteristics');
	my $data = eval { $self->{json}->decode( $request->{body} ) };
	return _response( status => 400 ) unless $data;

	my @results;
	my $has_errors = 0;

	for my $item ( @{ $data->{characteristics} // [] } ) {
		my $aid   = $item->{aid};
		my $iid   = $item->{iid};
		my $value = $item->{value};

		my $char = $self->_resolve_char( $aid, $iid );
		unless ($char) {
			push @results, _char_status( $aid, $iid, -70409 );
			$has_errors = 1;
			next;
		}

		# Check if the characteristic is writable
		my $is_writable = grep { $_ eq 'pw' } @{ $char->{perms} // [] };
		if ( defined $value && !$is_writable ) {
			push @results, _char_status( $aid, $iid, -70404 );
			$has_errors = 1;
			next;
		}

		# Set the value if the request contains one
		if ( defined $value ) {
			eval { $char->set_value($value) };
			if ($@) {
				push @results,
				    _char_status( $aid, $iid, -70402 );
				$has_errors = 1;
				next;
			}

			# Notify the subscribers on other connections.
			# Exclude the originating session
			# (HAP-HTTP.md §14).
			$self->queue_event( $aid, $iid, $char->json_value,
				$session );
		}

		# Enable or disable events
		if ( exists $item->{ev} ) {
			my $has_ev =
			    grep { $_ eq 'ev' } @{ $char->{perms} // [] };
			if ( !$has_ev ) {
				push @results,
				    _char_status( $aid, $iid, -70406 );
				$has_errors = 1;
				next;
			}
			$char->enable_events( $item->{ev} );

			# Record the session for event delivery
			if ( $item->{ev} ) {
				$self->_register_event_subscription( $session,
					$aid, $iid );
			}
			else {
				$self->_unregister_event_subscription( $session,
					$aid, $iid );
			}
		}

		# Success for this characteristic
		push @results, _char_status( $aid, $iid, 0 );
	}

	# Return 204 No Content when all writes succeed
	return _response( status => 204 )
	    unless $has_errors;

	# Return 207 Multi-Status with details if some writes fail
	my $json = $self->{json}->encode( { characteristics => \@results } );
	return _response(
		status  => 207,
		headers => { 'Content-Type' => 'application/hap+json' },
		body    => $json,
	);
}

sub _handle_identify ( $self, $, $ )
{
	# Identify is only for unpaired accessories
	if ( $self->is_paired ) {
		return _response(
			status  => 400,
			headers => { 'Content-Type' => 'application/hap+json' },
			body => $self->{json}->encode( { status => -70401 } ),
		);
	}

	$self->{logger}->info('Identify request received (unpaired)');

	return _response( status => 204 );
}

sub _handle_pairings ( $self, $request, $session )
{
	my %tlv = Protocol::HAP::TLV::decode( $request->{body} );

	my $method_raw = $tlv{ Protocol::HAP::Pairing::kTLVType_Method() };
	my $method     = defined $method_raw ? unpack( 'C', $method_raw ) : -1;

	$self->{logger}->debug( 'Pairings request method=%d', $method );

	# Method values: 3=Add, 4=Remove, 5=List
	if ( $method == 3 ) {
		return $self->_handle_add_pairing( \%tlv, $session );
	}
	elsif ( $method == 4 ) {
		return $self->_handle_remove_pairing( \%tlv, $session );
	}
	elsif ( $method == 5 ) {
		return $self->_handle_list_pairings( \%tlv, $session );
	}

	# Unknown method
	return $self->_pairings_error(
		Protocol::HAP::Pairing::kTLVError_Unknown() );
}

# $self->_pairings_error($code):
#	One failure response for the pairings endpoints.
sub _pairings_error ( $self, $code )
{
	return _tlv_response(
		Protocol::HAP::TLV::encode(
			Protocol::HAP::Pairing::kTLVType_State(),
			pack( 'C', 2 ),
			Protocol::HAP::Pairing::kTLVType_Error(),
			pack( 'C', $code ),
		) );
}

# $self->_require_admin($session):
#	The admin check of the pairings endpoints (HAP-Pairing.md §7).
#	Return the loaded pairings when the session's controller is an
#	admin, or undef.
sub _require_admin ( $self, $session )
{
	my $pairings = $self->{store}->load_pairings;
	my $current  = $pairings->{ $session->controller_id };
	return unless $current && $current->{permissions};

	return $pairings;
}

sub _handle_add_pairing ( $self, $tlv, $session )
{
	my $identifier =
	    $tlv->{ Protocol::HAP::Pairing::kTLVType_Identifier() };
	my $ltpk  = $tlv->{ Protocol::HAP::Pairing::kTLVType_PublicKey() };
	my $perms = unpack( 'C',
		$tlv->{ Protocol::HAP::Pairing::kTLVType_Permissions() }
		    // "\x00" );

	$self->{logger}
	    ->debug( 'Add pairing request for: %s', $identifier // 'unknown' );

	# Only admins can add pairings
	my $pairings = $self->_require_admin($session);
	unless ($pairings) {
		return $self->_pairings_error(
			Protocol::HAP::Pairing::kTLVError_Authentication() );
	}

	# An existing identifier with a different LTPK is an error.
	# With a matching LTPK, the server updates only the
	# permissions (HAP-Pairing.md §7.4).
	my $existing = $pairings->{$identifier};
	if ( $existing && $existing->{ltpk} ne $ltpk ) {
		return $self->_pairings_error(
			Protocol::HAP::Pairing::kTLVError_Unknown() );
	}

	# Save the pairing
	$self->{store}->save_pairing( $identifier, $ltpk, $perms );
	$self->{logger}
	    ->info( 'Added pairing for controller: %s', $identifier );

	return _tlv_response(
		Protocol::HAP::TLV::encode(
			Protocol::HAP::Pairing::kTLVType_State(),
			pack( 'C', 2 ),
		) );
}

sub _handle_remove_pairing ( $self, $tlv, $session )
{
	my $identifier =
	    $tlv->{ Protocol::HAP::Pairing::kTLVType_Identifier() };

	$self->{logger}->debug( 'Remove pairing request for: %s',
		$identifier // 'unknown' );

	unless ( $self->_require_admin($session) ) {
		return $self->_pairings_error(
			Protocol::HAP::Pairing::kTLVError_Authentication() );
	}

	# Remove the pairing
	$self->{store}->remove_pairing($identifier);
	$self->{logger}
	    ->info( 'Removed pairing for controller: %s', $identifier );

	# Check if any admins remain (HAP-Pairing.md §7.2). If no
	# admin remains, remove all pairings and regenerate the
	# identity.
	my $remaining = $self->{store}->load_pairings;
	my $has_admin = grep { $_->{permissions} } values %$remaining;
	unless ( $has_admin || keys %$remaining == 0 ) {
		$self->{logger}->info(
'Last admin removed - clearing all pairings and regenerating identity'
		);
		$self->{store}->remove_all_pairings;
		$self->_regenerate_identity;
	}

	return _tlv_response(
		Protocol::HAP::TLV::encode(
			Protocol::HAP::Pairing::kTLVType_State(),
			pack( 'C', 2 ),
		) );
}

sub _handle_list_pairings ( $self, $, $session )
{
	$self->{logger}->debug('List pairings request');

	my $pairings = $self->_require_admin($session);
	unless ($pairings) {
		return $self->_pairings_error(
			Protocol::HAP::Pairing::kTLVError_Authentication() );
	}

	# Build the response with all pairings. Separate them with
	# 0xFF.
	my @response_items =
	    ( Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 2 ), );

	my $first = 1;
	for my $id ( sort keys %$pairings ) {
		my $pairing = $pairings->{$id};

		# Add a separator between pairings
		unless ($first) {
			push @response_items,
			    Protocol::HAP::Pairing::kTLVType_Separator(), '';
		}
		$first = 0;

		push @response_items,
		    Protocol::HAP::Pairing::kTLVType_Identifier(), $id,
		    Protocol::HAP::Pairing::kTLVType_PublicKey(),
		    $pairing->{ltpk},
		    Protocol::HAP::Pairing::kTLVType_Permissions(),
		    pack( 'C', $pairing->{permissions} );
	}

	return _tlv_response( Protocol::HAP::TLV::encode(@response_items) );
}

sub _handle_prepare ( $self, $request, $ )
{
	$self->{logger}->debug('Timed write prepare request');
	my $data = eval { $self->{json}->decode( $request->{body} ) };
	return _response( status => 400 ) unless $data;

	# Validate the request
	unless ( defined $data->{ttl} && defined $data->{pid} ) {
		return _response(
			status  => 400,
			headers => { 'Content-Type' => 'application/hap+json' },
			body => $self->{json}->encode( { status => -70410 } ),
		);
	}

	return _response(
		status  => 200,
		headers => { 'Content-Type' => 'application/hap+json' },
		body    => $self->{json}->encode( { status => 0 } ),
	);
}

# --- events ---------------------------------------------------------------

# Event subscription tracking. A subscription is filed twice: under
# the characteristic, for delivery, and on the session, so that a
# disconnect is a delete of what that connection holds and not a
# sweep of every characteristic the bridge has.
sub _register_event_subscription ( $self, $session, $aid, $iid )
{
	my $key = "$aid.$iid";
	$self->{event_subscriptions}{$key}{ $session->id } = $session;
	$session->{subscriptions}{$key} = 1;
	$self->{logger}->debug( 'Registered event subscription for %s', $key );

	return;
}

sub _unregister_event_subscription ( $self, $session, $aid, $iid )
{
	my $key = "$aid.$iid";
	delete $self->{event_subscriptions}{$key}{ $session->id };
	delete $session->{subscriptions}{$key};
	$self->{logger}
	    ->debug( 'Unregistered event subscription for %s', $key );

	return;
}

# $self->_purge_event_subscriptions($session):
#	Remove every subscription that a disconnecting session
#	holds. Subscriptions are per-connection (HAP-HTTP.md §14).
sub _purge_event_subscriptions ( $self, $session )
{
	my $id = $session->id;

	for my $key ( keys %{ $session->{subscriptions} } ) {
		delete $self->{event_subscriptions}{$key}{$id};
	}
	$session->{subscriptions} = {};

	return;
}

# Queue an event for delivery. Coalesce all events except the
# immediate-delivery characteristic types. Without a $value, the
# current value of the characteristic goes out. The optional
# $originator is the session whose request caused the change.
# That session never receives the event (HAP-HTTP.md §14).
sub queue_event ( $self, $aid, $iid, $value = undef, $originator = undef )
{
	my $char = $self->_resolve_char( $aid, $iid );
	return unless $char;

	$value //= $char->json_value;

	# The immediate types bypass coalescing
	my $char_type = Protocol::HAP::uuid_to_short( $char->{type} // '' );
	if ( IMMEDIATE_EVENT_TYPES->{$char_type} ) {
		$self->send_event( $aid, $iid, $value, $originator );
		return;
	}

	# Queue the event for coalescing
	my $key = "$aid.$iid";
	$self->{event_queue}{$key} = {
		aid        => $aid,
		iid        => $iid,
		value      => $value,
		originator => $originator,
	};

	# Schedule one flush for the whole window through the host's
	# timer contract. A second event inside the window joins the
	# flush that the first one asked for, which is what coalescing
	# means. Without the contract, the host calls flush_events
	# itself.
	if ( $self->{after} ) {
		$self->{event_flush_timer} //= $self->{after}->(
			EVENT_COALESCE_DELAY,
			sub {
				$self->{event_flush_timer} = undef;
				$self->flush_events;
			} );
	}

	return;
}

# $self->flush_events:
#	Send every queued event now. The coalesce timer calls this at
#	the end of the window. A host without the timer contract calls
#	it directly.
sub flush_events ($self)
{
	return unless %{ $self->{event_queue} };

	for my $event ( values %{ $self->{event_queue} } ) {
		$self->send_event(
			$event->{aid},   $event->{iid},
			$event->{value}, $event->{originator} );
	}

	$self->{event_queue} = {};

	# A direct call empties the queue, so the pending timer has
	# nothing left to do. Test the handle for definedness, not
	# truth: the timer contract promises a handle, and a host is
	# free to hand out a false one.
	$self->{cancel}->( $self->{event_flush_timer} )
	    if $self->{cancel} && defined $self->{event_flush_timer};
	$self->{event_flush_timer} = undef;

	return;
}

# Send an EVENT/1.0 notification to the subscribed sessions, through
# the output contract. Do not send it to the originating session when
# the caller gives one (HAP-HTTP.md §14).
sub send_event ( $self, $aid, $iid, $value, $originator = undef )
{
	my $key  = "$aid.$iid";
	my $subs = $self->{event_subscriptions}{$key} // {};

	my $event_body = $self->{json}->encode( {
			characteristics =>
			    [ { aid => $aid, iid => $iid, value => $value } ] }
	);
	my $event_msg = Protocol::HAP::HTTP::build_event($event_body);

	for my $session ( values %$subs ) {
		next unless $session && $session->is_encrypted;
		next if defined $originator && $session == $originator;

		$self->{output}->( $session, $session->encrypt($event_msg) );
	}

	return;
}

# --- identity and discovery -----------------------------------------------

sub is_paired ($self)
{
	my $pairings = $self->{store}->load_pairings;
	return scalar( keys %$pairings ) > 0;
}

sub add_accessory ( $self, $accessory )
{
	$self->{bridge}->add_bridged_accessory($accessory);

	return;
}

sub get_bridged_accessories ($self)
{
	return $self->{bridge}->get_bridged_accessories;
}

sub get_config_number ($self)
{
	return $self->{store}->get_config_number;
}

# $self->update_config_number:
#	Increment c# when the accessory database changed since the
#	last run (HAP-mDNS.md §3.1). The host calls this after
#	device loading. It compares a digest of the accessory
#	structure against the stored one.
sub update_config_number ($self)
{
	my @parts;
	for my $accessory ( $self->{bridge}->get_all_accessories ) {
		push @parts, "a$accessory->{aid}";
		for my $service ( $accessory->get_services ) {
			push @parts,
			    "s$service->{iid}:" . $service->to_json->{type};
			for my $char ( $service->get_characteristics ) {
				push @parts,
				      "c$char->{iid}:"
				    . $char->to_json->{type} . ':'
				    . $char->{format};
			}
		}
	}
	my $digest = unpack( 'H*', sha512( join( ';', @parts ) ) );

	my $stored = $self->{store}->get_config_digest;
	if ( !defined $stored ) {

		# On the first run, record the digest. c# stays at
		# its initial value of 1.
		$self->{store}->save_config_digest($digest);
	}
	elsif ( $stored ne $digest ) {
		$self->{store}->increment_config_number;
		$self->{store}->save_config_digest($digest);
		$self->{logger}
		    ->info( 'Accessory database changed, c# is now %d',
			$self->get_config_number );
	}

	return $self->get_config_number;
}

sub get_device_id ($self)
{
	return Protocol::HAP::device_id( $self->{accessory_ltpk} );
}

# $self->mdns_txt_records:
#	The TXT records of the advertisement, as a hash reference
#	[HAP-mDNS §3]. The host formats and publishes them; the wire
#	format belongs to the host's mDNS responder, not to HAP.
sub mdns_txt_records ($self)
{
	# Note: pv=1, not 1.1. mdnsd uses '.' as the TXT record
	# delimiter and does not support escaping. HomeKit accepts
	# pv=1.
	my $records = {
		'c#' => $self->get_config_number,
		'ff' => 0,
		'id' => $self->get_device_id,
		'md' => $self->{name},
		'pv' => '1',
		's#' => 1,
		'sf' => $self->is_paired ? 0 : 1,
		'ci' => $self->{category},
	};

	# Add the setup hash if setup_id is set
	if ( defined $self->{setup_id} && length( $self->{setup_id} ) == 4 ) {
		$records->{sh} = $self->_get_setup_hash;
	}

	return $records;
}

# _get_setup_hash() - Calculate the setup hash for mDNS
# The hash is the Base64 of the first 4 bytes of
# SHA-512(setupID + deviceID.toUpperCase())
sub _get_setup_hash ($self)
{
	my $setup_id  = $self->{setup_id};
	my $device_id = $self->get_device_id;    # Already uppercase

	my $hash      = sha512( $setup_id . $device_id );
	my $truncated = substr( $hash, 0, 4 );

	# Encode the truncated hash in Base64 without newlines
	my $encoded = encode_base64( $truncated, '' );
	return $encoded;
}

# _regenerate_identity() - Generate new accessory keys after a
# factory reset. The engine calls this after removal of the
# last admin pairing (HAP-Pairing.md §7.2).
sub _regenerate_identity ($self)
{
	my ( $ltsk, $ltpk ) = Protocol::HAP::Crypto->ed25519_keypair;
	$self->{store}->save_accessory_keys( $ltsk, $ltpk );
	$self->{accessory_ltsk} = $ltsk;
	$self->{accessory_ltpk} = $ltpk;

	# Reinitialize the pairing handler with the new keys
	$self->{pairing} = Protocol::HAP::Pairing->new(
		pin            => $self->{pin},
		store          => $self->{store},
		logger         => $self->{logger},
		accessory_ltsk => $self->{accessory_ltsk},
		accessory_ltpk => $self->{accessory_ltpk},
	);

	# Reset the authentication attempt counter
	$self->{pairing}->reset_auth_attempts;

	$self->{logger}->info('Accessory identity regenerated');
	return;
}

1;
