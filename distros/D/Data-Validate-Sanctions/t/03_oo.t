use strict;
use Class::Unload;
use Data::Validate::Sanctions;
use YAML::XS   qw(Dump);
use Path::Tiny qw(tempfile);
use Test::Warnings;
use Test::More;
use Test::RedisServer;
use RedisDB;
my $redis_server;
eval { require Test::RedisServer; $redis_server = Test::RedisServer->new(conf => {port => 6379}) }
    or plan skip_all => 'Test::RedisServer is required for this test';
my $validator = Data::Validate::Sanctions->new;

ok $validator->is_sanctioned('NEVEROV', 'Sergei Ivanovich', -253411200), "Sergei Ivanov is_sanctioned for sure";
my $result = $validator->get_sanctioned_info('abu', 'usama', -306028800);
is $result->{matched},                   1;
is $result->{matched_args}->{dob_epoch}, -306028800;
ok $result->{matched_args}->{name} =~ m/\babu\b/i and $result->{matched_args}->{name} =~ m/\busama\b/i;

ok !$validator->is_sanctioned(qw(chris down)), "Chris is a good guy";

$result = $validator->get_sanctioned_info('ABBATTAY', 'Mohamed', 174614567);
is $result->{matched}, 0, 'ABBATTAY Mohamed is safe';

$result = $validator->get_sanctioned_info('Ali', 'Abu');
is $result->{matched}, 1, 'Should match because has dob_text';

$result = $validator->get_sanctioned_info('Abu', 'Salem', '1948-10-10');
is $result->{matched},                  1;
is $result->{matched_args}->{dob_year}, 1948;
ok $result->{matched_args}->{name} =~ m/\babu\b/i and $result->{matched_args}->{name} =~ m/\bsalem\b/i;

my $tmpa = tempfile;

$tmpa->spew(
    Dump({
            test1 => {
                updated => time,
                content => [{
                        names     => ['TMPA'],
                        dob_epoch => [],
                        dob_year  => []
                    },
                    {
                        names     => ['MOHAMMAD EWAZ Mohammad Wali'],
                        dob_epoch => [],
                        dob_year  => []
                    },
                    {
                        names     => ['Zaki Izzat Zaki AHMAD'],
                        dob_epoch => [],
                        dob_year  => [1999],
                        dob_text  => ['other info'],
                    },
                    {
                        names    => ['Atom'],
                        dob_year => [1999],
                    },
                    {
                        names    => ['Donald Trump'],
                        dob_text => ['circa-1951'],
                    },
                    {
                        names          => ['Bandit Outlaw'],
                        place_of_birth => ['ir'],
                        residence      => ['fr', 'us'],
                        nationality    => ['de', 'gb'],
                        citizen        => ['ru'],
                        postal_code    => ['123321'],
                        national_id    => ['321123'],
                        passport_no    => ['asdffdsa'],
                    }]
            },
        }));

my $tmpb = tempfile;

$tmpb->spew(
    Dump {
        test2 => {
            updated => time,
            content => [{
                    names     => ['TMPB'],
                    dob_epoch => [],
                    dob_year  => []}]
        },
    });

$validator = Data::Validate::Sanctions->new(sanction_file => "$tmpa");
ok !$validator->is_sanctioned(qw(sergei ivanov)),                      "Sergei Ivanov not is_sanctioned";
ok $validator->is_sanctioned(qw(tmpa)),                                "now sanction file is tmpa, and tmpa is in test1 list";
ok !$validator->is_sanctioned("Mohammad reere yuyuy", "wqwqw  qqqqq"), "is not in test1 list";
ok $validator->is_sanctioned("Zaki", "Ahmad"),                         "is in test1 list - searched without dob";
ok $validator->is_sanctioned("Zaki", "Ahmad", '1999-01-05'),           'the guy is sanctioned when dob year is matching';
ok $validator->is_sanctioned("atom", "test", '1999-01-05'),            "Match correctly with one world name in sanction list";

