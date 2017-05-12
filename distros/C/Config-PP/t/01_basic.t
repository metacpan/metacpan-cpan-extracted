use strict;
use Test::More;
use Config::PP;
use File::Spec;

local $Config::PP::DIR = File::Spec->tmpdir;

config_set "config.pp.test.basic", {
    'config.pp.test.basic' => 'ok',
};

is_deeply config_get("config.pp.test.basic"), {
    'config.pp.test.basic' => 'ok',
};

done_testing;
