package Business::Shipping::UPS_Offline::Shipment;

=head1 NAME

Business::Shipping::UPS_Offline::Shipment

=head1 METHODS

=over 4

=item * disable_hundredweight( )

If true, don't estimate the hundredweight rate even if it would otherwise be possible.

=item * hundredweight_margin( $percent )

If the shipment weight is only $percent (default 10%) higher than the required amount to qualify for 
hundredweight shipping, then do not calculate hundredweight.  This is to guard against the chance that the 
actual shipment weight turns out to be lower than what is used for estimation, resulting in failed eligibility
for hundredweight rates and a much higher rate than estimated.

=back

=cut

use Business::Shipping::Config;
use Business::Shipping::Logging;
use Any::Moose;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::Shipment::UPS';

# TODO: Only allow tiers 1-8
has 'tier'                  => (is => 'rw');
has 'from_state'            => (is => 'rw');
has 'max_weight'            => (is => 'rw', default => 150);
has 'disable_hundredweight' => (is => 'rw');
has 'hundredweight_margin'  => (is => 'rw', default => 10);
has 'packages' => (
    is         => 'rw',
    isa        => 'ArrayRef[Business::Shipping::UPS_Offline::Package]',
    default    => sub { [Business::Shipping::UPS_Offline::Package->new()] },
    auto_deref => 1
);

__PACKAGE__->meta()->make_immutable();

sub use_hundred_weight {
    my ($self) = @_;

    return if $self->disable_hundredweight;

    if (@{ $self->packages } > 1) {
        my $hundred_weight_qualification;

        #my %hundred_weight_info = (

        my @airborn_100 = qw/ 1da 1dasaver 2da 2dam /;
        my @ground_200  = qw/ gndres gndcom 3ds /;

        my $airborn_min = 100 + (100 * $self->hundredweight_margin * 0.01);
        my $ground_min  = 200 + (100 * $self->hundredweight_margin * 0.01);

#info "ground minimum = $ground_min, current weight = " . $self->weight . ", service = " . $self->service;

        if ((   grep($_ eq lc $self->service, @airborn_100)
                and $self->weight > $airborn_min
            )
            or (grep($_ eq lc $self->service, @ground_200)
                and $self->weight > $ground_min)
            )
        {
            return 1;
        }
    }

    return;
}

sub is_ground {
    my ($self) = @_;

    my $is_ground_svc = 0;

    my @ground_services = (
        'Ground Commercial',
        'Ground Residential',
        'Ground Hundredweight Service',
        'Standard',
    );

    my $ups_service_name = $self->service_name;
    info "ups_service_name = '$ups_service_name'";
    $is_ground_svc = 1 if grep /${ups_service_name}/i, @ground_services;
    info "is_ground_svc = $is_ground_svc";

    return $is_ground_svc;
}

sub get_hundredweight_table {
    my ($self, $table) = @_;

    # TODO: Need to map the remaining tables.
    my %table_map = qw/
        gndcomm gndcwt
        gndres gndcwt
        1da 1dacwt
        2da 2dacwt
        3ds 3dscwt
        /;

    my $suffix = '';
    if ($self->tier and $self->tier >= 1 and $self->tier <= 7) {
        $suffix = $self->tier;
    }

    return ($table_map{$table} || $table) . $suffix;
}

sub cwt_is_per {
    my ($self) = @_;

    # TODO: Complete list of services (move to config as well)

    my @airborn = qw/ 1da 1dasaver 2da 2dam /;
    my @ground  = qw/ gndres gndcom 3ds /;

    return 'pound'         if grep($_ eq lc $self->service, @airborn);
    return 'hundredweight' if grep($_ eq lc $self->service, @ground);
    error "could not determine is_per type.  service = " . $self->service;
    return;
}

=head2 packages_push

Syntatic sugar to avoid push @{$self->packages()}, $new_package;

=cut

sub packages_push {
    my ($self, $new_package) = @_;
    push @{ $self->packages() }, $new_package;
    return;
}

1;

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
