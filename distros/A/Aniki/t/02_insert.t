use strict;
use warnings;
use utf8;

use Test::More;

use File::Spec;
use lib File::Spec->catfile('t', 'lib');
use t::Util;

run_on_database {
    db->insert(author => { name => 'MOZNION' });
    is db->select(author => {}, { limit => 1 })->count, 1, 'created.';
};

done_testing();
