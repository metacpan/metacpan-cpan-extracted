# Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself. See LICENSE for more info.

package Business::Shipping;

=head1 NAME

Business::Shipping - Rates and tracking for UPS and USPS

=cut

use Any::Moose;
use Carp;
use Business::Shipping::Logging;
use Business::Shipping::Util 'unique';

=head1 VERSION

Version 3.1.0

=cut

use version; our $VERSION = qv('3.1.0');

=head1 SYNOPSIS

=head2 Rate request example

 use Business::Shipping;
 
 my $rate_request = Business::Shipping->rate_request(
     shipper   => 'UPS_Offline',
     service   => 'Ground Residential',
     from_zip  => '98683',
     to_zip    => '98270',
     weight    =>  5.00,
 );    
 
 $rate_request->execute() or die $rate_request->user_error();
 
 print $rate_request->rate();

=head1 FEATURES

Business::Shipping currently supports three shippers:

=head2 UPS_Offline: United Parcel Service

=over 4

=item * Shipment rate estimation using offline tables. 

As of January, 2007, UPS has only released the data tables in binary Excel 
format. These have not been converted to the text files necessary for use in 
this module. A script is distributed with the module for automatically 
updating the fuel surcharge every month.

=back

=head2 UPS_Online: United Parcel Service using UPS OnLine Tools

=over 4

=item * Shipment rate estimation

=item * Shipment tracking.

=item * Rate Shopping.

Gets rates for all the services in one request:

 my $rr_shop = Business::Shipping->rate_request( 
     service      => 'shop',    
     shipper      => 'UPS_Online',
     from_zip     => '98682',
     to_zip       => '98270',
     weight       => 5.00,
     user_id      => '',
     password     => '',
     access_key   => '',
 );
 
 $rr_shop->execute() or die $rr_shop->user_error();
 
 foreach my $shipper ( @$results ) {
     print "Shipper: $shipper->{name}\n\n";
     foreach my $rate ( @{ $shipper->{ rates } } ) {
         print "  Service:  $rate->{name}\n";
         print "  Charges:  $rate->{charges_formatted}\n";
         print "  Delivery: $rate->{deliv_date_formatted}\n" 
             if $rate->{ deliv_date_formatted };
         print "\n";
     }
 }

=item * C.O.D. (Cash On Delivery)

Add these options to your rate request for C.O.D.:

cod: enable C.O.D.

cod_funds_code:  The code that indicates the type of funds that will be used for
the COD payment. Required if CODCode is 1, 2, or 3.  Valid Values: 0 = All Funds
Allowed.  8 = cashier's check or money order, no cash allowed.

cod_value: The COD value for the package.  Required if COD option is present. 
Valid values: 0.01 - 50000.00

cod_code: The code associated with the type of COD.  Values: 1 = Regular COD, 
2 = Express COD, 3 = Tagless COD
 
For example:

	cod            => 1,
	cod_value      => 400.00,
	cod_funds_code => 0,

=back

=head2 USPS_Online: United States Postal Service

=over 4

=item * Shipment rate estimation using USPS Online WebTools.

=item * Shipment tracking

=back

=head1 INSTALLATION

 perl -MCPAN -e 'install Bundle::Business::Shipping'

See INSTALL.

=head1 REQUIRED MODULES

 Any::Moose (any)
 Config::IniFiles (any)
 Log::Log4perl (any)

See INSTALL.

=head1 OPTIONAL MODULES

For UPS offline rate estimation:

 Business::Shipping::DataFiles (any)

The following modules are used by online rate estimation and tracking.  See 
INSTALL.

 CHI (0.39)
 Crypt::SSLeay (any)
 LWP::UserAgent (any)
 XML::DOM (any)
 XML::Simple (2.05)

=head1 GETTING STARTED

Be careful to read, understand, and comply with the terms of use for the 
shipping service that you will use.

=head2 UPS_Offline: For United Parcel Service (UPS) offline rate requests

No signup required.  C<Business::Shipping::DataFiles> has all of rate tables, 
which are usually updated only once per year.

We recommend that you run the following script to update your fuel surcharge
every first monday of the month.

 bin/Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

=head2 UPS_Online: For United Parcel Service (UPS) Online XML: Free signup

=over 4

=item * Read the legal terms and conditions: 
L<http://www.ups.com/content/us/en/resources/service/terms/index.html>

=item * L<https://www.ups.com/one-to-one/register>

=item * After receiving a User Id and Password from UPS, login, then select
        "Get Access Key", then "Get XML Access Key".

=item * Read more about UPS Online Tools: 
L<http://www.ups.com/e_comm_access/toolintro>

=back

=head2 USPS_Online: For United States Postal Service (USPS): Free signup

=over 4

=item * L<https://secure.shippingapis.com/Registration/>

