use v5.42;
use feature 'class';
no warnings 'experimental::class', 'experimental::builtin', 'experimental::for_list';    # Be quiet.

#~ |---------------------------------------|
#~ |------3-33-----------------------------|
#~ |-5-55------4-44-5-55----353--3-33-/1~--|
#~ |---------------------335---33----------|
class At 1.1 {
    use Carp qw[];
    use experimental 'try';
    use File::ShareDir::Tiny qw[dist_dir];
    use JSON::PP             qw[decode_json encode_json];
    use Path::Tiny           qw[path];
    use Digest::SHA          qw[sha256];
    use MIME::Base64         qw[encode_base64url];
    use Crypt::PK::ECC;
    use Crypt::PRNG qw[random_string];
    use Time::Moment;    # Internal; standardize around Zulu
    use URI;
    use warnings::register;
    use At::Error;
    use At::Protocol::URI;
    use At::Protocol::Session;
    use At::UserAgent;
    field $share    : reader : param = ();
    field %lexicons : reader;
    field $http     : reader : param = ();
    field $lexicon_paths_param : param(lexicon_paths) = [];
    field @lexicon_paths;
    field $host : param : reader //= 'bsky.social';
    method set_host ($new) { $host = $new }
    field $session = ();
    field $oauth_state;
    field $dpop_key;
    field %ratelimits : reader = (    # https://docs.bsky.app/docs/advanced-guides/rate-limits
        global        => {},
        updateHandle  => {},          # per DID
        createSession => {},          # per handle
        deleteAccount => {},          # by IP
        resetPassword => {}           # by IP
    );
    ADJUST {
        if ( !defined $share ) {
            try { $share = dist_dir('At') }
            catch ($e) { $share = 'share' }
        }
        $share = path($share) unless builtin::blessed $share;
        @lexicon_paths = map { path($_) } ( ref $lexicon_paths_param eq 'ARRAY' ? @$lexicon_paths_param : ($lexicon_paths_param) );
        if ( !defined $http ) {
            my $ua_class;
            try {
                require Mojo::UserAgent;
                $ua_class = 'At::UserAgent::Mojo';
            }
            catch ($e) {
                $ua_class = 'At::UserAgent::Tiny';
            }
            $http = $ua_class->new();
        }
        $host = 'https://' . $host unless $host =~ /^https?:/;
        $host = URI->new($host)    unless builtin::blessed $host;
    }

    # OAuth Implementation
    method _get_dpop_key() {
        unless ($dpop_key) {
            $dpop_key = Crypt::PK::ECC->new();
            $dpop_key->generate_key('secp256r1');
        }
        return $dpop_key;
    }

    method oauth_discover ($handle) {
        my $res = $self->resolve_handle($handle);
        if ( builtin::blessed($res) && $res->isa('At::Error') ) { $res->throw; }
        return unless $res && $res->{did};
        my $pds = $self->pds_for_did( $res->{did} );
        unless ($pds) { die "Could not resolve PDS for DID: " . $res->{did}; }
        my ($protected) = $http->get("$pds/.well-known/oauth-protected-resource");
        if ( builtin::blessed($protected) && $protected->isa('At::Error') ) { $protected->throw; }
        return unless $protected && $protected->{authorization_servers};
        my $auth_server = $protected->{authorization_servers}[0];
        my ($metadata) = $http->get("$auth_server/.well-known/oauth-authorization-server");
        if ( builtin::blessed($metadata) && $metadata->isa('At::Error') ) { $metadata->throw; }
        return { pds => $pds, auth_server => $auth_server, metadata => $metadata, did => $res->{did} };
    }

