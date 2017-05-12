package Business::RO::CNP;

use Moose;
use DateTime::Format::Strptime;
use utf8;
use Carp;

use 5.008_008;

our $VERSION = '0.03';

around BUILDARGS => sub {
    my ( $orig, $class ) = ( shift, shift );

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( cnp => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

has cnp => ( is => 'ro', isa => 'Int', required => 1, );

has sex_id => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    default  => sub { substr shift->cnp, 0, 1 },
);

has sex => ( is => 'ro', isa => 'Str', init_arg => undef, lazy_build => 1, );

sub _build_sex {
    my $self  = shift;
    my %sexes = (
        '1' => 'm',
        '2' => 'f',
        '3' => 'm',
        '4' => 'f',
        '5' => 'm',
        '6' => 'f',
        '7' => 'm',
        '8' => 'f',
    );
    return
        $self->sex_id == 9 ? 'unknown'
      : !$self->sex_id     ? undef
      :                      $sexes{ $self->sex_id };
}

has century =>
  ( is => 'ro', isa => 'Int', init_arg => undef, lazy_build => 1, );

sub _build_century {
    my $self = shift;
    my $sid  = $self->sex_id;
    return
         $sid == 1
      || $sid == 2 ? 19 : $sid == 3
      || $sid == 4 ? 18 : $sid == 5
      || $sid == 6 ? 20 : 19;
}

has birthday =>
  ( is => 'ro', isa => 'DateTime', init_arg => undef, lazy_build => 1, );

sub _build_birthday {
    my $self = shift;

    my $date = eval {
        DateTime::Format::Strptime::strptime( '%Y%m%d',
            $self->century . substr( $self->cnp, 1, 6 ) );
    };

    if ($@) {
        carp "Wrong date";
        return q{};
    }
    else {
        return $date;
    }
}

has county_id => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    default  => sub { substr( shift->cnp, 7, 2 ) },
);

has county => ( is => 'ro', isa => 'Str', init_arg => undef, lazy_build => 1, );

sub _build_county {
    my $self = shift;

    my %counties = (
        '01' => 'Alba',
        '02' => 'Arad',
        '03' => 'Argeş',
        '04' => 'Bacău',
        '05' => 'Bihor',
        '06' => 'Bistriţa-Năsăud',
        '07' => 'Botoşani',
        '08' => 'Braşov',
        '09' => 'Brăila',
        '10' => 'Buzău',
        '11' => 'Caraş-Severin',
        '12' => 'Cluj',
        '13' => 'Constanţa',
        '14' => 'Covasna',
        '15' => 'Dâmboviţa',
        '16' => 'Dolj',
        '17' => 'Galaţi',
        '18' => 'Gorj',
        '19' => 'Harghita',
        '20' => 'Hunedoara',
        '21' => 'Ialomiţa',
        '22' => 'Iaşi',
        '23' => 'Ilfov',
        '24' => 'Maramureş',
        '25' => 'Mehedinţi',
        '26' => 'Mureş',
        '27' => 'Neamţ',
        '28' => 'Olt',
        '29' => 'Prahova',
        '30' => 'Satu Mare',
        '31' => 'Sălaj',
        '32' => 'Sibiu',
        '33' => 'Suceava',
        '34' => 'Teleorman',
        '35' => 'Timiş',
        '36' => 'Tulcea',
        '37' => 'Vaslui',
        '38' => 'Vâlcea',
        '39' => 'Vrancea',
        '40' => 'Bucureşti',
        '41' => 'Sectorul 1',
        '42' => 'Sectorul 2',
        '43' => 'Sectorul 3',
        '44' => 'Sectorul 4',
        '45' => 'Sectorul 5',
        '46' => 'Sectorul 6',
        '51' => 'Călăraşi',
        '52' => 'Giurgiu',
    );

    return $counties{ $self->county_id };
}

has order_number => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    default  => sub { substr( shift->cnp, 9, 3 ) },
);

has checksum => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    default  => sub { substr( shift->cnp, 12, 1 ) },
);

has validator =>
  ( is => 'ro', isa => 'Int', init_arg => undef, lazy_build => 1, );

