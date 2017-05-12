package Dancer2::Plugin::TemplateFlute::Form;

use Carp;
use Hash::MultiValue;
use Types::Standard -types;
use Moo;
use namespace::clean;

=head1 NAME

Dancer2::Plugin::TemplateFlute::Form - form object for Template::Flute

=cut

my $_coerce_to_hash_multivalue = sub {
    if ( !defined $_[0] ) {
        Hash::MultiValue->new;
    }
    elsif ( ref( $_[0] ) eq 'Hash::MultiValue' ) {
        $_[0];
    }
    elsif ( ref( $_[0] ) eq 'HASH' ) {
        Hash::MultiValue->from_mixed( $_[0] );
    }
    else {
        croak "Unable to coerce to Hash::MultiValue";
    }
};

#
# attributes
#

has action => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
    writer    => 'set_action',
);

has errors => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['Hash::MultiValue'],
    default => sub { Hash::MultiValue->new },
    coerce  => $_coerce_to_hash_multivalue,
    clearer => 1,
    writer  => '_set_errors',
);

sub add_error {
    my $self = shift;
    $self->errors->add(@_);
}

sub set_error {
    my $self = shift;
    $self->errors->set(@_);
}

sub set_errors {
    my $self = shift;
    $self->_set_errors(@_);
}

after 'add_error', 'set_error', 'set_errors' => sub {
    $_[0]->set_valid(0);
};

has fields => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [Str],
    default => sub { [] },
    clearer => 1,
    writer  => 'set_fields',
);

has log_cb => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has name => (
    is      => 'ro',
    isa     => Str,
    default => 'main',
);

has pristine => (
    is      => 'ro',
    isa     => Defined & Bool,
    default => 1,
    writer  => 'set_pristine',
);

has session => (
    is       => 'ro',
    isa      => HasMethods [ 'read', 'write' ],
    required => 1,
);

# We use a private writer since we want to have to_session called whenever
# the public set_valid method is called but we also have a need to be
# able to update this attribute without writing the form back to the session.
has valid => (
    is      => 'ro',
    isa     => Bool,
    clearer => 1,
    writer  => '_set_valid',
);

sub set_valid {
    my ( $self, $value ) = @_;
    $self->_set_valid($value);
    $self->log( "debug", "Setting valid for form ",
        $self->name, " to $value." );
    $self->to_session;
}

has values => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['Hash::MultiValue'],
    default => sub { Hash::MultiValue->new },
    coerce  => $_coerce_to_hash_multivalue,
    trigger => sub { $_[0]->set_pristine(0) if $_[1]->keys },
    clearer => 1,
    writer  => 'fill',
);

# in case fill gets passed a list then convert to hashref
around fill => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $values = @_ && ref( $_[0] ) ? $_[0] : {@_};
    $orig->( $self, $values );
};

#
# methods
#

sub errors_hashed {
    my $self = shift;
    my @hashed;

    $self->errors->each(
        sub { push @hashed, +{ name => $_[0], label => $_[1] } } );

    return \@hashed;
}

sub from_session {
    my ($self) = @_;

    $self->log( debug => "Reading form ", $self->name, " from session");

    if ( my $forms_ref = $self->session->read('form') ) {
        if ( exists $forms_ref->{ $self->name } ) {
            my $form = $forms_ref->{ $self->name };

            # set_valid causes write back to session so use private
            # method instead. Also set_errors causes set_valid to be
            # called so use private method there too.
            $self->set_action( $form->{action} ) if $form->{action};
            $self->set_fields( $form->{fields} ) if $form->{fields};
            $self->_set_errors( $form->{errors} ) if $form->{errors};
            $self->fill( $form->{values} )       if $form->{values};
            $self->_set_valid( $form->{valid} ) if defined $form->{valid};

            return 1;
        }
    }
    return 0;
}

sub log {
    my ($self, $level, @message) = @_;
    $self->log_cb->($level, join('',@message)) if $self->has_log_cb;
}

