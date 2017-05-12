package Data::MuForm::Field::Compound;
# ABSTRACT: field consisting of subfields

use Moo;
extends 'Data::MuForm::Field';
with 'Data::MuForm::Fields';
use Data::MuForm::Meta;
use Types::Standard ('Bool', 'ArrayRef');


sub is_compound {1}
has 'obj' => ( is => 'rw', clearer => 'clear_obj' );
has 'primary_key' => ( is => 'rw', isa => ArrayRef,
    predicate => 'has_primary_key', );

has '+field_namespace' => (
    default => sub {
        my $self = shift;
        return $self->form->field_namespace
            if $self->form && $self->form->field_namespace;
        return [];
    },
);

sub BUILD {
    my $self = shift;
    $self->build_fields;
}

# this is for testing compound fields outside
# of a form
sub test_field_validate {
    my $self = shift;
    unless( $self->form ) {
        if( $self->has_input ) {
            $self->fill_from_params( $self->input );
        }
        else {
            $self->fill_from_fields();
        }
    }
    $self->field_validate;
    unless( $self->form ) {
        foreach my $err_fld (@{$self->error_fields}) {
            $self->push_error($err_fld->all_errors);
        }
    }
}

around 'fill_from_object' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $obj ) = @_;
    $self->obj($obj) if $obj;
    $self->$orig(@_);
};

after 'clear_data' => sub {
    my $self = shift;
    $self->clear_obj;
};

around 'fill_from_params' => sub {
    my $orig = shift;
    my $self = shift;
    my ( $input, $exists ) = @_;
    if ( !$input && !$exists ) {
        return $self->fill_from_fields();
    }
    else {
        return $self->$orig(@_);
    }
};

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{is_compound} = 1;
    return $args;
}
sub render {
  my ( $self, $rargs ) = @_;
  my $render_args = $self->get_render_args(%$rargs);
  return $self->renderer->render_compound($render_args, $self->fields);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Compound - field consisting of subfields

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This field class is designed as the base (parent) class for fields with
multiple subfields. An example is L<Data::MuForm::Field::CompoundDateTime>.

A compound parent class requires the use of sub-fields prepended
with the parent class name plus a dot

   has_field 'birthdate' => ( type => 'DateTime' );
   has_field 'birthdate.year' => ( type => 'Year' );
   has_field 'birthdate.month' => ( type => 'Month' );
   has_field 'birthdate.day' => ( type => 'MonthDay');

If all validation is performed in the parent class so that no
validation is necessary in the child classes, then the field class
'Nested' may be used.

The array of subfields is available in the 'fields' array in
the compound field:

   $form->field('birthdate')->fields

Error messages will be available in the field on which the error
occurred. You can access 'error_fields' on the form or on Compound
fields (and subclasses, like Repeatable).

The process method of this field runs the process methods on the child fields
and then builds a hash of these fields values.  This hash is available for
further processing by L<Data::MuForm::Field/actions> and the validate method.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
