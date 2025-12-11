package Business::NAB::Australian::DirectEntry::Report::HeaderRecord;
$Business::NAB::Australian::DirectEntry::Report::HeaderRecord::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Report::HeaderRecord

=head1 SYNOPSIS

=head1 DESCRIPTION

Class for header record in the Australian Direct Entry Report file

=cut;

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::CSV';
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/
    add_max_string_attribute
    /;

=head1 ATTRIBUTES

All are Str types, required, except where stated

=over

=item bank_name

=item product_name

=item report_name

=item run_date (NAB::Type::Date)

=item run_time

=item fund_id

=item customer_name

=item import_file_name

=item payment_date (NAB::Type::Date)

=item batch_no_links

=item export_file_name

=item de_user_id

=item me_id

=item report_file_name

=back

=cut

sub _record_type { '00' }

sub _attributes {
    return qw/
        bank_name
        product_name
        report_name
        run_date
        run_time
        fund_id
        customer_name
        import_file_name
        payment_date
        batch_no_links
        export_file_name
        de_user_id
        me_id
        report_file_name
        /;
}

has [
    qw/
        run_date payment_date
        /
] => (
    is       => 'ro',
    isa      => 'NAB::Type::Date',
    required => 1,
    coerce   => 1,
);

foreach my $str_attr (
    grep { $_ !~ /date/ } __PACKAGE__->_attributes
) {
    __PACKAGE__->add_max_string_attribute(
        $str_attr,
        is       => 'ro',
        required => 1,
    );
}

sub to_record ( $self ) {

    my $aoa = [ [
        map {
            $_ =~ /date/
                ? $self->$_->dmy( '' )
                : $self->$_
                ;
        } '_record_type',
        $self->_attributes,
    ] ];

    return $self->SUPER::to_record( $aoa );
}

__PACKAGE__->meta->make_immutable;
