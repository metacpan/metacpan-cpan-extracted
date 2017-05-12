package DBIx::Connection::PostgreSQL::SQL;

use strict;
use warnings;
use vars qw($VERSION $LOB_MAX_SIZE);

use Abstract::Meta::Class ':all';
use Carp 'confess';

$VERSION = 0.03;
$LOB_MAX_SIZE = (1024 * 1024 * 1024);

=head1 NAME

DBIx::Connection::PostgreSQL::SQL - PostgreSQL catalog sql abstractaction layer.

=cut  

=head1 SYNOPSIS
    
    use DBIx::Connection::PostgreSQL::SQL;

=head1 DESCRIPTION

    Represents sql abstractaction layer

=head1 EXPORT

None

=head2 METHODS

=over

=item sequence_value

Returns sql statement that returns next sequence value

=cut

sub sequence_value {
    my ($class, $sequence_name) = @_;
    "SELECT nextval('${sequence_name}') AS val"
}


=item reset_sequence

Returns sql statement that restarts sequence.

=cut

sub reset_sequence {
    my ($class, $sequence_name, $restart_with, $increment_by) = @_;
    ("ALTER SEQUENCE ${sequence_name} RESTART WITH ${restart_with}",
     ($increment_by ? "ALTER SEQUENCE ${sequence_name} INCREMENT  ${increment_by}" : ()));
}


=item has_sequence

Returns sql statement that check is sequence exists in database schema

=cut

sub has_sequence {
    my ($class, $schema) = @_;
    "SELECT pc.relname AS sequence_name
    FROM pg_class pc 
    JOIN pg_authid pa ON pa.oid = pc.relowner AND pc.relkind = 'S' AND  pc.relname = lower(?)  AND rolname = '". $schema ."' ";
}


=item set_session_variables

Sets session variables

It uses the following sql command pattern:

    SET variable TO value;

    DBIx::Connection::PostgreSQL::SQL->set_session_variables($connection, {DateStyle => 'US'});

=cut

sub set_session_variables {
    my ($class, $connection, $db_session_variables) = @_;
    my $sql = "";
    $sql .= "SET " . $_ . " TO " . $db_session_variables->{$_} . ";"
      for keys %$db_session_variables;
    $connection->do($sql);
}


=item update_lob

Updates lob. (Large Object)
Takes connection object, table name, lob column_name, lob conetent, hash_ref to primary key values. optionally lob size column name.

=cut

sub update_lob {
    my ($class, $connection, $table_name, $lob_column_name, $lob, $primary_key_values, $lob_size_column_name) = @_;
    confess "missing primary key for lob update on ${table_name}.${lob_column_name}"
        if (!$primary_key_values  || ! (%$primary_key_values));
    confess "missing lob size column name" unless $lob_size_column_name;
    my $sql = "UPDATE ${table_name} SET ${lob_column_name} = ? ";
    $sql .= ($lob_size_column_name ? ", ${lob_size_column_name} = ? " : '')
      . $connection->_where_clause($primary_key_values);
    
    $class->_unlink_lob($connection, $class->_get_lob_id($connection, $table_name, $primary_key_values, $lob_column_name));
    my $lob_id = $class->_create_lob($connection, $lob);
    my $bind_counter = 1;
    my $sth = $connection->dbh->prepare($sql);
    $sth->bind_param($bind_counter++ ,$lob_id);
    $sth->bind_param($bind_counter++ , length($lob)) if $lob_size_column_name;
    for my $k (sort keys %$primary_key_values) {
        $sth->bind_param($bind_counter++ , $primary_key_values->{$k});
    }
    $sth->execute();
}



=item fetch_lob

Retrieve lobs.
Takes connection object, table name, lob column_name, hash_ref to primary key values. optionally lob size column name.
By default max lob size is set to 1 GB
DBIx::Connection::Oracle::SQL::LOB_MAX_SIZE = (1024 * 1024 * 1024);

=cut

sub fetch_lob {
    my ($class, $connection, $table_name, $lob_column_name, $primary_key_values, $lob_size_column_name) = @_;
    confess "missing primary key for lob update on ${table_name}.${lob_column_name}"
        if (! $primary_key_values  || ! (%$primary_key_values));
    confess "missing lob size column name" unless $lob_size_column_name;
    my $lob_id = $class->_get_lob_id($connection, $table_name, $primary_key_values, $lob_column_name);
    my $lob_size = $class->_get_lob_size($connection, $table_name, $primary_key_values, $lob_size_column_name);
    $class->_read_lob($connection, $lob_id, $lob_size);
}



