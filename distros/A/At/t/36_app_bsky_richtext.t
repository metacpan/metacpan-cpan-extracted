use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At::Bluesky;
#
isa_ok(
    At::Lexicon::app::bsky::richtext::facet::byteSlice->new( byteEnd => 5, byteStart => 3 ),
    ['At::Lexicon::app::bsky::richtext::facet::byteSlice'],
    '::richtext::facet::byteSlice'
);
isa_ok(
    At::Lexicon::app::bsky::richtext::facet::link->new( '$type' => 'app.bsky.richtext.facet#link', uri => 'https://google.com/' ),
    ['At::Lexicon::app::bsky::richtext::facet::link'],
    '::richtext::facet::link'
);
isa_ok(
    At::Lexicon::app::bsky::richtext::facet::tag->new( '$type' => 'app.bsky.richtext.facet#tag', tag => 'test' ),
    ['At::Lexicon::app::bsky::richtext::facet::tag'],
    '::richtext::facet::tag'
);
isa_ok(
    At::Lexicon::app::bsky::richtext::facet::mention->new( '$type' => 'app.bsky.richtext.facet#mention', did => 'did:plc:z72i7hdynmk6r22z27h6tvur' ),
    ['At::Lexicon::app::bsky::richtext::facet::mention'], '::richtext::facet::mention'
);
subtest 'facet' => sub {
    my $facet = At::Lexicon::app::bsky::richtext::facet->new(
        index    => { byteEnd => 5, byteStart => 3 },
        features => [
            { '$type' => 'app::bsky::richtext::facet#link',    uri => 'https://google.com/' },
            { '$type' => 'app::bsky::richtext::facet#tag',     tag => 'hi' },
            { '$type' => 'app::bsky::richtext::facet#mention', did => 'did:plc:z72i7hdynmk6r22z27h6tvur' }
        ]
    );
    isa_ok( $facet,                ['At::Lexicon::app::bsky::richtext::facet'],            '::richtext::facet' );
    isa_ok( $facet->index,         ['At::Lexicon::app::bsky::richtext::facet::byteSlice'], '::richtext::facet#index' );
    isa_ok( $facet->features->[0], ['At::Lexicon::app::bsky::richtext::facet::link'],      '::richtext::facet#link' );
    isa_ok( $facet->features->[1], ['At::Lexicon::app::bsky::richtext::facet::tag'],       '::richtext::facet#tag' );
    isa_ok( $facet->features->[2], ['At::Lexicon::app::bsky::richtext::facet::mention'],   '::richtext::facet#mention' );
};
#
done_testing;
