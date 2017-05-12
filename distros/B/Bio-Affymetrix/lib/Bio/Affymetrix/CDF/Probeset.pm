#!/usr/bin/perl

# A Affymetrix probeset. We gloss over the fact that multiple
# Unit_blocks are allowed per Unit, since this whole set of modules
# only really cares about expression

package Bio::Affymetrix::CDF::Probeset;

use Bio::Affymetrix::CDF::Probe;

use Carp;

use warnings;
use strict;
our $VERSION=0.5;

# Docs come before the code

=head1 NAME

Bio::Affymetrix::CDF::Probeset- an Affymetrix probeset in an CDF file

=head1 SYNOPSIS

use Bio::Affymetrix::CDF;

# Parse the CDF file

my $cdf=new Bio::Affymetrix::CDF();

$cdf->parse_from_file("foo.cdf");

# Print out the probeset name of Unit 1001

my $probeset=$cdf->probesets()->{1001};

print $probeset->name();

=head1 DESCRIPTION

The Affymetrix microarray system produces files in a variety of
formats. If this means nothing to you, these modules are probably not
for you :). After these modules have parsed a CDF file, the resulting
Bio::Affymetrix::CDF file contains a hash of
Bio::Affmetrix::CDF::Probeset objects, keyed on the unit number. This allows you look at the
details of the probeset.

