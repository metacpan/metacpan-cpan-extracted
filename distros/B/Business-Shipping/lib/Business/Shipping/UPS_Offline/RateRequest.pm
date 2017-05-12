package Business::Shipping::UPS_Offline::RateRequest;

=head1 NAME

Business::Shipping::UPS_Offline::RateRequest

=head1 GLOSSARY

=over 4

=item * EAS    Extended Area Surcharge

=item * DAS    Delivery Area Surcharge (same as EAS)

=back

=head1 METHODS

=cut

use strict;
use warnings;
use Business::Shipping::UPS_Offline::Shipment;
use Business::Shipping::UPS_Offline::Package;
use Business::Shipping::Logging;
use Business::Shipping::Util;
use Business::Shipping::Config;
use Business::Shipping::DataFiles 1.02;
use POSIX qw{ ceil strftime };

#use Fcntl ':flock';
#use File::Find;
#use File::Copy;
#use Math::BaseCnv;
#use Data::Dumper;
use Storable;
use Cwd;
use version; our $VERSION = qv('400');
use Any::Moose;

=head2 update

=head2 download

=head2 unzip

=head2 convert

=head2 is_from_west_coast

=head2 is_from_east_coast

=head2 to_residential

=head2 Zones

Hash.  Format:

    $self->Zones() = (
        'Canada' => {
            'zone_data' => [
                'low    high    service1    service2',
                '004    005        208            209',
                '006    010        208            209',
                'Canada    Canada    504            504',
            ]
        }
    )

=head2 zone_file

=head2 zone_name

  - For International, it's the name of the country (e.g. 'Canada')
  - For Domestic, it is the first three of a zip (e.g. '986')
  - For Canada, it is...?

=cut

extends 'Business::Shipping::RateRequest::Offline';

has 'update'             => (is => 'rw');
has 'download'           => (is => 'rw');
has 'unzip'              => (is => 'rw');
has 'convert'            => (is => 'rw');
has 'is_from_west_coast' => (is => 'rw');
has 'zone_file'          => (is => 'rw');
has 'zone_name'          => (is => 'rw');
has 'type'               => (is => 'rw');
has 'zone'               => (is => 'rw');

has 'shipment' => (
    is      => 'rw',
    isa     => 'Business::Shipping::UPS_Offline::Shipment',
    default => sub { Business::Shipping::UPS_Offline::Shipment->new() },
    handles => [
        'from_country',   'from_country_abbrev',
        'to_country',     'to_country_abbrev',
        'to_ak_or_hi',    'from_zip',
        'to_zip',         'packages',
        'weight',         'shipper',
        'domestic',       'intl',
        'domestic_or_ca', 'from_canada',
        'to_canada',      'from_ak_or_hi',
        'from_state',     'from_state_abbrev',
        'tier',           'service',
        'service_nick',   'service_name',
    ]
);

# Zones is deprecated.
has 'Zones' => (is => 'rw');
has 'Data' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'Fuel_surcharge_ground' => (is => 'rw');
has 'Fuel_surcharge_air'    => (is => 'rw');

__PACKAGE__->meta()->make_immutable();

sub _init {
    $_[0]->set_fuel_surcharge();
}

=head2 * Required()

from_state only required for Offline international orders.

=cut

sub Required {
    my ($self) = @_;

    my @required;

    if ($self->to_canada) {
        @required = qw/ service from_state          /;
    }
    elsif ($self->intl) {
        @required = qw/ service from_zip from_state /;
    }
    else {
        @required = qw/ service from_zip            /;
    }

    return ($self->SUPER::Required, @required);
}

sub Optional { return ($_[0]->SUPER::Optional, qw/ to_residential /); }
sub Unique   { return ($_[0]->SUPER::Unique,   qw/ to_residential /); }

sub to_residential     { return shift->shipment->to_residential(@_); }
sub is_from_east_coast { return not shift->is_from_west_coast(); }