sub _build_validator {
    my $self = shift;

    my @cnp = split //xms, substr( $self->cnp, 0, 12 );
    my @check = split //xsm, '279146358279';

    my $sum;
    for my $i ( 0 .. 11 ) {
        $sum += $cnp[$i] * $check[$i];
    }

    my $result = $sum % 11;
    return $result == 10 ? 1 : $result;
}

sub valid {
    my ($self) = @_;
    return $self->birthday && $self->checksum == $self->validator ? 1 : 0;
}

1;

__END__

=head1 NAME

Business::RO::CNP - Romanian CNP validation

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 use Business::RO::CNP;

 my $cnp = Business::RO::CNP->new(cnp => 1040229319996);
 #or:
 my $cnp = Business::RO::CNP->new(1040229319996);

 print $cnp->valid ? "The CNP is valid" : "The CNP is not valid";

=head1 DESCRIPTION

This module checks the validation of CNP (personal numeric code) of Romania's citizens and offers information about the person.

=head1 SUBROUTINES/METHODS

=head2 valid

This method returns 1 if the CNP is valid or 0 otherwise.

It returns 1 when the L</birthday> method returns a valid birth date and when the last digit of the CNP returned by the method L</checksum> is equal to the value returned by the method L</validator>.

=head2 sex

This method returns 'm' if the person is a male or 'f' if is a female.

The method returns 'unknown' if the sex id of the person (the first digit in the CNP) is 9 (for non-romanian citizens).

When the first digit of the CNP is 1, 3, 5 or 7, this method returns 'm' and when it is 2, 4, 6 or 8, this method returns 'f'.

 print $cnp->sex;

=head2 sex_id

The method returns the first digit of the CNP. This digit is odd for men and even for women. It is 1 or 2 for those born between January 1 1900 and December 31 1999, 3 or 4 for those born between January 1 1800 and December 31 1899, 5 or 6 for those born between January 1 2000 and December 31 2099 and 7 or 8 for foreign citizens resident in Romania.

The sex id 9 is also reserved for foreign citizens.

 print $cnp->sex_id;

=head2 birthday

This method returns a L<DateTime|DateTime> object that holds the birth day of the person so you can call any DateTime methods on it.

 print $cnp->birthday;
 print $cnp->birthday->ymd;
 print $cnp->birthday->strftime('%d %m %y');
 print $cnp->birthday->set_locale('ro')->month_name;

Check the L<DateTime|DateTime> module for finding out what methods you can use with this object.

=head2 county

This method returns the county where the person was born or where he received the CNP.

 print $cnp->county;

=head2 county_id

This method returns the county ID which is the pair of digits 8 and 9 in the CNP.

Bucharest has the ID 40 but its sectors also have their own IDs.

 print $cnp->county_id;

=head2 checksum

This method returns the last digit in the CNP and represents a pre-calculated value based on the first 12 digits of the CNP.

 print $cnp->checksum;

=head2 validator

This method calculates the checksum from the first 12 digits of the CNP and it should be equal to the result of the checksum method in order to prove that the CNP is valid.

 print $cnp->validator;

=head2 cnp

This method returns the CNP given as parameter to the object constructor.

 print $cnp->cnp;

=head2 order_number

This method returns the 3-digit order number from the CNP.

 print $cnp->order_number;

=head2 century

This method returns the century in which the person was born.

 print $cnp->century;

=head1 AUTHOR

Octavian Rasnita, C<< <orasnita at gmail.com> >>

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-business-ro-cnp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-RO-CNP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

No configuration is necessary.

=head1 DEPENDENCIES

L<Moose|Moose>, L<DateTime::Format::Strptime|DateTime::Format::Strptime>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::RO::CNP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-RO-CNP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-RO-CNP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-RO-CNP>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-RO-CNP/>

=back

=head1 ACKNOWLEDGEMENTS

I found the algorithm for CNP validation on L<http://www.validari.ro/cnp> and the counties IDs on L<http://ro.wikipedia.org/wiki/Cod_numeric_personal>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Octavian Rasnita.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
