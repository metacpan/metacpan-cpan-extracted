use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
#
subtest 'live' => sub {
    my $at = At->new( host => 'https://bsky.social', identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );
    use At::Lexicon::app::bsky::feed;
    my $msg = 'Hello world! I posted this via the API. Today is ' . localtime;
    ok my $newpost = $at->repo_createRecord(
        repo       => $at->did,
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => $msg, createdAt => time }
        ),
        'repo_createRecord( ... )';
    isa_ok $newpost->{uri}, ['URI'];
    my ($rkey) = ( $newpost->{uri}->as_string =~ m[at://did:plc:.+?/app.bsky.feed.post/(.+)] );
    diag '$rkey == ' . $rkey;
    subtest 'putRecord' => sub {
    SKIP:
        {
            skip 'Bluesky is only accepting updates for app.bsky.actor.profile, app.bsky.graph.list, app.bsky.feed.generator';
            ok my $editpost = $at->repo_putRecord(
                repo       => $at->did,
                collection => 'app.bsky.feed.post',
                rkey       => $rkey,
                record     => { '$type' => 'app.bsky.feed.post', text => join( ' ', reverse split( ' ', $msg ) ), createdAt => time }
                ),
                sprintf '$at->repo_putRecord( rkey => "%s", ... )', $rkey;
            isa_ok $editpost->{uri}, ['URI'];
            ($rkey) = ( $editpost->{uri}->as_string =~ m[at://did:plc:.+?/app.bsky.feed.post/(.+)] );
            diag '$rkey == ' . $rkey;
        }
    };
    subtest 'repo_getRecord' => sub {
        ok my $record = $at->repo_getRecord( repo => $at->did, collection => 'app.bsky.feed.post', rkey => $rkey ), '$at->repo_getRecord( ... )';
        is $record->{value}->text, $msg, ' ->{value}->text';
    };
    ok $at->repo_deleteRecord( repo => $at->did, collection => 'app.bsky.feed.post', rkey => $rkey ), sprintf '$at->repo_deleteRecord( "%s", ... )',
        $rkey;
    subtest 'repo_describeRepo' => sub {
        ok my $desc = $at->repo_describeRepo( $at->did ), sprintf '$at->repo_describeRepo( "%s", ... )', $at->did->_raw;
        todo 'updating things might give us unexpected access to new collections and this list will be incomplete' => sub {
            is $desc->{collections}, [ 'app.bsky.actor.profile', 'app.bsky.feed.like', 'app.bsky.feed.post', 'app.bsky.graph.follow' ],
                ' ->{collections}';
        };
        is $desc->{handle}->_raw, 'atperl.bsky.social', ' ->{handle}';
    };
    subtest 'repo_listRecords' => sub {
        ok my $res = $at->repo_listRecords( $at->did, 'app.bsky.feed.post' ), sprintf '$at->repo_listRecords( "%s", "app.bsky.feed.post" )',
            $at->did->_raw;
        isa_ok $res->{records}[0], ['At::Lexicon::com::atproto::repo::listRecords::record'], '->{records}[0]';
    };
    isa_ok my $create = At::Lexicon::com::atproto::repo::applyWrites::create->new(
        collection => 'app.bsky.feed.post',
        rkey       => $rkey,
        value      => {
            '$type'   => 'app.bsky.feed.post',
            text      => 'Hello world! I posted this via the API.',
            createdAt => At::Protocol::Timestamp->new( timestamp => time )->_raw
        }
    );
    isa_ok my $delete = At::Lexicon::com::atproto::repo::applyWrites::delete->new( collection => 'app.bsky.feed.post', rkey => $rkey );

    #~ ok $at->repo_applyWrites( $at->did, [ $create, $delete ], 1 );
};
#
done_testing;
