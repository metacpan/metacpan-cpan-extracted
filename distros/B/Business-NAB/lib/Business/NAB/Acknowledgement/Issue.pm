package Business::NAB::Acknowledgement::Issue;
$Business::NAB::Acknowledgement::Issue::VERSION = '0.01';
=head1 NAME

Business::NAB::Acknowledgement::Issue

=head1 SYNOPSIS

    my $Issue = Business::NAB::Acknowledgement::Issue->new(
        code => "290049",
        detail => "Uploaded Interchange 60063804 for ...",
    );

=head1 DESCRIPTION

Class for NAB file acknowledgement issues. You probably don't want
to interact with this class and instead use the parent class
L<Business::NAB::Acknowledgement>.

=cut

use strict;
use warnings;
use feature qw/ signatures /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;
use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item code (Str)

=item detail (Str)

=item itemId (Int)

=back

=cut

has [ qw/ code detail itemId type / ] => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 0,
);

=head1 METHODS

=head2 is_approved

=head2 is_authorised

=head2 is_changed

=head2 is_checked

=head2 is_corrected

=head2 is_error

=head2 is_failed

=head2 is_held

=head2 is_invalid

=head2 is_partially_failed

=head2 is_ready

=head2 is_ready_for_auth

=head2 is_referred

=head2 is_released

=head2 is_report

=head2 is_reserved

=head2 is_uploaded

=head2 is_validated

=head2 is_warning

Boolean checks on the issue type

=cut

# type codes map to the transaction state, which is *inferred*
# from the detail in the text the Issue contains
my %type_lookup = (
    error   => 'is_error',
    warning => 'is_warning',
    2025    => 'is_uploaded',
    5013    => 'is_corrected',
    6010    => 'is_ready_for_auth',
    6014    => 'is_authorised',
    50040   => 'is_changed',
    104503  => 'is_validated',
    104506  => 'is_invalid',
    112215  => 'is_invalid',
    130000  => 'is_checked',
    130001  => 'is_reserved',
    130003  => 'is_referred',
    133610  => 'is_failed',
    140000  => 'is_reserved',
    180004  => 'is_rejected',
    180054  => 'is_referred',
    180055  => 'is_approved',
    180057  => 'is_approved',
    181002  => 'is_validated',
    181004  => 'is_invalid',
    181015  => 'is_partially_failed',
    181016  => 'is_invalid',
    181026  => 'is_invalid',
    181100  => 'is_held',
    181104  => 'is_released',
    181253  => 'is_authorised',
    181258  => 'is_rejected',
    181259  => 'is_authorised',
    190108  => 'is_invalid',
    181301  => 'is_ready',
    194500  => 'is_report',
    290049  => 'is_report',
);

my %reverse_type_lookup = reverse( %type_lookup );

foreach my $method ( keys %reverse_type_lookup ) {

    __PACKAGE__->meta()->add_method(
        $method,
        sub ( $self ) {
            return $type_lookup{ $self->type } eq $method
                ? 1 : 0;
        },
    );
}

=head1 SEE ALSO

L<Business::NAB::Acknowledgement>

=cut

__PACKAGE__->meta->make_immutable;
