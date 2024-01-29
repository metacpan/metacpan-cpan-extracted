package At::Bluesky {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use At;
    use Carp;
    #
    use At::Lexicon::com::atproto::label;
    use At::Lexicon::app::bsky::actor;
    use At::Lexicon::app::bsky::embed;
    use At::Lexicon::app::bsky::graph;
    use At::Lexicon::app::bsky::richtext;
    use At::Lexicon::app::bsky::notification;
    use At::Lexicon::app::bsky::feed;
    use At::Lexicon::app::bsky::unspecced;
    #
    class At::Bluesky : isa(At) {
        field $_host : param(_host) //= 'https://bsky.social';

        # Required in subclasses of At
        method host { URI->new($_host) }
    }

    #~ class At::Lexicon::Bluesky::Actor
    {

        method actor_getPreferences () {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.getPreferences' ) );
            $res = At::Lexicon::app::bsky::actor::preferences->new( items => $res->{preferences} ) if defined $res->{preferences};
            $res;
        }

        method actor_getProfile ($actor) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.getProfile' ), { content => +{ actor => $actor } } );
            $res = At::Lexicon::app::bsky::actor::profileViewDetailed->new(%$res) if defined $res->{did};
            $res;
        }

        method actor_getProfiles (@ids) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'getProfiles( ... ) expects no more than 25 actors' if scalar @ids > 25;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.getProfiles' ), { content => +{ actors => \@ids } } );
            $res->{profiles} = [ map { At::Lexicon::app::bsky::actor::profileViewDetailed->new(%$_) } @{ $res->{profiles} } ]
                if defined $res->{profiles};
            $res;
        }

        method actor_getSuggestions ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'getSuggestions( ... ) expects a limit between 1 and 100 (default: 50)' if defined $limit && ( $limit < 1 || $limit > 100 );
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.getSuggestions' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{actors} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{actors} } ] if defined $res->{actors};
            $res;
        }

        method actor_searchActorsTypeahead ( $q, $limit //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'getSuggestions( ... ) expects a limit between 1 and 100 (default: 50)' if defined $limit && ( $limit < 1 || $limit > 100 );
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.searchActorsTypeahead' ),
                { content => +{ q => $q, defined $limit ? ( limit => $limit ) : () } }
            );
            $res->{actors} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{actors} } ] if defined $res->{actors};
            $res;
        }

        method actor_searchActors ( $q, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'searchActorsTypeahead( ... ) expects a limit between 1 and 100 (default: 25)'
                if defined $limit && ( $limit < 1 || $limit > 100 );
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.searchActors' ),
                { content => +{ q => $q, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{actors} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{actors} } ] if defined $res->{actors};
            $res;
        }

        method actor_putPreferences (@preferences) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $preferences = At::Lexicon::app::bsky::actor::preferences->new( items => \@preferences );
            my $res         = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.actor.putPreferences' ),
                { content => +{ preferences => $preferences->_raw } } );
            $res->{success};
        }
    }

    #~ class At::Lexicon::Bluesky::Feed
    {

        method feed_getSuggestedFeeds ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getSuggestedFeeds' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{feeds} = [ map { At::Lexicon::app::bsky::feed::generatorView->new(%$_) } @{ $res->{feeds} } ] if defined $res->{feeds};
            $res;
        }

        method feed_getTimeline ( $algorithm //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getTimeline' ),
                {   content => +{
                        defined $algorithm ? ( algorithm => $algorithm ) : (),
                        defined $limit     ? ( limit     => $limit )     : (),
                        defined $cursor    ? ( cursor    => $cursor )    : ()
                    }
                }
            );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::feedViewPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_searchPosts ( $q, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.searchPosts' ),
                { content => +{ q => $q, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{posts} = [ map { At::Lexicon::app::bsky::feed::postView->new(%$_) } @{ $res->{posts} } ] if defined $res->{posts};
            $res;
        }

        method feed_getAuthorFeed ( $actor, $limit //= (), $filter //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getAuthorFeed' ),
                {   content => +{
                        actor => $actor,
                        defined $limit ? ( limit => $limit ) : (), defined $filter ? ( filter => $filter ) : (),
                        defined $cursor ? ( cursor => $cursor ) : ()
                    }
                }
            );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::feedViewPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_getRepostedBy ( $uri, $cid //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getRepostedBy' ),
                {   content => +{
                        uri => ( builtin::blessed $uri? $uri->as_string : $uri ),
                        defined $cid ? ( cid => $cid ) : (), defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : ()
                    }
                }
            );
            $res->{uri}        = URI->new( $res->{uri} ) if defined $res->{uri};
            $res->{repostedBy} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{repostedBy} } ]
                if defined $res->{repostedBy};
            $res;
        }

        method feed_getActorFeeds ( $actor, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getActorFeeds' ),
                { content => +{ actor => $actor, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{feeds} = [ map { At::Lexicon::app::bsky::feed::generatorView->new(%$_) } @{ $res->{feeds} } ] if defined $res->{feeds};
            $res;
        }

        method feed_getActorLikes ( $actor, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::cluck 'limit is too large' if defined $limit && $limit < 0;
            Carp::cluck 'limit is too small' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getActorLikes' ),
                { content => +{ actor => $actor, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::feedViewPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_getPosts (@uris) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'too many uris' if scalar @uris > 25;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getPosts' ), { content => +{ uris => \@uris } } );
            $res->{posts} = [ map { At::Lexicon::app::bsky::feed::postView->new(%$_) } @{ $res->{posts} } ] if defined $res->{posts};
            $res;
        }

        method feed_getPostThread ( $uri, $depth //= (), $parentHeight //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'depth is too low'         if defined $depth        && $depth < 0;
            Carp::confess 'depth is too high'        if defined $depth        && $depth > 1000;
            Carp::confess 'parentHeight is too low'  if defined $parentHeight && $parentHeight < 0;
            Carp::confess 'parentHeight is too high' if defined $parentHeight && $parentHeight > 1000;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getPostThread' ),
                {   content =>
                        +{ uri => $uri, defined $depth ? ( depth => $depth ) : (), defined $parentHeight ? ( parentHeight => $parentHeight ) : () }
                }
            );
            $res->{thread} = At::_topkg( $res->{thread}->{'$type'} )->new( %{ $res->{thread} } )
                if defined $res->{thread} && defined $res->{thread}{'$type'};
            $res;
        }

        method feed_getLikes ( $uri, $cid //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'limit is too low'  if defined $limit && $limit < 1;
            Carp::confess 'limit is too high' if defined $limit && $limit > 100;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getLikes' ),
                {   content => +{
                        uri => $uri,
                        defined $cid ? ( cid => $cid ) : (), defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : ()
                    }
                }
            );
            $res->{likes} = [ map { At::Lexicon::app::bsky::feed::getLikes::like->new(%$_) } @{ $res->{likes} } ] if defined $res->{likes};
            $res;
        }

        method feed_getListFeed ( $list, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'limit is too low'  if defined $limit && $limit < 1;
            Carp::confess 'limit is too high' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getListFeed' ),
                { content => +{ list => $list, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::feedViewPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_getFeedSkeleton ( $feed, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            Carp::confess 'limit is too low'  if defined $limit && $limit < 1;
            Carp::confess 'limit is too high' if defined $limit && $limit > 100;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getFeedSkeleton' ),
                { content => +{ feed => $feed, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::skeletonFeedPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_getFeedGenerator ($feed) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getFeedGenerator' ), { content => +{ feed => $feed } } );
            $res->{view} = At::Lexicon::app::bsky::feed::generatorView->new( %{ $res->{view} } ) if defined $res->{view};
            $res;
        }

        method feed_getFeedGenerators (@feeds) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res
                = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getFeedGenerators' ), { content => +{ feeds => \@feeds } } );
            $res->{feeds} = [ map { At::Lexicon::app::bsky::feed::generatorView->new(%$_) } @{ $res->{feeds} } ] if defined $res->{feeds};
            $res;
        }

        method feed_getFeed ( $feed, $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.getFeed' ),
                { content => +{ feed => $feed, defined $cursor ? ( cursor => $cursor ) : () } }
            );
            $res->{feed} = [ map { At::Lexicon::app::bsky::feed::feedViewPost->new(%$_) } @{ $res->{feed} } ] if defined $res->{feed};
            $res;
        }

        method feed_describeFeedGenerator () {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.feed.describeFeedGenerator' ) );
            $res->{did}   = At::Protocol::DID->new( uri => $res->{did} ) if defined $res->{did};
            $res->{feeds} = [ map { At::Lexicon::app::bsky::feed::describeFeedGenerator::feed->new(%$_) } @{ $res->{feeds} } ]
                if defined $res->{feeds};
            $res->{links} = At::Lexicon::app::bsky::feed::describeFeedGenerator::links->new( %{ $res->{links} } ) if defined $res->{links};
            $res;
        }
    }

    #~ class At::Lexicon::Bluesky::Graph
    {

        method graph_getBlocks ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getBlocks' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{blocks} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{blocks} } ] if defined $res->{blocks};
            $res;
        }

        method graph_getFollowers ( $actor, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getFollowers' ),
                { content => +{ actor => $actor, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{subject}   = At::Lexicon::app::bsky::actor::profileView->new( %{ $res->{subject} } )                 if defined $res->{subject};
            $res->{followers} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{followers} } ] if defined $res->{followers};
            $res;
        }

        method graph_getFollows ( $actor, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getFollows' ),
                { content => +{ actor => $actor, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{subject} = At::Lexicon::app::bsky::actor::profileView->new( %{ $res->{subject} } )               if defined $res->{subject};
            $res->{follows} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{follows} } ] if defined $res->{follows};
            $res;
        }

        method graph_getList ( $list, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getList' ),
                { content => +{ list => $list, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{list}  = At::Lexicon::app::bsky::graph::listView->new( %{ $res->{list} } )                    if defined $res->{list};
            $res->{items} = [ map { At::Lexicon::app::bsky::graph::listItemView->new(%$_) } @{ $res->{items} } ] if defined $res->{items};
            $res;
        }

        method graph_getListBlocks ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getListBlocks' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{lists} = [ map { At::Lexicon::app::bsky::graph::listView->new(%$_) } @{ $res->{lists} } ] if defined $res->{lists};
            $res;
        }

        method graph_getListMutes ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getListMutes' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{lists} = [ map { At::Lexicon::app::bsky::graph::listView->new(%$_) } @{ $res->{lists} } ] if defined $res->{lists};
            $res;
        }

        method graph_getLists ( $actor, $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getLists' ),
                { content => +{ actor => $actor, defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{lists} = [ map { At::Lexicon::app::bsky::graph::listView->new(%$_) } @{ $res->{lists} } ] if defined $res->{lists};
            $res;
        }

        method graph_getMutes ( $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getMutes' ),
                { content => +{ defined $limit ? ( limit => $limit ) : (), defined $cursor ? ( cursor => $cursor ) : () } } );
            $res->{mutes} = [ map { At::Lexicon::app::bsky::actor::profileView->new(%$_) } @{ $res->{mutes} } ] if defined $res->{mutes};
            $res;
        }

        method graph_getRelationships ( $actor, $others //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            use URI;
            $actor  = URI->new($actor) unless builtin::blessed $actor;
            $others = [ map { builtin::blessed $_ ? $_ : URI->new($_) } @$others ] if defined $others;
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getRelationships' ),
                { content => +{ actor => $actor->as_string, defined $others ? ( others => [ map { $_->as_string } @$others ] ) : (), } } );
            $res->{actor}         = At::Protocol::DID->new( uri => $res->{actor} ) if defined $res->{actor};
            $res->{relationships} = [ map { $_ = At::_topkg( $_->{'$type'} )->new( %{$_} ) if defined $_->{'$type'}; } @{ $res->{relationships} } ]
                if defined $res->{relationships};
            $res;
        }

        method graph_getSuggestedFollowsByActor ($actor) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.getSuggestedFollowsByActor' ),
                { content => +{ actor => $actor } } );

            # XXX: current lexicon incorrectly claims this is a list of profileView objects
            $res->{suggestions} = [ map { At::Lexicon::app::bsky::actor::profileViewDetailed->new(%$_) } @{ $res->{suggestions} } ]
                if defined $res->{suggestions};
            $res;
        }

        method graph_muteActor ($actor) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.muteActor' ), { content => +{ actor => $actor } } );
            $res->{success};
        }

        method graph_muteActorList ($list) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.muteActorList' ), { content => +{ list => $list } } );
            $res->{success};
        }

        method graph_unmuteActor ($actor) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.unmuteActor' ), { content => +{ actor => $actor } } );
            $res->{success};
        }

        method graph_unmuteActorList ($list) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res
                = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.graph.unmuteActorList' ), { content => +{ list => $list } } );
            $res->{success};
        }
    }

    #~ class At::Lexicon::Bluesky::Notification
    {

        method notification_listNotifications ( $seenAt //= (), $limit //= 50, $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            $seenAt = At::Protocol::Timestamp->new( timestamp => $seenAt ) if defined $seenAt && !builtin::blessed $seenAt;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.notification.listNotifications' ),
                {   content => +{
                        defined $limit  ? ( limit  => $limit )                                             : (),
                        defined $cursor ? ( cursor => $cursor )                                            : (),
                        defined $seenAt ? ( seenAt => builtin::blessed $seenAt ? $seenAt->_raw : $seenAt ) : ()
                    }
                }
            );
            $res->{notifications} = [ map { At::Lexicon::app::bsky::notification->new(%$_) } @{ $res->{notifications} } ]
                if defined $res->{notifications};
            $res;
        }

        method notification_getUnreadCount ( $seenAt //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            $seenAt = At::Protocol::Timestamp->new( timestamp => $seenAt ) if defined $seenAt && builtin::blessed $seenAt;
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.notification.getUnreadCount' ),
                { content => +{ defined $seenAt ? ( seenAt => $seenAt->_raw ) : () } }
            );
            $res;
        }

        method notification_updateSeen ($seenAt) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            $seenAt = At::Protocol::Timestamp->new( timestamp => $seenAt ) unless builtin::blessed $seenAt;
            my $res = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.notification.updateSeen' ),
                { content => +{ seenAt => $seenAt->_raw } } );
            $res->{success};
        }

        method notification_registerPush ( $appId, $platform, $serviceDid, $token ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->post( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.notification.registerPush' ),
                { content => +{ appId => $appId, platform => $platform, serviceDid => $serviceDid, token => $token } } );
            $res->{success};
        }
    }

    #~ class At::Lexicon::Bluesky::Unspecced
    {

        method unspecced_getPopularFeedGenerators ( $query //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.unspecced.getPopularFeedGenerators' ),
                {   content => +{
                        defined $query  ? ( query  => $query )  : (),
                        defined $limit  ? ( limit  => $limit )  : (),
                        defined $cursor ? ( cursor => $cursor ) : ()
                    }
                }
            );
            $res->{feeds} = [ map { At::Lexicon::app::bsky::feed::generatorView->new(%$_) } @{ $res->{feeds} } ] if defined $res->{feeds};
            $res;
        }

        method unspecced_getTaggedSuggestions ( ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get( sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.unspecced.getTaggedSuggestions' ), );
            $res->{suggestions} = [ map { At::Lexicon::app::bsky::unspecced::suggestion->new(%$_) } @{ $res->{suggestions} } ]
                if defined $res->{suggestions};
            $res;
        }

        method unspecced_searchActorsSkeleton ( $query //= (), $typeahead //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.unspecced.searchActorsSkeleton' ),
                {   content => +{
                        defined $query     ? ( q         => $query )     : (),
                        defined $typeahead ? ( typeahead => $typeahead ) : (),
                        defined $limit     ? ( limit     => $limit )     : (),
                        defined $cursor    ? ( cursor    => $cursor )    : ()
                    }
                }
            );
            $res->{actors} = [ map { At::Lexicon::app::bsky::unspecced::skeletonSearchActor->new(%$_) } @{ $res->{actors} } ]
                if defined $res->{actors};
            $res;
        }

        method unspecced_searchPostsSkeleton ( $query //= (), $limit //= (), $cursor //= () ) {
            $self->http->session // Carp::confess 'requires an authenticated client';
            my $res = $self->http->get(
                sprintf( '%s/xrpc/%s', $self->host(), 'app.bsky.unspecced.searchPostsSkeleton' ),
                {   content => +{
                        defined $query  ? ( q      => $query )  : (),
                        defined $limit  ? ( limit  => $limit )  : (),
                        defined $cursor ? ( cursor => $cursor ) : ()
                    }
                }
            );
            $res->{posts} = [ map { At::Lexicon::app::bsky::unspecced::skeletonSearchPost->new(%$_) } @{ $res->{posts} } ] if defined $res->{posts};
            $res;
        }
    }
};
1;
__END__
=encoding utf-8

