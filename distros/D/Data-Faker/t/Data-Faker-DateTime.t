use Test::More;
BEGIN { use_ok('Data::Faker::DateTime') };

subtest 'instance is returned' => sub {
    new_ok('Data::Faker' => ['DateTime']);
};

subtest 'all methods return something true-ish' => sub {
    my $faker = Data::Faker->new('DateTime');
    ok($faker->$_(),$_) for $faker->methods;
};

done_testing();
