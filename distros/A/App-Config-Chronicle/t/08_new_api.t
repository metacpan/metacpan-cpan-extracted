use Test::Most;
use Test::Warn;
use Test::MockModule;
use Test::MockTime qw( :all );
use Data::Chronicle::Mock;
use App::Config::Chronicle;
use FindBin qw($Bin);

use constant {
    EMAIL_KEY     => 'system.email',
    FIRST_EMAIL   => 'abc@test.com',
    SECOND_EMAIL  => 'def@test.com',
    THIRD_EMAIL   => 'ghi@test.com',
    DEFAULT_EMAIL => 'dummy@email.com',
    ADMINS_KEY    => 'system.admins',
    ADMINS_SET    => ['john', 'bob', 'jane', 'susan'],
    REFRESH_KEY   => 'system.refresh',
    REFRESH_SET   => 20,
    DEFAULT_REF   => 10,
    NON_EXT_KEY   => 'system.wrong'
};

my $tick = 0;
set_fixed_time($tick);

{
    no warnings 'redefine';
    *Time::HiRes::time = \&Test::MockTime::time;
}

subtest 'Global revision = 0' => sub {
    my $app_config = _new_app_config();
    is $app_config->global_revision(), 0, 'Brand new app config returns 0 revision';
};

subtest 'Cannot externally set global_revision' => sub {
    my $app_config = _new_app_config();
    throws_ok {
        $app_config->set({'_global_rev' => 1});
    }
    qr/Cannot set with key/;
};

subtest 'Dynamic keys' => sub {
    my $app_config = _new_app_config();
    my @keys       = $app_config->dynamic_keys;
    is_deeply [sort @keys], [EMAIL_KEY, REFRESH_KEY], 'Keys are listed correctly';
};

subtest 'Static keys' => sub {
    my $app_config = _new_app_config();
    my @keys       = $app_config->static_keys;
    is_deeply [sort @keys], [ADMINS_KEY], 'Keys are listed correctly';
};

subtest 'All keys' => sub {
    my $app_config = _new_app_config();
    my @keys       = $app_config->all_keys();
    is_deeply [sort @keys], [ADMINS_KEY, EMAIL_KEY, REFRESH_KEY], 'Keys are listed correctly';
};

subtest 'Default values' => sub {
    my $app_config = _new_app_config();
    is $app_config->get(EMAIL_KEY),   DEFAULT_EMAIL, 'Default email is returned';
    is $app_config->get(REFRESH_KEY), DEFAULT_REF,   'Default refresh is returned';
    is_deeply $app_config->get(ADMINS_KEY), [], 'Default admins are returned';

    ok my $multi = $app_config->get([EMAIL_KEY, REFRESH_KEY]), 'Mget defaults is ok';
    is $multi->{EMAIL_KEY()},   DEFAULT_EMAIL, 'Default email is returned';
    is $multi->{REFRESH_KEY()}, DEFAULT_REF,   'Default refresh is returned';
};

subtest 'Check types' => sub {
    my $app_config = _new_app_config();
    is $app_config->get_data_type(NON_EXT_KEY), undef,      'Bad key returns nothing';
    is $app_config->get_data_type(EMAIL_KEY),   'Str',      'Email type is correct';
    is $app_config->get_data_type(ADMINS_KEY),  'ArrayRef', 'Admins type is correct';
    is $app_config->get_data_type(REFRESH_KEY), 'Num',      'Refresh rate type is correct';
};

subtest 'Check key types' => sub {
    my $app_config = _new_app_config();
    is $app_config->get_key_type(NON_EXT_KEY), undef,     'Bad key returns nothing';
    is $app_config->get_key_type(EMAIL_KEY),   'dynamic', 'Email type is correct';
    is $app_config->get_key_type(ADMINS_KEY),  'static',  'Admins type is correct';
    is $app_config->get_key_type(REFRESH_KEY), 'dynamic', 'Refresh rate type is correct';
};

subtest 'Basic set and get' => sub {
    my $app_config = _new_app_config();

    ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set 1 value succeeds';
    is $app_config->get(EMAIL_KEY), FIRST_EMAIL, 'Email is retrieved successfully';
};

subtest 'Batch set and get' => sub {
    my $app_config = _new_app_config();

    ok $app_config->set({
            EMAIL_KEY()   => FIRST_EMAIL,
            REFRESH_KEY() => REFRESH_SET
        }
        ),
        'Set 2 values succeeds';

    ok my $res = $app_config->get([EMAIL_KEY, REFRESH_KEY]);
    is $res->{EMAIL_KEY()},   FIRST_EMAIL, 'Email is retrieved successfully';
    is $res->{REFRESH_KEY()}, REFRESH_SET, 'Refresh is retrieved successfully';
    exists $res->{'_global_rev'}, 'Batch get returns global revision';
};

