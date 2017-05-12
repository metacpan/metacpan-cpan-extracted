package Business::Shipping::UPS_Online::RateRequest;

=head1 NAME

Business::Shipping::UPS_Online::RateRequest

=head1 REQUIRED FIELDS

user_id
password
access_key

If user_id,  password,  and/or access_key are not defined,  then the following 
shell environment variables will be used,  if defined:

UPS_USER_ID
UPS_PASSWORD
UPS_ACCESS_KEY

=head1 SERVICE TYPES

=head2 Domestic

    1DM       
    1DML      
    1DA       One Day Air
    1DAL      
    2DM       
    2DA       Two Day Air
    2DML      
    2DAL      
    3DS       Three Day Select
    GNDCOM    Ground Commercial
    GNDRES    Ground Residential
    
=head2 International
 
    XPR        UPS Worldwide Express
    XDM        UPS Worldwide Express Plus
    UPSSTD     UPS Standard
    XPRL       UPS Worldwide Express Letter
    XDML       UPS Worldwide Express Plus Letter
    XPD        UPS Worldwide Expedited

=head1 ARGUMENTS

=head2 Required

    user_id
    password
    access_key
    pickup_type
    from_country
    from_zip
    to_country
    to_zip
    to_residential
    service
    packaging
    weight
    
=head2 Optional

    test_server
    no_ssl
    event_handlers
    from_city
    to_city
    signature_type
    insured_currency_type
    insured_value

=head1 METHODS

=cut

use Any::Moose;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use Business::Shipping::UPS_Online::Package;
use Business::Shipping::UPS_Online::Shipment;
use Business::Shipping::Util;
use XML::Simple 2.05;
use CHI;
use LWP::UserAgent;
use POSIX ('strftime');
use version; our $VERSION = qv('400');

extends 'Business::Shipping::RateRequest::Online';

has 'shipment' => (
    is      => 'rw',
    isa     => 'Business::Shipping::UPS_Online::Shipment',
    default => sub { Business::Shipping::UPS_Online::Shipment->new() },
    handles => [
        'from_city',      'to_city',
        'from_country',   'from_country_abbrev',
        'to_country',     'to_ak_or_hi',
        'from_zip',       'to_zip',
        'packages',       'weight',
        'shipper',        'domestic',
        'intl',           'domestic_or_ca',
        'from_canada',    'to_canada',
        'from_ak_or_hi',  'packaging',
        'to_residential', 'cod',
        'cod_funds_code', 'cod_value',
        'signature_type', 'insured_currency_type',
        'insured_value',  'service_code',
        'service',        'service_name',
    ]
);

has 'shipper_number' => (is => 'rw');

=head1

=cut

=head2 access_key

=head2 test_server

=head2 no_ssl

=cut

has 'prod_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'https://www.ups.com/ups.app/xml/Rate'
);

has 'test_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'https://wwwcie.ups.com/ups.app/xml/Rate'
);

has 'access_key' => (is => 'rw');

__PACKAGE__->meta()->make_immutable();

sub Required { return ($_[0]->SUPER::Required, qw/ access_key /); }

sub Optional {
    return (
        $_[0]->SUPER::Optional,
        qw/ test_server no_ssl to_city packaging signature_type
            insured_currency_type insured_value /
    );
}
sub Unique { return ($_[0]->SUPER::Unique, qw/ packaging /); }

=head2 from_state()

Ignored.  For compatibility with UPS_Offline only.

=cut

sub from_state { }

=head2 pickup_type

=cut

sub pickup_type {
    my ($self) = @_;
    $self->{'pickup_type'} = shift if @_;

    # Translate alphas to numeric.
    my $alpha;
    $alpha = 1 if ($self->{'pickup_type'} =~ /\w+/);
    if ($alpha) {
        my %pickup_type_map = (
            'daily pickup'       => '01',
            'customer counter'   => '03',
            'one time pickup'    => '06',
            'on call air'        => '07',
            'letter center'      => '19',
            'air service center' => '20',
        );
        $self->{'pickup_type'} = $pickup_type_map{ $self->{'pickup_type'} }
            if $pickup_type_map{ $self->{'pickup_type'} }
                or $pickup_type_map{ lc($self->{'pickup_type'}) };
    }

    return $self->{'pickup_type'};
}

