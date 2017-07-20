use strict;
use warnings;

use Test::More;
use Config::GitLike;
use File::Spec;

for my $platform (qw(unix dos mac)) {
    my $config_filename = File::Spec->catfile('t', "$platform.conf");
    ok my $data = Config::GitLike->load_file($config_filename),
        "Load $platform config";
    is_deeply $data, {
        'core.engine' => 'pg',
        'core.topdir' => 'sql',
        'deploy.verify' => 'true',
    }, "Should have proper config for $platform file";
}

done_testing;
