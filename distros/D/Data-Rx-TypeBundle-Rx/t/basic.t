use strict;
use warnings;

use Test::More tests => 2;
use Data::Rx;
use Data::Rx::TypeBundle::Rx;

my $custom_types = Data::Rx::TypeBundle::Rx->new;
$custom_types->register_type('tag:contentment.org:rx/test/foo', {
    type => '//num',
});

my $rx = Data::Rx->new({
    prefix => {
        test => 'tag:contentment.org:rx/test/',
    },
    type_plugins => [ $custom_types ],
});

my $checker = $rx->make_schema({ type => '/test/foo' });

ok($checker->check(42), '42 is a /test/foo');
ok(!$checker->check('blah'), 'blah is not a /test/foo');

