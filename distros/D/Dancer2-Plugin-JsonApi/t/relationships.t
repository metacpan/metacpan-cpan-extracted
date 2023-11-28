use Test2::V0;

use Dancer2::Plugin::JsonApi::Registry;

use experimental qw/ signatures /;

my $registry = Dancer2::Plugin::JsonApi::Registry->new;

$registry->add_type( 'thing',
    { relationships => { subthings => { type => 'subthing' }, } } );
$registry->add_type('subthing');

subtest basic => sub {
    my $s = $registry->serialize(
        'thing',
        {   id        => 1,
            subthings => [ { id => 2, x => 10 }, { id => 3 } ]
        }
    );

    ok not $s->{data}{attributes};

    like $s => {
        data => {
            id            => 1,
            type          => 'thing',
            relationships =>
              { subthings => { data => [ { id => 2 }, { id => 3 } ] } }
        },
        included =>
          [ { type => 'subthing', id => 2, attributes => { x => 10 } }, ]
    };

};

subtest "don't repeat includes" => sub {
    my $s = $registry->serialize(
        'thing',
        [
            {   id        => 1,
                subthings => [
                    {   id => 2,
                        x  => 10
                    },
                    {   id => 3,
                        y  => 20
                    }
                ]
            },
            {   id        => 2,
                subthings => [
                    {   id => 3,
                        y  => 20
                    },
                    {   id => 2,
                        x  => 10
                    }
                ]
            }
        ]
    );

    is $s->{included}->@* + 0, 2;
};

done_testing;
