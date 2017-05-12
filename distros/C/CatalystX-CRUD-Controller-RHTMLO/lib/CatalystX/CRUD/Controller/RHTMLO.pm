package CatalystX::CRUD::Controller::RHTMLO;
use strict;
use base qw( CatalystX::CRUD::Controller );
use Carp;
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.20';

=head1 NAME

CatalystX::CRUD::Controller::RHTMLO - Rose::HTML::Objects CRUD controller

=head1 SYNOPSIS

 see CatalystX::CRUD::Controller

=head1 DESCRIPTION

This is an implementation of CatalystX::CRUD::Controller
for Rose::HTML::Objects. It supercedes Catalyst::Controller::Rose for
basic CRUD applications.

=cut

=head1 METHODS

The following methods are new or override base methods.

=cut

=head2 form( I<context> )

Returns an instance of config->{form_class}. 
A single form object is instantiated and cached in the controller object.
The form's clear() method is called before returning.
I<context> object is set in forms's app() method.

B<NOTE:> The form is cleared only the B<first time>
form() is called in each request cycle.
This is B<different> than the behaviour described in 
CatalystX::CRUD::Controller.

=cut

sub form {
    my ( $self, $c ) = @_;
    $self->{_form} ||= $self->form_class->new( app => $c );
    $self->{_form}->app($c) unless defined $self->{_form}->app;
    $self->{_form}->clear
        unless $self->{_form}->app->stash->{_form_called}
            ->{ $self->action_namespace }++;
    return $self->{_form};
}

=head2 field_names( I<context> )

Returns an array ref of the field names in form.

=cut

sub field_names {
    my ( $self, $c ) = @_;
    $self->throw_error("context required") unless defined $c;
    return $self->form($c)->field_names;
}

=head2 all_form_errors

Convenience method for aggregating all form errors. Returns a single
scalar string.

=cut

sub all_form_errors {
    my ( $self, $form ) = @_;
    my @err = ( $form->error );
    for my $f ( $form->fields ) {
        push( @err, $f->name . ': ' . $f->error ) if $f->error;
    }
    return join( "\n", grep {defined} @err );
}

=head2 form_to_object( I<context> )

Overrides base method.

=cut

sub form_to_object {
    my ( $self, $c ) = @_;

    my $form      = $c->stash->{form};
    my $obj       = $c->stash->{object};
    my $obj_meth  = $self->init_object;
    my $form_meth = $self->init_form;

    # id always comes from url but not necessarily from form,
    # but in either case, $obj should already have %pk set
    # since it was used in fetch()
    my $id = $c->stash->{object_id};
    my %pk = $self->get_primary_key( $c, $id );

    # initialize the form with the object's values
    # TODO this might not work if the delegate() does not have
    # 1-to-1 mapping of form fields to object methods.
    $form->$form_meth($obj);

    # set param values from request.
    $form->params( $c->req->params );

    # override form's values with those from params
    # no_clear is important because we already initialized with object
    # and we do not want to undo those mods.
    $form->init_fields( no_clear => 1 );

    # return if there was a problem with any param values
    unless ( $form->validate() ) {
        my $err = $self->all_form_errors($form);
        $c->stash( error => $err );    # NOT throw_error()
        $c->log->debug("RHTMLO: form error:\n$err\n")
            if $c->debug;
        $c->stash->{template} ||= $self->default_template;    # MUST specify
        return 0;
    }

    # re-set object's values from the now-valid form
    # TODO this might not work if the delegate() does not have
    # 1-to-1 mapping of form fields to object methods.
    # this is same objection as $form_method call above
    $form->$obj_meth($obj);

    return $obj;
}

=head2 do_search( I<context>, I<arg> )

Makes form values sticky then calls the base do_search() method with 
next::method().

=cut

sub do_search {
    my ( $self, $c, @arg ) = @_;

    # make form sticky
    $c->stash->{form} ||= $self->form($c);

    # if we have no input, just return for initial search
    if ( !@arg && !$c->req->param && $c->action->name eq 'search' ) {
        $c->log->debug("no input to search. return") if $c->debug;

        # must clear explicitly since this is a new search
        # and form may have been initialized elsewhere
        $c->stash->{form}->clear;
        $c->log->debug("rhtmlo form cleared") if $c->debug;
        return;
    }

    $c->stash->{form}->params( $c->req->params );
    $c->stash->{form}->init_fields();

    return $self->next::method( $c, scalar $self->field_names($c), @arg );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-controller-rhtmlo at rt.cpan.org>, 
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD-Controller-RHTMLO>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD::Controller::RHTMLO

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD-Controller-RHTMLO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD-Controller-RHTMLO>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-Controller-RHTMLO>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD-Controller-RHTMLO>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

