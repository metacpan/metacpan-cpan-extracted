package AnyEvent::Yubico;

use strict;
use AnyEvent::HTTP;
use UUID::Tiny;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use URI::Escape;

our $VERSION = '0.9.3';

# Creates a new Yubico instance to be used for validation of OTPs.
sub new {
	my $class = shift;
	my $self = {
		sign_request => 1,
		local_timeout => 30.0,
		urls => [
			"https://api.yubico.com/wsapi/2.0/verify",
			"https://api2.yubico.com/wsapi/2.0/verify",
			"https://api3.yubico.com/wsapi/2.0/verify",
			"https://api4.yubico.com/wsapi/2.0/verify",
			"https://api5.yubico.com/wsapi/2.0/verify"
		]
	};

	my $options = shift;

	$self = { %$self, %$options };

	return bless $self, $class;
};

# Verifies the given OTP and returns a true value if the OTP could be 
# verified, false otherwise.
sub verify {
	return verify_async(@_)->recv->{status} eq 'OK';
}

# Verifies the given OTP and returns a hash containing the server response.
sub verify_sync {
	return verify_async(@_)->recv
}

# Non-blocking version of verify_sync, which returns a condition variable
# (see AnyEvent->condvar for details).
sub verify_async {
	my($self, $otp, $callback) = @_;

	my $nonce = create_UUID_as_string(UUID_V4);
	$nonce =~ s/-//g;

	my $params = {
		id => $self->{client_id},
		nonce => $nonce,
		otp => $otp
	};

	if(exists $self->{timeout}) {
		$params->{timeout} = $self->{timeout};
	}
	if(exists $self->{sl}) {
		$params->{sl} = $self->{sl};
	}
	if($self->{timestamp}) {
		$params->{timestamp} = 1;
	}

	if($self->{sign_request} and !$self->{api_key} eq '') {
		$params->{h} = $self->sign($params);
	}

	my $query = "";
	for my $key (keys %$params) {
    		$query = "$query&$key=".uri_escape($params->{$key});
    	}
	$query = "?".substr($query, 1);
	
	my $last_response;
	my @requests = ();
	my $result_var = AnyEvent->condvar(cb => $callback);
	my $inner_var = AnyEvent->condvar(cb => sub {
		my $result = shift->recv;

		foreach my $req (@requests) {
			undef $req;
		}

		if(exists $result->{status}) {
			$result_var->send($result);
		} elsif(exists $last_response->{status}) {
			#All responses returned replayed request.
			$result_var->send($last_response);
		} else {
			#Didn't get any valid responses.
			$result_var->croak("No valid response!");
		}
	});

	foreach my $url (@{$self->{urls}}) {
		$inner_var->begin();
		push(@requests, http_get("$url$query", 
				timeout => $self->{local_timeout}, 
				tls_ctx => 'high', 
				sub {
			my($body, $hdr) = @_;

			if(not $hdr->{Status} =~ /^2/) {
				#Error, store message if none exists.
				if(not exists $last_response->{status}) {
					$last_response->{status} = $hdr->{Reason};
				}
				$inner_var->end();
				return;
			}

			my $response = parse_response($body);

			if(! exists $response->{status}) {
				#Response does not look valid, discard.
				$inner_var->end();
				return;
			}

			if(! $self->{api_key} eq '') {
				my $signature = $response->{h};
				delete $response->{h};
				if(! $signature eq $self->sign($response)) {
					$response->{status} = "BAD_RESPONSE_SIGNATURE";
				}
			}

			$last_response = $response;

			if($response->{status} eq "REPLAYED_REQUEST") {
				#Replayed request, wait for next.
				$inner_var->end();
			} else {
				#Definitive response, return it.
				if($response->{status} eq "OK") {
					$inner_var->croak("Response nonce does not match!") if(! $nonce eq $response->{nonce});
					$inner_var->croak("Response OTP does not match!") if(! $otp eq $response->{otp});
				}

				$inner_var->send($response);
			}
		}));
	}

	return $result_var;
};

