use strict;
use warnings;
use autodie ':all';
use Net::OAuth2::Profile::WebServer;
use JSON::XS qw(decode_json);
use Browser::Open qw(open_browser);
use AnyEvent::Plackup;

# Obtain one at Google Cloud Console <https://cloud.google.com/console>.
my $client_secret = do {
    open my $fh, '<', 'client_secret.json';
    local $/;
    decode_json scalar <$fh>;
};

my $server = plackup(port => 4000);
my $auth = Net::OAuth2::Profile::WebServer->new(
    client_id        => $client_secret->{web}->{client_id},
    client_secret    => $client_secret->{web}->{client_secret},
    authorize_url    => $client_secret->{web}->{auth_uri},
    access_token_url => $client_secret->{web}->{token_uri},
    scope            => 'openid profile',
    redirect_uri     => "http://localhost:$server->{port}/",
);

open_browser $auth->authorize;

my $req = $server->recv;
   $req->respond([ 200, [], [ 'Thank you! Now go back to the console.' ] ]);

my $access_token = $auth->get_access_token($req->parameters->{code});

my $res = $access_token->get('https://www.googleapis.com/oauth2/v1/userinfo');

my $user_info = decode_json $res->decoded_content;

print "Hello, $user_info->{name}.\n";
