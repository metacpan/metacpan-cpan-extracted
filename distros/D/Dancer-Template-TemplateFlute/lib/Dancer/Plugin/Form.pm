package Dancer::Plugin::Form;

use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;

my %forms;

=head1 NAME

Dancer::Plugin::Form - Dancer form handler for Template::Flute template engine

=head1 VERSION

Version 0.0061

=cut

our $VERSION = '0.0061';

=head1 SYNOPSIS

Display template with checkout form:
    
    get '/checkout' => sub {
        my $form;

        $form = form('checkout');
	
        template 'checkout', {form => $form};
    };

Retrieve form input from checkout form:

    post '/checkout' => sub {
        my ($form, $values);

        $form = form('checkout');
        $values = $form->values();
    };

Reset form after completion to prevent old data from
showing up on new form:

    $form = form('checkout');
    $form->reset;

=cut

register form => sub {
    my $name = '';
    my $object;

    if (@_ % 2) {
	$name = shift;
    }
    else {
	$name = 'main';
    }
    
    $object = Dancer::Plugin::Form->new(name => $name, @_);
    
    return $object;
};

register_plugin;

=head1 DESCRIPTION
    
C<Dancer::Plugin::Form> is used for forms with the L<Dancer::Template::TemplateFlute>
templating engine.    

Form fields, values and errors are stored into and loaded from the session key C<form>.

=head1 METHODS

=head2 new

Creates C<Dancer::Plugin::Form> object.
    
=cut
    
sub new {
    my ($class, $self, %params);

    $class = shift;

    $self = {fields => [], errors => [], valid => undef, pristine => 1};
    bless $self;

    %params = @_;

    if (exists $params{name}) {
	$self->{name} = $params{name};
    }
    else {
	$self->{name} = 'main';
    }

    if (exists $params{action}) {
	$self->action($params{action});
    }

    # try to load form data from session
    $self->from_session();
    
    return $self;
}

=head2 name

Get form name:

    $form->name

=cut

sub name {
    my $self = shift;

    return $self->{name};
}

=head2 action

Set form action:
    
   $form->action('/checkout');

Get form action:

   $action = $form->action;

=cut
    
sub action {
    my ($self, $action) = @_;

    if ($action) {
	$self->{action} = $action;
    }

    return $self->{action};
}

=head2 fill

Fill form values:

    $form->fill({username => 'racke', email => 'racke@linuxia.de'});

=cut

sub fill {
    my ($self);

    $self = shift;

    if (@_) {
	if (@_ == 1) {
	    %{$self->{values}} = %{$_[0]};
	}
	else {
	    %{$self->{values}} = @_;
	}
    }

    return $self->{values};
}

=head2 values

Get form values as hash reference:

    $values = $form->values;

Set form values from a hash reference:

    $values => $form->values(ref => \%input);

=cut
    
sub values {
    my ($self, $scope, $data) = @_;
    my (%values, $params, $save);


    if (! defined $scope) {
	$params = params('body');
	$save = 1;
    }
    elsif ($scope eq 'session') {
	$params = $self->{values};
    }
    elsif ($scope eq 'body' || $scope eq 'query' ) {
        $params = params($scope);
	$save = 1;
    }
    elsif ($scope eq 'ref') {
        $params = $data;
        $save = 1;
    }
    else {
	$params = '';
    }

    for my $f (@{$self->{fields}}) {
	$values{$f} = $params->{$f};

	if ($save && defined $values{$f}) {
	    # tidy form input first
	    $values{$f} =~ s/^\s+//;
	    $values{$f} =~ s/\s+$//;
	}
    }

    if ($save) {
	$self->{values} = \%values;
	return \%values;
    }

    return \%values;
}

=head2 valid

Determine whether form values are valid:

    $form->valid();

Return values are 1 (valid), 0 (invalid) or
undef (unknown).

Set form status to "valid":
    
    $form->valid(1);

Set form status to "invalid":
    
    $form->valid(0);

The form status automatically changes to
"invalid" when errors method is called with
error messages.
    
=cut

sub valid {
    my $self = shift;
    my $valid = shift;

    if (defined $valid) {
	Dancer::Logger::debug("Setting valid for $self->{name} to $valid.");
	$self->{valid} = $valid;

	# record changes in user's session
	$self->to_session;
    }

    return $self->{valid};
}