sub set_fuel_surcharge {
    my ($self) = @_;

    # See bin/Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

    my $fuel_surcharge_filename
        = Business::Shipping::Config::config_dir . '/fuel_surcharge.txt';

#error( "fuel_surcharge_filename = $fuel_surcharge_filename, current dir = " . Cwd::cwd() );
    my $fuel_surcharge_contents = readfile($fuel_surcharge_filename);
    my (@lines) = split("\n", $fuel_surcharge_contents);

    #info( "lines = " . join( "\n", @lines ) . "\n\n\n" );

    my (undef, $ground_through_fuel_surcharge) = split(': ', $lines[0]);
    my (undef, $through_date)                  = split(': ', $lines[1]);
    my (undef, $air_through_fuel_surcharge)    = split(': ', $lines[2]);

    # line 4 skipped.
    my (undef, $ground_effective_fuel_surcharge)
        = split(': ', $lines[4] || '');
    my (undef, $effective_date) = split(': ', $lines[5] || '');
    my (undef, $air_effective_fuel_surcharge) = split(': ', $lines[6] || '');

    # line 8 skipped.

    my $g_fuel_surcharge;
    my $a_fuel_surcharge;

    # Determine today's date, and see if it is past the $good_through_date.
    my $today = strftime("%Y%m%d", localtime(time));
    if ($today <= $through_date) {
        $g_fuel_surcharge = $ground_through_fuel_surcharge;
        $a_fuel_surcharge = $air_through_fuel_surcharge;
    }
    else {
        $g_fuel_surcharge = $ground_effective_fuel_surcharge;
        $a_fuel_surcharge = $air_effective_fuel_surcharge;
    }

    $self->Fuel_surcharge_ground($g_fuel_surcharge);
    $self->Fuel_surcharge_air($a_fuel_surcharge);

    return;
}

=head2 validate

=cut

sub validate {
    my ($self) = @_;
    trace '()';

    return if (!$self->SUPER::validate);

    if ($self->service_nick) {
        if ($self->service_nick eq 'GNDRES' and $self->to_ak_or_hi) {
            $self->user_error(
                "Invalid Rate Request: Ground Residential to AK or HI.");
            $self->invalid(1);
            return 0;
        }

        if ($self->service_nick eq 'UPSSTD' and not $self->to_canada) {
            $self->user_error(
                "UPS Standard service is available to Canada only.");
            $self->invalid(1);
            return 0;
        }
    }

    if (    $self->to_canada
        and $self->to_zip
        and $self->to_zip =~ /\d\d\d\d\d/)
    {
        $self->user_error(
            "Cannot use US-style zip codes when sending to Canada");
        $self->invalid(1);
        return 0;
    }

    return 1;
}

=head2 _handle_response
    
=cut

sub _handle_response {
    my $self = $_[0];

    my $total_charges;

# determines which file we look for the zone in, and which key we use to search.
    my ($zone_key, $zone_file) = $self->calc_zone_info;
    $self->determine_coast;
    $self->load_table($zone_file);
    $self->calc_zone($zone_key, $zone_file) or return $self->is_success(0);

# The fuel surcharge also applies to the following accessorial charges:
#  * On-Call Pickup Charges
#  * UPS Next Day Air Early A.M./UPS Express Plus Charges
#  * International Extended Area Charges
#  * Remote Delivery Charges
#  * Saturday Delivery
#  * Saturday Pickup
# In other words, it applies *after* all the other surcharges have been added.

    my @price_components = (
        {   component   => 'cost',
            description => 'Cost',
            fatal       => 1,
        },
        {   component   => 'express_plus_adder',
            description => 'Express Plus',
        },
        {   component   => 'delivery_area_surcharge',
            description => 'Delivery Area Surcharge',
        },
        {   component   => 'residential_surcharge',
            description => 'Ground Residential Differential',

            #residential_surcharge AKA "Ground Residential Differential"
        },
        {   component   => 'fuel_surcharge',
            description => 'Fuel Surcharge',
        }
    );

    my $final_price_components;

# This is where, for example, calc_cost, calc_fuel_surcharge, etc. get executed.
    foreach my $price_component (@price_components) {

        my $fn = "calc_" . $price_component->{component};

        my $price;
        if ($self->can($fn)) {
            $price = $self->$fn();
        }

        # Most of the price components we don't really care about, but some
        # are pretty important (like the main 'cost').
        if (!$price) {
            if ($price_component->{fatal}) {
                return $self->is_success(0);
            }
            else {
                next;
            }
        }
        trace "adding price $price to final_components";

        push @$final_price_components,
            {
            price       => $price,
            description => $price_component->{description}
            };
        $self->_increase_total_charges($price);
    }

    $self->price_components($final_price_components);

    $total_charges = Business::Shipping::Util::currency({ no_format => 1 },
        $self->_total_charges);

    my $name = $self->shipper();

    info "total_charges = $total_charges";

    my $results = [
        {   name  => $name,
            rates => [
                {   charges           => $total_charges,
                    charges_formatted => Business::Shipping::Util::currency(
                        {}, $total_charges
                    ),
                },
            ]
        }
    ];

    #trace 'results = ' . uneval( $results );
    $self->results($results);

    return $self->is_success(1);
}

