use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request;
use JSON;

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'base';
}

{

    package MyTestApp;
    use Dancer2;
    use Dancer2::Plugin::Github::Webhook;

    set serializer => 'JSON';

    post '/' => require_github_webhook_secret sub { [1] };
    post '/a' => require_github_webhook_secret config->{'github-webhooks'}->{endpoint_a} => sub { [1] };
    post '/b' => require_github_webhook_secret config->{'github-webhooks'}->{endpoint_b} => sub { [1] };
    post '/c' => require_github_webhook_secret 'anotherverysecretsecret'                 => sub { [1] };

}

my $app = MyTestApp->to_app;

test_psgi $app, sub {
    my $cb = shift;

    {
        # no X-Hub-Signature

        my $req = HTTP::Request->new( POST => '/' );
        my $res = $cb->($req);
        is $res->code, 403, 'Forbidden if no signature is sent';
        ok JSON::from_json( $res->content )->{message} eq 'No X-Hub-Signature found', 'Got message "No X-Hub-Signature found"';
    }

    {
        # wrong signature

        my $req = HTTP::Request->new( POST => '/' => [ 'X-Hub-Signature' => 1 ] );
        my $res = $cb->($req);
        is $res->code, 403, 'Forbidden if wrong signature is sent';
        ok JSON::from_json( $res->content )->{message} eq 'Not allowed', 'Got message "Not allowed" when using wrong signature';
    }

    {
        # correct signature

        my $content = JSON::to_json( { some => 'content' } );
        require Digest::SHA;
        my $signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $content, 'super!s3cret?' );
        my $req = HTTP::Request->new( POST => '/' => [ 'X-Hub-Signature' => $signature ], $content );
        my $res = $cb->($req);
        is $res->code, 200, 'Correct signature is accepted';
        ok JSON::from_json( $res->content )->[0] eq '1', 'Correct signature is accepted';
    }

    {
        # correct signature

        my $content = JSON::to_json( { some => 'content', random => int(rand(1000)) * 11 } );
        require Digest::SHA;
        my $signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $content, 'anotherverysecretsecret' );
        my $req = HTTP::Request->new( POST => '/c' => [ 'X-Hub-Signature' => $signature ], $content );
        my $res = $cb->($req);
        is $res->code, 200, 'Correct signature is accepted';
        ok JSON::from_json( $res->content )->[0] eq '1', 'Correct signature is accepted';
    }

    {
        # correct signature, other endpoint
        
        my $content = JSON::to_json( { some => 'other', content => [qw/here in this array/] } );
        require Digest::SHA;
        my $signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $content, 'sk78fozuhv3efgv' );
        my $req = HTTP::Request->new( POST => '/a' => [ 'X-Hub-Signature' => $signature ], $content );
        my $res = $cb->($req);
        is $res->code, 200, 'Correct signature is accepted';
        ok JSON::from_json( $res->content )->[0] eq '1', 'Correct signature is accepted';
    }

    {
        # wrong signature

        my $content = JSON::to_json( { some => 'other', content => [qw/here in this array/] } );
        require Digest::SHA;
        my $signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $content, 'sk78fozuhv3efgv' );
        my $req = HTTP::Request->new( POST => '/b' => [ 'X-Hub-Signature' => $signature ], $content );
        my $res = $cb->($req);
        is $res->code, 403, 'Forbidden if wrong signature is sent';
        ok JSON::from_json( $res->content )->{message} eq 'Not allowed', 'Got message "Not allowed" when using wrong signature';
    }


};

done_testing();
