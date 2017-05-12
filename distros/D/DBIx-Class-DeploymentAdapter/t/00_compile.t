use strict;
use Test::More 0.98;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

use_ok $_ for qw(
    DBIx::Class::DeploymentAdapter
);

done_testing;