=head1 NAME

At::Bluesky - Bluesky Extentions to the Core AT Protocol

=head1 SYNOPSIS

    use At::Bluesky;
    my $bsky = At::Bluesky->new( identifier => 'sanko', password => '1111-2222-3333-4444');
    $bsky->actor_getProfiles( 'xkcd.com', 'marthawells.bsky.social' );

=head1 DESCRIPTION

The AT Protocol is a "social networking technology created to power the next generation of social applications." The
Bluesky lexicons are official extensions to the core spec.

=head1 Methods

As a subclass of At.pm, see that module for inherited methods.

=head2 C<new( ... )>

    At::Bluesky->new( identifier => 'sanko', password => '1111-2222-3333-4444' );

Expected parameters include:

=over

=item C<identifier> - required

Handle or other identifier supported by the server for the authenticating user.

=item C<password> - required

This is the app password not the account's password. App passwords are generated at
L<https://bsky.app/settings/app-passwords>.

=back

=head2 C<actor_getPreferences( )>

    $bsky->actor_getPreferences;

Get private preferences attached to the account.

On success, returns a new C<At::Lexicon::app::bsky::actor::preferences> object.

=head2 C<actor_getProfile( ... )>

    $bsky->actor_getProfile( 'sankor.bsky.social' );

Get detailed profile view of an actor.

