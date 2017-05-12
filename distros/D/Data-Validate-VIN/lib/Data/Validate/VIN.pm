package Data::Validate::VIN;

use 5.008;
use strict;
use warnings;
#use Carp;

our $VERSION = '0.04';

sub new {
    my ( $class, $vin ) = @_;

    my $self = bless {}, $class;

    $self->{_allowed} = qr/[A-HJ-NPR-Z0-9]/;
    $self->{errors}   = [];

    # this next one might add to $self->{errors}, which is fine
    $self->{vin} = $self->_checkVIN($vin);

    # we won't process the wmi, vds or vis if the vin check returned errors
    unless ( scalar( @{ $self->{errors} } ) > 0 ) {
        $self->{wmi}        = $self->_checkWMI( $self->{vin} );
        $self->{vds}        = $self->_checkVDS( $self->{vin} );
        $self->{vis}        = $self->_checkVIS( $self->{vin} );
        $self->{checkdigit} = $self->_checkCheckDigit( $self->{vin} );
    }

    $self->{valid} =
      scalar( @{ $self->{errors} } > 0 )
      ? undef
      : 1;

    return $self;
}

sub valid {
    my ($self) = @_;

    defined $self->{valid}
      ? return 1
      : return;
}

sub errors {
    my ($self) = @_;

    scalar( @{ $self->{errors} } > 0 )
      ? return $self->{errors}
      : return [];
}

sub get {
    my ( $self, $wanted ) = @_;

    if ( $wanted =~ /wmi|vds|vis|vin|checkdigit|country|year/i ) {
        if ( $wanted =~ /vin|checkdigit/i ) {
            defined $self->{$wanted}
              ? return $self->{$wanted}
              : return;
        }
        elsif ( $wanted =~ /wmi|vds|vis/i ) {
            defined $self->{$wanted}->{$wanted}
              ? return $self->{$wanted}->{$wanted}
              : return;
        }
        elsif ( $wanted =~ /country/i ) {
            defined $self->{wmi}->{$wanted}
              ? return $self->{wmi}->{$wanted}
              : return;
        }
        elsif ( $wanted =~ /year/i ) {
            defined $self->{vis}->{$wanted}
              ? return $self->{vis}->{$wanted}
              : return;
        }
        else {
            return;
        }
    }
    return;
}

sub _checkVIN {
    my ( $self, $_vin ) = @_;

    if ( not defined $_vin or $_vin =~ /^$/ ) {
        $self->_trackError("No VIN supplied");
        return;
    }

    chomp($_vin);

    $_vin = $self->_checkCharacters(
        wanted   => $self->{_allowed},
        unwanted => qr/[IOQ]/,
        toCheck  => $_vin,
        section  => 'VIN'
    );

    if ( length($_vin) != 17 ) {
        my $err = sprintf( "%- 17s", $_vin ) . " is not the expected length";
        $self->_trackError($err);
    }

    return $_vin;
}

sub _checkWMI {
    my ( $self, $_vin ) = @_;

    my $wmi = {
        wmi => $self->_checkCharacters(
            wanted   => $self->{_allowed},
            unwanted => qr/[IOQ]/,
            toCheck  => substr( $_vin, 0, 2 ),
            section  => 'WMI'
        ),
    };

    # load known valid WMIs
    my $_allowed = $self->_loadWMI();

    defined $_allowed->{ $wmi->{wmi} }
      ? $wmi->{country} = $_allowed->{ $wmi->{wmi} }
      : $self->_trackError("Unknown WMI: $wmi->{wmi}");

    return $wmi;
}

sub _checkCharacters {
    my ( $self, %args ) = @_;

    # wanted unwanted toCheck section

    my $checked = uc($args{toCheck});
    my @checked = split(q{}, $checked); ## char array
    my @illegal;

    for (my $i = 0; $i < @checked; $i++) {
        unless ($checked[$i] =~ /^$args{wanted}+$/) {
            push @illegal, $checked[$i];
        }
    }

    if (@illegal) {
        my $err = "Illegal characters in " . $args{section} . ': ' . join(q{}, @illegal);
        $self->_trackError($err);
    }

    return $checked;
}

