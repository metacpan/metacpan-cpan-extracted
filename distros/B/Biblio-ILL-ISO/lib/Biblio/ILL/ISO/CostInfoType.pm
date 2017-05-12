package Biblio::ILL::ISO::CostInfoType;

=head1 NAME

Biblio::ILL::ISO::CostInfoType

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::AccountNumber;
use Biblio::ILL::ISO::Amount;

use Carp;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::CostInfoType is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::AccountNumber
 Biblio::ILL::ISO::Amount

=head1 USED IN

 Biblio::ILL::ISO::Request

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Cost-Info-Type ::= SEQUENCE {
	account-number	        [0]	Account-Number OPTIONAL,
	maximum-cost	        [1]	IMPLICIT Amount OPTIONAL,
	reciprocal-agreement	[2]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	will-pay-fee	        [3]	IMPLICIT BOOLEAN, -- DEFAULT FALSE,
	payment-provided	[4]	IMPLICIT BOOLEAN -- DEFAULT FALSE
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 from_asn($href)

Given a properly formatted hash, builds the object.

=cut
sub from_asn {
    my $self = shift;
    my $href = shift;

    foreach my $k (keys %$href) {
	#print ref($self) . "...$k\n";

	if ($k =~ /^account-number$/) {
	    $self->{$k} = new Biblio::ILL::ISO::AccountNumber();
	    $self->{$k}->from_asn($href->{$k});

	} elsif ($k =~ /^maximum-cost$/) {
	    $self->{$k} = new Biblio::ILL::ISO::Amount();
	    $self->{$k}->from_asn($href->{$k});

	} elsif (($k =~ /^reciprocal-agreement$/)
		 || ($k =~ /^will-pay-fee$/)
		 || ($k =~ /^payment-provided$/)
		 ) {
	    $self->{$k} = $href->{$k};
	    
	} else {
	    croak "invalid " . ref($self) . " element: [$k]";
	}

    }
    return $self;
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $reciprocal_agreement, $will_pay_fee, $payment_provided [, $account] [, $maxcost])

Creates a new CostInfoType object. 
 Expects a reciprocal-agreement flag (0/1),
 a will-pay-fee flag (0/1), 
 a payment-provided flag (0/1),
 (optionally) an account-number (Biblio::ILL:ISO::AccountNumber), and 
 (optionally) a maximum-cost (Biblio::ILL::ISO::Amount).

=cut
sub new {
    my $class = shift;
    my $self = {};

    $self->{"reciprocal-agreement"} = 0;
    $self->{"will-pay-fee"} = 0;
    $self->{"payment-provided"} = 0;

    if (@_) {
	my ($reciprocal, $will_pay, $payment_provided, 
	    $account, $maxcost) = @_;
	
	$self->{"reciprocal-agreement"} = $reciprocal if ($reciprocal);
	$self->{"will-pay-fee"} = $will_pay if ($will_pay);
	$self->{"payment-provided"} = $payment_provided  if ($payment_provided);;
	$self->{"account-number"} = new Biblio::ILL::ISO::AccountNumber($account) if ($account);
	$self->{"maximum-cost"} = new Biblio::ILL::ISO::Amount($maxcost);
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $reciprocal_agreement [, [$will_pay_fee] [, [$payment_provided] [, [$account] [, $maxcost]]]] )

 Sets the object's reciprocal-agreement flag (0/1),
 (optionally) will-pay-fee flag (0/1), 
 (optionally) payment-provided flag (0/1),
 (optionally) account-number (Biblio::ILL:ISO::AccountNumber), and 
 (optionally) maximum-cost (Biblio::ILL::ISO::Amount).

=cut
sub set {
    my $self = shift;
    my ($reciprocal, $will_pay, $payment_provided, $account, $maxcost) = @_;

    croak "missing reciprocal-agreement" unless $reciprocal;

    $self->{"reciprocal-agreement"} = $reciprocal;
    $self->{"will-pay-fee"} = $will_pay if ($will_pay);
    $self->{"payment-provided"} = $payment_provided if ($payment_provided);
    $self->{"account-number"} = new Biblio::ILL::ISO::AccountNumber($account) if ($account);
    $self->{"maximum-cost"} = new Biblio::ILL::ISO::Amount($maxcost) if ($maxcost);

    return;
}

=head1 SEE ALSO

See the README for system design notes.
See the parent class(es) for other available methods.

For more information on Interlibrary Loan standards (ISO 10160/10161),
a good place to start is:

http://www.nlc-bnc.ca/iso/ill/main.htm

=cut

=head1 AUTHOR

David Christensen, <DChristensenSPAMLESS@westman.wave.ca>

=cut


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by David Christensen

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