=head2 _massage_values

=cut

sub _massage_values {
    trace('called');
    my ($self) = @_;

    $self->shipment->massage_values;
    return;
}

=head2 _gen_request_xml

Generate the XML document.

=cut

sub _gen_request_xml {
    info('called');
    my ($self) = shift;

    logdie "No packages defined internally."
        unless ref $self->shipment->packages();
    foreach my $package (@{ $self->shipment->packages() }) {

        #print "package $package\n";
    }

    my $access_tree = {
        'AccessRequest' => [
            {   'xml:lang'            => 'en-US',
                'AccessLicenseNumber' => [$self->access_key()],
                'UserId'              => [$self->user_id()],
                'Password'            => [$self->password()],
            }
        ]
    };

    my $service = $self->shipment->service() || '';
    my $service_code = $self->shipment->service_code()
        or logdie "Could not get service_code for service '$service'";

    # 'Shipment' will be embedded in the $request_tree
    # It was broken out to reduce nesting.
    my %shipment_tree = (
        'Shipper' => [
            {   'Address' => [
                    {   'CountryCode' => [$self->from_country_abbrev()],
                        'PostalCode'  => [$self->from_zip()],
                    }
                ],
                'ShipperNumber' => [$self->shipper_number()],
            }
        ],
        'ShipTo' => [
            {   'Address' => [
                    {   'ResidentialAddress' => [$self->to_residential()],
                        'CountryCode'        => [$self->to_country_abbrev()],
                        'PostalCode'         => [$self->to_zip()],
                        'City'               => [$self->to_city()],
                    }
                ],
            }
        ],
        'Service'                    => [{ 'Code' => [$service_code], }],
        'ShipmentServiceSelfOptions' => {},
    );

    my $shipment = $self->shipment;

    my @packages;
    foreach my $package ($shipment->packages()) {

        my %package_service_options;

        if ($shipment->cod) {
            %package_service_options = (
                'PackageServiceOptions' => [
                    {   'COD' => [
                            {   'CODFundsCode' => [$shipment->cod_funds_code],
                                'CODCode'   => [3],    # Only valid value is 3
                                'CODAmount' => [
                                    {   'CurrencyCode' => ['USD'],
                                        'MonetaryValue' =>
                                            [$shipment->cod_value()],
                                    }
                                ],
                            }
                        ],
                    }
                ],
            );
        }

        ### If signature_type was defined and origin = dest = US
        if (defined($package->signature_type())
            && (!defined($self->to_country_abbrev())
                || $self->to_country_abbrev() eq 'US')
            && (!defined($self->from_country_abbrev())
                || $self->from_country_abbrev() eq 'US')
            )
        {
            if (!exists($package_service_options{PackageServiceOptions})) {
                $package_service_options{PackageServiceOptions} = [{}];
            }

            $package_service_options{PackageServiceOptions}[0]
                {DeliveryConfirmation}
                = [{ DCISType => [$package->signature_type()] }];
        }    # if signature

        ### If insured_value was defined
        if (defined($package->insured_value())) {
            if (!exists($package_service_options{PackageServiceOptions})) {
                $package_service_options{PackageServiceOptions} = [{}];
            }

            my $currCode
                = (defined($package->insured_currency_type()))
                ? $package->insured_currency_type()
                : 'USD';
            $package_service_options{PackageServiceOptions}[0]{InsuredValue}
                = [
                {   CurrencyCode  => [$currCode],
                    MonetaryValue => [$package->insured_value()],
                }
                ];
        }    # if signature

        push(
            @packages,
            {

                'PackagingType' => [
                    {   'Code'        => [$package->packaging()],
                        'Description' => ['Package'],
                    }
                ],

                'Description'   => ['Rate Lookup'],
                'PackageWeight' => [{ 'Weight' => [$package->weight()], }],

                %package_service_options
            },
        );
    }
    $shipment_tree{Package} = \@packages if (@packages > 0);

    my $req_option;
    $req_option = ucfirst $shipment->service
        if ucfirst $shipment->service eq 'Shop';

    my $request_tree = {
        'RatingServiceSelectionRequest' => [
            {   'Request' => [
                    {   'TransactionReference' => [
                            {   'CustomerContext' => ['Rating and Service'],
                                'XpciVersion'     => [1.0001],
                            }
                        ],
                        'RequestAction' => ['Rate'],
                        'RequestOption' => [$req_option],
                    }
                ],
                'PickupType' => [{ 'Code' => ['01'] }],
                'Shipment'   => [{%shipment_tree}]
            }
        ]
    };

    my $access_xml = '<?xml version="1.0"?>' . "\n"
        . XML::Simple::XMLout($access_tree, KeepRoot => 1);

    my $request_xml
        = $access_xml . "\n"
        . '<?xml version="1.0"?>' . "\n"
        . XML::Simple::XMLout($request_tree, KeepRoot => 1);

    trace($request_xml) if is_trace();

    return ($request_xml);
}

