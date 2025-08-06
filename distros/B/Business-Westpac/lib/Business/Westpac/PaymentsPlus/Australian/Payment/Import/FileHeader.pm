package Business::Westpac::PaymentsPlus::Australian::Payment::Import::FileHeader;

=head1 NAME

Business::Westpac::PaymentsPlus::Australian::Payment::Import::FileHeader

=head1 SYNOPSIS

    use Business::Westpac::PaymentsPlus::Australian::Payment::Import::FileHeader;
    my $Header = Business::Westpac::PaymentsPlus::Australian::Payment::Import::FileHeader->new(
        customer_code => 'TESTPAYER',
        customer_name => 'TESTPAYER NAME',
        customer_file_reference => 'TESTFILE001',
        scheduled_date => '26082016',
    );

    my @csv = $Header->to_csv;

=head1 DESCRIPTION

Class for Westpac Australian payment import CSV file header

=cut

use feature qw/ signatures /;

use Moose;
with 'Business::Westpac::Role::CSV';
no warnings qw/ experimental::signatures /;

use Business::Westpac::Types qw/
    add_max_string_attribute
/;

=head1 ATTRIBUTES

All attributes are required and are read only

=head2 customer_code (Str, max 10 chars)

=head2 customer_name (Str, max 40 chars)

=head2 customer_file_reference (Str, max 20 chars)

=head2 scheduled_date (DateTime, or coerced from DDMMYYYY)

=cut

sub record_type { 'H' }
sub currency    { 'AUD' }
sub version     { '6' }

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
        csv_date => [ strftime => '%d%m%C%y' ],
    },
);

=head1 METHODS

=head2 to_csv

Convert the attributes to CSV line(s):

    my @csv = $Header->to_csv;

=cut

sub to_csv ( $self ) {

    return $self->attributes_to_csv(
        qw/
            record_type
            customer_code
            customer_name
            customer_file_reference
            csv_date
            currency
            version
        /
    );
}

=head1 SEE ALSO

L<Business::Westpac::Types>

=cut

__PACKAGE__->meta->make_immutable;