is_deeply $validator->get_sanctioned_info("Zaki", "Ahmad", '1999-01-05'),
    {
    'comment'      => undef,
    'list'         => 'test1',
    'matched'      => 1,
    'matched_args' => {
        'dob_year' => 1999,
        'name'     => 'Zaki Izzat Zaki AHMAD'
    }
    },
    'Sanction info is correct';
ok $validator->is_sanctioned("Ahmad", "Ahmad", '1999-10-10'), "is in test1 list";

is_deeply $validator->get_sanctioned_info("TMPA"),
    {
    'comment'      => undef,
    'list'         => 'test1',
    'matched'      => 1,
    'matched_args' => {'name' => 'TMPA'}
    },
    'Sanction info is correct';

is_deeply $validator->get_sanctioned_info('Donald', 'Trump', '1999-01-05'),
    {
    'comment'      => 'dob raw text: circa-1951',
    'list'         => 'test1',
    'matched'      => 1,
    'matched_args' => {'name' => 'Donald Trump'}
    },
    "When client's name matches a case with dob_text";

is_deeply $validator->get_sanctioned_info('Bandit', 'Outlaw', '1999-01-05'),
    {
    'comment'      => undef,
    'list'         => 'test1',
    'matched'      => 1,
    'matched_args' => {'name' => 'Bandit Outlaw'}
    },
    "If optional ares are empty, only name is matched";

my $args = {
    first_name     => 'Bandit',
    last_name      => 'Outlaw',
    place_of_birth => 'Iran',
    residence      => 'France',
    nationality    => 'Germany',
    citizen        => 'Russia',
    postal_code    => '123321',
    national_id    => '321123',
    passport_no    => 'asdffdsa',
};

is_deeply $validator->get_sanctioned_info($args),
    {
    'comment'      => undef,
    'list'         => 'test1',
    'matched'      => 1,
    'matched_args' => {
        name           => 'Bandit Outlaw',
        place_of_birth => 'ir',
        residence      => 'fr',
        nationality    => 'de',
        citizen        => 'ru',
        postal_code    => '123321',
        national_id    => '321123',
        passport_no    => 'asdffdsa',
    }
    },
    "All matched fields are returned";

for my $field (qw/place_of_birth residence nationality citizen postal_code national_id passport_no/) {
    is_deeply $validator->get_sanctioned_info({%$args, $field => 'Israel'}),
        {'matched' => 0}, "A single wrong field will result in mismatch - $field";

    my $expected_result = {
        'list'         => 'test1',
        'matched'      => 1,
        'matched_args' => {
            name           => 'Bandit Outlaw',
            place_of_birth => 'ir',
            residence      => 'fr',
            nationality    => 'de',
            citizen        => 'ru',
            postal_code    => '123321',
            national_id    => '321123',
            passport_no    => 'asdffdsa',
        },
        comment => undef,
    };

    delete $expected_result->{matched_args}->{$field};
    is_deeply $validator->get_sanctioned_info({%$args, $field => undef}), $expected_result, "Missing optional args are ignored - $field";
}

Class::Unload->unload('Data::Validate::Sanctions');
local $ENV{SANCTION_FILE} = "$tmpb";
require Data::Validate::Sanctions;
$validator = Data::Validate::Sanctions->new;
ok $validator->is_sanctioned(qw(tmpb)), "get sanction file from ENV";
$validator = Data::Validate::Sanctions->new(sanction_file => "$tmpa");
ok $validator->is_sanctioned(qw(tmpa)), "get sanction file from args";

subtest 'Subclass factory' => sub {
    my $redis = RedisDB->new($redis_server->connect_info);

    my $validator = Data::Validate::Sanctions->new(
        storage    => 'redis',
        connection => $redis
    );
    is ref($validator), 'Data::Validate::Sanctions::Redis', 'A validator with redis storage is created';
};

done_testing;
