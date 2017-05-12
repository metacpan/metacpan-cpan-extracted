package Class::DBI::Factory::Ghost;
use strict;
use vars qw( $VERSION $AUTOLOAD );
$VERSION = '0.04';

=head1 NAME

Class::DBI::Factory::Ghost - a minimal data-container used as a precursor for Class::DBI objects when populating forms or otherwise preparing to create a new object from existing data.

=head1 SYNOPSIS

my $thing = Class::DBI::Factory::Ghost->new({
    id => 'new',
    moniker => $moniker,
    person => $self->session->person,
    parent => $self->param('parent'),
});

# or

my $thing = Class::DBI::Factory::Ghost->from( $other_thing );

$thing->title($input->param('title'));

$thing->solidify if (...);

=head1 INTRODUCTION

The ghost is a loose data-container that can be passed to templates or other processes in place of a full Class::DBI object. Its main purpose is to allow the same forms to be used for both creation and editing of objects, but it can be useful in other settings where you might want to make method calls without knowing whether the object had been stored in the database or not.

It is constructed and queried in largely the same way as a Class::DBI object, except that only the most basic parts of the interface are supported, and it depends on the availability of a L<Class::DBI::Factory> object (or an object of a subclass thereof, such as Delivery) to provide the necessary information about classes and columns.

More elaborate Class::DBI constructions, such as set_sql prototypes and has_* methods will not work: only the simple get-and-set functionality is duplicated here, and obviously anything which relies on cdbi's internal variables will not work.

=head2 new()

Constructs and returns a ghost object. Accepts a hashref of column => value pairs which must include a 'type' or 'moniker' value that corresponds to one of your data classes. Supplied values for other columns can be but don't have to be objects: they will be deflated in the usual way.

  my $temp = Class::DBI::Factory::Ghost->new({
      moniker => 'cd',
      person => $session->person,
  });  

=cut

sub new {
    my ($class, $data) = @_;
    $data->{id} ||= 'new';
    $data->{_moniker} = delete $data->{moniker} || delete $data->{type};
    return unless $data->{_moniker} && $class->factory->has_class($data->{_moniker});
    return bless $data, $class;
}

=head2 from( $object )

Constructs and returns a ghost copy of a real cdbi object. Useful if the object is about to be deleted or otherwise interfered with.

  my $remnant = Class::DBI::Factory::Ghost->from( $foo );  
  ...
  my $bar = $remnant->make;
  
Calling C<make> on the ghost object should give you an object that is not identical to but exactly resembles the original template object. 

But note that any cascading deletes or triggers associated with deletion will have been, er, triggered. 
  
=cut

sub from {
    my ($class, $source) = @_;
    return unless $source && $source->isa('Class::DBI');
    my %data = {};
    my @cols = $source->columns('All');
    @data{@cols} =  $source->_attrs( @cols );
    $data{_moniker} = $source->moniker;
    return bless \%data, $class;
}

=head2 is_ghost()

Returns true. This becomes more useful if you put a corresponding C<is_ghost> method in your Class::DBI base class and have it return false. Templates may not be able to tell the difference, otherwise.

=cut

sub is_ghost { 1 }

=head2 moniker()

This is the key that determines the class a particular object is ghosting, and therefore the columns and relationships it should enter into. It must be set at construction time, so this method just returns the value stored then.

Accessor only.

=cut

sub moniker {
    return shift->{_moniker};
}

=head2 type()

Old alias of C<moniker()>, dating back to before the moniker was introduced and so ripe for elimination.

=cut

sub type {
    return shift->{_moniker};
}

=head2 class()

Returns the Full::Class::Name of the class that we are ghosting.

=cut

sub class {
    my $self = shift;
    return $self->{_class} ||= $self->factory->class_name($self->moniker);
}

=head2 factory()

As usual, calls CDF->instance to get the locally active factory object, for some local definition of local.

=head2 factory_class()

Override this method in subclass to use a factory class other than CDF (a subclass of it, presumably). Should return a fully qualified Module::Name.

=cut

sub factory_class { "Class::DBI::Factory" }
sub factory { return shift->factory_class->instance; }
sub debug { return shift->factory->debug(@_); } 

=head2 AUTOLOAD()

Very simple: nothing clever here at all. This provides as a get-and-set method for each of the columns defined by the class that this object is ghosting (ie it uses the moniker parameter to check method names). Nothing else.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $method_name = $AUTOLOAD;
	$method_name =~ s/.*://;
	my ($package, $filename, $line) = caller;
    return if $method_name eq 'DESTROY';
    
    $self->debug(4, "*** CDF::Ghost->$method_name(" . join(', ', @_) . ") called at $package line $line", 'ghost');
    
    my $class_methods = $self->class_methods;
    return $self->class->$method_name(@_) if $class_methods->{$method_name};
    return unless $self->find_column($method_name);
    return $self->{$method_name} = shift if @_;
    return $self->{$method_name};
}

sub class_methods {
    return {
        class_title => 1,
        class_plural => 1,
        class_description => 1,
        columns => 1,
    }
}

=head2 find_column()

Exactly as with a normal Class::DBI class, except that it's a remote enquiry mediated by the factory. 

=cut

sub find_column {
	my ($self, $column) = @_;
    return $self->factory->find_column($self->moniker, $column);
}

=head2 just_data()

Returns only that part of the underlying hashref which is needed to create the real version of this object, ie having removed moniker, id and any extraneous values that have been set but are not columns of the eventual object.

=cut

sub just_data {
	my $self = shift;
    my %data = map { $_ => $self->{$_} } grep { $self->find_column($_) } keys %$self;
    delete $data{id};
    return \%data;
}

=head2 make()

Attempts to produce a real object of the class specified by the moniker parameter supplied during construction, using the column values of the ghost object.

The created object is returned, but the ghost object remains the same, so it is possible to create several new cdbi objects from one ghost.

  for(@addresses) {
    $ghost->address($_);
    $ghost->make;
  }

=head2 find_or_make()

Behaves exactly as C<make>, except that it calls C<find_or_create> instead of  C<create>: if an object of the relevant class exists containing exactly the values currently stored in this object, that object will be returned instead and no new object created.

=cut

sub make {
	my $self = shift;
	return $self->factory->create($self->moniker, $self->just_data);
}

sub find_or_make {
	my $self = shift;
    return $self->factory->foc($self->moniker, $self->just_data);
}

=head1 REQUIRES

=over

=item L<Class::DBI::Factory>

=back

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::Factory>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-4 William Ross, spanner.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;