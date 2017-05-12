use Test::More;
BEGIN { use_ok('Data::Faker') };

subtest 'instance is returned' => sub {
    new_ok('Data::Faker' => ['StreetAddress']);
};

subtest 'all methods return something' => sub {
    my $faker = Data::Faker->new('StreetAddress');
    ok($faker->$_(),$_) for $faker->methods;
};

done_testing();