# Signs a parameter hash using the client API key.
sub sign {
	my ($self, $params) = @_;
	my $content = "";

	foreach my $key (sort keys %$params) {
		$content = $content."&$key=$params->{$key}";
	}
	$content = substr($content, 1);

	my $key = decode_base64($self->{api_key});
	my $signature = encode_base64(hmac_sha1($content, $key), '');

	return $signature;
}

# Parses a response body into a hash.
sub parse_response {
	my $body = shift;
	my $response = {};

	if($body) {
		my @lines = split(' ', $body);
		foreach my $line (@lines) {
			my $index = index($line, '=');
			$response->{substr($line, 0, $index)} = substr($line, $index+1);
		}
	}

	return $response;
}

1;
__END__

=head1 NAME

AnyEvent::Yubico - AnyEvent based Perl extension for validating YubiKey OTPs.
Though AnyEvent is used internally, the module does not impose any particular
coding style on the caller. Provides both blocking and non-blocking methods of 
OTP verification.

=head1 SYNOPSIS

  use AnyEvent::Yubico;
  
  $yk = AnyEvent::Yubico->new({ client_id => 4711, api_key => '<your API key here>' });

  $result = $yk->verify('<YubiKey OTP here>');
  if($result) ...

For more details about the response, instead call verify_sync($otp), which 
returns a hash containing all the parameters that were in the response.

  $result_details = $yk->verify_sync('<YubiKey OTP here>');
  if($result_details->{status} == 'OK') ...


As an alternative, you can call verify_async, which will return a condition 
variable immediately. This can be used if your application already uses an 
asynchronous model. You can also pass a callback as a second parameter to 
verify as well as verify_async, which will be invoked once validation has
completed, with the result.

  $result_cv = $yk->verify_async('<YubiKey OTP here>', sub {
      #Callback invoked when verification is done
      $result_details = shift;
      if($result_details->{status} eq 'OK') ...
  });
  
  #Wait for the result (blocking, same as calling verify directly).
  $result_details = $result_cv->recv;

=head1 DESCRIPTION

Validates a YubiKey OTP (One Time Password) using the YKVAL 2.0 protocol as 
defined here: https://github.com/Yubico/yubikey-val/wiki/ValidationProtocolV20

To use this module, an API key is required, which can be requested here:
https://upgrade.yubico.com/getapikey/

When creating the AnyEvent::Yubico instance, the following arguments can be passed:

=over 4

=item client_id = $id_int

Required. The client ID corresponding to the API key.

=item api_key => $api_key_string

Optional. The API key used to sign requests and verify responses. Without 
this response signatures won't be verified.

=item urls => $array_of_urls

Optional. Defines which validation server URLs to query. The default uses 
the public YubiCloud validation servers. Must support version 2.0 of the 
validation protocol.

Example:

  $yk = AnyEvent::Yubico->new({
      client_id => ...,
      api_key => ...,
      urls => [
          "http://example.com/wsapi/2.0/verify",
          "http://127.0.0.1/wsapi/2.0/verify"
      ]
  });

=item sign_requests => $enable

Optional. When enabled (enabled by default) requests will be signed, as long 
as api_key is also provided.

=item timeout => $seconds

Optional. Timeout parameter sent to the server, see the protocol details for 
more information.

=item sl => $level

Optional. Security level parameter sent to the server, see the protocol 
details for more information.

=item timestamp => $enable

Optional. When enabled, sends the timestamp parameter to the server, causing
YubiKey counter and timestamp information to be returned in the response.

=item local_timeout => $seconds

Optional. Sets the local timeout for how long the verify method will wait 
until failing. The default is 30 seconds.

=back

=head1 SEE ALSO

The Yubico Validation Protocol 2.0 specification:
https://github.com/Yubico/yubikey-val/wiki/ValidationProtocolV20

More information about the YubiKey:
http://www.yubico.com

=head1 AUTHOR

Dain Nilsson, E<lt>dain@yubico.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yubico AB
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
