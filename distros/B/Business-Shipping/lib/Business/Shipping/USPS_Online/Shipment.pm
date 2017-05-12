package Business::Shipping::USPS_Online::Shipment;

=head1 NAME

Business::Shipping::USPS_Online::Shipment

=head1 DESCRIPTION

See Business::Shipping POD for usage information.

=head1 METHODS

=head2 pounds

=head2 ounces

=head2 weight

=head2 container

=head2 size

=head2 machinable

=head2 mail_type

=head2 width

=head2 height

=head2 length

=head2 girth

=cut

use Any::Moose;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::Util;
use Business::Shipping::USPS_Online::Package;
use version; our $VERSION = qv('400');
extends 'Business::Shipping::Shipment';

has 'packages' => (
    is         => 'rw',
    isa        => 'ArrayRef[Business::Shipping::USPS_Online::Package]',
    default    => sub { [Business::Shipping::USPS_Online::Package->new()] },
    auto_deref => 1,
);

has 'max_weight' => (is => 'rw', default => 70);
has 'service' => (is => 'rw');
has '_to_country' => (is => 'rw');

sub BUILD {
    $_[0]->from_country('US');
    return;
}

__PACKAGE__->meta()->make_immutable();

# Can't use 'handles', because the ArrayRef itself doesn't actually handle
# anything, it's the objects inside it that do.

foreach my $attribute (
    qw/
    pounds
    ounces
    weight
    container
    size
    machinable
    mail_type
    width
    height
    length
    girth
    /
    )
{
    eval "sub $attribute { return shift->package0->$attribute( \@_ ); }";
}

=head2 from_country

Always returns 'US'.

=cut

sub from_country { return 'US'; }

=head2 to_country( $to_country ) 

Uses the name translaters of Shipping::Shipment::to_country(), then applies its
own translations.  The former may not be necessary, but the latter is.

=cut

sub to_country {

    #trace '( ' . uneval( \@_ ) . ' )';
    my ($self, $to_country) = @_;

    if (defined $to_country) {

        #
        # Apply any Shipping::Shipment conversions, then apply our own.
        #
        $to_country = $self->SUPER::to_country($to_country);
        my $countries = config_to_hash(
            cfg()->{usps_information}->{usps_country_name_translations});
        $to_country = $countries->{$to_country} || $to_country;

        trace("setting to_country to \'$to_country\'");
        $self->_to_country($to_country);
    }
    trace("SUPER::to_country now is " . ($self->SUPER::to_country() || ''));

    return $self->_to_country();
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
