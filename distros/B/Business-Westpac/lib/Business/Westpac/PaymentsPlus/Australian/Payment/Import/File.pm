package Business::Westpac::PaymentsPlus::Australian::Payment::Import::File;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::File

=head1 SYNOPSIS

    my $ImportFile = Business::Westpac::PaymentsPlus::Australian::Payment::Import::File->new(
        customer_code => 'TESTPAYER',
        customer_name => 'TESTPAYER',
        customer_file_reference => 'TESTFILE001',
        scheduled_date => '26082016',
    );

    $ImportFile->add_eft_record(
        eft => \%eft_details,
        remittance => \%remittance_details,
        invoices => [
            \%invoice_details,
            \%second_invoice_details,
        ]
    );

    $ImportFile->add_osko_record( ... );
    $ImportFile->add_cheque_record( ... );
    $ImportFile->add_bpay_record( ... );
    $ImportFile->add_realtime_record( ... );
    $ImportFile->add_remittance_only_record( ... );
    $ImportFile->add_overseas_telegraphic_transfer_record( ... );


=head1 DESCRIPTION

This class implements the format as defined by Westpac at https://paymentsplus.westpac.com.au/docs/file-formats/australian-payment-import-csv

This class follows the structure and validation rules in the spec,
and delegates most of this to the subclasses (SEE ALSO below)

=cut

use feature qw/ signatures /;

use Moose;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

use Carp qw/ croak /;
use Module::Load;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import';

my @subclasses = ( qw/
    FileHeader
    Invoice
    Payment::BPAY
    Payment::Cheque
    Payment::EFT
    Payment::OTT
    Payment::Osko
    Payment::RealTime
    Payment::RemittanceOnly
    Remittance
    Trailer
/ );

load $parent . "::$_" for @subclasses;

has 'records' => (
    traits  => [ 'Array' ],
    is      => 'rw',
    isa     => "ArrayRef[ " . 
        join( " | ",map { "${parent}::$_" } @subclasses ) . "
    ]",
    default => sub { [] },
    handles => {
        _add_record => 'push',
    },
);

has 'count' => (
    traits  => [ 'Number' ],
    is      => 'rw',
    isa     => 'Num',
    default => sub { 0 },
    handles => {
        _add_payment => 'add'
    },
);

has 'amount' => (
    traits  => [ 'Number' ],
    is      => 'rw',
    isa     => 'Num',
    default => sub { 0 },
    handles => {
        _add_amount => 'add'
    },
);

foreach my $str_attr (
    'CustomerCode[10]',
    'CustomerName[40]',
    'CustomerFileReference[20]',
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

has 'scheduled_date' => (
    is       => 'ro',
    isa      => 'WestpacDate',
    required => 1,
    coerce   => 1,
    handles  => {
        scheduled_csv_date => [ strftime => '%d%m%C%y' ],
    },
);

has 'currency' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    default  => sub { 'AUD' },
);

has 'version' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    default  => sub { '6' },
);

sub record_type { 'H' }

=head1 METHODS

=head2 to_csv

Return an array of CSV lines for output

    my @csv = $self->to_csv;

The returned lines will contain the entire file structure ready for
output, including the header and trailers.

=cut

sub to_csv ( $self ) {

    # header line
    my @csv = $self->attributes_to_csv( qw/
        record_type
        customer_code
        customer_name
        customer_file_reference
        scheduled_csv_date
        currency
        version
    / );

    # payment records
    push( @csv,$_->to_csv )
        foreach $self->records->@*;

    # trailer line
    push(
        @csv,
        $self->values_to_csv(
            'T',$self->count,$self->amount
        )
    );

    return @csv;
}

=head2 add_eft_record (E)

=head2 add_osko_record (O)

=head2 add_realtime_record (RT)

=head2 add_overseas_telegraphic_transfer_record (OTT)

=head2 add_bpay_record (B)

=head2 add_cheque_record (C)

=head2 add_remittance_only_record (RO)

Add payment records to the file, optionally adding remittance and invoice
records. As per the Westpac spec some record types require remittance
and others have them as an option:

    Type   Remittance    Invoice

    E      0..1          0..n
    O      0..1          0..n
    RT     0..1          0..n
    OTT    0..1          0..n
    B      0..1          0..n
    C      1             0..n
    RO     1             0..n

Each method expects a hash with the attributes to populate the objects
that will be instantiated, with the key names being those used for the
method name C<add_${key_name}_record>, for example:

    $ImportFile->add_eft_record(

        # refer to Business::Westpac::PaymentsPlus::Australian::Payment::Import::Payment::EFT
        eft => {
            payer_payment_reference => 'REF00001',
            payment_amount => '36.04',
            recipient_reference => 'REF00001',
            account_number => '000002',
            account_name => 'Payee 02',
            bsb_number => '062-000',
            funding_bsb_number => '032-000',
            funding_account_number => '000007',
            remitter_name => 'Remitter Name',
        },

        # optional (in most cases) remittance and invoice lines
        # refer to Business::Westpac::PaymentsPlus::Australian::Payment::Import::Invoice
        # and Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance
        remittance => { ... },
        invoices => [ { ... },{ ... }, ... ],
    );

=cut

foreach my $payment_type (
    [ qw/ EFT eft / ],
    [ qw/ Osko osko / ],
    [ qw/ RealTime realtime / ],
    [ qw/ OTT overseas_telegraphic_transfer / ],
    [ qw/ BPAY bpay / ],
    [ qw/ Cheque cheque 1 / ],
    [ qw/ RemittanceOnly remittance_only 1 / ],
) {
    my ( $class,$key_name,$requires_remit ) = $payment_type->@*;
    my $sub = "add_${key_name}_record";

    __PACKAGE__->meta->add_method(
        $sub => sub ( $self,%records ) {

            if ( $requires_remit ) {
                $records{remittance} || croak(
                    "$class records must have a remittance"
                );
            }

            return $self->_add_payment_object_to_records(
                $class,$records{$key_name},\%records
            );
        },
    );
}

sub _add_payment_object_to_records (
    $self,
    $subclass,
    $attributes,
    $records = {},
) {
    my $parent = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import';
    my $class = "${parent}::Payment::${subclass}";

    $self->_add_record(
        my $Record = $class->new( $attributes->%* )
    );

    $self->_add_payment( 1 );
    $self->_add_amount( $Record->payment_amount );

    if ( $records->{remittance} ) {
        my $class = "${parent}::Remittance";
        $self->_add_record(
            $class->new( $records->{remittance}->%* )
        );
    }

    foreach my $invoice ( @{ $records->{invoices} // [] } ) {
        my $class = "${parent}::Invoice";
        $self->_add_record(
            $class->new( $invoice->%* )
        );
    }

    return $Record;
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

Business::Westpac::PaymentsPlus::Australian::Payment::Import...

=over 4

::FileHeader

::Invoice

::Payment

::Payment::Cheque

::Payment::EFT

::Payment::Okso

::Payment::OTT

::Payment::RealTime

::Remittance

::Remittance::Only

L<Business::Westpac::Types>

=back

=cut
