package  Data::RecordStore::SQL;

use strict;
use warnings;

use DBI;
use Data::Dumper qw(Dumper);

use vars qw($VERSION);
$VERSION = '0.1';

sub open_store {
    my( $cls, @options ) = @_;
    my( %options ) = @options;
    my( $table, $dbi, $user, $password ) = @options{'TABLE','DBI','USER','PASSWORD'};
    $table //= 'Objects';
    #"dbi:mysql:RecordStore",'wolf','boogers');

    my $dbh = DBI->connect( $dbi, $user, $password );

    $dbh->do( "CREATE TABLE IF NOT EXISTS $table (ID bigint(20) primary key AUTO_INCREMENT, Updated timestamp ON UPDATE CURRENT_TIMESTAMP, value text )" );
    
    return bless {
        TABLE          => $table,
        OPTIONS        => {%options},
        DBH            => $dbh,
        
        stow_with_id   => $dbh->prepare( "INSERT INTO $table (id,value) VALUES (?,?) ON DUPLICATE KEY UPDATE value=?" ),
        stow_no_id     => $dbh->prepare( "INSERT INTO $table (value) VALUES(?)" ),
        fetch          => $dbh->prepare( "SELECT value FROM $table WHERE ID=?" ),
        lock_read_obj_table => $dbh->prepare( "LOCK TABLES $table READ" ),
        lock_obj_table => $dbh->prepare( "LOCK TABLES $table WRITE" ),
        unlock_tables  => $dbh->prepare( "UNLOCK TABLES" ),
        record_count   => $dbh->prepare( "SELECT COUNT(*) FROM $table WHERE value IS NOT NULL" ),
        entry_count    => $dbh->prepare( "SELECT MAX(ID) FROM $table" ),
        has_id         => $dbh->prepare( "SELECT count(*) FROM $table WHERE ID=? AND value IS NOT NULL" ),
        last_id        => $dbh->prepare( "SELECT LAST_INSERT_ID()" ),
        delete_id      => $dbh->prepare( "DELETE FROM $table WHERE ID=?" ),
        
        LOCKS          => [],
    }, $cls;
} #open_store

sub _execute {
    my( $self, $qry, @args ) = @_;
    my $sth = $self->{$qry};
#    print STDERR Data::Dumper->Dump([$qry,\@args]);
    $sth->execute( @args );
    my $err = $sth->errstr;
    print STDERR "$err \n" if $err;
    my( @ret ) =  $sth->fetchrow_array;
    $err = $sth->errstr;
    print STDERR "$err\n" if $err;
#    print STDERR " $qry @ret\n";
    return @ret;
}

sub _last_id {
    my( $id ) = shift->_execute( 'last_id' );
    return $id;
}

sub has_id {
    my( $has ) =  shift->_execute( 'has_id', @_ );
    return $has;
}

sub next_id {
    my $self = shift;
#    print STDERR "NEXT ID LOCK\n";
    $self->{lock_obj_table}->execute;
    $self->{stow_no_id}->execute(undef);
    my $id = $self->_last_id;
#    print STDERR "NEXT ID UNLOCK\n";
    $self->{unlock_tables}->execute;
    return $id;
}


sub delete_record {
    my( $self, $id ) = @_;
    my $sth = $self->{delete_id};
    $sth->execute( $id );
    my $err = $sth->errstr;
    print STDERR "$err\n" if $err;
    return $self->has_id( $id );
}

sub stow {
    my( $self, $item, $id ) = @_;
    if( defined( $id ) && ($id < 1 || int($id) != $id ) ) {
        die "Invalid id $id. $id must be a positive integer";
    }
    my( $sth, $r );
#    print STDERR "STOW LOCK ($$)\n";
    $self->{lock_obj_table}->execute;
    if( $id ) {
        $sth = $self->{stow_with_id};
        $r = $sth->execute( $id, $item, $item );
    } else {
        $sth = $self->{stow_no_id};
        $r = $sth->execute( $item );
        $id = $self->_last_id;
    }
#    print STDERR "STOW UNLOCK ($$)\n";
    $self->{unlock_tables}->execute;
    my $err = $sth->errstr;
    print STDERR "$err\n" if $err;
    return $id;
}

sub fetch {
    my( $self, $id ) = @_;
    if( defined( $id ) && ($id == 0 || int($id) != $id ) ) {
        die "Invalid id $id. $id must be a positive integer";
    }
    $self->{lock_read_obj_table}->execute;
    my $sth = $self->{fetch};
    $sth->execute( $id );
    my( $val ) = $sth->fetchrow_array;
    my $err = $sth->errstr;
    print STDERR "$err\n" if $err;
    $self->{unlock_tables}->execute;
    return $val;
}

sub record_count {
    my( $c ) = shift->_execute( 'record_count' );
    return $c||0;
}

sub highest_entry_id {
    my( $c ) = shift->_execute( 'entry_count' );
    return $c||0;
}

sub entry_count {
    my( $c ) = shift->_execute( 'entry_count' );
    return $c||0;
}

# locks the given lock names
sub lock {
    my( $self, @locknames ) = @_;
    if( @{$self->{LOCKS}} ) {
        die "Data::RecordStore->lock cannot be called twice in a row without unlocking between";
    }
    my $dbh = $self->{DBH};
    my %seen;
    
    for my $name (sort @locknames) {
        $name =~ s/[:-]+/_/g;
        $dbh->do( "CREATE TABLE IF NOT EXISTS lock_$name (id int)" );
        $seen{$name} = 1;
    }
    my @locks = sort keys %seen;
    @{$self->{LOCKS}} = @locks;
    $dbh->do( "LOCK TABLES ".join(",", map { "lock_$_ WRITE" } @locks ) );
} #lock

# unlocks all locks
sub unlock {
    my $self = shift;
    $self->{unlock_tables}->execute;
    @{$self->{LOCKS}} = ();
} #unlock

sub empty {
    my $self = shift;
    my $table = $self->{TABLE};
    my $dbh = $self->{DBH};

    my $sth = $dbh->prepare( "TRUNCATE $table" );
    my $err = $sth->errstr;
    print STDERR "$err\n" if $err;
    $sth->execute;
    $err = $sth->errstr;
    print STDERR "$err\n" if $err;

    $sth = $dbh->prepare( "SELECT * FROM $table" );
    $sth->execute;
}

sub use_transaction {
    my $self = shift;
    if( 0 == $self->{IN_TRANSACTION}++ ) {
        $self->{DBH}->do( "START TRANSACTION" );
    }
}
sub start_transaction {
    shift->use_transaction;
}
sub commit_transaction {
    my $self = shift;
    $self->{IN_TRANSACTION} = 0;
    $self->{DBH}->do( "COMMIT" );
}
sub rollback_transaction {
    my $self = shift;
    $self->{IN_TRANSACTION} = 0;
    $self->{DBH}->do( "ROLLBACK" );
}

sub zap {
    my $self = shift;
    my $table = $self->{TABLE};
    my $dbh = $self->{DBH};
    my $sth = $dbh->prepare( "SELECT * FROM $table" );
    my $err = $sth->errstr;
    print STDERR "))$err\n" if $err;
    $sth->execute;
    $err = $sth->errstr;
    print STDERR "))$err\n" if $err;    
    my $all_t = $sth->fetchall_arrayref;
    $err = $sth->errstr;
    print STDERR "))$err\n" if $err;    
    print STDERR Data::Dumper->Dump([$all_t,"ZAP"]);

}

"GROOVY";
