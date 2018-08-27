use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::BorgRestore
    App::BorgRestore::Borg
    App::BorgRestore::DB
    App::BorgRestore::Helper
    App::BorgRestore::Settings
);

done_testing;

