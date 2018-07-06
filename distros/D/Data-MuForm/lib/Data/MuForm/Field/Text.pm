package Data::MuForm::Field::Text;
# ABSTRACT: Text field
use Moo;
extends 'Data::MuForm::Field';
use List::Util ('all');

has 'size' => ( is => 'rw', default => 0 );
has 'maxlength' => ( is => 'rw' );
has 'minlength' => ( is => 'rw', default => '0' );

sub build_input_type { 'text' }

our $class_messages = {
    'text_maxlength' => 'Field should not exceed {maxlength} characters. You entered {length}',
    'text_minlength' => 'Field must be at least {minlength} characters. You entered {length}',
    'multiple_values_disallowed' => 'Field must contain a single value',
};

sub get_class_messages {
    my $self = shift;
    my $messages = {
        %{ $self->next::method },
        %$class_messages,
    };
    return $messages;
}

sub base_render_args {
    my $self = shift;
    my $args = $self->next::method(@_);
    $args->{element_attr}->{size} = $self->size if $self->size;
    $args->{element_attr}->{maxlength} = $self->maxlength if $self->maxlength;
    $args->{element_attr}->{minlength} = $self->minlength if $self->minlength;
    return $args;
}

sub normalize_input {
    my $self = shift;

    my $input = $self->input;
    if ( ref $input eq 'ARRAY' && ! $self->multiple ) {
        if ( scalar @$input == 0 ) {
            $self->input('');
        }
        elsif (  all { $_ eq $input->[0] } @$input ) {
            $self->input($input->[0]);
        }
        else {
            $self->add_error( $self->get_message('multiple_values_disallowed') );
        }
    }
}

sub validate {
    my $self = shift;

    return unless $self->next::method;
    my $value = $self->value;
    # Check for max length
    if ( my $maxlength = $self->maxlength ) {
        return $self->add_error( $self->get_message('text_maxlength'),
            maxlength => $maxlength, length => length $value, field_label =>$self->loc_label )
            if length $value > $maxlength;
    }

    # Check for min length
    if ( my $minlength = $self->minlength ) {
        return $self->add_error(
            $self->get_message('text_minlength'),
            minlength => $minlength, length => length $value, field_label => $self->loc_label )
            if length $value < $minlength;
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Text - Text field

=head1 VERSION

version 0.05

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
