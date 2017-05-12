use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

use AWS::CLI::Config;

my ($fh, $file) = tempfile(UNLINK => 1);
my $default_access_key_id = 'Me';
my $default_secret_access_key = '__secret__';
my $tester_access_key_id = "Tester$default_access_key_id";
my $tester_secret_access_key = "__tester$default_secret_access_key";
print $fh <<"EOS";
[default]
aws_access_key_id = $default_access_key_id
aws_secret_access_key = $default_secret_access_key
[profile tester]
aws_access_key_id = $tester_access_key_id
aws_secret_access_key = $tester_secret_access_key
EOS

close $fh;

local $ENV{AWS_CONFIG_FILE} = $file;

subtest 'Default profile' => sub {
    my $config = AWS::CLI::Config::config;
    is($config->aws_access_key_id, $default_access_key_id, 'access_key_id');
    is($config->aws_secret_access_key, $default_secret_access_key, 'secret_access_key');
};

subtest 'Specific profile' => sub {
    my $config = AWS::CLI::Config::config('tester');
    is($config->aws_access_key_id, $tester_access_key_id, 'access_key_id');
    is($config->aws_secret_access_key, $tester_secret_access_key, 'secret_access_key');
};

subtest 'Undefined profile' => sub {
    my $config = AWS::CLI::Config::config('no-such-profile');
    ok(!$config, 'undefined');
};

done_testing;

__END__
# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