subtest 'Gets/sets of illegal keys' => sub {
    subtest 'Attempt to set static key' => sub {
        my $app_config = _new_app_config();
        throws_ok {
            $app_config->set({ADMINS_KEY() => ADMINS_SET});
        }
        qr/Cannot set with key/;
    };

    subtest 'Attempt to set non-existent key' => sub {
        my $app_config = _new_app_config();
        throws_ok {
            $app_config->set({NON_EXT_KEY() => ADMINS_SET});
        }
        qr/Cannot set with key/;
    };

    subtest 'Attempt to get non-existent key' => sub {
        my $app_config = _new_app_config();
        throws_ok {
            $app_config->get(NON_EXT_KEY);
        }
        qr/Cannot get with key/;
    };
};

subtest 'History chronicling' => sub {
    my $app_config = _new_app_config();
    my $module     = Test::MockModule->new('Data::Chronicle::Reader');

    subtest 'Add history of values' => sub {
        set_fixed_time(++$tick);
        ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set 1st value succeeds';
        set_fixed_time(++$tick);
        ok $app_config->set({EMAIL_KEY() => SECOND_EMAIL}), 'Set 2nd value succeeds';
        set_fixed_time(++$tick);
        ok $app_config->set({EMAIL_KEY() => THIRD_EMAIL}), 'Set 3rd value succeeds';
        set_fixed_time(++$tick);
    };

    subtest 'Get history' => sub {
        is($app_config->get_history(EMAIL_KEY, 0, 1), THIRD_EMAIL,  'History retrieved successfully');
        is($app_config->get_history(EMAIL_KEY, 1, 1), SECOND_EMAIL, 'History retrieved successfully');
        is($app_config->get_history(EMAIL_KEY, 2, 1), FIRST_EMAIL,  'History retrieved successfully');
    };

    subtest 'Ensure get_history is cached (i.e. get_history should not be called)' => sub {
        $module->mock('get_history', sub { ok(0, 'get_history should not be called here') });
        is($app_config->get_history(EMAIL_KEY, 0), THIRD_EMAIL,  'Email retrieved via cache');
        is($app_config->get_history(EMAIL_KEY, 1), SECOND_EMAIL, 'Email retrieved via cache');
        is($app_config->get_history(EMAIL_KEY, 2), FIRST_EMAIL,  'Email retrieved via cache');
        $module->unmock('get_history');
    };

    subtest 'Ensure cache goes stale when new is set' => sub {
        is($app_config->get_history(EMAIL_KEY, 1, 1), SECOND_EMAIL, 'Previous email is correct');
        ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set email succeeds';
        is($app_config->get_history(EMAIL_KEY, 1), THIRD_EMAIL, 'Correct previous email is returned');
    };

    subtest 'Check caching can be disabled' => sub {
        my $get_history_called;

        $app_config = _new_app_config();
        $module->mock('get_history', sub { $get_history_called++; return {data => SECOND_EMAIL} });
        is($app_config->get_history(EMAIL_KEY, 2), SECOND_EMAIL, 'Email retrieved via chronicle');
        is($app_config->get_history(EMAIL_KEY, 2), SECOND_EMAIL, 'Email retrieved via chronicle again');
        $module->unmock('get_history');

        is $get_history_called, 2, 'get_history was called twice';
    };

    subtest 'Rev too old' => sub {
        is($app_config->get_history(EMAIL_KEY, 50), undef, 'Rev older than oldest returns undef');
    };

    subtest 'History of static key' => sub {
        throws_ok {
            $app_config->get_history(ADMINS_KEY, 1);
        }
        qr/Cannot get history/;
    };
};

subtest 'Perl level caching' => sub {
    subtest "Chronicle shouldn't be engaged with perl caching enabled" => sub {
        my $app_config = _new_app_config(local_caching => 1);

        ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set email to chron';

        my $reader_module = Test::MockModule->new('Data::Chronicle::Reader');
        $reader_module->mock('get',  sub { ok(0, 'get should not be called here') });
        $reader_module->mock('mget', sub { ok(0, 'mget should not be called here') });

        is $app_config->get(EMAIL_KEY), FIRST_EMAIL, 'Email is retrieved without chron access';

        $reader_module->unmock('get');
        $reader_module->unmock('mget');
    };

    subtest 'Chronicle should be engaged with perl caching disabled' => sub {
        my $chronicle_gets;
        my $app_config = _new_app_config(local_caching => 0);

        my $reader_module = Test::MockModule->new('Data::Chronicle::Reader');
        $reader_module->mock('get',  sub { $chronicle_gets++; return {data => FIRST_EMAIL} });
        $reader_module->mock('mget', sub { $chronicle_gets++; return {data => FIRST_EMAIL} });

        ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set email with write to chron';
        is $app_config->get(EMAIL_KEY), FIRST_EMAIL, 'Email is retrieved with chron access';

        ok $chronicle_gets, 'get engages chronicle';

        $reader_module->unmock('get');
        $reader_module->unmock('mget');
    };
};

