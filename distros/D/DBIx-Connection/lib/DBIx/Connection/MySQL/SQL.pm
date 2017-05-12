package DBIx::Connection::MySQL::SQL;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use Carp 'confess';

$VERSION = 0.03;

=head1 NAME

DBIx::Connection::MySQL::SQL - MySQL catalog sql abstractaction layer.

=cut  

=head1 SYNOPSIS
    
    use DBIx::Connection::MySQL::SQL;


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
    my ($self) = @_;
    confess "not supported";
}


=item reset_sequence

Returns sql statement that restarts sequence.

=cut

sub reset_sequence {
    my ($class, $name, $start_with, $increment_by, $connection) = @_;
    $connection->do("ALTER TABLE $name AUTO_INCREMENT = ${start_with}");
    ();
}


=item set_session_variables

Iniitialise session variable.
It uses the following command pattern:

    SET @@local.variable = value;

=cut

sub set_session_variables {
    my ($class, $connection, $db_session_variables) = @_;
    my $sql = "";
    $sql .= 'SET @@local.' . $_ . " = " . $db_session_variables->{$_} . ";"
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

    $connection->dbh->{max_allowed_packet} = length($lob) if $lob;
    my $bind_counter = 1;
    my $sth = $connection->dbh->prepare($sql);
    $sth->bind_param($bind_counter++ ,$lob);
    $sth->bind_param($bind_counter++ , ($lob ? length($lob) : 0)) if $lob_size_column_name;
    for my $k (sort keys %$primary_key_values) {
        $sth->bind_param($bind_counter++ , $primary_key_values->{$k});
    }
    $sth->execute();
    
    
}


=item fetch_lob

Retrieves lob.
Takes connection object, table name, lob column_name, hash_ref to primary key values

=cut

sub fetch_lob {
    my ($class, $connection, $table_name, $lob_column_name, $primary_key_values) = @_;
    confess "missing primary key for lob update on ${table_name}.${lob_column_name}"
        if (! $primary_key_values  || ! (%$primary_key_values));
    my $sql = "SELECT ${lob_column_name} as lob_content FROM ${table_name} " . $connection->_where_clause($primary_key_values);
    my $record = $connection->record($sql, map { $primary_key_values->{$_}} sort keys %$primary_key_values);
    $record->{lob_content};
}



1;

__END__

=back

=head1 SEE ALSO

L<DBIx::PLSQLHandler>

=head1 COPYRIGHT AND LICENSE

The DBIx::Connection::MySQL::SQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
