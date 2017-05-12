package Class::PObject::Driver::sqlite;

# sqlite.pm,v 1.10 2003/11/07 04:51:04 sherzodr Exp

use strict;
#use diagnostics;
use Log::Agent;
use vars ('@ISA', '$VERSION');
require File::Path;
require File::Basename;
require Class::PObject::Driver::DBI;

@ISA = ('Class::PObject::Driver::DBI');
$VERSION = '2.01';


sub save {
    my ($self, $object_name, $props, $columns) = @_;
    
    my $dbh                 = $self->dbh($object_name, $props)        or return;
    my $table               = $self->_tablename($object_name, $props, $dbh) or return;
    my ($sql, $bind_params);

    # checking if $columns->{id} exists:
    if ( $columns->{id} ) {
        #let's check if there is a database record for this column already
        if ( $self->count($object_name, $props, {id=>$columns->{id}}) ) {
            ($sql, $bind_params) = $self->_prepare_update($table, $columns, {id=>$columns->{id}});
        }
    }
    unless ( $sql ) {
        ($sql, $bind_params)= $self->_prepare_insert($table, $columns)
    }
    my $sth                 = $dbh->prepare( $sql );
    unless ( $sth->execute(@$bind_params) ) {
        $self->errstr("couldn't save/update the record ($sth->{Statement}): " . $sth->errstr);
        logerr $self->errstr;
        return undef
    }
    return $dbh->func("last_insert_rowid")
}









sub dbh {
    my ($self, $object_name, $props) = @_;

    my $datasource = $props->{datasource};
    if ( defined $self->stash($datasource) ) {
        return $self->stash($datasource)
    }
    
    my $basedir = File::Basename::dirname( $datasource );
    logtrc 3, "datasource:%s, directory: %s", $datasource, $basedir;

    unless ( -e $basedir ) {
        unless ( File::Path::mkpath($basedir) ) {
            $self->errstr( "couldn't create '$basedir': $!" );
            return undef
        }
    }
    require DBI;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$datasource", "", "", {RaiseError=>0, PrintError=>0});
    unless ( defined $dbh ) {
        $self->errstr("couldn't connect to 'DSN': " . $DBI::errstr);
        return undef
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    $self->stash($datasource, $dbh);
    $self->stash('close', 1);
    return $dbh
}




sub _tablename {
    my ($self, $object_name, $props, $dbh) = @_;

    my $table_name = lc $object_name;
    $table_name =~ s/\W+/_/g;
    
    {
        local $^W = 0; # DBD::SQLite generates a warning
        my %tables = map { $_, 1 } $dbh->tables;
        if ( $tables{ $table_name } ) {
            return $table_name
        }
    }

    my $sql = $self->_prepare_create_table($object_name, $table_name);
    unless ( $dbh->do( $sql ) ) {
        $self->errstr( $dbh->errstr );
        return undef
    }
    return $table_name
}

1;
__END__;

=head1 NAME

Class::PObject::Driver::sqlite - SQLite Pobject Driver

=head1 SYNOPSIS

    use Class::PObject;
    pobject Person => {
        columns => ['id', 'name', 'email'],
        driver  => 'sqlite',
        datasource => 'data/website.db'
    };

=head1 DESCRIPTION

Class::PObject::Driver::sqlite is a direct subclass of L<Class::PObjecet::Driver::DBI|Class::PObject::Driver::DBI>.
It inherits all the base functionality needed for all the DBI-related classes. For details
of these methods and their specifications refer to L<Class::PObject::Driver|Class::PObject::Driver> and
L<Class::PObject::Driver::DBI|Class::PObject::Driver::DBI>.

=head2 DATASOURCE

I<datasource> attribute should be a string pointing to a database file. Multiple objects may have
the same datasource, in which case all the related tables will be stored in a single database.

=head1 METHODS

Class::PObject::Driver::sqlite (re-)defines following methods of its own

=over 4

=item *

C<dbh()> base DBI method is overridden with the version that creates a DBI handle
using L<DBD::SQLite|DBD::SQLite> I<datasource> attribute.

=item *

C<save()> - stores/updates the object

=back

=head1 NOTES

If the directory portion of the I<datasource> is missing, it will attempt to
create necessary directory tree for you.

If table to store the database is found to be missing, it will attempt to create
the a proper table for you. To have more control over how it creates this table,
you can fill-in column types using I<tmap> argument.

=head1 SEE ALSO

L<Class::PObject>, 
L<Class::PObject::Driver::csv>,
L<Class::PObject::Driver::file>, 
L<Class::PObject::Driver::mysql>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