=head2 $self->_increase_total_charges( $amount )

Increase the _total_charges by an amount.

=cut

sub _increase_total_charges {
    my ($self, $increase) = @_;

    $self->_total_charges(($self->_total_charges || 0) + $increase);

    return;
}

=head2 calc_express_plus_adder

=cut

sub calc_express_plus_adder {

    my ($self) = @_;

    if ($self->service_name =~ /plus/i) {
        return cfg()->{ups_information}->{express_plus_adder} || 40.00;
    }

    return 0;
}

=head2 calc_delivery_area_surcharge

The "Delivery Area Surcharge" is also known as "Extended Area Surcharge", but 
does not include special residential charges that apply to some services (air
services, for example).

=cut

# TODO: Calculate the delivery area surcharge amount from the accessorials.csv

# TODO: Handle international too.

sub calc_delivery_area_surcharge {
    my ($self) = @_;

    debug "Checking delivery area surcharge...";

    # Does not apply to hundredweight service.
    return 0.00 if ($self->service_name eq 'Ground Hundredweight Service');

    if ($self->domestic) {

        #info "is domestic...";
        my $table = 'xarea';
        $self->load_table($table);
        my $zip_codes = $self->Data->{$table}->{table};

        my $to_zip = $self->to_zip;
        my $is_das = binary_numeric_exact_match($zip_codes, $to_zip);

        if ($is_das) {
            if ($self->to_residential) {
                return cfg()->{ups_das}->{domestic_res} || 2.00;
            }
            else {
                return cfg()->{ups_das}->{domestic_com} || 1.25;
            }
        }
    }

    return 0.00;
}

=head2 $self->calc_residential_surcharge()

Note that this is different than the delivery area surcharge.
It is listed as "Residential Differential" in the accessorials.csv file.

=cut

sub calc_residential_surcharge {
    my ($self) = @_;

    my $ups_service_name = $self->service_name;
    my @exempt_services  = qw/
        Ground Hundredweight Service
        /;

    my $ground_residential_differential
        = cfg()->{ups_das}->{ground_residential_differential} || 1.50;
    my $air_residential_differential
        = cfg()->{ups_das}->{air_residential_differential} || 1.50;
    my $residential_differential
        = $self->shipment->is_ground
        ? $ground_residential_differential
        : $air_residential_differential;

    return 0 if $self->intl;
    return 0 if grep /^${ups_service_name}$/, @exempt_services;
    return $residential_differential if $self->to_residential;
    return 0;
}

=head2 calc_fuel_surcharge

=cut

sub calc_fuel_surcharge {
    my ($self) = @_;

    my $fuel_surcharge;
    if ($self->shipment->is_ground) {
        $fuel_surcharge = $self->Fuel_surcharge_ground;
    }
    else { $fuel_surcharge = $self->Fuel_surcharge_air; }

    $fuel_surcharge ||= 0;
    $fuel_surcharge *= .01;

# Currently, we apply the fuel surcharge to everything.  But in actuality, not all
# fees are applicable.  Just the basic "rate cost" and delivery area surcharges.
# Eventually, we'll need to use something else besides _total_charges.
    $fuel_surcharge *= $self->_total_charges;

    return $fuel_surcharge;
}

