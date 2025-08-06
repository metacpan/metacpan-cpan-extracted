package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Trailer;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Trailer

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Trailer;

    my $Trailer = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Trailer->new(
        total_payment_count => 8,
        total_payment_amount => '2015.42',
    );

=head1 DESCRIPTION

Class for Westpac CSV file trailer records.

=cut

use feature qw/ signatures /;

use Moose;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

sub record_type { 'T' }

=head1 ATTRIBUTES

All attributes are required, except were stated, and are read/write

=over

=item total_payment_count (Num)

=item total_payment_amount (Num)

=back

=cut

has [ qw/
    total_payment_count
    total_payment_amount
/ ] => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            total_payment_count
            total_payment_amount
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
