package Biblio::ILL::ISO::SupplyDetails;

=head1 NAME

Biblio::ILL::ISO::SupplyDetails

=cut

use Biblio::ILL::ISO::ILLASNtype;
use Biblio::ILL::ISO::ILLString;
use Biblio::ILL::ISO::DateDue;
use Biblio::ILL::ISO::Amount;
use Biblio::ILL::ISO::ShippedConditions;
use Biblio::ILL::ISO::ShippedVia;
use Biblio::ILL::ISO::UnitsPerMediumTypeSequence;

use Carp;

=head1 VERSION

Version 0.01

=cut
our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.08.11 - original version
#---------------------------------------------------------------------------

=head1 DESCRIPTION

Biblio::ILL::ISO::SupplyDetails is a derivation of Biblio::ILL::ISO::ILLASNtype.

=head1 USES

 Biblio::ILL::ISO::ILLString
 Biblio::ILL::ISO::DateDue
 Biblio::ILL::ISO::Amount
 Biblio::ILL::ISO::ShippedConditions
 Biblio::ILL::ISO::ShippedVia
 Biblio::ILL::ISO::UnitsPerMediumTypeSequence

=head1 USED IN

 Biblio::ILL::ISO::Shipped

=cut

BEGIN{@ISA = qw ( Biblio::ILL::ISO::ILLASNtype );}   # inherit from ILLASNtype

=head1 FROM THE ASN DEFINITION
 
 Supply-Details ::= EXPLICIT SEQUENCE {
	date-shipped	          [0]	IMPLICIT ISO-Date OPTIONAL,
	date-due	          [1]	IMPLICIT Date-Due OPTIONAL,
	chargeable-units	  [2]	IMPLICIT INTEGER OPTIONAL, -- (1..9999)
	cost	                  [3]	IMPLICIT Amount OPTIONAL,
	shipped-conditions	  [4]	IMPLICIT Shipped-Conditions OPTIONAL,
	shipped-via		Shipped-Via OPTIONAL,
		-- electronic-delivery may only be present in APDUs with a
		-- protocol-version-num value of 2 or greater
	insured-for	          [6]	IMPLICIT Amount OPTIONAL,
	return-insurance-require  [7]	IMPLICIT Amount OPTIONAL,
	no-of-units-per-medium	  [8]	IMPLICIT SEQUENCE OF Units-Per-Medium-Type OPTIONAL
	}

=cut

=head1 METHODS

=cut

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 new( $date_shipped,$date_due, $chargeable_units, $cost, $shipped_conditions, $shipped_via, $insured_for, $return_insurance_require, $no_of_units_per_medium )

 Creates a new SupplyDetails object. 
 Expects (optionally) date-shipped (Biblio::ILL::ISO::ISODate or text string YYYYMMDD),
 (optionally) date-due (Biblio::ILL::ISO::ISODate or text string YYYYMMDD), 
 (optionally) chargeable-units (integer), 
 (optionally) cost (Biblio::ILL::ISO::Amount or text string),
 (optionally) shipped-conditions (Biblio::ILL::ISO::ShippedConditions),
 (optionally) shipped-via (Biblio::ILL::ISO::ShippedVia),
 (optionally) insured-for (Biblio::ILL::ISO::Amount or text string),
 (optionally) return-insurance-require (Biblio::ILL::ISO::Amount or text string),
 (optionally) no-of-units-per-medium (Biblio::ILL::ISO::UnitsPerMediumTypeSequence).

 Pass empty strings ("") as placeholders.