On success, returns a new C<At::Lexicon::app::bsky::actor::profileViewDetailed> object.

=head2 C<actor_getProfiles( ... )>

    $bsky->actor_getProfiles( 'xkcd.com', 'marthawells.bsky.social' );

Get detailed profile views of multiple actors.

On success, returns a list of up to 25 new C<At::Lexicon::app::bsky::actor::profileViewDetailed> objects.

=head2 C<actor_getSuggestions( [...] )>

    $bsky->actor_getSuggestions( ); # grab 50 results

    my $res = $bsky->actor_getSuggestions( 75 ); # limit number of results to 75

    $bsky->actor_getSuggestions( 75, $res->{cursor} ); # look for the next group of 75 results

Get a list of suggested actors, used for discovery.

Expected parameters include:

=over

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of actors as new C<At::Lexicon::app::bsky::actor::profileView> objects and (optionally) a
cursor.

=head2 C<actor_searchActorsTypeahead( ..., [...] )>

    $bsky->actor_searchActorsTypeahead( 'joh' ); # grab 10 results

    $bsky->actor_searchActorsTypeahead( 'joh', 30 ); # limit number of results to 30

Find actor suggestions for a prefix search term.

Expected parameters include:

=over

=item C<query> - required

Search query prefix; not a full query string.

