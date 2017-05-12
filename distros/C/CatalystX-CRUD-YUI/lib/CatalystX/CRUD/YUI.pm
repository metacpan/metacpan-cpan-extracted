package CatalystX::CRUD::YUI;

use warnings;
use strict;
use Carp;
use CatalystX::CRUD::YUI::LiveGrid;
use CatalystX::CRUD::YUI::Serializer;
use base qw( Class::Accessor::Fast );
use MRO::Compat;
use mro "c3";
use Data::Dump qw( dump );

__PACKAGE__->mk_accessors(
    qw( serializer_class livegrid_class ));

our $VERSION = '0.031';

=head1 NAME

CatalystX::CRUD::YUI - YUI for your CatalystX::CRUD view

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use strict;
 use base qw(
    CatalystX::CRUD::YUI::Controller
    CatalystX::CRUD::Controller::RHTMLO
 );
 
 # config here -- see CatalystX::CRUD::Controller docs
 
 1;

=head1 DESCRIPTION

CatalystX::CRUD::YUI is a crud application using the Yahoo
User Interface and ExtJS toolkits, and CatalystX::CRUD components. It is
derived largely from the Rose::DBx::Garden::Catalyst project
but now with support for DBIx::Class via the 
CatalystX::CRUD::ModelAdapter::DBIC package.

The t/ test directly for this package contains two full
Catalyst applications, one for RDBO and one for DBIC, both
using the same basic db schema. Looking at those examples 
is a good way to start.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new( I<opts> )

=cut

sub new {
    my $self = shift->next::method(@_);
    $self->{serializer_class} ||= 'CatalystX::CRUD::YUI::Serializer';
    $self->{livegrid_class}   ||= 'CatalystX::CRUD::YUI::LiveGrid';
    return $self;
}

=head2 livegrid( I<opts> )

Returns a CatalystX::CRUD::YUI::LiveGrid object
ready for the livegrid_*.tt templates.

I<opts> should consist of:

=over

=item results

I<results> may be either a CatalystX::CRUD::Results object or a 
CatalystX::CRUD::Object object.

=item controller

The Catalyst::Controller instance for the request.

=item form

The current Form object. The Form class should be
Rose::HTMLx::Form::Related, a subclass thereof, or
a class with a corresponding API.

=item rel_info

If I<results> is a CatalystX::CRUD::Object object, 
then a I<rel_info> should be passed indicating
which relationship to pull data from.

=item field_names

Optional arrayref of field names to include. Defaults
to form->meta->field_methods().

=back

=cut

sub _fix_args {
    my @arg = @_;
    if ( @arg == 1 ) {
        if ( ref( $arg[0] ) eq 'ARRAY' ) {
            @arg = @{ $arg[0] };
        }
        elsif ( ref( $arg[0] ) eq 'HASH' ) {
            @arg = %{ $arg[0] };
        }
    }
    return @arg;
}

sub livegrid {
    my $self = shift;
    return $self->livegrid_class->new( _fix_args(@_), yui => $self );
}

=head2 serializer

Returns new Serializer object of type serializer_class().

=cut

sub serializer {
    my $self = shift;
    return $self->serializer_class->new( _fix_args(@_), yui => $self );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-yui@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

