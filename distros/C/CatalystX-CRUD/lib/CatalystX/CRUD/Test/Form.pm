package CatalystX::CRUD::Test::Form;
use strict;
use warnings;
use Carp;
use Data::Dump;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( params fields ));

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Test::Form - mock form class for testing CatalystX::CRUD packages

=head1 SYNOPSIS

 package MyApp::Form::Foo;
 use strict;
 use base qw( CatalystX::CRUD::Test::Form );
 
 sub foo_from_form {
     my $self = shift;
     return $self->SUPER::object_from_form(@_);
 }
 
 sub init_with_foo {
     my $self = shift;
     return $self->SUPER::init_with_object(@_);
 }
 
 1;
 
 
=head1 DESCRIPTION

CatalystX::CRUD::Test::Form is a mock form class for testing CatalystX::CRUD
packages. The API is similar to Rose::HTML::Form, but implements very naive
methods only.

=head1 METHODS


=head2 new( I<args> )

Returns new object instance. I<args> must be a hashref and 
must contain at least a key/value pair for B<fields>.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    croak "fields() required to be an ARRAY ref"
        unless $self->fields and ref( $self->fields ) eq 'ARRAY';
    $self->params( { map { $_ => undef } @{ $self->fields } } )
        unless $self->params;
    return $self;
}

*field_names = \&fields;

=head2 fields( [ I<arrayref> ] )

Get/set the arrayref of field names.

This must be set in new().

=head2 field_names

An alias for fields().

=head2 params( [ I<hashref> ] )

Get/set the hashref of key/value pairs for the form object. The keys should
be the names of form fields and should match the value of fields().

=head2 param( I<key> => I<val> )

Sets the key/value pair for a field. I<key> should be the name of a field,
as indicated by params().

=cut

sub param {
    my $self = shift;
    my $key  = shift;
    croak "key required" if !defined $key;
    my $val = shift;
    $self->params->{$key} = $val;
}

=head2 init_fields

Placeholder only. Does nothing.

=cut

sub init_fields {
    my $self = shift;

    # nothing to do
    #$self->dump;
}

=head2 clear

Resets params() to an empty hashref.

=cut

sub clear {
    my $self = shift;
    $self->params( {} );
}

=head2 validate

Does nothing. Always returns true.

=cut

sub validate {
    my $self = shift;

    # nothing to do in this poor man's form.
    #$self->dump;

    1;
}

=head2 init_with_object( I<object> )

You should override this method in your subclass. Basically sets all
accessors in form equal to the equivalent value in I<object>.

Returns the Form object.

=cut

sub init_with_object {
    my ( $self, $object ) = @_;
    for my $f ( keys %{ $self->params } ) {
        if ( $object->can($f) ) {
            $self->params->{$f} = $object->$f;
        }
    }
    return $self;
}

=head2 object_from_form( I<object> )

You should override this method in your subclass. Basically sets all
accessors in I<object> equal to the equivalent value in form.

=cut

sub object_from_form {
    my ( $self, $object ) = @_;
    for my $f ( keys %{ $self->params } ) {
        if ( $object->can($f) ) {
            $object->$f( $self->params->{$f} );
        }
    }
    return $object;
}

=head2 dump

Wrapper around Data::Dump::dump. Returns the form object serialized.

=cut

sub dump {
    my $self = shift;
    Data::Dump::dump($self);
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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
