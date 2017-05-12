package CatalystX::CRUD::Test::Controller;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Controller );
use Carp;
use Data::Dump;
use mro 'c3';

__PACKAGE__->mk_accessors(qw( form_fields ));

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Test::Controller - mock controller class for testing CatalystX::CRUD packages

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use strict;
 use base qw( CatalystX::CRUD::Test::Controller );
 
 use MyForm;
 
 __PACKAGE__->config(
    form_class            => 'MyForm',
    form_fields           => [qw( one two three )],
    init_form             => 'init_with_foo',
    init_object           => 'foo_from_form',
    default_template      => 'no/such/file',
    model_name            => 'Foo',
    primary_key           => 'id',
    view_on_single_result => 0,
    page_size             => 50,
    allow_GET_writes      => 0,
 );

 1;
 
 
=head1 DESCRIPTION

CatalystX::CRUD::Test::Controller is a mock controller class for 
testing CatalystX::CRUD packages. It implements the required Controller
methods and overrides others to work with CatalystX::CRUD::Test::Form.

=head1 METHODS

=head2 form_to_object

The flow of this methods comes more or less verbatim from the RHTMLO controller.

Returns the object from stash() initialized with the form and request params.

=cut

sub form_to_object {
    my ( $self, $c ) = @_;
    my $form      = $c->stash->{form};
    my $obj       = $c->stash->{object};
    my $obj_meth  = $self->init_object;
    my $form_meth = $self->init_form;

    # id always comes from url but not necessarily from form
    my $id = $c->stash->{object_id};

    # initialize the form with the object's values
    $form->$form_meth($obj);

    # set param values from request
    $form->params( $c->req->params );

    # override form's values with those from params
    # no_clear is important because we already initialized with object
    # and we do not want to undo those mods.
    $form->init_fields( no_clear => 1 );

    # return if there was a problem with any param values
    unless ( $form->validate() ) {
        $c->stash->{error} = $form->error;    # NOT throw_error()
        $c->stash->{template} ||= $self->default_template;    # MUST specify
        return 0;
    }

    # re-set object's values from the now-valid form
    $form->$obj_meth($obj);

    return $obj;
}

=head2 form

Returns a new C<form_class> object every time, initialized with C<form_fields>.

=cut

sub form {
    my ( $self, $c ) = @_;
    my $form_class = $self->form_class;
    my $arg        = { fields => $self->form_fields };
    my $form       = $form_class->new($arg);
    return $form;
}

=head2 end

If the stash() has an 'object' defined,
serializes the object with serialize_object() 
and sticks it in the response body().

If there are any errors, replaces the normal Catalyst debug screen
with contents of $c->error.

=cut

sub end : Private {
    my ( $self, $c ) = @_;
    $c->log->debug('test controller end()') if $c->debug;
    if ( defined $c->stash->{object} ) {
        $c->res->body( $self->serialize_object( $c, $c->stash->{object} ) );
    }
    elsif ( defined $c->stash->{results} ) {
        my @body;
        while ( my $result = $c->stash->{results}->next ) {
            push( @body, $self->serialize_object( $c, $result ) );
        }
        $c->res->body( join( "\n", @body ) );
    }
    if ( $self->has_errors($c) ) {
        my $err = join( "\n", @{ $c->error } );
        $c->log->error($err) if $c->debug;
        $c->res->body($err) unless $c->res->body;
        $c->res->status(500) unless $c->res->status;
        $c->clear_errors;
    }
}

=head2 serialize_object( I<context>, I<object> )

Serializes I<object> for response. Default is just to create hashref
of key/value pairs and send through Data::Dump::dump().

=cut

sub serialize_object {
    my ( $self, $c, $object ) = @_;
    my $fields = $self->form_fields;
    my $serial = {};
    for my $f (@$fields) {
        $serial->{$f} = defined $object->$f ? $object->$f . '' : undef;
    }
    return Data::Dump::dump($serial);
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
