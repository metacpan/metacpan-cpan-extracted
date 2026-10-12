use v5.40;
use feature 'class';
no warnings 'experimental::class', 'experimental::try';
#
class Bluesky v1.8.0 {
    use bytes;
    use Carp qw[carp];
    use At;
    use Path::Tiny;
    use HTTP::Tiny;
    use URI;
    use URI::Escape;
    use JSON::PP;
    #
    field $service       : param //= 'https://bsky.social';
    field $chat_service  : param //= 'https://api.bsky.chat';
    field $video_service : param : reader //= 'https://video.bsky.app';
    field $at            : reader = At->new( host => $service );
    #
    method _at_for ($method) {
        if ( $method =~ /^chat\.bsky\./ ) {

            # Chat requests are proxied via the PDS.
            # Service ID fragment (#bsky_chat) is required.
            say '[DEBUG] [Bluesky] Proxying chat request...' if $ENV{DEBUG};
            $self->at->http->at_protocol_proxy('did:web:api.bsky.chat#bsky_chat');
            return $at;
        }

        # Ensure proxy is NOT used for standard repo/feed calls
        $self->at->http->at_protocol_proxy(undef);
        return $at;
    }
    method login ( $identifier, $password ) { $self->at->login( $identifier, $password ); }

    method resume( $accessJwt, $refreshJwt, $token_type = 'Bearer', $dpop_key_jwk = (), $client_id = (), $handle = (), $pds = (), $scope = () ) {
        $self->at->resume( $accessJwt, $refreshJwt, $token_type, $dpop_key_jwk, $client_id, $handle, $pds, $scope );
    }

    method oauth_start( $handle, $client_id, $redirect_uri, $scope = 'atproto' ) {
        return $self->at->oauth_start( $handle, $client_id, $redirect_uri, $scope );
    }
    method oauth_callback( $code, $state ) { return $self->at->oauth_callback( $code, $state ); }

    method oauth_helper (%args) {
        my $handle = $args{handle} or die 'Handle is required for oauth_helper';

        # client_id base MUST be localhost for the PDS to recognize it as metadata-less
        my $client_id_base = $args{client_id} // 'http://localhost';

        # RFC 8252 requires loopback IP (127.0.0.1) for the actual redirect
        my $redirect_uri = $args{redirect} // 'http://127.0.0.1:8888/callback';

        # Transitional scopes for chat access via PDS proxy
        my $scope      = $args{scope}      // 'atproto';
        my $on_success = $args{on_success} // sub {1};

        # Build the magic localhost Client ID manually to ensure %20 encoding for spaces
        require URI::Escape;
        my $scope_encoded    = URI::Escape::uri_escape($scope);
        my $redirect_encoded = URI::Escape::uri_escape($redirect_uri);
        my $client_id        = "$client_id_base?scope=$scope_encoded&redirect_uri=$redirect_encoded";
        say "Starting OAuth flow for $handle...";
        my $auth_url = $self->oauth_start( $handle, $client_id, $redirect_uri, $scope );
        say 'Please open the following URL in your browser:';
        say "\n   $auth_url\n";

        if ( $args{listen} ) {

            # Attempt to start a local server to catch the callback
            try {
                require Mojolicious;
                my $app  = Mojolicious->new();
                my $port = 8888;
                my $daemon;
                $port = $1 if $redirect_uri =~ /:(\d+)/;
                my $path = URI->new($redirect_uri)->path || '/';
                $app->routes->get($path)->to(
                    cb => sub ($c) {
                        my $code  = $c->param('code');
                        my $state = $c->param('state');
                        if ( $code && $state ) {
                            say 'Exchanging code for tokens...';
                            try {
                                $self->oauth_callback( $code, $state );
                                $on_success->($self);
                                $c->render( text => '<h1>Success!</h1><p>You can close this window and return to the terminal.</p>' );

                                # Stop loop after response
                                require Mojo::IOLoop;
                                Mojo::IOLoop->timer(
                                    1 => sub { $daemon->stop if defined $daemon; Mojo::IOLoop->stop if Mojo::IOLoop->can('stop'); } );
                            }
                            catch ($e) {
                                $c->render( text => 'OAuth Callback failed: ' . $e, status => 500 );
                                die $e;
                            }
                        }
                        else {
                            $c->render( text => 'Error: Missing code or state.', status => 400 );
                        }
                    }
                );
                say "Starting local server on port $port to catch the callback...";
                $app->log->level('error');
                require Mojo::Server::Daemon;

                # Listen on all interfaces but specific to the redirect_uri port
                $daemon = Mojo::Server::Daemon->new( app => $app, listen => [ 'http://127.0.0.1:' . $port ] );
                $daemon->run();
                return $self;    # Listener ran (blocks until finished); control returns after stop
            }
            catch ($e) {
                warn "Could not start listener: $e\nFalling back to manual input.\n";
            }
        }

        # Manual fallback (only reached if listen is false or failed)
        say 'After authorizing, you will be redirected to a URL that looks like:';
        say "$redirect_uri?code=...&state=...";
        say "\nPlease paste the FULL redirect URL here:";
        my $callback_url = <STDIN>;
        chomp $callback_url;
        my ($code)  = $callback_url =~ /[?&]code=([^&]+)/;
        my ($state) = $callback_url =~ /[?&]state=([^&]+)/;

        if ( $code && $state ) {
            $self->oauth_callback( $code, $state );
            $on_success->($self);
        }
        else {
            die "Could not find code and state in the provided URL.\n";
        }
    }
    method firehose( $callback, $url = () ) { $self->at->firehose( $callback, $url ); }
    method session ()                       { $self->at->session; }
    #
    method did() { $self->at->did }

    # Session persistence
    method save_session ( $file = 'session.json' ) {
        my $session = $self->at->session;
        if ( !$session ) {
            carp 'No active session to save';
            return;
        }
        my $data;
        if ( builtin::blessed $session ) {
            try {
                my $raw = $session->_raw;
                if ( ref($raw) eq 'HASH' ) {
                    $data = {%$raw};
                }
                elsif ( defined $raw ) {

                    # maybe it returned something odd, try list
                    my @kvs = $session->_raw();
                    $data = {@kvs} if scalar @kvs;
                }
            }
            catch ($e) {
                $data = undef;
            }
            if ( !$data ) {
                try {
                    $data = +{ $session->_raw };
                }
                catch ($e) {
                    $data = undef;
                }
            }
            $data ||= {%$session};
        }
        elsif ( ref($session) eq 'HASH' ) {
            $data = {%$session};
        }
        unless ($data) {
            carp 'Cannot serialize session of type ' . ( ref $session || 'non-reference' );
            return;
        }
        path($file)->spew_raw( JSON::PP->new->ascii->pretty->allow_nonref->encode($data) );
        $self;
    }

    method load_session ( $file = 'session.json' ) {
        return unless -e $file;
        my $config;
        try {
            $config = JSON::PP::decode_json( path($file)->slurp_raw );
        }
        catch ($e) {
            return;
        }
        return unless $config && ref($config) eq 'HASH';
        my $result = $self->resume( map { $config->{$_} } qw[accessJwt refreshJwt token_type dpop_key_jwk client_id handle pds scope] );

        # resume() consumes the one-time-use refresh token whenever the access
        # token has expired. Write the rotated session back so the next run does
        # not replay the spent token (which would force a fresh interactive login).
        if ( $result && !$self->_session_is_error($result) ) {
            my $active = eval { $self->at->session };
            if ( $active && !$self->_session_is_error($active) ) {
                try { $self->save_session($file) } catch ($e) {
                }
            }
        }
        return $result;
    }

