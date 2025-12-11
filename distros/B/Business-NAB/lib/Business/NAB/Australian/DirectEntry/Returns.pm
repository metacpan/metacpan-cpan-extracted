package Business::NAB::Australian::DirectEntry::Returns;
$Business::NAB::Australian::DirectEntry::Returns::VERSION = '0.02';
=head1 NAME

Business::NAB::Australian::DirectEntry::Returns

=head1 SYNOPSIS

    use Business::NAB::Australian::DirectEntry::Returns;

    # parse:
    my $Returns = Business::NAB::Australian::DirectEntry::Returns
        ->new_from_file( $file_path );

    foreach my $DetailRecord ( $Returns->detail_record->@* ) {
        ...
    }

=head1 DESCRIPTION

Class for building/parsing a "Australian Direct Entry Payments"
returns file. This class extends L<Business::NAB::Australian::DirectEntry::Payments>
so see that for more detail

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
extends 'Business::NAB::Australian::DirectEntry::Payments';
no warnings qw/ experimental::signatures /;

# we have long namespaces and use them multiple times so have
# normalised them out into the $parent and @subclasses below
my $parent = 'Business::NAB::Australian::DirectEntry::Returns';

my @subclasses = (
    qw/
        DescriptiveRecord
        DetailRecord
        TotalRecord
        /
);

__PACKAGE__->load_attributes( $parent, @subclasses );

sub new_from_file ( $class, $file ) {

    my %sub_class_map = (
        0 => 'DescriptiveRecord',
        2 => 'DetailRecord',        # returns
        7 => 'TotalRecord',         # returns
    );

    my $self = $class->new;

    return $self->SUPER::new_from_file(
        $file, \%sub_class_map, $parent
    );
}

=head1 SEE ALSO

L<Business::NAB::Australian::DirectEntry::Payments>

=cut

__PACKAGE__->meta->make_immutable;