sub reset {
    my $self = shift;
    $self->clear_fields;
    $self->clear_errors;
    $self->clear_values;
    $self->clear_valid;
    $self->set_pristine(1);
    $self->to_session;
}

sub to_session {
    my $self = shift;
    my ($forms_ref);

    $self->log( debug => "Writing form ", $self->name, " to session");

    # get current form information from session
    $forms_ref = $self->session->read('form');

    # update our form
    $forms_ref->{ $self->name } = {
        action => $self->action,
        name   => $self->name,
        fields => $self->fields,
        errors => $self->errors->mixed,
        values => $self->values->mixed,
        valid  => $self->valid,
    };

    # update form information
    $self->session->write( form => $forms_ref );
}

=head1 ATTRIBUTES

=head2 name

The name of the form.

Defaults to 'main',

=head2 action

The form action.

=over

=item writer: set_action

=item predicate: has_action

=back

=head2 errors
    
Errors stored in a L<Hash::MultiValue> object.

Get form errors:

   $errors = $form->errors;

=over

=item writer: set_errors

Set form errors (this will overwrite all existing errors):
    
    $form->set_errors(
        username => 'Minimum 8 characters',
        username => 'Must contain at least one number',
        email    => 'Invalid email address',
    );

=item clearer: clear_errors

=back

B<NOTE:> Avoid using C<< $form->errors->add() >> or C<< $form->errors->set() >>
since doing that means that L</valid> does not automatically get set to C<0>.
Instead use one of L</add_error> or L</set_error> methods.

=head2 fields

Get form fields:

    $fields = $form->fields;

=over

=item writer: set_fields

    $form->set_fields([qw/username email password verify/]);

=item clearer: clear_fields

=back

=head2 log_cb

A code reference that can be used to log things. Signature must be like:

  $log_cb->( $level, $message );

Logging is via L</log> method.

=over

=item predicate: has_log_cb

=back

=head2 pristine

Determines whether a form is pristine or not.

This can be used to fill the form with default values and suppress display
of errors.

A form is pristine until it receives form field input from the request or
out of the session.

=over

=item writer: set_pristine

=back

=head2 session

A session object. Must have methods C<read> and C<write>.

Required.

=head2 valid

Determine whether form values are valid:

    $form->valid();

Return values are 1 (valid), 0 (invalid) or C<undef> (unknown).

=over

=item writer: set_valid

=item clearer: clear_valid

=back

The form status automatically changes to "invalid" when L</errors> is set
or either L</add_errors> or L</set_errors> are called.
    
=head2 values

Get form values as hash reference:

    $values = $form->values;

=over

=item writer: fill

Fill form values:

    $form->fill({username => 'racke', email => 'racke@linuxia.de'});

=item clearer: clear_values

=back

=head1 METHODS

=head2 add_error

Add an error:

    $form->add_error( $key, $value [, $value ... ]);

=head2 errors_hashed

Returns form errors as array reference filled with hash references
for each error.

For example these L</errors>:

    { username => 'Minimum 8 characters',
      email => 'Invalid email address' }

will be returned as:

    [
        { name => 'username', value => 'Minimum 8 characters'  },
        { name => 'email',    value => 'Invalid email address' },
    ]

=head2 from_session

Loads form data from session key C<form>.
Returns 1 if session contains data for this form, 0 otherwise.

=head2 log $level, @message

Log message via L</log_cb>.

=head2 reset

Reset form information (fields, errors, values, valid) and
updates session accordingly.

=head2 set_error

Set a specific error:

    $form->set_error( $key, $value [, $value ... ]);

=head2 to_session

Saves form name, form fields, form values and form errors into 
session key C<form>.


=head1 AUTHORS

Original Dancer plugin by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Initial port to Dancer2 by:

Evan Brown (evanernest), C<< <evan at bottlenose-wine.com> >>

Rehacking to Dancer2's plugin2 and general rework:

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 BUGS

Please report any bugs or feature requests via GitHub issues:
L<https://github.com/interchange/Dancer2-Plugin-TemplateFlute/issues>.

We will be notified, and then you'll automatically be notified of progress
on your bug as we make changes.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
