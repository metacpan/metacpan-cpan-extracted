#!perl -T

# This file aims to test the failure of an API call
package CloudFlare::Client::Test;

use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;
use mro 'c3';

use Readonly;
use Try::Tiny;
use Moose; use MooseX::StrictConstructor;

use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::Any;

plan tests => 1;

extends 'CloudFlare::Client';

# Build a simple error response
# Error code
Readonly my $ERR_CODE   => 'E_UNAUTH';
# Full response content
Readonly my $CNT        => { result    => 'error',
                             err_code  => $ERR_CODE,
                             msg       => 'something',};
# Reponse from server
Readonly my $RSP  => HTTP::Response::->new(200);
$RSP->content(JSON::Any::->objToJson($CNT));

# Override the real user agent with a mocked one
# It will always return the error response $RSP
sub _buildUa {
    Readonly my $ua => Test::LWP::UserAgent::->new;
    $ua->map_response( qr{www.cloudflare.com/api_json.html}, $RSP);
    return $ua;}
__PACKAGE__->meta->make_immutable;

# Test upstream failure
# Catch potential failure
Readonly my $API => try {
        CloudFlare::Client::Test::->new( user => 'user', apikey  => 'KEY')}
    catch { diag $_ };
# Valid values
Readonly my $ZONE  => 'zone.co.uk';
Readonly my $ITRVL => 20;
throws_ok { $API->action( z => $ZONE, interval => $ITRVL )}
          'CloudFlare::Client::Exception::Upstream',
          "methods die with an invalid response";
