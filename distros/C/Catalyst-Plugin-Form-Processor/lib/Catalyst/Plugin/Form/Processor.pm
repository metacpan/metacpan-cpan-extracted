package Catalyst::Plugin::Form::Processor;
$Catalyst::Plugin::Form::Processor::VERSION = '1.140270';
use Moose::Role;
use Class::Load 0.20;
use HTML::FillInForm;
use Module::Find;
use Scalar::Util;




# ABSTRACT: Use Form::Processor with Catalyst


sub form {
    my ( $c, $args_ref, $form_name ) = @_;


    # Determine the form package name
    my $package;
    if ( defined $form_name ) {

        $package
            = $form_name =~ s/^\+//
            ? $form_name
            : ref( $c ) . '::Form::' . $form_name;
    }
    else {
        $package = $c->action->class;
        $package =~ s/::C(?:ontroller)?::/::Form::/;
        $package .= '::' . ucfirst( $c->action->name );
    }

    Class::Load::load_class( $package );


    # Single argument to Form::Processor->new means it's an item id or object.
    # Hash references must be turned into lists.

    my %args;
    if ( defined $args_ref ) {
        if ( ref $args_ref eq 'HASH' ) {
            %args = %{$args_ref};
        }
        elsif ( Scalar::Util::blessed( $args_ref ) ) {
            %args = (
                item    => $args_ref,
                item_id => $args_ref->id,
            );
        }
        else {
            %args = ( item_id => $args_ref );
        }
    }

    # Set schema name -- mostly for DBIC

    if ( $package->can( 'schema' ) ) {
        unless ( exists $args{schema} ) {
            my $schema_name = $c->config->{form}{model_name}
                || $c->stash->{model_name};


            $args{schema} = $c->model( $schema_name )->schema
                if defined $schema_name;
        }
    }

    $args{user_data}{context} = $c;

    # Since $c holds a reference to the form and the form holds
    # a reference to the context must weaken.
    Scalar::Util::weaken( $args{user_data}{context} );


    return $c->stash->{form} = $package->new( %args );

} ## end sub form



sub validate_form {
    my ( $c, @rest ) = @_;

    my $form = $c->form( @rest );

    return
        $c->form_posted
        && $form->validate( $c->req->parameters );

}




sub update_from_form {
    my ( $c, @rest ) = @_;

    my $form = $c->form( @rest ) || return;

    return
        $c->form_posted
        && $form->update_from_form( $c->req->parameters );

}


sub form_posted {
    my $c = shift;

    return $c->req->method eq 'POST' || $c->req->method eq 'PUT';
}


# Used to override finalize, but that's not called in a redirect.
# TODO: add support for multiple forms on a page (and multiple forms
# in the stash).
#
# And better, simply remove this.

before 'finalize' => sub {
    my $c = shift;


    my $form = $c->stash->{form} || return;


    # Disabled in configuration
    return if $c->config->{form}{no_fillin};


    return if $c->res->status != 200;

    my $params = $form->fif;

    return unless ref $params && %{$params};

    return unless defined $c->response->{body};

    $c->log->debug( 'Filling in form with HTML::FillInForm' ) if $c->debug;


    # Run FillInForm
    $c->response->output(
        HTML::FillInForm->new->fill(
            scalarref => \$c->response->{body},
            fdat      => $params,
        ) );

    return;

};


after 'setup_finalize' => sub {
    my $c = shift;

    my $config = $c->config->{form} || {};

    return unless $config->{pre_load_forms};

    my $debug = $config->{debug};

    my $name_space = $c->config->{form_name_space} || $c->config->{name} . '::Form';
    my @namespace = ref $name_space eq 'ARRAY' ? @{$name_space} : ( $name_space );


    for my $ns ( @namespace ) {
        warn "Searching for forms in the [$ns] namespace\n" if $debug;

        for my $form ( Module::Find::findallmod( $ns ) ) {

            warn "Loading form module [$form]\n" if $debug;

            Class::Load::load_class( $form );

            # Should we pre-load the form's fields by attempting
            # to init the form?   May fail if the profile method
            # assumes it is running per request instead of at load time.

            next unless $config->{pre_load_fields};

            eval { $form->load_form; 1 }
                || die "Failed load_module for form module [$form]: $@";
        }
    }

    return;
};




no Moose::Role;

1;






__END__
=pod

=head1 NAME

Catalyst::Plugin::Form::Processor - Use Form::Processor with Catalyst

=head1 VERSION

version 1.140270

=head1 SYNOPSIS

In the Catalyst application base class:

    use Catalyst;

    with 'Catalyst::Plugin::Form::Processor';

    __PACKAGE__->config->{form} = {
        no_fillin       => 1,  # Don't auto-fill forms with HTML::FillInForm
        pre_load_forms  => 1,  # Try and load forms at setup time
        form_name_space => 'My::Forms',
        debug           => 1,   # Show forms pre-loaded.
        schema_class    => 'MyApp::DB',
    };

Then in a controller:

    package App::Controller::User;
    use strict;
    use warnings;
    use base 'Catalyst::Controller';

    # Create or edit
    sub edit : Local {
        my ( $self, $c, $user_id ) = @_;

        # Validate and insert/update database
        return unless $c->update_from_form( $user_id );

        # Form validated.

        $c->stash->{first_name} = $c->stash->{form}->value( 'first_name' );
    }

    # Form that doesn't update database
    sub profile : Local {
        my ( $self, $c ) = @_;

        # Redisplay form
        return unless $c->validate_form;

        # Form validated.

        $c->stash->{first_name} = $c->stash->{form}->value( 'first_name' );
    }


    # Use HTML::FillInForm to populate a form:
    $c->stash->{fillinform} = $c->req->parameters;

