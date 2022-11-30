use strict;
use warnings;

use Class::Unload;
use YAML;
use File::Slurp;
use Path::Tiny qw(tempfile);
use Test::Warnings;
use Test::More;
use Test::Fatal;
use Test::MockModule;
use Test::MockTime qw(set_fixed_time restore_time);
use RedisDB;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use Clone           qw(clone);

use Data::Validate::Sanctions::Redis;

my $redis_server;
eval { require Test::RedisServer; $redis_server = Test::RedisServer->new(conf => {port => 6379}) }
    or plan skip_all => 'Test::RedisServer is required for this test';

my $redis = RedisDB->new($redis_server->connect_info);

my $sample_data = {
    'EU-Sanctions' => {
        updated => 91,
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
        ],
    },
    'HMT-Sanctions' => {
        updated => 150,
        content => [{
                names     => ['Zaki Izzat Zaki AHMAD'],
                dob_epoch => [],
                dob_year  => [1999],
                dob_text  => ['other info'],
            },
        ]
    },
    'OFAC-Consolidated' => {
        updated => 50,
        content => [{
                names    => ['Atom'],
                dob_year => [1999],
            },
            {
                names    => ['Donald Trump'],
                dob_text => ['circa-1951'],
            },
        ]
    },
    'OFAC-SDN' => {
        updated => 100,
        content => [{
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
};

subtest 'Class constructor' => sub {
    clear_redis();
    my $validator;
    like exception { $validator = Data::Validate::Sanctions::Redis->new() }, qr/Redis connection is missing/, 'Correct error for missing redis';

    ok $validator = Data::Validate::Sanctions::Redis->new(connection => $redis), 'Successfully created the object with redis object';
    is_deeply $validator->data,
        {
        'EU-Sanctions' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'HMT-Sanctions' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'OFAC-Consolidated' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'OFAC-SDN' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        },
        'There is no sanction data';
};

subtest 'Update Data' => sub {
    clear_redis();
    my $mock_fetcher = Test::MockModule->new('Data::Validate::Sanctions::Fetcher');
    my $mock_data    = {
        'EU-Sanctions' => {
            updated => 90,
            content => []
        },
    };
    $mock_fetcher->redefine(run => sub { return clone($mock_data) });
    set_fixed_time(1500);
    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);
    $validator->update_data();
    my $expected = {
        'EU-Sanctions' => {
            content  => [],
            updated  => 90,
            verified => 1500,
        },
        'HMT-Sanctions' => {
            content  => [],
            verified => 1500,
            updated  => 0,
            error    => ''
        },
        'OFAC-Consolidated' => {
            content  => [],
            verified => 1500,
            updated  => 0,
            error    => ''
        },
        'OFAC-SDN' => {
            content  => [],
            verified => 1500,
            updated  => 0,
            error    => ''
        },
    };
    is_deeply $validator->data, $expected, 'Data is correctly loaded';
    check_redis_content('EU-Sanctions',      $mock_data->{'EU-Sanctions'}, 1500);
    check_redis_content('HMT-Sanctions',     {},                           1500);
    check_redis_content('OFAC-Consolidated', {},                           1500);
    check_redis_content('OFAC-SDN',          {},                           1500);

    # rewrite to redis if update (publish) time is changed
    set_fixed_time(1600);
    $mock_data->{'EU-Sanctions'}->{updated} = 91;
    $validator->update_data();
    $expected->{'EU-Sanctions'}->{updated} = 91;
    $expected->{$_}->{verified} = 1600 for keys %$expected;
    is_deeply $validator->data, $expected, 'Data is loaded with new update time';
    check_redis_content('EU-Sanctions', $mock_data->{'EU-Sanctions'}, 1600, 'Redis content changed by increased update time');

    # redis is updated with change in the number of entities, even if the publish date is the same
    $mock_data = {
        'EU-Sanctions' => {
            updated => 91,
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
            ]
        },
    };
    $expected->{'EU-Sanctions'} = clone($mock_data->{'EU-Sanctions'});
    set_fixed_time(1700);
    $validator->update_data();
    $expected->{$_}->{verified} = 1700 for keys %$expected;
    is_deeply $validator->data, $expected, 'Data is changed with new entries, even with the same update date';
    check_redis_content('EU-Sanctions', $expected->{'EU-Sanctions'}, 1700, 'New entries appear in Redis');

    # In case of error, content and dates are not changed
    set_fixed_time(1800);
    $mock_data->{'EU-Sanctions'}->{error}   = 'Test error';
    $mock_data->{'EU-Sanctions'}->{updated} = 92;
    $mock_data->{'EU-Sanctions'}->{content} = [1, 2, 3];
    like Test::Warnings::warning { $validator->update_data() }, qr/EU-Sanctions list update failed because: Test error/,
        'Error warning appears in logs';
    $expected->{'EU-Sanctions'}->{error} = 'Test error';
    $expected->{$_}->{verified} = 1800 for keys %$expected;
    is_deeply $validator->data, $expected, 'Data is not changed if there is error';
    check_redis_content('EU-Sanctions', $expected->{'EU-Sanctions'}, 1800, 'Redis content is not changed when there is an error');

    set_fixed_time(1850);
    $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);
    is_deeply $validator->data->{'EU-Sanctions'}, $expected->{'EU-Sanctions'}, 'All fieds are correctly loaded form redis in constructor';

    # All sources are updated at the same time
    $mock_data = $sample_data;
    $expected  = clone($mock_data);
    set_fixed_time(1900);
    $validator->update_data();
    $expected->{$_}->{verified} = 1900 for keys %$expected;
    is_deeply $validator->data, $expected, 'Data is populated from all sources';
    check_redis_content('EU-Sanctions',  $mock_data->{'EU-Sanctions'},  1900, 'EU-Sanctions error is removed with the same content and update date');
    check_redis_content('HMT-Sanctions', $mock_data->{'HMT-Sanctions'}, 1900, 'Sanction list is stored in redis');
    check_redis_content('OFAC-Consolidated', $mock_data->{'OFAC-Consolidated'}, 1900, 'Sanction list is stored in redis');
    check_redis_content('OFAC-SDN',          $mock_data->{'OFAC-SDN'},          1900, 'Sanction list is stored in redis');

    restore_time();
    $mock_fetcher->unmock_all;
};

