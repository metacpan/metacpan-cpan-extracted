package Class::PObject::Driver::csv;

# csv.pm,v 1.20 2003/11/07 04:51:04 sherzodr Exp

use strict;
#use diagnostics;
use Log::Agent;
use File::Spec;
use vars ('$VERSION', '@ISA');

require Class::PObject::Driver::DBI;
@ISA = ('Class::PObject::Driver::DBI');

$VERSION = '2.01';



sub save {
    my $self = shift;
    my ($object_name, $props, $columns) = @_;

    # if an id doesn't already exist, we should create one.
    # refer to generate_id() for the details
    unless ( defined $columns->{id} ) {
        $columns->{id} = $self->generate_id($object_name, $props)
    }

    my $dbh   = $self->dbh($object_name, $props)                or return;
    my $table = $self->_tablename($object_name, $props, $dbh)   or return;
    my ($sql, $bind_params);
  
    my $exists = $self->count($object_name, $props, {id=>$columns->{id}});
    if ( $exists ) {
        ($sql, $bind_params) = $self->_prepare_update($table, $columns, {id=>$columns->{id}});

    } else {
        ($sql, $bind_params) = $self->_prepare_insert($table, $columns);
        
    }
    my $sth = $dbh->prepare( $sql );
    unless ( $sth->execute( @$bind_params )  ) {
        $self->errstr( "Failed query ($sth->{Statement}): " . $sth->errstr );
        return undef
    }
    return $columns->{id}
}



sub generate_id {
    my ($self, $object_name, $props) = @_;

    my $dbh   = $self->dbh($object_name, $props)                  or return;
    my $table = $self->_tablename($object_name, $props, $dbh)     or return;

    my $last_id = $dbh->selectrow_array(qq|SELECT id FROM $table ORDER BY id DESC LIMIT 1|);
    return ++$last_id
}



sub dbh {
    my $self = shift;
    my ($object_name) = @_;
    my $props = $object_name->__props();

    if ( defined $props->{datasource}->{Handle} ) {
        return $props->{datasource}->{Handle}->{Name}
    }

    my $dir          = $self->_dir($props) or return;
    my $stashed_name = "f_dir=$dir";
    
    if ( defined $self->stash($stashed_name) ) {
        return $self->stash($stashed_name)
    }

    require DBI;
    
    my $dbh = DBI->connect("DBI:CSV:f_dir=$dir", "", "", {RaiseError=>1, PrintError=>1});
    unless ( defined $dbh ) {
        $self->error($DBI::errstr);
        return undef
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    $self->stash($stashed_name, $dbh);
    $self->stash('close', 1);
    return $dbh
}



sub _dir {
    my $self    = shift;
    my ($props) = @_;
  
    my $datasource = $props->{datasource} || {};
    my $dir        = $datasource->{Dir};
    unless ( defined $dir ) {
        $dir = File::Spec->tmpdir
    }
    unless ( -e $dir ) {
        require File::Path;
        unless(File::Path::mkpath($dir)) {
            $self->error("couldn't create datasource '$dir': $!");
            return undef
        }
    }
    return $dir
}



sub _tablename {
    my ($self, $object_name, $props, $dbh) = @_;

    my $table = $self->SUPER::_tablename($object_name, $props);
    my $dir   = $self->_dir($props) or return;
    if ( -e File::Spec->catfile($dir, $table) ) {
        return $table
    }

    my $sql = $self->_prepare_create_table($object_name, $table);
    unless( $dbh->do( $sql ) ) {
        $self->errstr( $dbh->errstr );
        return undef
    }
    return $table
}



sub _prepare_create_table {
    my $self = shift;

    my $sql = $self->SUPER::_prepare_create_table( @_ );
    $sql =~ s/(NOT\s+)?NULL//ig;
    return $sql
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Driver::csv - CSV Pobject Driver

=head1 SYNOPSIS

    use Class::PObject;
    pobject Person => {
        columns => ['id', 'name', 'email'],
        driver  => 'csv',
        datasource => {
            Dir => 'data/',
            Table => 'person'
        }
    };

=head1 DESCRIPTION

Class::PObject::Driver::csv is a direct subclass of L<Class::PObjecet::Driver::DBI|Class::PObject::Driver::DBI>.
It inherits all the base functionality needed for all the DBI-related classes. For details
of these methods and their specifications refer to L<Class::PObject::Driver|Class::PObject::Driver> and
L<Class::PObject::Driver::DBI|Class::PObject::Driver::DBI>.

=head2 DATASOURCE

I<datasource> attribute should be in the form of a hashref. The following keys are supported

=over 4

=item *

C<Dir> - points to the directory where the CSV files are stored. If this is missing
will default to your system's temporary folder. If the Dir is provided, and it doesn't
exist, it will be created for you.

=item *

C<Table> - defines the name of the table that objects will be stored in. If this is missing
will default to the name of the object, non-alphanumeric characters replaced with underscore (C<_>).

=back

=head1 METHODS

Class::PObject::Driver::csv (re-)defines following methods of its own

=over 4

=item *

C<dbh()> base DBI method is overridden with the version that creates a DBI handle
through L<DBD::CSV|DBD::CSV>.

=item *

C<save()> either builds a SELECT SQL statement by calling base C<_prepare_select()> 
if the object id is missing, or builds an UPDATE SQL statement by calling base C<_prepare_update()>.

If the ID is missing, calls C<generate_id()> method, which returns a unique ID for the object.

=item *

C<generate_id($self, $pobject_name, \%properties)> returns a unique ID for new objects. This determines
the new ID by performing a I<SELECT id FROM $table ORDER BY id DESC LIMIT 1> SQL statement to 
determine the latest inserted ID.

=item *

C<_tablename($self, $pobject_name, \%properties)>

Redefines base method C<_tablename()>. If the table is missing, it will also create the table
for you.

=back

=head1 NOTES

If the table is detected to be missing in the database, it will attempt to create proper
table for you. To have more control over how it creates this table,
you can fill-in column types using I<tmap> argument.


=head2 SPEED

I<csv> driver can get incredibly processor intensive once the number of records exceeds
1,000. This can be fixed by providing indexing functionality to the driver, which it currently
misses.

Main issue of the driver is in its C<save()> method, where it first needs to SELECT the records
to find out if the record being inserted exists or not. Then, depending on its discoveries
either runs INSERT or UPDATE queries.

C<generate_id()> method could also be improved by allowing it to keep track of record count
in a separate file.

All these issues need to be addressed in subsequent releases of the library.

=head1 SEE ALSO

L<Class::PObject>, L<Class::PObject::Driver::mysql>,
L<Class::PObject::Driver::file>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
