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
    At::Lexicon::app::bsky::embed::recordWithMedia->new(
        record => bless( {}, 'trash' ),
        media  => {
            '$type' => 'app.bsky.embed.images',
            images  => [ { image => 'fake', alt => 'not a real image', aspectRatio => { width => 16, height => 9 } } ]
        }
    ),
    ['At::Lexicon::app::bsky::embed::recordWithMedia'],
    '::recordWithMedia (image)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::recordWithMedia->new(
        record => bless( {}, 'trash' ),
        media  => {
            '$type'  => 'app.bsky.embed.external',
            external =>
                { uri => 'https://google.com/', title => 'Google.com', description => 'You gotta know what this is by now.', thumb => 'fake image' }
        }
    ),
    ['At::Lexicon::app::bsky::embed::recordWithMedia'],
    '::recordWithMedia (external)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record->new( '$type' => 'app.bsky.embed.record#viewRecord', record => { uri => 'https://at.uri/', cid => 'ok' } ),
    ['At::Lexicon::app::bsky::embed::record'], '::record'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::view->new(
        '$type' => 'app.bsky.embed.record#viewRecord',
        record  => {
            uri       => 'https://at.uri/',
            cid       => 'blah',
            author    => { did => 'did:web:fdsafdsajfkldsajkfldsajk', handle => 'fun.com' },
            value     => {},
            indexedAt => '2023-12-13T01:51:24Z'
        }
    ),
    ['At::Lexicon::app::bsky::embed::record::view'],
    '::record::view (#viewRecord)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::view->new(
        '$type' => 'app.bsky.embed.record#viewNotFound',
        record  => { uri => 'https://at.uri/', notFound => 1 }
    ),
    ['At::Lexicon::app::bsky::embed::record::view'],
    '::record::view (#viewNotFound)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::view->new(
        '$type' => 'app.bsky.embed.record#viewBlocked',
        record  => { uri => 'https://at.uri/', blocked => 1, author => { did => 'did:web:fdsafdsafdsafdsafsdafdsa' } }
    ),
    ['At::Lexicon::app::bsky::embed::record::view'],
    '::record::view (#viewBlocked)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::view->new(
        '$type' => 'app.bsky.feed.defs#generatorView',
        record  => {
            cid         => 'idk',
            creator     => { did => 'did:web:fdsafdsafdasfdsafds', handle => 'random.user' },
            did         => 'did:web:fdsjaofewaofewafdsajfkd',
            displayName => 'demo',
            indexedAt   => '2023-12-13T01:51:24Z',
            uri         => 'https://fake.uri/'
        }
    ),
    ['At::Lexicon::app::bsky::embed::record::view'],
    '::record::view (app.bsky.feed.defs#generatorView)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::view->new(
        '$type' => 'app.bsky.graph.defs#listView',
        record  => {
            uri       => 'https://google.com/',
            indexedAt => '2023-12-13T01:51:24Z',
            name      => 'fake',
            cid       => 'notreal',
            creator   => { did => 'did:web:fdsafdsafdasfdsafds', handle => 'random.user' },
            purpose   => 'app.bsky.graph.defs#modlist'
        }
    ),
    ['At::Lexicon::app::bsky::embed::record::view'],
    '::record::view (app.bsky.graph.defs#listView)'
);
isa_ok(
    At::Lexicon::app::bsky::embed::record::viewRecord->new(
        '$type'   => 'app.bsky.graph.defs#listView',
        uri       => 'https://google.com/',
        cid       => 'fdsafdsa',
        author    => { did  => 'did:web:fdsafdsjafkdsjakfldsaf', handle => 'fake.com' },
        value     => { this => 'is',                             user   => 'defined' },
        indexedAt => '2023-12-13T01:51:24Z',
        embeds    => [
            { '$type' => 'app.bsky.embed.images#view', images => [] },
            {   '$type'  => 'app.bsky.embed.external#view',
                external => { uri => 'https://google.com', title => 'Google', description => 'Search engine' }
            },
            { '$type' => 'app.bsky.embed.record#view', record => {} },
            {   '$type' => 'app.bsky.embed.recordWithMedia#view',
                record  => { '$type' => 'app.bsky.embed.record#view', record => {} },
                media   =>
                    { '$type' => 'app.bsky.embed.external', external => { uri => 'https://google.com/', title => 'Google', description => 'NA' } }
            }
        ]
    ),
    ['At::Lexicon::app::bsky::embed::record::viewRecord'],
    '::record::viewRecord (app.bsky.graph.defs#listView)'
);
#
done_testing;