subtest 'load data' => sub {
    clear_redis();
    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);
    my $expected  = {
        'EU-Sanctions' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'HMT-Sanctions' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'OFAC-Consolidated' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'OFAC-SDN' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        }};
    is_deeply $validator->data, $expected, 'Saction lists are loaded with default values when redis is empty';
    is $validator->last_updated, 0, 'Updated date is zero';

    my $test_data = {
        'EU-Sanctions'  => {},
        'HMT-Sanctions' => {
            updated     => 1001,
            content     => [{names => ['TMPA']}],
            verified    => 1101,
            extra_field => 1
        },
        'OFAC-SDN' => {
            updated  => 1002,
            content  => [],
            verified => 1102,
            error    => 'Test error'
        }};

    $expected = {
        'EU-Sanctions' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'HMT-Sanctions' => {
            updated  => 1001,
            content  => [{names => ['TMPA']}],
            verified => 1101,
            error    => ''
        },
        'OFAC-Consolidated' => {
            content  => [],
            verified => 0,
            updated  => 0,
            error    => ''
        },
        'OFAC-SDN' => {
            updated  => 1002,
            content  => [],
            verified => 1102,
            error    => 'Test error'
        }};

    for my $source (keys %$test_data) {
        # save data to redis
        for my $field (keys $test_data->{$source}->%*) {
            my $value = $test_data->{$source}->{$field};
            $value = encode_json_utf8($value) if ref $value;
            $redis->hmset("SANCTIONS::$source", $field, $value);
        }
    }

    $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);
    is_deeply $validator->data->{'EU-Sanctions'},
        {
        content  => [],
        verified => 0,
        updated  => 0,
        error    => ''
        },
        'EU sanctions list loaded with default values from Redis';
    is_deeply $validator->data->{'HMT-Sanctions'},
        {
        updated  => 1001,
        content  => [{names => ['TMPA']}],
        verified => 1101,
        error    => ''
        },
        'HMT sanctions loaded correctly with extra field ignored';
    is_deeply $validator->data->{'OFAC-SDN'},
        {
        updated  => 1002,
        content  => [],
        verified => 1102,
        error    => 'Test error'
        },
        'OFAC-SND loaded with correct error';
    is_deeply $validator->data->{'OFAC-Consolidated'},
        {
        content  => [],
        verified => 0,
        updated  => 0,
        error    => ''
        },
        'Missing source OFAC-Consolodated loaded with default values';
    is $validator->last_updated, 1002, 'Update date is the maximum of the dates in all sources';
};

