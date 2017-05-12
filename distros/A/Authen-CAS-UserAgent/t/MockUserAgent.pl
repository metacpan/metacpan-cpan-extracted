#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use LWP::UserAgent;
use Test::More;

my @responses;

# override LWP::UserAgent->new to force attachment of our request/response interceptor
{
	no warnings 'redefine';
	my $oldnew = \&LWP::UserAgent::new;
	*LWP::UserAgent::new = sub {
		# create object
		my $ua = $oldnew->(@_);

		# attach our response_send handler
		$ua->add_handler('request_send', sub {
			my($request, $ua, $h) = @_;

			# look for a matching response
			my @pairs = @responses;
			foreach (@responses) {
				my $response;
				if(ref($_) eq 'CODE') {
					$response = $_->($request);
				}
				elsif(ref($_) eq 'HASH') {
					$response = $_->{$request->uri};
				}

				if($response) {
					pass('expected request: ' . $request->uri);
					return $response->clone();
				}
			}

			# no response found, return a 500 ISE
			fail('unexpected request: ' . $request->uri);
			return HTTP::Response->new(500);
		});

		return $ua;
	};
}

sub addMockResponses {
	push @responses, @_;
}

sub clearMockResponses {
	@responses = ();
}
