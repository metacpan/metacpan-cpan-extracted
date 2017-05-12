package Business::GL::Postalcode;

use strict;
use warnings;
use 5.010; #5.10.0

use Class::Business::GL::Postalcode;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_all_data get_all_postalcodes get_all_cities get_postalcode_from_city get_city_from_postalcode validate_postalcode validate);

our $VERSION = '0.05';

sub get_all_data {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->postal_data();
}

sub get_all_postalcodes {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->get_all_postalcodes();
}

sub get_all_cities {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->get_all_cities();
}

sub get_city_from_postalcode {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->get_city_from_postalcode( $_[0] );
}

sub get_postalcode_from_city {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->get_postalcode_from_city( $_[0] );
}

sub validate {
    return validate_postalcode( $_[0] );
}

sub validate_postalcode {
    my $validator = Class::Business::GL::Postalcode->new();

    return $validator->validate( $_[0] );
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Business-GL-Postalcode.svg)](http://badge.fury.io/pl/Business-GL-Postalcode)
[![Build Status](https://travis-ci.org/jonasbn/perl-Business-GL-Postalcode.svg?branch=master)](https://travis-ci.org/jonasbn/perl-Business-GL-Postalcode)
[![Coverage Status](https://coveralls.io/repos/jonasbn/perl-Business-GL-Postalcode/badge.png)](https://coveralls.io/r/jonasbn/perl-Business-GL-Postalcode)

=end markdown

=head1 NAME

Business::GL::Postalcode - Greenland postal code validator and container

=head1 VERSION

This documentation describes version 0.02

=head1 SYNOPSIS

    # basic validation of string
    use Business::GL::Postalcode qw(validate);

    if (validate($postalcode)) {
        print "We have a valid Greenland postal code\n";
    } else {
        warn "Not a valid Greenland postal code\n";
    }


    # basic validation of string, using less intrusive subroutine
    use Business::GL::Postalcode qw(validate_postalcode);

    if (validate_postalcode($postalcode)) {
        print "We have a valid Greenland postal code\n";
    } else {
        warn "Not a valid Greenland postal code\n";
    }


    # using the untainted return value
    use Business::GL::Postalcode qw(validate_postalcode);

    if (my $untainted = validate_postalcode($postalcode)) {
        print "We have a valid Greenland postal code: $untainted\n";
    } else {
        warn "Not a valid Greenland postal code\n";
    }


    # All postal codes for use outside this module
    use Business::GL::Postalcode qw(get_all_postalcodes);

    my @postalcodes = @{get_all_postalcodes()};


    # All postal codes and data for use outside this module
    use Business::GL::Postalcode qw(get_all_data);

    my $postalcodes = get_all_data();

    foreach (@{postalcodes}) {
        printf
            'postal code: %s city: %s street/desc: %s company: %s province: %d country: %d', split /;/, $_, 6;
    }

=head1 FEATURES

=over

=item * Providing list of Greenland postal codes and related area names

=item * Look up methods for Greenland postal codes for web applications and the like

=item * The postal code for Santa Claus (father Christmas)

=back

=head1 DESCRIPTION

This distribution is not the original resource for the included data, but simply
acts as a simple distribution for Perl use. The central source is monitored so this
distribution can contain the newest data. The monitor script (F<postdanmark.pl>) is
included in the distribution: L<https://metacpan.org/pod/Business::DK::Postalcode>.

The data are converted for inclusion in this module. You can use different extraction
subroutines depending on your needs:

=over

=item * L</get_all_data>, to retrieve all data, data description below in L</Data>.

=item * L</get_all_postalcodes>, to retrieve all postal codes

=item * L</get_all_cities>, to retieve all cities

=item * L</get_postalcode_from_city>, to retrieve one or more postal codes from a city name

=item * L</get_city_from_postalcode>, to retieve a city name from a postal code

=back

=head2 Data

Here follows a description of the included data, based on the description from
the original source and the authors interpretation of the data, including
details on the distribution of the data.

=head3 city name

A non-unique, case-sensitive representation of a city name in Greenlandic or Danish.

=head3 street/description

This field is unused for this dataset.

=head3 company name

This field is unused for this dataset.

=head3 province

This field is a bit special and it's use is expected to be related to distribution
all entries are marked as 'False'. The data are included since they are a part of
the original data.

=head3 country

Since the original source contains data on 3 different countries:

=over

=item * Denmark (1)

=item * Greenland (2)

=item * Faroe Islands (3)

=back

Only the data representing Greenland has been included in this distribution, so this
field is always containing a '2'.

For access to the data on Denmark or Faroe Islands please refer to: L<Business::DK::Postalcode>
and L<Business::FO::Postalcode> respectfully.

=head2 Encoding

The data distributed are in Greenlandic and Danish for descriptions and names and these are encoded in UTF-8.

=head1 SUBROUTINES AND METHODS

=head2 validate

A simple validator for Greenlandic postal codes.

Takes a string representing a possible Greenlandic postal code and returns either
B<1> or B<0> indicating either validity or invalidity.

    my $rv = validate(3900);

    if ($rv == 1) {
        print "We have a valid Greenlandic postal code\n";
    } ($rv == 0) {
        print "Not a valid Greenlandic postal code\n";
    }

=head2 validate_postalcode

A less intrusive subroutine for import. Acts as a wrapper of L</validate>.

    my $rv = validate_postalcode(2412);

    if ($rv) {
        print "We have a valid Greenlandic postal code\n";
    } else {
        print "Not a valid Greenlandic postal code\n";
    }

=head2 get_all_data

Returns a reference to a a list of strings, separated by tab characters. See
L</Data> for a description of the fields.

    use Business::GL::Postalcode qw(get_all_data);

    my $postalcodes = get_all_data();

    foreach (@{postalcodes}) {
        printf
            'postalcode: %s city: %s street/desc: %s company: %s province: %d country: %d', split /\t/, $_, 6;
    }

=head2 get_all_postalcodes

Takes no parameters.

Returns a reference to an array containing all valid Danish postal codes.

    use Business::GL::Postalcode qw(get_all_postalcodes);

    my $postalcodes = get_all_postalcodes;

    foreach my $postalcode (@{$postalcodes}) { ... }

=head2 get_all_cities

Takes no parameters.

Returns a reference to an array containing all Danish city names having a postal code.

    use Business::GL::Postalcode qw(get_all_cities);

    my $cities = get_all_cities;

    foreach my $city (@{$cities}) { ... }

Please note that this data source used in this distribution by no means is authorative
when it comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head2 get_city_from_postalcode

Takes a string representing a Danish postal code.

Returns a single string representing the related city name or an empty string indicating nothing was found.

    use Business::GL::Postalcode qw(get_city_from_postalcode);

    my $zipcode = '3900';

    my $city = get_city_from_postalcode($zipcode);

    if ($city) {
        print "We found a city for $zipcode\n";
    } else {
        warn "No city found for $zipcode";
    }

=head2 get_postalcode_from_city

Takes a string representing a Danish/Greenlandic city name.

Returns a reference to an array containing zero or more postal codes related to that city name. Zero indicates nothing was found.

Please note that city names are not unique, hence the possibility of a list of postal codes.

    use Business::GL::Postalcode qw(get_postalcode_from_city);

    my $city = 'Nuuk';

    my $postalcodes = get_postalcode_from_city($city);

    if (scalar @{$postalcodes} == 1) {
        print "$city is unique\n";
    } elsif (scalar @{$postalcodes} > 1) {
        warn "$city is NOT unique\n";
    } else {
        die "$city not found\n";
    }

=head1 DIAGNOSTICS

There are not special diagnostics apart from the ones related to the different
subroutines.

=head1 CONFIGURATION AND ENVIRONMENT

This distribution requires no special configuration or environment.

=head1 DEPENDENCIES

=over

=item * L<https://metacpan.org/pod/Carp> (core)

=item * L<https://metacpan.org/pod/Exporter> (core)

=item * L<https://metacpan.org/pod/Data::Handle>

=item * L<https://metacpan.org/pod/List::Util>

=item * L<https://metacpan.org/pod/Params::Validate>

=back

=head2 TEST

Please note that the above list does not reflect requirements for:

=over

=item * Additional components in this distribution, see F<lib/>. Additional
components list own requirements

=item * Test and build system, please see: F<Build.PL> for details

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs at this time.

The data source used in this distribution by no means is authorative when it
comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * Web (RT): L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-GL-Postalcode>

=item * Web (Github): L<https://github.com/jonasbn/perl-Business-GL-Postalcode/issues>

=item * Email (RT): L<bug-Business-GL-Postalcode@rt.cpan.org>

=back

=head1 SEE ALSO

=over

=item L<Business::DK::Postalcode>

=item L<Business::FO::Postalcode>

=back

=head1 MOTIVATION

Postdanmark the largest danish postal and formerly stateowned postal service, maintain the
postalcode mapping for Greenland and the Faroe Islands. Since I am using this resource to
maintain the danish postalcodes I decided to release distributions of these two other countries.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-GL-Postalcode is (C) by Jonas B. Nielsen, (jonasbn) 2014-2015

Business-GL-Postalcode is released under the artistic license 2.0

=cut
