package CatalystX::CRUD::Model;
use strict;
use warnings;
use MRO::Compat;
use mro 'c3';
use base qw(
    Catalyst::Component::ACCEPT_CONTEXT
    CatalystX::CRUD
    Catalyst::Model
);

our $VERSION = '0.57';

__PACKAGE__->mk_accessors(qw( object_class page_size ));

__PACKAGE__->config( page_size => 50 );

=head1 NAME

CatalystX::CRUD::Model - base class for CRUD models

=head1 SYNOPSIS

 package MyApp::Model::Foo;
 use base qw( CatalystX::CRUD::Model );
 
 __PACKAGE__->config(
                    object_class    => 'MyApp::Foo',
                    page_size       => 50,
                    );
                     
 # must define the following methods
 sub new_object         { }
 sub fetch              { }
 sub search             { }
 sub iterator           { }
 sub count              { }
 sub search_related     { }
 sub iterator_related   { }
 sub count_related      { }
 
 1;
 
=head1 DESCRIPTION

CatalystX::CRUD::Model provides a high-level API for writing Model
classes. CatalystX::CRUD::Model methods typically return CatalystX::CRUD::Object
objects.

This documentation is intended for Model developers.

=head1 CONFIGURATION

You may configure your CXCM-derived Models in the usual way (see the Catalyst
Manual).

If the C<object_class> key/value pair is set at initialization time, the value
will be stored in the object_class() accessor. This feature is intended as a 
convenience for setting the name of the CatalystX::CRUD::Object class to which
your CatalystX::CRUD::Model acts as an interface.

=head1 METHODS

CatalystX::CRUD::Model inherits from Catalyst::Component::ACCEPT_CONTEXT
and Catalyst::Model. New and overridden methods are documented here.

=head2 context

This accessor is available via Catalyst::Component::ACCEPT_CONTEXT and
returns the C<$c> value for the current request.

This method is not implemented at the CatalystX::CRUD::Model level but is 
highlighted here in order to remind developers that it exists.

=head2 object_class

The object_class() accessor is defined for your convenience. It is set
by the default Xsetup() method if a key called C<object_class> is present
in config() at initialization time.

=cut

=head2 new

Overrides the Catalyst::Model new() method to call Xsetup().

=cut

sub new {
    my ( $class, $c, @arg ) = @_;
    my $self = $class->next::method( $c, @arg );
    $self->Xsetup( $c, @arg );
    return $self;
}

=head2 Xsetup

Called by new() at application startup time. Override this method
in order to set up your model in whatever way you require.

Xsetup() is called by new(), which in turn is called by COMPONENT().
Keep that order in mind when overriding Xsetup(), notably that config()
has already been merged by the time Xsetup() is called.

=cut

sub Xsetup {
    my ( $self, $c, $arg ) = @_;

    if ( !$self->object_class ) {
        $self->throw_error("must configure an object_class");
    }

    my $object_class = $self->object_class;
    eval "require $object_class";
    if ($@) {
        $self->throw_error("$object_class could not be loaded: $@");
    }

    return $self;
}

=head2 page_size

Returns the C<page_size> set in config().

=cut

=head2 new_object

Returns CatalystX::CRUD::Object->new(). A sane default, assuming
C<object_class> is set in config(), is implemented in this base class.


=head1 REQUIRED METHODS

CXCM subclasses need to implement at least the following methods:

=over

=item fetch( I<args> )

Should return the equivalent of 
CatalystX::CRUD::Object->new( I<args> )->read().

=item search( I<query> )

Returns zero or more CXCO instances as an array or arrayref.
I<query> may be the return value of make_query().

=item iterator( I<query> )

Like search() but returns an iterator conforming to the 
CatalystX::CRUD::Iterator API.

=item count( I<query> )

Like search() but returns an integer.

=item search_related( I<obj>, I<relationship> )

Returns zero or more CXCO instances like search().
The instances are related to I<obj> via I<relationship>.

=item iterator_related( I<obj>, I<relationship> )

Like search_related() but returns an iterator.

=item count_related( I<obj>, I<relationship> )

Like search_related() but returns an integer.

=back

=cut

sub new_object {
    my $self = shift;
    if ( $self->object_class ) {
        return $self->object_class->new(@_);
    }
    else {
        return $self->throw_error("must implement new_object()");
    }
}

sub fetch            { shift->throw_error("must implement fetch") }
sub search           { shift->throw_error("must implement search") }
sub iterator         { shift->throw_error("must implement iterator") }
sub count            { shift->throw_error("must implement count") }
sub search_related   { shift->throw_error("must implement search_related") }
sub iterator_related { shift->throw_error("must implement iterator_related") }
sub count_related    { shift->throw_error("must implement count_related") }

=head1 OPTIONAL METHODS

Catalyst components accessing CXCM instances may need to access
model-specific logic without necessarily knowing what kind of model they
are accessing.
An example would be a Controller that wants to remain agnostic about the kind
of data storage a particular model implements, but also needs to 
create a model-specific query based on request parameters.

 $c->model('Foo')->search(@arg);  # @arg depends upon what Foo is
 
To support this high level of abstraction, CXCM classes may implement
the following optional methods.

=over

=item make_query

Should return appropriate values for passing to search(), iterator() and
count(). Example of use:

 # in a CXCM subclass called MyApp::Model::Foo
 sub search {
     my $self = shift;
     my @arg  = @_;
     unless(@arg) {
         @arg = $self->make_query;
     }
     # search code here
     
     return $results;
 }
 
 sub make_query {
     my $self = shift;
     my $c    = $self->context;
     
     # use $c->req to get at params() etc.
     # and create a query
     
     return $query;
 }
 
 # elsewhere in a controller
 
 my $results = $c->model('Foo')->search;  # notice no @arg necessary since 
                                          # it will default to 
                                          # $c->model('Foo')->make_query()


=item add_related( I<obj>, I<rel_name>, I<foreign_value> )

Associate foreign object identified by I<foreign_value> with I<obj>
via the relationship I<rel_name>.

It is up to the subclass to implement this method.

=item rm_related( I<obj>, I<rel_name>, I<foreign_value> )

Dissociate foreign object identified by I<foreign_value> from I<obj>
via the relationship I<rel_name>.

It is up to the subclass to implement this method.

=item put_related( I<obj>, I<rel_name>, I<foreign_value> )

Create new related foreign object. Unlike add_related(),
the foreign object need not already exist. put_related()
should be idempotent.

=item remove_related

remove_related() is an alias for rm_related().

=item find_related( I<obj>, I<rel_name>, I<foreign_value> )

Return related object for I<foreign_value> based on I<rel_name>
for I<obj>.

=item has_relationship( I<obj>, I<rel_name> )

Should return true or false as to whether I<rel_name> exists for
I<obj>.

It is up to the subclass to implement this method.

=back

=cut

sub make_query  { shift->throw_error("must implement make_query()") }
sub add_related { shift->throw_error("must implement add_related()") }
sub rm_related  { shift->throw_error("must implement rm_related()") }
*remove_related = \&rm_related;
sub find_related { shift->throw_error("must implement view_related()") }
sub put_related  { shift->throw_error("must implement put_related()") }

sub has_relationship {
    shift->throw_error("must implement has_relationship()");
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
