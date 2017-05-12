package Business::Shipping::Shipment;

=head1 NAME

Business::Shipping::Shipment - Abstract class

=head1 DESCRIPTION

Abstract Class: real implementations are done in subclasses.

Shipments have a source, a destination, packages, and other attributes.

=head1 METHODS

=cut

use Any::Moose;
extends 'Business::Shipping';
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::Util;
use version; our $VERSION = qv('400');

=head2 service

=head2 from_country

=head2 from_zip

=head2 from_city

=head2 to_country

=head2 to_zip

=head2 to_city

=head2 packages

=cut

# of Business::Shipping::Package objects.
has 'packages' => (is => 'rw', isa => 'ArrayRef');
has 'current_package_index' => (is => 'rw');
has 'from_zip'              => (is => 'rw');
has 'from_city'             => (is => 'rw');
has 'to_city'               => (is => 'rw');
has 'shipment_num'          => (is => 'rw');

__PACKAGE__->meta()->make_immutable();

=head2 weight

Forward the weight to the current package.

=cut

=head2 default_package()

Only used for forwarding methods in simple uses of the class.  For example:

 $rate_request->init(
     service   => '',
     weight    => '',
     packaging => '',
 );

Which is simpler than:

 $rate_request->shipment->service( '' );
 $rate_request->shipment->packages_index( 0 )->weight( '' );
 $rate_request->shipment->packages_index( 0 )->packaging( '' );
 
Note that it only works when there is one package only (no multiple packages).

=head2 package0

Alias for default_package.

=head2 dflt_pkg

Alias for default_package.

=cut

sub package0 { $_[0]->packages->[0] }
*default_package = *package0;
*dflt_pkg        = *package0;

sub weight {
    my ($self, $in_weight) = @_;

    if ($in_weight) {
        return $self->package0->weight($in_weight);
    }
    else {
        my $sum_weight;
        foreach my $package ($self->packages) {
            next unless defined $package->weight();
            $sum_weight += $package->weight();
        }
        return $sum_weight;
    }
}

=head2 total_weight

Returns the weight of all packages within the shipment.

=cut

sub total_weight {
    my $self = shift;

    my $total_weight;
    foreach my $package (@{ $self->packages() }) {
        $total_weight += $package->weight();
    }
    return $total_weight;
}

=head2 to_zip( $to_zip )

Throw away the "four" from zip+four.  

Redefines the MethodMaker implementation of this attribute.

=cut

no warnings 'redefine';

sub to_zip {
    my $self = shift;

    if ($_[0]) {
        my $to_zip = shift;

        #
        # U.S. only: need to throw away the "plus four" of zip+four.
        #
        if ($self->domestic and $to_zip and length($to_zip) > 5) {
            $to_zip = substr($to_zip, 0, 5);
        }

        $self->{'to_zip'} = $to_zip;
    }

    return $self->{'to_zip'};
}
use warnings;    # end 'redefine'

=head2 to_country()

to_country must be overridden to transform from various forms (alternate
spellings of the full name, abbreviatations, alternate abbreviations) into
the full name that we use internally.

May be overridden by subclasses to provide their own spelling ("United Kingdom"
vs "Great Britain", etc.).  

Redefines the MethodMaker implementation of this attribute.

=cut

sub to_country {
    my ($self, $to_country) = @_;

    if (defined $to_country) {
        my $abbrevs
            = config_to_hash(cfg()->{ups_information}->{abbrev_to_country});
        my $abbrev_to_country = $abbrevs->{$to_country};

#use Data::Dumper; print STDERR "cfg() -> { ups_information } -> { abbrev_to_country } = " . Dumper( cfg()->{ ups_information }->{ abbrev_to_country } ) . "\nhash = " . Dumper( $abbrevs ) . "\n\n to_country = $to_country, abbrev_to_country = $abbrev_to_country\n";
        $to_country = $abbrev_to_country || $to_country;
    }
    $self->{to_country} = $to_country if defined $to_country;

    return $self->{to_country};
}

=head2 to_country_abbrev()

Returns the abbreviated form of 'to_country'.

