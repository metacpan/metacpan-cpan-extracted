use strict;
use utf8;
use Test::More;

use Acme::Lou;

my $lou = Acme::Lou->new;

is(
    $lou->translate('今年もよろしくお願いいたします。', { lou_rate => 0 }),
    '今年もよろしくお願いいたします。',
    'lou_rate = 0'
);

done_testing();