=head2 _handle_response

=head2 error_details()

See L<Business::Shipping::RateRequest> for full documentation.
Adds the following keys to each error:

 error_severity		: Transient, Hard, or Warning
 minimum_retry_seconds	: The minimum number of seconds to wait
 locations		: An arrayref of hashrefs.  Each hash ref has
			  the keys, element and attribute.  
 error_data		: An arrayref of strings containing the invalid data
			  
=cut

sub _handle_response {

    #trace '()';
    my ($self) = @_;

    my $response_tree = XML::Simple::XMLin(
        $self->response()->content(),
        ForceArray => 0,
        KeepRoot   => 0,
    );

    #use Data::Dumper; trace("response = " . Dumper($response_tree));

    my $status_code = $response_tree->{Response}->{ResponseStatusCode};
    my $status_description
        = $response_tree->{Response}->{ResponseStatusDescription};

    ### If there is an error
    if (exists($response_tree->{Response}->{Error})) {
        ### Lets work on an array, since there could be more than one
        my $errors
            = (ref($response_tree->{Response}->{Error}) eq 'ARRAY')
            ? $response_tree->{Response}->{Error}
            : [$response_tree->{Response}->{Error}];

        ### Loop through the errors, gathering the details and
        ### create a simple error message string
        my (@errorDetails, $errorMsg);
        foreach my $errorHash (@$errors) {
            ### Get some of the error details
            my $severity      = $errorHash->{ErrorSeverity};
            my $code          = $errorHash->{ErrorCode};
            my $error         = $errorHash->{ErrorDescription};
            my $retry_secs    = $errorHash->{MinimumRetrySeconds};
            my @err_locations = ();
            my @err_contents  = ();
            my $err_location  = '';

            # If it's a warning, ignore.
            next if $severity eq 'Warning';

            ### Check if the error location was given
            if (exists($errorHash->{ErrorLocation})) {
                ### There could be more than one
                my $locations
                    = (ref $errorHash->{ErrorLocation} eq 'ARRAY')
                    ? $errorHash->{ErrorLocation}
                    : [$errorHash->{ErrorLocation}];
                foreach my $location (@$locations) {
                    my ($elem, $attrib) = (
                        $location->{ErrorLocationElementName},
                        $location->{ErrorLocationAttributeName},
                    );
                    $err_location = $elem
                        if (!defined($err_location) || $err_location eq '');
                    push(@err_locations,
                        { element => $elem, attribute => $attrib });
                }
            }

            ### Check if the contents of the element in error was given
            if (exists($errorHash->{ErrorDigest})) {
                ### There could be more than one
                my $digests
                    = (ref $errorHash->{ErrorDigest} eq 'ARRAY')
                    ? $errorHash->{ErrorDigest}
                    : [$errorHash->{ErrorDigest}];
                foreach my $digest (@$digests) {
                    push(@err_contents, $digest);
                }
            }

            push(
                @errorDetails,
                {   error_code            => $code,
                    error_msg             => $error,
                    error_severity        => $severity,
                    minimum_retry_seconds => $retry_secs,
                    locations             => \@err_locations,
                    error_data            => \@err_contents
                }
            );

            if (!defined($errorMsg) && $error and $error !~ /Success/) {
                my $combined_error_msg
                    = "$status_description ($status_code): $error @ $err_location";
                $combined_error_msg =~ s/\s{3, }/ /g;
                $errorMsg = $combined_error_msg;
            }
        }    # foreach error

        ### Store the error message and details in the object
        $self->user_error($errorMsg);
        $self->error_details(@errorDetails);

        ### Status code is 1 on success and 0 on failure.
        ### Return, only if status code is 0
        return $self->is_success(0) if (!$status_code);

    }    # if there is an error

    my @services_results;
    my $ups_results;

    if ($self->service_name and $self->service_name eq 'Shop') {
        if (ref $response_tree->{RatedShipment} ne 'ARRAY') {
            $self->user_error("UPS did not return shopped services");
            return $self->clear_is_success();
        }
        $ups_results = $response_tree->{RatedShipment};
    }
    else {

      # UPS doesn't provide an array for only one shipment,  so lets make one.
        $ups_results = [$response_tree->{RatedShipment}];
    }

    #use Data::Dumper;
    #debug "ups_results = " . Dumper( $ups_results );

    foreach my $ups_rate_info (@$ups_results) {

        my $service_code = $ups_rate_info->{Service}->{Code};
        my $charges      = $ups_rate_info->{TotalCharges}->{MonetaryValue};
        my $deliv_days   = $ups_rate_info->{GuaranteedDaysToDelivery};

        # When there is no deliv_days,  XML::Simple sets it to an empty hash.

        $deliv_days = undef if ref $deliv_days eq 'HASH';
        my $deliv_date;
        my $deliv_date_formatted;

        if ($deliv_days) {

# This code is more elegant, but we're reducing the number of required modules.
#
#use DateTime;
#my $dt = DateTime->now;
#$dt->add( DateTime::Duration->new( days => $deliv_days ) );
#$deliv_date = $dt->ymd;

            my @deliv_date = localtime(time + ($deliv_days * 86400));
            $deliv_date           = strftime "%Y-%m-%d",  @deliv_date;
            $deliv_date_formatted = strftime "%a, %b %e", @deliv_date;
        }

        my $service_hash = {
            code => $service_code,
            nick => $self->shipment->service_code_to_nick($service_code),
            name => $self->shipment->service_code_to_name($service_code),
            deliv_days => $deliv_days,
            deliv_date => $deliv_date,
            charges    => $charges,
            charges_formatted =>
                Business::Shipping::Util::currency({}, $charges),
            deliv_date_formatted => $deliv_date_formatted,
        };

        push @services_results, $service_hash;
    }

    return $self->clear_is_success() unless (@services_results);

    # Just in case.

    for ('shipper', 'service') {
        if (!$self->shipment->$_()) {
            $self->shipment->$_('Unknown');
        }
    }

    my $results = [
        {   name  => $self->shipper(),
            rates => \@services_results,
        }
    ];

    #trace 'results = ' . uneval(  $results );
    $self->results($results);

    return $self->is_success(1);
}

=head2 to_country_abbrev()

We have to override the to_country_abbrev function becuase UPS_Online
likes its own spellings of certain country abbreviations (GB,  etc.).

Redefines attribute.

=cut

sub to_country_abbrev {
    my ($self) = @_;

    return unless $self->to_country;

    # Do the UPS translations
    #info('to_country = ' . $self->to_country());
    my $online_ups_country_to_abbrev
        = cfg()->{ups_information}->{online_ups_country_to_abbrev};

    # The Config module doesn't give an array ref if it's just one value
    # any more, so we do that ourselves.
    if ($online_ups_country_to_abbrev
        and ref $online_ups_country_to_abbrev ne 'ARRAY')
    {
        $online_ups_country_to_abbrev = [$online_ups_country_to_abbrev];
    }
    my $countries = config_to_hash($online_ups_country_to_abbrev);

#info('online_ups_country_to_abbrev LUT = ' . Data::Dumper::Dumper($online_ups_country_to_abbrev));
#info('country LUT = ' . Data::Dumper::Dumper($countries));
    my $to_country_abbrev = $countries->{ $self->to_country }
        || $self->shipment->to_country_abbrev();

    #info("to_country_abbrev returning $to_country_abbrev");
    return $to_country_abbrev || $self->to_country;
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