If you have parsed a CDF file with probe-level parsing turned on, you
can examine the individual probes using the probes method. By altering
the contents of this array, you can redesign the chip! NASC use this
in our cross-species work (http://affymetrix.arabidopsis.info/xspecies).

=head2 HINTS

You can only get probe-level information if you have parsed the CDF
object with probe-level parsing turned on.

=head2 WARNING

The probe level parsing interface is a bit inelegant at the
moment. This might change in future versions.

=head1 COPYRIGHT

Copyright (C) 2005 by Nick James, David J Craigon, NASC (arabidopsis.info), The
University of Nottingham

This module is free software. You can copy or redistribute it under the same terms as Perl itself. 

Affymetrix is a registered trademark of Affymetrix Inc., Santa
Clara, California, USA.

=head1 AUTHORS
    
Nick James (nick at arabidopsis.info)

David J Craigon (david at arabidopsis.info)

Nottingham Arabidopsis Stock Centre (http://arabidopsis.info), University of Nottingham.

=head1 METHODS

=cut


=head2 new

  Arg [0]    : none
  Example    : my $cdf=new Bio::Affymetrix::CDF::Probeset();
  Description: constructor for Bio::Affymetrix::CDF::Probeset
object. You probably do not want to make these objects yourself yet, however.
  Returntype : new Bio::Affmetrix::CDF::Probeset object
  Exceptions : none
  Caller     : general

=cut


sub new {
    my $class=shift;
    my $q=shift;
    my $self={};
    $self->{"PROBES"}=[];

    bless $self,$class;


    return $self;
}

# Getter/setters

# Probeset trivia


# Unit Name is always None for expression arrays

=head2 unit_name
  Arg [1]    : 	string $unit_name (optional)
  Example    : 	my $unit_name=$ps->unit_name()
  Description: 	Always NONE for expression arrays. Only available in MAS5 files
  Returntype : string
  Exceptions : none
  Caller     : general
=cut

sub unit_name {
    my $self=shift;
    
    if (my $q=shift) {
	$self->{"UNITNAME"}=$q;
    }
    
    return $self->{"UNITNAME"};
}

# Sense or anti sense probeset? Returns true, or false

=head2 is_sense
  Arg [1]    : 	boolean $sense (optional)
  Example    : 	if ($ps->is_sense()) { .... }
  Description: 	Returns true when this is a sense (rather than
anti-sense) probeset. Only available in MAS5 files
  Returntype : boolean
  Exceptions : none
  Caller     : general
=cut


sub is_sense {
    my $self=shift;

    if (my $q=shift) {
	$self->{"SENSE"}=$q;
    }
    return $self->{"SENSE"};
}

# These are all named "original_" because they aren't calculated, they are what a parsed file claims

# number of probepairs making up the probeset


=head2 original_num_probepairs
  Arg [0]    : 	none
  Example    : 	my $probepairs=$ps->original_num_probepairs()
  Description: 	Get the number of probepairs in this probeset
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub original_num_probepairs {
    my $self=shift;
    return $self->{"NUMATOMS"};
}

# number of squares making up the probeset
=head2 original_num_probes
  Arg [0]    : 	none
  Example    : 	my $probepairs=$ps->original_num_probes()
  Description: 	Get the number of probes in this probeset
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut


sub original_num_probes {
    my $self=shift;
    return $self->{"NUMCELLS"};
}

# arbitrary number for the probeset

=head2 original_unit_number
  Arg [0]    : 	none
  Example    : 	my $probepairs=$ps->unit_number()
  Description: 	Get the unit number of this probeset (a unique number
assigned to each probe in the CDF file but otherwise meaningless)
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub original_unit_number {
    my $self=shift;
    return $self->{"UNITNUMBER"};
}

sub unit_number {
    my $self=shift;
    carp "unit_number is deprecated. Use original_unit_number instead (same function only renamed)";
    $self->original_unit_number(@_);
}

# type of unit as an ENUM like thing


=head2 unit_type
  Arg [1]    : 	optional, one of "CustomSeq", "genotyping", "expression", "tag/GenFlex"
  Example    : 	my $unit_type=$ps->unit_type()
  Description: 	Get/Set the unit number of this probeset. Probably expression only
  Returntype : one of "CustomSeq", "genotyping", "expression", "tag/GenFlex"
  Exceptions : none
  Caller     : general
=cut

sub unit_type {
    my $self=shift;

    if (my $q=shift) {
	if ($q eq "CustomSeq") {
	    $self->{"UNITTYPE"}=1;
	} elsif ($q eq "genotyping") {
	    $self->{"UNITTYPE"}=2;
	} elsif ($q eq "expression") {
	    $self->{"UNITTYPE"}=3;
	} elsif ($q eq "tag/GenFlex") {
	    $self->{"UNITTYPE"}=7;
	} else {
	    die "Not a valid unit type";
	}
    }

    if ($self->{"UNITTYPE"}==1) {
	return "CustomSeq";
    } elsif ($self->{"UNITTYPE"}==2) {
	return "genotyping";
    } elsif ($self->{"UNITTYPE"}==3) {
	return "expression";
    } elsif ($self->{"UNITTYPE"}==7) {
	return "tag/GenFlex";
    }
}

## Censor this?

sub original_number_blocks {
    my $self=shift;
    return $self->{"NUMBERBLOCKS"};
}


# 0= substitution 1= insertion 2=deletion. No effort made here- we
# don't really do genotyping arrays

=head2 mutation_type
  Arg [0]    : 	integer
  Example    : none
  Description: Get/set mutation_type. If this is a genotyping probe
set, 0=substitution, 1=insertion, 2=deletion. Only available in MAS5
  arrays using this software.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut


sub mutation_type {
    my $self=shift;

    if (my $q=shift) {
	$self->{"MUTATIONTYPE"}=$q;
    }
    return $self->{"MUTATIONTYPE"};
}

=head2 name
  Arg [1]    : string
  Example    : my $name=$ps->name()
  Description: Get/set name of probeset
  Returntype : string
  Exceptions : none
  Caller     : general
=cut


sub name {
    my $self=shift;

    if (my $q=shift) {
	$self->{"NAME"}=$q;
    }
    return $self->{"NAME"};
}

=head2 probe_pairs
  Arg [1]    : arrayref $probelist
  Example    : my @probes=$ps->probe_pairs()
  Description: Get/set list of probe pairs making up this array. Only available if
    with probes mode is used.

    Returns an reference to an array of "probe pairs". Each "probe pair"
    is an array reference containing two Bio::Affymetrix::CDF::Probe
    objects.
    
    The design of the CDF file implies that one point chips with 3
    mismatch probes and one perfect match probe were mooted, but we
    are unsure whether any of these were ever released to the
    public. Nevertheless, these modules are ready!

  Returntype : reference to array of arrayrefs of Bio::Affymetrix::CDF::Probe objects
  Exceptions : none
  Caller     : general
=cut


sub probe_pairs {
    my $self=shift;
    if (!$self->{"probemode"}) {
	die "Probes is not available when not in probemode";
    }

    if (my $q=shift) {
	$self->{"PROBES"}=$q;
    }
    return $self->{"PROBES"};
}


sub probes {
    my $self=shift;

    carp ("probes deprecated. Use probe_pairs instead");
    $self->probe_pairs(@_);
}


=head2 CDF
  Arg [1]    : Bio::Affymetrix::CDF object $probelist
  Example    : my $cdf=$ps->probes()
  Description: Get/set CDF object this probeset belongs to.
  Returntype : Bio::Affymetrix::CDF object
  Exceptions : none
  Caller     : general
=cut


sub CDF {
    my $self=shift;

    if (my $q=shift) {
	$self->{"CDF"}=$q;
    }
    return $self->{"CDF"};
}



# Parses from FileHandle


sub _parse_from_filehandle {
    my $self=shift;
    my $fh=shift;

    $self->{"probemode"}=shift;

    $self->{"FH"}=$fh;

    # Handle trivia from unit header
    my $i;

    while (defined($i=<$fh>) && (!($i=~/^\[.*\]$/o))) {
	if ($i=~/^([^=]+)=(.*)$/o) { 
	    my $name=$1;
	    my $value=$2;
	    if (uc $name eq "NAME") {
		$self->{"UNITNAME"}=$value;
	    } elsif (uc $name eq "DIRECTION") {
		$self->{"SENSE"}=($value==1);
	    } else {
		$self->{uc $name}=$value;
	    }
	}
    }

    # Block section
    while (defined($i=<$fh>) && (!($i=~/^\[.*\]$/o))) {
	if ($i=~/^([^=]+)=(.*)$/o) { 
	    my $name=$1;
	    my $value=$2;
	    if ($self->{"probemode"}&&$name=~/Cell\d+/o) {
		my $h= new Bio::Affymetrix::CDF::Probe();
		my @s=split /\t/,$value;
		$h->{"NAME"}=$name;
		$h->{"X"}=$s[0];
		$h->{"Y"}=$s[1];
		$h->{"PROBE"}=$s[2];
		$h->{"EXPOS"}=$s[5];
		$h->{"POS"}=$s[6];
		$h->{"PBASE"}=$s[8];
		$h->{"TBASE"}=$s[9];
		$h->{"ATOM"}=$s[10];
		$h->{"INDEX"}=$s[11];
		$h->{"PROBESET"}=$self;
		push @{$self->{"PROBES"}->[$h->{"ATOM"}]},$h;
		$self->{"CDF"}->{"PROBEGRID"}->[$h->{"X"}][$h->{"Y"}]=$h;

	    } elsif (uc $name eq "NAME") {
		$self->{"NAME"}=$value;
	    }
	}
    }

    return $i;
}

# Parses from FileHandle for XDA format file


sub _parse_from_filehandle_bin {
    my $self=shift;
    my $fh=shift;

    $self->{"probemode"}=shift;

    $self->{"FH"}=$fh;

    # Handle trivia from unit header

    my $buffer;

    # General header information

    (read ($fh, $buffer, 20)==20) or die "Can no longer read from file";

    ($self->{"UNITTYPE"},$self->{"DIRECTION"},$self->{"NUMATOMS"},undef,$self->{"NUMCELLS"},$self->{"UNITNUMBER"},$self->{"ATOMSPERCELL"})=unpack ("SCV4C",$buffer);

    # Translate UNITTYPE into equivalent numbers for MAS5

    if ($self->{"UNITTYPE"}==1) {
	$self->{"UNITTYPE"}=3;
    } elsif ($self->{"UNITTYPE"}==2) {
	$self->{"UNITTYPE"}=2;
    } elsif ($self->{"UNITTYPE"}==3) {
	$self->{"UNITTYPE"}=1;
    } elsif ($self->{"UNITTYPE"}==4) {
	$self->{"UNITTYPE"}=7;
    } 

    # Block information- we assume one block only since we only do expression arrays

    $self->{"NUMBERBLOCKS"}=1;

    (read ($fh, $buffer, 82)==82) or die "Can no longer read from file";

    {
	my @temp=unpack ("V2C2V2Z64",$buffer);
	$self->{"NAME"}=$temp[6];
    }

    $self->{"UNITNAME"}="NONE";

    $self->{"PROBES"}=[];

    for (my $i=1;$i<=$self->{"NUMCELLS"};$i++) {
	(read ($fh, $buffer, 14)==14) or die "Can no longer read from file";
	if ($self->{"probemode"}) {	
	    my $h= new Bio::Affymetrix::CDF::Probe();
	    
	    ($h->{"ATOM"},$h->{"X"},$h->{"Y"},$h->{"POS"},$h->{"PBASE"},$h->{"TBASE"})=unpack("VS2VC2",$buffer);
	    
	    $h->{"INDEX"}=$i;
	    
	    $h->{"PBASE"}=uc(chr($h->{"PBASE"}));
	    $h->{"TBASE"}=uc(chr($h->{"TBASE"}));
	    $h->{"PROBESET"}=$self;
	    
	    push @{$self->{"PROBES"}->[$h->{"ATOM"}]},$h;
	    $self->{"CDF"}->{"PROBEGRID"}->[$h->{"X"}][$h->{"Y"}]=$h;
	}
    }

}


1;
