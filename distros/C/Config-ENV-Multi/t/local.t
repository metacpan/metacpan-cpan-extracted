{
    package MyConfig;
    use strict;
    use warnings;
    use Config::ENV::Multi [qw/ENV REGION/];

    common {
        name => 'foobar',
        cnf => '/etc/my.cnf',
    };

    config [qw/prod jp/] => {
        db_host => 'jp.local',
    };

    config [qw/prod us/] => {
        db_host => 'us.local',
    };

    config [qw/dev */] => {
        db_host => 'localhost',
    };

    config [qw/! !/] => {
        db_host => 'localhost',
    };
};


BEGIN { MyConfig->import };
sub config { 'MyConfig' }

use Test::More;

{
    my $guard = config->local(db_host => 'test.local');
    is config->param('db_host'), 'test.local';
};

is config->param('name'), 'foobar';

{
    my $guard1 = config->local(name => 'localized1');
    is config->param('name'), 'localized1';

    my $guard2 = config->local(name => 'localized2');
    is config->param('name'), 'localized2';

    undef $guard2;

    is config->param('name'), 'localized1';

    {
        my $guard3 = config->local(name => 'localized3');
        is config->param('name'), 'localized3';
    };

    is config->param('name'), 'localized1';
};

{
    is @{ config->_data->{local} }, 0 if $ENV{AUTHOR_TESTING};

    my $guard1 = config->local(name => 'localized1');
    is config->param('name'), 'localized1';
    is @{ config->_data->{local} }, 1 if $ENV{AUTHOR_TESTING};

    my $guard2 = config->local(name => 'localized2');
    is config->param('name'), 'localized2';
    is @{ config->_data->{local} }, 2 if $ENV{AUTHOR_TESTING};

    my $guard3 = config->local(name => 'localized3');
    is config->param('name'), 'localized3';
    is @{ config->_data->{local} }, 3 if $ENV{AUTHOR_TESTING};

    undef $guard2;
    is config->param('name'), 'localized3';
    is @{ config->_data->{local} }, 2 if $ENV{AUTHOR_TESTING};

    undef $guard3;
    is config->param('name'), 'localized1';
    is @{ config->_data->{local} }, 1 if $ENV{AUTHOR_TESTING};

    undef $guard1;
    is config->param('name'), 'foobar';
    is @{ config->_data->{local} }, 0 if $ENV{AUTHOR_TESTING};
};

eval { config->local(name => 'localized') };
like $@, qr/local returns guard object; Can't use in void context/;

done_testing;