=cut
sub new {
    my $class = shift;
    my $self = {};

    if (@_) {
	my ($date_shipped, $date_due, $chargeable_units, $cost,
	    $shipped_conditions, $shipped_via, $insured_for,
	    $return_insurance_require, $no_of_units_per_medium) = @_;
	
	if ($date_shipped) {
	    if (ref($date_shipped) eq "Biblio::ILL::ISO::ISODate") {
		$self->{"date-shipped"} = $date_shipped;
	    } else {
		# assume it's in text format (ISODate will tell you if it's not)
		$self->{"date-shipped"} = new Biblio::ILL::ISO::ISODate($date_shipped);
	    }
	}

	if ($date_due) {
	    if (ref($date_due) eq "Biblio::ILL::ISO::DateDue") {
		$self->{"date-due"} = $date_due;
	    } else {
		# assume it's in text format (DateDue will tell you if it's not)
		# also assume it's renewable.
		$self->{"date-due"} = new Biblio::ILL::ISO::DateDue($date_due,"true");
	    }
	}

	if ($chargeable_units) {
	    croak "invalid chargeable-units" unless (($chargeable_units > 0) && ($chargeable_units <= 9999));
	    $self->{"chargeable-units"} = $chargeable_units;
	}

	if ($cost) {
	    if (ref($cost) eq "Biblio::ILL::ISO::Amount") {
		$self->{"cost"} = $cost;
	    } else {
		# assume it's in text format (Amount will tell you if it's not)
		$self->{"cost"} = new Biblio::ILL::ISO::Amount($cost);
	    }
	}

	if ($shipped_conditions) {
	    croak "invalid shipped-conditions" unless (ref($shipped_conditions) eq "Biblio::ILL::ISO::ShippedConditions");
	    $self->{"shipped-conditions"} = $shipped_conditions;
	}

	if ($shipped_via) {
	    croak "invalid shipped-via" unless (ref($shipped_via) eq "Biblio::ILL::ISO::ShippedVia");
	    $self->{"shipped-via"} = $shipped_via;
	}

	if ($insured_for) {
	    if (ref($insured_for) eq "Biblio::ILL::ISO::Amount") {
		$self->{"insured_for"} = $insured_for;
	    } else {
		# assume it's in text format (Amount will tell you if it's not)
		$self->{"insured-for"} = new Biblio::ILL::ISO::Amount($insured_for);
	    }
	}

	if ($return_insurance_require) {
	    if (ref($return_insurance_require) eq "Biblio::ILL::ISO::Amount") {
		$self->{"return-insurance-require"} = $return_insurance_require;
	    } else {
		# assume it's in text format (Amount will tell you if it's not)
		$self->{"return-insurance-require"} = new Biblio::ILL::ISO::Amount($return_insurance_require);
	    }
	}

	if ($no_of_units_per_medium) {
	    croak "invalid no-of-units-per-medium" unless (ref($no_of_units_per_medium) eq "Biblio::ILL::ISO::UnitsPerMediumTypeSequence");
	    $self->{"no-of-units-per-medium"} = $no_of_units_per_medium;
	}
    }

    bless($self, ref($class) || $class);
    return ($self);
}


#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set( $date_shipped, $date_due, $chargeable_units, $cost, $shipped_conditions, $shipped_via, $insured_for, $return_insurance_require, $no_of_units_per_medium )

 Sets the object's fields:
 (optionally) date-shipped (Biblio::ILL::ISO::ISODate or text string YYYYMMDD),
 (optionally) date-due (Biblio::ILL::ISO::ISODate or text string YYYYMMDD), 
 (optionally) chargeable-units (integer), 
 (optionally) cost (Biblio::ILL::ISO::Amount or text string),
 (optionally) shipped-conditions (Biblio::ILL::ISO::ShippedConditions),
 (optionally) shipped-via (Biblio::ILL::ISO::ShippedVia),
 (optionally) insured-for (Biblio::ILL::ISO::Amount or text string),
 (optionally) return-insurance-require (Biblio::ILL::ISO::Amount or text string),
 (optionally) no-of-units-per-medium (Biblio::ILL::ISO::UnitsPerMediumTypeSequence).

 Pass empty strings ("") as placeholders.

=cut
sub set {
    my $self = shift;
    my ($date_shipped, $date_due, $chargeable_units, $cost,
	$shipped_conditions, $shipped_via, $insured_for,
	$return_insurance_require, $no_of_units_per_medium) = @_;
    
    if ($date_shipped) {
	if (ref($date_shipped) eq "Biblio::ILL::ISO::ISODate") {
	    $self->{"date-shipped"} = $date_shipped;
	} else {
	    # assume it's in text format (ISODate will tell you if it's not)
	    $self->{"date-shipped"} = new Biblio::ILL::ISO::ISODate($date_shipped) if ($date_shipped);
	}
    }
    
    if ($date_due) {
	if (ref($date_due) eq "Biblio::ILL::ISO::DateDue") {
	    $self->{"date-due"} = $date_due;
	} else {
	    # assume it's in text format (DateDue will tell you if it's not)
	    # also assume it's renewable.
	    $self->{"date-due"} = new Biblio::ILL::ISO::DateDue($date_due,"true");
	}
    }

    if ($chargeable_units) {
	croak "invalid chargeable-units" unless (($chargeable_units > 0) && ($chargeable_units <= 9999));
	$self->{"chargeable-units"} = $chargeable_units;
    }
    
    if ($cost) {
	if (ref($cost) eq "Biblio::ILL::ISO::Amount") {
	    $self->{"cost"} = $cost;
	} else {
	    # assume it's in text format (Amount will tell you if it's not)
	    $self->{"cost"} = new Biblio::ILL::ISO::Amount($cost);
	}
    }
    
    if ($shipped_conditions) {
	croak "invalid shipped-conditions" unless (ref($shipped_conditions) eq "Biblio::ILL::ISO::ShippedConditions");
	$self->{"shipped-conditions"} = $shipped_conditions;
    }
    
    if ($shipped_via) {
	croak "invalid shipped-via" unless (ref($shipped_via) eq "Biblio::ILL::ISO::ShippedVia");
	$self->{"shipped-via"} = $shipped_via;
    }
    
    if ($insured_for) {
	if (ref($insured_for) eq "Biblio::ILL::ISO::Amount") {
	    $self->{"insured_for"} = $insured_for;
	} else {
	    # assume it's in text format (Amount will tell you if it's not)
	    $self->{"insured-for"} = new Biblio::ILL::ISO::Amount($insured_for);
	}
    }
    
    if ($return_insurance_require) {
	if (ref($return_insurance_require) eq "Biblio::ILL::ISO::Amount") {
	    $self->{"return-insurance-require"} = $return_insurance_require;
	} else {
	    # assume it's in text format (Amount will tell you if it's not)
	    $self->{"return-insurance-require"} = new Biblio::ILL::ISO::Amount($return_insurance_require);
	}
    }
    
    if ($no_of_units_per_medium) {
	croak "invalid no-of-units-per-medium" unless (ref($no_of_units_per_medium) eq "Biblio::ILL::ISO::UnitsPerMediumTypeSequence");
	$self->{"no-of-units-per-medium"} = $no_of_units_per_medium;
    }
    
    return;
}

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

	if (($k =~ /^client-name$/)
	    || ($k =~ /^client-status$/)
	    || ($k =~ /^client-identifier$/)
	    ) {
	    $self->{$k} = new Biblio::ILL::ISO::ILLString();
	    $self->{$k}->from_asn($href->{$k});
	    
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

=head2 set_date_shipped( $dt )

 Sets the object's date-shipped.
 Expects a valid Biblio::ILL::ISO::ISODate or a properly formattted text string (YYYYMMDD).

=cut
sub set_date_shipped {
    my $self = shift;
    my ($date_shipped) = @_;
    
    croak "missing date-shipped" unless ($date_shipped);
    if (ref($date_shipped) eq "Biblio::ILL::ISO::ISODate") {
	$self->{"date-shipped"} = $date_shipped;
    } else {
	# assume it's in text format (ISODate will tell you if it's not)
	$self->{"date-shipped"} = new Biblio::ILL::ISO::ISODate($date_shipped) if ($date_shipped);
    }
    
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_date_due( $dt )

 Sets the object's date-due.
 Expects a valid Biblio::ILL::ISO::ISODate or a properly formattted text string (YYYYMMDD).

=cut
sub set_date_due {
    my $self = shift;
    my ($date_due) = @_;
    
    croak "missing date-due" unless ($date_due);
    croak "invalid date-due" unless (ref($date_due) eq "Biblio::ILL::ISO::DateDue");
    $self->{"date-due"} = $date_due;
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_chargeable_units( $cu )

 Sets the object's chargeable-units.
 Expects an integer (1-9999).

=cut
sub set_chargeable_units {
    my $self = shift;
    my ($chargeable_units) = @_;
    
    croak "missing chargeable-units" unless ($chargeable_units);
    croak "invalid chargeable-units" unless (($chargeable_units > 0) && ($chargeable_units <= 9999));
    $self->{"chargeable-units"} = $chargeable_units;
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_cost( $cost )

 Sets the object's cost.
 Expects a valid Biblio::ILL::ISO::Amount or a text string.

=cut
sub set_cost {
    my $self = shift;
    my ($cost) = @_;
    
    croak "missing cost" unless ($cost);
    if (ref($cost) eq "Biblio::ILL::ISO::Amount") {
	$self->{"cost"} = $cost;
    } else {
	# assume it's in text format (Amount will tell you if it's not)
	$self->{"cost"} = new Biblio::ILL::ISO::Amount($cost);
    }
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_shipped_conditions( $sc )

 Sets the object's shipped-conditions.
 Expects a valid Biblio::ILL::ISO::ShippedConditions.

=cut
sub set_shipped_conditions {
    my $self = shift;
    my ($shipped_conditions) = @_;
    
    croak "missing shipped-conditions" unless ($shipped_conditions);
    croak "invalid shipped-conditions" unless (ref($shipped_conditions) eq "Biblio::ILL::ISO::ShippedConditions");
    $self->{"shipped-conditions"} = $shipped_conditions;
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_shipped_via( $sv )

 Sets the object's shipped-via.
 Expects a valid Biblio::ILL::ISO::ShippedVia.

=cut
sub set_shipped_via {
    my $self = shift;
    my ($shipped_via) = @_;
    
    croak "missing shipped-via" unless ($shipped_via);
    croak "invalid shipped-via" unless (ref($shipped_via) eq "Biblio::ILL::ISO::ShippedVia");
    $self->{"shipped-via"} = $shipped_via;
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_insured_for( $insured_amount )

 Sets the object's insured-for.
 Expects a valid Biblio::ILL::ISO::Amount or a text string.

=cut
sub set_insured_for {
    my $self = shift;
    my ($insured_for) = @_;
    
    croak "missing insured-for" unless ($insured_for);
    if (ref($insured_for) eq "Biblio::ILL::ISO::Amount") {
	$self->{"insured_for"} = $insured_for;
    } else {
	# assume it's in text format (Amount will tell you if it's not)
	$self->{"insured-for"} = new Biblio::ILL::ISO::Amount($insured_for);
    }
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_return_insurance_require( $insurance_required_amount )

 Sets the object's return-insurance-require.
 Expects a valid Biblio::ILL::ISO::Amount or a text string.

=cut
sub set_return_insurance_require {
    my $self = shift;
    my ($return_insurance_require) = @_;
    
    croak "missing return-insurance-require" unless ($return_insurance_require);
    if (ref($insured_for) eq "Biblio::ILL::ISO::Amount") {
	$self->{"return-insurance-require"} = $return_insurance_require;
    } else {
	# assume it's in text format (Amount will tell you if it's not)
	$self->{"return-insurance-require"} = new Biblio::ILL::ISO::Amount($return_insurance_requre);
    }
    return;
}

#---------------------------------------------------------------
#
#---------------------------------------------------------------
=head1

=head2 set_no_of_units_per_medium( $units )

 Sets the object's no-of-units-per-medium.
 Expects a valid Biblio::ILL::ISO::UnitsPerMediumType.

=cut
sub set_no_of_units_per_medium {
    my $self = shift;
    my ($no_of_units_per_medium) = @_;
    
    croak "missing no-of-units-per-medium" unless ($no_of_units_per_medium);
    croak "invalid no-of-units-per-medium" unless (ref($no_of_units_per_medium) eq "Biblio::ILL::ISO::UnitsPerMediumType");
    $self->{"no-of-units-per-medium"} = $no_of_units_per_medium;
    
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