=item C<limit>

Maximum of 100, minimum of 1, and 10 is the default.

=back

On success, returns a list of actors as new C<At::Lexicon::app::bsky::actor::profileViewBasic> objects.

=head2 C<actor_searchActors( ..., [...] )>

    $bsky->actor_searchActors( 'john' ); # grab 25 results

    my $res = $bsky->actor_searchActors( 'john', 30 ); # limit number of results to 30

    $bsky->actor_searchActors( 'john', 30, $res->{cursor} ); # next 30 results

Find actors (profiles) matching search criteria.

Expected parameters include:

=over

=item C<query> - required

Search query string. Syntax, phrase, boolean, and faceting is unspecified, but Lucene query syntax is recommended.

=item C<limit>

Maximum of 100, minimum of 1, and 25 is the default.

=item C<cursor>

=back

On success, returns a list of actors as new C<At::Lexicon::app::bsky::actor::profileViewBasic> objects and (optionally)
a cursor.

=head2 C<actor_putPreferences( ... )>

    $bsky->actor_putPreferences( { '$type' => 'app.bsky.actor#adultContentPref', enabled => false } ); # pass along a coerced adultContentPref object

Set the private preferences attached to the account. This may be an C<At::Lexicon::app::bsky::actor::adultContentPref>,
C<At::Lexicon::app::bsky::actor::contentLabelPref>, C<At::Lexicon::app::bsky::actor::savedFeedsPref>,
C<At::Lexicon::app::bsky::actor::personalDetailsPref>, C<At::Lexicon::app::bsky::actor::feedViewPref>, or
C<At::Lexicon::app::bsky::actor::threadViewPref>. They're coerced if not already objects.

