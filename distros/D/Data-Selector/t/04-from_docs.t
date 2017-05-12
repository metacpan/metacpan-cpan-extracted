use Data::Selector;
use Storable ();
use Test::More;
use strict;
use warnings FATAL => 'all';

# synopsis
{
    my @sets = (
        {
            named_selectors => { '$bla' => '[non-existent,asdf]', },
            selector_string => '$bla,foo.bar.baz*2.1..-1',
            desc            => 'sans plus signs',
        },
        {
            named_selectors => { '$bla' => '[+non-existent,+asdf]', },
            selector_string => '$bla,+foo.+bar.+baz*2.+1..-1',
            desc            => 'with plus signs',
        },
    );

    for (@sets) {
        my $data_tree = {
            foo => {
                bar => { baz1 => 1, baz22 => 2, baz32 => [ 'a', 'b', 'c', ], },
            },
            asdf => 'woohoo',
        };

        Data::Selector->apply_tree(
            {
                selector_tree => Data::Selector->parse_string( $_, ),
                data_tree     => $data_tree,
            }
        );

        is_deeply(
            $data_tree,
            {
                foo  => { bar => { baz22 => 2, baz32 => [ 'b', 'c', ], }, },
                asdf => 'woohoo',
            },
            $_->{desc},
        );
    }
}

my $examples_data_tree = {
    count => 2,
    items => [
        {
            body      => 'b1',
            links     => [ 'l1', 'l2', 'l3', ],
            rel_1_url => 'foo',
            rel_1_id  => 12,
            rel_2_url => 'bar',
            rel_2_id  => 34,
        },
        {
            body      => 'b2',
            links     => [ 'l4', 'l5', ],
            rel_1_url => 'up',
            rel_1_id  => 56,
            rel_2_url => 'down',
            rel_2_id  => 78,
        },
    ],
    total => 42,
};

# example 1
{
    my $data_tree = Storable::dclone($examples_data_tree);

    Data::Selector->apply_tree(
        {
            selector_tree =>
              Data::Selector->parse_string( { selector_string => 'total', } ),
            data_tree => $data_tree,
        }
    );

    is_deeply( $data_tree, { total => 42, }, 'example 1', );
}

# example 2
{
    my $data_tree = Storable::dclone($examples_data_tree);

    Data::Selector->apply_tree(
        {
            selector_tree => Data::Selector->parse_string(
                { selector_string => 'items.*.rel_*_url', }
            ),
            data_tree => $data_tree,
        }
    );

    is_deeply(
        $data_tree,
        {
            items => [
                {
                    rel_1_url => 'foo',
                    rel_2_url => 'bar',
                },
                {
                    rel_1_url => 'up',
                    rel_2_url => 'down',
                },
            ],
        },
        'example 2',
    );
}

# example 3
{
    my $data_tree = Storable::dclone($examples_data_tree);

    Data::Selector->apply_tree(
        {
            selector_tree => Data::Selector->parse_string(
                { selector_string => 'count,items.+-1.-body', }
            ),
            data_tree => $data_tree,
        }
    );

    is_deeply(
        $data_tree,
        {
            count => 2,
            items => [
                {
                    links     => [ 'l4', 'l5', ],
                    rel_1_url => 'up',
                    rel_1_id  => 56,
                    rel_2_url => 'down',
                    rel_2_id  => 78,
                },
            ],
        },
        'example 3',
    );
}

# example 4
{
    my $data_tree = Storable::dclone($examples_data_tree);

    Data::Selector->apply_tree(
        {
            selector_tree => Data::Selector->parse_string(
                { selector_string => 'items.*.links.+-2..-1', }
            ),
            data_tree => $data_tree,
        }
    );

    is_deeply(
        $data_tree,
        {
            items =>
              [ { links => [ 'l2', 'l3', ], }, { links => [ 'l4', 'l5', ], }, ],
        },
        'example 4',
    );
}

done_testing;
