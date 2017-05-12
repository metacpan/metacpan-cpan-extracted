package Class::PObject::Driver;

# Driver.pm,v 1.19 2003/11/07 00:36:21 sherzodr Exp

use strict;
#use diagnostics;
use Carp;
use Log::Agent;
use vars ('$VERSION');

$VERSION = '2.00';

# Preloaded methods go here.

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    logtrc 3, "%s->new()", $class;

    my $self = {
        _stash    => { },
    };
    return bless($self, $class)
}


sub DESTROY { }


sub errstr {
    my ($self, $errstr) = @_;
    my $class = ref($self) || $self;

    no strict 'refs';
    if ( defined $errstr ) {
        ${ "$class\::errstr" } = $errstr
    }
    return ${ "$class\::errstr" }
}




sub stash {
    my ($self, $key, $value) = @_;

    if ( defined($key) && defined($value) ) {
        $self->{_stash}->{$key} = $value
    }
    return $self->{_stash}->{$key}
}




sub dump {
    my $self = shift;

    require Data::Dumper;
    my $d = new Data::Dumper([$self], [ref $self]);
    return $d->Dump()
}


sub save {
    my $self = shift;
    my ($object_name, $props, $columns) = @_;

    croak "'$object_name' object doesn't support 'save()' method"
}

sub load {
    my $self = shift;
    my ($object_name, $props, $id) = @_;

    croak "'$object_name' doesn't support 'load()' method"
}



sub load_ids {
    my $self = shift;
    my ($object_name, $props, $terms, $args) = @_;

    croak "'$object_name' doesn't support  'load()' method"
}



sub remove {
    my $self = shift;
    my ($object_name, $props, $id) = @_;

    croak "'$object_name' doesn't support 'remove()' method"
}

sub drop_datasource {
    my $self = shift;
    my ($object_name, $props) = @_;

    croak "'$object_name' doesn't support 'drop_datasource()' method"
}


sub remove_all {
    my $self = shift;
    my $class = ref($self) || $self;
    my ($object_name, $props, $terms) = @_;

    logtrc 3, "%s->remove_all(%s)", $class, join ", ", @_;

    my $data_set = $self->load_ids($object_name, $props, $terms);
    for ( @$data_set ) {
        $self->remove($object_name, $props, $_)
    }
    return 1
}




sub count {
    my $self = shift;
    my $class = ref($self) || $self;
    my ($object_name, $props, $terms) = @_;

    logtrc 3, "%s->count(%s)", $class, join ", ", @_;

    my $data_set = $self->load_ids($object_name, $props, $terms);
    return scalar( @$data_set ) || 0
}










sub _filter_by_args {
    my ($self, $data_set, $args) = @_;

    unless ( keys %$args ) {
        return $data_set
    }
    # if sorting column was defined
    if ( defined $args->{'sort'} ) {
        # default to 'asc' sorting direction if it was not specified
        $args->{direction} ||= 'asc';
        # and sort the data set
        if ( $args->{direction} eq 'desc' ) {
            $data_set = [ sort {$b->{$args->{'sort'}} cmp $a->{$args->{'sort'}} } @$data_set]
        } else {
            $data_set = [ sort {$a->{$args->{'sort'}} cmp $b->{$args->{'sort'}} } @$data_set]
        }
    }
    # if 'limit' was defined
    if ( defined $args->{limit} ) {
        # default to 0 for 'offset' if 'offset' was not set
        $args->{offset} ||= 0;
        # and splice the data set
        return [splice(@$data_set, $args->{offset}, $args->{limit})]
    }
    return $data_set
}






sub _matches_terms {
    my $self = shift;
    my $class = ref($self) || $self;
    my ($data, $terms) = @_;

    logtrc 3, "%s->_matches_terms(@_)", $class;
    unless ( keys %$terms ) {
        return 1
    }
    # otherwise check this data set against all the terms
    # provided. If even one of those terms are not satisfied,
    # return false
    while ( my ($column, $value) = each %$terms ) {
        $^W = 0;
        if ( $data->{$column} ne $value ) {
            return 0
        }
    }
    return 1
}




