package Class::Business::FO::Postalcode;

use strict;
use warnings;
use base qw(Class::Business::GL::Postalcode);
use 5.010; #5.10.0
use utf8;
use Data::Handle;

our $VERSION = '0.03';

use constant NUM_OF_DIGITS_IN_POSTALCODE => 3;

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

1;

=pod

=begin HTML

<a href="https://travis-ci.org/jonasbn/perl-Business-FO-Postalcode"><img src="https://travis-ci.org/jonasbn/perl-Business-FO-Postalcode.svg?branch=master"></a>

=end HTML

=encoding UTF-8

=head1 NAME

Class::Business::FO::Postalcode - OO interface to validation and listing of Faroe Islands postal codes

=head1 VERSION

This documentation describes version 0.03

=head1 SYNOPSIS

    # construction
    my $validator = Business::FO::Postalcode->new();

    # basic validation of string
    if ($validator->validate($postalcode)) {
        print "We have a valid Faroe Islands postal code\n";
    } else {
        warn "Not a valid Faroe Islands postal code\n";
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

=item * Providing list of Faroe Islands postal codes and related area names

=item * Look up methods for Faroe Islands postal codes for web applications and the like

=back

=head1 DESCRIPTION

Please note that this class inherits from: L<https://metacpan.org/pod/Business::GL::Postalcode>,
so most of the functionality is implmented in the parent class.

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

A non-unique, case-sensitive representation of a city name in Faroese or Danish.

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

Only the data representing Faroe Islands has been included in this distribution, so this
field is always containing a '3'.

For access to the data on Denmark or Greenland please refer to: L<Business::DK::Postalcode>
and L<Business::GL::Postalcode> respectfully.

=head2 Encoding

The data distributed are in Faroese and Danish for descriptions and names and these are encoded in UTF-8.

=head1 SUBROUTINES AND METHODS

=head2 new

Basic contructor, takes no arguments. Load the dataset and returns
a Class::Business::FO::Postalcode object.

=head2 validate

A simple validator for Faroese postal codes.

Takes a string representing a possible Faroese postal code and returns either
B<1> or B<0> indicating either validity or invalidity.

    my $validator = Business::FO::Postalcode->new();

    my $rv = $validator->validate(100);

    if ($rv == 1) {
        print "We have a valid Faroese postal code\n";
    } ($rv == 0) {
        print "Not a valid Faroese postal code\n";
    }

=head2 get_all_postalcodes

Takes no parameters.

Returns a reference to an array containing all valid Faroese postal codes.

    my $validator = Business::FO::Postalcode->new();

    my $postalcodes = $validator->get_all_postalcodes;

    foreach my $postalcode (@{$postalcodes}) { ... }

=head2 get_all_cities

Takes no parameters.

Returns a reference to an array containing all Faroese city names having a postal code.

    my $validator = Business::FO::Postalcode->new();

    my $cities = $validator->get_all_cities;

    foreach my $city (@{$cities}) { ... }

Please note that this data source used in this distribution by no means is authorative
when it comes to cities located in Denmark, it might have all cities listed, but
unfortunately also other post distribution data.

=head2 get_city_from_postalcode

Takes a string representing a Faroese postal code.

Returns a single string representing the related city name or an empty string indicating nothing was found.

    my $validator = Business::FO::Postalcode->new();

    my $zipcode = '3900';

    my $city = $validator->get_city_from_postalcode($zipcode);

    if ($city) {
        print "We found a city for $zipcode\n";
    } else {
        warn "No city found for $zipcode";
    }

=head2 get_postalcode_from_city

Takes a string representing a Faroese city name.

Returns a reference to an array containing zero or more postal codes related to that city name. Zero indicates nothing was found.

Please note that city names are not unique, hence the possibility of a list of postal codes.

    my $validator = Business::FO::Postalcode->new();

    my $city = 'Tórshavn';

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

    my $validator = Business::FO::Postalcode->new();

    my $rv = $validator->num_of_digits_in_postalcode(3);

    my $digits = $validator->num_of_digits_in_postalcode();

=head2 postal_data

Mutator to get/set the reference to the array comprising the main data structure

    my $validator = Business::FO::Postalcode->new();

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
comes to cities located in Faroe Islands, it might have all cities listed, but
unfortunately also other post distribution data.

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * Web (RT): L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-FO-Postalcode>

=item * Web (Github): L<https://github.com/jonasbn/perl-Business-FO-Postalcode/issues>

=item * Email (RT): L<bug-Business-FO-Postalcode@rt.cpan.org>

=back

=head1 SEE ALSO

=over

=item L<Business::DK::Postalcode>

=item L<Business::GL::Postalcode>

=back

=head1 MOTIVATION

Postdanmark the largest danish postal and formerly stateowned postal service, maintain the
postalcode mapping for Greenland and the Faroe Islands. Since I am using this resource to
maintain the danish postalcodes I decided to release distributions of these two other countries.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Class-Business-FO-Postalcode is (C) by Jonas B. Nielsen, (jonasbn) 2014

Class-Business-FO-Postalcode is released under the artistic license 2.0

=cut

__DATA__
100;Tórshavn;;;FALSE;3
110;Tórshavn;Postboks;;FALSE;3
160;Argir;;;FALSE;3
165;Argir;Postboks;;FALSE;3
175;Kirkjubøur;;;FALSE;3
176;Velbastadur;;FALSE;3
177;Sydradalur, Streymoy;;;FALSE;3
178;Nordradalur;;FALSE;3
180;Kaldbak;;FALSE;3
185;Kaldbaksbotnur;;;FALSE;3
186;Sund;;;FALSE;3
187;Hvitanes;;;FALSE;3
188;Hoyvík;;;FALSE;3
210;Sandur;;;FALSE;3
215;Sandur;Postboks;;FALSE;3
220;Skálavík;;;FALSE;3
230;Húsavík;;FALSE;3
235;Dalur;;;FALSE;3
236;Skarvanes;;;FALSE;3
240;Skopun;;;FALSE;3
260;Skúvoy;;;FALSE;3
270;Nólsoy;;;FALSE;3
280;Hestur;;;FALSE;3
285;Koltur;;;FALSE;3
286;Stóra Dimun;;FALSE;3
330;Stykkid;;FALSE;3
335;Leynar;;;FALSE;3
336;Skællingur;;;FALSE;3
340;Kvívík;;;FALSE;3
350;Vestmanna;;;FALSE;3
355;Vestmanna;Postboks;;FALSE;3
358;Válur;;;FALSE;3
360;Sandavágur;;;FALSE;3
370;Midvágur;;;FALSE;3
375;Midvágur;Postboks;;FALSE;3
380;Sørvágur;;;FALSE;3
385;Vatnsoyrar;;;FALSE;3
386;Bøur;;;FALSE;3
387;Gásadalur;;;FALSE;3
388;Mykines;;FALSE;3
400;Oyrarbakki;;;FALSE;3
405;Oyrarbakki;Postboks;;FALSE;3
410;Kollafjørdur;;;FALSE;3
415;Oyrareingir;;FALSE;3
416;Signabøur;;;FALSE;3
420;Hósvík;;;FALSE;3
430;Hvalvík;;FALSE;3
435;Streymnes;;;FALSE;3
436;Saksun;;;FALSE;3
437;Nesvík;;;FALSE;3
438;Langasandur;;FALSE;3
440;Haldarsvík;;;FALSE;3
445;Tjørnuvík;;;FALSE;3
450;Oyri;;;FALSE;3
460;Nordskáli;;;FALSE;3
465;Svináir;;FALSE;3
466;Ljósá;;;FALSE;3
470;Eidi;;;FALSE;3
475;Funningur;;;FALSE;3
476;Gjógv;;;FALSE;3
477;Funningsfjørdur;;FALSE;3
478;Elduvík;;FALSE;3
480;Skáli;;;FALSE;3
485;Skálafjørdur;;;FALSE;3
490;Strendur;;;FALSE;3
494;innan Glyvur;;;FALSE;3
495;Kolbanargjógv;;;FALSE;3
496;Morskranes;;;FALSE;3
497;Selatrad;;;FALSE;3
510;Gøta;;;FALSE;3
511;Gøtugjógv;;;FALSE;3
512;Nordragøta;;;FALSE;3
513;Sydrugøta;;;FALSE;3
515;Gøta;Postboks;;FALSE;3
520;Leirvík;;FALSE;3
530;Fuglafjørdur;;;FALSE;3
535;Fuglafjørdur;Postboks;;FALSE;3
600;Saltangará;;;FALSE;3
610;Saltangará;Postboks;;FALSE;3
620;Runavík;;FALSE;3
625;Glyvrar;;FALSE;3
626;Lambareidi;;;FALSE;3
627;Lambi;;;FALSE;3
640;Rituvík;;FALSE;3
645;Æduvík;;;FALSE;3
650;Toftir;;;FALSE;3
655;Nes, Eysturoy;;;FALSE;3
656;Saltnes;;FALSE;3
660;Søldarfjørdur;;;FALSE;3
665;Skipanes;;;FALSE;3
666;Gøtueidi;;;FALSE;3
690;Oyndarfjørdur;;;FALSE;3
695;Hellur;;;FALSE;3
700;Klaksvík;;;FALSE;3
710;Klaksvík;Postboks;;FALSE;3
725;Nordoyri;;;FALSE;3
726;Ánir;;;FALSE;3
727;Árnafjørdur;;FALSE;3
730;Norddepil;;;FALSE;3
735;Depil;;;FALSE;3
736;Nordtoftir;;;FALSE;3
737;Múli;;;FALSE;3
740;Hvannasund;;;FALSE;3
750;Vidareidi;;;FALSE;3
765;Svinoy;;;FALSE;3
766;Kirkja;;;FALSE;3
767;Hattarvík;;;FALSE;3
780;Kunoy;;;FALSE;3
785;Haraldssund;;FALSE;3
795;Sydradalur, Kalsoy;;;FALSE;3
796;Húsar;;;FALSE;3
797;Mikladalur;;;FALSE;3
798;Trøllanes;;;FALSE;3
800;Tvøroyri;;;FALSE;3
810;Tvøroyri;Postboks;;FALSE;3
825;Frodba;;;FALSE;3
826;Trongisvágur;;;FALSE;3
827;Øravík;;;FALSE;3
850;Hvalba;;;FALSE;3
860;Sandvík;;FALSE;3
870;Fámjin;;;FALSE;3
900;Vágur;;;FALSE;3
910;Vágur;Postboks;;FALSE;3
925;Nes, Vágur;;;FALSE;3
926;Lopra;;;FALSE;3
927;Akrar;;;FALSE;3
928;Vikarbyrgi;;;FALSE;3
950;Porkeri;;FALSE;3
960;Hov;;FALSE;3
970;Sumba;;;FALSE;3