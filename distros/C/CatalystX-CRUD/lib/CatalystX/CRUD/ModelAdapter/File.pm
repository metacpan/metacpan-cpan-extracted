package CatalystX::CRUD::ModelAdapter::File;
use strict;
use warnings;
use base qw( CatalystX::CRUD::ModelAdapter );

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::ModelAdapter::File - filesystem CRUD model adapter

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 __PACKAGE__->config(
    # ... other config here
    model_adapter => 'CatalystX::CRUD::ModelAdapter::File',
    model_name    => 'MyFile',
 );
 
 1;
 
=head1 DESCRIPTION

CatalystX::CRUD::ModelAdapter::File is an example 
implementation of CatalystX::CRUD::ModelAdapter. It basically proxies
for CatalystX::CRUD::Model::File.

=head1 METHODS

Only new or overridden methods are documented here.

=cut

=head2 new_object( I<controller>, I<context>, I<args> )

Implements required method.

=cut

sub new_object {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->new_object(@arg);
}

=head2 fetch( I<controller>, I<context>, I<args> )

Implements required method.

=cut

sub fetch {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->fetch(@arg);
}

=head2 prep_new_object( I<controller>, I<context>, I<file> )

Implements required method.

=cut

sub prep_new_object {
    my ( $self, $controller, $c, $file ) = @_;
    my $model = $c->model( $self->model_name );
    $model->prep_new_object($file);
}

=head2 search( I<context>, I<args> )

Implements required method.

=cut

sub search {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->search(@arg);
}

=head2 iterator( I<context>, I<args> )

Implements required method.

=cut

sub iterator {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->iterator(@arg);
}

=head2 count( I<context>, I<args> )

Implements required method.

=cut

sub count {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->count(@arg);
}

=head2 make_query( I<context>, I<args> )

Implements required method.

=cut

sub make_query {
    my ( $self, $controller, $c, @arg ) = @_;
    my $model = $c->model( $self->model_name );
    $model->make_query(@arg);
}

=head2 create( I<context>, I<file_object> )

Implements required CRUD method.

=cut

sub create {
    my ( $self, $c, $file ) = @_;
    $file->create;
}

=head2 read( I<context>, I<file_object> )

Implements required CRUD method.

=cut

sub read {
    my ( $self, $c, $file ) = @_;
    $file->read;
}

=head2 update( I<context>, I<file_object> )

Implements required CRUD method.

=cut

sub update {
    my ( $self, $c, $file ) = @_;
    $file->update;
}

=head2 delete( I<context>, I<file_object> )

Implements required CRUD method.

=cut

sub delete {
    my ( $self, $c, $file ) = @_;
    $file->delete;
}

1;

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

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
