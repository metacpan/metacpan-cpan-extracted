package Class::PObject::Driver::DBM;

# DBM.pm,v 1.8 2003/09/09 00:11:54 sherzodr Exp

use strict;
#use diagnostics;
use Carp;
use Class::PObject::Driver;
use File::Spec;
use Fcntl (':DEFAULT', ':flock');
use vars ('$VERSION', '@ISA', '$lock');

@ISA = ('Class::PObject::Driver');

$VERSION = '2.00';


sub save {
    my ($self, $object_name, $properties, $columns) = @_;
    
    my (undef, $dbh, $unlock) = $self->dbh($object_name, $properties, 'w') or return undef;
    unless ( $columns->{id} ) {
        my $lastid = $dbh->{_lastid} || 0;
        $columns->{id} = ++$dbh->{_lastid}
    }
    $dbh->{ "!ID:" . $columns->{id} } = $self->freeze($object_name, $properties, $columns);
    $unlock->();
    return $columns->{id}
}



sub load_ids {
    my ($self, $object_name, $properties, $terms, $args) = @_;

    my (undef, $dbh, $unlock) = $self->dbh($object_name, $properties) or return undef;
    my @data_set = ();
    my $n = 0;
    while ( my ($k, $v) = each %$dbh ) {
        if ( $args && $args->{limit} && !$args->{offset} && !$args->{sort} ) {
            $n++ == $args->{limit} and last
        }
        $k =~ /!ID:/ or next;
        my $data = $self->thaw( $object_name, $properties, $v );
        if ( $self->_matches_terms($data, $terms) ) {
            push @data_set, keys %$args ? $data : $data->{id}
        }
    }
    $unlock->();
    unless ( keys %$args ) {
        return \@data_set
    }
    my $data = $self->_filter_by_args(\@data_set, $args);
    return [ map { $_->{id} } @$data ]
}






sub load {
    my ($self, $object_name, $props, $id) = @_;

    my (undef, $dbh, $unlock) = $self->dbh($object_name, $props) or return undef;
    return $self->thaw($object_name, $props, $dbh->{ "!ID:" . $id })
}


















sub remove {
    my ($self, $object_name, $properties, $id) = @_;

    
    my (undef, $dbh, $unlock) = $self->dbh($object_name, $properties, 'w') or return undef;
    delete $dbh->{ "!ID:" . $id };
    $unlock->();
    return 1
}










sub _lock {
    my $self = shift;
    my ($file, $type) = @_;
    
    $file    .= '.lck';
    my $lock_flags = $type eq 'w' ? LOCK_EX : LOCK_SH;

    require Symbol;
    my $lock_h = Symbol::gensym();
    unless ( sysopen($lock_h, $file, O_RDWR|O_CREAT, 0666) ) {
        $self->errstr("couldn't create/open '$file': $!");
        return undef
    }
    unless (flock($lock_h, $lock_flags)) {
        $self->errstr("couldn't lock '$file': $!");
        close($lock_h);
        return undef
    }
    return sub { 
        close($lock_h);
        unlink $file
    }
}













1;
__END__

=head1 NAME

Class::PObject::Driver::DBM - Base class for DBM-related pobject drivers

=head1 SYNOPSIS

    use Class::PObject::Driver::DBM;
    @ISA = ('Class::PObject::Driver::DBM');

    sub dbh {
        my ($self, $pobject_name, $properties) = @_;
        ...
    }

=head1 ABSTRACT

    Class::PObject::Driver::DBM is a base class for all the DBM-related
    pobject drivers. Class::PObject::Driver::DBM is a direct subclass of
    Class::PObject::Driver.

=head1 DESCRIPTION

Class::PObject::Driver::DBM is a direct subclass of Class::PObject::Driver, 
and provides all the necessary methods common for DBM-related disk access.

=head1 METHODS

Refer to L<Class::PObject::Driver|Class::PObject::Driver> for the details of all
the driver-specific methods. Class::PObject::Driver::DBM overrides C<save()>,
C<load()> and C<remove()> methods with the versions relevant to DBM-related
disk access.

=over 4

=item *

C<dbh($self, $pobject_name, \%properties, $lock_type)> - called whenever base methods
need database tied hash. DBM drivers should provide this method, which should
return an array of elements, namely C<$DB> - an DBM object, usually returned from
C<tie()> or C<tied()> functions; C<$dbh> - a hash tied to database; C<$unlock> - 
an action required for unlocking the database. C<$unlock> should be a reference 
to a subroutine, which when called should release the lock.

Currently base methods ignore C<$DB>, but it may change in the future.

=item *

C<_filename($self, $pobject_name, \%properties)> - returns a name of the file
to connect to. It first looks for C<$properties->{datasource}> and if it exists,
uses the value as a directory name object file should be created in. If it's missing,
defaults to systems temporary folder.

It then returns a file name derived out of C<$pobject_name> inside this directory.

=item *

C<_lock($file, $filename, $lock_type)> - acquires either shared or exclusive lock depending
on the C<$lock_type>, which can be either of I<w> or I<r>.

Returns a reference to an action (subroutine), which perform unlocking for this particular
lock. On failure returns undef. C<_lock()> is usually called from within C<dbh()>, and return
value is returned together with database handles.

=back

=head1 NOTES

Currently the only record index is the I<id> column. By introducing configurable indexes,
object selections (through C<load()> method) can be improved tremendously. Syntax similar 
to the following may suffice:

    pobject Article => {
        columns         => ['id', 'title', 'author', 'content'],
        indexes         => ['title', 'author'],
        driver          => 'db_file',
        datasource      => './data'
    }
        
This issue is to be addressed in subsequent releases.

=head1 SEE ALSO

L<Class::PObject::Driver>,
L<Class::PObject::Driver::DB_File>
L<Class::PObject::Driver::DBI>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