On success, returns a true value.

=head2 C<feed_getSuggestedFeeds( [...] )>

    $bsky->feed_getSuggestedFeeds( );

Get a list of suggested feeds for the viewer.

Expected parameters include:

=over

=item C<limit>

The number of feeds to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns a list of feeds as new C<At::Lexicon::app::bsky::feed::generatorView> objects and (optionally) a
cursor.

=head2 C<feed_getTimeline( [...] )>

    $bsky->feed_getTimeline( );

    $bsky->feed_getTimeline( 'reverse-chronological', 30 );

Get a view of the actor's home timeline.

Expected parameters include:

=over

=item C<algorithm>

Potential values include: C<reverse-chronological>

=item C<limit>

The number of posts to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns the feed containing a list of new C<At::Lexicon::app::bsky::feed::feedViewPost> objects and
(optionally) a cursor.

=head2 C<feed_searchPosts( ..., [...] )>

    $bsky->feed_searchPosts( "perl" );

Find posts matching search criteria.

Expected parameters include:

=over

=item C<q> - required

Search query string; syntax, phrase, boolean, and faceting is unspecified, but Lucene query syntax is recommended.

=item C<limit>

The number of posts to return. Min. is 1, max is 100, 25 is the default.

=item C<cursor>

Optional pagination mechanism; may not necessarily allow scrolling through entire result set.

