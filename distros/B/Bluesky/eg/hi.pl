use v5.40;
use blib;
$|++;
use Bluesky;
use JSON::PP;
#
my $bsky = Bluesky->new();
if ( my $config = session() ) {
    try {
        my $res = $bsky->resume( map { $config->{$_} } qw[accessJwt refreshJwt token_type dpop_key_jwk client_id handle pds scope] );
        if ( $bsky->session && builtin::blessed( $bsky->session ) && $bsky->session->isa('At::Protocol::Session') ) {
            my $access = $bsky->at->_decode_token( $bsky->session->accessJwt );
            if ( $access && time > $access->{exp} ) {
                $bsky->at->oauth_refresh;
                session( $bsky->session );
            }
        }
    }
    catch ($e) {
        oauth();
    };
}
else {
    oauth();
}

# Posting
my $post = $bsky->createPost( text => 'Hello from Perl!' );
say sprintf 'New post at https://bsky.app/profile/%s/post/%s', $bsky->session->handle, $post->{uri}->rkey if $post;

sub oauth() {
    $bsky->oauth_helper(
        handle     => 'atperl.bsky.social',
        scope      => 'atproto transition:generic transition:chat.bsky',
        listen     => 1,                                                   # Automatically catch the redirect
        on_success => sub {
            say 'Logged in!';
            session( $bsky->session );
        }
    );
}

sub session ( $sesh //= () ) {
    state $session //= 'session.json';
    state $json    //= JSON::PP->new->ascii->pretty->allow_nonref;
    state $config;
    if ( defined $sesh ) {
        $config = $sesh->_raw;
        open my $fh, '>', $session or die "Can't open output.txt: $!";
        print {$fh} $json->encode($config);
        close $fh;
    }
    else {
        open my $fh, '<:encoding(UTF-8)', $session or die $!;
        local $/;
        $config = $json->decode(<$fh>);
    }
    $config;
}