sub freeze {
    my ($self, $object_name, $props, $data) = @_;

    my $rv = undef;
    if ( $props->{serializer} eq "xml" ) {
        require Data::DumpXML;
        $rv = Data::DumpXML::dump_xml($data)
    } elsif ( $props->{serializer} eq "dumper" ) {
        require Data::Dumper;
        my $d = Data::Dumper->new([$data]);
        $d->Terse(1);
        $d->Indent(0);
        $rv =  $d->Dump();
    } elsif ( $props->{serializer} eq 'freezethaw' ) {
        require FreezeThaw;
        $rv = FreezeThaw::freeze($data)
    } else {
        require Storable;
        $rv = Storable::freeze( $data )
    }
    return $rv
}




sub thaw {
    my ($self, $object_name, $props, $datastr) = @_;

    unless ( $datastr ) {
        return undef
    }

    my $rv = undef;
    if ( $props->{serializer} eq "xml" ) {
        require Data::DumpXML::Parser;
        my $p = Data::DumpXML::Parser->new();
        warn "parsing '$datastr'";
        $rv = $p->parse($datastr)
    } elsif ( $props->{serializer} eq "dumper" ) {
        $rv = eval $datastr;
    } elsif ( $props->{serializer} eq 'freezethaw' ) {
        require FreezeThaw;
        $rv = (FreezeThaw::thaw($datastr))[0]
    } else {
        require Storable;
        $rv = Storable::thaw( $datastr );
    }
    return $rv
}







1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Driver - Pobject driver specifications

=head1 SYNOPSIS

  package Class::PObject::Driver::my_driver;
  use base ('Class::PObject::Driver');

=head1 STOP!

If you just want to be able to use Class::PObject this manual is not for you.
This is for those planning to write I<pobject> drivers to support other database
systems and storage devices.

If you just want to be able to use Class::PObject, you should refer to its
L<online manual|Class::PObject> instead.

=head1 DESCRIPTION

Class::PObject::Driver is a base class for all the Object drivers.

Driver is another library Class::PObject uses only when disk access is necessary.
So you can still use Class::PObject without any valid driver, but it won't be
persistent object now, would it? 

    If you want to create on-the-fly, non-persistent
    objects, you are better off with Class::Struct

Driver's certain methods will be invoked when C<load()>, C<save()>, C<count()>, C<remove()> 
and C<remove_all()> methods of L<Class::PObject|Class::PObject> are called. 
They receive certain arguments, and are required to return certain values.

=head1 DRIVER SPECIFICATION

All the Class::PObject drivers should subclass Class::PObject::Driver,
thus they all should begin with the following lines or equivalent

    package Class::PObject::Driver::my_driver;
    use base ("Class::PObject::Driver");

Exceptions may be L<DBI|DBI>-related drivers, which are better off subclassing
L<Class::PObject::Driver::DBI|Class::PObject::Driver::DBI> and DBM-related drivers, 
that are better off subclassing L<Class::PObject::Driver::DBM|Class::PObject::Driver::DBM>

Methods that L<Class::PObject::Driver> defines are:

=over 4

=item stash($key [,$value])

For storing data in the driver object safely. This is mostly useful for caching the return value
of certain expensive operations that may be used over and over again. Good example is
stash()ing database connection.

For example, consider the following example:

  $dbh = DBI->connect(...);
  $self->stash($dsn, $dbh);

  # ... later, in some other method:
  $dbh = $self->stash( 'dbh' );

=item errstr($message)

Whenever an error occurs within any of driver methods, you should always call this method
with the error message, and return undef.

=back

Class::PObject::Driver also defines C<new()> - constructor. I don't think you should
know anything about it. You won't deal with it directly. All the driver methods
receive the driver object as the first argument.

=head1 WHAT SHOULD DRIVER DO?

All the driver methods accept at least three same arguments: C<$self> - driver object,
C<$class_name> - name of the class and C<\%properties> hashref of all the properties
as passed to C<pobject()> as the second (or first) argument in the form of a hashref.

These arguments are relevant to all the driver methods, unless noted otherwise.

On failure all the driver methods should pass the error message to C<errstr()> method as the
first and the only argument, and return undef.

On success they either should return a documented value (below), or boolean value whenever
appropriate.

