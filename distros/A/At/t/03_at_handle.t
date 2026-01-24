use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use Path::Tiny qw[path];
use v5.42;
use lib '../lib', 'lib';
#
use At::Protocol::Handle qw[:all];
#
imported_ok qw[
    ensureValidHandle ensureValidHandleRegex
    normalizeHandle   normalizeAndEnsureValidHandle
    isValidHandle     isValidTld];
#
subtest 'old At.pm' => sub {

    # Invalid syntax:
    subtest 'malformed handle' => sub {
        like( dies { At::Protocol::Handle->new($_) }, qr/Handle/i, $_ ) for qw[
            jo@hn.test
            💩.test
            john..test
            xn--bcher-.tld
            john.0
            cn.8
            www.masełkowski.pl.com
            org
            name.org.];
    };

    # Valid syntax, but must always fail resolution due to other restrictions:
    subtest 'fatal level restricted TDL' => sub {
        ok dies { At::Protocol::Handle->new($_) }, $_ for qw[
            2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion
            laptop.local
            blah.arpa];
    };

    # Valid but only during testing and development
    subtest 'warning level restricted TDL' => sub {    # Note: only thrown once!
        like( warning { At::Protocol::Handle->new($_) }, qr/testing TLD used in handle/, $_ ) for qw[nice.test];
    };

    # All examples are taken directly from the DID docs found at https://atproto.com/specs/handle#identifier-examples
    # Syntactically valid handles (which may or may not have existing TLDs):
    ok( At::Protocol::Handle->new('jay.bsky.social'),                              'jay.bsky.social' );
    ok( At::Protocol::Handle->new('8.cn'),                                         '8.cn' );
    ok( At::Protocol::Handle->new('name.t--t'),                                    'name.t--t' );             #  not a real TLD, but syntax ok
    ok( At::Protocol::Handle->new('XX.LCS.MIT.EDU'),                               'XX.LCS.MIT.EDU' );
    ok( At::Protocol::Handle->new('a.co'),                                         'a.co' );
    ok( At::Protocol::Handle->new('xn--notarealidn.com'),                          'xn--notarealidn.com' );
    ok( At::Protocol::Handle->new('xn--fiqa61au8b7zsevnm8ak20mc4a87e.xn--fiqs8s'), 'xn--fiqa61au8b7zsevnm8ak20mc4a87e.xn--fiqs8s' );
    ok( At::Protocol::Handle->new('xn--ls8h.test'),                                'xn--ls8h.test' );
    ok( At::Protocol::Handle->new('example.t'),                                    'example.t' );             # not a real TLD, but syntax ok
};
subtest 'AT Handle validation' => sub {

    sub expectValid($handle) {
        subtest $handle => sub {
            ok ensureValidHandle($handle),      'ensureValidHandle( ... )';
            ok ensureValidHandleRegex($handle), 'ensureValidHandleRegex( ... )';
        }
    }

    sub expectInvalid($handle) {
        subtest $handle => sub {
            ok dies { ensureValidHandle($handle) },      'ensureValidHandle( ... ) dies';
            ok dies { ensureValidHandleRegex($handle) }, 'ensureValidHandleRegex( ... ) dies';
        }
    }
    subtest 'allows valid handles' => sub {
        expectValid('A.ISI.EDU');
        expectValid('XX.LCS.MIT.EDU');
        expectValid('SRI-NIC.ARPA');
        expectValid('john.test');
        expectValid('jan.test');
        expectValid('a234567890123456789.test');
        expectValid('john2.test');
        expectValid('john-john.test');
        expectValid('john.bsky.app');
        expectValid('jo.hn');
        expectValid('a.co');
        expectValid('a.org');
        expectValid('joh.n');
        expectValid('j0.h0');
        my $longHandle = 'shoooort' . ( '.loooooooooooooooooooooooooong' x 8 ) . '.test';
        is length $longHandle, 253, 'length of longhandle';
        expectValid($longHandle);
        expectValid( 'short.' . ( 'o' x 63 ) . '.test' );
        expectValid('jaymome-johnber123456.test');
        expectValid('jay.mome-johnber123456.test');
        expectValid('john.test.bsky.app');

        # NOTE: this probably isn't ever going to be a real domain, but my read of
        # the RFC is that it would be possible
        expectValid('john.t');
    };

    # NOTE: they may change this at the proto level; currently only disallowed at
    # the registration level
    subtest 'allows .local and .arpa handles (proto-level)' => sub {
        expectValid('laptop.local');
        expectValid('laptop.arpa');
    };
    subtest 'allows punycode handles' => sub {
        expectValid('xn--ls8h.test');        # 💩.test
        expectValid('xn--bcher-kva.tld');    # bücher.tld
        expectValid('xn--3jk.com');
        expectValid('xn--w3d.com');
        expectValid('xn--vqb.com');
        expectValid('xn--ppd.com');
        expectValid('xn--cs9a.com');
        expectValid('xn--8r9a.com');
        expectValid('xn--cfd.com');
        expectValid('xn--5jk.com');
        expectValid('xn--2lb.com');
    };
    subtest 'allows onion (Tor) handles' => sub {
        expectValid('expyuzz4wqqyqhjn.onion');
        expectValid('friend.expyuzz4wqqyqhjn.onion');
        expectValid('g2zyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
        expectValid('friend.g2zyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
        expectValid('friend.g2zyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
        expectValid('2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
        expectValid('friend.2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion');
    };
    subtest 'throws on invalid handles' => sub {
        expectInvalid('did:thing.test');
        expectInvalid('did:thing');
        expectInvalid('john-.test');
        expectInvalid('john.0');
        expectInvalid('john.-');
        expectInvalid( 'short.' . ( 'o' x 64 ) . '.test' );
        expectInvalid( 'short' . ( '.loooooooooooooooooooooooong' x 10 ) . '.test' );
        my $longHandle = 'shooooort' . ( '.loooooooooooooooooooooooooong' x 8 ) . '.test';
        is length $longHandle, 254, 'verifying length of $longHandle';
        expectInvalid($longHandle);
        expectInvalid('xn--bcher-.tld');
        expectInvalid('john..test');
        expectInvalid('jo_hn.test');
        expectInvalid('-john.test');
        expectInvalid('.john.test');
        expectInvalid('jo!hn.test');
        expectInvalid('jo%hn.test');
        expectInvalid('jo&hn.test');
        expectInvalid('jo@hn.test');
        expectInvalid('jo*hn.test');
        expectInvalid('jo|hn.test');
        expectInvalid('jo:hn.test');
        expectInvalid('jo/hn.test');
        expectInvalid('john💩.test');
        expectInvalid('bücher.test');
        expectInvalid('john .test');
        expectInvalid('john.test.');
        expectInvalid('john');
        expectInvalid('john.');
        expectInvalid('.john');
        expectInvalid('john.test.');
        expectInvalid('.john.test');
        expectInvalid(' john.test');
        expectInvalid('john.test ');
        expectInvalid('joh-.test');
        expectInvalid('john.-est');
        expectInvalid('john.tes-');
    };
    subtest 'throws on "dotless" TLD handles' => sub {
        expectInvalid('org');
        expectInvalid('ai');
        expectInvalid('gg');
        expectInvalid('io');
    };
    subtest 'correctly validates corner cases (modern vs. old RFCs)' => sub {
        expectValid('12345.test');
        expectValid('8.cn');
        expectValid('4chan.org');
        expectValid('4chan.o-g');
        expectValid('blah.4chan.org');
        expectValid('thing.a01');
        expectValid('120.0.0.1.com');
        expectValid('0john.test');
        expectValid('9sta--ck.com');
        expectValid('99stack.com');
        expectValid('0ohn.test');
        expectValid('john.t--t');
        expectValid('thing.0aa.thing');
        #
        expectInvalid('cn.8');
        expectInvalid('thing.0aa');
        expectInvalid('thing.0aa');
    };
    subtest 'does not allow IP addresses as handles' => sub {
        expectInvalid('127.0.0.1');
        expectInvalid('192.168.0.142');
        expectInvalid('fe80::7325:8a97:c100:94b');
        expectInvalid('2600:3c03::f03c:9100:feb0:af1f');
    };
    subtest 'is consistent with examples from stackoverflow' => sub {
        my @okStackoverflow = (
            'stack.com',                                    'sta-ck.com',
            'sta---ck.com',                                 'sta--ck9.com',
            'stack99.com',                                  'sta99ck.com',
            'google.com.uk',                                'google.co.in',
            'google.com',                                   'maselkowski.pl',
            'm.maselkowski.pl',                             'xn--masekowski-d0b.pl',
            'xn--fiqa61au8b7zsevnm8ak20mc4a87e.xn--fiqs8s', 'xn--stackoverflow.com',
            'stackoverflow.xn--com',                        'stackoverflow.co.uk',
            'xn--masekowski-d0b.pl',                        'xn--fiqa61au8b7zsevnm8ak20mc4a87e.xn--fiqs8s'
        );
        expectValid($_) for @okStackoverflow;
        #
        my @badStackoverflow = ( '-notvalid.at-all', '-thing.com', 'www.masełkowski.pl.com' );
        expectInvalid($_) for @badStackoverflow;
    };
    subtest 'conforms to interop valid handles' => sub {
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax handle_syntax_valid.txt])->realpath;
        $path // skip_all 'failed to locate valid test data';
        for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
            if ( $line =~ /^#\s*/ ) {

                #~ diag $';
                next;
            }
            expectValid($line);
        }
    };
    subtest 'conforms to interop invalid handles' => sub {
        my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax handle_syntax_invalid.txt])->realpath;
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
subtest normalization => sub {
    is normalizeAndEnsureValidHandle('JoHn.TeST'), 'john.test', q[normalize 'JoHn.TeST'];
    ok dies {
        normalizeAndEnsureValidHandle('JoH!n.TeST')
    }, q[throws on invalid normalized handle 'JoH!n.TeST'];
};
#
done_testing;
