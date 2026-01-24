use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib '../lib';
use At;
use URI;
use URI::QueryParam;
use JSON::PP   qw[decode_json encode_json];
use Path::Tiny qw[path];
$|++;

# Initialize client
my $at = At->new( host => 'bsky.social' );

# Attempt to load session from test_auth.json
my $auth_file = path('test_auth.json');
my $auth      = $auth_file->exists ? decode_json( $auth_file->slurp_raw ) : {};
if ( $auth->{oauth} && $auth->{oauth}{accessJwt} ) {
    say 'Resuming OAuth session...';
    $at->resume(
        $auth->{oauth}{accessJwt}, $auth->{oauth}{refreshJwt}, $auth->{oauth}{token_type}, $auth->{oauth}{dpop_key_jwk},
        $auth->{oauth}{client_id}, $auth->{oauth}{handle},     $auth->{oauth}{pds}
    );
}

# Ensure we are authenticated
unless ( $at->did ) {
    my $handle = $auth->{login}{identifier} || die <<'ERR';
No authentication info found in 'test_auth.json'.

Please create it with at least a handle:
{
    "login": {
        "identifier": "your.handle.bsky.social"
    }
}
ERR
    say 'Discovering and starting OAuth flow for ' . $handle . '...';
    my $REDIRECT_URI  = 'http://127.0.0.1:8888/';
    my $SCOPE         = 'atproto transition:generic';
    my $client_id_uri = URI->new('http://localhost');
    $client_id_uri->query_param( scope        => $SCOPE );
    $client_id_uri->query_param( redirect_uri => $REDIRECT_URI );
    my $CLIENT_ID = $client_id_uri->as_string;
    my $auth_url  = $at->oauth_start( $handle, $CLIENT_ID, $REDIRECT_URI, $SCOPE );
    say 'Open this URL: ' . $auth_url;
    say 'Paste callback URL:';
    print '> ';
    my $callback_url_str = <STDIN>;
    chomp $callback_url_str;
    my $cb_uri = URI->new($callback_url_str);
    my $code   = $cb_uri->query_param('code');
    my $state  = $cb_uri->query_param('state');
    say 'Exchanging token...';
    $at->oauth_callback( $code, $state );

    # Save session back to file
    $auth->{oauth} = $at->session->_raw;
    $auth_file->spew_raw( encode_json($auth) );
    say '   Session saved to test_auth.json';
}
say 'Authenticated as ' . $at->did;
say 'Testing Read Access (listRecords)...';
my $ident = $at->get( 'com.atproto.repo.listRecords', { repo => $at->did, collection => 'app.bsky.feed.post', limit => 1 } );
if ( builtin::blessed($ident) && $ident->isa('At::Error') ) {
    say '   Read failed: ' . $ident;
}
else {
    say '   Read OK. Found ' . scalar( @{ $ident->{records} } ) . ' posts.';
}
say 'Testing Write Access (createRecord)...';
my $res = $at->post(
    'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => 'Hello from At.pm via OAuth! 🦋', createdAt => At::_now->to_string }
    }
);
if ( $res && !builtin::blessed $res ) {
    say '   Post created! CID: ' . $res->{cid};
}
else {
    my $err_msg = builtin::blessed($res) && $res->isa('At::Error') ? $res->message : "$res";
    say '   Post failed: ' . $err_msg;
}

=head1 NAME

bsky_oauth.pl - OAuth Authentication Example

=head1 SYNOPSIS

    perl eg/bsky_oauth.pl

=head1 DESCRIPTION

This script demonstrates the OAuth authentication flow in a CLI environment.
Since OAuth requires a redirect, this script uses the "loopback" client ID method.
It prints the authorization URL, asks you to open it, and then requests the
redirected URL (containing the code) to be pasted back into the terminal.

It verifies:

=over

=item * OAuth flow (start -> callback -> token exchange)

=item * Session persistence (saving/loading tokens)

=item * Read access (listRecords)

=item * Write access (createRecord)

=back

For an example that uses a tiny, local webserver to gather the tokens instead,
see C<eg/mojo_oauth.pl>.

=cut