=head2 ups_name_to_table

Find rate table using UPS 'type' or name at the top of the table.

=cut

sub ups_name_to_table {
    my ($self, $ups_name) = @_;

    if (!$ups_name) {
        $self->user_error("Need ups_name parameter.");
        return;
    }

    my $translate_map = cfg()->{ups_names_in_zone_file_to_table_map};

    if ($translate_map->{$ups_name}) {
        my $name = $translate_map->{$ups_name};

        if ($name eq 'gndres') {
            $self->to_residential(1);
            return 'gndcomm';
        }
        return $name;
    }
    else {
        return $ups_name;
    }
}

# calc_zone_data() is gone.  New code uses calc_zone()

=head2 determine_keys()

Decides what unique keys will be used to locate the zone record.  

 * The first key ("key") is a shortened version (the zip code "98682" becomes
   "986") to locate the zone file and the range that it fits into.
   
 * The second key ("raw_key") is the actual key, for looking up the record
   in the correct zone file once it has been found.

Returns ( $key, $raw_key )

=cut

sub determine_key {
    my ($self) = @_;

    # The raw key isn't used any more.
    #my $raw_key;
    my $key;

    if ($self->domestic_or_ca) {

        # Domestic and Canada - by ZIP code
        if (!$self->to_zip) {
            $self->user_error("Need to_zip.");
            $self->invalid(1);
            return;
        }

        #$raw_key = $self->to_zip;
        $key = $self->to_zip;
        $key = substr($key, 0, 3);
        $key =~ s/\W+//g;
        $key = uc $key;
    }
    elsif ($self->intl) {

        # International - by country name
        $key = $self->to_country;

        #$raw_key = $key;
    }

    return $key;
}

=head2 rate_table_exceptions

WorldWide methods use different tables for Canada

=cut

sub rate_table_exceptions {
    my ($self, $type, $table) = @_;

    return $table unless $self->to_country;
    my $exceptions_cfg
        = cfg()->{ups_names_in_zone_file_to_table_map_exceptions}
        ->{ $self->to_country };
    return $table unless $exceptions_cfg;

    my $exceptions_hash = config_to_hash($exceptions_cfg);
    trace(
        "type = $type, table = $table, looking for type in exceptions hash..."
    );

    if ($exceptions_hash->{$type}) {
        $table = $exceptions_hash->{$type};
        trace("table exception found: $table");
    }
    else {
        trace("No table exception found.  Returning regular table $table");
    }

    return $table;
}

sub load_table {
    my ($self, $table) = @_;

    if (!$self->Data->{$table}) {
        my $filename = Business::Shipping::Config::data_dir . "/$table.dat";
        info "loading filename $filename";
        if (!-f $filename) {

# Current working directory is useful to know if the $filename is not an absolute path.
            my $error_append = '';
            if ($filename !~ m|^/|) {
                my $cur_working_dir = Cwd::cwd();
                $error_append = " (current working dir: $cur_working_dir)";
            }
            return error "file does not exist: ${filename}${error_append}";
        }
        $self->Data->{$table} = Storable::retrieve($filename);
    }

    return;
}

=head2 calc_zone( )

=cut