=back

On success, returns a list of posts containing new C<At::Lexicon::app::bsky::feed::postView> objects and (optionally) a
cursor. The total number of hits might also be returned. If so, the value may be rounded/truncated, and it may not be
possible to paginate through all hits

=head2 C<feed_getAuthorFeed( ..., [...] )>

    $bsky->feed_getAuthorFeed( "bsky.app" );

Get a view of an actor's feed.

Expected parameters include:

=over

=item C<actor> - required

=item C<limit>

The number of posts to return. Min. is 1, max is 100, 50 is the default.

=item C<filter>

Options:

=over

=item C<posts_with_replies> - default

=item C<posts_no_replies>

=item C<posts_with_media>

=item C<posts_and_author_threads>

=back

=item C<cursor>

Optional pagination mechanism; may not necessarily allow scrolling through entire result set.

=back

On success, returns a feed of posts containing new C<At::Lexicon::app::bsky::feed::feedViewPost> objects and
(optionally) a cursor.

=head2 C<feed_getRepostedBy( ..., [...] )>

    $bsky->feed_getRepostedBy( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3kghpdkfnsk2i' );

Get a list of reposts.

Expected parameters include:

=over

=item C<uri> - required

=item C<cid>

=item C<limit>

The number of authors to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns the original uri, a list of reposters as C<At::Lexicon::app::bsky::actor::profileView> objects and
(optionally) a cursor and the original cid.

=head2 C<feed_getActorFeeds( ..., [...] )>

    $bsky->feed_getActorFeeds( 'bsky.app' );

Get a list of feeds created by the actor.

Expected parameters include:

=over

=item C<actor> - required

=item C<limit>

The number of feeds to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns a list of feeds as C<At::Lexicon::app::bsky::feed::generatorView> objects and (optionally) a
cursor.

=head2 C<feed_getActorLikes( ..., [...] )>

    $bsky->feed_getActorLikes( 'bsky.app' );

Get a list of posts liked by an actor.

Expected parameters include:

=over

=item C<actor> - required

=item C<limit>

The number of posts to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns a list of posts as C<At::Lexicon::app::bsky::feed::feedViewPost> objects and (optionally) a cursor.

=head2 C<feed_getPosts( ... )>

    $bsky->feed_getPosts( 'at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24' );

Get a view of an actor's feed.

Expected parameters include:

=over

=item C<uris> - required

List of C<at://> URIs. No more than 25 at a time.

=back

On success, returns a list of posts as C<At::Lexicon::app::bsky::feed::postView> objects.

=head2 C<feed_getPostThread( ..., [...] )>

    $bsky->feed_getPostThread( 'at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24' );

Get posts in a thread.

Expected parameters include:

=over

=item C<uri> - required

An C<at://> URI.

=item C<depth>

Integer. Maximum value: 1000, Minimum value: 0, Default: 6.

=item C<parentHeight>

Integer. Maximum value: 1000, Minimum value: 0, Default: 80.

=back

On success, returns the thread containing replies as a new C<At::Lexicon::app::bsky::feed::threadViewPost> object.

=head2 C<feed_getLikes( ..., [...] )>

    $bsky->feed_getLikes( 'at://did:plc:ewvi7nxzyoun6zhxrhs64oiz/app.bsky.feed.post/3kftlbujmfk24' );

Get the list of likes.

Expected parameters include:

=over

=item C<uri> - required

=item C<cid>

=item C<limit>

The number of likes to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns the original URI, a list of likes as C<At::Lexicon::app::bsky::feed::getLikes::like> objects and
(optionally) a cursor, and the original cid.

=head2 C<feed_getListFeed( ..., [...] )>

    $bsky->feed_getListFeed( 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.graph.list/3k4diugcw3k2p' );

Get a view of a recent posts from actors in a list.

Expected parameters include:

=over

=item C<list> - required

=item C<limit>

The number of results to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns feed containing a list of C<At::Lexicon::app::bsky::feed::feedViewPost> objects and (optionally) a
cursor.

=head2 C<feed_getFeedSkeleton( ..., [...] )>

    $bsky->feed_getFeedSkeleton( 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.graph.list/3k4diugcw3k2p' );

Get a skeleton of a feed provided by a feed generator.

Expected parameters include:

=over

=item C<feed> - required

=item C<limit>

The number of results to return. Min. is 1, max is 100, 50 is the default.

=item C<cursor>

=back

On success, returns a feed containing a list of C<At::Lexicon::app::bsky::feed::skeletonFeedPost> objects and
(optionally) a cursor.

=head2 C<feed_getFeedGenerator( ... )>

    $bsky->feed_getFeedGenerator( 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.feed.generator/aaalfodybabzy' );

Get information about a feed generator.

Expected parameters include:

=over

=item C<feed> - required

=back

On success, returns a C<At::Lexicon::app::bsky::feed::generatorView> object and booleans indicating the feed's online
status and validity.

=head2 C<feed_getFeedGenerators( ... )>

    $bsky->feed_getFeedGenerators( 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.feed.generator/aaalfodybabzy', 'at://did:plc:eaf...' );

Get information about a list of feed generators.

Expected parameters include:

=over

=item C<feeds> - required

=back

On success, returns a list of feeds as new C<At::Lexicon::app::bsky::feed::generatorView> objects.

=head2 C<feed_getFeed( ..., [...] )>

    $bsky->feed_getFeed( 'at://did:plc:kyttpb6um57f4c2wep25lqhq/app.bsky.graph.list/3k4diugcw3k2p' );

Get a hydrated feed from an actor's selected feed generator.

Expected parameters include:

=over

=item C<feed> - required

=item C<cursor>

=back

On success, returns feed containing a list of C<At::Lexicon::app::bsky::feed::feedViewPost> objects and (optionally) a
cursor.

=head2 C<graph_getBlocks( [ ... ] )>

    $bsky->graph_getBlocks( );

Get a list of who the actor is blocking.

Expected parameters include:

=over

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::actor::profileView> objects.

=head2 C<graph_getFollowers( ..., [ ... ] )>

    $bsky->graph_getFollowers('sankor.bsky.social');

Get a list of an actor's followers.

Expected parameters include:

=over

=item C<actor>

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of followers as C<At::Lexicon::app::bsky::actor::profileView> objects and the original actor
as the subject, and, potentially, a cursor.

=head2 C<graph_getFollows( ..., [ ... ] )>

    $bsky->graph_getFollows('sankor.bsky.social');

Get a list of who the actor follows.

Expected parameters include:

=over

=item C<actor>

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of follows as C<At::Lexicon::app::bsky::actor::profileView> objects and the original actor
as the subject, and, potentially, a cursor.

=head2 C<graph_getList( ..., [ ... ] )>

    $bsky->graph_getList('at://did:plc:.../app.bsky.graph.list/...');

Get a list of actors.

Expected parameters include:

=over

=item C<list>

Full AT URI.

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::graph::listItemView> objects, the original list as a
C<At::Lexicon::app::bsky::graph::listView> object and, potentially, a cursor.

=head2 C<graph_getListBlocks( [ ... ] )>

    $bsky->graph_getListBlocks( );

Get lists that the actor is blocking.

Expected parameters include:

=over

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::graph::listView> objects and, potentially, a cursor.

=head2 C<graph_getListMutes( [ ... ] )>

    $bsky->graph_getListMutes( );

Get lists that the actor is muting.

Expected parameters include:

=over

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::graph::listView> objects and, potentially, a cursor.

=head2 C<graph_getLists( ..., [ ... ] )>

    $bsky->graph_getLists('sankor.bsky.social');

Get a list of lists that belong to an actor.

Expected parameters include:

=over

=item C<actor>

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::graph::listView> objects and, potentially, a cursor.

=head2 C<graph_getMutes( [ ... ] )>

    $bsky->graph_getMutes( );

Get a list of who the actor mutes.

Expected parameters include:

=over

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::actor::profileView> objects.

=head2 C<graph_getRelationships( ... )>

    $bsky->graph_getRelationships('sankor.bsky.social');

Enumerates public relationships between one account, and a list of other accounts.

Expected parameters include:

=over

=item C<actor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::graph::relationship> objects and, optionally, the primary
actor.

=head2 C<graph_getSuggestedFollowsByActor( ... )>

    $bsky->graph_getSuggestedFollowsByActor('sankor.bsky.social');

Get suggested follows related to a given actor.

Expected parameters include:

=over

=item C<actor>

=back

On success, returns a list of C<At::Lexicon::app::bsky::actor::profileViewDetailed> objects.

=head2 C<graph_muteActor( ... )>

    $bsky->graph_muteActor( 'at://...' );

Mute an actor by DID or handle.

Expected parameters include:

=over

=item C<actor>

Person to mute.

=back

=head2 C<graph_muteActorList( ... )>

    $bsky->graph_muteActorList( 'at://...' );

Mute a list of actors.

Expected parameters include:

=over

=item C<list>

List of people to mute.

=back

=head2 C<graph_unmuteActor( ... )>

    $bsky->graph_unmuteActor( 'at://...' );

Unmute an actor by DID or handle.

Expected parameters include:

=over

=item C<actor>

Person to mute.

=back

=head2 C<graph_unmuteActorList( ... )>

    $bsky->graph_unmuteActorList( 'at://...' );

Unmute a list of actors.

Expected parameters include:

=over

=item C<list>

=back

=head2 C<notification_listNotifications( [...] )>

    $bsky->notification_listNotifications( );

Get a list of notifications.

Expected parameters include:

=over

=item C<limit>

=item C<seenAt>

A timestamp.

=item C<cursor>

=back

On success, returns a list of notifications as C<At::Lexicon::app::bsky::notification> objects and, optionally, a
cursor.

=head2 C<notification_getUnreadCount( [...] )>

    $bsky->notification_getUnreadCount( );

Get the count of unread notifications.

Expected parameters include:

=over

=item C<seenAt>

A timestamp.

=back

On success, returns a count of unread notifications.

=head2 C<notification_updateSeen( ... )>

    $bsky->notification_updateSeen( time );

Notify server that the user has seen notifications.

Expected parameters include:

=over

=item C<seenAt> - required

A timestamp.

=back

=head2 C<notification_registerPush( [...] )>

    $bsky->notification_registerPush(

    );

Register for push notifications with a service.

Expected parameters include:

=over

=item C<appId> - required

=item C<platform> - required

Known values include 'ios', 'android', and 'web'.

=item C<serviceDid> - required

=item C<token> - required

=back

See L<https://github.com/bluesky-social/atproto/discussions/1914>.

=head2 C<unspecced_getPopularFeedGenerators( [...] )>

    $bsky->unspecced_getPopularFeedGenerators( );

An unspecced view of globally popular feed generators.

Expected parameters include:

=over

=item C<query>

=item C<limit>

Maximum of 100, minimum of 1, and 50 is the default.

=item C<cursor>

=back

On success, returns a list of feeds as C<At::Lexicon::app::bsky::feed::generatorView> objects and, optionally, a
cursor.

=head2 C<unspecced_getTaggedSuggestions( )>

    $bsky->unspecced_getTaggedSuggestions( );

Get a list of suggestions (feeds and users) tagged with categories.

On success, returns a list of suggestions as C<At::Lexicon::app::bsky::unspecced::suggestion> objects.

=head2 C<unspecced_searchActorsSkeleton( ..., [...] )>

    $bsky->unspecced_searchActorsSkeleton( 'jake' );

Backend Actors (profile) search, returns only skeleton.

Expected parameters include:

=over

=item C<query> - required

Search query string; syntax, phrase, boolean, and faceting is unspecified, but Lucene query syntax is recommended. For
typeahead search, only simple term match is supported, not full syntax.

=item C<typeahead>

If true, acts as fast/simple 'typeahead' query.

=item C<limit>

Maximum of 100, minimum of 1, and 25 is the default.

=item C<cursor>

Optional pagination mechanism; may not necessarily allow scrolling through entire result set.

=back

On success, returns a list of actors as C<At::Lexicon::app::bsky::unspecced::skeletonSearchActor> objects and,
optionally, an approximate count of all search hits and a cursor.

=head2 C<unspecced_searchPostsSkeleton( ..., [...] )>

    $bsky->unspecced_searchPostsSkeleton( 'for sure' );

Backend Posts search, returns only skeleton.

Expected parameters include:

=over

=item C<query> - required

Search query string; syntax, phrase, boolean, and faceting is unspecified, but Lucene query syntax is recommended. For
typeahead search, only simple term match is supported, not full syntax.

=item C<limit>

Maximum of 100, minimum of 1, and 25 is the default.

=item C<cursor>

Optional pagination mechanism; may not necessarily allow scrolling through entire result set.

=back

On success, returns a list of posts as C<At::Lexicon::app::bsky::unspecced::skeletonSearchPost> objects and,
optionally, an approximate count of all search hits and a cursor.

=head1 See Also

L<App::bsky> - Bluesky client on the command line

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

Bluesky ios cid reposters reposts booleans online unspecced typeahead

=end stopwords

=cut