subtest 'Global revision updates' => sub {
    my $app_config = _new_app_config();
    my $old_rev    = $app_config->global_revision();

    set_fixed_time(++$tick);
    ok $app_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set 1 value succeeds';

    my $new_rev = $app_config->global_revision();
    ok $new_rev > $old_rev, 'Revision was increased';
};

subtest 'Cache syncing' => sub {
    my $cached_config1 = _new_app_config(
        local_caching    => 1,
        refresh_interval => 0
    );
    my $cached_config2 = _new_app_config(
        local_caching    => 1,
        refresh_interval => 0
    );
    my $direct_config = _new_app_config(local_caching => 0);

    ok $direct_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set email succeeds';
    is $direct_config->get(EMAIL_KEY),  FIRST_EMAIL,   'Email is retrieved successfully';
    is $cached_config1->get(EMAIL_KEY), DEFAULT_EMAIL, 'Cache1 contains default before first update call';
    is $cached_config2->get(EMAIL_KEY), DEFAULT_EMAIL, 'Cache2 contains default before first update call';

    ok $cached_config1->update_cache(), 'Cache 1 is updated';
    ok $cached_config2->update_cache(), 'Cache 2 is updated';
    is $cached_config1->get(EMAIL_KEY), FIRST_EMAIL, 'Cache1 is updated with email';
    is $cached_config2->get(EMAIL_KEY), FIRST_EMAIL, 'Cache2 is updated with email';

    set_fixed_time(++$tick);    #Ensure new value is recorded at a different time
    ok $cached_config1->set({EMAIL_KEY() => SECOND_EMAIL}), 'Set email via cache 1 succeeds';
    is $direct_config->get(EMAIL_KEY),  SECOND_EMAIL, 'Email is retrieved directly';
    is $cached_config1->get(EMAIL_KEY), SECOND_EMAIL, 'Cache1 has updated email';
    is $cached_config2->get(EMAIL_KEY), FIRST_EMAIL,  'Cache2 still has old email';

    ok $cached_config2->update_cache(), 'Cache 2 is updated';
    is $cached_config2->get(EMAIL_KEY), SECOND_EMAIL, 'Cache2 has updated email';
};

subtest 'Cache refresh_interval' => sub {
    my $cached_config = _new_app_config(
        local_caching    => 1,
        refresh_interval => 2
    );
    my $direct_config = _new_app_config(local_caching => 0);

    set_fixed_time(++$tick);    #Ensure new value is recorded at a different time
    ok $direct_config->set({EMAIL_KEY() => FIRST_EMAIL}), 'Set email succeeds';
    is $direct_config->get(EMAIL_KEY), FIRST_EMAIL, 'Email is retrieved successfully';
    ok $cached_config->update_cache(), 'Cache is updated';
    is $cached_config->get(EMAIL_KEY), FIRST_EMAIL, 'Email is retrieved successfully';

    set_fixed_time(++$tick);    #Ensure new value is recorded at a different time
    ok $direct_config->set({EMAIL_KEY() => SECOND_EMAIL}), 'Set email succeeds';
    is $direct_config->get(EMAIL_KEY), SECOND_EMAIL, 'Email is retrieved successfully';
    ok !$cached_config->update_cache(), 'update not done due to refresh_interval';
    is $cached_config->get(EMAIL_KEY), FIRST_EMAIL, "Cache still has old value since interval hasn't passed";

    set_fixed_time($tick + $cached_config->refresh_interval);
    ok $cached_config->update_cache(), 'Cache is updated';
    is $cached_config->get(EMAIL_KEY), SECOND_EMAIL, 'Email is retrieved successfully from updated cache';
};

sub _new_app_config {
    my $app_config;
    my %options = @_;

    subtest 'Setup' => sub {
        my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
        lives_ok {
            $app_config = App::Config::Chronicle->new(
                definition_yml   => "$Bin/test.yml",
                chronicle_reader => $chronicle_r,
                chronicle_writer => $chronicle_w,
                %options
            );
        }
        'We are living';
    };
    return $app_config;
}

done_testing;