sub calc_zone {
    my ($self, $zone_key, $zone_file) = @_;

    # zone_name is like "986".

    if (!$self->zone_name) {
        $self->user_error("Need zone_name");
        return;
    }
    if (!$self->shipment->service_nick2) {
        $self->user_error("Need service");
        return;
    }

    my $zone_name = $zone_key;

    #my $zone_file_basename = File::Basename::basename( $zone_file );

    my $type
        = $self->shipment->service_nick2; # The column name we're looking for.

    my $key = $self->determine_key || return error "Could not determine key.";

    my $obj = $self->Data->{$zone_file};

    #die "woot";
    my $table_data = $obj->{table}
        || $self->user_error("Could not get table data") && return;

    my $col_idx = $obj->{meta}->{col_idx};
    my $cols    = $obj->{meta}->{columns};
    my $zone;

    # Handle eastcoast / westcoast fieldnames
    # Except for Canada.
    if (not $self->to_canada) {

        # The only other Expedited methods are intl.
        if ($type eq 'Expedited') {
            $type
                = $self->is_from_west_coast()
                ? 'Expedited_WC'
                : 'Expedited_EC';
        }
    }

    #die "type = '$type'";
    $self->type($type);

# TODO: binary search here as well
#$key = cnv( $key, 36, 10 ) if $self->shipment->to_canada; # We're using lt and gt instead of numeric
    info "number of records to check: " . scalar(@$table_data);

    foreach my $record (@$table_data) {
        my ($min, $max) = @$record[0, 1];

     #trace "checking if $key >= $min and $key <= $max";
     # TODO: detect if the zone name is numeric, then use numeric comparisons?
        if ($self->shipment->to_canada) {

#
# Canada uses a base-36 (0-10 + A-Z) zip number system.
# Use a base converter to convert the numbers to base-10
# just for the sake of comparison.
#
# This would be done in the DataTools, but we're not even using numeric comparisons anymore.
#
# $min = cnv( $min, 36, 10 );
# $max = cnv( $max, 36, 10 );

        }

      # Note that here we use less than or equal to instead of just less than.
        if (   ($self->shipment->domestic and $key >= $min and $key <= $max)
            or ($self->shipment->to_canada and $key ge $min and $key le $max)
            or ($self->shipment->intl and lc $key eq lc $min))
        {
            info "found zone record:" . join(', ', @$record);

#info "(key = $key, min = $min, max = $max)";
#my $col_num = $col_idx{ $self->service_nick2 } or do {
#    error "Could not find the column ($self->service_nick2) in the column list: "
#        . join( ', ', @$cols );
#    return;
#};
            my $col_num = $col_idx->{$type};
            if (not defined $col_num) {
                error "could not find column for " . $type;
                info "columns were: " . join(', ', keys %$col_idx);
                return;
            }
            $zone = $record->[$col_num];    # Minus one if International?

            if (not $zone) {
                error "Zone empty";
            }
            elsif ($zone eq '-') {
                $self->user_error(
                    "UPS does not ship to this zone via this service.");
            }
            elsif ($zone =~ /^\[\d+\]$/) {
                $zone = $self->special_zone_hi_ak($type);
                if (not defined $zone) {
                    $self->user_error(
                        "UPS does not ship to this zone via this service.");
                }
            }
            else {
                info "Setting zone to $zone";
            }
            last;
        }
    }

    if (not defined $zone) {
        $self->user_error("No zone found for geo code (key) "
                . ($key  || 'undef') . ", " . "type "
                . ($type || 'undef')
                . '.');
        return 0;
    }
    elsif (!$zone or $zone eq '-') {
        $self->user_error("No $type shipping allowed for $key.");
        $self->invalid(1);
        return 0;
    }

    $self->type($type);
    $self->zone($zone);

    return ($zone);
}

=head2 calc_cost( )

=cut

