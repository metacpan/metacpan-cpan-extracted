use v5.42;
use utf8;
use open ':std', ':encoding(UTF-8)';
use lib '../lib';
use At;
use JSON::PP   qw[decode_json];
use Path::Tiny qw[path];

# Initialize client
my $at = At->new( host => 'bsky.social' );

# Attempt to load session from test_auth.json (same as unit tests)
my $auth_file = path('test_auth.json');
if ( $auth_file->exists ) {
    my $auth = decode_json( $auth_file->slurp_raw );
    if ( $auth->{resume} && $auth->{resume}{accessJwt} ) {
        say 'Resuming session...';
        $at->resume( $auth->{resume}{accessJwt}, $auth->{resume}{refreshJwt} );
    }
    elsif ( $auth->{login} && $auth->{login}{identifier} ) {
        say 'Logging in (legacy password auth)...';
        $at->login( $auth->{login}{identifier}, $auth->{login}{password} );
    }
}

# Ensure we are authenticated
unless ( $at->did ) {
    die <<'ERR';
Not authenticated.

Please create a 'test_auth.json' file in the root directory:
{
    "login": {
        "identifier": "your.handle.bsky.social",
        "password": "your-app-password"
    }
}
ERR
}
say 'Authenticated as ' . $at->did;

# Create a simple text post
say 'Sending post...';
my $res = $at->post(
    'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => {
            '$type'   => 'app.bsky.feed.post',
            text      => "Hello from At.pm! 🦋\n\nThis post was generated using the updated Perl client.",
            createdAt => At::_now->to_string
        }
    }
);

# Handle response
if ( $res && !builtin::blessed $res ) {
    say 'Post successful!';
    say 'URI: ' . $res->{uri};
    say 'CID: ' . $res->{cid};
}
else {
    die 'Post failed: ' . $res;
}

=head1 NAME

bsky_legacy.pl - Legacy Authentication Example

=head1 SYNOPSIS

    perl eg/bsky_legacy.pl

=head1 DESCRIPTION

This script demonstrates how to authenticate with Bluesky using the legacy
password-based method (App Passwords). It also shows how to:

=over

=item * Resume a session from a saved file

=item * Login with a handle and app password

=item * Create a simple text post

=back

Note that this login scheme is being replaced by OAuth. See C<eg/bsky_oauth.pl>.

=cut
