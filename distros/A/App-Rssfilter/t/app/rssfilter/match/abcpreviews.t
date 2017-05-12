use Test::Most;

use App::Rssfilter::Match::AbcPreviews;
use Mojo::DOM;

throws_ok(
    sub { App::Rssfilter::Match::AbcPreviews::match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { App::Rssfilter::Match::AbcPreviews::match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one item to match'
);

ok(
    App::Rssfilter::Match::AbcPreviews::match( Mojo::DOM->new( '<guid>I am a preview<\guid>' ) ),
    'match item whose guid contains "preview"'
);

ok(
    ! App::Rssfilter::Match::AbcPreviews::match( Mojo::DOM->new( '<guid>I am a human being<\guid>' ) ),
    'does not match item whose guid does not contain "preview"'
);

ok(
    ! App::Rssfilter::Match::AbcPreviews::match( Mojo::DOM->new( '<title>sneak peek preview season</title><guid>http://hoop.de.doo/sneak-preview</guid>' ) ),
    'does not match item whose title and guid contain "preview"'
);

done_testing;