sub calc_cost {
    my ($self) = @_;

    my $table = $self->ups_name_to_table($self->type);
    $table
        = $self->rate_table_exceptions($self->shipment->service_nick, $table);

    #die "type = " . $self->type;
    info("rate table = " . ($table ? $table : 'undef'));

# Check to see if this shipment qualifies for hundred-weight shipping, which is probably
# cheaper than regular shipping if it qualifies.
# Requires that it be multi-package, over a certain total weight, and only certain services.
# 100 pounds for airborn services, 200 pounds for ground (Ground, 3DS)
    my $cost;
    if ($self->shipment->use_hundred_weight) {
        my $weight = $self->shipment->weight;

        # Tables don't cover fractional pounds, and UPS specifies "at least",
        # so any fraction should cause a jump to the next integer.
        $weight = POSIX::ceil($weight);

        my $h_table = $self->shipment->get_hundredweight_table($table);
        info "Using hundredweight with table $h_table";

        my $rate_val = $self->get_cost($h_table, $self->zone, $weight);

        if (!$rate_val and $self->tier) {

# Many tier tables are not implemented yet.
# TODO: remove this after all the tier levels are implemented for all the services.
            info "No rate for tier '"
                . $self->tier
                . "'.  Try removing tier.";
            $h_table =~ s/\d$//;
            $rate_val = $self->get_cost($h_table, $self->zone, $weight);
        }

        if ($self->shipment->cwt_is_per eq 'hundredweight') {
            my $number_of_hundred_pounds = $weight * 0.01;
            my $rate_per_hundred_pounds  = $rate_val;
            $cost = $number_of_hundred_pounds * $rate_per_hundred_pounds;
            debug
                "cwt is per hundredweight, num of hundredpounds ($number_of_hundred_pounds) * rate_per_hund ($rate_per_hundred_pounds) = cost ($cost)";
        }
        elsif ($self->shipment->cwt_is_per eq 'pound') {
            $cost = $rate_val * $weight;
            debug
                "cwt is per pound, rate val ($rate_val) * weight ($weight ) = cost ($cost)";
        }
        else {
            error "unknown is_per type";
        }
    }
    else {
        my $running_sum_cost;
        foreach my $package ($self->shipment->packages) {

            my $weight = $package->weight;

            # Here we can adapt for pounds/kg
            #if ($zref->{mult_factor}) {
            #    $weight = $weight * $zref->{mult_factor};
            #}

            # Tables don't cover fractional pounds, and UPS specifies
            # "at least", so any fraction should cause a jump to the next
            # integer.
            $weight = POSIX::ceil($weight);

            $cost = $self->get_cost($table, $self->zone, $weight);

            $running_sum_cost += $cost if $cost;
        }
        $cost = $running_sum_cost;
    }

    if (!$cost) {
        $self->user_error("Zero cost returned for mode "
                . $self->type()
                . ", geo code (key) "
                . $self->zone);
        return 0;
    }

    info "cost = $cost";

    # TODO: Surcharge table + Surcharge_field?
    # TODO: Residential field (same table)?

    return $cost || 0;
}

sub get_cost {
    my ($self, $table, $zone, $weight) = @_;

    $self->load_table($table);
    my $table_data = $self->Data->{$table}->{table};

    # "Zone name to array element number" for later lookups.
    my $col_idx = $self->Data->{$table}->{meta}->{col_idx};

    #my $row = seq_scan( $table_data, $weight );
    my $row = binary_numeric($table_data, $weight);
    info "searching for weight $weight";

    # Calculate cost from row.
    if (not defined $row) {
        error "Could not find cost in rate table, no matching records.";
        return;
    }

    my $col_num = $col_idx->{$zone};
    if (not defined $col_num) {
        error "Could not get column index from zone name/number";
        return;
    }

    my $this_cost = $row->[$col_num];
    if (not $this_cost) {
        error
            "Could not find cost in rate table, matching record did not have data for this zone.";
        return;
    }

    return $this_cost;
}

=head2 seq_scan( $array, $target )

Sequential scan.

=cut

sub seq_scan {
    my ($array, $target) = @_;

    foreach my $c (0 .. @$array - 1) {
        my $row = $array->[$c];

   #my ( $min, $max ) = ( $row->[ 0 ], $row->[ 1 ] ); # TODO: Use array slice.
        if ($target >= $row->[0] and $target < $row->[1]) {
            return $row;
        }
    }

    return;
}

=head2 binary_numeric_exact_match

=cut

