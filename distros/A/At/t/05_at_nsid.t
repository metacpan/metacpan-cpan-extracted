use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use Path::Tiny qw[path];
use v5.36;
use lib '../eg/', 'eg', '../lib', 'lib';
#
use At::Protocol::NSID qw[:all];
#
imported_ok qw[
    parse create
    isValid
    ensureValidNsid ensureValidNsidRegex
];
#
subtest 'NSID parsing & creation' => sub {
    subtest 'parses valid NSIDs' => sub {
        subtest 'com.example.foo' => sub {
            is parse('com.example.foo')->authority, 'example.com',     '->authority';
            is parse('com.example.foo')->name,      'foo',             '->name';
            is parse('com.example.foo'),            'com.example.foo', 'stringify';
        };
        subtest 'com.long-thing1.cool.fooBarBaz' => sub {
            is parse('com.long-thing1.cool.fooBarBaz')->authority, 'cool.long-thing1.com',           '->authority';
            is parse('com.long-thing1.cool.fooBarBaz')->name,      'fooBarBaz',                      '->name';
            is parse('com.long-thing1.cool.fooBarBaz'),            'com.long-thing1.cool.fooBarBaz', 'stringify';
        }
    };
    subtest 'creates valid NSIDs' => sub {
        subtest q[::create('example.com', 'foo')] => sub {
            is create( 'example.com', 'foo' )->authority, 'example.com',     '->authority';
            is create( 'example.com', 'foo' )->name,      'foo',             '->name';
            is create( 'example.com', 'foo' ),            'com.example.foo', 'stringify';
        };
        subtest q[::create('cool.long-thing1.com', 'fooBarBaz')] => sub {
            is create( 'cool.long-thing1.com', 'fooBarBaz' )->authority, 'cool.long-thing1.com',           '->authority';
            is create( 'cool.long-thing1.com', 'fooBarBaz' )->name,      'fooBarBaz',                      '->name';
            is create( 'cool.long-thing1.com', 'fooBarBaz' ),            'com.long-thing1.cool.fooBarBaz', 'stringify';
        };
    };
};
#
subtest 'NSID validation' => sub {

    sub expectValid($uri) {
        subtest $uri => sub {
            ok ensureValidNsid($uri),      'ensureValidNsid( ... )';
            ok ensureValidNsidRegex($uri), 'ensureValidNsidRegex( ... )';
        }
    }

    sub expectInvalid($uri) {
        subtest $uri => sub {
            ok dies { ensureValidNsid($uri) },      'ensureValidNsid( ... ) dies';
            ok dies { ensureValidNsidRegex($uri) }, 'ensureValidNsidRegex( ... ) dies';
        }
    }
    #
    subtest 'enforces spec details' => sub {
        expectValid('com.example.foo');
        expectValid( 'com.' . ( 'o' x 63 ) . '.foo' );
        #
        expectInvalid( 'com.' . ( 'o' x 64 ) . '.foo' );
        #
        expectValid( 'com.example.' . ( 'o' x 63 ) );
        #
        expectInvalid( 'com.example.' . ( 'o' x 64 ) );
        #
        my $longOverall = 'com.' . ( 'middle.' x 40 ) . 'foo';
        is length $longOverall, 287, 'length';
        expectValid($longOverall);
        #
        my $tooLongOverall = 'com.' . ( 'middle.' x 50 ) . 'foo';
        is length $tooLongOverall, 357, 'length';
        expectInvalid($tooLongOverall);
        #
        expectValid('com.example.fooBar');
        expectValid('net.users.bob.ping');
        expectValid('a.b.c');
        expectValid('m.xn--masekowski-d0b.pl');
        expectValid('one.two.three');
        expectValid('one.two.three.four-and.FiVe');
        expectValid('one.2.three');
        expectValid('a-0.b-1.c');
        expectValid('a0.b1.cc');
        expectValid('cn.8.lex.stuff');
        expectValid('test.12345.record');
        expectValid('a01.thing.record');
        expectValid('a.0.c');
        expectValid('xn--fiqs8s.xn--fiqa61au8b7zsevnm8ak20mc4a87e.record.two');
        #
        expectInvalid('com.example.foo.*');
        expectInvalid('com.example.foo.blah*');
        expectInvalid('com.example.foo.*blah');
        expectInvalid('com.example.f00');
        expectInvalid('com.exa💩ple.thing');
        expectInvalid('a-0.b-1.c-3');
        expectInvalid('a-0.b-1.c-o');
        expectInvalid('a0.b1.c3');
        expectInvalid('1.0.0.127.record');
        expectInvalid('0two.example.foo');
        expectInvalid('example.com');
        expectInvalid('com.example');
        expectInvalid('a.');
        expectInvalid('.one.two.three');
        expectInvalid('one.two.three ');
        expectInvalid('one.two..three');
        expectInvalid('one .two.three');
        expectInvalid(' one.two.three');
        expectInvalid('com.exa💩ple.thing');
        expectInvalid('com.atproto.feed.p@st');
        expectInvalid('com.atproto.feed.p_st');
        expectInvalid('com.atproto.feed.p*st');
        expectInvalid('com.atproto.feed.po#t');
        expectInvalid('com.atproto.feed.p!ot');
        expectInvalid('com.example-.foo');
    };
    subtest 'allows onion (Tor) NSIDs' => sub {
        expectValid('onion.expyuzz4wqqyqhjn.spec.getThing');
        expectValid('onion.g2zyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.lex.deleteThing');
    };
    subtest 'allows starting-with-numeric segments (same as domains)' => sub {
        expectValid('org.4chan.lex.getThing');
        expectValid('cn.8.lex.stuff');
        expectValid('onion.2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.lex.deleteThing');
    };
    subtest 'conforms to interop valid NSIDs' => sub {
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax nsid_syntax_valid.txt])->realpath;
        $path // skip_all 'failed to locate invalid test data';
        for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
            if ( $line =~ /^#\s*/ ) {

                #~ diag $';
                next;
            }
            expectValid($line);
        }
    };
    subtest 'conforms to interop invalid NSIDs' => sub {
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax nsid_syntax_invalid.txt])->realpath;
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