=head2 errors
    
Set form errors:
    
   $form->errors({username => 'Minimum 8 characters',
                  email => 'Invalid email address'});

Get form errors as hash reference:

   $errors = $form->errors;

=cut
    
sub errors {
    my ($self, $errors) = @_;
    my ($key, $value, @buf);
    
    if ($errors) {
	if (ref($errors) eq 'HASH') {
	    while (($key, $value) = each %$errors) {
		push @buf, {name => $key, label => $value};
	    }
	    $self->{errors} = \@buf;
	}

	$self->{valid} = 0;
    }

    return $self->{errors};
}

=head2 errors_hashed

Returns form errors as array reference filled with a hash reference
for each error.

=cut

sub errors_hashed {
    my ($self) = @_;
    my (@hashed);

    for my $err (@{$self->{errors}}) {
	push (@hashed, {name => $err->[0], label => $err->[1]});
    }

    return \@hashed;
}

=head2 failure

Indicates form failure by passing form errors.

    $form->failure(errors => {username => 'Minimum 8 characters',
                              email => 'Invalid email address'});

You can also set a route for redirection:

    return $form->failure(errors => {username => 'Minimum 8 characters'},
        route => '/account');

Passing parameters for the redirection URL is also possible:

    return $form->failure(errors => {username => 'Minimum 8 characters'},
        route => '/account',
        params => {layout => 'mobile'});

Please ensure that you validate input submitted by an user before
adding them to the C<params> hash.

=cut

sub failure {
    my ($self, %args) = @_;

    $self->{errors} = $args{errors};

    # update session data about this form
    $self->to_session();

    if (ref($args{errors}) eq 'ARRAY') {
        $self->{errors} = {@{$args{errors}}};
    }

    session(form_errors => '<ul>' . join('', map {"<li>$_</li>"} CORE::values %{$self->{errors} || {}}) . '</ul>');

    session(form_data => $args{data});

    if ($args{route}) {
        redirect uri_for($args{route}, $args{params});
    }

    return;
}

=head2 fields

Set form fields:
    
    $form->fields([qw/username email password verify/]);

Get form fields:

    $fields = $form->fields;

=cut
    
sub fields {
    my ($self);

    $self = shift;

    if (@_) {
	$self->{fields} = shift;
    }

    return $self->{fields};    
}

=head2 pristine

Determines whether a form is pristine or not.

This can be used to fill the form with default
values and suppress display of errors.

A form is pristine until it receives form
field input from the request or out of the
session.

=cut

sub pristine {
    return $_[0]->{pristine};
};

=head2 reset

Reset form information (fields, errors, values, valid) and
updates session accordingly.

=cut

sub reset {
    my $self = shift;

    $self->{fields} = [];
    $self->{errors} = [];
    $self->{values} = {};
    $self->{valid} = undef;
    $self->{pristine} = 1;
    $self->to_session;

    return 1;
}

=head2 from_session

Loads form data from session key 'form'.
Returns 1 if session contains data for this form, 0 otherwise.

=cut

sub from_session {
    my ($self) = @_;
    my ($forms_ref, $form);

    if ($forms_ref = session('form')) {
        if (exists $forms_ref->{$self->{name}}) {
            $form = $forms_ref->{$self->{name}};

            $self->{fields} = $form->{fields} || [];
            $self->{errors} = $form->{errors} || [];
            $self->{values} = $form->{values} || {};
            $self->{valid} = $form->{valid};

            while (my ($key, $value) = each %{$self->{values}}) {
                if (defined $value) {
                    $self->{pristine} = 0;
                    last;
                }
            }

            return 1;
        }
    }

    return 0;
}

=head2 to_session

Saves form name, form fields, form values and form errors into 
session key 'form'.

=cut

sub to_session {
    my ($self) = @_;
    my ($forms_ref);

    # get current form information from session
    $forms_ref = session 'form';

    # update our form
    $forms_ref->{$self->{name}} = {name => $self->{name}, 
				   fields => $self->{fields},
				   errors => $self->{errors},
				   values => $self->{values},
				   valid => $self->{valid},
    };
    
    # update form information
    session 'form' => $forms_ref;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-template-templateflute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Template-TemplateFlute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Form


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Template-TemplateFlute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Template-TemplateFlute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Template-TemplateFlute>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Template-TemplateFlute/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::Form