sub binary_numeric_exact_match {
    my ($array, $target) = @_;

    # $low is first element that is not too low;
    # $high is the first that is too high
    my ($low, $high) = (0, scalar(@$array));

    # Keep trying as long as there are elements that might work.
    while ($low < $high) {

        # Try the middle element.

        use integer;
        my $cur = ($low + $high) / 2;

        my $this_value = $array->[$cur];

#print STDERR "Row $cur:low = $low, high = $high, target = $target, min = $min, max = $max\n";

        if ($target < $this_value) {

            # Too high, try lower
            $high = $cur;
        }
        elsif ($target > $this_value) {

            # Too low, try higher
            $low = $cur + 1;
        }
        elsif ($target == $this_value) {

            # Just right.  Return matching row.
            return $this_value;
        }
        else {

            # This can never happen.
            error("Bug in binary search (numeric exact match)");
        }
    }

    # Didn't find the record
    return;
}

=head2 binary_numeric( $array, $target )

From Mastering Algorithms in Perl, modified to handle rows and my own matching specifications.

=cut

sub binary_numeric {
    my ($array, $target) = @_;

    return unless ref $array eq 'ARRAY';

    # $low is first element that is not too low;
    # $high is the first that is too high
    my ($low, $high) = (0, scalar(@$array));

    # Keep trying as long as there are elements that might work.
    while ($low < $high) {

        # Try the middle element.

        use integer;
        my $cur = ($low + $high) / 2;

        my $row = $array->[$cur];
        my ($min, $max) = ($row->[0], $row->[1]);    # TODO: Use array slice.

#print STDERR "Row $cur:low = $low, high = $high, target = $target, min = $min, max = $max\n";

        if ($target < $min) {

            # Too high, try lower
            $high = $cur;
        }
        elsif ($target > $max) {

            # Too low, try higher
            $low = $cur + 1;
        }
        elsif ($target >= $min and $target <= $max) {

            # Just right.  Return matching row.
            return $row;
        }
    }

    # Didn't find the record, returning.
    return;
}

=head2 special_zone_hi_ak( $type )

 $type    Type of service.
 
Hawaii and Alaska have special per-zipcode zone exceptions for 1da/2da.

=cut

sub special_zone_hi_ak {
    my ($self, $type) = @_;
    trace('( ' . ($type ? $type : 'undef') . ' )');
    my $zone;
    return $zone
        unless $type and ($type eq 'NextDayAir' or $type eq '2ndDayAir');

    my @hi_special_zipcodes_124_224 = split(',',
        (cfg()->{ups_information}->{hi_special_zipcodes_124_224} or ''));
    my @hi_special_zipcodes_126_226 = split(',',
        (cfg()->{ups_information}->{hi_special_zipcodes_126_226} or ''));
    my @ak_special_zipcodes_124_224 = split(',',
        (cfg()->{ups_information}->{ak_special_zipcodes_124_224} or ''));
    my @ak_special_zipcodes_126_226 = split(',',
        (cfg()->{ups_information}->{ak_special_zipcodes_126_226} or ''));
    trace(    "zip="
            . $self->to_zip
            . ".  Hawaii special zip codes = "
            . join(",\t", @hi_special_zipcodes_124_224));

    my $to_zip = $self->to_zip;
    if (grep(/^$to_zip$/,
            @hi_special_zipcodes_124_224, @ak_special_zipcodes_124_224)
        )
    {
        if ($type eq 'NextDayAir') {
            $zone = '124';
        }
        elsif ($type eq '2ndDayAir') {
            $zone = '224';
        }
    }
    if (grep(/^$to_zip$/,
            @hi_special_zipcodes_126_226, @ak_special_zipcodes_126_226)
        )
    {
        if ($type eq 'NextDayAir') {
            $zone = '126';
        }
        elsif ($type eq '2ndDayAir') {
            $zone = '226';
        }
    }

    return $zone;
}

=head2 calc_zone_info()

Determines which zone (zone_name), and which zone file to use for lookup.

=cut

