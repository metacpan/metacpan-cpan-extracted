#!perl -w

use strict;
use warnings;

# Base DBD Driver Test
use Test::More tests => 6;

require_ok('DBI');

eval {
    import DBI;
};

is $@ => '', 'successfully import DBI';

is ref DBI->internal => 'DBI::dr', 'internal';

my $drh = eval {
    # This is a special case. install_driver should not normally be used.
    DBI->install_driver('Oracle');
};

is $@ => '', 'install_driver' 
    or diag "Failed to load Oracle extension and/or shared libraries";

SKIP: {
    skip 'install_driver failed - skipping remaining', 2 if $@;

    is ref $drh => 'DBI::dr', 'install_driver';

    ok $drh->{Version}, 'version';
}
