package Dwarf::Session::Store::DBI;
use Dwarf::Pragma;
use DBI;
use MIME::Base64;
use Storable qw/nfreeze thaw/;

use Dwarf::Accessor qw/
    dbh expires sid_table sid_col data_col expires_col clean_thres
/;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->{expires}     //= 3600;
    $self->{sid_table}   //= 'session';
    $self->{sid_col}     //= 'sid';
    $self->{data_col}    //= 'data';
    $self->{expires_col} //= 'expires';
    $self->{clean_thres} //= 0.001;
    return $self;
}

sub select {
    my ( $self, $session_id ) = @_;
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql = qq~SELECT $data_col, $expires_col FROM $sid_table WHERE $sid_col = ?~;
    my $sth = $dbh->prepare( $sql ); 
    $sth->execute( $session_id );
    my ($data, $expires) = $sth->fetchrow_array;
    
    return unless ($data);
    return unless ( $expires > time() );
    
    return thaw( decode_base64($data) );
}

sub insert {
    my ($self, $session_id, $data) = @_;
    
    $data = encode_base64( nfreeze($data) );
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~INSERT INTO $sid_table ($sid_col, $data_col, $expires_col) VALUES (?, ?, ?)~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $session_id, $data, time() + $self->expires );
}

sub update {
    my ($self, $session_id, $data) = @_;
    
    $data = encode_base64( nfreeze($data) );
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~UPDATE $sid_table SET $data_col = ?, $expires_col = ? WHERE $sid_col = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $data, time() + $self->expires, $session_id );
}

sub delete {
    my ($self, $session_id) = @_;
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~DELETE FROM $sid_table WHERE $sid_col = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $session_id );
    
    if ( rand() < $self->clean_thres ) {
        my $time_now = time();
        $dbh->do(qq~DELETE FROM $sid_table WHERE expires < $time_now~);
    }
}

sub cleanup {
    my ($self) = @_;
    if (rand() < $self->clean_thres) {
        my $sid_table = $self->sid_table;
        my $time_now = time();
        $self->dbh->do(qq~DELETE FROM $sid_table WHERE expires < $time_now~);
    }
}

1;
__END__

