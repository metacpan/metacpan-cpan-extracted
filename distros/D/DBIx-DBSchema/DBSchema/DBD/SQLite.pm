package DBIx::DBSchema::DBD::SQLite;
use base qw( DBIx::DBSchema::DBD );

use strict;
use vars qw($VERSION %typemap);

$VERSION = '0.03';

%typemap = (
  'SERIAL' => 'INTEGER PRIMARY KEY AUTOINCREMENT',
);

=head1 NAME

DBIx::DBSchema::DBD::SQLite - SQLite native driver for DBIx::DBSchema

=head1 SYNOPSIS

use DBI;
use DBIx::DBSchema;

$dbh = DBI->connect('dbi:SQLite:tns_service_name', 'user','pass');
$schema = new_native DBIx::DBSchema $dbh;

=head1 DESCRIPTION

This module implements a SQLite-native driver for DBIx::DBSchema.

=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>

=cut 

=head1 API 

=over


=item columns CLASS DBI_DBH TABLE

Given an active DBI database handle, return a listref of listrefs (see
L<perllol>), each containing six elements: column name, column type,
nullability, column length, column default, and a field reserved for
driver-specific use (which for sqlite is whether this col is a primary key)


=cut

sub columns {
    my ( $proto, $dbh, $table ) = @_;
    my $sth  = $dbh->prepare("PRAGMA table_info($table)");
        $sth->execute();
    my $rows = [];

    while ( my $row = $sth->fetchrow_hashref ) {

        #  notnull #  pk #  name #  type #  cid #  dflt_value
        push @$rows,
            [
            $row->{'name'},    
            $row->{'type'},
            ( $row->{'notnull'} ? 0 : 1 ), 
            undef,
            $row->{'dflt_value'}, 
            $row->{'pk'}
            ];

    }

    return $rows;
}


=item primary_key CLASS DBI_DBH TABLE

Given an active DBI database handle, return the primary key for the specified
table.

=cut

sub primary_key {
  my ($proto, $dbh, $table) = @_;

        my $cols = $proto->columns($dbh,$table);
        foreach my $col (@$cols) {
                return ($col->[1]) if ($col->[5]);
        }
        
        return undef;
}



=item unique CLASS DBI_DBH TABLE

Given an active DBI database handle, return a hashref of unique indices.  The
keys of the hashref are index names, and the values are arrayrefs which point
a list of column names for each.  See L<perldsc/"HASHES OF LISTS"> and
L<DBIx::DBSchema::ColGroup>.

=cut

sub unique {
  my ($proto, $dbh, $table) = @_;
  my @names;
        my $indexes = $proto->_index_info($dbh, $table);
   foreach my $row (@$indexes) {
        push @names, $row->{'name'} if ($row->{'unique'});

    }
    my $info  = {};
        foreach my $name (@names) {
                $info->{'name'} = $proto->_index_cols($dbh, $name);
        }
    return $info;
}


=item index CLASS DBI_DBH TABLE

Given an active DBI database handle, return a hashref of (non-unique) indices.
The keys of the hashref are index names, and the values are arrayrefs which
point a list of column names for each.  See L<perldsc/"HASHES OF LISTS"> and
L<DBIx::DBSchema::ColGroup>.

=cut

sub index {
  my ($proto, $dbh, $table) = @_;
  my @names;
        my $indexes = $proto->_index_info($dbh, $table);
   foreach my $row (@$indexes) {
        push @names, $row->{'name'} if not ($row->{'unique'});

    }
    my $info  = {};
        foreach my $name (@names) {
                $info->{'name'} = $proto->_index_cols($dbh, $name);
        }

  return $info;
}



sub _index_list {

        my $proto = shift;
        my $dbh = shift;
        my $table = shift;

my $sth  = $dbh->prepare('PRAGMA index_list($table)');
$sth->execute();
my $rows = [];

while ( my $row = $sth->fetchrow_hashref ) {
    # Keys are "name" and "unique"
    push @$rows, $row;

}

return $rows;
}



sub _index_cols {
        my $proto  = shift;
        my $dbh = shift;
        my $index = shift;
        
        my $sth  = $dbh->prepare('PRAGMA index_info($index)');
        $sth->execute();
        my $data = {}; 
while ( my $row = $sth->fetchrow_hashref ) {
    # Keys are "name" and "seqno"
        $data->{$row->{'seqno'}} = $data->{'name'};
}
        my @results; 
        foreach my $key (sort keys %$data) {
              push @results, $data->{$key}; 
        }

        return \@results;

}

=pod

=back

=cut

1;