=head2 REQUIRED METHODS

If you are inheriting from Class::PObject::Driver, you should provide following methods
of your own.

=over 4

=item C<save($self, $pobject_name, \%properties, \%columns)>

Whenever a user calls C<save()> method of I<pobject>, that method calls your driver's
C<save()> method in turn.

In addition to standard arguments, C<save()> accepts C<\%columns>, which is a
hash of column names and their respective values to be stored into disk.

It's the driver's obligation to figure whether the object should be stored, or updated.

New objects usually do not have C<id> defined. This is a clue that it is a new object,
thus you need to create a new ID and store the object into disk. If the I<id> exists,
it mostly means that object already should exist in the disk, and thus you need to update
it.

On success C<save()> should always return I<id> of the object stored or updated.

=item C<load_ids($self, $pobject_name, \%properties, [\%terms [, \%arguments]])>

When a user asks to load an object by calling C<load()> method of I<pobject>, driver's
C<load_ids()> method will be called by L<Class::PObject>.

In addition to aforementioned 3 standard arguments, it may (or may not) receive
C<\%terms> - terms passed to initial pobject's load() method as the first argument
and C<\%args> - arguments passed to pobject's load() method as the second argument.

Should return an arrayref of object ids.

=item C<load($self, $object_name, \%properties, $id)>

Is called to retrieve an individual object from the database. Along with standard
arguments, it receives C<$id> - ID of the record to be retrieved. On success should
return hash-ref of column/value pairs. 

=item C<remove($self, $object_name, \%properties, $id)>

Called when C<remove()> method is called on pobject.

In addition to standard arguments, it will receive C<$id> - ID of the object that needs to be removed.

Your task is to delete the record from the disk, and return any true value indicating success.

=item C<drop_datasource($self, $object_name, \%properties)>

Called when C<drop_datasource()> method is called on pobject. Its task is to remove 
the storage device allocated for storing this particular object. On success should return
I<1>.

=back

=head2 OPTIONAL METHODS

You may choose not to override the following methods if you don't want to. In that case
Class::PObject::Driver will try to implement these functionality based on other available
methods.

So why are these methods required if their functionality can be achieved using other methods?
Some drivers, especially RDBMS drivers, may perform these tasks much more efficiently by applying
special optimizations to queries. In cases like these, you may want to override these methods.
If you don't, default methods still perform as intended, but may not be as efficient.

=over 4

=item C<remove_all($self, $object_name, \%properties [,\%terms])>

Called when remove_all() method is called on pobject. It's job is to delete all
the objects from the disk.

In addition to standard arguments, it may (or may not) receive C<\%terms>, which is a set of key/value
pairs. All the objects matching these terms should be deleted from the disk.

Should return true on success.

=item C<count($self, $object_name, \%properties, [,\%terms])>

Counts number of objects stored in disk.

In addition to standard arguments, may (or may not) accept C<\%terms>, which is a set of key/value
pairs. If C<\%terms> is present, only the count of objects matching these terms should be returned.

On success should return a digit, representing a count of objects.

=back

=head1 UTILITY METHODS

Class::PObject::Driver provides several utility methods for you to ease the serialization
of data.

These methods consult C<serializer> attribute of pobject declaration to discover
what type of serialization to be used. Available attributes are, I<xml>, which 
serializes the data into an XML document using L<XML::Dumper|XML::Dumper>; 
I<dumper>, which serializes the data into pretty-printed string using L<Data::Dumper|Data::Dumper>;
I<storable>, which serializes the data using L<Stroable|Storable>.

Default is I<storable>, for backward compatibility.

Following are the specs of these methods.

=over 4

=item C<freeze($self, $object_name, \%properties, $hashref)>

In addition to standard arguments, accepts C<$hashref>, which is an in-memory perl Hash
table needed to be serialized into a string.

Should return serialized string on success, undef otherwise.

=item C<thaw($self, $object_name, \%properties, $datastr)>

Should reverse the serialization process performed by C<freeze()>.

In addition to standard arguments, accepts C<$datastr>, which is a serialized string
needed to be de-serialized into in-memory Perl data.

=back

=head1 SEE ALSO

L<Class::PObject::Driver::DBI>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
