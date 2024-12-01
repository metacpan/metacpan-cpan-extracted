use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use Path::Tiny qw[path];
use v5.36;
use lib '../eg/', 'eg', '../lib', 'lib';
#
use At::Protocol::URI qw[:all];
#
imported_ok qw[ensureValidAtUri ensureValidAtUriRegex];
#
subtest 'test At::Protocol::URI::_query' => sub {
    isa_ok my $query = At::Protocol::URI::_query->new('?foo=bar&foo=baz'), ['At::Protocol::URI::_query'], '?foo=bar&foo=baz';
    is $query->as_string, 'foo=bar&foo=baz', '->as_string';
    ok $query->add_param( foo => 'qux' ), q[add_param(foo => 'qux')];
    is $query->as_string, 'foo=bar&foo=baz&foo=qux', '->as_string';
    ok $query->set_param( foo => 'corge' ), q[set_param(foo => 'corge')];
    is $query->as_string, 'foo=corge&foo=baz&foo=qux', '->as_string';
    ok $query->set_param( foo => qw[grault garply waldo fred] ), q[set_param(foo => [...])];
    is $query->as_string,            'foo=grault&foo=garply&foo=waldo&foo=fred', '->as_string';
    is [ $query->get_param('foo') ], [qw[grault garply waldo fred]],             '->get_param("foo")';
    ok $query->replace_param( foo => 'test' ), q[replace_param(foo => [...])];
    ok $query->reset,                          '->reset';
    is [ $query->get_param('foo') ], [], '->get_param("foo")';
    is $query->as_string,            '', '->as_string';
    ok $query->set_param( foo => 'plugh' ), q[set_param(foo => 'plugh')];
    ok $query->set_param( bar => 'xyzzy' ), q[set_param(bar => 'xyzzy')];
    is $query->as_string, 'foo=plugh&bar=xyzzy', '->as_string';
    ok $query->add_param( foo => 'thud' ), q[add_param(foo => 'thud')];
    is $query->as_string, 'foo=plugh&bar=xyzzy&foo=thud', '->as_string';
    ok $query->delete_param('foo'), q[delete_param('foo')];
    is $query->as_string, 'bar=xyzzy', '->as_string';
};