Redefines the MethodMaker implementation of this attribute.

=cut

sub to_country_abbrev {
    my ($self) = @_;

    my $country_abbrevs
        = config_to_hash(cfg()->{ups_information}->{country_to_abbrev});

    return $country_abbrevs->{ $self->to_country } or $self->to_country;
}

=head2 from_country()


=cut

sub from_country {
    my ($self, $from_country) = @_;

    if (defined $from_country) {
        my $abbrevs
            = config_to_hash(cfg()->{ups_information}->{abbrev_to_country});
        $from_country = $abbrevs->{$from_country} || $from_country;
    }
    $self->{from_country} = $from_country if defined $from_country;

    return $self->{from_country};
}

=head2 from_country_abbrev()

=cut

sub from_country_abbrev {
    my ($self) = @_;
    return unless $self->from_country;

    my $countries
        = config_to_hash(cfg()->{ups_information}->{country_to_abbrev});
    my $from_country_abbrev = $countries->{ $self->from_country };

    return $from_country_abbrev || $self->from_country;
}

=head2 domestic_or_ca()

Returns 1 (true) if the to_country value for this shipment is domestic (United
States) or Canada.

Returns 1 if to_country is not set.

=cut

sub domestic_or_ca {
    my ($self) = @_;

    return 1 if not $self->to_country;
    return 1 if $self->to_canada or $self->domestic;
    return 0;
}

=head2 intl()

Uses to_country() value to determine if the order is International (non-US).

Returns 1 or 0 (true or false).

=cut

sub intl {
    my ($self) = @_;

    if ($self->to_country) {
        if ($self->to_country !~ /(US)|(United States)/) {
            return 1;
        }
    }

    return 0;
}

=head2 domestic()

Returns the opposite of $self->intl
 
=cut

sub domestic {
    my ($self) = @_;

    if ($self->intl) {
        return 0;
    }

    return 1;
}

=head2 from_canada()

UPS treats Canada differently.

=cut

sub from_canada {
    my ($self) = @_;

    if ($self->from_country) {
        if ($self->from_country =~ /^((CA)|(Canada))$/i) {
            return 1;
        }
    }

    return 0;
}

=head2 to_canada()

UPS treats Canada differently.

=cut

sub to_canada {
    my ($self) = @_;

    if ($self->to_country) {
        if ($self->to_country =~ /^((CA)|(Canada))$/i) {
            return 1;
        }
    }

    return 0;
}

=head2 to_ak_or_hi()

Alaska and Hawaii are treated differently by many shippers.

=cut

sub to_ak_or_hi {
    my ($self) = @_;

    return unless $self->to_zip;

    my @ak_hi_zip_config_params = (
        qw/
            hi_special_zipcodes_124_224
            hi_special_zipcodes_126_226
            ak_special_zipcodes_124_224
            ak_special_zipcodes_126_226
            /
    );

    for (@ak_hi_zip_config_params) {
        my $zips   = cfg()->{ups_information}->{$_};
        my $to_zip = $self->to_zip;
        if ($zips =~ /$to_zip/) {
            return 1;
        }
    }

    return 0;
}

=head2 add_package( %args )

Adds a new package to the shipment.

=cut

# This is from 0.04.
# Needs to be made compatible with the new version.

sub add_package {
    my ($self, %options) = @_;

    #trace( 'called with ' . uneval( @_ ) );

    if (not $self->shipper) {
        error "Need shipper to get the package subclass.";
        return;
    }

    debug "add_package shipper = " . $self->shipper;

    my $package;
    eval {
        $package
            = Business::Shipping->_new_subclass($self->shipper . '::Package');
    };
    logdie "Error when creating Package subclass: $@" if $@;
    logdie "package was undefined." if not defined $package;

    $package->init(%options);

    # If the passed package has an ID.  Do not evaluate for perl trueness,
    # because 0 is a valid true value in this case.
    if (defined $package->id()) {
        info 'Using id in passed package';
        $self->packages_set($package->id => $package);
        return 1;
    }

    $self->packages_push($package);

    return 1;
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
