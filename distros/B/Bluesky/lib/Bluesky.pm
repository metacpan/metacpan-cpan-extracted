package Bluesky 1.00 {
    use v5.40;
    use Carp qw[carp];
    use bytes;
    use feature 'class';
    no warnings 'experimental::class', 'experimental::try';
    use At;
    use Path::Tiny;
    use HTTP::Tiny;
    use URI;
    use JSON::PP;
    #
    class Bluesky {
        field $at           : reader;
        field $service      : param //= 'https://bsky.social';
        field $chat_service : param //= 'https://api.bsky.chat';
        #
        ADJUST {
            $at = At->new( host => $service );
        }

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
            my $scope      = $args{scope}      // 'atproto transition:generic transition:chat.bsky';
            my $on_success = $args{on_success} // sub { say 'Success! Session established.' };

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
                                    Mojo::IOLoop->timer( 1 => sub { exit 0 } );
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
                    my $daemon = Mojo::Server::Daemon->new( app => $app, listen => [ 'http://127.0.0.1:' . $port ] );
                    $daemon->run();
                    return;    # Exit method if listener ran (it blocks until finished or exits)
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
                if ( defined $args{embed}{images} ) {
                    $post{embed} = $self->uploadImages( @{ $args{embed}{images} } );
                }
                elsif ( defined $args{embed}{video} ) {
                    $post{embed} = $self->uploadVideo( $args{embed}{video} );
                }
                elsif ( defined $args{embed}{url} ) {
                    $post{embed} = $self->fetch_embed_url_card( $args{embed}{url} );
                }
                elsif ( defined $args{embed}{ref} ) {
                    $post{embed} = $self->getEmbedRef( $args{embed}{ref} );
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
                        elsif ( $type eq 'following' ) { push @allow, { '$type' => 'app.bsky.feed.threadgate#followingRule' }; }
                        elsif ( $type eq 'list' ) { push @allow, { '$type' => 'app.bsky.feed.threadgate#listRule', list => $args{reply_gate_list} }; }
                    }
                }
                $self->at->create_record( 'app.bsky.feed.threadgate',
                    { post => $post_uri->as_string, allow => \@allow, createdAt => $self->at->_now->to_string, },
                    $post_uri->rkey );    # Must match post rkey
            }
            return $res;
        }

        method deletePost($at_uri) {
            $at_uri = At::Protocol::URI->new($at_uri) unless builtin::blessed $at_uri;
            $self->at->delete_record( 'app.bsky.feed.post', $at_uri->rkey );

            # Automatically try to delete threadgate too
            $self->at->delete_record( 'app.bsky.feed.threadgate', $at_uri->rkey );
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

        method getLists( $actor, %args ) {
            my $res = $self->_at_for('app.bsky.graph.getLists')->get( 'app.bsky.graph.getLists' => { actor => $actor, %args } );
            $res ? $res->{lists} // () : $res;
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
            my $res
                = $self->_at_for('app.bsky.graph.getActorStarterPacks')->get( 'app.bsky.graph.getActorStarterPacks' => { actor => $actor, %args } );
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
            $res ? $res->{profiles} : $res;
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
            elsif ( ( $^O eq 'MSWin32' ? $bytes !~ m/[\x00<>:"\/\\|?*]/ : 1 ) && -e $bytes ) {
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
            my %headers = ( 'Content-Type' => $determined_mime, ( $at_http->auth ? ( 'Authorization' => $at_http->auth ) : () ), );
            $headers{DPoP} = $at_http->_generate_dpop_proof( $url, 'POST' ) if $at_http->token_type eq 'DPoP';
            state $http //= HTTP::Tiny->new;
            my $res     = $http->post( $url, { content => $bytes, headers => \%headers } );
            my $content = $res->{content};

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

        method uploadImages(@images) {
            my @ret;
            for my $img (@images) {
                my $alt  = '';
                my $mime = ();
                if ( ( builtin::reftype($img) // '' ) eq 'HASH' ) {
                    $alt  = $img->{alt};
                    $mime = $img->{mime} // ();
                    $img  = $img->{image};
                }
                if ( builtin::blessed $img ) {
                    At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . $img->size )->throw
                        if $img->size > 1000000;
                    $img = $img->slurp_raw;
                }
                elsif ( ( $^O eq 'MSWin32' ? $img !~ m/[\x00<>:"\/\\|?*]/ : 1 ) && -e $img ) {
                    $img = path($img);
                    At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . $img->size )->throw
                        if $img->size > 1000000;
                    $img = path($img)->slurp_raw;
                }
                else {
                    At::Error->new( message => 'image file size too large. 1000000 bytes maximum, got: ' . length $img )->throw
                        if length $img > 1000000;
                }
                my $blob = $self->uploadFile( $img, $mime );
                $blob || $blob->throw;
                push @ret, { alt => $alt, image => $blob };
            }
            { '$type' => 'app.bsky.embed.images', images => \@ret };
        }

        method uploadVideoCaption( $lang, $caption ) {
            if ( builtin::blessed $caption ) {
                At::Error->new( message => 'caption file size too large. 20000 bytes maximum, got: ' . $caption->size )->throw
                    if $caption->size > 20000;
                $caption = $caption->slurp_raw;
            }
            elsif ( ( $^O eq 'MSWin32' ? $caption !~ m/[\x00<>:"\/\\|?*]/ : 1 ) && -e $caption ) {
                $caption = path($caption);
                At::Error->new( message => 'caption file size too large. 20000 bytes maximum, got: ' . $caption->size )->throw
                    if $caption->size > 20000;
                $caption = path($caption)->slurp_raw;
            }
            else {
                At::Error->new( message => 'cation file size too large. 20000 bytes maximum, got: ' . length $caption )->throw
                    if length $caption > 20000;
            }
            my $blob = $self->uploadFile( $caption, 'text/vtt' );
            $blob || $blob->throw;
            { '$type' => 'app.bsky.embed.video#caption', lang => $lang, file => $blob };
        }

        method uploadVideo($vid) {
            my @ret;
            my ( $alt, $mime, $aspectRatio );
            my @captions;
            if ( ( builtin::reftype($vid) // '' ) eq 'HASH' ) {
                $alt         = $vid->{alt};
                $mime        = $vid->{mime} // ();
                $aspectRatio = $vid->{aspectRatio};
                @captions    = map { { lang => $_, file => $self->uploadFile( $vid->{captions}{$_}, 'text/vtt' ) } } keys %{ $vid->{captions} };
                $vid         = $vid->{video};
            }
            if ( builtin::blessed $vid ) {
                At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . $vid->size )->throw if $vid->size > 50000000;
                $vid = $vid->slurp_raw;
            }
            elsif ( ( $^O eq 'MSWin32' ? $vid !~ m/[\x00<>:"\/\\|?*]/ : 1 ) && -e $vid ) {
                $vid = path($vid);
                At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . $vid->size )->throw if $vid->size > 50000000;
                $vid = path($vid)->slurp_raw;
            }
            else {
                At::Error->new( message => 'video file size too large. 50000000 bytes maximum, got: ' . length $vid )->throw
                    if length $vid > 50000000;
            }
            my $blob = $self->uploadFile( $vid, $mime );
            $blob || return $blob->throw;
            return {
                '$type' => 'app.bsky.embed.video',
                video   => $blob,
                ( @captions            ? ( captions    => \@captions )   : () ), ( defined $alt ? ( alt => $alt ) : () ),
                ( defined $aspectRatio ? ( aspectRatio => $aspectRatio ) : () )
            };
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
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

Bluesky - Bluesky Client Library in Perl

=head1 SYNOPSIS

    use Bluesky;
    my $bsky = Bluesky->new();

    # Interactive OAuth Authentication (Recommended)
    $bsky->oauth_helper(
        handle => 'user.bsky.social',
        listen => 1, # Automatically catch the redirect
        on_success => sub { say 'Logged in!' }
    );

    # Posting
    $bsky->createPost( text => 'Hello from Perl!' );

    # Streaming
    my $fh = $bsky->firehose(sub ( $header, $body, $err ) {
        return warn $err if $err;
        say 'New event: ' . $header->{t};
    });
    $fh->start();

=head1 DESCRIPTION

You shouldn't need to know the AT protocol in order to get things done so I'm including this sugary wrapper so that
L<At> can remain mostly technical.

=head1 Constructor and Session Management

Bluesky.pm is my attempt to make use of Perl's class syntax so this is obviously OO.

=head2 C<new( ... )>

    my $bsky = Bluesky->new( 'sanko', '1111-2222-3333-4444' );

Expected parameters include:

=over

=item C<identifier> - required

Handle or other identifier supported by the server for the authenticating user.

=item C<password> - required

This is the app password not the account's password. App passwords are generated at
L<https://bsky.app/settings/app-passwords>.

=back

=head2 C<oauth_start( $handle, $client_id, $redirect_uri, [ $scope ] )>

Initiates the OAuth 2.0 Authorization Code flow. Returns the authorization URL.

    my $url = $bsky->oauth_start(
        'user.bsky.social',
        'http://localhost',
        'http://127.0.0.1:8888/callback'
    );

=head2 C<oauth_callback( $code, $state )>

Exchanges the authorization code for tokens and completes the OAuth flow.

    $bsky->oauth_callback( $code, $state );

=head2 C<oauth_helper( %args )>

A high-level helper to manage the entire OAuth flow. This is the recommended way to authenticate for interactive
applications.

    $bsky->oauth_helper(
        handle     => 'user.bsky.social',
        listen     => 1,
        on_success => sub ($self) {
            say 'Authenticated as ' . $self->did;
        }
    );

Expected parameters include:

=over

=item C<handle> - required

The user's handle or DID.

=item C<listen>

Boolean. If true, attempts to start a local HTTP server (using L<Mojolicious::Lite>) to automatically capture the
C<code> and C<state> from the redirect.

=item C<redirect>

The redirect URI. Defaults to C<http://127.0.0.1:8888/callback>.

=item C<scope>

The requested OAuth scopes. Defaults to C<atproto chat.bsky.convo>.

=item C<on_success>

A callback subroutine invoked after a successful login. Receives the C<$bsky> object as an argument.

=back

=head2 C<firehose( $callback, [ $url ] )>

Returns a new L<At::Protocol::Firehose> client for real-time streaming.

    my $fh = $bsky->firehose(sub ($header, $body, $err) { ... });
    $fh->start();

See L<At::Protocol::Firehose> for more details.

=head1 Feed and Content

Methods in this category create, modify, access, and delete content.

=head2 C<getTrendingTopics( [...] )>

    $bsky->getTrendingTopics( );

Get a list of trending topics.

Expected parameters include:

=over

=item C<viewer>

DID of the account making the request (not included for public/unauthenticated queries). Used to boost followed
accounts in ranking.

=item C<limit>

Integer.

Default: C<10>, Minimum: C<1>, Maximum: C<25>.

=back

=head2 C<getTimeline( [...] )>

    $bsky->getTimeline();

Get a view of the requesting account's home timeline. This is expected to some form of reverse-chronological feed.

Expected parameters include:

=over

=item C<algorithm>

Variant 'algorithm' for timeline. Implementation-specific.

NOTE: most feed flexibility has been moved to feed generator mechanism.

=item C<limit>

Integer.

Default: C<50>, Minimum: C<1>, Maximum: C<100>.

=item C<cursor>

=back

=head2 C<getFeed( ... )>

    $bsky->getFeed( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );

Get a hydrated feed from a feed generator.

=head2 C<getFeedSkeleton( ... )>

    $bsky->getFeedSkeleton( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );

Get a feed skeleton (list of URIs) from a feed generator.

=head2 C<getAuthorFeed( ... )>

    $bsky->getAuthorFeed( actor => 'sankorobinson.com' );

Get a view of an actor's 'author feed' (post and reposts by the author).

Expected parameters include:

=over

=item C<actor> - required

AT-identifier for the author.

=item C<limit>

Integer.

Default: C<50>, Minimum: C<1>, Maximum: C<100>.

=item C<cursor>

=item C<filter>

Combinations of post/repost types to include in response.

Known values:

=over

=item C<posts_with_replies> - default

=item C<posts_no_replies>

=item C<posts_with_media>

=item C<posts_and_author_threads>

=back

=item C<includePins>

Boolean value (false is default).

=back

An error is returned if the client is blocked by the actor.

=head2 C<getPostThread( ... )>

    $bsky->getPostThread( uri => 'at://bsky.app/app.bsky.feed.post/3l6oveex3ii2l' );

Get posts in a thread. Does not require auth, but additional metadata and filtering will be applied for authed
requests.

Expected parameters include:

=over

=item C<uri> - required

Reference (AT-URI) to post record.

=item C<depth>

How many levels of reply depth should be included in response.

Default: C<6>, Minimum: C<0>, Maximum: C<1000>.

=item C<parentHeight>

How many levels of parent (and grandparent, etc) post to include.

Default: C<80>, Minimum: C<0>, Maximum: C<1000>.

=back

Returns an error if the thread cannot be found.

=head2 C<getFeed( ... )>

    $bsky->getFeed( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );

Get a hydrated feed from a feed generator.

=head2 C<getFeedSkeleton( ... )>

    $bsky->getFeedSkeleton( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );

Get a feed skeleton (list of URIs) from a feed generator.

=head2 C<getPost( ... )>

    $bsky->getPost('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2');

Gets a single post view for a specified post (by AT-URI).

Expected parameters include:

=over

=item C<uri> - required

AT-URI.

=back

=head2 C<getPosts( ... )>

    $bsky->getPosts(
        'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l',
        'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3lbvgvbvcf22c'
    );

Gets post views for a specified list of posts (by AT-URI). This is sometimes referred to as 'hydrating' a 'feed
skeleton'.

Expected parameters include:

=over

=item C<uris> - required

List of (up to 25) post AT-URIs to return hydrated views for.

=back

=head2 C<getLikes( ... )>

    $bsky->getLikes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Get like records which reference a subject (by AT-URI and CID).

Expected parameters include:

=over

=item C<uri> - required

AT-URI of the subject (eg, a post record).

=item C<cid>

CID of the subject record (aka, specific version of record), to filter likes.

=item C<limit>

Integer.

Default: 50, Minimum: 1, Maximum: 100.

=item C<cursor>

=back

=head2 C<getBookmarks( ... )>

    $bsky->getBookmarks();

Get private bookmarks for the authorized account.

=head2 C<createBookmark( ... )>

    $bsky->createBookmark( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Create a private bookmark for a post.

=head2 C<deleteBookmark( ... )>

    $bsky->deleteBookmark( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Delete a private bookmark.

=head2 C<getQuotes( ... )>

    $bsky->getQuotes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Get quotes of a post.

=head2 C<getActorLikes( ... )>

    $bsky->getActorLikes( actor => 'sankorobinson.com' );

Get a list of posts liked by an actor.

=head2 C<searchPosts( ... )>

    $bsky->searchPosts( q => 'perl' );

Find posts matching search criteria.

=head2 C<getSuggestedFeeds( ... )>

    $bsky->getSuggestedFeeds();

Get suggested feed generators.

=head2 C<describeFeedGenerator( )>

    $bsky->describeFeedGenerator();

Get information about a feed generator.

=head2 C<getFeedGenerator( ... )>

    $bsky->getFeedGenerator( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );

Get information about a feed generator.

=head2 C<getFeedGenerators( ... )>

    $bsky->getFeedGenerators( feeds => [ ... ] );

Get information about multiple feed generators.

=head2 C<getActorFeeds( ... )>

    $bsky->getActorFeeds( actor => 'sankorobinson.com' );

Get a list of feed generators created by an actor.

=head2 C<getRepostedBy( ... )>

    $bsky->getRepostedBy( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Get repost records which reference a subject (by AT-URI and CID).

=head2 C<createPost( ... )>

    $bsky->createPost( text => 'Test. Test. Test.' );

Create a new post.

Expected parameters include:

=over

=item C<text> - required

The primary post content. May be an empty string, if there are embeds.

Annotations of text (mentions, URLs, hashtags, etc) are automatically parsed. These include:

=over

=item mentions

Facet feature for mention of another account. The text is usually a handle, including a '@' prefix, but the facet
reference is a DID.

    This is an example. Here, I am mentioning @atproto.bsky.social and it links to their profile.

=item links

Facet feature for a URL. The text URL may have been simplified or truncated, but the facet reference should be a
complete URL.

    This is an example that would link to Google here: https://google.com/.

=item tags

Facet feature for a hashtag. The text usually includes a '#' prefix, but the facet reference should not (except in the
case of 'double hash tags').

    This is an example that would link to a few hashtags. #perl #atproto

=back

=item C<timestamp>

Client-declared timestamp (ISO 8601 in UTC) when this post was originally created.

Defaults to the current time.

=item C<lang>

Indicates human language of post primary text content.

    $bsky->createPost(
        lang     => [ 'en', 'ja' ],
        reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
        text     => 'こんにちは, World!'
    );

This is expected to be a comma separated string of language codes (e.g. C<en-US,en;q=0.9,fr>).

Bluesky recommends sending the C<Accept-Language> header to get posts in the user's preferred language. See
L<https://www.w3.org/International/questions/qa-lang-priorities.en> and
L<https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry>.

=item C<reply_to>

AT-URL of a post to reply to.

    $bsky->createPost( reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27', text => 'Exactly!' );

=item C<reply_gate>

Arrayref of rules to restrict who can reply to this post.

Supported rules:

=over

=item C<mention> - Only users mentioned in the post can reply.

=item C<following> - Only users the author follows can reply.

=item C<list> - Only users in a specific moderation list can reply (requires C<reply_gate_list>).

=back

Example:

    $bsky->createPost( text => 'Private post', reply_gate => ['following'] );

=item C<reply_gate_list>

The AT-URI of a moderation list to use with the C<list> rule in C<reply_gate>.

=item C<embed>

Bluesky allows for posts to contain embedded data.

Known embed types:

=over

=item C<images>

Up to 4 images (path name or raw data).

Set alt text by passing a hash.

    $bsky->createPost(
        embed    => { images => ['path/to/my.jpg'] },
        lang     => 'en',
        reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
        text     => 'I found this image on https://google.com/'
    );

    $bsky->createPost(
        embed    => { images => [{ alt => 'Might be a picture of a frog.', image => 'path/to/my.jpg' }] },
        lang     => 'en',
        reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
        text     => 'I found this image on https://google.com/'
    );

=item C<url>

A card (including the URL, the page title, and a description) will be presented in a GUI.

    $bsky->createPost( embed => { url => 'https://en.wikipedia.org/wiki/Main_Page' }, text => <<'END');
    This is the link to wikipedia, @atproto.bsky.social. You should check it out.
    END

=item C<ref>

An AT-URL to link from this post.

=item C<video>

A video to be embedded in a Bluesky record (eg, a post).

    $bsky->createPost( embed => { video => 'path/to/cat.mpeg' }, text => 'Loot at this little guy!' );

This might be a single path, raw data, or a hash reference (if you're really into what and how the video is presented).

If passed a hash, the following are expected:

=over

=item C<video> - required

The path name.

=item C<alt>

Alt text description of the video, for accessibility.

=item C<mime>

Mime type.

We try to figure this out internally if undefined.

=item C<aspectRatio>

Represents an aspect ratio.

It may be approximate, and may not correspond to absolute dimensions in any given unit.

    ...
    aspectRatio =>{ width => 100, height => 120 },
    ...

=item C<captions>

This is a hash reference of up to 20 L<WebVTT|https://en.wikipedia.org/wiki/WebVTT> files organized by language.

    ...
    captions => {
        en => 'english.vtt',
        ja => 'japanese.vtt'
    },
    ...

=back

=back

You may also pass your own valid embed.

=item C<labels>

Self-label values for this post. Effectively content warnings.

=item C<tags>

Additional hashtags, in addition to any included in post text and facets.

These are not visible in the current Bluesky interface but do cause posts to return as results to to search (such as
L<https://bsky.app/hashtag/perl>.

=back

Note that a post may only contain one of the following embeds: C<image>, C<video>, C<embed_url>, or C<embed_ref>.

=head2 C<deletePost( ... )>

    $bsky->deletePost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

    my $post = $bsky->createPost( ... );
    ...
    $bsky->deletePost( $post->{uri} );

Delete a post or ensures it doesn't exist.

Expected parameters include:

=over

=item C<uri> - required

=back

=head2 C<like( ... )>

    $bsky->like( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

    $bsky->like( 'at://did:plc:totallymadeupgarbagehere/app.bsky.feed.post/randomexample', 'fu82qrfrf829crw89rfpuwcfiosdfcu8239wcrusiofcv2epcuy8r9jkfsl' );

Like a post publically.

Expected parameters include:

=over

=item C<uri> - required

The AT-URI of the post.

=item C<cid>

If undefined, the post is fetched to gather this for you.

=back

On success, a record is returned.

=head2 C<deleteLike( ... )>

    $bsky->deleteLike( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

    $bsky->deleteLike( 'at://did:plc:totallymadeupgarbagehere/app.bsky.feed.like/randomexample' );

Remove a like record.

Expected parameters include:

=over

=item C<uri> - required

The AT-URI of the post or the like record itself.

=back

On success, commit info is returned.

=head2 C<repost( ... )>

    $bsky->repost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

Repost a post.

Expected parameters include:

=over

=item C<uri> - required

The AT-URI of the post.

=item C<cid>

If undefined, the post is fetched to gather this for you.

=back

=head2 C<deleteRepost( ... )>

    $bsky->deleteRepost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.repost/3lcdwvquo7y25' );

Remove a repost record.

=head2 C<uploadBlob( ... )>

    $bsky->uploadBlob( $data, mime_type => 'image/png' );

Upload a blob (file/data) to the PDS. This is a wrapper around C<uploadFile>.

=head1 Social Graph

Methods documented in this section deal with relationships between the authorized user and other members of the social
network.

=head2 C<block( ... )>

    $bsky->block( 'sankorobinson.com' );

Blocks a user.

Expected parameters include:

=over

=item C<identifier> - required

Handle or DID of the person you'd like to block.

=back

=head2 C<getBlocks( ... )>

    $bsky->getBlocks( );

Enumerates which accounts the requesting account is currently blocking.

Requires auth.

Expected parameters include:

=over

=item C<uri>

AT-URI of the subject (eg, a post record).

=item C<limit>

Integer.

Default: 50, Minimum: 1, Maximum: 100.

=item C<cursor>

=back

Returns a list of actor profile views on success.

=head2 C<deleteBlock( ... )>

    $bsky->deleteBlock( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.block/3l6oveex3ii2l' );

Unblocks a user by removing the block record.

=head2 C<follow( ... )>

    $bsky->follow( 'sankorobinson.com' );

Follows a user.

=head2 C<deleteFollow( ... )>

    $bsky->deleteFollow( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.follow/3l6oveex3ii2l' );

Unfollows a user by removing the follow record.

=head2 C<getFollows( ... )>

    $bsky->getFollows( 'sankorobinson.com' );

Enumerates who an account is following.

=head2 C<getFollowers( ... )>

    $bsky->getFollowers( 'sankorobinson.com' );

Enumerates who is following an account.

=head2 C<getKnownFollowers( ... )>

    $bsky->getKnownFollowers( 'sankorobinson.com' );

Enumerates followers of an account that the authorized user also follows (mutuals).

=head2 C<getRelationships( ... )>

    $bsky->getRelationships( actors => ['sankorobinson.com', 'bsky.app'] );

Enumerates relationships between the authorized user and other actors.

=head2 C<getMutes( ... )>

    $bsky->getMutes();

Enumerate actors that the authorized user has muted.

=head2 C<muteThread( ... )>

    $bsky->muteThread( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Mute a thread.

=head2 C<unmuteThread( ... )>

    $bsky->unmuteThread( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );

Unmute a thread.

=head2 C<getLists( ... )>

    $bsky->getLists( 'sankorobinson.com' );

Enumerate moderation lists created by an actor.

=head2 C<getList( ... )>

    $bsky->getList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );

Get detailed view of a moderation list.

=head2 C<getStarterPack( ... )>

    $bsky->getStarterPack( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.starterpack/3l6oveex3ii2l' );

Get a detailed view of a starter pack.

=head2 C<getStarterPacks( ... )>

    $bsky->getStarterPacks( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.starterpack/3l6oveex3ii2l' );

Get views for a list of starter packs.

=head2 C<getActorStarterPacks( ... )>

    $bsky->getActorStarterPacks( 'sankorobinson.com' );

Get starter packs created by an actor.

=head1 Actors

Methods in this section deal with profile information and actor discovery.

=head2 C<getProfile( ... )>

    $bsky->getProfile( 'sankorobinson.com' );

Get detailed profile view of an actor.

=head2 C<getPreferences( )>

    $bsky->getPreferences();

Get private preferences for the authorized account.

=head2 C<putPreferences( ... )>

    $bsky->putPreferences( [ ... ] );

Update private preferences for the authorized account.

=head2 C<upsertProfile( &callback )>

    $bsky->upsertProfile( sub (%existing) {
        return { %existing, displayName => 'New Name' };
    });

Retrieve the current profile, allow a callback to modify it, and then update it.

=head2 C<getProfiles( ... )>

    $bsky->getProfiles( actors => ['sankorobinson.com', 'bsky.app'] );

Get detailed profile views of multiple actors.

=head2 C<getSuggestions( )>

    $bsky->getSuggestions();

Get a list of suggested actors.

=head2 C<searchActors( ... )>

    $bsky->searchActors( q => 'perl' );

Search for actors.

=head2 C<searchActorsTypeahead( ... )>

    $bsky->searchActorsTypeahead( q => 'san' );

Find actor suggestions for a partial search term.

=head2 C<mute( ... )>

    $bsky->mute( 'sankorobinson.com' );

Mutes an actor.

=head2 C<unmute( ... )>

    $bsky->unmute( 'sankorobinson.com' );

Unmutes an actor.

=head2 C<muteModList( ... )>

    $bsky->muteModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );

Mutes all actors in a moderation list.

=head2 C<unmuteModList( ... )>

    $bsky->unmuteModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );

Unmutes all actors in a moderation list.

=head2 C<blockModList( ... )>

    $bsky->blockModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );

Blocks all actors in a moderation list.

=head2 C<unblockModList( ... )>

    $bsky->unblockModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.listblock/3l6oveex3ii2l' );

Unblocks a moderation list.

=head1 Moderation

=head2 C<mute( ... )>

    $bsky->mute( 'sankorobinson.com' );

Mutes an actor.

=head2 C<unmute( ... )>

    $bsky->unmute( 'sankorobinson.com' );

Unmutes an actor.

=head2 C<report( $subject, $reason_type, [ $reason ] )>

Submits a moderation report.

Expected parameters:

=over

=item C<$subject> - The AT-URI or DID being reported.

=item C<$reason_type> - Lexicon-defined reason (e.g., C<com.atproto.moderation.defs#reasonSpam>).

=item C<$reason> - Optional free-text description.

=back

=head1 Notifications

Methods in this section deal with notifications.

=head2 C<listNotifications( ... )>

    $bsky->listNotifications();

Enumerate notifications for the authorized user.

=head2 C<countUnreadNotifications( )>

    $bsky->countUnreadNotifications();

Count unread notifications.

=head2 C<updateSeenNotifications( [ $seenAt ] )>

    $bsky->updateSeenNotifications();

Update when notifications were last seen.

=head1 Identity

Methods in this section deal with handle and DID resolution.

=head2 C<resolveHandle( ... )>

    $bsky->resolveHandle( 'sankorobinson.com' );

Resolves a handle to a DID.

=head2 C<updateHandle( ... )>

    $bsky->updateHandle( 'new-handle.bsky.social' );

Updates the handle for the authorized user.

=head2 C<describeServer( )>

    $bsky->describeServer();

Describes the server's account creation requirements and capabilities.

=head2 C<listRecords( ... )>

    $bsky->listRecords( repo => 'sankorobinson.com', collection => 'app.bsky.feed.post' );

List records in a repository collection.

=head2 C<getLabelerServices( ... )>

    $bsky->getLabelerServices( dids => [ ... ] );

Get views of labeler services.

=head1 Chat

Methods in this section deal with direct messaging and conversations.

=head2 C<listConvos( [...] )>

    $bsky->listConvos();

Enumerates conversations for the authorized user.

=head2 C<getConvo( $convoId )>

    $bsky->getConvo( $convoId );

Get a detailed view of a conversation.

=head2 C<getConvoForMembers( actors =E<gt> [ ... ] )>

    $bsky->getConvoForMembers( actors => [ 'did:plc:...' ] );

Get or create a conversation for a list of members.

=head2 C<getMessages( convoId =E<gt> ..., [...] )>

    $bsky->getMessages( convoId => $convoId );

Get messages in a conversation.

=head2 C<sendMessage( $convoId, { text =E<gt> ... } )>

    $bsky->sendMessage( $convoId, { text => 'Hello!' } );

Send a message to a conversation.

=head2 C<acceptConvo( $convoId )>

    $bsky->acceptConvo( $convoId );

Accept a conversation request.

=head2 C<leaveConvo( $convoId )>

    $bsky->leaveConvo( $convoId );

Leave a conversation.

=head2 C<updateRead( $convoId, [ $messageId ] )>

    $bsky->updateRead( $convoId );

Update the read status of a conversation.

=head2 C<muteConvo( $convoId )>

    $bsky->muteConvo( $convoId );

Mute a conversation.

=head2 C<unmuteConvo( $convoId )>

    $bsky->unmuteConvo( $convoId );

Unmute a conversation.

=head2 C<addReaction( $convoId, $messageId, $reaction )>

    $bsky->addReaction( $convoId, $messageId, '👍' );

Add a reaction to a message.

=head2 C<removeReaction( $convoId, $messageId, $reaction )>

    $bsky->removeReaction( $convoId, $messageId, '👍' );

Remove a reaction from a message.

=head2 C<deleteMessageForSelf( $convoId, $messageId )>

    $bsky->deleteMessageForSelf( $convoId, $messageId );

Delete a message for the local user.

=head2 C<getConvoAvailability( [...] )>

    $bsky->getConvoAvailability();

Check if the authorized user can join conversations.

=head2 C<getLog( [...] )>

    $bsky->getLog();

Get a log of chat events.

=head1 See Also

L<At> - AT Protocol library

L<App::bsky> - Bluesky client on the command line

L<https://docs.bsky.app/docs/api/>

=head1 Perl Starter Pack

I've created a starter pack of Perl folks on Bluesky.

Follow it at L<https://bsky.app/starter-pack/sankorobinson.com/3lk3xd5utq52s> and get in touch to have yourself added.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

Bluesky unfollow reposts auth authed

=end stopwords

=cut
