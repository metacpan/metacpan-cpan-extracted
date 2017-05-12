use Test::More;
use strict;

use Test::Exception;
use Config::Path;

lives_ok(sub { Config::Path->new(
        files => [ 't/conf/simple.yml', 't/conf/other.yml' ],
)}, 'instantiates fine w/files');

lives_ok(sub { Config::Path->new(
        directory => 't/conf',
)}, 'instantiates fine w/directory');

dies_ok(sub { Config::Path->new(
        files => [ 't/conf/simple.yml', 't/conf/other.yml' ],
        directory => 't/conf'
    ) }, 'failure to instantiate with both files and directory'
);

dies_ok(sub { Config::Path->new(
    ) }, 'failure to instantiate with neither files or directory'
);

done_testing;