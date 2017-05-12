package Chloro::Role::Form;
BEGIN {
  $Chloro::Role::Form::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

use Chloro::Error::Form;
use Chloro::ErrorMessage;
use Chloro::Result::Field;
use Chloro::Result::Group;
use Chloro::ResultSet;
use Chloro::Types qw( HashRef );
use List::AllUtils qw( all );
use MooseX::Params::Validate qw( validated_list );

sub fields {
    my $self = shift;

    return $self->meta()->fields();
}

sub groups {
    my $self = shift;

    return $self->meta()->groups();
}

sub process {
    my $self = shift;
    my ($params) = validated_list(
        \@_,
        params => { isa => HashRef },
    );

    my %results;
    for my $field ( $self->fields() ) {
        $results{ $field->name() }
            = $self->_result_for_field( $field, $params );
    }

    for my $group ( $self->groups() ) {
        for my $result ( $self->_results_for_group( $group, $params ) ) {
            $results{ $result->prefix() } = $result;
        }
    }

    my @form_errors = map { Chloro::Error::Form->new( message => $_ ) }
        map {
        ref $_
            ? $_
            : Chloro::ErrorMessage->new(
            text     => $_,
            category => 'invalid',
            )
        } $self->_validate_form( $params, \%results );

    return $self->_make_resultset( $params, \%results, \@form_errors );
}

sub _make_resultset {
    my $self        = shift;
    my $params      = shift;
    my $results     = shift;
    my $form_errors = shift;

    return $self->_resultset_class()->new(
        params      => $params,
        results     => $results,
        form_errors => $form_errors,
    );
}

sub _resultset_class {
    return 'Chloro::ResultSet';
}

sub _result_for_field {
    my $self   = shift;
    my $field  = shift;
    my $params = shift;
    my $prefix = shift;

    my @return = $self->_validate_field( $field, $params, $prefix );

    my ( $value, $names, $errors );
    if (@return) {
        ( $value, $names, $errors ) = @return;
    }
    else {
        $names  = [];
        $errors = [];
    }

    return Chloro::Result::Field->new(
        field       => $field,
        param_names => $names,
        errors      => [
            map {
                Chloro::Error::Field->new( field => $field, message => $_ )
                } @{$errors}
        ],
        ( defined $value ? ( value => $value ) : () ),
    );
}

sub _validate_field {
    my $self   = shift;
    my $field  = shift;
    my $params = shift;
    my $prefix = shift;

    my $extractor = $field->extractor();
    my ( $value, @names ) = $self->$extractor( $params, $prefix, $field );

    $value = $field->generate_default( $params, $prefix )
        if !defined $value && $field->has_default();

    # A missing boolean should be treated as false (an unchecked checkbox does
    # not show up in user-submitted parameters).
    if ( _value_is_empty($value) ) {
        if ( $field->type()->is_a_type_of('Bool') ) {
            $value = 0;
        }
        elsif ( ! $field->is_required() ) {
            return;
        }
    }

    my $validator = $field->validator();

    my @errors;
    if ( $field->is_required() && _value_is_empty($value) ) {
        push @errors,
            Chloro::ErrorMessage->new(
            text     => 'The ' . $field->human_name() . ' field is required.',
            category => 'missing',
            );
    }
    else {
        # The validate() method returns false on valid (bah)
        if ( $field->type()->validate($value) ) {

            # XXX - we are ignoring the Moose-returned message for now, because
            # it's not at all end user friendly.
            push @errors,
                Chloro::ErrorMessage->new(
                text => 'The '
                    . $field->human_name()
                    . ' field did not contain a valid value.',
                category => 'invalid',
                );
        }
        elsif ( my $msg
            = $self->$validator( $value, $params, $prefix, $field ) ) {

            push @errors, ref $msg
                ? $msg
                : Chloro::ErrorMessage->new(
                text     => $msg,
                category => 'invalid',
                );
        }
    }

    return ( $value, \@names, \@errors );
}

sub _extract_field_value {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;
    my $field  = shift;

    my $key = join q{.}, grep {defined} $prefix, $field->name();

    return ( $params->{$key}, $key );
}

sub _errors_for_field_value {
    # my $self   = shift;
    # my $value  = shift;
    # my $params = shift;
    # my $prefix = shift;
    # my $field  = shift;

    return;
}

sub _results_for_group {
    my $self   = shift;
    my $group  = shift;
    my $params = shift;

    my $keys = $params->{ $group->repetition_key() };

    return
        map { $self->_result_for_group_by_key( $group, $params, $_ ) }
        grep { defined && length }
        ref $keys ? @{$keys} : $keys;
}

sub _result_for_group_by_key {
    my $self   = shift;
    my $group  = shift;
    my $params = shift;
    my $key    = shift;

    my $prefix = join q{.}, $group->name(), $key;

    my $checker = $group->is_empty_checker();
    return if $self->$checker( $params, $prefix, $group );

    my %results;
    for my $field ( $group->fields() ) {
        $results{ $field->name() }
            = $self->_result_for_field( $field, $params, $prefix );
    }

    return Chloro::Result::Group->new(
        group   => $group,
        key     => $key,
        prefix  => $prefix,
        results => \%results,
    );
}

sub _group_is_empty {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;
    my $group  = shift;

    return all { !( defined $params->{$_} && length $params->{$_} ) }
    map { join q{.}, $prefix, $_->name() } $group->fields();
}

sub _validate_form { }

sub _value_is_empty {
    return defined $_[0] && length $_[0] ? 0 : 1;
}

1;

# ABSTRACT: A role for form classes



=pod

=head1 NAME

Chloro::Role::Form - A role for form classes

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package MyApp::Form::Login;

    # define fields

    my $form = MyApp::Form::Login->new();
    my $resultset = $form->process( params => $params );

=head1 DESCRIPTION

When you write a class or role which C<use>s L<Chloro>, your class or role
will automatically consume this role.

This role implements most of the logic related to process a user's form
submission. You can provide custom versions of some of these methods to change
how this processing is done.

=head1 PUBLIC METHODS

This role provides the following public methods:

=head2 $form->fields()

This returns the ungrouped L<Chloro::Field> objects for the form.

=head2 $form->groups()

This returns the L<Chloro::Group> objects for the form.

=head2 $form->process( params => $params )

This method takes a hash reference of user-submitted form data and processes
it. The hash reference should contain field names (as found in the HTML form)
as keys.

=head1 PRIVATE METHODS

This role also provides a number of private methods. Some are for Chloro's use
only, but some of them are designed so that you can provide your own alternate
implementation.

=head2 $form->_resultset_class()

This returns the name of the class that should be used for the form's
resultset. This defaults to L<Chloro::ResultSet>, but you can provide your own
class.

If you provide a custom resultset class, you should extend
L<Chloro::ResultSet>.

=head2 $form->_validate_form( $params, $results_hash )

This method will be called with two arguments. The first is the raw parameters
passed to C<< $form->process() >>. The second is a hash reference where the
keys are field and group names and the values are L<Chloro::Result::Field> and
L<Chloro::Result::Group> objects.

By default, this is a no-op method, but you can provide your own
implementation to do whole form validation. See L<Chloro::Manual::Intro> for
an example.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

