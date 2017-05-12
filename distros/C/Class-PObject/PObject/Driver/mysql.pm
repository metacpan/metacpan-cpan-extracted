package Class::PObject::Driver::mysql;

# mysql.pm,v 1.25 2003/12/12 05:17:37 sherzodr Exp

use strict;
#use diagnostics;
use Log::Agent;
use vars ('@ISA', '$VERSION');
require Class::PObject::Driver::DBI;

@ISA = ('Class::PObject::Driver::DBI');
$VERSION = '2.01';

# 
# overriding _prepare_insert() with the version that uses REPLACE
# statement of MySQL instead of usual INSERT
#
sub _prepare_insert {
    my ($self, $table_name, $columns) = @_;

    my ($sql, @fields, @bind_params);
    $sql = "REPLACE INTO $table_name SET ";
    while ( my ($k, $v) = each %$columns ) {
        push @fields, "`$k`=?";
        push @bind_params, $v
    }
    $sql .= join(", ", @fields);
    return ($sql, \@bind_params)
}





sub save {
    my ($self, $object_name, $props, $columns) = @_;
    
    my $dbh                 = $self->dbh($object_name, $props)        or return;
    my $table               = $self->_tablename($object_name, $props, $dbh) or return;
    my ($sql, $bind_params) = $self->_prepare_insert($table, $columns);

    $self->_write_lock($dbh, $table) or return undef;
    my $sth                 = $dbh->prepare( $sql );
    unless ( $sth->execute(@$bind_params) ) {
        $self->errstr("couldn't save/update the record: " . $sth->errstr);
        logerr $self->errstr;
        return undef
    }
    $self->_unlock($dbh) or return undef;
    return $dbh->{mysql_insertid} || $dbh->{insertid}
}









sub dbh {
    my ($self, $object_name, $props) = @_;

    # checking if datasource provides adequate information to us
    my $datasource = $props->{datasource};
    unless ( ref($datasource) eq 'HASH' ) {    
        $self->errstr("'datasource' is invalid");
        return undef
    }
    if ( defined $props->{datasource}->{Handle} ) {
        return $props->{datasource}->{Handle}
    }
    my $stashed_name = $props->{datasource}->{DSN};
    if ( defined $self->stash($stashed_name) ) {
        return $self->stash($stashed_name)
    }
    if ( $datasource->{Handle} ) {
        $self->stash($stashed_name, $datasource->{Handle});
        return $datasource->{Handle}
    }
    my $dsn       = $datasource->{DSN};
    my $db_user   = $datasource->{User} || $datasource->{UserName};
    my $db_pass   = $datasource->{Password};
    unless ( $dsn ) {
        $self->errstr("'DSN' is missing in 'datasource'");
        return undef
    }
    require DBI;
    my $dbh = DBI->connect($dsn, $db_user, $db_pass, {RaiseError=>1, PrintError=>0});
    unless ( defined $dbh ) {
        $self->errstr("couldn't connect to 'DSN': " . $DBI::errstr);
        return undef
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    $self->stash($stashed_name, $dbh);
    $self->stash('close', 1);
    return $dbh
}



sub _tablename {
    my $self = shift;
    my ($object_name, $props, $dbh) = @_;

    unless ( defined $dbh ) {
        $dbh = $self->dbh( $object_name, $props )
    }
    my $tablename   = $self->SUPER::_tablename(@_);
    my $exists= 0;
    # if table by this name already exists in the database,
    # no reason to go any further.Return the name
    my $stashed = sprintf "exists:%s-%s", $dbh->{Name}, $tablename;
    if ( $self->stash($stashed) ) {
        logtrc 3, "'$stashed' was present. Table exists";
        return $tablename
    }
    
    # if we come this far, we're still not sure if the database 
    # exists or not. so we peek into the catalog.
    my %tables  = map { s/\W//g; $_, 1 } $dbh->tables;
    logtrc 3, "Retrieved %d tables from the database", scalar keys %tables;
    if ( $tables{ $tablename } ) {
        logtrc 3, "Table '%s' exists", $tablename;
        $self->stash($stashed, 1);
        return $tablename
    }

    my $sql = $self->_prepare_create_table($object_name, $tablename);
    unless ( $dbh->do( $sql ) ) {
        $self->errstr( $dbh->errstr );
        return undef
    }
    $self->stash($stashed, 1);
    return $tablename
}



sub _prepare_create_table {
    my ($self, $object_name, $tablename) = @_;

    my $sql = $self->SUPER::_prepare_create_table($object_name, $tablename);
    $sql =~ s/(id +INTEGER +PRIMARY +KEY)/$1 AUTO_INCREMENT/i;
    return $sql
}





1;
__END__;

=head1 NAME

Class::PObject::Driver::mysql - MySQL Pobject Driver

=head1 SYNOPSIS

    use Class::PObject;
    pobject Person => {
        columns => ['id', 'name', 'email'],
        driver  => 'mysql',
        datasource => {
            DSN => 'dbi:mysql:db_name',
            User => 'sherzodr',
            Password => 'marley01'
        }
    };


=head1 DESCRIPTION

Class::PObject::Driver::mysql is a direct subclass of L<Class::PObjecet::Driver::DBI|Class::PObject::Driver::DBI>.
It inherits all the base functionality needed for all the DBI-related classes. For details
of these methods and their specifications refer to L<Class::PObject::Driver|Class::PObject::Driver> and
L<Class::PObject::Driver::DBI|Class::PObject::Driver::DBI>.

=head2 DATASOURCE

I<datasource> attribute should be in the form of a hashref. The following keys are supported

=over 4

=item *

C<DSN> - provides a DSN string suitable for the first argument of DBI->connect(...).
Usually it should be I<dbi:mysql:$database_name>.

=item *

C<User> - username to connect to the database.

=item *

C<Password> - password required by the C<User> to connect to the database. If the user doesn't
require any passwords, you can set it to undef.

=item *

C<Table> - defines the name of the table that objects will be stored in. If this is missing
will default to the name of the object, non-alphanumeric characters replaced with underscore (C<_>).

=item *

C<Handle> attribute is useful if you already have C<$dbh> handy. If $dbh is used, C<DSN>, C<User>
and C<Password> attributes will be obsolete nor make sense.

=back

=head1 METHODS

Class::PObject::Driver::mysql (re-)defines following methods of its own

=over 4

=item *

C<dbh()> base DBI method is overridden with the version that creates a DBI handle
using I<DSN> I<datasource> attribute.

=item *

C<save()> - stores/updates the object

=item *

C<_prepare_insert()> redefines base method of the same name with the version that generates
a REPLACE SQL statement instead of default INSERT SQL statement. This allows the driver to
either leave "insert or update?" problem to MySQL.

This implies that table's I<id> column should be of I<AUTO_INCREMENT> type. This will ensure
that MySQL will take care of creating auto-incrementing unique object ids for you.

=back

=head1 NOTES

If the table is detected to be missing in the database, it will attempt to create proper
table for you. To have more control over how it creates this table,
you can fill-in column types using I<tmap> argument.

=head1 SEE ALSO

L<Class::PObject>, L<Class::PObject::Driver::csv>,
L<Class::PObject::Driver::file>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
