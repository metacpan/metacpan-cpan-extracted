use Test2::V0;
use Test2::Tools::Spec;

use Config::AWS;
use Path::Tiny qw( path );

describe 'Config::AWS environment tests' => sub {
    local $ENV{HOME}    = 'tester';
    local $ENV{HOMEDIR} = 'tester';

    tests 'default_profile' => sub {
        local $ENV{AWS_DEFAULT_PROFILE} = 'some-profile';
        is Config::AWS::default_profile(), 'some-profile';

        delete $ENV{AWS_DEFAULT_PROFILE};
        is Config::AWS::default_profile(), 'default';
    };

    tests 'credentials_file' => sub {
        local $ENV{AWS_SHARED_CREDENTIALS_FILE} = 'some-credentials';
        is Config::AWS::credentials_file(), 'some-credentials';

        delete $ENV{AWS_SHARED_CREDENTIALS_FILE};
        is path( Config::AWS::credentials_file )
            ->relative('~/.aws/credentials')->stringify, '.';

        unlike Config::AWS::credentials_file, qr/^~/, 'tilde is expanded';
    };

    tests 'config_file' => sub {
        local $ENV{AWS_CONFIG_FILE} = 'some-config';
        is Config::AWS::config_file(), 'some-config';

        delete $ENV{AWS_CONFIG_FILE};
        is path( Config::AWS::config_file )
            ->relative('~/.aws/config')->stringify, '.';

        unlike Config::AWS::config_file, qr/^~/, 'tilde is expanded';
    };
};

done_testing;
