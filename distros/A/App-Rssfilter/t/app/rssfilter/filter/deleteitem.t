use Test::Most;

use App::Rssfilter::Filter::DeleteItem;
use Mojo::DOM;

throws_ok(
    sub { App::Rssfilter::Filter::DeleteItem::filter },
    qr/missing required argument/,
    'throws error when not given an item to delete'
);

throws_ok(
    sub { App::Rssfilter::Filter::DeleteItem::filter( qw< one two three > ) },
    qr/too many arguments/,
    'throws error when given multiple matchers'
);

is(
    App::Rssfilter::Filter::DeleteItem::filter( Mojo::DOM->new( '<title>Man Bites Dog</title>' ), 'SensationalHeadline' ),
    '',
    'deletes content of item when a reason is given'
);

is(
    App::Rssfilter::Filter::DeleteItem::filter( Mojo::DOM->new( '<title>Man Bites Dog</title>' ) ),
    '',
    'deletes content of item when a reason is not given'
);

done_testing;
