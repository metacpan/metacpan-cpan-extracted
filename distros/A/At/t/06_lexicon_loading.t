use Test2::V0;
use At;
use v5.42;
my $at = At->new( host => 'bsky.social' );
subtest 'lexicon loading' => sub {
    ok $at->_locate_lexicon('app.bsky.feed.getTimeline'),        'found app.bsky.feed.getTimeline';
    ok $at->_locate_lexicon('app.bsky.actor.getProfile'),        'found app.bsky.actor.getProfile';
    ok $at->_locate_lexicon('chat.bsky.convo.sendMessage'),      'found chat.bsky.convo.sendMessage';
    ok $at->_locate_lexicon('tools.ozone.moderation.emitEvent'), 'found tools.ozone.moderation.emitEvent';
    ok $at->_locate_lexicon('com.atproto.sync.subscribeRepos'),  'found com.atproto.sync.subscribeRepos';

    # Test normalization of #main
    ok $at->_locate_lexicon('app.bsky.feed.post'),      'found app.bsky.feed.post';
    ok $at->_locate_lexicon('app.bsky.feed.post#main'), 'found app.bsky.feed.post#main';
};
subtest 'subscribe method' => sub {
    can_ok $at, 'subscribe';
};
subtest 'custom lexicon_paths' => sub {
    use Path::Tiny;
    use JSON::PP qw[encode_json];
    my $temp_dir = Path::Tiny->tempdir;
    my $lex_dir  = $temp_dir->child( 'com', 'example' );
    $lex_dir->mkpath;
    $lex_dir->child('test.json')
        ->spew_raw( encode_json( { lexicon => 1, id => 'com.example.test', defs => { main => { type => 'query', description => 'Test' } } } ) );
    my $at_custom = At->new( lexicon_paths => [$temp_dir] );
    ok $at_custom->_locate_lexicon('com.example.test'), 'found custom lexicon in provided path';
};
done_testing;
