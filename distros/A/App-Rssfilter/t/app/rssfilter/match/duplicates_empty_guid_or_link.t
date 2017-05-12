use Test::Most;

use App::Rssfilter::Match::Duplicates;
use Mojo::DOM;

App::Rssfilter::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid></guid><link>Dominant Species</link>' ) ),

ok(
    ! App::Rssfilter::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid></guid><link>Urban Sprawl</link>' ) ),
    'item with empty guid is not matched as a duplicate of a previous item with an empty guid'
);

App::Rssfilter::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>Combat Commander: Europe</guid><link></link>' ) ),

ok(
    ! App::Rssfilter::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>Fighting Formations: Grossdeutchland Division</guid><link></link>' ) ),
    'item with empty link is not matched as a duplicate of a previous item with an empty link'
);

done_testing;
