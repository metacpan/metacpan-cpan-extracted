use 5.020;
use Test::More;
use Boost::UUID;

subtest random_uuid => sub {
    my $uuid = Boost::UUID::random_uuid();

    ok $uuid;
    is length $uuid, 36;

    my $uuid_hash = {};
    $uuid_hash->{Boost::UUID::random_uuid()} = 1 for 1..1000;
    is scalar keys %$uuid_hash, 1000, 'all UUIDs are unique';
};

subtest nil_uuid => sub {
    my $uuid = Boost::UUID::nil_uuid();

    is $uuid, "00000000-0000-0000-0000-000000000000";

    my $uuid_hash = {};
    $uuid_hash->{Boost::UUID::nil_uuid()} = 1 for 1..1000;
    is scalar keys %$uuid_hash, 1, 'all UUIDs are similar';
};

subtest string_uuid => sub {
    is Boost::UUID::string_uuid(""), '';

    is Boost::UUID::string_uuid("test"), '00000000-0000-0000-0000-000000000000', 'wrong uuid string return nil uuid';

    is Boost::UUID::string_uuid("0123456789abcdef0123456789abcdef"), '01234567-89ab-cdef-0123-456789abcdef';
};

subtest name_uuid => sub {
    is Boost::UUID::name_uuid(""), 'e129f27c-5103-5c5c-844b-cdf0a15e160d';

    is Boost::UUID::name_uuid("crazypanda.ru"), '25f9de77-a9a6-5816-b7cb-bafc0a203417';
};


done_testing();
1;
