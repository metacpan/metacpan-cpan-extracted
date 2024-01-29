package App::bsky 0.03 {
    use v5.38;
    use utf8;
    use Bluesky;
    use experimental 'class';
    no warnings 'experimental';
    use open qw[:std :encoding(UTF-8)];
    $|++;

    class App::bsky::CLI {
        use JSON::Tiny qw[/code_json/];
        use Path::Tiny;
        use File::HomeDir;
        use Getopt::Long qw[GetOptionsFromArray];
        use Term::ANSIColor;
        #
        field $bsky;
        field $config;
        field $config_file : param //= path( File::HomeDir->my_data )->absolute->child('.bsky');
        #
        ADJUST {
            $config_file = path($config_file) unless builtin::blessed $config_file;
            $self->config;
            if ( defined $config->{session}{accessJwt} ) {    # Check if the tokens are expired...
                $bsky = Bluesky->resume( %{ $config->{session} } );
                $config->{session} = $bsky->session;
                $self->put_config;
                return if defined $config->{session}{accessJwt};
            }
            $bsky = Bluesky->new();
        }

        method config() {
            $self->get_config if !$config && $config_file->is_file && $config_file->size;
            $config->{settings} //= { wrap => 0 };
            $config;
        }

        method DESTROY ( $global //= 0 ) {
            return unless $config;

            #~ $self->put_config;
        }
        #
        method get_config() {
            $config = decode_json $config_file->slurp_utf8;
        }
        method put_config() { $config_file->spew_utf8( JSON::Tiny::to_json $config ); }

        sub _wrap_and_indent {
            my ( $width, $indent, $string ) = @_;
            my $size        = $width - $indent;
            my $indentation = ' ' x $indent;
            $string =~ s[(.{1,$size})(\s+|$)][$1\n]g if $size > 0;
            $string =~ s[^\s+|\n(\s+)][$1//'']gme;                   # Preserve leading whitespace
            $string =~ s/^/$indentation/gm;
            return $string;
        }

        method err ( $msg, $fatal //= 0 ) {
            my $indent = $msg =~ /^(\s*)/ ? $1 : '';
            $msg = _wrap_and_indent( $config->{settings}{wrap}, length $indent, $msg ) if length $msg;
            die "$msg\n" if $fatal;
            warn "$msg\n";
            !$fatal;
        }

        method say ( $msg, @etc ) {
            $msg = @etc ? sprintf $msg, @etc : $msg;
            my $indent = $msg =~ /^(\s*)/ ? $1 : '';
            $msg = _wrap_and_indent( $config->{settings}{wrap}, length $indent, $msg ) if length $msg;
            CORE::say $msg;
            1;
        }

        method run (@args) {

            #~ use Data::Dump;
            #~ ddx \@args;
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
            my $profile = $bsky->actor_getProfile( $handle // $config->{session}{handle} );
            if ($json) {
                $self->say( JSON::Tiny::to_json( $profile->_raw ) );
            }
            else {
                $self->say( 'DID: %s',         $profile->did->_raw );
                $self->say( 'Handle: %s',      $profile->handle->_raw );
                $self->say( 'DisplayName: %s', $profile->displayName // '' );
                $self->say( 'Description: %s', $profile->description // '' );
                $self->say( 'Follows: %d',     $profile->followsCount );
                $self->say( 'Followers: %d',   $profile->followersCount );
                $self->say( 'Avatar: %s',      $profile->avatar ) if $profile->avatar;
                $self->say( 'Banner: %s',      $profile->banner ) if $profile->banner;
                $self->say('Blocks you: yes') if $profile->viewer->blockedBy // ();
                $self->say('Following: yes')  if $profile->viewer->following // ();
                $self->say('Muted: yes')      if $profile->viewer->muted     // ();
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
            my $profile = $bsky->actor_getProfile( $config->{session}{handle} );
            if ($profile) {    # Bluesky clears them if we do not set them every time
                $displayName //= $profile->displayName;
                $description //= $profile->description;
            }
            if ( defined $avatar ) {
                if ( $avatar =~ m[^https?://] ) {
                    my $res = $bsky->http->get($avatar);
                    use Carp;
                    $res->{content} // confess 'failed to download avatar from ' . $avatar;

                    # TODO: check content type HTTP::Tiny and Mojo::UserAgent do this differently
                    $avatar = $bsky->repo_uploadBlob( $res->{content}, $res->{headers}{'content-type'} );
                }
                elsif ( -e $avatar ) {
                    use Path::Tiny;
                    $avatar = path($avatar)->slurp_raw;
                    my $type = substr( $avatar, 0, 2 ) eq pack 'H*',
                        'ffd8' ? 'image/jpeg' : substr( $avatar, 1, 3 ) eq 'PNG' ? 'image/png' : 'image/jpeg';    # XXX: Assume it's a jpeg?
                    $avatar = $bsky->repo_uploadBlob( $avatar, $type );
                }
                else {
                    $self->err('unsure what to do with this avatar; does not seem to be a URL or local file');
                }
                if ($avatar) {
                    $self->say( 'uploaded avatar... %d bytes', $avatar->{blob}{size} );
                }
                else {
                    $self->say('failed to upload avatar');
                }
            }
            if ( defined $banner ) {
                if ( $banner =~ m[^https?://] ) {
                    my $res = $bsky->http->get($banner);
                    use Carp;
                    $res->{content} // confess 'failed to download banner from ' . $banner;

                    # TODO: check content type HTTP::Tiny and Mojo::UserAgent do this differently
                    $banner = $bsky->repo_uploadBlob( $res->{content}, $res->{headers}{'content-type'} );
                }
                elsif ( -e $banner ) {
                    use Path::Tiny;
                    $banner = path($banner)->slurp_raw;
                    my $type = substr( $banner, 0, 2 ) eq pack 'H*',
                        'ffd8' ? 'image/jpeg' : substr( $banner, 1, 3 ) eq 'PNG' ? 'image/png' : 'image/jpeg';    # XXX: Assume it's a jpeg?
                    $banner = $bsky->repo_uploadBlob( $banner, $type );
                }
                else {
                    $self->err('unsure what to do with this banner; does not seem to be a URL or local file');
                }
                if ($banner) {
                    $self->say( 'uploaded banner... %d bytes', $banner->{blob}{size} );
                }
                else {
                    $self->say('failed to upload banner');
                }
            }
            my $res = $bsky->repo_putRecord(
                repo       => $config->{session}{did},
                collection => 'app.bsky.actor.profile',
                record     => At::Lexicon::app::bsky::actor::profile->new(
                    defined $displayName ? ( displayName => $displayName )    : (),
                    defined $description ? ( description => $description )    : (),
                    defined $avatar      ? ( avatar      => $avatar->{blob} ) : (),
                    defined $banner      ? ( banner      => $banner->{blob} ) : ()
                ),
                rkey => 'self'
            );
            defined $res->{uri} ? $self->say( $res->{uri}->as_string ) : $self->err( $res->{message} );
        }

        method cmd_showsession (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my $session = $bsky->server_getSession;
            if ($json) {
                $self->say(
                    JSON::Tiny::to_json(
                        {   did            => $session->{did}->_raw,
                            email          => $session->{email},
                            emailConfirmed => \!!$session->{emailConfirmed},
                            handle         => $session->{handle}->_raw
                        }
                    )
                );
            }
            else {
                $self->say( 'DID: ' . $session->{did}->_raw );
                $self->say( 'Email: ' . $session->{email} );
                $self->say( 'Handle: ' . $session->{handle}->_raw );
            }
            return 1;
        }

        method _dump_post ( $depth, $post ) {
            if ( $post->isa('At::Lexicon::app::bsky::feed::threadViewPost') && builtin::blessed $post->parent ) {
                $self->_dump_post( $depth++, $post->parent );
                $post = $post->post;
            }
            elsif ( $post->isa('At::Lexicon::app::bsky::feed::threadViewPost') ) {
                $self->_dump_post( $depth++,   $post->post );
                $self->_dump_post( $depth + 2, $_->post ) for @{ $post->replies };
                return;
            }

            #~ warn ref $post;
            #~ use Data::Dump;
            #~ ddx $post->_raw;
            # TODO: Support image embeds as raw links
            $self->say(
                '%s%s%s%s%s (%s)',
                ' ' x ( $depth * 4 ),
                color('red'), $post->author->handle->_raw,
                color('reset'),
                defined $post->author->displayName ? ' [' . $post->author->displayName . ']' : '',
                $post->record->createdAt->_raw
            );
            if ( $post->embed && defined $post->embed->_raw->{images} ) {    # TODO: Check $post->embed->$type to match 'app.bsky.embed.images#view'
                $self->say( '%s%s', ' ' x ( $depth * 4 ), $_->{fullsize} ) for @{ $post->embed->_raw->{images} };
            }
            $self->say( '%s%s', ' ' x ( $depth * 4 ), $post->record->text );
            $self->say(
                '%s 👍(%d) ⚡(%d) 🔄(%d) %s',
                ' ' x ( $depth * 4 ),
                $post->likeCount, $post->replyCount, $post->repostCount, $post->uri->as_string
            );
            $self->say( '%s', ' ' x ( $depth * 4 ) );
        }

        method cmd_timeline (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );

            #~ use Data::Dump;
            my $tl = $bsky->feed_getTimeline();

            #$algorithm //= (), $limit //= (), $cursor //= ()
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @{ $tl->{feed} } ] );
            }
            else {    # TODO: filter where $type ne 'app.bsky.feed.post'
                for my $post ( @{ $tl->{feed} } ) {
                    my $depth = 0;
                    if ( $post->reply ) {
                        _dump_post( $self, $depth, $post->reply->parent );
                        $depth = 1;
                    }
                    _dump_post( $self, $depth, $post->post );
                }
            }
            scalar @{ $tl->{feed} };
        }
        method cmd_tl (@args) { $self->cmd_timeline(@args); }

        method cmd_stream() {

            # Mojo::UserAgent is triggering 'Subroutine attributes must come before the signature' bug in perl 5.38.x
            return $self->err('Streaming client requires Mojo::UserAgent') unless $Mojo::UserAgent::VERSION;
        }

        method cmd_thread (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'n=i' => \my $number );
            $number //= ();
            my ($id) = @args;
            $id // return $self->cmd_help('thread');
            my $res = $bsky->feed_getPostThread( $id, $number, $number );    # $uri, depth, $parentHeight
            return unless $res->{thread} && builtin::blessed $res->{thread};
            return $self->say( JSON::Tiny::to_json $res->{thread}->_raw ) if $json;
            $self->_dump_post( 0, $res->{thread} );
        }

        method cmd_post ($text) {
            my $res = $bsky->post( text => $text );
            defined $res->{uri} ? $self->say( $res->{uri} ) : 0;
        }

        method cmd_delete ($rkey) {
            $bsky->delete($rkey);
        }

        method cmd_like ($uri) {    # can take the post uri
            my $res = $bsky->like($uri);
            $res // return;
            $self->say( $res->{uri}->as_string );
        }

        method cmd_unlike ($uri) {    # can take the post uri or the like uri
            $bsky->unlike($uri);
        }

        method cmd_likes ( $uri, @args ) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @likes;
            my $cursor = ();
            do {
                my $likes = $bsky->feed_getLikes( $uri, undef, 100, $cursor );
                push @likes, @{ $likes->{likes} };
                $cursor = $likes->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @likes ] );
            }
            else {
                $self->say(
                    '%s%s%s%s (%s)',
                    color('red'),   $_->actor->handle->_raw,
                    color('reset'), defined $_->actor->displayName ? ' [' . $_->actor->displayName . ']' : '',
                    $_->createdAt->_raw
                ) for @likes;
            }
            scalar @likes;
        }

        method cmd_repost ($uri) {
            my $res = $bsky->repost($uri);
            $res // return;
            $self->say( $res->{uri}->as_string );
        }

        method cmd_reposts ( $uri, @args ) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @reposts;
            my $cursor = ();
            do {
                my $reposts = $bsky->feed_getRepostedBy( $uri, undef, 100, $cursor );
                push @reposts, @{ $reposts->{repostedBy} };
                $cursor = $reposts->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @reposts ] );
            }
            else {
                $self->say( '%s%s%s%s', color('red'), $_->handle->_raw, color('reset'), defined $_->displayName ? ' [' . $_->displayName . ']' : '' )
                    for @reposts;
            }
            scalar @reposts;
        }

        method cmd_follow ($actor) {    # takes handle or did
            my $res = $bsky->follow($actor);

            # Sometimes, the backend hasn't caught up yet and actor_getProfile( ... ) has bad data
            $self->say( $res->{viewer}{following} // 'okay' );
        }

        method cmd_unfollow ($actor) {    # takes handle or did
            my $res = $bsky->unfollow($actor);

            # Sometimes, the backend hasn't caught up yet and actor_getProfile( ... ) has bad data
            $self->say( $res->{viewer}{following} // 'okay' );
        }

        method cmd_follows (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'handle|H=s' => \my $handle );
            my @follows;
            my $cursor = ();
            do {
                my $follows = $bsky->graph_getFollows( $handle // $config->{session}{handle}, 100, $cursor );
                push @follows, @{ $follows->{follows} };
                $cursor = $follows->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @follows ] );
            }
            else {
                for my $follow (@follows) {
                    $self->say(
                        sprintf '%s%s%s%s %s%s%s',
                        color('red'),  $follow->handle->_raw, color('reset'), defined $follow->displayName ? ' [' . $follow->displayName . ']' : '',
                        color('blue'), $follow->did->_raw,    color('reset')
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
                my $followers = $bsky->graph_getFollowers( $handle // $config->{session}{handle}, 100, $cursor );
                if ( defined $followers->{followers} ) {
                    push @followers, @{ $followers->{followers} };
                    $cursor = $followers->{cursor};
                }
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @followers ] );
            }
            else {
                for my $follower (@followers) {
                    $self->say(
                        sprintf '%s%s%s%s %s%s%s',
                        color('red'),   $follower->handle->_raw,
                        color('reset'), defined $follower->displayName ? ' [' . $follower->displayName . ']' : '',
                        color('blue'),  $follower->did->_raw, color('reset')
                    );
                }
            }
            return scalar @followers;
        }

        method cmd_block ($actor) {    # takes handle or did
            my $res = $bsky->block($actor);
            builtin::blessed $res ? $self->say( $res->{viewer}{blocking} ) : 0;
        }

        method cmd_unblock ($actor) {    # takes handle or did
            my $res = $bsky->unblock($actor);
            defined $res ? $self->say( $res->{viewer}{blocking} ) : 0;
        }

        method cmd_blocks (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my @blocks;
            my $cursor = ();
            do {
                my $follows = $bsky->graph_getBlocks( 100, $cursor );
                push @blocks, @{ $follows->{blocks} };
                $cursor = $follows->{cursor};
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @blocks ] );
            }
            else {
                for my $follow (@blocks) {
                    $self->say(
                        sprintf '%s%s%s%s %s%s%s',
                        color('red'),  $follow->handle->_raw, color('reset'), defined $follow->displayName ? ' [' . $follow->displayName . ']' : '',
                        color('blue'), $follow->did->_raw,    color('reset')
                    );
                }
            }
            return scalar @blocks;
        }

        method cmd_login ( $ident, $password, @args ) {
            GetOptionsFromArray( \@args, 'host=s' => \my $host );
            $bsky = Bluesky->new( identifier => $ident, password => $password, defined $host ? ( _host => $host ) : () );
            return $self->err( '', 1 ) unless $bsky->session;
            $config->{session} = $bsky->session;    # Already raw
            $self->put_config;
            $self->say( $config ?
                    'Logged in' .
                    ( $host ? ' at ' . $host : '' ) . ' as ' .
                    color('red') .
                    $ident .
                    color('reset') . ' [' .
                    $config->{session}{did} . ']' :
                    'Failed to log in as ' . $ident );
        }

        method cmd_notifications (@args) {
            GetOptionsFromArray( \@args, 'all|a' => \my $all, 'json!' => \my $json );
            my @notes;
            my $cursor = ();
            do {
                my $notes = $bsky->notification_listNotifications( undef, 100, $cursor );
                if ( defined $notes->{notifications} ) {
                    push @notes, @{ $notes->{notifications} };
                    $cursor = $all && $notes->{cursor} ? $notes->{cursor} : ();
                }
            } while ($cursor);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @notes ] );
            }
            else {
                for my $note (@notes) {
                    $self->say(
                        '%s%s%s%s %s', color('red'), $note->author->handle->_raw,
                        color('reset'),
                        defined $note->author->displayName ? ' [' . $note->author->displayName . ']' : '',
                        $note->author->did->_raw
                    );
                    $self->say(
                        '  %s',
                        $note->reason eq 'like'        ? 'liked ' . $note->record->{subject}{uri} :
                            $note->reason eq 'repost'  ? 'reposted ' . $note->record->{subject}{uri} :
                            $note->reason eq 'follow'  ? 'followed you' :
                            $note->reason eq 'mention' ? 'mentioned you at ' . $note->record->{subject}{uri} :
                            $note->reason eq 'reply'   ? 'replied at ' . $note->record->{subject}{uri} :
                            $note->reason eq 'quote'   ? 'quoted you at ' . $note->record->{subject}{uri} :
                            'unknown notification: ' . $note->reason
                    );
                }
            }
            return scalar @notes;
        }

        method cmd_notif (@args) {
            $self->cmd_notifications(@args);
        }

        method cmd_invitecodes (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json, 'used!' => \my $used );
            my $res = $bsky->server_getAccountInviteCodes($used);
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @{ $res->{codes} } ] );
            }
            else {
                $self->say( $_->code . ( $_->available ? '' : ' [unavailable]' ) . ( $_->disabled ? ' [disabled]' : '' ) ) for @{ $res->{codes} };
            }
            scalar @{ $res->{codes} };
        }

        method cmd_listapppasswords (@args) {
            GetOptionsFromArray( \@args, 'json!' => \my $json );
            my $passwords = $bsky->server_listAppPasswords;
            my @passwords = @{ $passwords->{passwords} };
            if ($json) {
                $self->say( JSON::Tiny::to_json [ map { $_->_raw } @passwords ] );
            }
            else {
                $self->say( '%s (%s)', $_->name, $_->createdAt->_raw ) for @passwords;
            }
            scalar @passwords;
        }

        method cmd_addapppassword ($name) {
            my $res = $bsky->server_createAppPassword($name);
            if ( builtin::blessed $res->{appPassword} ) {
                $self->say( 'App name: %s', $res->{appPassword}->name );
                $self->say( 'Password: %s', $res->{appPassword}->password );
            }
            1;
        }

        method cmd_revokeapppassword ($name) {
            $bsky->server_revokeAppPassword($name) ? 1 : 0;
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
                Pod::Text::Color->new->parse_from_file( $0, $fh );
            }
            else {
                BEGIN { $Pod::Usage::Formatter = 'Pod::Text::Color'; }
                use Pod::Usage;
                $command = 'timeline'      if $command eq 'tl';
                $command = 'notifications' if $command eq 'notif';
                pod2usage( -output => $fh, -verbose => 99, -sections => [ 'Usage', 'Commands/' . $command ], -exitval => 'noexit' );
            }
            $out =~ s[^[ ]{6}][    ]mg;
            $out =~ s[\s+$][]gs;
            return $self->say($out);
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
            $self->say($_) for 'bsky  v' . $App::bsky::VERSION, 'At.pm v' . $At::VERSION, 'perl  ' . $^V;
            1;
        }
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

App::bsky - A Command-line Bluesky Client

=head1 SYNOPSIS

    bsky [global options] command [command options] [arguments...]

    $ bsky ...

    $ bsky help

    $ bsky help login

    $ bsky login ... ...

=head1 DESCRIPTION

App::bsky is a command line client for the At protocol backed Bluesky social network.

=head1 See Also

L<At>.pm

L<https://github.com/mattn/bsky> - Original Golang client

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut
