package Class::Business::GL::Postalcode;

use strict;
use warnings;
use utf8;
use Data::Handle;
use List::Util qw(first);
use Readonly;
use 5.010; #5.10.0

use constant NUM_OF_DIGITS_IN_POSTALCODE => 4;
use constant NUM_OF_DATA_ELEMENTS        => 6;
use constant TRUE                        => 1;
use constant FALSE                       => 0;

Readonly::Scalar my $SEPARATOR => ';';

our $VERSION = '0.05';

sub new {
    my $class = shift;

    my $self = bless ({}, $class);

    #seek DATA, 0, 0;
    #my @postal_data = <DATA>;

    my $handle = Data::Handle->new( __PACKAGE__ );
    my @postal_data = $handle->getlines();

    $self->postal_data(\@postal_data);

    $self->num_of_digits_in_postalcode(NUM_OF_DIGITS_IN_POSTALCODE);

    return $self;
}

sub num_of_digits_in_postalcode {
    my ($self, $number) = @_;

    if ($number) {
        $self->{num_of_digits_in_postalcode} = $number;

        return TRUE;
    } else {
        return $self->{num_of_digits_in_postalcode};
    }
}

sub postal_data {
    my ($self, $postal_data) = @_;

    if ($postal_data) {
        $self->{postal_data} = $postal_data;

        return TRUE;
    } else {
        return $self->{postal_data};
    }
}

sub get_all_postalcodes {
    my $self = shift;

    my @postalcodes = ();

    foreach my $line ( @{$self->postal_data} ) {
        $self->_retrieve_postalcode( \@postalcodes, $line );
    }

    return \@postalcodes;
}

sub get_all_cities {
    my ($self) = @_;

    my @cities = ();

    foreach my $line ( @{$self->postal_data} ) {
        $self->_retrieve_city( \@cities, $line );
    }

    return \@cities;
}

sub _retrieve_postalcode {
    my ( $self, $postalcodes, $string ) = @_;

    ## no critic qw(RegularExpressions::RequireLineBoundaryMatching RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireDotMatchAnything)
    my @entries = split /$SEPARATOR/x, $string, NUM_OF_DATA_ELEMENTS;

    my $num_of_digits_in_postalcode = $self->num_of_digits_in_postalcode();

    if ($entries[0] =~ m{
        ^ #beginning of string
        \d{$num_of_digits_in_postalcode} #digits in postalcode
        $ #end of string
        }xsm
        )
    {
        push @{$postalcodes}, $entries[0];
    }

    return;
}

sub _retrieve_city {
    my ( $self, $postalcodes, $string ) = @_;

    ## no critic qw(RegularExpressions::RequireLineBoundaryMatching RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireDotMatchAnything)
    my @entries = split /$SEPARATOR/x, $string, NUM_OF_DATA_ELEMENTS;

    my $num_of_digits_in_postalcode = $self->num_of_digits_in_postalcode();

    if ($entries[0] =~ m{
        ^ #beginning of string
        \d{$num_of_digits_in_postalcode} #digits in postalcode
        $ #end of string
        }xsm
        )
    {
        push @{$postalcodes}, $entries[1];
    }

    return;
}

sub validate {
    my ($self, $number) = @_;

    my $postalcodes = $self->get_all_postalcodes();

    if (first { $number == $_ } @{$postalcodes}) {
        return TRUE;
    } else {
        return FALSE;
    }
}

sub get_city_from_postalcode {
    my ($self, $postalcode) = @_;

    #validate( @_, {
    #    zipcode => { type => SCALAR, regex => qr/^\d+$/, }, });

    my $postaldata = $self->postal_data();

    my $city = '';
    foreach my $line (@{$postaldata}) {
        my @entries = split /$SEPARATOR/x, $line, NUM_OF_DATA_ELEMENTS;

        if ($entries[0] eq $postalcode) {
            $city = $entries[1];
            last;
        }
    }

    return $city;
}

sub get_postalcode_from_city {
    my ($self, $city) = @_;

    #validate( @_, {
    #    city => { type => SCALAR, regex => qr/^[\w ]+$/, }, });

    my $postaldata = $self->postal_data();

    my @postalcodes;
    foreach my $line (@{$postaldata}) {
        my @entries = split /$SEPARATOR/x, $line, NUM_OF_DATA_ELEMENTS;

        if ($entries[1] =~ m/$city$/i) {
            push @postalcodes, $entries[0];
        }
    }

    return \@postalcodes;
}

1;

=pod

=begin HTML

<a href="https://travis-ci.org/jonasbn/perl-Business-GL-Postalcode"><img src="https://travis-ci.org/jonasbn/perl-Business-GL-Postalcode.svg?branch=master"></a>

=end HTML

=head1 NAME

Class::Business::GL::Postalcode - OO interface to validation and listing of Greenland postal codes

=head1 VERSION

This documentation describes version 0.02

=head1 SYNOPSIS

    # construction
    my $validator = Business::GL::Postalcode->new();

    # basic validation of string
    if ($validator->validate($postalcode)) {
        print "We have a valid Greenland postal code\n";
    } else {
        warn "Not a valid Greenland postal code\n";
    }


    # All postal codes for use outside this module
    my @postalcodes = @{$validator->get_all_postalcodes()};


    # All postal codes and data for use outside this module
    my $postalcodes = $validator->get_all_data();

    foreach (@{postalcodes}) {
        printf
            'postal code: %s city: %s street/desc: %s company: %s province: %d country: %d', split /;/, $_, 6;
    }

=head1 FEATURES

=over

=item * Providing list of Greenland postal codes and related area names

=item * Look up methods for Greenland postal codes for web applications and the like

=item * The postal code from Santa Claus (father Christmas)

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

=head2 new

Basic contructor, takes no arguments. Load the dataset and returns
a Class::Business::GL::Postalcode object.

=head2 validate

A simple validator for Greenlandic postal codes.

Takes a string representing a possible Greenlandic postal code and returns either
B<1> or B<0> indicating either validity or invalidity.

    my $validator = Business::GL::Postalcode->new();

    my $rv = $validator->validate(3900);

    if ($rv == 1) {
        print "We have a valid Greenlandic postal code\n";
    } ($rv == 0) {
        print "Not a valid Greenlandic postal code\n";
    }

=head2 get_all_postalcodes

Takes no parameters.

Returns a reference to an array containing all valid Danish postal codes.

    my $validator = Business::GL::Postalcode->new();

    my $postalcodes = $validator->get_all_postalcodes;

    foreach my $postalcode (@{$postalcodes}) { ... }

=head2 get_all_cities

Takes no parameters.

Returns a reference to an array containing all Danish city names having a postal code.

    my $validator = Business::GL::Postalcode->new();

    my $cities = $validator->get_all_cities;

    foreach my $city (@{$cities}) { ... }

Please note that this data source used in this distribution by no means is authorative
when it comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head2 get_city_from_postalcode

Takes a string representing a Danish postal code.

Returns a single string representing the related city name or an empty string indicating nothing was found.

    my $validator = Business::GL::Postalcode->new();

    my $zipcode = '3900';

    my $city = $validator->get_city_from_postalcode($zipcode);

    if ($city) {
        print "We found a city for $zipcode\n";
    } else {
        warn "No city found for $zipcode";
    }

=head2 get_postalcode_from_city

Takes a string representing a Danish/Greenlandic city name.

Returns a reference to an array containing zero or more postal codes related to that city name. Zero indicates nothing was found.

Please note that city names are not unique, hence the possibility of a list of postal codes.

    my $validator = Business::GL::Postalcode->new();

    my $city = 'Nuuk';

    my $postalcodes = $validator->get_postalcode_from_city($city);

    if (scalar @{$postalcodes} == 1) {
        print "$city is unique\n";
    } elsif (scalar @{$postalcodes} > 1) {
        warn "$city is NOT unique\n";
    } else {
        die "$city not found\n";
    }

=head2 num_of_digits_in_postalcode

Mutator to get/set the number of digits used to compose a Greenlandic postal code

    my $validator = Business::GL::Postalcode->new();

    my $rv = $validator->num_of_digits_in_postalcode(4);

    my $digits = $validator->num_of_digits_in_postalcode();

=head2 postal_data

Mutator to get/set the reference to the array comprising the main data structure

    my $validator = Business::GL::Postalcode->new();

    my $rv = $validator->postal_data(\@postal_data);

    my $postal_data = $validator->postal_data();

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

Class-Business-GL-Postalcode is (C) by Jonas B. Nielsen, (jonasbn) 2014-2015

Class-Business-GL-Postalcode is released under the artistic license 2.0

=cut

__DATA__
2412;Santa Claus/Julemanden;;;False;2
3900;Nuuk;;;False;2
3905;Nuussuaq;;;False;2
3910;Kangerlussuaq;;;False;2
3911;Sisimiut;;;False;2
3912;Maniitsoq;;;False;2
3913;Tasiilaq;;;False;2
3915;Kulusuk;;;False;2
3919;Alluitsup Paa;;;False;2
3920;Qaqortoq;;;False;2
3921;Narsaq;;;False;2
3922;Nanortalik;;;False;2
3923;Narsarsuaq;;;False;2
3924;Ikerasassuaq;;;False;2
3930;Kangilinnguit;;;False;2
3932;Arsuk;;;False;2
3940;Paamiut;;;False;2
3950;Aasiaat;;;False;2
3951;Qasigiannguit;;;False;2
3952;Ilulissat;;;False;2
3953;Qeqertarsuaq;;;False;2
3955;Kangaatsiaq;;;False;2
3961;Uummannaq;;;False;2
3962;Upernavik;;;False;2
3964;Qaarsut;;;False;2
3970;Pituffik;;;False;2
3971;Qaanaaq;;;False;2
3972;Station Nord;;;False;2
3980;Ittoqqortoormiit;;;False;2
3982;Mestersvig;;;False;2
3984;Danmarkshavn;;;False;2
3985;Constable Pynt;;;False;2
3992;Slædepatrulje Sirius;;;False;2
