use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Exception qw[dies];
use Test2::Tools::Warnings  qw[warns];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use At;

# All examples are taken directly from the DID docs found at https://atproto.com/specs/did#examples
# Valid DIDs for use in atproto (correct syntax, and supported method):
ok( At::Protocol::DID->new( uri => 'did:plc:z72i7hdynmk6r22z27h6tvur' ), 'did:plc:z72i7hdynmk6r22z27h6tvur' );
ok( At::Protocol::DID->new( uri => 'did:web:blueskyweb.xyz' ),           'did:web:blueskyweb.xyz' );

# Valid DID syntax (would pass Lexicon syntax validation), but unsupported DID method:
subtest 'unsupported method' => sub {
    like( warning { At::Protocol::DID->new( uri => $_ ) }, qr/unsupported method/, $_ ) for qw[
        did:method:val:two
        did:m:v
        did:method::::val
        did:method:-:_:.
        did:key:zQ3shZc2QzApp2oymGvQbzP8eKheVshBHbU4ZYjeXqwSKEn6N
    ];
};

# Invalid DID identifier syntax (regardless of DID method):
subtest 'malformed DID' => sub {
    like( dies { At::Protocol::DID->new( uri => $_ ) }, qr/malformed DID/, $_ ) for qw[did:METHOD:val
        did:m123:val
        DID:method:val
        did:method:
        did:method:val/two
        did:method:val?two], 'did:method:val#two';
};
#
done_testing;
