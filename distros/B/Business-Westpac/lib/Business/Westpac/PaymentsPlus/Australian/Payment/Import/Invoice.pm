package Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice;

    my $Invoice = Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice->new(
        payers_invoice_number => '1000000001',
        recipient_invoice_number => '1000000001',
        issued_date => '26082016',
        due_date => '01092016',
        invoice_amount => '36.04',
        invoice_amount_paid => '36.04',
        invoice_description => 'Desc 1',
        deduction_description => 'Ded Desc 1',
        pass_through_data => 'Some pass through data',
    );

=head1 DESCRIPTION

Class for modeling Invoice details in the context of Westpac CSV files.

=cut

use feature qw/ signatures /;

use Moose;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

sub record_type { 'I' }

=head1 ATTRIBUTES

All attributes are optional, except were stated, and are read only

=over

=item payers_invoice_number (Str, max 20 chars)

=item recipient_invoice_number (Str, max 20 chars)

=item invoice_description (Str, max 80 chars)

=item deduction_description (Str, max 80 chars)

=item issued_date (WestpacDate)

=item due_date (WestpacDate)

=item invoice_amount (Num)

=item invoice_amount_paid (Num)

=item deduction_amount (Num)

=back

=cut

foreach my $str_attr (
    'PayersInvoiceNumber[20]',
    'RecipientInvoiceNumber[20]',
    'InvoiceDescription[80]',
    'DeductionDescription[80]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 0,
    );
}

=head1 METHODS

=head2 issued_csv_date

Returns the issued_date to a string suitable for the CSV

=head2 due_csv_date

Returns the due_date to a string suitable for the CSV

=cut

has 'issued_date' => (
    is       => 'ro',
    isa      => 'WestpacDate',
    required => 0,
    coerce   => 1,
    handles  => {
        issued_csv_date => [ strftime => '%d%m%C%y' ],
    },
);

has 'due_date' => (
    is       => 'ro',
    isa      => 'WestpacDate',
    required => 0,
    coerce   => 1,
    handles  => {
        due_csv_date => [ strftime => '%d%m%C%y' ],
    },
);

has [ qw/
    invoice_amount
    invoice_amount_paid
    deduction_amount
/ ] => (
    is       => 'ro',
    isa      => 'Num',
    required => 0,
    default  => sub { 0 },
);

# Pass through data appears on a distinct "Invoice Pass-through record"
# (IP) however it can only appear after a Invoice record (I), i.e. this
# class. Given the IP line currently *only* contains a single field, the
# pass through data, it seems overkill to have an entire distinct class for
# it. So for now it's just an attribute on *this* class.
__PACKAGE__->add_max_string_attribute(
    'PassThroughData[120]',
    is       => 'ro',
    required => 0,
);

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Invoice->to_csv;

=cut

sub to_csv ( $self ) {

    my @csv_str = $self->attributes_to_csv(
        qw/
            record_type
            payers_invoice_number
            recipient_invoice_number
            issued_csv_date
            due_csv_date
            invoice_amount
            invoice_amount_paid
            invoice_description
            deduction_amount
            deduction_description
        /
    );

    # add the "Invoice Pass-through record" if present
    if ( $self->_has_pass_through_data ) {
        push( @csv_str, $self->values_to_csv(
            "IP",$self->pass_through_data
        ) );
    }

    return @csv_str;
}

=head1 SEE ALSO

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