=item _create_lob

Creates lob

=cut

sub _create_lob {
    my ($class, $connection, $lob) = @_;
    my $dbh = $connection->dbh;
    my $autocomit_mode = $connection->has_autocomit_mode;
    $connection->begin_work if $autocomit_mode;
    my $mode = $dbh->{pg_INV_WRITE};
    my $lob_id = $dbh->func($mode, 'lo_creat')
        or confess "can't create lob ". $!;
    my $lobj_fd = $dbh->func($lob_id, $mode, 'lo_open');
    confess "can't open lob ${lob_id}". $!
        unless defined $lobj_fd;
    my $length = length($lob || '');
    my $offset = 0;
    while($length > 0) {
        $dbh->func($lobj_fd, $offset, 0, 'lo_lseek');
        my $nbytes = $dbh->func($lobj_fd, substr($lob, $offset, $length), $length, 'lo_write')
            or confess "can't write lob " . $!;
        $offset += $nbytes;
        $length -=  $nbytes;
    }
    $dbh->func($lobj_fd, 'lo_close');
    $connection->commit if ($autocomit_mode);
    $lob_id;
}
    


=item _read_lob

Reads lob

=cut

sub _read_lob {
    my ($class, $connection, $lob_id, $length) = @_;
    my $dbh = $connection->dbh;
    my $autocomit_mode = $connection->has_autocomit_mode;
    $connection->begin_work if $autocomit_mode;
    my $mode = $dbh->{pg_INV_READ};
    my $lobj_fd = $dbh->func($lob_id, $mode, 'lo_open');
    confess "can't open lob ${lob_id}". $!
        unless defined $lobj_fd;
    my $result = '';
    my $buff = '';
    my $offset = 0;
    while(1) {
        $dbh->func($lobj_fd, $offset, 0, 'lo_lseek');
        my $nbytes = $dbh->func($lobj_fd, $buff, $length, 'lo_read');
        confess "can't read lob ${lob_id}" . $!
            unless defined $nbytes;
        $result .= $buff;
        $offset += $nbytes;
        last if ($offset == $length);
    }
    $dbh->func($lobj_fd, 'lo_close');
    $connection->commit if ($autocomit_mode);
    $result
}
    

=item _unlnik_lob

Removes lob.

=cut

sub _unlink_lob {
    my ($class, $connection, $lob_id) = @_;
    return unless  $lob_id;
    my $dbh = $connection->dbh;
    my $autocomit_mode = $connection->has_autocomit_mode;
    $connection->begin_work if $autocomit_mode;
    $dbh->func($lob_id, 'lo_unlink')
        or confess "can't unlink lob ${lob_id}". $!;
    $connection->commit if ($autocomit_mode);
}


=item _get_lob_size

Returns lob size.

=cut

sub _get_lob_size {
    my ($class, $connection, $table_name, $primary_key_values, $lob_size_column_name) = @_;
    my $resut;
    if($lob_size_column_name) {
        my $sql = "SELECT ${lob_size_column_name} as lob_size FROM ${table_name} " . $connection->_where_clause($primary_key_values);
        my ($record) = $connection->record($sql, map { $primary_key_values->{$_}} sort keys %$primary_key_values);
        $resut = $record->{lob_size};
    }
    $resut || $LOB_MAX_SIZE;
}


=item _get_lob_id

Returns lob oid.

=cut

sub _get_lob_id {
    my ($class, $connection, $table_name, $primary_key_values, $lob_column_name) = @_;
    my $resut;
    my $sql = "SELECT ${lob_column_name} as lob_id FROM ${table_name} " . $connection->_where_clause($primary_key_values);
    my ($record) = $connection->record($sql, map { $primary_key_values->{$_}} sort keys %$primary_key_values);
    $resut = $record->{lob_id};
}

1;    

__END__

=back

=head1 SEE ALSO

L<DBIx::Connection>

=head1 COPYRIGHT AND LICENSE

The DBIx::Connection::PostgreSQL::SQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