=item * (More info at L<http://www.usps.com/webtools/>)

=item * The online signup will result in a testing-only account (only a small
        sample of queries will work).  

=item * To activate the "production" use of your USPS account, you must follow 
        the USPS documentation.  As of Sept 16 2004, that means contacting the 
        USPS Internet Customer Care Center by e-mail 
        (C<icustomercare@usps.com>) or phone: 1-800-344-7779.

=back

=head1 ERROR/DEBUG HANDLING

Log4perl is used for logging error, debug, etc. messages. For simple 
manipulation of the current log level, use the Business::Shipping->log_level()
class method (below). For more advanced logging/debugging options, see 
config/log4perl.conf.

=head1 Preloading Modules

To preload all modules, call Business::Shipping with this syntax:

 use Business::Shipping { preload => 'All' };

To preload the modules for just one shipper:

 use Business::Shipping { preload => 'USPS_Online' };
 
Without preloading, some modules will be loaded at runtime.  Normally, runtime
loading is the best mode of operation.  However, there are some circumstances 
when preloading is advantagous.  For example:

=over 4

=item * For mod_perl, to load the modules only once at startup to reduce memory
utilization.

=item * For compatibilty with some security modules (e.g. Safe).

=item * To move the delay that would normally occur with the first request into 
 startup time.  That way, it takes longer to start up, but the first user
 will not experience any delay.

=back

=head1 METHODS

=cut

has 'tx_type'         => (is => 'rw', isa => 'Str');
has 'shipper'         => (is => 'rw', isa => 'Str');
has '_user_error_msg' => (is => 'rw', isa => 'Str');

__PACKAGE__->meta()->make_immutable();

$Business::Shipping::RuntimeLoad = 1;

sub import {
    my ($class_name, $record) = @_;

    return unless defined $record and ref($record) eq 'HASH';

    while (my ($key, $val) = each %$record) {
        if (lc $key eq 'preload') {

            # Required modules lists
            # ======================
            # Each of these modules does a compile-time require of all
            # the modules that it needs.  If, in the future, any of these
            # modules switch to a run-time require, then update this list with
            # the modules that may be run-time required.
            my $module_list = {
                'USPS_Online' =>
                    ['Business::Shipping::USPS_Online::Tracking',],
                'UPS_Online' => ['Business::Shipping::UPS_Online::Tracking',],
                'UPS_Offline' => [],
            };

            my @to_load;
            while (my ($shipper, $mod_list) = each %$module_list) {
                if (lc $val eq lc $shipper or lc $val eq 'all') {
                    my $rate_req_mod
                        = 'Business::Shipping::' . $shipper . '::RateRequest';
                    push @to_load, (@$mod_list, $rate_req_mod);
                }
            }

            if (@to_load) {
                $Business::Shipping::RuntimeLoad = 0;
            }
            my @unique_to_load = Business::Shipping::Util::unique(@to_load);
            foreach my $module (@unique_to_load) {
                eval "use $module;";
                die $@ if $@;
            }
        }
    }
}

=head2 $obj->init()

Generic attribute setter.

=cut

sub init {
    my ($self, %args) = @_;

    foreach my $arg (keys %args) {
        if ($self->can($arg)) {
            $self->$arg($args{$arg});
        }
    }

    return;
}

=head2 $obj->user_error()

Log and store errors that should be visibile to the user.

=cut

sub user_error {
    my ($self, $msg) = @_;

    if (defined $msg) {
        $self->_user_error_msg($msg);
        error($msg);
    }

    return $self->_user_error_msg;
}

=head2 $obj->validate()

Confirms that the object is valid.  Checks that required attributes are set.

=cut

sub validate {
    trace '()';
    my ($self) = shift;

    my @required = $self->get_grouped_attrs('Required');
    my @optional = $self->get_grouped_attrs('Optional');

    info("required = " . join(', ', @required));
    trace("optional = " . join(', ', @optional));

    my @missing;
    foreach my $required_field (@required) {
        if (!$self->$required_field()) {
            push @missing, $required_field;
        }
    }

    if (@missing) {
        my $user_error = "Missing required argument(s): " . join ", ",
            @missing;
        $self->user_error($user_error);
        $self->invalid(1);
        return 0;
    }
    else {
        return 1;
    }
}

=head2 $self->get_grouped_attrs( $attribute_name )

=cut

# attr_name = Attribute Name.
sub get_grouped_attrs {
    my ($self, $attr_name) = @_;
    my @results = $self->$attr_name();

   #print "get_grouped_attrs( $attr_name ): " . join( ', ', @results ) . "\n";
    return @results;
}

=head2 $obj->rate_request()

This method is used to request shipping rate information from online providers
or offline tables.  A hash is accepted as input.  The acceptable values are 
determined by the shipper class, but the following are common to all:

=over 4

=item * shipper

The name of the shipper to use. Must correspond to a module by the name of:
C<Business::Shipping::SHIPPER>.  For example, C<UPS_Online>.

=item * service

A valid service name for the provider. See the corresponding module 
documentation for a list of services compatible with the shipper.

=item * from_zip

The origin zipcode.

=item * from_state

The origin state in two-letter code format or full-name format.  Required for 
UPS_Offline.

=item * to_zip

The destination zipcode.

=item * to_country

The destination country.  Required for international shipments only.

=item * weight

Weight of the shipment, in pounds, as a decimal number.

=back 

There are some additional common values:

=over 4

=item * user_id

A user_id, if required by the provider. USPS_Online and UPS_Online require
this, while UPS_Offline does not.

=item * password

A password,  if required by the provider. USPS_Online and UPS_Online require
this, while UPS_Offline does not.

=back

=cut

sub rate_request {
    my $class   = shift;
    my (%opt)   = @_;
    my $shipper = $opt{shipper};

    Carp::croak 'shipper required' unless $opt{shipper};

    $shipper = _compat_shipper_name($shipper);

    my $rr = Business::Shipping->_new_subclass($shipper . '::RateRequest');
    logdie "New $shipper::RateRequest object was undefined."
        if not defined $rr;

    $rr->init(%opt);

    return $rr;
}

# _compat_shipper_name
#
# Shipper name backwards-compatibility
#
# 1. Really old: "UPS" or "USPS" (implies Online::)
# 2. Semi-old:   "Online::UPS", "Offline::UPS", or "Online::USPS"
# 3. Current:    "UPS_Online", "UPS_Offline", or "USPS_Online"
sub _compat_shipper_name {
    my ($shipper) = @_;

    my %old_to_new = (
        'Online::UPS'  => 'UPS_Online',
        'Offline::UPS' => 'UPS_Offline',
        'Online::USPS' => 'USPS_Online',
        'UPS'          => 'UPS_Online',
        'USPS'         => 'USPS_Online'
    );
    $shipper = $old_to_new{$shipper} if $old_to_new{$shipper};

    return $shipper;
}

=head2 Business::Shipping->log_level()

Simple alternative to editing the config/log4perl.conf file.  Sets the log 
level for all Business::Shipping objects.  

Takes a scalar that can be 'trace', 'debug', 'info', 'warn', 'error', or 
'fatal'.

=cut

*log_level = *Business::Shipping::Logging::log_level;

#=head2 Business::Shipping->_new_subclass()
#
#Private Method.
#
#Generates an object of a given subclass dynamically.  Will dynamically 'use'
#the corresponding module, unless runtime module loading has been disabled via
#the 'preload' option.
#
#=cut

sub _new_subclass {
    my ($class, $subclass, %opt) = @_;

    croak("Error before _new_subclass was called: $@") if $@;

    my $new_class = $class . '::' . $subclass;

    if ($Business::Shipping::RuntimeLoad) {
        eval "use $new_class";
    }

    croak("Error when trying to use $new_class: \n\t$@") if $@;

    my $new_sub_object = eval "$new_class->new()";
    croak("Failed to create new $new_class object.  Error: $@") if $@;

    return $new_sub_object;
}

sub Optional { return qw/ tx_type /; }
sub Required { return (); }
sub Unique   { return (); }

1;

__END__

=head1 SEE ALSO

Important modules that are related to Business::Shipping:

=over 4

=item * Business::Shipping::DataFiles - Required for offline cost estimation

=item * Business::Shipping::DataTools - Tools that generate DataFiles (optional)

=back

Other Perl modules that are similar to Business::Shipping:

=over 4

=item * Business::UPS::Tracking - Online shipment tracking.

=item * WebService::UPS - Online shipment tracking

=item * Business::Shipping::UPS_XML - Online cost estimation module that has 
very few prerequisites.  Supports shipments that originate in USA and Canada.

=item * Business::UPS - Online cost estimation module that uses the UPS web form
instead of the UPS Online Tools.  For shipments that originate in the USA only.

=item * Net::UPS - Implementation of UPS Online Tools API in Perl

=back
 
=head1 Use of this software

Please let the author know how you are using Business::Shipping.

=over 4

=item * Advanced support and integration services are available from the 
author.

=item * Interchange e-commerce system ( L<http://www.icdevgroup.org> ).  See 
    C<UserTag/business-shipping.tag>.

=item * Many E-Commerce websites, such as Phatmotorsports.com.

=item * PaymentOnline.com software.

=item * The "Shopping Cart" Wobject for the WebGUI project, by Andy Grundman 
    L<http://www.plainblack.com/shopping_cart_wobject>

=item * Mentioned in YAPC 2004: "Writing web applications with perl ..."

=back

=head1 WEBSITE

Source code repository: L<https://github.com/danielbr/Business--Shipping>

CPAN web site: L<http://search.cpan.org/~dbrowning/Business-Shipping/>

Backpan (old releases): L<http://backpan.cpan.org/authors/id/D/DB/DBROWNING/>

Author homepage: L<http://www.kavod.com/Business-Shipping/>

=head1 SUPPORT

This module is supported by the author. Please report any bugs or feature 
requests to C<bug-business-shipping@rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org>. The author will be notified, and then you'll 
automatically be notified of progress on your bug as the author makes changes.

=head1 CREDITS

Many people have contributed to this software, please see the C<CREDITS> file. 

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
