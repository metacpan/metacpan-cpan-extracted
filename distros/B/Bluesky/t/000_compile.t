use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use JSON::Tiny qw[decode_json];
use Path::Tiny qw[path];
use HTTP::Tiny;
use utf8;
use v5.40;

# Dev
# https://github.com/bluesky-social/atproto/tree/main/packages/api
# https://github.com/bluesky-social/atproto/blob/main/packages/api/src/client/index.ts
#~ use Data::Dump;
use lib '../lib', 'lib';
#
use Bluesky;
#
my $bsky;

# Utils
sub getProfileDisplayName () {
    my $h = $bsky->getProfile( $bsky->did );
    $h->throw unless $h;
    $h->{displayName} // ();
}
#
isa_ok $bsky = Bluesky->new(), ['Bluesky'];
#
subtest 'parse mentions' => sub {
    is [ $bsky->parse_mentions('prefix @handle.example.com @handle.com suffix') ],
        [ { start => 7, end => 26, handle => 'handle.example.com' }, { start => 27, end => 38, handle => 'handle.com' } ],
        'prefix @handle.example.com @handle.com suffix';
    is [ $bsky->parse_mentions('handle.example.com') ], [], 'handle.example.com';
    is [ $bsky->parse_mentions('@bare') ],              [], '@bare';
    is [ $bsky->parse_mentions('💩💩💩 @handle.example.com') ], [ { start => 13, end => 32, handle => 'handle.example.com' } ],
        '💩💩💩 @handle.example.com';
    is [ $bsky->parse_mentions('email@example.com') ], [],                                                     'email@example.com';
    is [ $bsky->parse_mentions('cc:@example.com') ],   [ { start => 3, end => 15, handle => 'example.com' } ], 'cc:@example.com';
};
subtest 'parse urls' => sub {
    is [ $bsky->parse_urls('prefix https://example.com/index.html http://bsky.app suffix') ],
        [ { end => 37, start => 7, url => 'https://example.com/index.html' }, { end => 53, start => 38, url => 'http://bsky.app' } ],
        'prefix https://example.com/index.html http://bsky.app suffix';
    is [ $bsky->parse_urls('example.com') ],                        [],                                                       'example.com';
    is [ $bsky->parse_urls('💩💩💩 http://bsky.app') ],                [ { end => 28, start => 13, url => 'http://bsky.app' } ], '💩💩💩 http://bsky.app';
    is [ $bsky->parse_urls('runonhttp://blah.comcontinuesafter') ], [], 'runonhttp://blah.comcontinuesafter';
    is [ $bsky->parse_urls('ref [https://bsky.app]') ], [ { end => 21, start => 5, url => 'https://bsky.app' } ], 'ref [https://bsky.app]';

    # a better regex would not mangle these:
    is [ $bsky->parse_urls('ref (https://bsky.app/)') ], [ { end => 22, start => 5, url => 'https://bsky.app/' } ], 'ref (https://bsky.app/)';
    is [ $bsky->parse_urls('ends https://bsky.app. what else?') ], [ { end => 21, start => 5, url => 'https://bsky.app' } ],
        'ends https://bsky.app. what else?';
};
subtest 'parse facets' => sub {
    is [ $bsky->parse_facets('prefix https://example.com/index.html http://bsky.app @atperl.bsky.social #perl suffix') ],
        [
        {   features => [
                {   '$type' => 'app.bsky.richtext.facet#mention',
                    did     => bless( \( my $o = 'did:plc:pwqewimhd3rxc4hg6ztwrcyj' ), 'At::Protocol::DID' ),
                },
            ],
            index => { byteEnd => 73, byteStart => 54 },
        },
        {   features => [ { '$type' => 'app.bsky.richtext.facet#link', uri => 'https://example.com/index.html' } ],
            index    => { byteEnd => 37, byteStart => 7 }
        },
        { features => [ { '$type' => 'app.bsky.richtext.facet#link', uri => 'http://bsky.app' } ], index => { byteEnd => 53, byteStart => 38 } },
        { features => [ { '$type' => 'app.bsky.richtext.facet#tag',  tag => 'perl' } ],            index => { byteEnd => 79, byteStart => 74 } }
        ],
        'prefix https://example.com/index.html http://bsky.app @atperl.bsky.social #perl suffix';
};
subtest 'parse uri' => sub {
    is $bsky->parse_uri('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l'),
        { collection => 'app.bsky.feed.post', repo => 'did:plc:z72i7hdynmk6r22z27h6tvur', rkey => '3l6oveex3ii2l' },
        'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l';
};
#
subtest getReplyRefs => sub {
    is $bsky->getReplyRefs('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l'),
        {
        parent => {
            cid => 'bafyreicnt42y6vo6pfpvyro234ac4o6ijug6adwwrh7awflgrqlt4zibxq',
            uri => bless(
                {   hash         => '',
                    host         => 'did:plc:z72i7hdynmk6r22z27h6tvur',
                    pathname     => '/app.bsky.feed.post/3l6oveex3ii2l',
                    searchParams => bless( [], 'At::Protocol::URI::_query' ),
                },
                'At::Protocol::URI'
            )
        },
        root => {
            cid => 'bafyreicnt42y6vo6pfpvyro234ac4o6ijug6adwwrh7awflgrqlt4zibxq',
            uri => bless(
                {   hash         => '',
                    host         => 'did:plc:z72i7hdynmk6r22z27h6tvur',
                    pathname     => '/app.bsky.feed.post/3l6oveex3ii2l',
                    searchParams => bless( [], 'At::Protocol::URI::_query' ),
                },
                'At::Protocol::URI'
            )
        }
        },
        'root';
    is $bsky->getReplyRefs('at://jacob.gold/app.bsky.feed.post/3lbzusbwlok2j'),
        {
        parent => {
            cid => 'bafyreifvqzinsicw4pmwk6butdioezwy4wbx22som5lsyavjhvalmuzmri',
            uri => bless(
                {   hash         => '',
                    host         => 'did:plc:tpg43qhh4lw4ksiffs4nbda3',
                    pathname     => '/app.bsky.feed.post/3lbzusbwlok2j',
                    searchParams => bless( [], 'At::Protocol::URI::_query' ),
                },
                'At::Protocol::URI'
            )
        },
        root => {
            cid => 'bafyreiahl3awi5qmakvgbogi3dhj5ji5vq7xeyye4fkznx6fm4o75vlmx4',
            uri => bless(
                {   hash         => '',
                    host         => 'did:plc:tpg43qhh4lw4ksiffs4nbda3',
                    pathname     => '/app.bsky.feed.post/3lbzupvurts2j',
                    searchParams => bless( [], 'At::Protocol::URI::_query' ),
                },
                'At::Protocol::URI'
            )
        }
        },
        'reply';
};
subtest auth => sub {
    my $login;
    my $path = path(__FILE__)->sibling('test_auth.json')->realpath;    # Public and totally worthless auth info
    skip_all 'failed to locate auth data' unless $path->exists;
    my $auth = decode_json $path->slurp_utf8;
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

            #~ ddx $bsky->session;
        };
    };
    subtest 'Feeds and content' => sub {
        $login || skip_all "$login";
        is my $tt = $bsky->getTrendingTopics(), hash {
            field suggested => bag {
                all_items hash {
                    field description => E();
                    field displayName => E();
                    field link        => D();
                    field topic       => D();
                    end;
                };
                end
            };
            field topics => bag {
                all_items hash {
                    field description => E();
                    field displayName => E();
                    field link        => D();
                    field topic       => D();
                    end;
                };
                end
            };
            end
        }, 'getTrendingTopics( ... )';
        is my $timeline = $bsky->getTimeline(), hash {
            field cursor => D();
            field feed   => D();    # Feed items are subject to change
            end;
        }, 'getTimeline( )';
        is my $authorFeed = $bsky->getAuthorFeed( actor => 'bsky.app' ), hash {
            field cursor => E();
            field feed   => D();    # Feed items are subject to change
            end;
        }, 'getAuthorFeed( ... )';
        is my $postThread = $bsky->getPostThread( uri => 'at://bsky.app/app.bsky.feed.post/3l6oveex3ii2l' ), hash {
            field thread     => D();
            field threadgate => E();
            end;
        }, 'getPostThread( ... )';
        is my $stable_post = $bsky->getPost('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l'), hash {
            field author      => D();
            field cid         => D();
            field embed       => E();
            field indexedAt   => D();
            field labels      => D();
            field likeCount   => D();
            field quoteCount  => D();
            field record      => D();
            field replyCount  => D();
            field repostCount => D();
            field threadgate  => E();
            field uri         => D();
            field viewer      => D();
            end;
        }, 'getPost( ... )';
        isa_ok $bsky->getPost('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii20'), ['At::Error'], 'getPost( ... ) with bad uri';
        is my $posts = $bsky->getPosts(
            'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l',
            'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3lbvgvbvcf22c'
            ),
            array {
            item 0 => D();
            item 1 => D();
            end;
            }, 'getPosts( ... )';
        is my $likes = $bsky->getLikes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' ), hash {
            field cid    => E();
            field likes  => array {etc};
            field uri    => D();
            field cursor => E();
            end
        }, 'getLikes( ... )';

        #~ ddx $likes;
        #~ p my $ys   = $bsky->getLikes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
        my $post;
        subtest createPost => sub {
            is $post = $bsky->createPost( text => 'Post is for #testing only. @atproto.bsky.social https://wikipedia.com/' ), hash {
                field cid    => D();
                field commit => hash {
                    field cid => D();
                    field rev => D();
                    end;
                };
                field uri              => D();
                field validationStatus => D();
                end;
            }, 'plain text';
            is my $reply = $bsky->createPost( reply_to => $post->{uri}, text => <<'END'),
Just another test.

This isn't a hashtag but #this is! This is a double ##hashtag.

こんにちは
END
                hash {
                field cid    => D();
                field commit => hash {
                    field cid => D();
                    field rev => D();
                    end;
                };
                field uri              => D();
                field validationStatus => D();
                end;
                }, 'reply to text post';
            my $img = HTTP::Tiny->new->get('https://picsum.photos/500/300');

            #~ use Data::Dump;
            #~ ddx $img;
            skip 1 unless $img->{success};
            is my $image_reply = $bsky->createPost(
                reply_to => $post->{uri},
                embed    => { images => [ { image => $img->{content}, alt => 'Lorem Picsum', mime => $img->{headers}{'content-type'} } ] },
                text     => <<'END'),
Yet another test.

But with an image this time!
END
                hash {
                field cid    => D();
                field commit => hash {
                    field cid => D();
                    field rev => D();
                    end;
                };
                field uri              => D();
                field validationStatus => D();
                end;
                }, 'reply with image';
            $image_reply->throw unless $image_reply;
        };
        my $like;
        subtest like => sub {
            skip 1 unless $post;
            is $like = $bsky->like( $post->{uri}, $post->{cid} ), hash {
                field cid              => E();
                field commit           => hash { field cid => D(); field rev => D(); etc };
                field uri              => D();
                field validationStatus => D();
                end
            }, 'like( ... )';
        };
        subtest deleteLike => sub {
            skip 1 unless $like;
            is my $unlike = $bsky->deleteLike( $like->{uri} ), hash {
                field commit => hash {
                    field cid => E();
                    field rev => D();
                    end
                };
                end
            }, 'deleteLike( ... )';
        };
    };
    subtest 'Social graph' => sub {
        $login || skip_all "$login";
        subtest getBlocks => sub {
            my $blocks = $bsky->getBlocks();
            skip_all 'failed to gather blocks: ' . $blocks->message unless $blocks;
            is $blocks, bag {
                all_items hash {
                    field createdAt => D();
                    field did       => E();
                    field handle    => E();
                    etc;
                };
                end
            }, 'list of blocks';
        };
    }
};
if (0) {

    # }
    my $login = 0;
    #
    subtest 'upsertProfile correctly handles CAS failures' => sub {
        my $original = getProfileDisplayName();
    SKIP: {
            $original // skip 'failed to get display name';
            ok $bsky->upsertProfile(
                sub (%existing) {
                    %existing, displayName => localtime . ' [' . ( int rand time ) . ']';
                }
                ),
                'upsertProfile';
            #
            {
                my $todo = todo 'Bluesky might take a little time to commit changes';
                my $ok   = 0;
                for ( 1 .. 3 ) {
                    last if $ok = $original ne getProfileDisplayName();
                    diag 'giving Bluesky a moment to catch up...';
                    sleep 2;
                }
                ok $ok, 'displayName has changed';
            }
        }
    };
    subtest 'pull author feed' => sub {
        $login || skip_all "$login";
        is my $feed = $bsky->getAuthorFeed( actor => 'did:plc:z72i7hdynmk6r22z27h6tvur', filter => 'posts_and_author_threads', limit => 30 ), hash {
            field cursor => D();
            field feed   => D();    # Feed items are subject to change
            end;
        }, 'getAuthorFeed( ... )';
    };
    subtest 'pull post thread' => sub {
        $login || skip_all "$login";
        is my $thread = $bsky->getPostThread( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c' ), hash {
            field threadgate => E();
            field thread     => meta {    # Feed items are subject to change
                prop isa     => 'At::Lexicon::app::bsky::feed::defs::threadViewPost';
                prop reftype => 'HASH';
            };
            end;
        }, 'getPostThread( ... )';
    };
    subtest 'pull post' => sub {
        $login || skip_all "$login";
        is my $post = $bsky->getPost('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c'), hash {
            field posts => array {
                item meta {
                    prop blessed => 'At::Lexicon::app::bsky::feed::defs::postView'
                };
                end;
            };
            end;
        }, 'getPost( ... )';
    };
    subtest 'pull reposts' => sub {
        $login || skip_all "$login";
        is my $reposts = $bsky->getRepostedBy( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l2s5xxv2ze2c' ), hash {
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
            is $post = $bsky->post( text => 'Testing' ), hash {    # com.atproto.repo.createRecord#output
                field cid => D();                                  # CID
                field uri => D();                                  # AT-uri
                etc;                                               # might also contain commit and validationStatus
            }, 'post( ... )';
        };
        {
            my $like;
            subtest 'like the post we just created' => sub {
                $login || skip_all "$login";
                $post  || skip_all "$post";
                is $like = $bsky->like( $post->{uri}, $post->{cid} ), hash {

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
                is $bsky->deleteLike( $like->{uri} ), hash {
                    field commit => hash {
                        field cid => D();    # CID
                        field rev => D();
                        end;
                    };
                    etc;
                }, 'deleteLike(...)';
            };
        }
        {
            my $repost;
            subtest 'repost the post we just created' => sub {
                $login || skip_all "$login";
                $post  || skip_all "$post";
                is $repost = $bsky->repost( $post->{uri}, $post->{cid} ), hash {

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
                is $bsky->deleteRepost( $repost->{uri} ), hash {
                    field commit => hash {
                        field cid => D();    # CID
                        field rev => D();
                        end;
                    };
                    etc;
                }, 'deleteRepost(...)';
            };
        }
        subtest 'delete the post we created earlier' => sub {
            $login || skip_all "$login";
            $post  || skip_all "$post";
            is my $delete = $bsky->deletePost( $post->{uri} ), hash {
                field commit => hash {
                    field cid => D();    # CID
                    field rev => D();
                    end;
                };
                etc;
            }, 'deletePost(...)';
        };
    }
    subtest 'get our own follows' => sub {
        $login || skip_all "$login";
        is my $follows = $bsky->getFollows( $bsky->did ), hash {
            field cursor  => E();
            field follows => D();    # array of At::Lexicon::app::bsky::actor::defs::profileView objects
            field subject => D();    # profileview
            end;
        }, 'getFollows( ... )';
    };
    subtest 'get our own followers' => sub {
        $login || skip_all "$login";
        is my $followers = $bsky->getFollowers( $bsky->did ), hash {
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
            is $follow = $bsky->follow( $bsky->did ), hash {
                field cid => D();
                field uri => D();
                etc;    # might also contain commit and validationStatus
            }, 'follow( ... )';
        };
        subtest 'delete the follow record we created earlier' => sub {
            $login  || skip_all "$login";
            $follow || skip_all "$follow";
            is my $delete = $bsky->deleteFollow( $follow->{uri} ), hash {
                field commit => hash {
                    field cid => D();    # CID
                    field rev => D();
                    end;
                };
                etc;
            }, 'deleteFollow(...)';
        };
    }
}
#
done_testing;
