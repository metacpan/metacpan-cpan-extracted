package Business::Westpac::Role::CSV;

=head1 NAME

Business::Westpac::Role::CSV

=head1 SYNOPSIS

    use Moose;
    with 'Business::Westpac::Role::CSV';

=head1 DESCRIPTION

Role for CSV related attributes and functions used in the
Business::Westpac namespace

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose::Role;
no warnings qw/ experimental::signatures /;
use Text::CSV;

=head1 ATTRIBUTES

None yet

=cut

has _csv_encoder => (
    is      => 'ro',
    isa     => 'Text::CSV',
    lazy    => 1,
    default => sub {
        Text::CSV->new({
            binary       => 1,
            quote        => '"',
            always_quote => 1,
        });
    }
);

=head1 METHODS

=head2 attributes_to_csv

Convert the list of attributes to a CSV line:

    my @csv = $self->attributes_to_csv( qw/
        record_type
        payment_amount
        ...
    / );

=cut

sub attributes_to_csv (
    $self,
    @attributes,
) {
    return $self->values_to_csv(
        map { $self->$_ } @attributes
    );
}

=head1 METHODS

=head2 values_to_csv

Convert the list of values to a CSV line:

    my @csv = $self->values_to_csv(
        $self->record_type,
        $self->payment_amount,
        ...
    );

=cut

sub values_to_csv (
    $self,
    @values,
) {
    my $csv = $self->_csv_encoder;
    $csv->combine( @values );
    return $csv->string;
}

1;