sub _loadWMI {
    my ($self) = @_;

    my %wmi;

    $self->_loadCountry( 'AA', 'AH', 'South Africa',         \%wmi );
    $self->_loadCountry( 'AJ', 'AN', 'Ivory Coast',          \%wmi );
    $self->_loadCountry( 'BA', 'BE', 'Angola',               \%wmi );
    $self->_loadCountry( 'BF', 'BK', 'Kenya',                \%wmi );
    $self->_loadCountry( 'BL', 'BR', 'Tanzania',             \%wmi );
    $self->_loadCountry( 'CA', 'CE', 'Benin',                \%wmi );
    $self->_loadCountry( 'CF', 'CK', 'Madagascar',           \%wmi );
    $self->_loadCountry( 'CL', 'CR', 'Tunisia',              \%wmi );
    $self->_loadCountry( 'DA', 'DE', 'Egypt',                \%wmi );
    $self->_loadCountry( 'DF', 'DK', 'Morocco',              \%wmi );
    $self->_loadCountry( 'DL', 'DR', 'Zambia',               \%wmi );
    $self->_loadCountry( 'EA', 'EE', 'Ethiopia',             \%wmi );
    $self->_loadCountry( 'EF', 'EK', 'Mozambique',           \%wmi );
    $self->_loadCountry( 'FA', 'FE', 'Ghana',                \%wmi );
    $self->_loadCountry( 'FF', 'FK', 'Nigeria',              \%wmi );
    $self->_loadCountry( 'JA', 'JT', 'Japan',                \%wmi );
    $self->_loadCountry( 'KA', 'KE', 'Sri Lanka',            \%wmi );
    $self->_loadCountry( 'KF', 'KK', 'Israel',               \%wmi );
    $self->_loadCountry( 'KL', 'KR', 'Korea (South)',        \%wmi );
    $self->_loadCountry( 'LA', 'L0', 'China',                \%wmi );
    $self->_loadCountry( 'MA', 'ME', 'India',                \%wmi );
    $self->_loadCountry( 'MF', 'MK', 'Indonesia',            \%wmi );
    $self->_loadCountry( 'ML', 'MR', 'Thailand',             \%wmi );
    $self->_loadCountry( 'NF', 'NK', 'Pakistan',             \%wmi );
    $self->_loadCountry( 'NL', 'NR', 'Turkey',               \%wmi );
    $self->_loadCountry( 'PA', 'PE', 'Philippines',          \%wmi );
    $self->_loadCountry( 'PF', 'PK', 'Singapore',            \%wmi );
    $self->_loadCountry( 'PL', 'PR', 'Malaysia',             \%wmi );
    $self->_loadCountry( 'RA', 'RE', 'United Arab Emirates', \%wmi );
    $self->_loadCountry( 'RF', 'RK', 'Taiwan',               \%wmi );
    $self->_loadCountry( 'RL', 'RR', 'Vietnam',              \%wmi );
    $self->_loadCountry( 'SA', 'SM', 'United Kingdom',       \%wmi );
    $self->_loadCountry( 'SN', 'ST', 'Germany',              \%wmi );
    $self->_loadCountry( 'SU', 'SZ', 'Poland',               \%wmi );
    $self->_loadCountry( 'S1', 'S4', 'Latvia',               \%wmi );
    $self->_loadCountry( 'TA', 'TH', 'Switzerland',          \%wmi );
    $self->_loadCountry( 'TJ', 'TP', 'Czech Republic',       \%wmi );
    $self->_loadCountry( 'TR', 'TV', 'Hungary',              \%wmi );
    $self->_loadCountry( 'TW', 'T1', 'Portugal',             \%wmi );
    $self->_loadCountry( 'UH', 'UM', 'Denmark',              \%wmi );
    $self->_loadCountry( 'UN', 'UT', 'Ireland',              \%wmi );
    $self->_loadCountry( 'UU', 'UZ', 'Romania',              \%wmi );
    $self->_loadCountry( 'U5', 'U7', 'Slovakia',             \%wmi );
    $self->_loadCountry( 'VA', 'VE', 'Austria',              \%wmi );
    $self->_loadCountry( 'VF', 'VR', 'France',               \%wmi );
    $self->_loadCountry( 'VS', 'VW', 'Spain',                \%wmi );
    $self->_loadCountry( 'VX', 'V2', 'Serbia',               \%wmi );
    $self->_loadCountry( 'V3', 'V5', 'Croatia',              \%wmi );
    $self->_loadCountry( 'V6', 'V0', 'Estonia',              \%wmi );
    $self->_loadCountry( 'WA', 'W0', 'Germany',              \%wmi );
    $self->_loadCountry( 'XA', 'XE', 'Bulgaria',             \%wmi );
    $self->_loadCountry( 'XF', 'XK', 'Greece',               \%wmi );
    $self->_loadCountry( 'XL', 'XR', 'Netherlands',          \%wmi );
    $self->_loadCountry( 'XS', 'XW', 'USSR',                 \%wmi );
    $self->_loadCountry( 'XX', 'X2', 'Luxembourg',           \%wmi );
    $self->_loadCountry( 'X3', 'X0', 'Russia',               \%wmi );
    $self->_loadCountry( 'YA', 'YE', 'Belgium',              \%wmi );
    $self->_loadCountry( 'YF', 'YK', 'Finland',              \%wmi );
    $self->_loadCountry( 'YL', 'YR', 'Malta',                \%wmi );
    $self->_loadCountry( 'YS', 'YW', 'Sweden',               \%wmi );
    $self->_loadCountry( 'YX', 'Y2', 'Norway',               \%wmi );
    $self->_loadCountry( 'Y3', 'Y5', 'Belarus',              \%wmi );
    $self->_loadCountry( 'Y6', 'Y0', 'Ukraine',              \%wmi );
    $self->_loadCountry( 'ZA', 'ZR', 'Italy',                \%wmi );
    $self->_loadCountry( 'ZX', 'Z2', 'Slovenia',             \%wmi );
    $self->_loadCountry( 'Z3', 'Z5', 'Lithuania',            \%wmi );
    $self->_loadCountry( '1A', '10', 'United States',        \%wmi );
    $self->_loadCountry( '2A', '20', 'Canada',               \%wmi );
    $self->_loadCountry( '3A', '3W', 'Mexico',               \%wmi );
    $self->_loadCountry( '3X', '37', 'Costa Rica',           \%wmi );
    $self->_loadCountry( '38', '30', 'Cayman Islands',       \%wmi );
    $self->_loadCountry( '4A', '40', 'United States',        \%wmi );
    $self->_loadCountry( '5A', '50', 'United States',        \%wmi );
    $self->_loadCountry( '6A', '6W', 'Australia',            \%wmi );
    $self->_loadCountry( '7A', '7E', 'New Zealand',          \%wmi );
    $self->_loadCountry( '8A', '8E', 'Argentina',            \%wmi );
    $self->_loadCountry( '8F', '8K', 'Chile',                \%wmi );
    $self->_loadCountry( '8L', '8R', 'Ecuador',              \%wmi );
    $self->_loadCountry( '8S', '8W', 'Peru',                 \%wmi );
    $self->_loadCountry( '8X', '82', 'Venezuela',            \%wmi );
    $self->_loadCountry( '9A', '9E', 'Brazil',               \%wmi );
    $self->_loadCountry( '9F', '9K', 'Colombia',             \%wmi );
    $self->_loadCountry( '9L', '9R', 'Paraguay',             \%wmi );
    $self->_loadCountry( '9S', '9W', 'Uruguay',              \%wmi );
    $self->_loadCountry( '9X', '92', 'Trinidad & Tobago',    \%wmi );
    $self->_loadCountry( '93', '99', 'Brazil',               \%wmi );

    return \%wmi;
}

