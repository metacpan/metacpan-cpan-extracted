use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use JSON::Tiny qw[decode_json encode_json];
use Path::Tiny qw[path];
use v5.36;

# Dev
# https://github.com/bluesky-social/atproto/blob/main/packages/api/tests/bsky-agent.test.ts
use lib '../lib', 'lib';
use At;
#
my $share = -d 'share' ? 'share' : '../share';

#~ use warnings 'At';
#
my $bsky;
subtest 'should build the client' => sub {
    isa_ok $bsky = At->new( service => 'https://bsky.social', lexicon => $share . '/lexicons' ), ['At'];
};
#
subtest live => sub {    # Public and totally worthless auth info
    my $login;
    my $path = path(__FILE__)->sibling('test_auth.json')->realpath;
    skip_all 'failed to locate auth data' unless $path->exists;
    my $auth = decode_json $path->slurp_raw;
    subtest auth => sub {
        subtest resume => sub {
            skip_all 'no session to resume' unless keys %{ $auth->{resume} };
            my $todo = todo 'Working with live services here. Things might not go as we expect or hope...';
            ok $login = $bsky->resume( $auth->{resume}{accessJwt}, $auth->{resume}{refreshJwt} ), 'resume session for the following tests';
        };
        subtest login => sub {
            skip_all 'resumed session; no login required' if $login;
            skip_all 'no auth info found' unless keys %{ $auth->{login} };
            my $todo = todo 'Working with live services here. Things might not go as we expect or hope...';
            ok $login = $bsky->login( $auth->{login}{identifier}, $auth->{login}{password} ), 'logging in for the following tests';
            if ($login) {
                $auth->{resume} = { accessJwt => $bsky->session->{accessJwt}, refreshJwt => $bsky->session->{refreshJwt} };
                $path->spew_raw( encode_json $auth );
            }
        };
    };

    # }
    #
    subtest 'upsertProfile correctly handles CAS failures' => sub {
        $login || skip_all "$login";
        my $profile;
        my $cid;
        {
            my $res = $bsky->get( 'com.atproto.repo.getRecord' => { repo => $bsky->did, collection => 'app.bsky.actor.profile', rkey => 'self' } );
            $res->throw unless $res;
            $profile = $res->{value};
            $cid     = $res->{cid}
        }
        my $original = $profile->{description};
    SKIP: {
            $original // skip 'failed to get display name';
            $profile->{displayName} = 'At.pm';
            $profile->{description} = localtime . ' [' . ( int rand time ) . ']';
            ok my $upsert
                = $bsky->post( 'com.atproto.repo.putRecord' =>
                    { repo => $bsky->did, collection => 'app.bsky.actor.profile', rkey => 'self', record => $profile, swapRecord => $cid } ),
                'upsertProfile';
            #
            {
                my $todo = todo 'Bluesky might take a little time to commit changes';
                my $ok   = 0;
                for ( 1 .. 3 ) {
                    diag 'giving Bluesky a moment to catch up...';
                    sleep 2;
                    $profile = $bsky->get( 'app.bsky.actor.getProfile' => { actor => $bsky->did } );
                    $profile || next;

                    #~ use Data::Dump;
                    #~ ddx $profile;
                    ++$ok && last if defined $profile->{description} && $original ne $profile->{description};
                }
                ok $ok, 'displayName has changed';
            }
        }
    };
    subtest 'pull timeline' => sub {
        $login || skip_all "$login";
        is my $timeline = $bsky->get( 'app.bsky.feed.getTimeline' => { actor => $bsky->did } ), hash {
            field cursor => D();
            field feed   => D();    # Feed items are subject to change
            end;
        }, 'getTimeline( )';
    };
    subtest 'pull author feed' => sub {
        $login || skip_all "$login";
        is my $feed
            = $bsky->get(
            'app.bsky.feed.getAuthorFeed' => { actor => 'did:plc:z72i7hdynmk6r22z27h6tvur', filter => 'posts_and_author_threads', limit => 30 } ),
            hash {
            field cursor => D();
            field feed   => D();    # Feed items are subject to change
            end;
            }, 'getAuthorFeed( ... )';
    };
    subtest 'pull post thread' => sub {
        $login || skip_all "$login";
        is my $thread
            = $bsky->get( 'app.bsky.feed.getPostThread' => { uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c' } ),
            hash {
            field threadgate => E();
            field thread     => meta {    # Feed items are subject to change
                prop reftype => 'HASH';
            };
            end;
            }, 'getPostThread( ... )';
    };
    subtest 'pull post' => sub {
        $login || skip_all "$login";
        is my $post
            = $bsky->get( 'app.bsky.feed.getPosts' => { uris => ['at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c'] } ), hash {
            field posts => array {
                item meta {
                    prop reftype => 'HASH';
                };
                end;
            };
            end;
            }, 'getPost( ... )';
    };
    subtest 'pull reposts' => sub {
        $login || skip_all "$login";
        is my $reposts
            = $bsky->get( 'app.bsky.feed.getRepostedBy' => { uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c' } ),
            hash {
            field cursor     => D();
            field cid        => E();
            field repostedBy => D();    # array
            field uri        => D();    # AT-uri
            end;
            }, 'getRepostedBy( ... )';
    };
    {
        my $post;
        subtest 'post plain text content' => sub {
            $login || skip_all "$login";
            is $post = $bsky->post(
                'com.atproto.repo.createRecord' => {
                    repo       => $bsky->did,
                    collection => 'app.bsky.feed.post',
                    record     => { '$type' => 'app.bsky.feed.post', createdAt => Time::Moment->now->to_string, text => 'Testing' }
                }
                ),
                hash {    # com.atproto.repo.createRecord#output
                field cid => D();    # CID
                field uri => D();    # AT-uri
                etc;                 # might also contain commit and validationStatus
                }, 'post( ... )';
        };
        {
            my $like;
            subtest 'like the post we just created' => sub {
                $login || skip_all "$login";
                $post  || skip_all "$post";
                is $like = $bsky->post(
                    'com.atproto.repo.createRecord' => {
                        repo       => $bsky->did,
                        collection => 'app.bsky.feed.like',
                        record     => {
                            '$type' => 'app.bsky.feed.like',
                            subject => {                       # com.atproto.repo.strongRef
                                uri => $post->{uri},
                                cid => $post->{cid}
                            },
                            createdAt => $bsky->now
                        }
                    }
                    ),
                    hash {
                    # com.atproto.repo.createRecord#output
                    field cid => D();    # CID
                    field uri => D();    # AT-uri
                    etc;                 # might also contain commit and validationStatus
                    }, 'like(...)';
            };
            subtest 'delete like we just created' => sub {
                $login || skip_all "$login";
                $post  || skip_all "$post";
                $like  || skip_all "$like";
                is $bsky->post(
                    'com.atproto.repo.deleteRecord' => { repo => $bsky->did, collection => 'app.bsky.feed.like', rkey => $like->{uri}->rkey } ),
                    hash {
                    # com.atproto.repo.deleteRecord#output
                    field commit => hash {
                        field cid => D();    # CID
                        field rev => D();    # rkey
                        end;
                    }
                    },
                    'deleteLike(...)';
            };
        }
        {
            my $repost;
            subtest 'repost the post we just created' => sub {
                $login || skip_all "$login";
                $post  || skip_all "$post";
                is $repost = $bsky->post(
                    'com.atproto.repo.createRecord' => {
                        repo       => $bsky->did,
                        collection => 'app.bsky.feed.repost',
                        record     => {
                            '$type' => 'app.bsky.feed.repost',
                            subject => {                         # com.atproto.repo.strongRef
                                uri => $post->{uri},
                                cid => $post->{cid}
                            },
                            createdAt => At::now
                        }
                    }
                    ),
                    hash {
                    # com.atproto.repo.createRecord#output
                    field cid => D();    # CID
                    field uri => D();    # AT-uri
                    etc;                 # might also contain commit and validationStatus
                    }, 'repost(...)';
            };
            subtest 'delete repost we just created' => sub {
                $login  || skip_all "$login";
                $post   || skip_all "$post";
                $repost || skip_all "$repost";
                is $bsky->post(
                    'com.atproto.repo.deleteRecord' => { repo => $bsky->did, collection => 'app.bsky.feed.repost', rkey => $repost->{uri}->rkey } ),
                    hash {
                    # com.atproto.repo.deleteRecord#output
                    field commit => hash {
                        field cid => D();    # CID
                        field rev => D();    # rkey
                        end;
                    }
                    },
                    'deleteRepost(...)';
            };
        }
        subtest 'delete the post we created earlier' => sub {
            $login || skip_all "$login";
            $post  || skip_all "$post";
            is $bsky->post(
                'com.atproto.repo.deleteRecord' => { repo => $bsky->did, collection => 'app.bsky.feed.post', rkey => $post->{uri}->rkey } ), hash {

                # com.atproto.repo.deleteRecord#output
                field commit => hash {
                    field cid => D();    # CID
                    field rev => D();    # rkey
                    end;
                }
                },
                'deletePost(...)';
        };
    }
    subtest 'get our own follows' => sub {
        $login || skip_all "$login";
        is my $follows = $bsky->get( 'app.bsky.graph.getFollows' => { actor => $bsky->did } ), hash {
            field cursor  => E();
            field follows => D();    # array of At::Lexicon::app::bsky::actor::defs::profileView objects
            field subject => D();    # profileview
            end;
        }, 'getFollows( ... )';

        #~ $follows || $follows->throw;
    };
    subtest 'get our own followers' => sub {
        $login || skip_all "$login";
        is my $followers = $bsky->get( 'app.bsky.graph.getFollowers' => { actor => $bsky->did } ), hash {
            field cursor    => E();
            field followers => D();    # array of At::Lexicon::app::bsky::actor::defs::profileView objects
            field subject   => D();    # profileview
            end;
        }, 'getFollowers( ... )';
    };
    {
        my $follow;
        subtest 'follow myself' => sub {
            $login || skip_all "$login";
            is $follow = $bsky->post(
                'com.atproto.repo.createRecord' => {
                    repo       => $bsky->did,
                    collection => 'app.bsky.feed.follow',
                    record     => { '$type' => 'app.bsky.feed.follow', subject => $bsky->did, createdAt => At::now }
                }
                ),
                hash {
                field cid => D();
                field uri => D();
                etc;    # might also contain commit and validationStatus
                }, 'follow( ... )';
        };
        subtest 'delete the follow record we created earlier' => sub {
            $login  || skip_all "$login";
            $follow || skip_all "$follow";
            is my $delete
                = $bsky->post(
                'com.atproto.repo.deleteRecord' => { repo => $bsky->did, collection => 'app.bsky.feed.follow', rkey => $follow->{uri}->rkey } ),
                hash {
                # com.atproto.repo.deleteRecord#output
                field commit => hash {
                    field cid => D();    # CID
                    field rev => D();    # rkey
                    end;
                }
                },
                'deleteFollow(...)';
        };
    }
};
#
done_testing;
