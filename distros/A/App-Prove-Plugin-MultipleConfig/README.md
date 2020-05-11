# NAME

App::Prove::Plugin::MultipleConfig - set multiple configs for parallel prove tests

# SYNOPSIS

    prove -j3 -PMySQLPool t::Prepare,./config/config1.pl,./config/config2.pl,./config/config3.pl

# DESCRIPTION

App::Prove::Plugin::MultipleConfig is [prove](https://metacpan.org/pod/prove) plugin for setting multiple configs for parallel test.

This plugin enables you to change each environment for each test.
For example, if you want to use some databases and redis when testing, each test can use a different database and redis.

First, you make config files, the number of files is -j(the number of jobs).
Each test reads this config file like `do $config_path;`.

    # ./config/config1.pl
    my $config = +{
        'DB' => {
            uri => 'DBI:mysql:database=test_db;hostname=127.0.0.1;port=10002',
            username => 'root',
            password => 'root',
        },
        'REDIS' => +{
            server => '127.0.0.1:20003',
        },
    };

    $config;

Next, you make a module for initializing tests. This method is called **once every config** before starting tests.
This module must have a `prepare` method whose second argument is a config path.

    # t/Prepare.pm
    sub prepare {
        my ($self, $config) = @_;
        my $conf = do $config;

        my $uri = $conf->{DB}->{uri};
        $uri =~ s/database=.+?;/database=mysql;/; # use mysql table
        my $dbh = DBI->connect($uri, $conf->{DB}->{username}, $conf->{DB}->{password},
            {'RaiseError' => 1}
        );
        ....
    }

In the end, you pass arguments to prove for specifying prepare module and config files paths.
This format is comma-separated value(CSV). First value is prepared module name. Subsequent values are config files path.

    prove -j3 -PMySQLPool t::Prepare,./config/config1.pl,./config/config2.pl,./config/config3.pl

Congratulations! In each test, you can read `ENV{PERL_MULTIPLE_CONFIG}` which returns a config path.

    # your test code
    my $config_path = $ENV{PERL_MULTIPLE_CONFIG};
    my $conf = do $config_path;

# LICENSE

Copyright (C) takahito.yamada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

takahito.yamada

# SEE ALSO

[prove](https://metacpan.org/pod/prove), [App::Prove::Plugin::MySQLPool](https://metacpan.org/pod/App%3A%3AProve%3A%3APlugin%3A%3AMySQLPool)