=head1 DESCRIPTION

"This distribution should not exist" - https://rt.cpan.org/Ticket/Display.html?id=40733

This plugin adds methods to make L<Form::Processor> easy to use with Catalyst.
The plugin uses the current action name to find the form module, creates the
form object and stuffs it into the stash, and passes the Catalyst request
parameters to the form for validation.

The method C<< $c->update_from_form >> is used when the form inherits from a
Form::Processor model class (e.g. L<Form::Processor::Model::CDBI>) which will
load a form's current values from a database and update/create rows in the
database from a posted form.

C<< $c->validate_form >> simply validates the form and you must then decide
what to do with the validated data.  This is useful when the posted data
will be used for something other than updating a row in a database.

The C<< $c->form >> method will create an instance of your form class.
Both C<< $c->update_from_form >> and C<< $c->validate_form >> call this method
to load the form for you.  So, you generally don't need to call this directly.

Forms are assumed to be in the $App::Form name space.  But, that's just
the default.  This can be overridden with the C<form_name_space> option.

The form object is stored in the stash as C<< $c->stash->{form} >>.  Templates
can use this to access for form.

In addition, this Plugin use HTML-FillInForm to populate the form.  Typically,
this data will come automatically form the current values in the form object,
but can be overridden by populating the stash with a hash reference:

    $c->stash->{fillinform} = $c->req->parameters;

Note that this can also be used to populate forms not managed by Form::Processor.
Currently, only one form per page is supported.

=head1 METHODS

=head2 form ( $item_or_args_ref, $form_name );

    $form = $c->form;
    $form = $c->form( $user_id );
    $form = $c->form( $args_ref );
    $form = $c->form( $args_ref, $form_name );

Generates a form object, populates the stash "form" and returns the
form object.  This method is typically not used.  Use
L<update_from_form> or L<validate_form> instead.

The form will be require()ed at run time so the form does not need to be
explicitly loaded by your application. The form is expected to be in the
App::Form name space, but that can be overridden.

But, it might be worth loading the modules at compile time if you
have a lot of modules to save on memory (e.g. under mod_perl).
See L</pre_load_forms> below.

The Catalyst context (C<$c>) is made available to the form
via the form's user data attribute.  In the form you may do:

    my $c = $form->user_data->{context};

Pass:
    $item_or_args_ref. This can be
        scalar:
            it will be assumed to be the id of the row to edit
        hash ref:
            assumed to be a list of options and will be passed
            as a list to Form::Processor->new.
        object:
            and will be set as the item and item_id is set by
            calling the "id" method on this object.  If id
            is not the correct method then pass a hash reference
            instead.

    If $form_name is not provided then will use the current controller
    class and the action for the form name.  If $form_name is defined then
    it is appended to C<$App::Form::>.  A plus sign can be included
    to avoid prefixing the form name.


    package MyApp::Controller::Foo::Bar
    sub edit : Local {

        # MyAPP::Form::Foo::Bar::Edit->new
        # Note the upper case -- ucfirst is used
        my $form = $c->form;

        # MyAPP::Form::Login::User->new
        my $form = $c->form( $args_ref, 'Login::User' );

        # External form Other::Form->new
        my $form = $c->form( $args_ref, '+Other::Form' );

Returns:
    Sets $c->{form} by calling new on the form object.
    That value is also returned.

=head2 validate_form

    return unless $c->validate_form;

This method passes the request parameters to
the form's C<validate> method and returns true
if all fields validate.

This is the method to use if you are not using
a Form::Processor::Model class to automatically
update or insert a row into the database.

=head2 update_from_form

This combines common actions on CRUD tables.
It replaces, say:

    my $form = $c->form( $item );

    return unless $c->form_posted
        && $form->update_from_form( $c->req->parameters );

with

    $c->update_from_form( $item )

For this to work your form should inherit from a Form::Processor::Model
class (e.g. see L<Form::Processor::Model::CDBI>), or your form must
have an C<update_from_form()> method (which calls validate).

=head2 form_posted

This returns true if the request was a post request.
This could be replace with a method that does more extensive
checking, such as validating a form token to prevent double-posting
of forms.

=head2 finalize

Automatically fills in a form if $form variable is found.
This can be disabled by setting

    $c->config->{form}{no_fillin};

=head2 setup

If the C<pre_load_forms> configuration options is set will search for forms in
the name space provided by the C<form_name_space> configuration list or by
default the application name space with the suffix ::Form appended (e.g.
MyApp::Form).

=head1 EXTENDED METHODS

=head1 CONFIGURATION

Configuration is specified within C<< MyApp->config->{form}} >>.
The following options are available:

=over 4

=item no_fillin

Don't use use L<HTML::FillInForm> to populate the form data.

=item pre_load_forms

It this is true then will pre-load all modules in the MyApp::Form name space
during setup.  This works by requiring the form module and loading associated
form fields.  The form is not initialized so any fields dynamically loaded may
not be included.

This is useful in a persistent environments like mod_perl or FastCGI.

=item form_name_space

This is a list of name spaces where to look for forms to pre load.  It defaults
to the application name with the ::Form suffix (e.g. MyApp::Form).  Note, this
DOES NOT currently change where C<< $c->form >> looks for form modules.
Not quite sure why that's not implemented yet.

=item model_name

Defines the default model class.  To play nicely with
L<Form::Processor::Model::DBIC> will set "schema" option when
creating a new Form if this value is set.

Basically does:

    $schema = $c->model( $model_name )->schema;

Can be overridden by a stash element of the same name.

=item debug

If true will write brief debugging information when running setup.

=back

=head1 See also

L<Form::Processor>

L<Form::Processor::Model::CDBI>

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by iParadigms, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

