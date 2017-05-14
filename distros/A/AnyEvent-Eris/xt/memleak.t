use t::lib::Eris::Test;

eval { require Test::MemoryGrowth; 1; }
or plan skip_all => 'Test::MemoryGrowth required for this test';

Test::MemoryGrowth::no_growth(
    sub {
        my $client = AnyEvent::eris::Client->new(
            MessageHandler => sub {1},
        );
    },
    burn_in => 10,
    calls   => 20,
    'Constructing Client does not grow memory',
);

Test::MemoryGrowth::no_growth(
    sub { my ($server, $cv) = new_server },
    burn_in => 10,
    calls   => 20,
    'Constructing Server and run does not grow memory',
);

done_testing;
