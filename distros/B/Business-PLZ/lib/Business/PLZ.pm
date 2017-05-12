use strict;
use warnings;
package Business::PLZ;
{
  $Business::PLZ::VERSION = '0.11';
}
#ABSTRACT: Validate German postal codes and map them to states

use Tree::Binary::Search 1.0;
use overload '""' => sub { ${$_[0]} };
use Carp 'croak';

our $STATES;

# http://web.archive.org/web/*/http://www.uni-koeln.de/~arcd2/3d.htm
BEGIN { 
my %RANGES = ( 
BW => [qw(68000-68309 68520-68549 68700-69234 69240-69429 69435-69469
          69489-69502 69510-69514 70000-76709 77600-79879 88000-88099
          88180-89198 89300-89619 97860-97999)],
BY => [qw(63700-63939 80000-87490 87493-87561 87570-87789 88100-88179
          89200-89299 90000-96489 97000-97859)],
BE => [qw(10000-12527 12531-14199)],
BB => [qw(01940-01998 03000-03253 04890-04938 12529 
          14400-16949 17260-17291 19340-19357)],
HB => [qw(27500-27580 28000-28779)],
HH => [qw(20000-21149 22000-22769 27499)],
HE => [qw(34000-34329 34356-34399 34440-36399 37195 37200-37299
          55240-55252 59969 60000-63699 64200-65556 65583-65620 65627
          65700-65936 68501-68519 68600-68649 69235-69239 69430-69434
          69479-69488 69503-69509 69515-69518)],
MV => [qw(17000-17259 17300-19260 19280-19339 19360-19417 23920-23999)],
NI => [qw(19270-19273 21202-21449 21522 21600-21789 26000-27478 27607-27809
          28784-29399 29430-31868 34330-34355 37000-37194 37197-37199 
          37400-37649 37689-37691 37697-38479 38500-38729 48442-48465 
          48478-48480 48486-48488 48497-48531 49000-49459 49550-49849)],
NW => [qw(32000-33829 34400-34439 37650-37688 37692-37696 40000-48432
          48466-48477 48481-48485 48489-48496 48541-48739 49461-49549
          50100-51597 51600-53359 53580-53604 53620-53949 57000-57489
          58000-59968)],
RP => [qw(51598 53400-53579 53614-53619 54200-55239 55253-56869 57500-57648
          65558-65582 65621-65626 65629 66460-66509 66840-67829 76710-76891)],
SL => [qw(66000-66459 66510-66839)],
SN => [qw(01000-01936 02600-02999 04000-04579 04640-04889 07917-07919
          07951-07952 07982-07985 08000-09669)],
ST => [qw(06000-06548 06600-06928 29400-29416 38480-38489 38800-39649)],
SH => [qw(21450-21521 21524-21529 22801-23919 24000-25999 27483-27498)],
TH => [qw(04580-04639 06550-06578 07300-07907 07920-07950 07953-07980
          07987-07989 36400-36469 37300-37359 96500-96529 98500-99998)],
8 => [qw(87567-87569)], # Kleinwalsertal, Vorarlberg
7 => [87491],           # Jungholz, Tirol
);

    $STATES = Tree::Binary::Search->new;
    $STATES->setComparisonFunction(sub {
        my ($a1,$a2) = split '-', $_[0];
        my ($b1,$b2) = split '-', $_[1];
        $a2 = $a1 unless defined $a2;   
        $b2 = $b1 unless defined $b2;
        return -1  if $a2 < $b1;
        return +1  if $a1 > $b2;
        return 0;
    });
    while (my ($state,$ranges) = each(%RANGES)) {
        foreach my $plz (@$ranges) {
            $STATES->insert($plz,$state);
        }
    }
}

# TODO: see http://anchje.de/inv_rep2.htm for more expections
# 21039 SH and HH
# 37194 HE and NE
# 59969 HE and NW

sub new {
    my ($class, $code) = @_;
    $class = ref $class || $class;

    croak 'invalid postal code' unless $code and $code =~ qr/^\d{5}$/;
    
    bless \$code, $class;
}

sub state {
    my $plz = shift;
    $plz = Business::PLZ->new( $plz )
        unless ref $plz and $plz->isa('Business::PLZ');
    # Tree::Binary throws on exception if key does not exist :-(
    return $STATES->exists($plz) ? $STATES->select($plz) : undef;
}

sub exists {
    my $state = state(shift);
    return defined $state ? 1 : 0;
}

sub iso_state {
    my $state = state(shift) || return;
    return ($state =~ /[A-Z][A-Z]/) ? "DE-$state" : "AT-$state";
}

1;



=pod

=head1 NAME

Business::PLZ - Validate German postal codes and map them to states

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Business::PLZ;

    my $plz = Business::PLZ->new('12345'); # croaks on invalid code

    print "$plz";     # stringify

    $plz->state;      # state or undef if not exist 
    $plz->iso_state;  # state as full ISO code

=head1 DESCRIPTION

This module validates German postal codes and maps them to states.

=head1 METHODS

=head2 state

Returns the state ("Bundesland") of a postal code as ISO 3166-2 subdivision
code. The country prefix 'DE-' (or 'AT-') is not included. Some postal codes
belong to more than one state - in this case only one state is returned. A
future version of this module may also return multiple states. 

If no state was found (so the postal code likely does not exists), this
method returns undef. The method 'exists' is based on this lookup.

To get more information about a state, you can use L<Locale::SubCountry>:

   $state_code = $plz->state;
   $state_name = Locale::SubCountry->new('DE')->full_name( $state_code );

=head2 iso_state

Returns the state of a postal code as ISO 3166-2 subdivision code, including
country prefix.

=head2 exists

Returns whether the postal code is assigned. This is exactely the case if
it can be mapped to a state.

=head1 SEE ALSO

There are some country-specific modules to handle postal codes, for instance
L<PT::PostalCode> and L<Business::DK::PO>. L<Geo::PostalAddress> contains
regular expressions for postal codes of almost every country.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

