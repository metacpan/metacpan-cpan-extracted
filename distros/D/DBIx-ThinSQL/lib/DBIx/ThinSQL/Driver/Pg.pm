package DBIx::ThinSQL::Driver::Pg;

use strict;
use warnings;

use base qw(DBIx::ThinSQL::Driver);

sub savepoint {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->pg_savepoint($name);
}

sub release {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->pg_release($name);
}

sub rollback_to {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->pg_rollback_to($name);
}

1;