subtest 'get sanctioned info' => sub {
    # reload data freshly from the sample data
    clear_redis();
    set_fixed_time(1000);
    my $mock_fetcher = Test::MockModule->new('Data::Validate::Sanctions::Fetcher');
    $mock_fetcher->redefine(run => sub { return clone($sample_data) });
    my $validator = Data::Validate::Sanctions::Redis->new(connection => $redis);
    $validator->update_data();

    # create a new new validator for sanction checks. No write_redis is needed.
    $validator                     = Data::Validate::Sanctions::Redis->new(connection => $redis);
    $sample_data->{$_}->{verified} = 1000 for keys %$sample_data;
    $sample_data->{$_}->{error}    = ''   for keys %$sample_data;
    is_deeply $validator->data, $sample_data, 'Sample data is correctly loaded';

    ok !$validator->is_sanctioned(qw(sergei ivanov)),                      "Sergei Ivanov not is_sanctioned";
    ok $validator->is_sanctioned(qw(tmpa)),                                "now sanction file is tmpa, and tmpa is in test1 list";
    ok !$validator->is_sanctioned("Mohammad reere yuyuy", "wqwqw  qqqqq"), "is not in test1 list";
    ok $validator->is_sanctioned("Zaki", "Ahmad"),                         "is in test1 list - searched without dob";
    ok $validator->is_sanctioned("Zaki", "Ahmad", '1999-01-05'),           'the guy is sanctioned when dob year is matching';
    ok $validator->is_sanctioned("atom", "test", '1999-01-05'),            "Match correctly with one world name in sanction list";

    is_deeply $validator->get_sanctioned_info("Zaki", "Ahmad", '1999-01-05'),
        {
        'comment'      => undef,
        'list'         => 'HMT-Sanctions',
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
        'list'         => 'EU-Sanctions',
        'matched'      => 1,
        'matched_args' => {'name' => 'TMPA'}
        },
        'Sanction info is correct';

    is_deeply $validator->get_sanctioned_info('Donald', 'Trump', '1999-01-05'),
        {
        'comment'      => 'dob raw text: circa-1951',
        'list'         => 'OFAC-Consolidated',
        'matched'      => 1,
        'matched_args' => {'name' => 'Donald Trump'}
        },
        "When client's name matches a case with dob_text";

    is_deeply $validator->get_sanctioned_info('Bandit', 'Outlaw', '1999-01-05'),
        {
        'comment'      => undef,
        'list'         => 'OFAC-SDN',
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
        'list'         => 'OFAC-SDN',
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
            'list'         => 'OFAC-SDN',
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
    restore_time();
};

sub clear_redis {
    for my $key ($redis->keys('SANCTIONS::*')->@*) {
        $redis->del($key);
    }
}

sub check_redis_content {
    my ($source_name, $config, $verified_time, $comment) = @_;
    $comment //= 'Redis content is correct';

    my %stored = $redis->hgetall("SANCTIONS::$source_name")->@*;
    $stored{content} = decode_json_utf8($stored{content});

    is_deeply \%stored,
        {
        content  => $config->{content} // [],
        updated  => $config->{updated} // 0,
        error    => $config->{error}   // '',
        verified => $verified_time,
        },
        "$comment - $source_name";
}

done_testing;