sub _checkVDS {
    my ( $self, $_vin ) = @_;

    my $vds = {
        vds => length($_vin) == 17
        ? $self->_checkCharacters(
            wanted   => $self->{_allowed},
            unwanted => qr/[IOQ]/,
            toCheck  => substr( $_vin, 3, 6 ),
            section  => 'VDS'
          )
        : undef
    };

    return $vds;
}

sub _checkVIS {
    my ( $self, $_vin ) = @_;

    my $vis = {
        vis => length($_vin) == 17
        ? $self->_checkCharacters(
            wanted   => $self->{_allowed},
            unwanted => qr/[IOQ]/,
            toCheck  => substr( $_vin, 9, 8 ),
            section  => 'VIS'
          )
        : undef
    };

    if ( defined $vis->{vis} ) {

        my %years = (
            A => [ 1980, 2010 ],
            L => [1990],
            Y => [2000],
            B => [ 1981, 2011 ],
            M => [1991],
            1 => [2001],
            C => [ 1982, 2012 ],
            N => [1992],
            2 => [2002],
            D => [ 1983, 2013 ],
            P => [1993],
            3 => [2003],
            E => [ 1984, 2014 ],
            R => [1994],
            4 => [2004],
            F => [ 1985, 2015 ],
            S => [1995],
            5 => [2005],
            G => [ 1986, 2016 ],
            T => [1996],
            6 => [2006],
            H => [ 1987, 2017 ],
            V => [1997],
            7 => [2007],
            J => [ 1988, 2018 ],
            W => [1998],
            8 => [2008],
            K => [ 1989, 2019 ],
            X => [1999],
            9 => [2009],
        );

        my $yearDigit = substr( $vis->{vis}, 0, 1 );

        my $year =
          defined $years{$yearDigit}
          ? $years{$yearDigit}
          : undef;

        if ($year) {
            $vis->{year} = $year;
        }
        else {
            $self->_trackError("Illegal character in 10th position: $yearDigit")
              unless $vis->{year};
        }
    }

    return $vis;
}

