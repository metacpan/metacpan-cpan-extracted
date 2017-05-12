use Test::More;
BEGIN { use_ok('Data::Faker::Internet') };

subtest 'instance is returned' => sub {
    new_ok('Data::Faker' => ['Internet']);
};

subtest 'all methods return something true-ish' => sub {
    my $faker = Data::Faker->new('Internet');
    ok($faker->$_(),$_) for $faker->methods;
};

done_testing();