    method oauth_start ( $handle, $client_id, $redirect_uri, $scope = 'atproto' ) {
        my $discovery = $self->oauth_discover($handle);
        die "Failed to discover OAuth metadata for $handle" unless $discovery;
        my $chars          = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
        my $code_verifier  = Crypt::PRNG::random_string_from( $chars, 43 );
        my $code_challenge = encode_base64url( sha256($code_verifier) );
        $code_challenge =~ s/=+$//;
        my $state = Crypt::PRNG::random_string_from( $chars, 16 );
        $oauth_state = {
            discovery     => $discovery,
            code_verifier => $code_verifier,
            state         => $state,
            redirect_uri  => $redirect_uri,
            client_id     => $client_id,
            handle        => $handle,
            scope         => $scope
        };

        # Prepare UA for DPoP
        $http->set_tokens( undef, undef, 'DPoP', $self->_get_dpop_key() );
        my $par_endpoint = $discovery->{metadata}{pushed_authorization_request_endpoint};
        my ($par_res) = $http->post(
            $par_endpoint => {
                headers  => { DPoP => $http->_generate_dpop_proof( $par_endpoint, 'POST' ) },
                encoding => 'form',
                content  => {
                    client_id             => $client_id,
                    response_type         => 'code',
                    code_challenge        => $code_challenge,
                    code_challenge_method => 'S256',
                    redirect_uri          => $redirect_uri,
                    state                 => $state,
                    scope                 => $scope,
                    aud                   => $discovery->{pds},
                }
            }
        );
        die 'PAR failed: ' . ( $par_res . "" ) if builtin::blessed $par_res;
        my $auth_uri = URI->new( $discovery->{metadata}{authorization_endpoint} );
        $auth_uri->query_form( client_id => $client_id, request_uri => $par_res->{request_uri} );
        return $auth_uri->as_string;
    }

    method oauth_callback ( $code, $state ) {
        die 'OAuth state mismatch' unless $oauth_state && $state eq $oauth_state->{state};
        my $token_endpoint = $oauth_state->{discovery}{metadata}{token_endpoint};
        my $key            = $self->_get_dpop_key();
        my ($token_res)    = $http->post(
            $token_endpoint => {
                headers  => { DPoP => $http->_generate_dpop_proof( $token_endpoint, 'POST' ) },
                encoding => 'form',
                content  => {
                    grant_type    => 'authorization_code',
                    code          => $code,
                    client_id     => $oauth_state->{client_id},
                    redirect_uri  => $oauth_state->{redirect_uri},
                    code_verifier => $oauth_state->{code_verifier},
                    aud           => $oauth_state->{discovery}{pds}
                }
            }
        );
        die 'Token exchange failed: ' . ( $token_res . "" ) if builtin::blessed $token_res;
        $session = At::Protocol::Session->new(
            did          => $token_res->{sub},
            accessJwt    => $token_res->{access_token},
            refreshJwt   => $token_res->{refresh_token},
            handle       => $oauth_state->{handle},
            token_type   => 'DPoP',
            dpop_key_jwk => $key->export_key_jwk('private'),
            client_id    => $oauth_state->{client_id},
            scope        => $token_res->{scope},
            pds          => $oauth_state->{discovery}{pds}
        );
        $self->set_host( $oauth_state->{discovery}{pds} );
        $http->set_tokens( $token_res->{access_token}, $token_res->{refresh_token}, 'DPoP', $key );
    }

    method oauth_refresh() {
        return unless $session && $session->refreshJwt && $session->token_type eq 'DPoP';
        my $discovery = $self->oauth_discover( $session->handle );
        return unless $discovery;
        my $token_endpoint = $discovery->{metadata}{token_endpoint};
        my $key            = $self->_get_dpop_key();
        my ($token_res)    = $http->post(
            $token_endpoint => {
                headers  => { DPoP => $http->_generate_dpop_proof( $token_endpoint, 'POST' ) },
                encoding => 'form',
                content  => {
                    grant_type    => 'refresh_token',
                    refresh_token => $session->refreshJwt,
                    client_id     => $session->client_id // '',
                    aud           => $discovery->{pds},
                }
            }
        );
        die "Refresh failed: " . ( $token_res . "" ) if builtin::blessed $token_res;
        $session = At::Protocol::Session->new(
            did          => $token_res->{sub},
            accessJwt    => $token_res->{access_token},
            refreshJwt   => $token_res->{refresh_token},
            handle       => $session->handle,
            token_type   => 'DPoP',
            dpop_key_jwk => $key->export_key_jwk('private'),
            client_id    => $session->client_id,
            scope        => $token_res->{scope},
            pds          => $discovery->{pds}
        );
        $self->set_host( $discovery->{pds} );
        return $http->set_tokens( $token_res->{access_token}, $token_res->{refresh_token}, 'DPoP', $key );
    }

    method collection_scope ( $collection, $action = 'create' ) {
        return "repo:$collection?action=$action";
    }

