use strict;
use warnings;
use Test::More;

use AWS::CLI::Config;

subtest 'Windows' => sub {
    local $^O = 'MSWin32';
    local $ENV{USERPROFILE} = 'C:\Users\foo';
    is(AWS::CLI::Config::_base_dir, $ENV{USERPROFILE}, 'same as USERPROFILE');
};

subtest 'Other OS' => sub {
    local $^O = 'Other';
    local $ENV{HOME} = '/home/foo';
    is(AWS::CLI::Config::_base_dir, $ENV{HOME}, 'same as HOME');
};

done_testing;

__END__
# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
