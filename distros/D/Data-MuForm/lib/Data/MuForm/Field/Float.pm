package Data::MuForm::Field::Float;
# ABSTRACT: validate a float value

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Field::Text';
use Types::Standard -types;


has '+size'                 => ( default => 8 );
has 'precision'             => ( is => 'rw', default => 2 );
has 'decimal_symbol'        => ( is => 'rw', default => '.');
has 'decimal_symbol_for_db' => ( is => 'rw', default => '.');
has '+transform_input_to_value' => ( default => sub { *input_to_value } );
has '+transform_value_to_fif'   => ( default => sub { *value_to_fif } );

our $class_messages = {
    'float_needed'      => 'Must be a number. May contain numbers, +, - and decimal separator \'[_1]\'',
    'float_size'        => 'Total size of number must be less than or equal to {size}, but is {actual_size}',
    'float_precision1'   => 'May have only one digit after the decimal point, but has {num_digits:num}',
    'float_precision2'   => 'May have a maximum of {precision:num} digits after the decimal point, but has {num_digits:num}',
};

sub get_class_messages {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub input_to_value {
    my ( $self, $value ) = @_;
    return $value unless defined $value;
    $value =~ s/^\+//;
    return $value;
}

sub value_to_fif {
    my ( $self, $value ) = @_;
    return $value unless defined $value;
    my $symbol      = $self->decimal_symbol;
    my $symbol_db   = $self->decimal_symbol_for_db;
    $value =~ s/\Q$symbol_db\E/$symbol/x;
    return $value;
}

sub validate {
    my $field = shift;

    #return unless $field->next::method;
    my ($integer_part, $decimal_part) = ();
    my $value       = $field->value;
    my $symbol      = $field->decimal_symbol;
    my $symbol_db   = $field->decimal_symbol_for_db;

    if ($value =~ m/^-?([0-9]+)(\Q$symbol\E([0-9]+))?$/x) {     # \Q ... \E - All the characters between the \Q and the \E are interpreted as literal characters.
        $integer_part = $1;
        $decimal_part = defined $3 ? $3 : '';
    }
    else {
        return $field->add_error( $field->get_message('float_needed'), $symbol );
    }

    # check total float size
    if ( my $allowed_size = $field->size ) {
        my $total_size = length($integer_part) + length($decimal_part);
        return $field->add_error( $field->get_message('float_size'),
            size => $allowed_size, actual_size => $total_size )
            if $total_size > $allowed_size;
    }

    # check precision
    if ( my $allowed_precision = $field->precision ) {
        return $field->add_error_nx(
            $field->get_message('float_precision1'),
            $field->get_message('float_precision2'),
            $allowed_precision, precision => $allowed_precision, num_digits => length($decimal_part))
            if length $decimal_part > $allowed_precision;
    }

    # Inflate to database accepted format
    $value =~ s/\Q$symbol\E/$symbol_db/x;
    $field->value($value);

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Float - validate a float value

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This accepts a positive or negative float/integer.  Negative numbers may
be prefixed with a dash.  By default a max of eight digits including 2 precision
are accepted. Default decimal symbol is ','.
Widget type is 'text'.

    # For example 1234,12 has size of 6 and precision of 2
    # and separator symbol of ','

    has_field 'test_result' => (
        type                    => 'Float',
        size                    => 8,               # Total size of number including decimal part.
        precision               => 2,               # Size of the part after decimal symbol.
        decimal_symbol          => '.',             # Decimal symbol accepted in web page form
        decimal_symbol_for_db   => '.',             # For inflation. Decimal symbol accepted in DB, which automatically converted to.
        range_start             => 0,
        range_end               => 100
    );

=head2 messages

   float_needed
   float_size
   float_precision1
   float_precision2

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