    # Legacy Auth
    method login( $identifier, $password ) {
        warnings::warnif( At => 'login() (com.atproto.server.createSession) is deprecated. Please use OAuth instead.' );
        my $res = $self->post( 'com.atproto.server.createSession' => { identifier => $identifier, password => $password } );
        if   ( $res && !builtin::blessed($res) ) { $session = At::Protocol::Session->new(%$res); }
        else                                     { $session = $res; }
        return $session ? $http->set_tokens( $session->accessJwt, $session->refreshJwt, undef, undef ) : $session;
    }

    method resume ( $accessJwt, $refreshJwt, $token_type = 'Bearer', $dpop_key_jwk = (), $client_id = (), $handle = (), $pds = () ) {
        my $access  = $self->_decode_token($accessJwt);
        my $refresh = $self->_decode_token($refreshJwt);
        return unless $access;
        my $key;
        if ( $token_type eq 'DPoP' && $dpop_key_jwk ) {
            $key = Crypt::PK::ECC->new();
            $key->import_key( \$dpop_key_jwk );
            $dpop_key = $key;
        }
        if ( $refresh && time > $access->{exp} && time < $refresh->{exp} ) {
            if ( $token_type eq 'DPoP' ) { return $self->oauth_refresh(); }
            else {
                my $res = $self->post( 'com.atproto.server.refreshSession' => { refreshJwt => $refreshJwt } );
                if   ( $res && !builtin::blessed($res) ) { $session = At::Protocol::Session->new(%$res); }
                else                                     { $session = $res; }
                return $session ? $http->set_tokens( $session->accessJwt, $session->refreshJwt, $token_type, $key ) : $session;
            }
        }
        $session = At::Protocol::Session->new(
            did          => $access->{sub},
            accessJwt    => $accessJwt,
            refreshJwt   => $refreshJwt,
            token_type   => $token_type,
            dpop_key_jwk => $dpop_key_jwk,
            client_id    => $client_id,
            handle       => $handle,
            pds          => $pds
        );
        $self->set_host($pds) if $pds;
        return $http->set_tokens( $accessJwt, $refreshJwt, $token_type, $key );
    }

    method _decode_token ($token) {
        return unless defined $token;
        use MIME::Base64 qw[decode_base64];
        my ( $header, $payload, $sig ) = split /\./, $token;
        return unless defined $payload;
        $payload =~ tr[-_][+/];
        try {
            return decode_json decode_base64 $payload;
        }
        catch ($e) {
            return;
        }
    }

