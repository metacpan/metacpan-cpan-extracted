use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
use Path::Tiny qw[path];
use v5.36;
use lib '../eg/', 'eg', '../lib', 'lib';
#
use At::Protocol::DID qw[:all];
#
imported_ok qw[ensureValidDid ensureValidDidRegex];
#
sub expectValid($uri) {
    subtest $uri => sub {
        ok ensureValidDid($uri),      'ensureValidDid( ... )';
        ok ensureValidDidRegex($uri), 'ensureValidDidRegex( ... )';
    }
}

sub expectInvalid($uri) {
    subtest $uri => sub {
        ok dies { ensureValidDid($uri) },        'ensureValidDid( ... ) dies';
        ok dies { ensureValidAtDidRegex($uri) }, 'ensureValidAtDidRegex( ... ) dies';
    }
}
subtest 'enforces spec details' => sub {
    expectValid('did:method:val');
    expectValid('did:method:VAL');
    expectValid('did:method:val123');
    expectValid('did:method:123');
    expectValid('did:method:val-two');
    expectValid('did:method:val_two');
    expectValid('did:method:val.two');
    expectValid('did:method:val:two');
    expectValid('did:method:val%BB');
    #
    expectInvalid('did');
    expectInvalid('didmethodval');
    expectInvalid('method:did:val');
    expectInvalid('did:method:');
    expectInvalid('didmethod:val');
    expectInvalid('did:methodval');
    expectInvalid(':did:method:val');
    expectInvalid('did.method.val');
    expectInvalid('did:method:val:');
    expectInvalid('did:method:val%');
    expectInvalid('DID:method:val');
    expectInvalid('did:METHOD:val');
    expectInvalid('did:m123:val');
    #
    expectValid( 'did:method:' . ( 'v' x 240 ) );
    expectInvalid( 'did:method:' . ( 'v' x 8500 ) );
    #
    expectValid('did:m:v');
    expectValid('did:method::::val');
    expectValid('did:method:-');
    expectValid('did:method:-:_:.:%ab');
    expectValid('did:method:.');
    expectValid('did:method:_');
    expectValid('did:method::.');
    #
    expectInvalid('did:method:val/two');
    expectInvalid('did:method:val?two');
    expectInvalid('did:method:val#two');
    expectInvalid('did:method:val%');
    #
    expectValid('did:onion:2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid');
};
subtest 'allows some real DID values' => sub {
    expectValid('did:example:123456789abcdefghi');
    expectValid('did:plc:7iza6de2dwap2sbkpav7c6c6');
    expectValid('did:web:example.com');
    expectValid('did:web:localhost%3A1234');
    expectValid('did:key:zQ3shZc2QzApp2oymGvQbzP8eKheVshBHbU4ZYjeXqwSKEn6N');
    expectValid('did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a');
};
#
subtest 'conforms to interop valid DIDs' => sub {
    my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax did_syntax_valid.txt])->realpath;
    $path // skip_all 'failed to locate valid test data';
    for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
        if ( $line =~ /^#\s*/ ) {

            #~ diag $';
            next;
        }
        expectValid($line);
    }
};
subtest 'conforms to interop invalid DIDs' => sub {
    my $path = path(__FILE__)->sibling('interop-test-files')->child(qw[syntax did_syntax_invalid.txt])->realpath;
    $path // skip_all 'failed to locate invalid test data';
    for my $line ( grep {length} $path->lines( { chomp => 1 } ) ) {
        if ( $line =~ /^#\s*/ ) {

            #~ diag $';
            next;
        }
        expectInvalid($line);
    }
};
#
done_testing;
