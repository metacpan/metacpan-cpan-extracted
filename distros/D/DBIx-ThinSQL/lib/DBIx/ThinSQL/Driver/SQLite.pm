package DBIx::ThinSQL::Driver::SQLite;

use strict;
use warnings;

our @ISA = ('DBIx::ThinSQL::Driver');

sub savepoint {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->do( 'SAVEPOINT ' . $name );
}

sub release {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->do( 'RELEASE ' . $name );
}

sub rollback_to {
    my $self = shift;
    my $dbh  = shift;
    my $name = shift;
    $dbh->do( 'ROLLBACK TO ' . $name );
}

1;
