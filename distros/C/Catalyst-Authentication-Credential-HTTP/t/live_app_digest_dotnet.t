use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use Test::Needs {
    'Test::WWW::Mechanize::Catalyst' => '0.51',
    'Catalyst::Plugin::Cache' => '0',
    'Cache::FileCache' => undef,
};

plan tests => 19;

use Digest::MD5;
use HTTP::Request;

sub do_test {
    my ($username, $uri, $emulate_dotnet, $fail) = @_;
    my $app = $fail ? 'AuthDigestTestApp' : 'AuthDigestDotnetTestApp';
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => $app);
    $mech->get("http://localhost/moose");
    is( $mech->status, 401, "status is 401" );
    my $www_auth = $mech->res->headers->header('WWW-Authenticate');
    my %www_auth_params = map {
        my @key_val = split /=/, $_, 2;
        $key_val[0] = lc $key_val[0];
        $key_val[1] =~ s{"}{}g;    # remove the quotes
        @key_val;
    } split /, /, substr( $www_auth, 7 );    #7 == length "Digest "
    $mech->content_lacks( "foo", "no output" );
    my $response = '';
    {
        my $password = 'Circle Of Life';
        my $realm    = $www_auth_params{realm};
        my $nonce    = $www_auth_params{nonce};
        my $cnonce   = '0a4f113b';
        my $opaque   = $www_auth_params{opaque};
        my $nc       = '00000001';
        my $method   = 'GET';
        my $qop      = 'auth';
        $uri         ||= '/moose';
        my $auth_uri = $uri;
        if ($emulate_dotnet) {
          $auth_uri =~ s/\?.*//;
        }
        my $ctx = Digest::MD5->new;
        $ctx->add( join( ':', $username, $realm, $password ) );
        my $A1_digest = $ctx->hexdigest;
        $ctx = Digest::MD5->new;
        $ctx->add( join( ':', $method, $auth_uri ) );
        my $A2_digest = $ctx->hexdigest;
        my $digest = Digest::MD5::md5_hex(
            join( ':',
                $A1_digest, $nonce, $qop ? ( $nc, $cnonce, $qop ) : (), $A2_digest )
        );

        $response = qq{Digest username="$username", realm="$realm", nonce="$nonce", uri="$auth_uri", qop=$qop, nc=$nc, cnonce="$cnonce", response="$digest", opaque="$opaque"};
    }
    my $r = HTTP::Request->new( GET => "http://localhost" . $uri );
    $mech->request($r);
    $r->headers->push_header( Authorization => $response );
    $mech->request($r);
    if ($fail) {
      is( $mech->status, 400, "status is 400" );
    } else {
      is( $mech->status, 200, "status is 200" );
      $mech->content_contains( $username, "Mufasa output" );
    }
}

do_test('Mufasa');
do_test('Mufasa2');
# Test with query string
do_test('Mufasa2', '/moose?moose_id=1');
# Test with query string, emulating .NET, which omits the query string
# from the Authorization header
do_test('Mufasa2', '/moose?moose_id=1', 1);

# Test with query string, emulating .NET, against app without .NET setting;
# authorization should fail
do_test('Mufasa2', '/moose?moose_id=1', 1, 1);