sub calc_zone_info {
    trace '()';
    my ($self) = @_;

    my $zone;
    my $zone_file;
    my $data_dir_name = Business::Shipping::Config::data_dir_name();
    if ($self->domestic) {
        info("domestic");
        if (!$self->from_zip) {
            $self->user_error("Need from_zip");
            return;
        }
        info "from_zip = " . $self->from_zip;
        $zone      = $self->make_three($self->from_zip);
        $zone_file = $zone;
    }
    elsif ($self->to_canada) {
        info("to canada");
        $zone = $self->make_three($self->to_zip);

        if ($self->service_nick eq 'UPSSTD') {

         #
         # TODO: Build a list of state names => "UPS Standard zone file names"
         #
            if ($self->from_ak_or_hi) {

           #
           # An Alaska or Hawaii source has it's own complete set of data. :-(
           #
                $self->user_error(
                    "UPS Standard from Alaska or Hawaii not supported.")
                    and return;
            }
            my $state_to_upsstd_zone_file
                = cfg()->{ups_information}->{state_to_upsstd_zone_file};
            my $states = config_to_hash($state_to_upsstd_zone_file);

            if (    $self->from_state_abbrev
                and $states->{ $self->from_state_abbrev })
            {
                $zone_file = $states->{ $self->from_state_abbrev };
                trace(
                    "Found state in the state to upsstd_zone_file configuration "
                        . "parameter, zone_file = $zone_file ");
            }
            else {
                $self->user_error(
                    "could not find state in \'state to UPS Standard zone file\' converter."
                );
                return;
            }
        }
        else {

            #
            # WorldWide Expedited/Express uses the 'canww' zone file.
            #
            $zone_file = "canww";
        }
    }
    else {
        $zone = $self->to_country();

        $zone_file = 'ewwzone';
    }
    my $data_dir            = Business::Shipping::Config::data_dir();
    my $zone_file_with_path = "$data_dir/$zone_file.dat";

    # If you can't find the zone file on the first try, try up to 10 times.
    # (Sometimes, zips like 97214 are in a different file, like 970).
    # TODO: analyze all the zone files and use the metadata to build a map
    # of which zips go to which file.
    #
    # Only apply if the zone is purly numeric.

    if (Business::Shipping::Util::looks_like_number($zone)) {
        for my $c (1 .. 10) {
            if (!-f $zone_file_with_path) {
                trace(
                    "Zone file '$zone_file_with_path' doesn't exist, trying others nearby ($zone)..."
                );
                my $zone = $zone - $c;
                $zone_file           = $zone;
                $zone_file_with_path = "$data_dir/$zone.dat";
            }
        }
    }

    info(
        "zone_name = $zone, zone file = $zone_file, zone_file_with_path = $zone_file_with_path"
    );
    $self->zone_name($zone);
    $self->zone_file($zone_file);

    #$self->zone_file_with_path( $zone_file_with_path );

    return ($zone, $zone_file);
}

=head2 determine_coast

If this is an international order, we need to determine which state the shipper
is in, then if it is east or west coast.  If west, then use the first "Express" field
in the zone chart.  If east, then use the second.

=cut

sub determine_coast {
    my ($self) = @_;

    if ($self->intl() and $self->from_state()) {

        my @west_coast_states_abbrev
            = split(',', cfg()->{ups_information}->{west_coast_states});
        my @east_coast_states_abbrev
            = split(',', cfg()->{ups_information}->{east_coast_states});

        for (@west_coast_states_abbrev) {
            if ($_ eq $self->from_state_abbrev()) {
                $self->is_from_west_coast(1);
            }
        }
        for (@east_coast_states_abbrev) {
            if ($_ eq $self->from_state_abbrev()) {
                $self->is_from_west_coast(0);
            }
        }
    }

    return;
}

=head2 * readfile( $file )

Note: this is not an object-oriented method.

=cut

sub readfile {
    my ($file) = @_;

    return unless open my $readin_fh, '<', $file;

    # TODO: Use English;

    undef $/;

    my $contents = <$readin_fh>;
    close($readin_fh);

    return $contents;
}

=head2 _massage_values()

Performs some final value modification just before the submit.

=cut

sub _massage_values {
    my ($self) = @_;
    trace '()';

    # In order to share the Shipment::UPS object between both UPS_Online and
    # UPS_Offline, we do a little magic.  If it gets more complex than this,
    # subclass it instead.

    $self->shipment->offline(1);

    # Default is residential: yes.

    if (not defined $self->to_residential) { $self->to_residential(1); }

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
