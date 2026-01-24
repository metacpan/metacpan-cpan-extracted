use v5.42;
use lib '../lib', 'lib';
use At;
use Mojolicious::Lite;
use URI;
$|++;
#
# Configuration
my $handle = 'atperl.bsky.social';
my $scope  = 'atproto transition:generic';
my $port   = 8888;
my $redir  = "http://127.0.0.1:$port/callback";

# Initialize client with Mojo UA
my $ua = At::UserAgent::Mojo->new;
my $at = At->new( http => $ua );

# Build the magic localhost Client ID
my $client_id = URI->new('http://localhost');
$client_id->query_param( scope        => $scope );
$client_id->query_param( redirect_uri => $redir );
say 'At.pm OAuth Demo (Mojo)';
say "Starting OAuth flow for $handle...";
my $auth_url = $at->oauth_start( $handle, $client_id->as_string, $redir, $scope );
say "Please open this URL in your browser:";
say "\n   $auth_url\n";
say "Waiting for redirect to $redir ...";

# Setup Mojo App to listen for the redirect
get '/callback' => sub ($c) {
    my $code  = $c->param('code');
    my $state = $c->param('state');
    return $c->render( text => "Error: Missing code or state parameters.", status => 400 ) unless $code && $state;
    say 'Exchanging code for tokens...';
    try {
        $at->oauth_callback( $code, $state );
    }
    catch ($e) {
        $c->app->log->error( 'OAuth Callback failed: ' . $e );
        return $c->render( text => 'OAuth Callback failed: ' . $e, status => 500 );
    }
    say '   Authenticated as: ' . $at->did;
    say 'Fetching your profile...';
    my $profile;
    try {
        $profile = $at->get( 'app.bsky.actor.getProfile', { actor => $at->did } );
    }
    catch ($e) {
        $c->app->log->error( 'Failed to fetch profile: ' . $e );
        return $c->render( text => 'Authenticated, but failed to fetch profile: ' . $@, status => 500 );
    }
    say '   Display Name: ' . $profile->{displayName};
    say '   Description:  ' . ( $profile->{description} // '[no description]' );
    $c->render( text => '<h1>Success!</h1><p>You are authenticated as <b>' .
            $profile->{displayName} . '</b>.</p><p>You can close this window and check the console.</p>' );

    # Gracefully stop the server
    Mojo::IOLoop->timer( 1 => sub { exit 0 } );
};
app->start( 'daemon', '-l', 'http://127.0.0.1:' . $port );

=head1 NAME

mojo_oauth.pl - OAuth Authentication Example Using Mojolicious

=head1 SYNOPSIS

    perl eg/mojo_oauth.pl

=head1 DESCRIPTION

A more advanced OAuth example that spins up a temporary local web server to
catch tokens.

Instead of copy and pasting URLs back and forth like in C<eg/bsky_oauth.pl>,
this script acts as a real web client:

=cut
