use Test::More;
BEGIN { use_ok('Data::Faker') };

subtest 'instance is returned' => sub {
    new_ok('Data::Faker');
};

subtest 'all methods return something true-ish' => sub {
    my $faker = Data::Faker->new();
    foreach($faker->methods) {
        ok($faker->$_(), $_);
    }
};

done_testing();
