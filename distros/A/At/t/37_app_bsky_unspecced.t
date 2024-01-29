use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class     qw[isa_ok];
use Test2::Tools::Exception qw[try_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At::Bluesky;
#
subtest 'live' => sub {
    my $bsky = At::Bluesky->new( identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );
    subtest 'unspecced_getPopularFeedGenerators' => sub {
        ok my $res = $bsky->unspecced_getPopularFeedGenerators(), '$bsky->unspecced_getPopularFeedGenerators()';
        isa_ok $res->{feeds}->[0], ['At::Lexicon::app::bsky::feed::generatorView'], '...returns a list of ::bsky::feed::generatorView objects';
    };
    subtest 'unspecced_getTaggedSuggestions' => sub {
        ok my $res = $bsky->unspecced_getTaggedSuggestions(), '$bsky->unspecced_getTaggedSuggestions()';
        isa_ok $res->{suggestions}->[0], ['At::Lexicon::app::bsky::unspecced::suggestion'],
            '...returns a list of ::bsky::unspecced::suggestion objects';
    };
    subtest 'unspecced_searchActorsSkeleton' => sub {
        my $todo = todo 'searchActorsSkeleton is unsupported';    # it comes and goes...
    SKIP: {
            ok my $res = eval { $bsky->unspecced_searchActorsSkeleton('perl') }, '$bsky->unspecced_searchActorsSkeleton("perl")';
            skip 'searchActorsSkeleton is unsupported' if !$res->{actors};
            isa_ok $res->{actors}->[0], ['At::Lexicon::app::bsky::unspecced::skeletonSearchActor'],
                '...returns a list of ::bsky::unspecced::skeletonSearchActor objects';
        }
    };
    subtest 'unspecced_searchPostsSkeleton' => sub {
        my $todo = todo 'searchActorsSkeleton is unsupported';    # it comes and goes...
    SKIP: {
            ok my $res = eval { $bsky->unspecced_searchPostsSkeleton('perl') }, '$bsky->unspecced_searchPostsSkeleton("perl")';
            skip 'unspecced_searchPostsSkeleton is unsupported' if !$res->{posts};
            isa_ok $res->{posts}->[0], ['At::Lexicon::app::bsky::unspecced::skeletonSearchPost'],
                '...returns a list of ::bsky::unspecced::skeletonSearchPost objects';
        }
    };
};
#
done_testing;
