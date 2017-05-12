package DBIx::Connection::Oracle::SQL;

use strict;
use warnings;
use vars qw($VERSION $LOB_MAX_SIZE);

use Abstract::Meta::Class ':all';
use Carp 'confess';

$VERSION = 0.04;
$LOB_MAX_SIZE = (1024 * 1024 * 1024);

=head1 NAME

DBIx::Connection::Oracle::SQL - Oracle catalog sql abstractaction layer.

=cut  

=head1 SYNOPSIS
    
    use DBIx::Connection::Oracle::SQL;


=head1 DESCRIPTION

    Represents sql abstract layer

=head1 EXPORT

None

=head2 METHODS

=over

=item sequence_value

Returns sql statement that returns next sequence value

=cut

sub sequence_value {
    my ($class, $sequence_name) = @_;
    "SELECT ${sequence_name}.NEXTVAL as val FROM dual"
}



=item reset_sequence

Returns sql statement that restarts sequence.

=cut

sub reset_sequence {
    my ($class, $sequence_name, $restart_with, $increment_by) = @_;
    $restart_with ||= 1;
    $increment_by ||= 1;
    ("DROP SEQUENCE ${sequence_name}", "CREATE SEQUENCE ${sequence_name} START WITH ${restart_with} INCREMENT BY ${increment_by}");
}


=item has_sequence

Returns sql statement that check is sequence exists in database schema

=cut

sub has_sequence {
    my ($class) = @_;
    "SELECT sequence_name FROM user_sequences WHERE sequence_name = UPPER(?)"
}


=item has_table

Returns sql statement that check is table exists in database schema

=cut

sub has_table {
    my ($class, $connection, $table_name) = @_;
    my $result;
    my $sql = "SELECT table_name FROM user_tables WHERE table_name = UPPER(?)";
    my $record = $connection->record($sql, $table_name);
    $result = [undef,$connection->name, $record->{table_name}, undef]
        if $record->{table_name};
    $result 
}


=item primary_key_info

=cut

sub primary_key_info {
    my ($class, $schema) = @_;
    $schema
        ? "SELECT LOWER(cl.column_name) AS column_name, cs.constraint_name AS pk_name, LOWER(cs.table_name) AS table_name FROM all_cons_columns cl
JOIN all_constraints cs
ON (cl.owner = cs. owner AND cl.constraint_name = cs. constraint_name AND  constraint_type='P'
AND cs.table_name = UPPER(?) AND cs.owner = UPPER(?))
ORDER BY position"
        : "SELECT LOWER(cl.column_name) AS column_name,  cs.constraint_name, LOWER(cs.table_name) AS table_name FROM user_cons_columns cl
JOIN user_constraints cs
ON (cl.constraint_name = cs. constraint_name AND  constraint_type='P' AND cs.table_name = UPPER(?))
ORDER BY position";
}


=item set_session_variables

Sets session variables.
It uses the following sql command pattern,

    alter session set variable  = value;

    DBIx::Connection::Oracle::Session->initialise_session($connection, {NLS_DATE_FORMAT => 'DD.MM.YYYY'});

=cut

sub set_session_variables {
    my ($class, $connection, $db_session_variables) = @_;
    my $plsql = "BEGIN\n";
    $plsql .= "execute immediate 'alter session set " . $_ . "=''" . $db_session_variables->{$_} . "''';\n" 
      for keys %$db_session_variables;
    $plsql .= "END;";
    $connection->do($plsql);
}


=item update_lob

Updates lob. (Large Object)
Takes connection object, table name, lob column_name, lob conetent, hash_ref to primary key values. optionally lob size column name.

=cut

sub update_lob {
    my ($class, $connection, $table_name, $lob_column_name, $lob, $primary_key_values, $lob_size_column_name) = @_;
    confess "missing primary key for lob update on ${table_name}.${lob_column_name}"
        if (!$primary_key_values  || ! (%$primary_key_values));

    my $sql = "UPDATE ${table_name} SET ${lob_column_name} = ? ";
    $sql .= ($lob_size_column_name ? ", ${lob_size_column_name} = ? " : '')
      . $connection->_where_clause($primary_key_values);
    my $clas = 'DBD::Oracle';
    my $ora_type = $clas->can('SQLT_BIN') ? $class->SQLT_BIN : $clas->ORA_BLOB;
    my $bind_counter = 1;
    my $sth = $connection->dbh->prepare($sql);
    $sth->bind_param($bind_counter++ ,$lob, { ora_type => $ora_type});
    $sth->bind_param($bind_counter++ , length($lob || '')) if $lob_size_column_name;
    for my $k (sort keys %$primary_key_values) {
        $sth->bind_param($bind_counter++ , $primary_key_values->{$k});
    }
    $sth->execute();
}


=item fetch_lob

Retrieves lob.
Takes connection object, table name, lob column_name, hash_ref to primary key values. optionally lob size column name.
By default max lob size is set to 1 GB
DBIx::Connection::Oracle::SQL::LOB_MAX_SIZE = (1024 * 1024 * 1024);

=cut

{
    my %long_read_cache;

    sub fetch_lob {
        my ($class, $connection, $table_name, $lob_column_name, $primary_key_values, $lob_size_column_name) = @_;
        confess "missing primary key for lob update on ${table_name}.${lob_column_name}"
            if (! $primary_key_values  || ! (%$primary_key_values));
    
        my $dbh = $connection->dbh;
        # a bit hacky but it looks like DBD::Oracle 1.20 caches first call with LongReadLen
        # and doesn't allow updates for greater size then the initial LongReadLen read
        # so physicaly 1GB on lob limitiation to declared here variable $LOB_SIZE = (1024 * 1024 * 1024);
        # another working solution is to reconnection - to expensive thuogh
        
        if (! exists($long_read_cache{"_" . $dbh})){
            $dbh->{LongReadLen} = $LOB_MAX_SIZE;
            $long_read_cache{"_" . $dbh} = 1;
            
        } else {
            $dbh->{LongReadLen} = $class->_get_lob_size($connection, $table_name, $primary_key_values, $lob_size_column_name);
        }
        
        my $sql = "SELECT ${lob_column_name} as lob_content FROM ${table_name} " . $connection->_where_clause($primary_key_values);
        my $record = $connection->record($sql, map { $primary_key_values->{$_}} sort keys %$primary_key_values);
        $record->{lob_content};
    }
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

1;

__END__

=back

=head1 SEE ALSO

L<DBIx::Connection>

=head1 COPYRIGHT AND LICENSE

The DBIx::Connection::Oracle::SQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

