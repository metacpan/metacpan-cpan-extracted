package DBIx::ThinSQL::Driver;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub savepoint {
}

sub release {
}

sub rollback_to {
}

1;
