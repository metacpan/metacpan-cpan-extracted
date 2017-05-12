#!/usr/bin/perl

# A Affymetrix probeset. We gloss over the fact that multiple
# Unit_blocks are allowed per Unit, since this whole set of modules
# only really cares about expression

package Bio::Affymetrix::CDF::Probe;

# Docs come before the code

=head1 NAME

Bio::Affymetrix::CDF::Probe- an Affymetrix probe in a probeset in an CDF file

=head1 SYNOPSIS

use Bio::Affymetrix::CDF;

# Parse the CDF file

my $cdf=new CDF();

$cdf->parse_from_file("foo.cdf");

# Find a probe. This is the first probe in the first probepair in Unit 1000

my $probe=$chp->probesets()->{1000}->[0]->[0];

# Find some fun facts about this probe

print join ",",
($probe->x(),$probe->y(),($probe->is_mismatch()?"Mismatch probe":"Perfect match probe");

=head1 DESCRIPTION

The Affymetrix microarray system produces files in a variety of
formats. If this means nothing to you, these modules are probably not
for you :). After these modules have parsed a CDF file, the resulting
Bio::Affymetrix::CDF file contains a hash of
Bio::Affmetrix::CDF::Probeset objects. Each probeset then contains an
 array reference of probepairs, each one which is an array reference
 of Bio::Affymetrix::CDF::Probe objects.

=head2 HINTS

You can only get probe-level information if you have parsed the CDF
object with probe-level parsing turned on.

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


use Carp;

use warnings;
use strict;
our $VERSION=0.5;

=head2 new

  Arg [0]    : none
  Example    : my $probe=new Bio::Affymetrix::CDF::Probe();
  Description: constructor for Bio::Affymetrix::CDF::Probe object. You
  probably do not want to make these objects yourself, however. 
  Returntype : new Bio::Affmetrix::CDF object
  Exceptions : none
  Caller     : general

=cut

sub new {
    my $class=shift;
    my $q=shift;
    my $self={};

    bless $self,$class;


    return $self;
}

# Getter/setters

# Probe info

# Coordinates of probe


=head2 x
    Arg [1]    :  integer $x (optional)
    Example    :  my $x=$probe->x();
 Description: 	Get the x coordinate of this probe. This is now (since version 0.3) immutable.
    Returntype : integer
    Exceptions : none
    Caller     : general
    
=cut
sub x {
    my $self=shift;
    return $self->{"X"};
}

=head2 y
    Arg [1]    : 	integer $y (optional)
    Example    : 	my $name=$probe->cols()
  Description: 	Get the y coordinate of this probe. This is now (since version 0.3) immutable.
    Returntype : integer
    Exceptions : none
    Caller     : general
=cut
sub y {
    my $self=shift;
    
    return $self->{"Y"};
}

# Probeset the probe came out of (name)

=head2 original_probeset
    Arg [0]    : none
    Example    : my $name=$probe->original_probeset()
  Description: 	The name of the original probeset this probe came from
    Returntype : string $probesetname
    Exceptions : none
    Caller     : general
=cut

sub original_probeset {
    my $self=shift;
    return $self->{"PROBESET"};
}

# The number of the probe in the probeset

=head2 orignal_probe_number
    Arg [0]    : none
    Example    : my $position=$probe->original_probe_number()
  Description: 	The name of the original index of this probe in the probeset
    Returntype : string $probesetname
    Exceptions : none
    Caller     : general
=cut
sub original_probe_number {
    my $self=shift;
    return $self->{"EXPOS"};
}



# Position of the mismatched base
=head2 mismatch_position
    Arg [1]    :  integer $position (optional)
    Example    :  my $position=$probe->mismatch_position();
 Description: 	Get/set the postition of the mismatch base (in the
 25-mer oligo. As far as the author knows, all factory Affymetrix
chips have the mismatch probe in position 13). Only available if the
    original CDF file was in MAS5 format. 
    Returntype : integer
    Exceptions : none
    Caller     : general
    
=cut
sub mismatch_position {
    my $self=shift;
    
    if (my $q=shift) {
	$self->{"POS"}=$q;
    }
    
    return $self->{"POS"};
}


# The base at the mismatch position
=head2 probe_mismatch_base
    Arg [1]    : char $base
    Example    : my $base=$probe->probe_mismatch_base()
  Description: 	Get/set the base A,C,T or G at the mismatch position.
    Returntype : char $base
    Exceptions : none
    Caller     : general
=cut
sub probe_mismatch_base {
    my $self=shift;
    
    if (my $q=shift) {
	$self->{"PBASE"}=$q;
    }
    
    return $self->{"PBASE"};
}

# 
=head2 probe_target_base
    Arg [1]    : char $base
    Example    : my $base=$probe->probe_target_base()
  Description: 	Get/set what the base (A, C, T or G) would be if it is to detect for
    the target sequence. Non-mismatch probes have
    probe_mismatch_base() eq probe_target_base().
    Returntype : char $base
    Exceptions : none
    Caller     : general
=cut
sub probe_target_base {
    my $self=shift;
    
    if (my $q=shift) {
	$self->{"TBASE"}=$q;
    }
    
    return $self->{"TBASE"};
}

# Is this probe a mismatch?
=head2 is_mismatch
    Arg [0]    : none
    Example    : if ($probe->is_mismatch()) { 
print "Everybody loves mismatch probes!"; 
}
  Description: 	Utility function that returns whether this probe is a
    mismatch probe or not.
    Returntype : bool
    Exceptions : none
    Caller     : general
=cut
sub is_mismatch {
    my $self=shift;
    return ($self->probe_target_base() eq $self->probe_mismatch_base());
}

=head2 original_probepair_number
    Arg [0]    : none
    Example    : my $original_number=$probe->original_probepair_number();
  Description: 	Returns the probe pair number as written in the file
    Returntype : integer $number
    Exceptions : none
    Caller     : general
=cut
sub original_probepair_number {
    my $self=shift;

    return $self->{"ATOM"};
}

# Index for CEL file, apparently

=head2 index
    Arg [1]    :  integer $index (optional)
    Example    :  my $i=$probe->index();
 Description: 	Get/set the index of this probe. Allegedly this number
    was used in the CEL file at some point, but is probably useless now.
    Returntype : integer
    Exceptions : none
    Caller     : general
    
=cut
sub index {
    my $self=shift;

    if (my $q=shift) {
	$self->{"INDEX"}=$q;
    }
    return $self->{"INDEX"};
}

1;
