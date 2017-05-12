package DBD::Mock::Pool;

use strict;
use warnings;

my $connection;

sub connect {
    return $connection if $connection;

    # according to the code before my tweaks, this could be a class
    # name, but it was never used - DR, 2008-11-08
    shift unless ref $_[0];

    my $drh = shift;
    return $connection = bless $drh->connect(@_), 'DBD::Mock::Pool::db';
}

1;
