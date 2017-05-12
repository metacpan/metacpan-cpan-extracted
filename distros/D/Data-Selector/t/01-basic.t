use Data::Selector;
use Test::More;
use strict;
use warnings FATAL => 'all';

my $data_tree = {
    count => 2,
    items => [
        {
            author => {
                first_name => 'jdv',
                id         => '123',
            },
            id       => '5544332211',
            url_name => 'some-random-article',
        },
        {
            id       => '1122334455',
            url_name => 'other_random_article',
        },
    ],
    _version => 3,
};

my $selector_string = join( ',', "items.[*].[author.-id,url_name]", "-count", );

my $selector_tree =
  Data::Selector->parse_string( { selector_string => $selector_string, } );

is_deeply(
    $selector_tree,
    {
        '-count' => { _order_ => 2, },
        '+items' => {
            _order_ => 1,
            '+*'    => {
                _order_   => 3,
                '+author' => {
                    _order_ => 4,
                    '-id'   => { _order_ => 6, },
                },
                '+url_name' => { _order_ => 5, },
            },
        },
    },
    'selector tree'
);

Data::Selector->apply_tree(
    {
        selector_tree => $selector_tree,
        data_tree     => $data_tree,
    }
);

is_deeply(
    $data_tree,
    {
        'items' => [
            {
                'author' => { 'first_name' => 'jdv', },
                'url_name' => 'some-random-article',
            },
            { 'url_name' => 'other_random_article', },
        ],
    },
    'data tree'
);

done_testing;
