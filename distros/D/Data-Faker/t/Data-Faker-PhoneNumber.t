use Test::More;
BEGIN { use_ok('Data::Faker') };

subtest 'instance is returned' => sub {
    new_ok('Data::Faker' => ['PhoneNumber']);
};

subtest 'all methods return something' => sub {
    my $faker = Data::Faker->new('PhoneNumber');
    ok($faker->$_(),$_) for $faker->methods;
};

done_testing();
