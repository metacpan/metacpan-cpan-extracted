use strict;
use warnings;
use Test::More;

use AWS::CLI::Config;

subtest 'Environment Variable' => sub {
    local $ENV{AWS_ACCESS_KEY_ID} = '__dummy__';
    is(AWS::CLI::Config::access_key_id, $ENV{AWS_ACCESS_KEY_ID}, 'set by env');
};

subtest 'From credentials file' => sub {
    my $access_key_id = q[It's me.];
    undef local $ENV{AWS_ACCESS_KEY_ID};
    no strict 'refs';
    no warnings 'redefine';
    *AWS::CLI::Config::credentials = sub {
        return AWS::CLI::Config::Profile->new({
                aws_access_key_id => $access_key_id,
            });
    };
    is(AWS::CLI::Config::access_key_id, $access_key_id, 'set by credentials');
};

subtest 'From config file' => sub {
    my $access_key_id = q[It's me.];
    undef local $ENV{AWS_ACCESS_KEY_ID};
    no strict 'refs';
    no warnings 'redefine';
    *AWS::CLI::Config::credentials = sub {
        return undef;
    };
    *AWS::CLI::Config::config = sub {
        return AWS::CLI::Config::Profile->new({
                aws_access_key_id => $access_key_id,
            });
    };
    is(AWS::CLI::Config::access_key_id, $access_key_id, 'set by config');
};

done_testing;

__END__
# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
