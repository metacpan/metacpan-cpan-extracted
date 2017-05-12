package Business::Shipping::Shipment::UPS;

=head1 NAME

Business::Shipping::Shipment::UPS

=head1 VERSION

$Rev: 280 $

=head1 METHODS

=cut

use Any::Moose;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use version; our $VERSION = qv('400');

=head2 to_residential()

Defaults to true.

=cut

extends 'Business::Shipping::Shipment';
has 'to_residential' => (is => 'rw', default => 1);
has '_service'       => (is => 'rw');
has 'service_code'   => (is => 'rw');
has 'service_nick'   => (is => 'rw');
has 'service_name'   => (is => 'rw');
has 'service_nick2'  => (is => 'rw');

# We need this offline boolean to know if from_state is required.
has 'offline' => (is => 'rw');

#type => 'Business::Shipping::Package
#has 'packages' => (is => 'rw', isa => 'ArrayRef');

__PACKAGE__->meta()->make_immutable();

=head2 packaging()

=head2 weight()

# Uses the standard Shipment::weight().

=head2 signature_type()

=head2 insured_currency_type()

=head2 insured_value()

=cut

sub packaging             { shift->package0->packaging(@_) }
sub signature_type        { shift->package0->signature_type(@_) }
sub insured_currency_type { shift->package0->insured_currency_type(@_) }
sub insured_value         { shift->package0->insured_value(@_) }

=head2 massage_values()

Assign a package type (if none given) based on the service.  Set weight to 0.01
minimum.  Remove "+4" from ZIP+4.  

=cut

sub massage_values {
    my ($self) = @_;

    # Check each package for a package type and assign one if none given.
    my %services_default_packaging_codes = (
        qw/
            1DM    02
            1DML   01
            1DA    02
            1DAL   01
            1DP    02
            2DM    02
            2DA    02
            2DML   01
            2DAL   01
            3DS    02
            GNDCOM 02
            GNDRES 02
            XPR    02
            UPSSTD 02
            XDM    02
            XPRL   01
            XDML   01
            XPD    02
            /
    );

    #use Data::Dumper; die "packages = " . Dumper($self->packages());
    # Set default packaging code based on the service.

    foreach my $package ($self->packages()) {
        next if $package->packaging();

        my $dflt_pkg_code_for_svc;
        if (my $service_nick = $self->service_nick()) {
            $dflt_pkg_code_for_svc
                = $services_default_packaging_codes{$service_nick};
        }
        if ($dflt_pkg_code_for_svc) {
            $package->packaging($dflt_pkg_code_for_svc);
        }
        else {
            $package->packaging('02');
        }
    }

    # UPS requires weight is at least 0.1 pounds.
    foreach my $package ($self->packages) {
        $package->weight(0.1)
            if (not $package->weight() or $package->weight() < 0.1);
    }

    # In the U.S., UPS only wants the 5-digit base ZIP code, not ZIP+4
    $self->to_country('US') if not $self->to_country();
    if ($self->to_zip()) {
        $self->to_zip() =~ /^(\d{5})/ and $self->to_zip($1);
    }

    #info('to_country currently = ' . $self->to_country());
    # UPS prefers 'GB' instead of 'UK'
    $self->to_country('GB') if $self->to_country() eq 'UK';

}

=head2 Required()

from_state only required for Offline international orders.

=cut

sub Required {
    return 'service, from_state' if $_[0]->to_canada and $_[0]->offline;
    return 'service, from_zip, from_state' if $_[0]->intl and $_[0]->offline;
    return 'service, from_zip';
}

=head2 from_state_abbrev()

Returns the abbreviated form of 'from_state'.

=cut

sub from_state_abbrev {
    my ($self) = @_;

    my $state_abbrevs
        = config_to_hash(cfg()->{ups_information}->{state_to_abbrev});

    return $state_abbrevs->{ $self->from_state } || $self->from_state;
}

=head2 from_ak_or_hi()

Alaska and Hawaii are treated differently by many shippers.

=cut

sub from_ak_or_hi {
    my ($self) = @_;
    return unless $self->from_state();
    return 1 if $self->from_state() =~ /^(AK|HI)$/i;
    return 0;
}

=head2 service

Stores the name as the user entered it, and updates the sibling methods.

=head2 service_code

The correct UPS code (e.g. 03).

=head2 service_nick

The semi-official UPS nickname (e.g. 'GNDRES').

=head2 service_name

The official UPS name (e.g. 'Ground Residential').

=head2 service_nick2

The other nickname for that service (e.g. 'Ground'), used in offline UPS
data files.

=cut

sub service {
    my ($self, $service) = @_;

    if (defined $service) {
        $self->_service($service);

        my $service_map = $self->service_info($service, 'get_map');

        if ($service_map) {

           # Record whatever the user passed in.  If we need a certain format,
           # we can always use the sibling methods.
            $self->_service($service);

            # Setup the sibling method data
            $self->service_code($service_map->{code});
            $self->service_nick($service_map->{nick});
            $self->service_name($service_map->{name});
            $self->service_nick2($service_map->{nick2});
        }
        else {
            $self->user_error(
                "The service '$service' is not a valid service type");
        }

        # Default values for residential addresses.

        if (not $self->to_residential) {
            if ($self->service_name eq 'Ground Residential') {
                $self->to_residential(1);
            }
            elsif ($self->service_name eq 'Ground Commercial') {
                $self->to_residential(0);
            }
        }

    }

    return $self->_service();
}

=head2 service_code_to_nick

=head2 service_code_to_name

=cut

sub service_code_to_nick { return $_[0]->service_info($_[1], 'nick'); }
sub service_code_to_name { return $_[0]->service_info($_[1], 'name'); }

=head2 service_info

Provides implementation details for service() and friends.

=cut

sub service_info {
    my ($self, $service, $type) = @_;

    return unless $service and $type;

    return { name => 'Shop', code => 999, nick => 'SHOP', nick2 => 'Shop' }
        if $service eq 'shop' and $type eq 'get_map';

    my $service_info_cfg = cfg()->{ups_service_info};
    my $service_info;

    # Reset counter for 'each'
    keys %$service_info_cfg;

    while (my ($name, $other_values) = each %$service_info_cfg) {
        my ($nick, $code, $nick2) = split("\t", $other_values);
        my $service_info_hash = {
            name  => $name,
            nick  => $nick,
            code  => $code,
            nick2 => $nick2,
        };
        push @$service_info, $service_info_hash;
    }

    my $matching_map;
    my $match;
    foreach my $service_map (@$service_info) {

        if ($type eq 'get_map') {
            if ($service eq $service_map->{code}) {
                $match = 1;
            }
            elsif (lc $service eq lc $service_map->{nick}) {
                $match = 1;
            }
            elsif (lc $service eq lc $service_map->{name}) {
                $match = 1;
            }

            if ($match) {
                return $service_map;
            }
        }
        else {

            # Individual type
            if ($service_map->{code} eq $service) {
                return $service_map->{$type};

                # TODO: check to see if none matched, then throw user_error
            }
        }
    }

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
