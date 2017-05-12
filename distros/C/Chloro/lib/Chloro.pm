package Chloro;
BEGIN {
  $Chloro::VERSION = '0.06';
}

use strict;
use warnings;

use Chloro::Field;
use Chloro::Group;
use Chloro::Role::Form;
use Chloro::Trait::Class;
use Moose::Exporter;
use Moose::Util::MetaRole;
use Scalar::Util qw( blessed );

Moose::Exporter->setup_import_methods(
    with_meta => [qw( field group )],
);

sub init_meta {
    shift;
    my %p = @_;

    Moose::Util::MetaRole::apply_metaroles(
        for             => $p{for_class},
        class_metaroles => { class => ['Chloro::Trait::Class'] },
        role_metaroles  => {
            role                 => ['Chloro::Trait::Role'],
            application_to_class => ['Chloro::Trait::Application::ToClass'],
            application_to_role  => ['Chloro::Trait::Application::ToRole'],
        },
    );

    if ( Class::MOP::class_of( $p{for_class} )->isa('Moose::Meta::Class') ) {
        Moose::Util::MetaRole::apply_base_class_roles(
            for   => $p{for_class},
            roles => ['Chloro::Role::Form'],
        );
    }

    return;
}

sub field {
    my $meta = shift;

    my $field = $meta->_make_field(@_);

    # Called inside a call to group()
    if (wantarray) {
        return $field;
    }
    else {
        $meta->add_field($field);
    }

    return;
}

sub group {
    my $meta = shift;

    my @fields;
    push @fields, pop @_ while blessed $_[-1];

    my $group = Chloro::Group->new(
        name   => shift,
        fields => \@fields,
        @_,
    );

    $meta->add_group($group);
}

1;

# ABSTRACT: Form Processing So Easy It Will Knock You Out



=pod

=head1 NAME

Chloro - Form Processing So Easy It Will Knock You Out

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package MyApp::Form::Login;

    use Moose;
    use Chloro;

    field username => (
        isa      => 'Str',
        required => 1,
    );

    field password => (
        isa      => 'Str',
        required => 1,
    );

    ...

    sub login {
        ...

        my $form = MyApp::Form::Login->new();

        my $resultset = $form->process( params => $submitted_params );

        if ( $resultset->is_valid() ) {
            my $login = $resultset->results();

            # Do something with $login->{username} & $login->{password}
        }
        else {
            # Errors that are not specific to just one field
            my @form_errors = $resultset->form_errors();

            # Errors keyed by specific field names
            my %field_errors = $resultset->field_errors();

            # Do something with these errors
        }
    }

=head1 DESCRIPTION

B<This software is still very alpha, and the API may change without warning in
future versions.>

For a walkthrough of all this module's features, see L<Chloro::Manual>.

Chloro is yet another in a long line of form processing libraries. It differs
from other libraries in that it is entirely focused on defining forms in
programmer terms. Field types are Moose type constraints, not HTML widgets
("Str" not "Select").

Chloro is focused on taking a browser's submission, doing basic validation,
and returning a data structure that you can use for further processing.

Out of the box, it does not talk to your database, nor does it know anything
about rendering HTML. However, it is designed so that these features could be
provided by extensions.

=head1 OVERVIEW

Chloro starts with forms. A form is a class which uses Chloro (and Moose).

    package MyApp::Form::User;

    use Moose;
    use Chloro;

    field username => (
        isa      => 'Str',
        required => 1,
    );

In order to validate data against a form, you instantiate a form object and
call C<< $form->process() >>:

    my $form = MyApp::Form::User->new();
    my $resultset = $form->process( params => $params );

The C<$params> are a hash reference where the keys are field names and the
values are field values. Under the hood, you can define a variety of parameter
munging and validation methods, or just use the defaults.

The C<process()> method returns a L<Chloro::ResultSet> object. This object can
tell you whether the submitted parameters were valid. If they weren't, you can
dig into the errors associated with specific fields. You can also define
validations against the form as a whole, and the resultset will have those
errors too.

    if ( $resultset->is_valid() ) {
        ...
    }
    else {
        my $result = $resultset->result_for('username');

        print $_->message() for $result->errors();
    }

If the submission was valid, you can get the results as a hash reference:

    my $hash = $resultset->results();

That's the basic workflow using Chloro.

=head1 MANUAL

If you're new to Chloro, you should start by reading L<Chloro::Manual>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

