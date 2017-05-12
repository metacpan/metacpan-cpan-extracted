package DDLock::Server::Client::DBI;

# Using DBI based ddlock is blocking. Probably shouldn't use this unless you need to.

use strict;
use warnings;

# CREATE TABLE

use base 'DDLock::Server::Client';
use fields qw(dbh);

my $hostname;
my $table;
my $dbh;

sub _setup {
    my DDLock::Server::Client::DBI $self = shift;
    ($hostname, $table) = @_;
    eval "use DBI; 1" or die "No DBI available?";
    $dbh = DBI->connect( 'dbi:mysql:dbname=sixalock', '', '', {AutoCommit => 0} ) or die;
}

sub _trylock {
    my DDLock::Server::Client::DBI $self = shift;
    my $lock = shift;

    my $local_locks = $self->{locks};
    exists( $local_locks->{$lock} ) and return $self->err_line( "local taken" );

    $dbh->do( 'START TRANSACTION' ) or return $self->err_line( "Transaction failed to start" );

    my $sth = $dbh->prepare( "SELECT * FROM $table WHERE name=?" );
    $sth->execute( $lock )
        or return $self->err_line( "STH->execute failed" );
    my $ary = $sth->fetchall_arrayref;
    ref($ary) eq 'ARRAY'
        or return $self->err_line( "DBI->selectall_arrayref returned non-arrayref" );
    scalar @$ary == 0
        or return $self->err_line( "remote taken" );

    $dbh->do( "INSERT INTO $table (name) VALUES (?)", {}, $lock )
        or return $self->err_line( "INSERT failed" );
    $dbh->do( 'COMMIT' )
        or return $self->err_line( "COMMIT failed" );
    return $self->ok_line();
}

sub _release_lock {
    my DDLock::Server::Client::DBI $self = shift;
    my $lock = shift;

    my $locks = $self->{locks};
    if (exists( $locks->{$lock} )) {
        delete $locks->{$lock};
        $dbh->do( "SELECT AND DELETE * FROM $table WHERE name=?", {}, $lock );
        return 1;
    }
    else {
        return 0;
    }
}

sub _get_locks {
    my DDLock::Server::Client::DBI $self = shift;

    my $ary = $dbh->selectall_arrayref( "SELECT name FROM $table" );
    return map { $_->[0] } @$ary;
}

1;
