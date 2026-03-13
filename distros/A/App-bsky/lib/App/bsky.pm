package App::bsky 0.05 {
    use v5.38;
    use utf8;
    use Bluesky;
    use experimental 'class', 'try';
    no warnings 'experimental';
    use open qw[:std :encoding(UTF-8)];
    $|++;
    class App::bsky::CLI 0.05 {
        use JSON::Tiny qw[/code_json/];
        use Path::Tiny;
        use File::HomeDir;
        use Getopt::Long qw[GetOptionsFromArray];
        use Term::ANSIColor;
        #
        field $bsky = Bluesky->new();
        field $config;
        field $config_file : param //= path( File::HomeDir->my_data )->absolute->child('.bsky');
        #
        ADJUST {
            if ( $^O eq 'MSWin32' ) {
                try {
                    require Win32::Console;
                    Win32::Console::OutputCP(65001);
                }
                catch ($e) {

                    #~ warn $e;
                    #~ warn 'We may have issues with non-ASCII display';
                }
                binmode STDOUT, ':encoding(UTF-8)';
                binmode STDERR, ':encoding(UTF-8)';
            }
            $self->get_config;
            if ( defined $config->{resume}{accessJwt} && defined $config->{resume}{refreshJwt} ) {
                my $res = $bsky->resume(
                    $config->{resume}{accessJwt},
                    $config->{resume}{refreshJwt},
                    $config->{resume}{token_type} // 'Bearer',
                    $config->{resume}{dpop_key_jwk},
                    $config->{resume}{client_id},
                    $config->{resume}{handle},
                    $config->{resume}{pds},
                    $config->{resume}{scope}
                );

                # If resume automatically refreshed, update our config
                # Also, if the session is expired, try to refresh it manually
                if ( $bsky->session && builtin::blessed( $bsky->session ) && $bsky->session->isa('At::Protocol::Session') ) {
                    my $access = $bsky->at->_decode_token( $bsky->session->accessJwt );
                    if ( $access && time > $access->{exp} ) {
                        $bsky->at->oauth_refresh;
                    }
                    $config->{resume} = $bsky->session->_raw;
                    $self->put_config;
                }
            }
            elsif ( defined $config->{login}{identifier} && defined $config->{login}{password} ) {
                if ( $bsky->login( $config->{login}{identifier}, $config->{login}{password} ) &&
                    builtin::blessed( $bsky->session ) &&
                    $bsky->session->isa('At::Protocol::Session') ) {
                    $config->{resume} = $bsky->session->_raw;
                    $self->put_config;
                }
            }
            $config->{session}
                = ( $bsky->session && builtin::blessed( $bsky->session ) && $bsky->session->isa('At::Protocol::Session') ) ? $bsky->session->_raw :
                undef;
            $config->{settings} //= { wrap => 0 };
            $self->put_config;
        }

        method config() {
            $self->get_config if !$config && $config_file->is_file && $config_file->size;
            $config;
        }

        method DESTROY ( $global //= 0 ) {
            return unless $config;

            #~ $self->put_config;
        }
        #
        method get_config() {
            $config = ( $config_file->is_file && $config_file->size ) ? decode_json $config_file->slurp_utf8 : {};
        }
        method put_config() { $config_file->spew_utf8( JSON::Tiny::to_json $config ); }

        sub _wrap_and_indent {
            my ( $width, $indent, $string ) = @_;
            my $size        = $width - $indent;
            my $indentation = ' ' x $indent;
            $string =~ s[(.{1,$size})(\s+|$)][$1\n]g if $size > 0;

            #~ $string =~ s[^\s+|\n(\s+)][$1//'']gme;                   # Preserve leading whitespace
            $string =~ s/^/$indentation/gm;
            return $string;
        }

        method err ( $msg, $fatal //= 0 ) {
            my $indent = $msg =~ /^(\s*)/ ? $1 : '';
            $msg = _wrap_and_indent( $config->{settings}{wrap} // 0, length $indent, $msg ) if length $msg;
            die "$msg\n" if $fatal;
            warn "$msg\n";
            !$fatal;
        }

        method say ( $msg, @etc ) {
            $msg = @etc ? sprintf $msg, @etc : $msg;
            my $indent = $msg =~ /^(\s*)/ ? $1 : '';
            $msg = _wrap_and_indent( $config->{settings}{wrap} // 0, length $indent, $msg ) if length $msg;
            try { say $msg; }
            catch ($e) {

                # Stage 1 fallback: try explicit UTF-8 encode before syswrite
                try {
                    my $out = $msg . "\n";
                    utf8::encode($out) if utf8::is_utf8($out);
                    syswrite( STDOUT, $out );
                }
                catch ($e2) {

                    # Stage 2 fallback: aggressive ASCII sanitization
                    my $out = $msg;
                    utf8::encode($out) if utf8::is_utf8($out);
                    $out =~ s/[^\x20-\x7E]/ /g;
                    syswrite( STDOUT, $out . " [sanitized]\n" );
                }
            }
            1;
        }

        method run (@args) {
            $|++;
            return $self->err( 'No subcommand found. Try bsky --help', 1 ) unless scalar @args;
            my $cmd = shift @args;
            $cmd =~ m[^-(h|-help)$] ? $cmd = 'help' : $cmd =~ m[^-V$] ? $cmd = 'VERSION' : $cmd =~ m[^-(v|-version)$] ? $cmd = 'version' : ();
            {
                my $cmd = $cmd;
                $cmd =~ s[[^a-z]][]gi;
                if ( my $method = $self->can( 'cmd_' . $cmd ) ) {
                    return $method->( $self, @args );
                }
            }
            $self->err( 'Unknown subcommand found: ' . $cmd . '. Try bsky --help', 1 ) unless @args;
        }

        method cmd_showprofile (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'handle|H=s' => \my $handle );
            return $self->cmd_help('show-profile') if scalar @args;
            my $profile = $bsky->getProfile( $handle // $config->{session}{handle} );
            if ($json) {
                $self->say( JSON::Tiny::to_json($profile) );
            }
            else {
                $profile->throw unless $profile;
                $self->say( 'DID: %s',         $profile->{did} );
                $self->say( 'Handle: %s',      $profile->{handle} );
                $self->say( 'DisplayName: %s', $profile->{displayName} // '' );
                $self->say( 'Description: %s', $profile->{description} // '' );
                $self->say( 'Follows: %d',     $profile->{followsCount} );
                $self->say( 'Followers: %d',   $profile->{followersCount} );
                $self->say( 'Avatar: %s',      $profile->{avatar} ) if $profile->{avatar};
                $self->say( 'Banner: %s',      $profile->{banner} ) if $profile->{banner};
                $self->say('Blocks you: yes') if $profile->{viewer}{blockedBy} // ();
                $self->say('Following: yes')  if $profile->{viewer}{following} // ();
                $self->say('Muted: yes')      if $profile->{viewer}{muted}     // ();
            }
            1;
        }

        method cmd_updateprofile (@args) {
            GetOptionsFromArray(
                \@args,
                'avatar=s'      => \my $avatar,
                'banner=s'      => \my $banner,
                'name=s'        => \my $displayName,
                'description=s' => \my $description
            );
            $avatar // $banner // $displayName // $description // return $self->cmd_help('updateprofile');
            my $profile = $bsky->getProfile( $config->{session}{handle} );
            if ($profile) {    # Bluesky clears them if we do not set them every time
                $displayName //= $profile->{displayName};
                $description //= $profile->{description};
            }
            if ( defined $avatar ) {
                if ( $avatar =~ m[^https?://] ) {
                    my ( $content, $headers ) = $bsky->at->http->get($avatar);
                    use Carp;
                    $content // confess 'failed to download avatar from ' . $avatar;

                    # TODO: check content type HTTP::Tiny and Mojo::UserAgent do this differently
                    $avatar = $bsky->uploadFile( $content, $headers->{'content-type'} );
                }
                elsif ( -e $avatar ) {
                    use Path::Tiny;
                    $avatar = path($avatar)->slurp_raw;
                    my $type = substr( $avatar, 0, 2 ) eq pack 'H*',
                        'ffd8' ? 'image/jpeg' : substr( $avatar, 1, 3 ) eq 'PNG' ? 'image/png' : 'image/jpeg';    # XXX: Assume it's a jpeg?
                    $avatar = $bsky->uploadFile( $avatar, $type );
                }
                else {
                    $self->err('unsure what to do with this avatar; does not seem to be a URL or local file');
                }
                if ($avatar) {
                    $self->say( 'uploaded avatar... %d bytes', $avatar->{size} );
                }
                else {
                    $self->say('failed to upload avatar');
                }
            }
            if ( defined $banner ) {
                if ( $banner =~ m[^https?://] ) {
                    my ( $content, $headers ) = $bsky->at->http->get($banner);
                    use Carp;
                    $content // confess 'failed to download banner from ' . $banner;

                    # TODO: check content type HTTP::Tiny and Mojo::UserAgent do this differently
                    $banner = $bsky->uploadFile( $content, $headers->{'content-type'} );
                }
                elsif ( -e $banner ) {
                    use Path::Tiny;
                    $banner = path($banner)->slurp_raw;
                    my $type = substr( $banner, 0, 2 ) eq pack 'H*',
                        'ffd8' ? 'image/jpeg' : substr( $banner, 1, 3 ) eq 'PNG' ? 'image/png' : 'image/jpeg';    # XXX: Assume it's a jpeg?
                    $banner = $bsky->uploadFile( $banner, $type );
                }
                else {
                    $self->err('unsure what to do with this banner; does not seem to be a URL or local file');
                }
                if ($banner) {
                    $self->say( 'uploaded banner... %d bytes', $banner->{size} );
                }
                else {
                    $self->say('failed to upload banner');
                }
            }
            my $res = $bsky->at->put_record(
                'app.bsky.actor.profile',
                'self',
                {   defined $displayName ? ( displayName => $displayName ) : (),
                    defined $description ? ( description => $description ) : (),
                    defined $avatar      ? ( avatar      => $avatar )      : (),
                    defined $banner      ? ( banner      => $banner )      : ()
                }
            );
            defined $res->{uri} ? $self->say( $res->{uri}->as_string ) : $self->err( $res->{message} );
        }

        method cmd_oauth ( $handle, @args ) {
            my $cli = $self;
            GetOptionsFromArray( \@args, 'redirect=s' => \my $redirect );
            $bsky->oauth_helper(
                handle => $handle,
                listen => 1,
                defined $redirect ? ( redirect => $redirect ) : (),
                on_success => sub ($bsky_obj) {
                    $config->{resume}  = $bsky_obj->session->_raw;
                    $config->{session} = $bsky_obj->session->_raw;
                    $cli->put_config;
                    $cli->say( "Authenticated as " . $bsky_obj->did );
                }
            );
        }

        method cmd_showsession (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my $session = $bsky->session;
            unless ($session) {
                return $self->err("No active session. Run 'bsky oauth <handle>' or 'bsky login' first.");
            }
            if ($json) {
                $self->say( JSON::Tiny::to_json( $session->_raw ) );
            }
            else {
                $self->say( 'DID:    ' . $session->did );
                $self->say( 'Handle: ' . $session->handle );
                $self->say( 'Email:  ' . ( $session->email // 'N/A' ) );
                $self->say( 'Type:   ' . $session->token_type );
                $self->say( 'Scopes: ' . ( $session->scope // 'N/A' ) );
            }
            return 1;
        }

        method _dump_post ( $depth, $post ) {
            if ( builtin::blessed $post ) {
                if ( $post->isa('At::Lexicon::app::bsky::feed::threadViewPost') && builtin::blessed $post->parent ) {
                    $self->_dump_post( $depth++, $post->parent );
                    $post = $post->post;
                }
                elsif ( $post->isa('At::Lexicon::app::bsky::feed::threadViewPost') ) {
                    $self->_dump_post( $depth++, $post->post );
                    my $replies = $post->replies // [];
                    $self->_dump_post( $depth + 2, $_->post ) for @$replies;
                    return;
                }
            }

            #~ warn ref $post;
            #~ use Data::Dump;
            #~ ddx $post;
            # TODO: Support image embeds as raw links
            $self->say(
                '%s%s%s%s%s (%s)',
                ' ' x ( $depth * 4 ),
                color('red'), $post->{author}{handle},
                color('reset'),
                defined $post->{author}{displayName} ? ' [' . $post->{author}{displayName} . ']' : '',
                $post->{record}{createdAt}
            );
            if ( $post->{embed} && defined $post->{embed}{images} ) {    # TODO: Check $post->embed->$type to match 'app.bsky.embed.images#view'
                $self->say( '%s%s', ' ' x ( $depth * 4 ), $_->{fullsize} ) for @{ $post->{embed}{images} };
            }
            $self->say( '%s%s', ' ' x ( $depth * 4 ), $post->{record}{text} );
            $self->say(
                '%s ❤️ %d 💬 %d 🔄 %d %s',
                ' ' x ( $depth * 4 ),
                $post->{likeCount}, $post->{replyCount}, $post->{repostCount},
                ( builtin::blessed $post->{uri} ? $post->{uri}->as_string : $post->{uri} )
            );
            $self->say( '%s', ' ' x ( $depth * 4 ) );
        }

        method cmd_timeline (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my $tl = $bsky->getTimeline();
            if ( builtin::blessed $tl && $tl->isa('At::Error') ) {
                return $self->err( "Error fetching timeline: " . $tl->message );
            }
            unless ( $tl && $tl->{feed} ) {
                return $self->say("Timeline is empty.");
            }
            if ($json) {
                $self->say( JSON::Tiny::to_json( $tl->{feed} ) );
            }
            else {
                for my $item ( @{ $tl->{feed} } ) {
                    my $depth = 0;
                    if ( $item->{reply} && $item->{reply}{parent} ) {
                        $self->_dump_post( $depth, $item->{reply}{parent} );
                        $depth = 1;
                    }
                    $self->_dump_post( $depth, $item->{post} );
                }
            }
            return scalar @{ $tl->{feed} };
        }
        method cmd_tl (@args) { $self->cmd_timeline(@args); }

        method cmd_stream(@args) {
            GetOptionsFromArray( \@args, 'json|j' => \my $json );
            require Mojo::IOLoop;    # Ensure Mojo is available for the event loop
            require Archive::CAR::CID;
            require Archive::CAR;
            require Codec::CBOR;

            # Keep the loop alive even if the connection drops briefly
            my $keepalive = Mojo::IOLoop->recurring( 60 => sub { $self->say("[DEBUG] Firehose loop keepalive...") if $ENV{DEBUG}; } );
            my %profile_cache;
            my @profile_lru;
            my $MAX_CACHE     = 1000;
            my $cache_profile = sub ($p) {
                my $did = $p->{did};
                if ( exists $profile_cache{$did} ) {
                    @profile_lru = grep { $_ ne $did } @profile_lru;
                }
                push @profile_lru, $did;
                $profile_cache{$did} = $p;
                if ( @profile_lru > $MAX_CACHE ) {
                    my $oldest = shift @profile_lru;
                    delete $profile_cache{$oldest};
                }
            };
            my @post_queue;
            my %dids_to_resolve;
            my %did_fail_count;
            my $render_queue = sub {
                my @to_resolve = grep { ( $did_fail_count{$_} // 0 ) < 5 } keys %dids_to_resolve;
                if (@to_resolve) {
                    say "[DEBUG] Resolving " . scalar(@to_resolve) . " DIDs..." if $ENV{DEBUG};
                    while (@to_resolve) {
                        my @chunk = splice @to_resolve, 0, 25;
                        my $res   = $bsky->getProfiles( actors => \@chunk );
                        if ( ref $res eq 'ARRAY' || ( ref $res eq 'HASH' && $res->{profiles} ) ) {
                            my @profiles = ref $res eq 'ARRAY' ? @$res : @{ $res->{profiles} };
                            say "[DEBUG] Resolved " . scalar(@profiles) . " profiles" if $ENV{DEBUG};
                            for my $p (@profiles) {
                                $cache_profile->($p);
                                delete $dids_to_resolve{ $p->{did} };
                                delete $did_fail_count{ $p->{did} };
                            }

                            # If some didn't come back in the response, they might be invalid or deleted
                            # We'll increment their fail count if they are still in dids_to_resolve
                            for my $did (@chunk) {
                                if ( exists $dids_to_resolve{$did} ) {
                                    $did_fail_count{$did}++;
                                }
                            }
                        }
                        else {
                            say "[DEBUG] getProfiles failed: " . ( $res // 'undef' ) if $ENV{DEBUG};

                            # Increment fail count for the whole chunk
                            for my $did (@chunk) {
                                $did_fail_count{$did}++;
                            }
                        }
                    }
                }
                if (@post_queue) {
                    say "[DEBUG] Processing post queue with " . scalar(@post_queue) . " items" if $ENV{DEBUG};
                    @post_queue = sort { $a->{record}{createdAt} cmp $b->{record}{createdAt} } @post_queue;
                }
                while (@post_queue) {
                    my $item       = shift @post_queue;
                    my $repo       = $item->{repo};
                    my $record     = $item->{record};
                    my $ts         = $item->{ts};
                    my $author     = $profile_cache{$repo};
                    my $handle     = ( ref $author eq 'HASH' ) ? ( $author->{handle}      // $repo ) : $repo;
                    my $name       = ( ref $author eq 'HASH' ) ? ( $author->{displayName} // '' )    : '';
                    my $text       = $record->{text} // '[no text]';
                    my $reply_info = '';

                    if ( $record->{reply} && $record->{reply}{parent} ) {
                        my $parent_uri = $record->{reply}{parent}{uri};
                        if ( $parent_uri =~ m[^at://(did:[^/]+)] ) {
                            my $parent_did     = $1;
                            my $parent_profile = $profile_cache{$parent_did};
                            my $parent_handle  = ( ref $parent_profile eq 'HASH' ) ? $parent_profile->{handle} : $parent_did;
                            $reply_info = color('white') . " [in reply to \@" . $parent_handle . "]";
                        }
                    }
                    try {
                        $self->say( '%s%s    %s (%s)%s%s', color('white'), $ts, $name, '@' . $handle, $reply_info, color('reset') );
                        my $indented = $text;
                        $indented =~ s/^/   /mg;
                        $self->say($indented);
                        $self->say("");
                    }
                    catch ($e) {
                        try {
                            my $out = $text;
                            utf8::encode($out) if utf8::is_utf8($out);
                            $out =~ s/[^\x20-\x7E]/ /g;
                            $self->say( '%s%s    %s (%s)%s [sanitized]', color('white'), $ts, $name, '@' . $handle, $reply_info );
                            my $indented = $out;
                            $indented =~ s/^/   /mg;
                            $self->say($indented);
                            $self->say("");
                        }
                        catch ($e2) { }
                    }
                }
            };

            # Trigger rendering every 5 seconds
            Mojo::IOLoop->recurring( 5 => sub { $render_queue->() } );
            my $start_stream;
            $start_stream = sub {
                $self->say('[DEBUG] Starting firehose stream...') if $ENV{DEBUG} || 1;
                my $fh = $bsky->firehose(
                    sub ( $header, $body, $err ) {
                        try {
                            if ( defined $err ) {
                                warn 'Firehose error: ' . $err;

                                # Always try to reconnect if not explicitly fatal
                                if ( !$err->fatal ) {
                                    $self->say('[DEBUG] Attempting to reconnect in 5 seconds...') if $ENV{DEBUG} || 1;
                                    Mojo::IOLoop->timer( 5 => sub { $start_stream->() } );
                                }
                                else {
                                    $self->say('[DEBUG] Fatal firehose error. Exiting.') if $ENV{DEBUG} || 1;
                                    Mojo::IOLoop->remove($keepalive);
                                    Mojo::IOLoop->stop;
                                }
                                return;
                            }
                            if ($json) {
                                $self->say( JSON::Tiny::to_json( { header => $header, body => $body } ) );
                                return;
                            }

                            # Only process commit events for now
                            unless ( defined $header->{t} && $header->{t} eq '#commit' ) {
                                return;
                            }
                            for my $op ( @{ $body->{ops} } ) {
                                next unless $op->{action} eq 'create';
                                next unless $op->{path} =~ /^app\.bsky\.feed\.post\//;
                                try {
                                    # Decode the blocks to find the record
                                    require Archive::CAR::v1;
                                    my $car = Archive::CAR::v1->new();
                                    open my $cfh, '<:raw', \$body->{blocks};
                                    my %blocks = map { $_->{cid}->to_string => $_->{data} } $car->read($cfh)->blocks->@*;
                                    require Archive::CAR::CID;    # Ensure it's loaded for conversion
                                    my $cid_raw = $op->{cid};
                                    if ( ref $cid_raw eq 'HASH' && exists $cid_raw->{cid_raw} ) {
                                        $cid_raw = $cid_raw->{cid_raw};
                                    }
                                    my $target_cid_obj = Archive::CAR::CID->from_raw($cid_raw);
                                    my $record_bytes   = $blocks{ $target_cid_obj->to_string };
                                    next unless $record_bytes;
                                    require Codec::CBOR;
                                    my $codec  = Codec::CBOR->new();
                                    my $record = $codec->decode($record_bytes);
                                    next unless $record;
                                    my $repo = $body->{repo};
                                    my $ts   = $record->{createdAt} // '';
                                    $ts =~ s/T/ /;
                                    $ts =~ s/\..*Z//;

                                    # Queue for later rendering
                                    push @post_queue, { repo => $repo, record => $record, ts => $ts };
                                    $dids_to_resolve{$repo} = 1 unless exists $profile_cache{$repo};
                                    if ( $record->{reply} && $record->{reply}{parent} ) {
                                        my $parent_uri = $record->{reply}{parent}{uri};
                                        if ( $parent_uri =~ m[^at://(did:[^/]+)] ) {
                                            my $parent_did = $1;
                                            $dids_to_resolve{$parent_did} = 1 unless exists $profile_cache{$parent_did};
                                        }
                                    }
                                }
                                catch ($e) {
                                    warn "CAR/CBOR decoding error for op on repo " . $body->{repo} . ": $e";
                                }
                            }
                        }
                        catch ($e) {
                            warn "Error processing firehose event: $e";
                        }
                    }
                );
                $fh->start();
            };
            $start_stream->();
            Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
        }

        method cmd_thread (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'n=i' => \my $number );
            $number //= ();
            my ($id) = @args;
            $id // return $self->cmd_help('thread');
            my $res = $bsky->getPostThread( uri => $id, depth => $number, parentHeight => $number );    # $uri, depth, $parentHeight
            return unless $res->{thread};
            return $self->say( JSON::Tiny::to_json $res->{thread} ) if $json;
            $self->_dump_post( 0, $res->{thread} );
        }

        method cmd_post ($text) {
            my $res = $bsky->createPost( text => $text );
            defined $res ? $self->say( $res->{uri} ) : 0;
        }

        method cmd_delete ($uri) {
            $uri = At::Protocol::URI->new($uri) unless builtin::blessed $uri;
            $bsky->at->delete_record( $uri->collection, $uri->rkey );
        }

        # TODO
        method cmd_like ( $uri, @args ) {    # can take the post uri
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'cid=s' => \my $cid );
            my $res = $bsky->like( $uri, $cid );
            $res || $res->throw;
            $self->say( $json ? JSON::Tiny::to_json($res) : sprintf 'Liked! [id:%s]', $res->{uri}->as_string );
        }

        # TODO
        method cmd_unlike ( $uri, @args ) {    # can take the post uri or the like uri
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'cid=s' => \my $cid );
            my $res = $bsky->deleteLike($uri);
            $res || $res->throw;
            $self->say( $json ? JSON::Tiny::to_json($res) : sprintf 'Removed like!' );
        }

        # TODO
        method cmd_likes ( $uri, @args ) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @likes;
            my $cursor = ();
            do {
                my $likes = $bsky->at->get( 'app.bsky.feed.getLikes', { uri => $uri, limit => 100, cursor => $cursor } );
                push @likes, @{ $likes->{likes} };
                $cursor = $likes->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json \@likes );
            }
            else {
                $self->say(
                    '%s%s%s%s (%s)',
                    color('red'),   $_->{actor}{handle},
                    color('reset'), defined $_->{actor}{displayName} ? ' [' . $_->{actor}{displayName} . ']' : '',
                    $_->{createdAt}
                ) for @likes;
            }
            scalar @likes;
        }

        # TODO
        method cmd_repost ($uri) {
            my $res = $bsky->repost($uri);
            $res // return;
            $self->say( $res->{uri}->as_string );
        }

        # TODO
        method cmd_reposts ( $uri, @args ) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @reposts;
            my $cursor = ();
            do {
                my $reposts = $bsky->at->get( 'app.bsky.feed.getRepostedBy', { uri => $uri, limit => 100, cursor => $cursor } );
                push @reposts, @{ $reposts->{repostedBy} };
                $cursor = $reposts->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json \@reposts );
            }
            else {
                $self->say( '%s%s%s%s', color('red'), $_->{handle}, color('reset'), defined $_->{displayName} ? ' [' . $_->{displayName} . ']' : '' )
                    for @reposts;
            }
            scalar @reposts;
        }

        # TODO
        method cmd_follow ($actor) {    # takes handle or did
            my $res = $bsky->follow($actor);
            $res || $res->throw;
            $self->say( $res->{uri}->as_string );
        }

        # TODO
        method cmd_unfollow ($actor) {    # takes handle or did
            my $profile = $bsky->getProfile($actor);
            my $uri     = $profile->{viewer}{following} // return $self->err("You are not following $actor");
            $bsky->deleteFollow($uri);
            $self->say("Unfollowed $actor");
        }

        # TODO
        method cmd_follows (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'handle|H=s' => \my $handle );
            my @follows;
            my $cursor = ();
            do {
                my $follows = $bsky->at->get( 'app.bsky.graph.getFollows',
                    { actor => $handle // $config->{session}{handle}, limit => 100, cursor => $cursor } );
                push @follows, @{ $follows->{follows} };
                $cursor = $follows->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json \@follows );
            }
            else {
                for my $follow (@follows) {
                    $self->say(
                        sprintf '%s%s%s%s %s%s%s',
                        color('red'),  $follow->{handle}, color('reset'), defined $follow->{displayName} ? ' [' . $follow->{displayName} . ']' : '',
                        color('blue'), $follow->{did},    color('reset')
                    );
                }
            }
            return scalar @follows;
        }

        method cmd_followers (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'handle|H=s' => \my $handle );
            my @followers;
            my $cursor = ();
            do {
                my $followers = $bsky->at->get( 'app.bsky.graph.getFollowers',
                    { actor => $handle // $config->{session}{handle}, limit => 100, cursor => $cursor } );
                $followers // last;
                if ( defined $followers->{followers} ) {
                    push @followers, @{ $followers->{followers} };
                    $cursor = $followers->{cursor};
                }
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map {$_} @followers ] );
            }
            else {
                my $len1 = my $len2 = 0;
                for (@followers) {
                    $len1 = length( $_->{handle} )      if length( $_->{handle} ) > $len1;
                    $len2 = length( $_->{displayName} ) if length( $_->{displayName} ) > $len2;
                }
                for my $follower (@followers) {
                    $self->say(
                        sprintf '%s%-' . ($len1) . 's %s%-' . ($len2) . 's %s%s%s',
                        color('red'),  $follower->{handle}, color('reset'), $follower->{displayName} // '',
                        color('blue'), $follower->{did},    color('reset')
                    );
                }
            }
            scalar @followers;
        }

        # TODO
        method cmd_block ($actor) {    # takes handle or did
            my $res = $bsky->block($actor);
            $res || $res->throw;
            $self->say( $res->{uri}->as_string );
        }

        # TODO
        method cmd_unblock ($actor) {    # takes handle or did
            my $profile = $bsky->getProfile($actor);
            my $uri     = $profile->{viewer}{blocking} // return $self->err("You are not blocking $actor");
            $bsky->deleteBlock($uri);
            $self->say("Unblocked $actor");
        }

        # TODO
        method cmd_blocks (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @blocks;
            my $cursor = ();
            do {
                my $follows = $bsky->at->get( 'app.bsky.graph.getBlocks', { limit => 100, cursor => $cursor } );
                push @blocks, @{ $follows->{blocks} };
                $cursor = $follows->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json \@blocks );
            }
            else {
                for my $follow (@blocks) {
                    $self->say(
                        sprintf '%s%s%s%s %s%s%s',
                        color('red'),  $follow->{handle}, color('reset'), defined $follow->{displayName} ? ' [' . $follow->{displayName} . ']' : '',
                        color('blue'), $follow->{did},    color('reset')
                    );
                }
            }
            return scalar @blocks;
        }

        method cmd_login ( $ident, $password, @args ) {
            GetOptionsFromArray( \@args, 'host=s' => \my $host );
            $bsky = Bluesky->new( defined $host ? ( service => $host ) : () );
            unless ( $bsky->login( $ident, $password ) ) {
                return $self->err( 'Failed to log in as ' . $ident, 1 );
            }
            $config->{resume}  = $bsky->session->_raw;
            $config->{session} = $bsky->session->_raw;
            $self->put_config;
            $self->say( 'Logged in' . ( $host ? ' at ' . $host : '' ) . ' as ' . color('red') . $ident . color('reset') . ' [' . $bsky->did . ']' );
        }

        method cmd_notifications (@args) {
            GetOptionsFromArray( \@args, 'all|a' => \my $all, 'json!' => \my $json );
            if ( !$all ) {
                my $notification_count = $bsky->at->get('app.bsky.notification.getUnreadCount');
                $notification_count || $notification_count->throw;
                return $self->say( $json ? '[]' : 'No unread notifications' ) unless $notification_count->{count};
            }
            my @notes;
            my $cursor = ();
            do {
                my $notes = $bsky->at->get( 'app.bsky.notification.listNotifications', { limit => 100, cursor => $cursor } );
                $notes || $notes->throw;
                push @notes, @{ $notes->{notifications} };
                $cursor = $all && $notes->{cursor} ? $notes->{cursor} : ();
            } while ($cursor);
            return $self->say( JSON::Tiny::to_json [ map {$_} @notes ] ) if $json;
            return $self->say('No notifications.') unless @notes;
            for my $note (@notes) {
                $self->say(
                    '%s%s%s%s %s', color('red'), $note->{author}{handle},
                    color('reset'),
                    defined $note->{author}{displayName} ? ' [' . $note->{author}{displayName} . ']' : '',
                    $note->{author}{did}
                );
                $self->say(
                    '  %s',
                    $note->{reason} eq 'like'        ? 'liked ' . $note->{record}{subject}{uri} :
                        $note->{reason} eq 'repost'  ? 'reposted ' . $note->{record}{subject}{uri} :
                        $note->{reason} eq 'follow'  ? 'followed you' :
                        $note->{reason} eq 'mention' ? 'mentioned you at ' . $note->{record}{subject}{uri} :
                        $note->{reason} eq 'reply'   ? 'replied at ' . $note->{record}{subject}{uri} :
                        $note->{reason} eq 'quote'   ? 'quoted you at ' . $note->{record}{subject}{uri} :
                        'unknown notification: ' . $note->{reason}
                );
            }
            scalar @notes;
        }

        method cmd_notif (@args) {
            $self->cmd_notifications(@args);
        }

        method cmd_listapppasswords (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my $passwords = $bsky->at->get('com.atproto.server.listAppPasswords');
            $passwords || $passwords->throw;
            my @passwords = @{ $passwords->{passwords} };
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map {$_} @passwords ] );
            }
            elsif (@passwords) {
                $self->say( '%s%s (%s)', $_->{privileged} ? '*' : ' ', $_->{name}, $_->{createdAt} ) for @passwords;
            }
            else {
                $self->say('No app passwords found');
            }
            scalar @passwords;
        }

        method cmd_addapppassword ($name) {
            my $res = $bsky->at->post( 'com.atproto.server.createAppPassword', { name => $name } );
            $res || $res->throw;
            if ( $res->{appPassword} ) {
                $self->say( 'App name: %s', $res->{appPassword}{name} );
                $self->say( 'Password: %s', $res->{appPassword}{password} );
            }
            1;
        }

        method cmd_revokeapppassword ($name) {
            $bsky->at->post( 'com.atproto.server.revokeAppPassword', { name => $name } ) ? 1 : 0;
        }

        method cmd_config ( $field //= (), $value //= () ) {
            unless ( defined $field ) {
                $self->say('Current config:');
                for my $k ( sort keys %{ $config->{settings} } ) {
                    $self->say( '  %-20s %s', $k . ':', $config->{settings}{$k} );
                }
            }
            elsif ( defined $field && defined $config->{settings}{$field} ) {
                if ( defined $value ) {
                    $config->{settings}{$field} = $value;
                    $self->put_config;
                    $self->say( 'Config value %s set to %s', $field, $value );
                }
                else {
                    $self->say( $config->{settings}{$field} );
                }
            }
            else {
                return $self->err( 'Unknown config field: ' . $field, 1 );
            }
            return 1;
        }

        method cmd_help ( $command //= () ) {    # cribbed from App::cpm::CLI
            open my $fh, '>', \my $out;
            if ( !defined $command ) {
                use Pod::Text::Color;
                Pod::Text::Color->new->parse_from_file( path($0)->absolute->stringify, $fh );
            }
            else {
                BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Color'; }
                use Pod::Usage;
                $command = 'timeline'      if $command eq 'tl';
                $command = 'notifications' if $command eq 'notif';
                pod2usage( -output => $fh, -verbose => 99, -sections => [ 'Usage', 'Commands/' . $command ], -exitval => 'noexit' );
                $out =~ s[^[ ]{6}][    ]mg;
                $out =~ s[\s+$][]gs;
            }
            return $self->say($out);
        }

        method cmd_chat (@args) {
            my $convos = $bsky->listConvos();
            return $self->err( 'Failed to list conversations: ' . $convos->message ) if ref $convos eq 'At::Error';
            return $self->say('No active conversations.') unless @$convos;
            for my $convo (@$convos) {
                my $members = join ', ', map { $_->{handle} } @{ $convo->{members} };
                $self->say( '[%s] members: %s', $convo->{id}, $members );
                my $messages = $bsky->getMessages( convoId => $convo->{id}, limit => 3 );
                next if ref $messages eq 'At::Error';
                my %handles = map { $_->{did} => $_->{handle} } @{ $convo->{members} };
                for my $msg (@$messages) {
                    my $text   = $msg->{text}                    // '[Non-text message]';
                    my $sender = $handles{ $msg->{sender}{did} } // $msg->{sender}{did};
                    $self->say( '  [%s] %s: %s', $msg->{sentAt}, $sender, $text );
                }
            }
            return 1;
        }

        method cmd_dm (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'handle|H=s' => \my $handle, 'text|m=s' => \my $text );
            return $self->cmd_help('dm') if scalar @args || !length $handle;
            my $did = $bsky->resolveHandle($handle);
            return $self->err("Could not resolve handle '$handle'") unless $did;
            my $convo_res = $bsky->getConvoForMembers( members => [$did] );
            return $self->err( 'Could not initiate conversation: ' . $convo_res->message ) if ref $convo_res eq 'At::Error';
            my $res = $bsky->sendMessage( $convo_res->{id}, { text => $text } );
            return $self->err( 'Failed to send message: ' . $res->message ) if ref $res eq 'At::Error';
            $self->say( "Message sent to $handle. Convo ID: " . $res->{id} );
            return 1;
        }

        method cmd_VERSION() {
            $self->cmd_version;
            use Config qw[%Config];
            $self->say($_)
                for '  %Config:',
                ( map {"    $_=$Config{$_}"}
                grep { defined $Config{$_} }
                    sort
                    qw[archname installsitelib installsitebin installman1dir installman3dir sitearchexp sitelibexp vendorarch vendorlibexp archlibexp privlibexp]
                ), '  %ENV:', ( map {"    $_=$ENV{$_}"} sort grep {/^PERL/} keys %ENV ), '  @INC:',
                ( map {"    $_"} grep { ref $_ ne 'CODE' } @INC );
            1;
        }

        method cmd_version() {
            $self->say($_)
                for 'bsky       v' . $App::bsky::VERSION, 'Bluesky.pm v' . $Bluesky::VERSION, 'At.pm      v' . $At::VERSION, 'perl       ' . $^V;
            1;
        }
    };
}
1;
