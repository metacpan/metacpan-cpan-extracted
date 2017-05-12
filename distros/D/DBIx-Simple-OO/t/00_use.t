use Test::More 'no_plan';
use strict;

BEGIN {
    chdir 't' if -d 't';

    use File::Spec;
    use lib File::Spec->catdir(qw[.. lib]), 'inc';

    require 'conf.pl';
}

my $Class = 'DBIx::Simple::OO';

use_ok( $Class );

diag "Testing $Class " . $Class->VERSION;