sub _checkCheckDigit {
    my ( $self, $_vin ) = @_;

    return unless length($_vin) == 17;

    my $passedCheckDigit = substr( $_vin, 8, 1 );

    my %vals = (
        A => 1,
        B => 2,
        C => 3,
        D => 4,
        E => 5,
        F => 6,
        G => 7,
        H => 8,
        J => 1,
        K => 2,
        L => 3,
        M => 4,
        N => 5,
        P => 7,
        R => 9,
        S => 2,
        T => 3,
        U => 4,
        V => 5,
        W => 6,
        X => 7,
        Y => 8,
        Z => 9
    );

    # Add the numeric pieces
    # these are worth face value
    for ( 0 .. 9 ) {
        $vals{$_} = $_;
    }

    my %wghts = (
        1  => 8,
        2  => 7,
        3  => 6,
        4  => 5,
        5  => 4,
        6  => 3,
        7  => 2,
        8  => 10,
        9  => 0,
        10 => 9,
        11 => 8,
        12 => 7,
        13 => 6,
        14 => 5,
        15 => 4,
        16 => 3,
        17 => 2
    );

    my @vinbits = split( // => $_vin );

    my $sum;

    my $ind = 1;
    for my $bit (@vinbits) {
        $sum += $vals{$bit} * $wghts{$ind};
        $ind++;
    }

    my $calcCheckDigit = $sum % 11;
    $calcCheckDigit = 'X'
      if $calcCheckDigit == '10';

    $calcCheckDigit =~ /$passedCheckDigit/
      ? return $calcCheckDigit
      : $self->_trackError(
        "Checkdigit mismatch; expected $calcCheckDigit, got $passedCheckDigit");

    return;
}

sub _loadCountry {
    my ( $self, $start, $end, $country, $store ) = @_;

    $store->{$start} = $country;

    until ( $start eq $end ) {
        my @pieces = split( // => $start );
        my $next = $self->_next( $pieces[1] );

        $start = $pieces[0] . $next;

        $store->{$start} = $country;
    }

    return;
}

sub _next {
    my ( $self, $current ) = @_;

    my @fields = qw{ A B C D E F G H J K L M N P R S T
      U V W X Y Z 1 2 3 4 5 6 7 8 9 0 };

    my %order = map { ( $fields[$_], $_ ) } 0 .. scalar(@fields) - 1;

    my $max = scalar(@fields) - 1;

    my $next =
        $order{$current} == $max
      ? $fields[0]
      : $fields[ $order{$current} + 1 ];

    return $next;
}

sub _trackError {
    my ( $self, $error ) = @_;

    push @{ $self->{errors} }, $error;

    return;
}

1;
__END__

=head1 NAME

Data::Validate::VIN - Perl extension for basic validation of
North American Vehicle Identification Numbers from 1980 and later

=head1 VERSION

0.04

=head1 SYNOPSIS

    use Data::Validate::VIN;

    my $vv = Data::Validate::VIN->new($somePotentialVIN);

    if ( $vv->valid() ) {
        print $vv->get('vin'), "\n";
    }
    else {
        print "$_\n" for @{ $vv->errors() };
    }

=head1 DESCRIPTION

Data::Validate::VIN provides a simple way to validate the very basics of North American VINs. The only information
this module can glean from a valid VIN is the country of manufacture and the year it was produced.

It cannot tell you if a VIN corresponds to an actual vehicle in the world, it just knows what most VINs look like.

The following checks are run:

=head2 Length

17 characters expected

=head2 Legal Characters

The following are allowed :
A-H,J-N,P,R-Z,0-9

Note that following are illegal in the 10th position:
U,Z,0

=head2 Country of Manufacture

Identified through the first two characters in the WMI

=head2 Year

Identified by the 10th character in the VIN

=head2 Check Digit

This is the 9th character in the VIN

=head1 VEHICLE IDENTIFICATION NUMBERS

Vehicle Identification Numbers in North America since 1980 can be, very basically and in brief, broken down into three sections:
the WMI (World Manufacturer Identifier), the VDS (Vehicle Descriptor Section) and the VIS
(Vehicle Identifier Section).

The WMI is the first three characters in the VIN.  The first two of these identify manufacturer of the vehicle.

The VDS is the fourth through ninth characters in the VIN.  This is typically unique per manufacturer. The ninth digit
is the check digit.

The VIS is used to identify the particular vehicle in question.

=head1 METHODS

=head2 new()

Accepts an alphanumeric string which will be automatically run through the checks outlined above

=head2 valid()

Returns 1 if the string sent through new() passed all checks. Returns undef otherwise

=head2 errors()

Returns an array ref containing any errors encountered while checking the string. Will return an empty array ref if the string passed all tests.

=head2 get()

Returns a piece of the VIN or data gleaned from the VIN. Accepts the following:

vin - will always be returned unless an empty string was passed to new()

vid

vis

checkdigit

country

year - returns an array ref, as some characters refer to multiple years.

=head1 SEE ALSO

http://www.access.gpo.gov/nara/cfr/waisidx_05/49cfr565_05.html

http://en.wikipedia.org/wiki/Vehicle_Identification_Number

=head1 AUTHOR

collin seaton, C<< <cseaton at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-validate-vin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-VIN>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

Fork me on Github: L<https://github.com/chilledham/Data-Validate-VIN>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::VIN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validate-VIN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Validate-VIN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Validate-VIN>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Validate-VIN/>

=back

=head1 THANKS

Thanks to the following contributors:

moltar

=head1 WARRANTY

None.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 collin seaton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