    # XRPC & Lexicons
    method _locate_lexicon($fqdn) {
        unless ( defined $lexicons{$fqdn} ) {
            my $base_fqdn = $fqdn =~ s[#(.+)$][]r;
            my @namespace = split /\./, $base_fqdn;
            my @search    = (
                @lexicon_paths,
                $share->child('lexicons'),
                defined $ENV{HOME} ? path( $ENV{HOME}, '.cache', 'atproto', 'lexicons' ) : (),
                path( 'share', 'lexicons' )
            );
            my $lex_file;
            for my $dir (@search) {
                next unless defined $dir;
                my $possible = $dir->child( @namespace[ 0 .. $#namespace - 1 ], $namespace[-1] . '.json' );
                if ( $possible->exists ) { $lex_file = $possible; last; }
            }
            if ( !$lex_file ) { $lex_file = $self->_fetch_lexicon($base_fqdn); }
            if ( $lex_file && $lex_file->exists ) {
                my $json = decode_json $lex_file->slurp_raw;
                for my $def ( keys %{ $json->{defs} } ) {
                    $lexicons{ $base_fqdn . ( $def eq 'main' ? '' : '#' . $def ) } = $json->{defs}{$def};
                    $lexicons{ $base_fqdn . '#main' } = $json->{defs}{$def} if $def eq 'main';
                }
            }
        }
        $lexicons{$fqdn};
    }

    method _fetch_lexicon($base_fqdn) {
        my @namespace = split /\./, $base_fqdn;
        my $rel_path  = join( '/', @namespace[ 0 .. $#namespace - 1 ], $namespace[-1] . '.json' );
        my $url       = "https://raw.githubusercontent.com/bluesky-social/atproto/main/lexicons/$rel_path";
        my ( $content, $headers ) = $http->get($url);
        if ( $content && !builtin::blessed($content) ) {
            my $cache_dir = defined $ENV{HOME} ? path( $ENV{HOME}, '.cache', 'atproto', 'lexicons' ) : path( '.cache', 'atproto', 'lexicons' );
            $cache_dir->mkpath;
            my $lex_file = $cache_dir->child( @namespace[ 0 .. $#namespace - 1 ], $namespace[-1] . '.json' );
            $lex_file->parent->mkpath;
            $lex_file->spew_raw( builtin::blessed($content) ? encode_json($content) : $content );
            return $lex_file;
        }
        return;
    }

    method get( $fqdn, $args = (), $headers = {} ) {
        my $lexicon  = $self->_locate_lexicon($fqdn);
        my $category = $fqdn =~ /^com\.atproto\.repo\./ ? 'repo'                          : 'global';
        my $meta     = $category eq 'repo'              ? ( $args->{repo} // $self->did ) : ();
        $self->_ratecheck( $category, $meta );
        my ( $content, $res_headers )
            = $http->get( sprintf( '%s/xrpc/%s', $host, $fqdn ), { defined $args ? ( content => $args ) : (), headers => $headers } );
        $self->ratelimit_( $res_headers, $category, $meta );
        if ( $lexicon && !builtin::blessed $content ) {
            $content = $self->_coerce( $fqdn, $lexicon->{output}{schema}, $content );
        }
        wantarray ? ( $content, $res_headers ) : $content;
    }

    method post( $fqdn, $args = (), $headers = {} ) {
        my @namespace = split /\./, $fqdn;
        my $lexicon   = $self->_locate_lexicon($fqdn);

        # Categorize according to bsky specs
        my $category = 'global';
        my $meta     = ();
        if ( $fqdn =~ /^com\.atproto\.server\.createSession$/ ) {
            $category = 'auth';
            $meta     = $args->{identifier};
        }
        elsif ( $fqdn =~ /^com\.atproto\.repo\./ ) {
            $category = 'repo';
            $meta     = $args->{repo} // $self->did;
        }
        elsif ( $namespace[-1] =~ m[^(updateHandle|createAccount|deleteAccount|resetPassword)$] ) {
            $category = $namespace[-1];
            $meta     = $args->{did} // $args->{handle} // $args->{email};
        }
        $self->_ratecheck( $category, $meta );
        my ( $content, $res_headers )
            = $http->post( sprintf( '%s/xrpc/%s', $host, $fqdn ), { defined $args ? ( content => $args ) : (), headers => $headers } );
        $self->ratelimit_( $res_headers, $category, $meta );
        if ( $lexicon && !builtin::blessed $content ) {
            $content = $self->_coerce( $fqdn, $lexicon->{output}{schema}, $content );
        }
        return wantarray ? ( $content, $res_headers ) : $content;
    }
    method subscribe( $id, $cb ) { $self->http->websocket( sprintf( '%s/xrpc/%s', $host, $id ), $cb ); }

    method firehose ( $callback, $url = () ) {
        require At::Protocol::Firehose;
        return At::Protocol::Firehose->new( at => $self, callback => $callback, defined $url ? ( url => $url ) : () );
    }

    # Coercion Logic
    my %coercions = (
        array => method( $namespace, $schema, $data ) {
            [ map { $self->_coerce( $namespace, $schema->{items}, $_ ) } @$data ]
        },
        boolean => method( $namespace, $schema, $data ) { !!$data },
        bytes   => method( $namespace, $schema, $data ) {$data},
        blob    => method( $namespace, $schema, $data ) {$data},
        integer => method( $namespace, $schema, $data ) { int $data },
        object  => method( $namespace, $schema, $data ) {
            for my ( $name, $subschema )( %{ $schema->{properties} } ) {
                $data->{$name} = $self->_coerce( $namespace, $subschema, $data->{$name} );
            }
            $data;
        },
        ref => method( $namespace, $schema, $data ) {
            my $target_namespace = $self->_resolve_namespace( $namespace, $schema->{ref} );
            my $lexicon          = $self->_locate_lexicon($target_namespace);
            return $data unless $lexicon;
            $self->_coerce( $target_namespace, $lexicon, $data );
        },
        union   => method( $namespace, $schema, $data ) {$data},
        unknown => method( $namespace, $schema, $data ) {$data},
        string  => method( $namespace, $schema, $data ) {
            $data // return ();
            if ( defined $schema->{format} ) {
                if    ( $schema->{format} eq 'uri' )    { return URI->new($data); }
                elsif ( $schema->{format} eq 'at-uri' ) { return At::Protocol::URI->new($data); }
                elsif ( $schema->{format} eq 'datetime' ) {
                    return $data =~ /\D/ ? Time::Moment->from_string($data) : Time::Moment->from_epoch($data);
                }
                elsif ( $schema->{format} eq 'did' ) {
                    require At::Protocol::DID;
                    return At::Protocol::DID->new($data);
                }
                elsif ( $schema->{format} eq 'handle' ) {
                    require At::Protocol::Handle;
                    return At::Protocol::Handle->new($data);
                }
            }
            $data;
        }
    );

    method _coerce ( $namespace, $schema, $data ) {
        $data // return ();
        return $coercions{ $schema->{type} }->( $self, $namespace, $schema, $data ) if defined $coercions{ $schema->{type} };
        return $data;
    }

    method _resolve_namespace ( $l, $r ) {
        return $r      if $r =~ m[.+#];
        return $` . $r if $l =~ m[#.+];
        $l . $r;
    }

    # Identity & Helpers
    method did()                   { $session ? $session->did . "" : undef; }
    method resolve_handle($handle) { $self->get( 'com.atproto.identity.resolveHandle' => { handle => $handle } ); }

    method resolve_did ($did) {
        if ( $did =~ /^did:plc:(.+)$/ ) {
            my ($content) = $http->get("https://plc.directory/$did");
            return $content;
        }
        elsif ( $did =~ /^did:web:(.+)$/ ) {
            my $domain = $1;
            $domain =~ s/:/\//g;
            my ($content) = $http->get("https://$domain/.well-known/did.json");
            return $content;
        }
        return;
    }

    method pds_for_did ($did) {
        my $doc = $self->resolve_did($did);
        return unless $doc && ref $doc eq 'HASH' && $doc->{service};
        for my $service ( @{ $doc->{service} } ) {
            return $service->{serviceEndpoint} if $service->{type} eq 'AtprotoPersonalDataServer';
        }
        return;
    }
    method session()            { $session //= $self->get('com.atproto.server.getSession'); $session; }
    sub _now                    { Time::Moment->now }
    method _duration ($seconds) { $seconds || return '0 seconds'; $seconds = abs $seconds; return "$seconds seconds"; }

    method ratelimit_ ( $headers, $type, $meta //= () ) {
        my %h = map { lc($_) => $headers->{$_} } keys %$headers;
        return unless exists $h{'ratelimit-limit'};
        my $rate = {
            limit     => $h{'ratelimit-limit'},
            remaining => $h{'ratelimit-remaining'},
            reset     => $h{'ratelimit-reset'},
            policy    => $h{'ratelimit-policy'},
        };
        defined $meta ? $ratelimits{$type}{$meta} = $rate : $ratelimits{$type} = $rate;
    }

    method _ratecheck( $type, $meta //= () ) {
        my $rate = defined $meta ? $ratelimits{$type}{$meta} : $ratelimits{$type};
        return unless $rate && $rate->{reset};
        if ( $rate->{remaining} <= 0 && time < $rate->{reset} ) {
            my $wait = $rate->{reset} - time;
            warnings::warnif( At => "Rate limit exceeded for $type. Reset in $wait seconds." );
        }
        elsif ( $rate->{remaining} < ( $rate->{limit} * 0.1 ) ) {
            warnings::warnif( At => "Approaching rate limit for $type ($rate->{remaining} remaining)." );
        }
    }
}
1;
__END__

=pod

=encoding utf-8

=head1 NAME

At - The AT Protocol for Social Networking

=head1 SYNOPSIS

    use At;
    my $at = At->new( host => 'bsky.social' );

    # Authentication (The Modern Way)
    my $auth_url = $at->oauth_start( 'user.bsky.social', 'http://localhost', 'http://127.0.0.1:8888/' );
    # ... Redirect user to $auth_url, then get $code and $state from callback ...
    $at->oauth_callback( $code, $state );

    # Creating a Post
    $at->post( 'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => {
            text      => 'Hello from Perl!',
            createdAt => At::_now->to_string
        }
    });

    # Streaming the Firehose
    my $fh = $at->firehose(sub ( $header, $body, $err ) {
        return warn $err if $err;
        say "New event: " . $header->{t};
    });
    $fh->start();
    # ... Start event loop (e.g. Mojo::IOLoop->start) ...

=head1 DESCRIPTION

At.pm is a toolkit for interacting with the AT Protocol which powers decentralized social networks like Bluesky.

Unless you're designing a new client around the AT Protocol, you are probably looking for L<Bluesky.pm|Bluesky>.

=head2 Rate Limits

At.pm attempts to keep track of rate limits according to the protocol's specs. Requests are categorized (C<auth>,
C<repo>, C<global>) and tracked per-identifier.

If you approach a limit (less than 10% remaining), a warning is issued. If you exceed a limit, a warning is issued with
the time until reset.

See L<https://docs.bsky.app/docs/advanced-guides/rate-limits>

=head1 Getting Started

If you are new to the AT Protocol, the first thing to understand is that it is decentralized. Your data lives on a
Personal Data Server (PDS), but your identity is portable.

=head2 Identity (Handles and DIDs)

=over

=item * B<Handle>: A human-friendly name like C<alice.bsky.social>.

=item * B<DID>: A persistent, machine-friendly identifier like C<did:plc:z72i7...>.

=back

=head1 Authentication and Session Management

There are two ways to authenticate: the modern OAuth system and the legacy password system. Once authenticated, all
other methods (like C<get>, C<post>, and C<subscribe>) work the same way.

Developers of new code should be aware that the AT protocol is transitioning to OAuth and this library strongly
encourages its use.

=head2 The OAuth System (Recommended)

OAuth is the secure, modern way to authenticate. It uses DPoP (Demonstrating Proof-of-Possession) to ensure tokens
cannot be stolen and reused. It's a three step process:

=over

=item 1. Start the flow:

    my $auth_url = $at->oauth_start(
        'user.bsky.social',
        'http://localhost',                  # Client ID
        'http://127.0.0.1:8888/callback',    # Redirect URI
        'atproto transition:generic'         # Scopes
    );

=item 2. Redirect the user:

Open C<$auth_url> in a browser. After they approve, they will be redirected to your callback URL with C<code> and
C<state> parameters.

=item 3. Complete the callback:

    $at->oauth_callback( $code, $state );

See the demonstration scripts C<eg/bsky_oauth.pl> and C<eg/mojo_oauth.pl> for both a CLI and web based examples.

=back

Once authenticated, you should store your session data securely so you can resume it later without requiring the user
to log in again.

=head3 Resuming an OAuth Session

You need to store the tokens, the DPoP key, and the PDS endpoint. The C<_raw> method on the session  object provides a
simple hash for this purpose:

    # After login, save the session
    my $data = $at->session->_raw;
    # ... store $data securely ...

    # Later, resume the session
    $at->resume(
        $data->{accessJwt},
        $data->{refreshJwt},
        $data->{token_type},
        $data->{dpop_key_jwk},
        $data->{client_id},
        $data->{handle},
        $data->{pds}
    );

=head2 The Legacy System (App Passwords)

Legacy authentication is simpler but less secure. It uses a single call to C<login>. B<Never use your main password;
always use an App Password.>

    $at->login( 'user.bsky.social', 'your-app-password' );

Once authenticated, you should store your session data securely so you can resume it later without requiring the user
to log in again.

=head3 Resuming a Legacy Session

Legacy sessions only require the access and refresh tokens:

    $at->resume( $access_jwt, $refresh_jwt );

B<Note:> In both cases, if the access token has expired, C<resume()> will automatically attempt to refresh it using the
refresh token.

=head1 Account Management

=head2 Creating an Account

You can create a new account using C<com.atproto.server.createAccount>. Note that PDS instances I<may> require an
invite code.

    my $res = $at->post( 'com.atproto.server.createAccount' => {
        handle      => 'newuser.bsky.social',
        email       => 'user@example.com',
        password    => 'secure-password',
        inviteCode  => 'bsky-social-abcde'
    });

=head1 Working With Data: Records and Repositories

Data in the AT Protocol is stored in "repositories" as "records". Each record belongs to a "collection" (defined by a
Lexicon).

=head2 Creating a Post

Posts are records in, for example, the C<app.bsky.feed.post> collection.

    $at->post( 'com.atproto.repo.createRecord' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => {
            '$type'   => 'app.bsky.feed.post',
            text      => 'Content of the post',
            createdAt => At::_now->to_string,
        }
    });

=head2 Listing Records

To see what's in a collection:

    my $res = $at->get( 'com.atproto.repo.listRecords' => {
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        limit      => 10
    });

    for my $record (@{$res->{records}}) {
        say $record->{value}{text};
    }

=head1 Drinking from the Firehose: Real-time Streaming

The Firehose is a real-time stream of B<all> events happening on the network (or a specific PDS). This includes new
posts, likes, handle changes, deletions, and more.

=head2 Subscribing to the Firehose

    my $fh = $at->firehose(sub ( $header, $body, $err ) {
        if ($err) {
            warn "Firehose error: $err";
            return;
        }

        if ($header->{t} eq '#commit') {
            say "New commit in repo: " . $body->{repo};
        }
    });

    $fh->start();

B<Note:> The Firehose requires L<CBOR::Free> and an async event loop to keep the connection alive. Currently, At.pm
supports L<Mojo::UserAgent> so you should usually use L<Mojo::IOLoop>:

    use Mojo::IOLoop;
    # ... setup firehose ...
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 Lexicon Caching

The AT Protocol defines its API endpoints using "Lexicons" (JSON schemas). This library uses these schemas to
automatically coerce API responses into Perl objects.

=head2 How it works

When you call a method like C<app.bsky.actor.getProfile>, the library:

=over

=item 1. B<Checks user-provided paths:> It looks in any directories passed to C<lexicon_paths>.

=item 2. B<Checks local storage:> It looks for the schema in the distribution's C<share> directory.

=item 3. B<Checks user cache:> It looks in C<~/.cache/atproto/lexicons/>.

=item 4. B<Downloads if missing:> If not found, it automatically downloads the schema from the
official AT Protocol repository and saves it to your user cache.

=back

This system ensures that the library can support new or updated features without requiring a new release of the Perl
module.

=head1 METHODS

=head2 C<new( [ host => ..., share => ... ] )>

Constructor.

Expected parameters include:

=over

=item C<host>

Host for the service. Defaults to C<bsky.social>.

=item C<share>

Location of lexicons. Defaults to the C<share> directory under the distribution.

=item C<lexicon_paths>

An optional path string or arrayref of paths to search for Lexicons before checking the default cache locations. Useful
for local development with a checkout of the C<atproto> repository.

=item C<http>

A pre-instantiated L<At::UserAgent> object. By default, this is auto-detected by checking for L<Mojo::UserAgent>,
falling back to L<HTTP::Tiny>.

=back

=head2 C<oauth_start( $handle, $client_id, $redirect_uri, [ $scope ] )>

Initiates the OAuth 2.0 Authorization Code flow. Returns the authorization URL.

=head2 C<oauth_callback( $code, $state )>

Exchanges the authorization code for tokens and completes the OAuth flow.

=head2 C<login( $handle, $app_password )>

Performs legacy password-based authentication. B<Deprecated: Use OAuth instead.>

=head2 C<resume( $access_jwt, $refresh_jwt, [ $token_type, $dpop_key_jwk, $client_id, $handle, $pds ] )>

Resumes a previous session using stored tokens and metadata.

=head2 C<get( $method, [ \%params ] )>

Calls an XRPC query (GET). Returns the decoded JSON response.

=head2 C<post( $method, [ \%data ] )>

Calls an XRPC procedure (POST). Returns the decoded JSON response.

=head2 C<subscribe( $method, $callback )>

Connects to a WebSocket stream (Firehose).

=head2 C<firehose( $callback, [ $url ] )>

Returns a new L<At::Protocol::Firehose> client. C<$url> defaults to the Bluesky relay firehose.

=head2 C<resolve_handle( $handle )>

Resolves a handle to a DID.

=head2 C<collection_scope( $collection, [ $action ] )>

Helper to generate granular OAuth scopes (e.g., C<repo:app.bsky.feed.post?action=create>).

=head2 C<session()>

Returns the current L<At::Protocol::Session> object.

=head2 C<did()>

Returns the DID of the authenticated user.

=head1 ERROR HANDLING

Exception handling is carried out by returning L<At::Error> objects which have untrue boolean values.

=head1 See Also

L<Bluesky> - Bluesky client library

L<App::bsky> - Bluesky client on the command line

L<https://docs.bsky.app/docs/api/>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

atproto Bluesky auth authed login

=end stopwords

=cut
