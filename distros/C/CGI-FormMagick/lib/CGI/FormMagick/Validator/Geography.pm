#!/usr/bin/perl -w
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.
#
# $Id: Geography.pm,v 1.4 2003/02/05 17:18:39 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick::Validator;

=pod

=head1 NAME

CGI::FormMagick::Validator::Geography - geography-related validation routines

=head1 SYNOPSIS

use CGI::FormMagick;

=head1 DESCRIPTION

See CGI::FormMagick::Validator for a general description.

=for testing
BEGIN: {
    use CGI::FormMagick::Validator;
}

=head2 Validation routines provided:

=over 4

=item iso_country_code

The data is a standard 2-letter ISO country code.  Requires the Locale::Country 
module to be installed.

=begin testing

SKIP: {
    skip "Locale::Country not installed", 4 
        unless eval { require Locale::Country };

    ok( iso_country_code()      ne "OK" , "undef is not a country");
    ok( iso_country_code(undef, "")    ne "OK" , "empty string is not a country");
    ok( iso_country_code(undef, "00")  ne "OK" , "00 is not a country");
    ok( iso_country_code(undef, "au")  eq "OK" , "au is a country");
}

=end testing

=cut

sub iso_country_code {
    my ($fm, $country) = @_;

    require Locale::Country;
    my @countries =  Locale::Country::all_country_codes();

    if ( not defined $country ) {
        return "You must provide a country code";
    } elsif ( grep /^$country$/, @countries ) {
        return "OK";
    } else {
        return "This field does not contain an ISO country code";
    }
}

=pod

=item US_state

The data is a standard 2-letter US state abbreviation.  Uses
Geography::State in non-strict mode, so this module must be installed
for it to work.

=begin testing

SKIP: {
    skip "Geography::States broken, this needs figuring out", 5 
        unless eval { require Geography::States };

    ok( US_state(undef, "or")          eq "OK" , "Oregon is a US state");
    ok( US_state(undef, "OR")          eq "OK" , "Oregon is a US state");
    ok( US_state()              ne "OK" , "undef is not a US state");
    ok( US_state(undef, "")            ne "OK" , "empty string is not a US state");
    ok( US_state(undef, "zz")          ne "OK" , "zz is not a US state");

}

=end testing

=cut

sub US_state {
    my ($fm, $data) = @_;
    require Geography::States;

    my $us = Geography::States->new('USA');

    if ($data && $us->state(uc($data))) {
        return "OK";
    } else {
        return "This doesn't appear to be a valid 2-letter US state abbreviation"
    }
}


=item US_zipcode

The data looks like a valid US zipcode

=for testing
ok( US_zipcode()            ne "OK" , "undef is not a US zipcode");
ok( US_zipcode(undef, "")          ne "OK" , "empty string is not a US zipcode");
ok( US_zipcode(undef, "abc")       ne "OK" , "abc is not a US zipcode");
ok( US_zipcode(undef, "2210")      ne "OK" , "2210 is not a US zipcode");
ok( US_zipcode(undef, "90210")     eq "OK" , "90210 is a US zipcode");
ok( US_zipcode(undef, "a0210")     ne "OK" , "a0210 is not a US zipcode");
ok( US_zipcode(undef, "123456789") eq "OK" , "123456789 is a valid US zipcode");
ok( US_zipcode(undef, "12345-6789") eq "OK" , "12345-6789 is a valid US zipcode");

=cut

sub US_zipcode {
    my ($fm, $data) = @_;

    if (not $data) {
        return "You must enter a US zip code";
    } elsif ($data =~ /^\d{5}(-?\d{4})?$/) {
        return "OK";
    } else {
        return "US zip codes must contain 5 or 9 numbers";
    }
}

=pod

=head1 SEE ALSO

The main perldoc for CGI::FormMagick

=head1 AUTHOR

Kirrily "Skud" Robert <skud@infotrope.net>

More information about FormMagick may be found at 
http://sourceforge.net/projects/formmagick/

=cut

return 1;