    method ensure_auth (%args) {
        my $file   = $args{file} // 'session.json';
        my $handle = $args{handle};
        my $scope  = $args{scope} // 'atproto';
        if ( -e $file ) {
            my $ok = 0;
            try {
                $self->load_session($file);
                $ok = 1;
            }
            catch ($e) {
                $ok = 0;
            }
            my $probe;
            try {
                $probe = $self->at->session;
            }
            catch ($e) {
                $probe = undef;
            }
            if ( $ok && $probe && !$self->_session_is_error($probe) ) {

                # resume() already rotated expired tokens; persist the current session
                try { $self->save_session($file) } catch ($e) {
                }
                return $self;
            }
        }
        $handle or die 'ensure_auth: no saved session found and no handle given; pass handle => "you.bsky.social" for first-time auth';
        my %helper = ( handle => $handle, scope => $scope, listen => $args{listen} // 1 );
        $helper{client_id}  = $args{client_id} if defined $args{client_id};
        $helper{redirect}   = $args{redirect}  if defined $args{redirect};
        $helper{on_success} = sub {
            $self->save_session($file);
            $args{on_success}->($self) if $args{on_success};
        };
        $self->oauth_helper(%helper);
        $self;
    }

    method _session_is_error ($session) {
        return 0 unless builtin::blessed $session;
        return 1 if $session->can('isa') && $session->isa('At::Error');
        return 0;
    }

    # Feeds and content
    method getTrendingTopics(%args) {
        $self->_at_for('app.bsky.unspecced.getTrendingTopics')->get( 'app.bsky.unspecced.getTrendingTopics' => \%args );
    }
    method getTimeline(%args)   { $self->_at_for('app.bsky.feed.getTimeline')->get( 'app.bsky.feed.getTimeline' => \%args ); }
    method getAuthorFeed(%args) { $self->_at_for('app.bsky.feed.getAuthorFeed')->get( 'app.bsky.feed.getAuthorFeed' => \%args ); }
    method getPostThread(%args) { $self->_at_for('app.bsky.feed.getPostThread')->get( 'app.bsky.feed.getPostThread' => \%args ); }

    method getFeed( $feed, %args ) {
        my $res = $self->_at_for('app.bsky.feed.getFeed')->get( 'app.bsky.feed.getFeed' => { feed => $feed, %args } );
        $res ? $res->{feed} // () : $res;
    }

    method getFeedSkeleton( $feed, %args ) {
        my $res = $self->_at_for('app.bsky.feed.getFeedSkeleton')->get( 'app.bsky.feed.getFeedSkeleton' => { feed => $feed, %args } );
        $res ? $res->{feed} // () : $res;
    }

    method getListFeed( $list, %args ) {
        my $res = $self->_at_for('app.bsky.feed.getListFeed')->get( 'app.bsky.feed.getListFeed' => { list => $list, %args } );
        $res ? $res->{feed} // () : $res;
    }

    method sendInteractions(%args) {
        $self->_at_for('app.bsky.feed.sendInteractions')->post( 'app.bsky.feed.sendInteractions' => \%args );
    }

    method getPost($uri) {
        my $res = $self->_at_for('app.bsky.feed.getPosts')
            ->get( 'app.bsky.feed.getPosts' => { uris => [ builtin::blessed $uri ? $uri->as_string : $uri ] } );
        $res ? $res->{posts}[0] // () : $res;
    }

    method getPosts(@uris) {
        my $res = $self->_at_for('app.bsky.feed.getPosts')
            ->get( 'app.bsky.feed.getPosts' => { uris => [ map { builtin::blessed $_ ? $_->as_string : $_ } @uris ] } );
        $res ? $res->{posts} // () : $res;
    }
    method getLikes(%args) { $self->_at_for('app.bsky.feed.getLikes')->get( 'app.bsky.feed.getLikes' => \%args ); }

    method getBookmarks(%args) {
        my $res = $self->_at_for('app.bsky.bookmark.getBookmarks')->get( 'app.bsky.bookmark.getBookmarks' => \%args );
        $res ? $res->{bookmarks} // () : $res;
    }

    method createBookmark( $uri, $cid //= () ) {
        if ( !defined $cid ) {
            my $post = $self->_at_for('app.bsky.feed.getPosts')->get( 'app.bsky.feed.getPosts' => { uris => [$uri] } );
            $post || $post->throw;
            $cid = $post->{posts}[0]{cid};
        }
        $self->_at_for('app.bsky.bookmark.createBookmark')->post( 'app.bsky.bookmark.createBookmark' => { uri => $uri, cid => $cid } );
    }

    method deleteBookmark($uri) {
        $self->_at_for('app.bsky.bookmark.deleteBookmark')->post( 'app.bsky.bookmark.deleteBookmark' => { uri => $uri } );
    }

    method getQuotes(%args) {
        my $res = $self->_at_for('app.bsky.feed.getQuotes')->get( 'app.bsky.feed.getQuotes' => \%args );
        $res ? $res->{quotes} // () : $res;
    }

    method getActorLikes(%args) {
        my $res = $self->_at_for('app.bsky.feed.getActorLikes')->get( 'app.bsky.feed.getActorLikes' => \%args );
        $res ? $res->{feed} // () : $res;
    }

    method searchPosts(%args) {
        my $res = $self->_at_for('app.bsky.feed.searchPosts')->get( 'app.bsky.feed.searchPosts' => \%args );
        $res ? $res->{posts} // () : $res;
    }

    method getSuggestedFeeds(%args) {
        my $res = $self->_at_for('app.bsky.feed.getSuggestedFeeds')->get( 'app.bsky.feed.getSuggestedFeeds' => \%args );
        $res ? $res->{feeds} // () : $res;
    }
    method describeFeedGenerator() { $self->_at_for('app.bsky.feed.describeFeedGenerator')->get('app.bsky.feed.describeFeedGenerator') }

    method getFeedGenerator($generator) {
        $self->_at_for('app.bsky.feed.getFeedGenerator')->get( 'app.bsky.feed.getFeedGenerator' => { feed => $generator } );
    }

    method getFeedGenerators(%args) {
        my $res = $self->_at_for('app.bsky.feed.getFeedGenerators')->get( 'app.bsky.feed.getFeedGenerators' => \%args );
        $res ? $res->{feeds} // () : $res;
    }

    method getActorFeeds(%args) {
        my $res = $self->_at_for('app.bsky.feed.getActorFeeds')->get( 'app.bsky.feed.getActorFeeds' => \%args );
        $res ? $res->{feeds} // () : $res;
    }

    method getRepostedBy(%args) {
        my $res = $self->_at_for('app.bsky.feed.getRepostedBy')->get( 'app.bsky.feed.getRepostedBy' => \%args );
        $res ? $res->{repostedBy} // () : $res;
    }

    method repost( $uri, $cid //= () ) {
        if ( !defined $cid ) {
            my $post = $self->_at_for('app.bsky.feed.getPosts')->get( 'app.bsky.feed.getPosts' => { uris => [$uri] } );
            $post || $post->throw;
            $cid = $post->{posts}[0]{cid};
        }
        $self->at->create_record( 'app.bsky.feed.repost', { subject => { uri => $uri, cid => $cid }, createdAt => $self->at->_now->to_string } );
    }

    method deleteRepost($url) {
        $url = At::Protocol::URI->new($url) unless builtin::blessed $url;
        if ( $url->collection eq 'app.bsky.feed.post' ) {
            my $post = $self->getPost($url);
            $url = $post->{viewer}{repost} // return;
        }
        $self->at->delete_record( 'app.bsky.feed.repost', $url->rkey );
    }
    method uploadBlob( $data, %opts ) { $self->at->upload_blob( $data, $opts{mime_type} // () ) }

    method createPost(%args) {

        # TODO:
        #   - recordWithMedia embed
        #
        my %post = (    # these are the required fields which every post must include
            '$type'   => 'app.bsky.feed.post',
            text      => $args{text}      // '',
            createdAt => $args{timestamp} // $self->at->_now->to_string    # trailing "Z" is preferred over "+00:00"
        );

        # indicate included languages (optional)
        $post{langs} = [ ( ( builtin::reftype( $args{lang} ) // '' ) eq 'ARRAY' ) ? @{ $args{lang} } : $args{lang} ] if defined $args{lang};

        # parse out mentions and URLs as "facets"
        if ( length $post{text} > 0 ) {
            my @facets = $self->parse_facets( $post{text} );
            $post{facets} = \@facets if @facets;
        }

        # additional tags (up to 8)
        $post{tags} = [ ( builtin::reftype( $args{tags} ) // '' ) eq 'ARRAY' ? @{ $args{tags} } : $args{tags} ] if defined $args{tags};

        # metadata tags on an atproto record, published by the author within the record (up to 10)
        $post{labels} = {
            '$type' => 'com.atproto.label.defs#selfLabels',
            values  => [
                map { { '$type' => 'com.atproto.label.defs#selfLabel', val => $_ } }
                    ( ( builtin::reftype( $args{labels} ) // '' ) eq 'ARRAY' ? @{ $args{labels} } : $args{labels} )
            ]
            }
            if defined $args{labels};

        #~ com.atproto.label.defs#selfLabels
        # if this is a reply, get references to the parent and root
        $post{reply} = $self->getReplyRefs( $args{reply_to} ) if defined $args{reply_to};

        # embeds
        if ( defined $args{embed} ) {
            my $embed = $args{embed};
            if ( defined $embed->{'$type'} ) {

                # A fully-built embed (e.g. from videoEmbed()) used as-is.
                $post{embed} = $embed;
            }
            elsif ( defined $embed->{images} ) {
                $post{embed} = $self->uploadImages( @{ $embed->{images} } );
            }
            elsif ( defined $embed->{video} ) {
                $post{embed} = $self->uploadVideo( $embed->{video} );
            }
            elsif ( defined $embed->{gallery} ) {
                $post{embed} = $self->uploadGallery( @{ $embed->{gallery} } );
            }
            elsif ( defined $embed->{url} ) {
                $post{embed} = $self->fetch_embed_url_card( $embed->{url} );
            }
            elsif ( defined $embed->{ref} ) {
                $post{embed} = $self->getEmbedRef( $embed->{ref} );
            }
        }
        my $res = $self->at->create_record( 'app.bsky.feed.post', \%post );

        # If reply_gate is requested, create a threadgate record
        if ( $res && $res->{uri} && $args{reply_gate} ) {
            my $post_uri = At::Protocol::URI->new( $res->{uri} );
            my @allow;
            if ( ref $args{reply_gate} eq 'ARRAY' ) {
                for my $type ( @{ $args{reply_gate} } ) {
                    if    ( $type eq 'mention' )   { push @allow, { '$type' => 'app.bsky.feed.threadgate#mentionRule' }; }
                    elsif ( $type eq 'follower' )  { push @allow, { '$type' => 'app.bsky.feed.threadgate#followerRule' }; }
                    elsif ( $type eq 'following' ) { push @allow, { '$type' => 'app.bsky.feed.threadgate#followingRule' }; }
                    elsif ( $type eq 'list' ) { push @allow, { '$type' => 'app.bsky.feed.threadgate#listRule', list => $args{reply_gate_list} }; }
                }
            }
            $self->at->create_record( 'app.bsky.feed.threadgate',
                { post => $post_uri->as_string, allow => \@allow, createdAt => $self->at->_now->to_string, },
                $post_uri->rkey );    # Must match post rkey
        }

        # If post_gate is requested, create a postgate record
        if ( $res && $res->{uri} && $args{post_gate} ) {
            my $post_uri = At::Protocol::URI->new( $res->{uri} );
            my @embedding_rules;
            if ( ref $args{post_gate} eq 'ARRAY' ) {
                for my $rule ( @{ $args{post_gate} } ) {
                    if ( $rule eq 'disable' ) {
                        push @embedding_rules, { '$type' => 'app.bsky.feed.postgate#disableRule' };
                    }
                }
            }
            $self->at->create_record( 'app.bsky.feed.postgate',
                { post => $post_uri->as_string, embeddingRules => \@embedding_rules, createdAt => $self->at->_now->to_string, },
                $post_uri->rkey );
        }
        return $res;
    }

    method deletePost($at_uri) {
        $at_uri = At::Protocol::URI->new($at_uri) unless builtin::blessed $at_uri;
        $self->at->delete_record( 'app.bsky.feed.post', $at_uri->rkey );

        # Automatically try to delete gates too
        $self->at->delete_record( 'app.bsky.feed.threadgate', $at_uri->rkey );
        $self->at->delete_record( 'app.bsky.feed.postgate',   $at_uri->rkey );
    }

    method like( $uri, $cid //= () ) {
        if ( !defined $cid ) {
            my $post = $self->_at_for('app.bsky.feed.getPosts')->get( 'app.bsky.feed.getPosts' => { uris => [$uri] } );
            $post || $post->throw;
            $cid = $post->{posts}[0]{cid};
        }
        $self->at->create_record(
            'app.bsky.feed.like',
            {   '$type' => 'app.bsky.feed.like',
                subject => {                       # com.atproto.repo.strongRef
                    uri => $uri,
                    cid => $cid
                },
                createdAt => $self->at->_now->to_string
            }
        );
    }

    method deleteLike($url) {
        $url = At::Protocol::URI->new($url) unless builtin::blessed $url;
        if ( $url->collection eq 'app.bsky.feed.post' ) {
            my $post = $self->getPost($url);
            $url = $post->{viewer}{like} // return;
        }
        $self->at->delete_record( 'app.bsky.feed.like', $url->rkey );
    }

    # Social graph
    method block($actor) {
        my $profile = $self->getProfile($actor);
        $profile->{did} // return;
        $self->at->create_record( 'app.bsky.graph.block', { createdAt => $self->at->_now->to_string, subject => $profile->{did} } );
    }

    method getBlocks(%args) {
        my $res = $self->_at_for('app.bsky.graph.getBlocks')->get( 'app.bsky.graph.getBlocks' => \%args );
        $res ? $res->{blocks} : $res;
    }

    method deleteBlock($url) {
        $url = At::Protocol::URI->new($url) unless builtin::blessed $url;
        $self->at->delete_record( 'app.bsky.graph.block', $url->rkey );
    }

    method follow($subject) {
        my $profile = $self->getProfile($subject);
        $profile->{did} // return;
        $self->at->create_record( 'app.bsky.graph.follow',
            { '$type' => 'app.bsky.graph.follow', subject => $profile->{did}, createdAt => $self->at->_now->to_string } );
    }

    method deleteFollow($url) {
        $url = At::Protocol::URI->new($url) unless builtin::blessed $url;
        $self->at->delete_record( 'app.bsky.graph.follow', $url->rkey );
    }

    method getFollows( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getFollows')->get( 'app.bsky.graph.getFollows' => { actor => $actor, %args } );
        $res ? $res->{follows} : $res;
    }

    method getFollowers( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getFollowers')->get( 'app.bsky.graph.getFollowers' => { actor => $actor, %args } );
        $res ? $res->{followers} : $res;
    }

    method getKnownFollowers( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getKnownFollowers')->get( 'app.bsky.graph.getKnownFollowers' => { actor => $actor, %args } );
        $res ? $res->{followers} : $res;
    }

    method getRelationships(%args) {
        $args{actor} //= $self->at->did;
        if ( exists $args{actors} && !exists $args{others} ) {
            $args{others} = delete $args{actors};
        }
        my $res = $self->_at_for('app.bsky.graph.getRelationships')->get( 'app.bsky.graph.getRelationships' => \%args );
        $res ? $res->{relationships} : $res;
    }

    method getMutes(%args) {
        my $res = $self->_at_for('app.bsky.graph.getMutes')->get( 'app.bsky.graph.getMutes' => \%args );
        $res ? $res->{mutes} // () : $res;
    }
    method muteThread($uri)   { $self->_at_for('app.bsky.graph.muteThread')->post( 'app.bsky.graph.muteThread' => { root => $uri } ) }
    method unmuteThread($uri) { $self->_at_for('app.bsky.graph.unmuteThread')->post( 'app.bsky.graph.unmuteThread' => { root => $uri } ) }

    method getListBlocks(%args) {
        my $res = $self->_at_for('app.bsky.graph.getListBlocks')->get( 'app.bsky.graph.getListBlocks' => \%args );
        $res ? $res->{lists} // () : $res;
    }

    method getListMutes(%args) {
        my $res = $self->_at_for('app.bsky.graph.getListMutes')->get( 'app.bsky.graph.getListMutes' => \%args );
        $res ? $res->{lists} // () : $res;
    }

    method getLists( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getLists')->get( 'app.bsky.graph.getLists' => { actor => $actor, %args } );
        $res ? $res->{lists} // () : $res;
    }

    method getListsWithMembership( $actor, %args ) {
        my $res
            = $self->_at_for('app.bsky.graph.getListsWithMembership')->get( 'app.bsky.graph.getListsWithMembership' => { actor => $actor, %args } );
        $res ? $res->{listsWithMembership} // () : $res;
    }

    method getList( $list, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getList')->get( 'app.bsky.graph.getList' => { list => $list, %args } );
        $res ? $res->{items} // () : $res;
    }

    method getStarterPack($uri) {
        $self->_at_for('app.bsky.graph.getStarterPack')->get( 'app.bsky.graph.getStarterPack' => { starterPack => $uri } );
    }

    method getStarterPacks(@uris) {
        my $res = $self->_at_for('app.bsky.graph.getStarterPacks')->get( 'app.bsky.graph.getStarterPacks' => { uris => \@uris } );
        $res ? $res->{starterPacks} // () : $res;
    }

    method getActorStarterPacks( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getActorStarterPacks')->get( 'app.bsky.graph.getActorStarterPacks' => { actor => $actor, %args } );
        $res ? $res->{starterPacks} // () : $res;
    }

    method getStarterPacksWithMembership( $actor, %args ) {
        my $res = $self->_at_for('app.bsky.graph.getStarterPacksWithMembership')
            ->get( 'app.bsky.graph.getStarterPacksWithMembership' => { actor => $actor, %args } );
        $res ? $res->{starterPacksWithMembership} // () : $res;
    }

    method getSuggestedFollowsByActor($actor) {
        my $res
            = $self->_at_for('app.bsky.graph.getSuggestedFollowsByActor')->get( 'app.bsky.graph.getSuggestedFollowsByActor' => { actor => $actor } );
        $res ? $res->{suggestions} // () : $res;
    }

    method searchStarterPacks(%args) {
        my $res = $self->_at_for('app.bsky.graph.searchStarterPacks')->get( 'app.bsky.graph.searchStarterPacks' => \%args );
        $res ? $res->{starterPacks} // () : $res;
    }

    # Actors
    method getProfile($actor) { $self->_at_for('app.bsky.actor.getProfile')->get( 'app.bsky.actor.getProfile' => { actor => $actor } ) }

    method getPreferences() {
        my $res = $self->_at_for('app.bsky.actor.getPreferences')->get('app.bsky.actor.getPreferences');
        $res ? $res->{preferences} : $res;
    }

    method putPreferences($preferences) {
        $self->_at_for('app.bsky.actor.putPreferences')->post( 'app.bsky.actor.putPreferences' => { preferences => $preferences } );
    }

    method upsertProfile($cb) {
        my $profile = $self->_at_for('com.atproto.repo.getRecord')
            ->get( 'com.atproto.repo.getRecord' => { repo => $self->at->did, collection => 'app.bsky.actor.profile', rkey => 'self' } );
        my %existing = $profile ? %{ $profile->{value} } : ( '$type' => 'app.bsky.actor.profile' );
        my $updated  = $cb->(%existing);
        my $res      = $self->at->put_record( 'app.bsky.actor.profile', 'self', $updated, $profile ? $profile->{cid} : () );
        $res // 1;
    }

    method getProfiles(%args) {
        my $res = $self->_at_for('app.bsky.actor.getProfiles')->get( 'app.bsky.actor.getProfiles' => \%args );
        return $res ? ( $res->{profiles} // [] ) : [];
    }

    method getSuggestions(%args) {
        my $res = $self->_at_for('app.bsky.actor.getSuggestions')->get( 'app.bsky.actor.getSuggestions' => \%args );
        $res ? $res->{actors} : $res;
    }

    method searchActors(%args) {
        my $res = $self->_at_for('app.bsky.actor.searchActors')->get( 'app.bsky.actor.searchActors' => \%args );
        $res ? $res->{actors} : $res;
    }

    method searchActorsTypeahead(%args) {
        my $res = $self->_at_for('app.bsky.actor.searchActorsTypeahead')->get( 'app.bsky.actor.searchActorsTypeahead' => \%args );
        $res ? $res->{actors} : $res;
    }
    method mute($actor)   { $self->_at_for('app.bsky.graph.muteActor')->post( 'app.bsky.graph.muteActor' => { actor => $actor } ) }
    method unmute($actor) { $self->_at_for('app.bsky.graph.unmuteActor')->post( 'app.bsky.graph.unmuteActor' => { actor => $actor } ) }

    method muteModList($listUri) {
        $self->_at_for('app.bsky.graph.muteActorList')->post( 'app.bsky.graph.muteActorList' => { list => $listUri } );
    }

    method unmuteModList($listUri) {
        $self->_at_for('app.bsky.graph.unmuteActorList')->post( 'app.bsky.graph.unmuteActorList' => { list => $listUri } );
    }

    method blockModList($listUri) {
        $self->at->create_record( 'app.bsky.graph.listblock',
            { '$type' => 'app.bsky.graph.listblock', subject => $listUri, createdAt => $self->at->_now->to_string } );
    }

    # Moderation
    method report ( $subject, $reason_type, $reason = () ) {
        $self->_at_for('com.atproto.moderation.createReport')
            ->post( 'com.atproto.moderation.createReport' =>
                { subject => $subject, reasonType => $reason_type, defined $reason ? ( reason => $reason ) : () } );
    }

    method unblockModList($url) {
        $url = At::Protocol::URI->new($url) unless builtin::blessed $url;
        $self->at->delete_record( 'app.bsky.graph.listblock', $url->rkey );
    }

    # Notifications
    method listNotifications(%args) {
        my $res = $self->at->get( 'app.bsky.notification.listNotifications' => \%args );
        $res ? $res->{notifications} : $res;
    }

    method countUnreadNotifications() {
        my $res = $self->at->get('app.bsky.notification.getUnreadCount');
        $res ? $res->{count} : $res;
    }

    method updateSeenNotifications( $seenAt = undef ) {
        my $res = $self->at->post( 'app.bsky.notification.updateSeen' => { seenAt => $seenAt // $self->at->_now->to_string } );
        $res // 1;
    }

    method getNotificationPreferences() {
        my $res = $self->_at_for('app.bsky.notification.getPreferences')->get('app.bsky.notification.getPreferences');
        $res ? $res->{preferences} // () : $res;
    }

    method putNotificationPreferences(%args) {
        $self->_at_for('app.bsky.notification.putPreferences')->post( 'app.bsky.notification.putPreferences' => \%args );
    }

    method putNotificationPreferencesV2(%args) {
        my $res = $self->_at_for('app.bsky.notification.putPreferencesV2')->post( 'app.bsky.notification.putPreferencesV2' => \%args );
        $res ? $res->{preferences} // () : $res;
    }

    method listActivitySubscriptions(%args) {
        my $res
            = $self->_at_for('app.bsky.notification.listActivitySubscriptions')->get( 'app.bsky.notification.listActivitySubscriptions' => \%args );
        $res ? $res->{subscriptions} // () : $res;
    }

    method putActivitySubscription( $subject, $activitySubscription ) {
        $self->_at_for('app.bsky.notification.putActivitySubscription')
            ->post( 'app.bsky.notification.putActivitySubscription' => { subject => $subject, activitySubscription => $activitySubscription } );
    }

    method registerPush(%args) {
        $self->_at_for('app.bsky.notification.registerPush')->post( 'app.bsky.notification.registerPush' => \%args );
    }

    method unregisterPush(%args) {
        $self->_at_for('app.bsky.notification.unregisterPush')->post( 'app.bsky.notification.unregisterPush' => \%args );
    }

    # Identity
    method resolveHandle($handle) {
        my $res = $self->at->get( 'com.atproto.identity.resolveHandle' => { handle => $handle } );
        $res ? $res->{did} : $res;
    }

    method updateHandle($handle) {
        $self->at->post( 'com.atproto.identity.updateHandle' => { handle => $handle } );
    }
    method describeServer() { $self->at->get('com.atproto.server.describeServer') }

    method listRecords(%args) {
        my $res = $self->at->get( 'com.atproto.repo.listRecords' => \%args );
        $res ? $res->{records} // () : $res;
    }

    method getLabelerServices(%args) {
        my $res = $self->at->get( 'app.bsky.labeler.getServices' => \%args );
        $res ? $res->{views} // () : $res;
    }

    method queryLabels(%args) {
        my $res = $self->_at_for('com.atproto.label.queryLabels')->get( 'com.atproto.label.queryLabels' => \%args );
        $res ? $res->{labels} // () : $res;
    }

    # Chat
    method listConvos(%args) {
        my $res = $self->_at_for('chat.bsky.convo.listConvos')->get( 'chat.bsky.convo.listConvos' => \%args );
        $res ? $res->{convos} // () : $res;
    }

    method getConvo($convoId) {
        my $res = $self->_at_for('chat.bsky.convo.getConvo')->get( 'chat.bsky.convo.getConvo' => { convoId => $convoId } );
        $res ? $res->{convo} // () : $res;
    }

    method getConvoForMembers(%args) {
        my $res = $self->_at_for('chat.bsky.convo.getConvoForMembers')->get( 'chat.bsky.convo.getConvoForMembers' => \%args );
        $res ? $res->{convo} // () : $res;
    }

    method getMessages(%args) {
        my $res = $self->_at_for('chat.bsky.convo.getMessages')->get( 'chat.bsky.convo.getMessages' => \%args );
        $res ? $res->{messages} // () : $res;
    }

    method sendMessage( $convoId, $message ) {
        $self->_at_for('chat.bsky.convo.sendMessage')->post( 'chat.bsky.convo.sendMessage' => { convoId => $convoId, message => $message } );
    }

    method acceptConvo($convoId) {
        $self->_at_for('chat.bsky.convo.acceptConvo')->post( 'chat.bsky.convo.acceptConvo' => { convoId => $convoId } );
    }

    method leaveConvo($convoId) {
        $self->_at_for('chat.bsky.convo.leaveConvo')->post( 'chat.bsky.convo.leaveConvo' => { convoId => $convoId } );
    }

    method updateRead( $convoId, $messageId = undef ) {
        $self->_at_for('chat.bsky.convo.updateRead')->post( 'chat.bsky.convo.updateRead' => { convoId => $convoId, messageId => $messageId } );
    }
    method muteConvo($convoId) { $self->_at_for('chat.bsky.convo.muteConvo')->post( 'chat.bsky.convo.muteConvo' => { convoId => $convoId } ) }

    method unmuteConvo($convoId) {
        $self->_at_for('chat.bsky.convo.unmuteConvo')->post( 'chat.bsky.convo.unmuteConvo' => { convoId => $convoId } );
    }

    method addReaction( $convoId, $messageId, $reaction ) {
        $self->_at_for('chat.bsky.convo.addReaction')
            ->post( 'chat.bsky.convo.addReaction' => { convoId => $convoId, messageId => $messageId, reaction => $reaction } );
    }

    method removeReaction( $convoId, $messageId, $reaction ) {
        $self->_at_for('chat.bsky.convo.removeReaction')
            ->post( 'chat.bsky.convo.removeReaction' => { convoId => $convoId, messageId => $messageId, reaction => $reaction } );
    }

    method deleteMessageForSelf( $convoId, $messageId ) {
        $self->_at_for('chat.bsky.convo.deleteMessageForSelf')
            ->post( 'chat.bsky.convo.deleteMessageForSelf' => { convoId => $convoId, messageId => $messageId } );
    }

    method getConvoAvailability(%args) {
        $self->_at_for('chat.bsky.convo.getConvoAvailability')->get( 'chat.bsky.convo.getConvoAvailability' => \%args );
    }
    method getLog(%args) { $self->_at_for('chat.bsky.convo.getLog')->get( 'chat.bsky.convo.getLog' => \%args ) }

    # Video services (https://atproto.com/guides/video-handling)
    #
    # Video processing lives on a sidecar service (video.bsky.app), not on the
    # PDS. Each call is authenticated with a short-lived service token minted
    # by the user's PDS via com.atproto.server.getServiceAuth, then sent as a
    # plain "Bearer" token. The session's DPoP token is NOT used here, which
    # is why posting video to the PDS returns 501 Method Not Implemented.
    method _video_http() { state $http //= HTTP::Tiny->new; $http }

    # did:web form of the user's PDS. Used as the audience for the token that
    # lets the video service deposit the processed blob in our PDS.
    method _pds_did() {
        my $session = eval { $self->at->session };
        my $pds     = ( builtin::blessed $session && $session->can('pds') ? $session->pds : undef ) // $self->at->host;
        $pds = $pds . '';
        $pds =~ s{^https?://}{};
        $pds =~ s{/.*$}{};
        $pds =~ s{:}{%3A}g;        # did:web encodes the port separator
        'did:web:' . $pds;
    }

    # Mint a service token for the given audience/lexicon. Returns the token
    # string, or an At::Error which callers should propagate.
    method _service_token ( $aud, $lxm, $exp = undef ) {
        my $res = $self->at->get( 'com.atproto.server.getServiceAuth' => { aud => $aud, lxm => $lxm, exp => ( $exp // ( time + 1800 ) ) } );
        return $res          if builtin::blessed $res;
        return $res->{token} if ref $res eq 'HASH' && defined $res->{token};
        At::Error->new( message => 'getServiceAuth did not return a token', fatal => 1 );
    }

    method _video_url ( $lexicon, %query ) {
        my $url   = "$video_service/xrpc/$lexicon";
        my @pairs = map { "$_=" . URI::Escape::uri_escape( $query{$_} ) } grep { defined $query{$_} } sort keys %query;
        @pairs ? "$url?" . join( '&', @pairs ) : $url;
    }

    method _video_error ( $res, $content ) {
        my $msg = $res->{reason} // 'Unknown error';
        if ( ref $content eq 'HASH' ) {
            my $detail = $content->{message} // $content->{error};
            $msg = $detail . ' (' . $msg . ')' if defined $detail && $detail ne $msg;
        }
        At::Error->new( message => $msg, fatal => 1 );
    }

    # The video service wraps job data in a "jobStatus" key; unwrap it when
    # present, otherwise return the payload untouched.
    method _unwrap_job ($content) {
        return $content unless ref $content eq 'HASH';
        $content->{jobStatus} // $content;
    }

    method getVideoUploadLimits () {
        my $token = $self->_service_token( 'did:web:video.bsky.app', 'app.bsky.video.getUploadLimits' );
        return $token if builtin::blessed $token;
        my $res = $self->_video_http->get( $self->_video_url('app.bsky.video.getUploadLimits'),
            { headers => { Authorization => "Bearer $token", Accept => 'application/json' } } );
        my $content = $res->{content};
        $content = decode_json($content) if defined $content && !ref $content && ( $res->{headers}{'content-type'} // '' ) =~ m[json];
        $res->{success} ? $self->_unwrap_job($content) : $self->_video_error( $res, $content );
    }

    method getVideoJobStatus ( $jobId, %opts ) {
        my $token = $opts{token} // $self->_service_token( 'did:web:video.bsky.app', 'app.bsky.video.getJobStatus', $opts{exp} );
        return $token if builtin::blessed $token;
        my $res = $self->_video_http->get(
            $self->_video_url( 'app.bsky.video.getJobStatus', jobId => $jobId ),
            { headers => { Authorization => "Bearer $token", Accept => 'application/json' } }
        );
        my $content = $res->{content};
        $content = decode_json($content) if defined $content && !ref $content && ( $res->{headers}{'content-type'} // '' ) =~ m[json];
        return $self->_video_error( $res, $content ) unless $res->{success};
        $self->_unwrap_job($content);
    }

    method uploadVideoJob ( $bytes, $mime_type = 'video/mp4', %opts ) {
        if    ( builtin::blessed $bytes ) { $bytes = $bytes->slurp_raw }
        elsif ( !ref $bytes && $bytes !~ /[\x00-\x1f]/ && -e $bytes ) {
            $bytes = path($bytes)->slurp_raw;
        }
        $opts{did} //= $self->did;
        my $base  = $opts{host} // $video_service;
        my $query = join( '&', map { "$_=" . URI::Escape::uri_escape( $opts{$_} ) } grep { defined $opts{$_} } qw[did name] );
        my $url   = "$base/xrpc/app.bsky.video.uploadVideo" . ( $query ? "?$query" : '' );

        # uploadVideo writes into the PDS on our behalf, so the token audience
        # is the PDS and the lexicon is uploadBlob, not uploadVideo.
        my $token = $opts{token} // $self->_service_token( $opts{aud} // $self->_pds_did, 'com.atproto.repo.uploadBlob', $opts{exp} );
        return $token if builtin::blessed $token;
        my $res
            = $self->_video_http->post( $url, { content => $bytes, headers => { Authorization => "Bearer $token", 'Content-Type' => $mime_type } } );
        my $content = $res->{content};
        $content = decode_json($content) if defined $content && !ref $content && ( $res->{headers}{'content-type'} // '' ) =~ m[json];

        # 409 Conflict means the video was already processed; the body still
        # carries a usable jobStatus (including the finished blob).
        return $self->_video_error( $res, $content ) unless $res->{success} || $res->{status} == 409;
        $self->_unwrap_job($content);
    }

    # Drafts (private post drafts via stash)
    method getDrafts(%args) {
        my $res = $self->_at_for('app.bsky.draft.getDrafts')->get( 'app.bsky.draft.getDrafts' => \%args );
        $res ? $res->{drafts} // () : $res;
    }

    method createDraft($draft) {
        $self->_at_for('app.bsky.draft.createDraft')->post( 'app.bsky.draft.createDraft' => { draft => $draft } );
    }

    method updateDraft($draft) {
        $self->_at_for('app.bsky.draft.updateDraft')->post( 'app.bsky.draft.updateDraft' => { draft => $draft } );
    }

    method deleteDraft($id) {
        $self->_at_for('app.bsky.draft.deleteDraft')->post( 'app.bsky.draft.deleteDraft' => { id => $id } );
    }

    # Contacts (secure contact-import matching)
    method getContactMatches(%args) {
        my $res = $self->_at_for('app.bsky.contact.getMatches')->get( 'app.bsky.contact.getMatches' => \%args );
        $res ? $res->{matches} // () : $res;
    }

    method getContactSyncStatus() {
        my $res = $self->_at_for('app.bsky.contact.getSyncStatus')->get('app.bsky.contact.getSyncStatus');
        $res ? $res->{syncStatus} // () : $res;
    }

    method importContacts(%args) {
        my $res = $self->_at_for('app.bsky.contact.importContacts')->post( 'app.bsky.contact.importContacts' => \%args );
        $res ? $res->{matchesAndContactIndexes} // () : $res;
    }

    method dismissContactMatch($subject) {
        $self->_at_for('app.bsky.contact.dismissMatch')->post( 'app.bsky.contact.dismissMatch' => { subject => $subject } );
    }

    method removeContactData() {
        $self->_at_for('app.bsky.contact.removeData')->post('app.bsky.contact.removeData');
    }

    method startPhoneVerification($phone) {
        $self->_at_for('app.bsky.contact.startPhoneVerification')->post( 'app.bsky.contact.startPhoneVerification' => { phone => $phone } );
    }

    method verifyPhone( $phone, $code ) {
        my $res = $self->_at_for('app.bsky.contact.verifyPhone')->post( 'app.bsky.contact.verifyPhone' => { phone => $phone, code => $code } );
        $res ? $res->{token} // () : $res;
    }

    # Age assurance
    method beginAgeAssurance(%args) {
        $self->_at_for('app.bsky.ageassurance.begin')->post( 'app.bsky.ageassurance.begin' => \%args );
    }

    method getAgeAssuranceConfig() {
        $self->_at_for('app.bsky.ageassurance.getConfig')->get('app.bsky.ageassurance.getConfig');
    }

    method getAgeAssuranceState(%args) {
        $self->_at_for('app.bsky.ageassurance.getState')->get( 'app.bsky.ageassurance.getState' => \%args );
    }

    # Utils
    method parse_mentions($text) {
        my @spans;
        push @spans, { start => $-[1], handle => $2, end => $+[1] }
            while $text =~ /(?:\A|\W)(@(([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?))/g;
        @spans;
    }

    method parse_urls($text) {
        my @spans;

        # partial/naive URL regex based on: https://stackoverflow.com/a/3809435
        # tweaked to disallow some training punctuation
        push @spans, { start => $-[1], url => $1, end => $+[1] }
            while $text
            =~ /(?:\A|\W)(https?:\/\/(www\.)?[-a-zA-Z0-9\@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9\(\)\@:%_\+.~#?&\/\/=]*[-a-zA-Z0-9@%_\+~#\/\/=])?)/g;
        @spans;
    }

    method parse_tags($text) {
        my @spans;
        push @spans, { start => $-[1], tag => $2, end => $+[1] } while $text =~ /(?:\A|\W)(#+(\w{1, 640}))/g;
        @spans;
    }

    method parse_facets($text) {
        my @facets;
        for my $m ( $self->parse_mentions($text) ) {
            my $res = $self->at->get( 'com.atproto.identity.resolveHandle', { handle => $m->{handle} } );

            # if handle cannot be resolved, just skip it. Bluesky will display it as plain text
            $res || next;
            push @facets,
                {
                index    => { byteStart => $m->{start}, byteEnd => $m->{end} },
                features => [ { '$type' => 'app.bsky.richtext.facet#mention', did => $res->{did} } ]
                };
        }
        for my $m ( $self->parse_urls($text) ) {
            push @facets,
                {
                index    => { byteStart => $m->{start}, byteEnd => $m->{end} },
                features => [ { '$type' => 'app.bsky.richtext.facet#link', uri => $m->{url} } ]
                };
        }
        for my $m ( $self->parse_tags($text) ) {
            push @facets,
                {
                index    => { byteStart => $m->{start}, byteEnd => $m->{end} },
                features => [ { '$type' => 'app.bsky.richtext.facet#tag', tag => $m->{tag} } ]
                };
        }
        @facets;
    }

    method parse_uri($uri) {
        require At::Protocol::URI;    # Should already be loaded but...
        $uri = At::Protocol::URI->new($uri) unless builtin::blessed $uri;
        { repo => $uri->host, collection => $uri->collection, rkey => $uri->rkey };
    }

    method getReplyRefs($parent_uri) {
        my $res = $self->at->get( 'com.atproto.repo.getRecord', $self->parse_uri($parent_uri) );
        $res || return;
        my $root = my $parent = $res;
        if ( $parent->{value}{reply} ) {
            $root = $self->at->get( 'com.atproto.repo.getRecord', $self->parse_uri( $parent->{value}{reply}{root}{uri} ) );
            $res ||= $parent;    # escape hatch
        }
        { root => { uri => $root->{uri}, cid => $root->{cid} }, parent => { uri => $parent->{uri}, cid => $parent->{cid} } };
    }

    method uploadFile( $bytes, $mime_type //= undef ) {
        if    ( builtin::blessed $bytes ) { $bytes = $bytes->slurp_raw }
        elsif ( !ref $bytes && $bytes !~ /[\x00-\x1f]/ && -e $bytes ) {
            $bytes = path($bytes)->slurp_raw;
        }

        # TODO: a non-naive implementation would strip EXIF metadata from JPEG files here by default
        my $determined_mime
            = defined $mime_type ? $mime_type :
            ( $bytes =~ /^GIF89a/ ? 'image/gif' :
                $bytes =~ /^.{2}JFIF/                                  ? 'image/jpeg' :
                $bytes =~ /^.{4}PNG\r\n\x1a\n/                         ? 'image/png' :
                $bytes =~ /^.{8}BM/                                    ? 'image/bmp' :
                $bytes =~ /^.{4}(II|MM)\x42\x4D/                       ? 'image/tiff' :
                $bytes =~ /^.{4}8BPS/                                  ? 'image/psd' :
                $bytes =~ /^data:image\/svg\+xml;/                     ? 'image/svg+xml' :
                $bytes =~ /^.{4}ftypqt /                               ? 'video/quicktime' :
                $bytes =~ /^.{4}ftyp(isom|mp4[12]?|MSNV|M4[v|a]|f4v)/i ? 'video/mp4' :
                'application/octet-stream' );
        my $at_http = $self->at->http;
        my $url     = sprintf( '%s/xrpc/%s', $self->at->host, 'com.atproto.repo.uploadBlob' );
        my %headers = ( 'Content-Type' => $determined_mime );
        if ( $at_http && $at_http->can('auth') && $at_http->auth ) {
            $headers{'Authorization'} = $at_http->auth;
        }
        if ( $at_http && $at_http->can('token_type') && $at_http->token_type eq 'DPoP' && $at_http->can('_generate_dpop_proof') ) {
            $headers{DPoP} = $at_http->_generate_dpop_proof( $url, 'POST' );
        }
        state $http //= HTTP::Tiny->new;
        my $res     = $http->post( $url, { content => $bytes, headers => \%headers } );
        my $content = $res->{content};

        # Retry on DPoP nonce issues
        if ( !$res->{success} ) {
            my $body = $content;
            if ( $body && !ref $body && ( $res->{status} == 401 || $res->{status} == 400 ) ) {
                if ( $body =~ /use_dpop_nonce|dpop_nonce|required nonce|nonce in dpop|DPoP.*nonce/i && $at_http && $at_http->can('dpop_nonce') ) {
                    my $nonce;
                    foreach my $k ( keys %{ $res->{headers} } ) {
                        if ( lc($k) eq 'dpop-nonce' ) { $nonce = $res->{headers}{$k}; last; }
                    }
                    $at_http->dpop_nonce($nonce) if defined $nonce && $nonce ne '';
                    if ( $at_http && $at_http->can('_generate_dpop_proof') ) {
                        $headers{DPoP} = $at_http->_generate_dpop_proof( $url, 'POST' );
                    }
                    $res     = $http->post( $url, { content => $bytes, headers => \%headers } );
                    $content = $res->{content};
                }
            }
        }
        if ( $res->{success} ) {
            $content = decode_json($content) if $content && ( $res->{headers}{'content-type'} // '' ) =~ m[json];
            return $content->{blob};
        }
        my $msg = $res->{reason} // 'Unknown error';
        if ( $content && ( $res->{headers}{'content-type'} // '' ) =~ m[json] ) {
            my $json = decode_json($content);
            $msg .= ': ' . $json->{message} if $json->{message};
        }
        return At::Error->new( message => $msg, fatal => 1 );
    }

    # Upload a single image (path, bytes, handle, or Path::Tiny object),
    # enforcing the 1 MB legacy image guard, and return its blob. Shared by
    # the images and gallery embeds.
    method _upload_image ( $img, $mime = undef ) {
        if ( builtin::blessed $img && $img->can('slurp_raw') ) {
            my $sz = $img->can('size') ? $img->size : length( $img->slurp_raw );
            At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . $sz )->throw if $sz > 1000000;
            $img = $img->slurp_raw;
        }
        elsif ( !ref $img && $img !~ /[\x00-\x1f]/ && -e $img ) {
            my $p  = path($img);
            my $sz = $p->size;
            At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . $sz )->throw if $sz > 1000000;
            $img = $p->slurp_raw;
        }
        else {
            my $sz = length $img;
            At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . $sz )->throw if $sz > 1000000;
        }
        my $blob = $self->uploadFile( $img, $mime );
        builtin::blessed($blob) && $blob->isa('At::Error') ? $blob->throw : ();
        $blob || At::Error->new( message => 'upload failed', fatal => 1 )->throw;
        $blob;
    }

    # app.bsky.embed.images - up to 4 images, each { image, alt, [aspectRatio] }
    method uploadImages(@images) {
        my @ret;
        for my $img (@images) {
            my ( $alt, $mime, $aspectRatio ) = ( '', undef, undef );
            if ( ( builtin::reftype($img) // '' ) eq 'HASH' ) {
                $alt         = $img->{alt}  // '';
                $mime        = $img->{mime} // ();
                $aspectRatio = $img->{aspectRatio};
                $img         = $img->{image};
            }
            my $blob = $self->_upload_image( $img, $mime );
            push @ret, { alt => $alt, image => $blob, ( defined $aspectRatio ? ( aspectRatio => $aspectRatio ) : () ), };
        }
        { '$type' => 'app.bsky.embed.images', images => \@ret };
    }

    # app.bsky.embed.gallery - up to 20 media items (soft limit 10 in clients),
    # each item being an app.bsky.embed.gallery#image { image, alt, [aspectRatio] }
    method uploadGallery(@items) {
        my @ret;
        for my $item (@items) {
            my ( $alt, $mime, $aspectRatio ) = ( '', undef, undef );
            if ( ( builtin::reftype($item) // '' ) eq 'HASH' ) {
                $alt         = $item->{alt}  // '';
                $mime        = $item->{mime} // ();
                $aspectRatio = $item->{aspectRatio};
                $item        = $item->{image};
            }
            my $blob = $self->_upload_image( $item, $mime );
            push @ret,
                {
                '$type' => 'app.bsky.embed.gallery#image',
                image   => $blob,
                alt     => $alt,
                ( defined $aspectRatio ? ( aspectRatio => $aspectRatio ) : () ),
                };
        }
        { '$type' => 'app.bsky.embed.gallery', items => \@ret };
    }

    method uploadVideoCaption( $lang, $caption ) {
        if ( builtin::blessed $caption && $caption->can('slurp_raw') ) {
            my $sz = $caption->can('size') ? $caption->size : length( $caption->slurp_raw );
            At::Error->new( message => 'caption file size too large. 20000 bytes maximum, got: ' . $sz )->throw if $sz > 20000;
            $caption = $caption->slurp_raw;
        }
        else {
            my $sz = length $caption;
            At::Error->new( message => 'caption file size too large. 20000 bytes maximum, got: ' . $sz )->throw if $sz > 20000;
        }
        my $blob = $self->uploadFile( $caption, 'text/vtt' );
        builtin::blessed($blob) && $blob->isa('At::Error') ? $blob->throw : ();
        $blob || At::Error->new( message => 'upload failed', fatal => 1 )->throw;
        { '$type' => 'app.bsky.embed.video#caption', lang => $lang, file => $blob };
    }

    # Build an app.bsky.embed.video from an already-uploaded blob (for example
    # the processed blob returned by getVideoJobStatus after uploadVideoJob).
    # %opts: alt, aspectRatio, presentation (default|gif), captions
    # (either { lang => file } or [ { lang => ..., file => ... } ]).
    method videoEmbed ( $blob, %opts ) {
        my @captions;
        if ( defined $opts{captions} ) {
            my $captions = $opts{captions};
            if ( ( builtin::reftype($captions) // '' ) eq 'HASH' ) {
                @captions = map { $self->uploadVideoCaption( $_, $captions->{$_} ) } sort keys %$captions;
            }
            elsif ( ( builtin::reftype($captions) // '' ) eq 'ARRAY' ) {
                for my $c (@$captions) {
                    next unless ( builtin::reftype($c) // '' ) eq 'HASH';
                    push @captions, $self->uploadVideoCaption( $c->{lang}, $c->{file} // $c->{caption} // $c->{vtt} );
                }
            }
        }
        {   '$type' => 'app.bsky.embed.video',
            video   => $blob,
            ( @captions                   ? ( captions     => \@captions )          : () ), ( defined $opts{alt} ? ( alt => $opts{alt} ) : () ),
            ( defined $opts{aspectRatio}  ? ( aspectRatio  => $opts{aspectRatio} )  : () ),
            ( defined $opts{presentation} ? ( presentation => $opts{presentation} ) : () ),
        };
    }

    method uploadVideo($vid) {
        my ( $alt, $mime, $aspectRatio, $presentation, $captions );
        if ( ( builtin::reftype($vid) // '' ) eq 'HASH' ) {
            $alt          = $vid->{alt};
            $mime         = $vid->{mime} // ();
            $aspectRatio  = $vid->{aspectRatio};
            $presentation = $vid->{presentation};
            $captions     = $vid->{captions};
            $vid          = $vid->{video};
        }
        if ( builtin::blessed $vid && $vid->can('slurp_raw') ) {
            my $szv = $vid->can('size') ? $vid->size : length( $vid->slurp_raw );
            At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . $szv )->throw if $szv > 50000000;
            $vid = $vid->slurp_raw;
        }
        elsif ( !ref $vid && $vid !~ /[\x00-\x1f]/ && -e $vid ) {
            my $pv = path($vid);
            At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . $pv->size )->throw if $pv->size > 50000000;
            $vid = $pv->slurp_raw;
        }
        else {
            At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . length $vid )->throw if length $vid > 50000000;
        }
        my $blob = $self->uploadFile( $vid, $mime );
        builtin::blessed($blob) && $blob->isa('At::Error') ? $blob->throw : ();
        $blob || At::Error->new( message => 'upload failed', fatal => 1 )->throw;
        return $self->videoEmbed( $blob, alt => $alt, aspectRatio => $aspectRatio, presentation => $presentation, captions => $captions );
    }

    method getEmbedRef($uri) {
        my $res = $self->at->get( 'com.atproto.repo.getRecord', $self->parse_uri($uri) );
        $res || return;
        { '$type' => 'app.bsky.embed.record', record => { uri => $res->{uri}, cid => $res->{cid} } };
    }

    method fetch_embed_url_card($url) {
        my %card = ( uri => $url, title => '', description => '' );
        state $http //= HTTP::Tiny->new;
        my $res = $http->get($url);
        if ( $res->{success} ) {
            ( $card{title} )       = $res->{content} =~ m[<title>(.*?)</title>.*</head>]is;
            ( $card{description} ) = ( $res->{content} =~ m[<meta name="description" content="(.*?)".+</meta>.*</head>]is ) // '';
            my ($image) = $res->{content} =~ m[<img.*?src="([^"]*)"[^>]*>(?:</img>)?]isp;
            if ( defined $image ) {
                if ( $image =~ /^data:/ ) {
                    $card{thumb} = $self->uploadFile($image);
                }
                else {
                    $res = $http->get( URI->new_abs( $image, $url ) );
                    $card{thumb} = $res->{success} ? $self->uploadFile( $res->{content}, $res->{headers}{'content-type'} ) : ();
                }
            }
        }
        { '$type' => 'app.bsky.embed.external', external => \%card };
    }
};
#
1;
