package Data::MuForm::Field::Integer;
# ABSTRACT: validate an integer value

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Field::Text';

has '+html5_input_type' => ( default => 'number' );
has '+size' => ( default => 8 );

has 'range_start' => ( is => 'rw' );
has 'range_end' => ( is => 'rw' );

our $class_messages = {
    'integer_needed' => 'Value must be an integer',
    'range_too_low'   => 'Value must be greater than or equal to [_1]',
    'range_too_high'  => 'Value must be less than or equal to [_1]',
    'range_incorrect' => 'Value must be between [_1] and [_2]',
};

sub get_class_messages {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub validate {
    my $field = shift;

    my $value = $field->value;
    return 1 unless defined $value;

    $value =~ s/^\+//;
    $field->value($value);

    unless ( $value =~ /^-?[0-9]+$/ ) {
        $field->add_error($field->get_message('integer_needed'));
    }

    my $low  = $field->range_start;
    my $high = $field->range_end;

    if ( defined $low && defined $high ) {
        return
            $value >= $low && $value <= $high ? 1 :
              $field->add_error( $field->get_message('range_incorrect'), low => $low, high => $high );
    }

    if ( defined $low ) {
        return
            $value >= $low ? 1 :
              $field->add_error( $field->get_message('range_too_low'), low => $low );
    }

    if ( defined $high ) {
        return
            $value <= $high ? 1 :
              $field->add_error( $field->get_message('range_too_high'), high => $high );
    }

    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Integer - validate an integer value

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This accepts a positive or negative integer.  Negative integers may
be prefixed with a dash.  By default a max of eight digits are accepted.
Widget type is 'text'.

If form has 'is_html5' flag active it will render <input type="number" ... />
instead of type="text"

The 'range_start' and 'range_end' attributes may be used to limit valid numbers.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