# Taken from https://github.com/bluesky-social/atproto/blob/main/packages/syntax/tests/aturi.test.ts
subtest 'parses valid at uris' => sub {
    my @uris = (

        # [ input, host, path, query, hash]
        [ 'foo.com',                                                    'foo.com', '',         '',                 '' ],
        [ 'at://foo.com',                                               'foo.com', '',         '',                 '' ],
        [ 'at://foo.com/',                                              'foo.com', '/',        '',                 '' ],
        [ 'at://foo.com/foo',                                           'foo.com', '/foo',     '',                 '' ],
        [ 'at://foo.com/foo/',                                          'foo.com', '/foo/',    '',                 '' ],
        [ 'at://foo.com/foo/bar',                                       'foo.com', '/foo/bar', '',                 '' ],
        [ 'at://foo.com?foo=bar',                                       'foo.com', '',         'foo=bar',          '' ],
        [ 'at://foo.com?foo=bar&baz=buux',                              'foo.com', '',         'foo=bar&baz=buux', '' ],
        [ 'at://foo.com/?foo=bar',                                      'foo.com', '/',        'foo=bar',          '' ],
        [ 'at://foo.com/foo?foo=bar',                                   'foo.com', '/foo',     'foo=bar',          '' ],
        [ 'at://foo.com/foo/?foo=bar',                                  'foo.com', '/foo/',    'foo=bar',          '' ],
        [ 'at://foo.com#hash',                                          'foo.com', '',         '',                 '#hash' ],
        [ 'at://foo.com/#hash',                                         'foo.com', '/',        '',                 '#hash' ],
        [ 'at://foo.com/foo#hash',                                      'foo.com', '/foo',     '',                 '#hash' ],
        [ 'at://foo.com/foo/#hash',                                     'foo.com', '/foo/',    '',                 '#hash' ],
        [ 'at://foo.com?foo=bar#hash',                                  'foo.com', '',         'foo=bar',          '#hash' ],
        [ 'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw', 'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw', '', '', '', ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '', '', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/', '', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo', '', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo/',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo/', '', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo/bar',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo/bar', '', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw?foo=bar',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '', 'foo=bar', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw?foo=bar&baz=buux',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '', 'foo=bar&baz=buux', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/?foo=bar',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/', 'foo=bar', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo?foo=bar',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo', 'foo=bar', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo/?foo=bar',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo/', 'foo=bar', '',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw#hash',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '', '', '#hash',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/#hash',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/', '', '#hash',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo#hash',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo', '', '#hash',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw/foo/#hash',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '/foo/', '', '#hash',
        ],
        [   'at://did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw?foo=bar#hash',
            'did:example:EiAnKD8-jfdd0MDcZUjAbRgaThBrMxPTFOxcnfJhI7Ukaw',
            '', 'foo=bar', '#hash',
        ],
        [ 'did:web:localhost%3A1234',                                   'did:web:localhost%3A1234', '',         '',                 '' ],
        [ 'at://did:web:localhost%3A1234',                              'did:web:localhost%3A1234', '',         '',                 '' ],
        [ 'at://did:web:localhost%3A1234/',                             'did:web:localhost%3A1234', '/',        '',                 '', ],
        [ 'at://did:web:localhost%3A1234/foo',                          'did:web:localhost%3A1234', '/foo',     '',                 '', ],
        [ 'at://did:web:localhost%3A1234/foo/',                         'did:web:localhost%3A1234', '/foo/',    '',                 '', ],
        [ 'at://did:web:localhost%3A1234/foo/bar',                      'did:web:localhost%3A1234', '/foo/bar', '',                 '', ],
        [ 'at://did:web:localhost%3A1234?foo=bar',                      'did:web:localhost%3A1234', '',         'foo=bar',          '', ],
        [ 'at://did:web:localhost%3A1234?foo=bar&baz=buux',             'did:web:localhost%3A1234', '',         'foo=bar&baz=buux', '', ],
        [ 'at://did:web:localhost%3A1234/?foo=bar',                     'did:web:localhost%3A1234', '/',        'foo=bar',          '', ],
        [ 'at://did:web:localhost%3A1234/foo?foo=bar',                  'did:web:localhost%3A1234', '/foo',     'foo=bar',          '', ],
        [ 'at://did:web:localhost%3A1234/foo/?foo=bar',                 'did:web:localhost%3A1234', '/foo/',    'foo=bar',          '', ],
        [ 'at://did:web:localhost%3A1234#hash',                         'did:web:localhost%3A1234', '',         '',                 '#hash', ],
        [ 'at://did:web:localhost%3A1234/#hash',                        'did:web:localhost%3A1234', '/',        '',                 '#hash', ],
        [ 'at://did:web:localhost%3A1234/foo#hash',                     'did:web:localhost%3A1234', '/foo',     '',                 '#hash', ],
        [ 'at://did:web:localhost%3A1234/foo/#hash',                    'did:web:localhost%3A1234', '/foo/',    '',                 '#hash', ],
        [ 'at://did:web:localhost%3A1234?foo=bar#hash',                 'did:web:localhost%3A1234', '',         'foo=bar',          '#hash', ],
        [ 'at://4513echo.bsky.social/app.bsky.feed.post/3jsrpdyf6ss23', '4513echo.bsky.social',     '/app.bsky.feed.post/3jsrpdyf6ss23', '', '', ],
    );
    #
    for my $uri (@uris) {
        subtest $uri->[0] => sub {
            isa_ok my $urip = At::Protocol::URI->new( $uri->[0] ), ['At::Protocol::URI'], 'At::Protocol::URI->new(...)';
            is $urip->protocol,     'at:',               '->protocol';
            is $urip->host,         $uri->[1],           '->host';
            is $urip->origin,       'at://' . $uri->[1], '->origin';
            is $urip->pathname,     $uri->[2],           '->pathname';
            is $urip->search // '', $uri->[3],           '->search';
            is $urip->hash,         $uri->[4],           '->hash';
        }
    }
};
subtest 'handles ATP-specific parsing' => sub {
    subtest 'at://foo.com' => sub {
        isa_ok my $urip = At::Protocol::URI->new('at://foo.com'), ['At::Protocol::URI'], 'At::Protocol::URI->new(...)';
        is $urip->collection, '', '->collection';
        is $urip->rkey,       '', '->rkey';
    };
    subtest 'at://foo.com/com.example.foo' => sub {
        isa_ok my $urip = At::Protocol::URI->new('at://foo.com/com.example.foo'), ['At::Protocol::URI'], 'At::Protocol::URI->new(...)';
        is $urip->collection, 'com.example.foo', '->collection';
        is $urip->rkey,       '',                '->rkey';
    };
    subtest 'at://foo.com/com.example.foo/123' => sub {
        isa_ok my $urip = At::Protocol::URI->new('at://foo.com/com.example.foo/123'), ['At::Protocol::URI'], 'At::Protocol::URI->new(...)';
        is $urip->collection, 'com.example.foo', '->collection';
        is $urip->rkey,       '123',             '->rkey';
    };
};
subtest 'supports modifications' => sub {
    isa_ok my $urip = At::Protocol::URI->new('at://foo.com'), ['At::Protocol::URI'], 'At::Protocol::URI->new(...)';
    is $urip, 'at://foo.com/', 'foo.com';
    #
    subtest 'host' => sub {
        $urip->host('bar.com');
        is $urip, 'at://bar.com/', 'bar.com';
        $urip->host('did:web:localhost%3A1234');
        is $urip, 'at://did:web:localhost%3A1234/', 'did:web:localhost%3A1234';
        $urip->host('foo.com');    # restore
    };
    subtest 'pathname' => sub {
        $urip->pathname('/');
        is $urip, 'at://foo.com/', '/';
        $urip->pathname('/foo');
        is $urip, 'at://foo.com/foo', '/foo';
        $urip->pathname('foo');
        is $urip, 'at://foo.com/foo', 'foo';
    };
    subtest 'collection and rkey' => sub {
        $urip->collection('com.example.foo');
        $urip->rkey('123');
        is $urip, 'at://foo.com/com.example.foo/123', 'collection: com.example.foo, rkey: 123';
        $urip->rkey('124');
        is $urip, 'at://foo.com/com.example.foo/124', 'collection: com.example.foo, rkey: 124';
        $urip->collection('com.other.foo');
        is $urip, 'at://foo.com/com.other.foo/124', 'collection: com.other.foo, rkey: 124';
        $urip->pathname('');
        $urip->rkey('123');
        is $urip, 'at://foo.com/undefined/123', 'pathname: [empty string], rkey: 123';
        $urip->pathname('foo');    # restore
    };
    subtest 'search' => sub {
        $urip->search('?foo=bar');
        is $urip, 'at://foo.com/foo?foo=bar', 'search: ?foo=bar';
        $urip->search->set_param( baz => 'buux' );
        is $urip, 'at://foo.com/foo?foo=bar&baz=buux', 'search: ?foo=bar&baz=buux';
    };
    subtest 'hash' => sub {
        $urip->hash('#hash');
        is $urip, 'at://foo.com/foo?foo=bar&baz=buux#hash', 'hash: #hash';
        $urip->hash('hash');
        is $urip, 'at://foo.com/foo?foo=bar&baz=buux#hash', 'hash: hash';
    };
};
subtest 'supports relative URIs' => sub {
    my @tests = (

        # [ input, host, path, query, hash]
        [ '', '', '', '' ], [ '/', '/', '', '' ], [ '/foo', '/foo', '', '' ], [ '/foo/', '/foo/', '', '' ], [ '/foo/bar', '/foo/bar', '', '' ],
        [ '?foo=bar',     '',     'foo=bar', '' ], [ '?foo=bar&baz=buux', '',      'foo=bar&baz=buux', '' ], [ '/?foo=bar', '/', 'foo=bar', '' ],
        [ '/foo?foo=bar', '/foo', 'foo=bar', '' ], [ '/foo/?foo=bar',     '/foo/', 'foo=bar',          '' ], [ '#hash',     '',  '',        '#hash' ],
        [ '/#hash',       '/',    '',        '#hash' ], [ '/foo#hash', '/foo', '', '#hash' ],                [ '/foo/#hash', '/foo/', '', '#hash' ],
        [ '?foo=bar#hash', '',    'foo=bar', '#hash' ]
    );
    my @bases = (
        'did:web:localhost%3A1234',                                    'at://did:web:localhost%3A1234',
        'at://did:web:localhost%3A1234/foo/bar?foo=bar&baz=buux#hash', 'did:web:localhost%3A1234',
        'at://did:web:localhost%3A1234',                               'at://did:web:localhost%3A1234/foo/bar?foo=bar&baz=buux#hash'
    );
    for my $base (@bases) {
        subtest 'base: ' . $base => sub {
            isa_ok my $basep = At::Protocol::URI->new($base), ['At::Protocol::URI'], '$basep = ...->new( "' . $base . '" )';
            for my $test (@tests) {
                subtest 'rel: ' . $test->[0] => sub {
                    isa_ok my $urip = At::Protocol::URI->new( $test->[0], $base ), ['At::Protocol::URI'],
                        '->new( "' . $base . '", "' . $test->[0] . '" )';
                    is $urip->protocol, 'at:',          '->protocol';
                    is $urip->host,     $basep->host,   '->host matches $basep->host';
                    is $urip->origin,   $basep->origin, '->origin matches $basep->origin';
                    is $urip->pathname, $test->[1],     '->pathname';
                    is $urip->search,   $test->[2],     '->search';
                    is $urip->hash,     $test->[3],     '->hash';
                }
            }
        };
    }
};
subtest 'AT URI validation' => sub {

    sub expectValid($uri) {
        subtest $uri => sub {
            ok ensureValidAtUri($uri),      'ensureValidAtUri( ... )';
            ok ensureValidAtUriRegex($uri), 'ensureValidAtUriRegex( ... )';
        }
    }

    sub expectInvalid($uri) {
        subtest $uri => sub {
            ok dies { ensureValidAtUri($uri) },      'ensureValidAtUri( ... ) dies';
            ok dies { ensureValidAtUriRegex($uri) }, 'ensureValidAtUriRegex( ... ) dies';
        }
    }
    #
    subtest 'enfore spec basics' => sub {
        expectValid('at://did:plc:asdf123');
        expectValid('at://user.bsky.social');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/record');
        #
        expectValid('at://did:plc:asdf123#/frag');
        expectValid('at://user.bsky.social#/frag');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post#/frag');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/record#/frag');
        #
        expectInvalid('a://did:plc:asdf123');
        expectInvalid('at//did:plc:asdf123');
        expectInvalid('at:/a/did:plc:asdf123');
        expectInvalid('at:/did:plc:asdf123');
        expectInvalid('AT://did:plc:asdf123');
        expectInvalid('http://did:plc:asdf123');
        expectInvalid('://did:plc:asdf123');
        expectInvalid('at:did:plc:asdf123');
        expectInvalid('at:/did:plc:asdf123');
        expectInvalid('at:///did:plc:asdf123');
        expectInvalid('at://:/did:plc:asdf123');
        expectInvalid('at:/ /did:plc:asdf123');
        expectInvalid('at://did:plc:asdf123 ');
        expectInvalid('at://did:plc:asdf123/ ');
        expectInvalid(' at://did:plc:asdf123');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post ');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post# ');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post#/ ');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post#/frag ');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post#fr ag');
        expectInvalid('//did:plc:asdf123');
        expectInvalid('at://name');
        expectInvalid('at://name.0');
        expectInvalid('at://diD:plc:asdf123');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.p@st');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.p$st');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.p%st');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.p&st');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.p()t');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed_post');
        expectInvalid('at://did:plc:asdf123/-com.atproto.feed.post');
        expectInvalid('at://did:plc:asdf@123/com.atproto.feed.post');
        #
        expectInvalid('at://DID:plc:asdf123');
        expectInvalid('at://user.bsky.123');
        expectInvalid('at://bsky');
        expectInvalid('at://did:plc:');
        expectInvalid('at://did:plc:');
        expectInvalid('at://frag');
        #
        expectValid( 'at://did:plc:asdf123/com.atproto.feed.post/' . ( 'o' x 800 ) );
        expectInvalid( 'at://did:plc:asdf123/com.atproto.feed.post/' . ( 'o' x 8200 ) );
    };
    subtest 'has specified behavior on edge cases' => sub {
        expectInvalid('at://user.bsky.social//');
        expectInvalid('at://user.bsky.social//com.atproto.feed.post');
        expectInvalid('at://user.bsky.social/com.atproto.feed.post//');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post/asdf123/more/more');
        expectInvalid('at://did:plc:asdf123/short/stuff');
        expectInvalid('at://did:plc:asdf123/12345');
    };
    subtest 'enforces no trailing slashes' => sub {
        expectValid('at://did:plc:asdf123');
        expectInvalid('at://did:plc:asdf123/');
        #
        expectValid('at://user.bsky.social');
        expectInvalid('at://user.bsky.social/');
        #
        expectValid('at://did:plc:asdf123/com.atproto.feed.post');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post/');
        #
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/record');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post/record/');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post/record/#/frag');
    };
    subtest 'enforces strict paths' => sub {
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/asdf123');
        expectInvalid('at://did:plc:asdf123/com.atproto.feed.post/asdf123/asdf');
    };
    subtest 'is very permissive about record keys' => sub {
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/asdf123');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/a');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%23');
        #
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/$@!*)(:,;~.sdf123');
        expectValid("at://did:plc:asdf123/com.atproto.feed.post/~'sdf123");
        #
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/$');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/@');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/!');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/*');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/(');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/,');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/;');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/abc%30123');
    };
    subtest 'is probably too permissive about URL encoding' => sub {
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%30');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%3');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%zz');
        expectValid('at://did:plc:asdf123/com.atproto.feed.post/%%%');
    };
    subtest 'is very permissive about fragments' => sub {
        expectValid('at://did:plc:asdf123#/frac');
        #
        expectInvalid('at://did:plc:asdf123#');
        expectInvalid('at://did:plc:asdf123##');
        expectInvalid('#at://did:plc:asdf123');
        expectInvalid('at://did:plc:asdf123#/asdf#/asdf');
        #
        expectValid('at://did:plc:asdf123#/com.atproto.feed.post');
        expectValid('at://did:plc:asdf123#/com.atproto.feed.post/');
        expectValid('at://did:plc:asdf123#/asdf/');
        #
        expectValid('at://did:plc:asdf123/com.atproto.feed.post#/$@!*():,;~.sdf123');
        expectValid('at://did:plc:asdf123#/[asfd]');
        #
        expectValid('at://did:plc:asdf123#/$');
        expectValid('at://did:plc:asdf123#/*');
        expectValid('at://did:plc:asdf123#/;');
        expectValid('at://did:plc:asdf123#/,');
    };
    subtest 'conforms to interop valid ATURIs' => sub {
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax aturi_syntax_valid.txt])->realpath;
        $path // skip_all 'failed to locate invalid test data';
        for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
            if ( $line =~ /^#\s*/ ) {

                #~ diag $';
                next;
            }
            expectValid($line);
        }
    };
    subtest 'conforms to interop invalid ATURIs' => sub {
        my $todo
            = todo 'Like the official project, this package is currently more permissive than spec about AT URIs, so invalid cases are not errors';
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax aturi_syntax_invalid.txt])->realpath;
        $path // skip_all 'failed to locate invalid test data';
        for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
            if ( $line =~ /^#\s*/ ) {

                #~ diag $';
                next;
            }
            expectInvalid($line);
        }
    };
};
#
done_testing;
