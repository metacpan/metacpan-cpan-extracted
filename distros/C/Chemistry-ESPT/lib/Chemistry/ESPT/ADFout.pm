package Chemistry::ESPT::ADFout;

use base qw(Chemistry::ESPT::ESSfile);
use strict;
use warnings;

=head1 NAME

Chemistry::ESPT::ADFout - Amsterdam Density Functional (ADF) output file object.

=head1 SYNOPSIS

   use Chemistry::ESPT::ADFout;

   my $out = Chemistry::ESPT::ADFout->new();

=head1 DESCRIPTION

This module provides methods to quickly access data contianed in an ADF output file.
ADF output files can only be read currently.

=begin comment

### Version History ###
 0.01	digest open & closed shell DFT output files,
 0.02	unified get method, Debug options, <S**2>,
	switched to ESPT namespace 

### To Do ###
 -Convert functionals to simpler syntax when appropriate
 -Report non-mixed ADF basis sets
 -Non-GGG functionals & energetics
 -Electronic state & multiplicity

=end comment

=cut

our $VERSION = '0.02';

=head1 ATTRIBUTES

All attributes are currently read-only and get populated by reading the assigned ESS file.  Attribute values 
are accessible through the B<$ADFout-E<gt>get()> method.

=over 15

=item COMPILE

String containing the compile architechture.

=item EELEC

Electronic energy.

=item EIGEN

A rank two tensor containing the eigenvalues.  The eigenvalues correspond to Alpha or 
Beta depending upon what spin was passesd to B<$ADFout-E<gt>analyze()>.

=item FUNCTIONAL

String containing the DFT functional utlized in this job.

=item HOMO

Number corresponding to the highest occupied molecular orbital. The value corresponds
to either Alpha or Beta electrons depending upon what spin was passesd to 
B<$ADFout-E<gt>analyze()>.

=item MOSYMM

A rank two tensor containing the molecular orbital symmetry labels.

=item OCC

A rank two tensor containing the molecular orbital occupations.

=item PG

Array of molecular point group values.

=item REVISION

ADF revision label.

=item RUNTIME

Date when the calculation was run.

=item VERSION 

ADF version.

=back

=head1 METHODS

Method parameters denoted in [] are optional.

=over 15

=item B<$out-E<gt>new()>

Creates a new ADFout object

=cut

## the object constructor **

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $out = Chemistry::ESPT::ESSfile->new();
	
	$out->{TYPE} = "out";
	
	# program info
	$out->{PROGRAM} = "ADF";
	$out->{VERSION} = undef;
	$out->{REVISION} = undef;
	$out->{COMPILE} = undef;
	
	# calc info
	$out->{RUNTIME} = undef;
	$out->{THEORY} = "DFT";		
	$out->{FUNCTIONAL} = undef;	
	$out->{BASIS} = "Mixed";	
	$out->{NBASIS} = 0;			# Core-orthogonalized Symmetrized Fragment Orbitals
	
	# molecular info
	$out->{EIGEN} = [];
	$out->{EELEC} = undef;			# SCF electronic bonding energy
	$out->{ENERGY} = undef; 		# total bonding energy 
	$out->{EINFO} = "Bonding E(elec)";	# total bonding energy description
	$out->{HOMO} = undef;
	$out->{MOSYMM} = [];
	$out->{OCC} = [];
	$out->{PG} = undef;

	bless($out, $class);
	return $out;
}


## methods ##

=item B<$out-E<gt>analyze(filename [spin])>
    
Analyze the spin results in file called filename.  Spin defaults to Alpha.

=cut

# set filename & spin then digest the file
sub analyze: method {
	my $out = shift;
	$out->prepare(@_);
	$out->_digest();
	return;
}

## subroutines ##

sub _digest {
# Files larger than 1Mb should be converted to binary and then
# processed to ensure maximum speed. -D. Ennis, OSC

# For items with multiple occurances, the last value is reported 

my $out = shift;

# flags & counters
my $Ccount = 0;
my $Cflag = 0;
my $eigcount = 0;
my $MOcount = 0;
my $orbcount = -1;
my $PGcount = 0;
my $rparsed = 0;
my $Sflag = 0;
my $symmflag = 0;

# open filename for reading or display error
open(LOGFILE,$out->{FILENAME}) || die "Could not read $out->{FILENAME}\n$!\n";

# grab everything which may be useful
while (<LOGFILE>){
	# skip blank lines
	next if /^$/;

        # version info & run time (multiple occurances & values)
	if ( /^\sADF\s+(\d+).(\d+)\s+RunTime:\s+([a-zA-Z]+)(\d{1,2})-(\d{4})\s\d{2}:\d{2}:\d{2}/ ) {
		$out->{VERSION} = $1;
              	$out->{REVISION} = $2;
		$out->{RUNTIME} = "$4-$3-$5";
		next;
        }
	# compile architecture (multiple occurances)
	if ( /^\s\*+\s+([a-z_A-Z]+)\s+\*+/ ) {
		$out->{COMPILE} = $1;
		next;
	}
	# functional (multiple occurances)
	if ( /^\s+Gradient Corrections:\s+([a-zA-Z0-9]+)\s+([a-zA-Z0-9]+)/ ) {
		$out->{FUNCTIONAL} = "$1$2";
		next;
	}
        # full point group 
        if ( /^\s+Symmetry:\s+([CDSIOT])\(([0-9DHILNV]+)\)/ ) {
	        $out->{PG} [$PGcount] = "$1($2)";
		$PGcount++;
		next;
	}
        # electrons 
	# figure HOMO & LUMO, alphas fill first
	# restricted
        if ( /^\s+Total:\s+(\d+)\s+\z/ ) {
                $out->{ALPHA} = $out->{BETA} = $out->{HOMO} = $1/2;
		next;
        }
	# unrestricted
        if ( /^\s+Total:\s+(\d+)\s+(?:\(Spin-A\)\s+\+\s+)*(\d+)\s+(?:\(Spin-B\))*/ ) {
                $out->{ALPHA} = $1;
                $out->{BETA} = $2;
		$out->{HOMO} = $out->{uc($out->{SPIN})};
		next;
        }
        # charge (multiple values and occurances)
        if ( /^\s+Net Charge:\s+(-*\d+)/ ) {   
                $out->{CHARGE} = $1;
		next;
        }
	# Multiplicity (multiple occurrences)
	if ( /^\s+Spin polar:\s+(\d+)/ ) {
		$out->{MULTIPLICITY} = $1+1;
		next;
	}
	# Core-orthogonalized Symmetrized Fragment Orbitals (molecular calculations)
	if (/^\s+Total nr. of \(C\)SFOs \(summation over all irreps\)\s+:\s+(\d+)/) {
		$out->{NBASIS} = $1;
		next;
	}
        # orbital symmetries, energies, occupations (multiple occurrences)
        if ( /^\s+Orbital\s+Energies,\s+all\s+Irreps/ ) {
		$symmflag = 1;
		$MOcount = 0;
		$orbcount++;
		next;
	} 
        if ( $symmflag == 1 && /^\s+([123ABDEGHILMPST\.gu]+)\s+\d+\s+[$out->{SPIN}]*\s+(\d+\.\d+)\s+(\-*\d\.\d+E\-*\+*\d+)\s+(\-*\d+\.\d+)\s+/ ) {
		my $symm = $1;
		my $txt = $2;
		my $eigen = $3;
		my $degen = 1;
		if ( $symm =~ /E[E123\.ug]/ ) {
			$degen = 2;
		} elsif ( $symm =~ /T[123\.ug]/ ) {
			$degen = 3;
		}
		$orbcount++ if $orbcount == -1;  	# temporary hack
		for (my $i=1; $i<=$degen; $i++ ) {
			$out->{MOSYMM} [$orbcount] [$MOcount] = lc($symm);
              		$out->{EIGEN} [$orbcount] [$MOcount] = $eigen;
			$out->{OCC} [$orbcount] [$MOcount] = $txt/$degen;
 			$MOcount++;
		}
            	$MOcount = $symmflag = 0 if $MOcount == $out->{NBASIS};
                next;                                     
        }
	# SCF bonding electronic energy
	# Grab from logfile.  Occurs earlier but harder to pick out.
	if ( /^\s+.*\s+GGA-XC\s+(-*\d+\.\d+)\s+a\.u\./ ) {
		$out->{EELEC} = $1;
		$out->{ENERGY} = $1;
		next;
	}
	# <S**2> value
	if ( /^\s+Total\s+S2\s+\(S\s+squared\)\s+\d\.\d+\s+(\d\.\d+)/ ) {
		$out->{SSQUARED} = $1;
		next;
	}

}
}


1;
__END__
# Below is the documentation for this module.

=back

=head1 VERSION

0.02

=head1 SEE ALSO

L<Chemistry::ESPT::ESSfile>, L<http://www.scm.com>

=head1 AUTHOR

Dr. Jason L. Sonnenberg, E<lt>sonnenberg.11@osu.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Dr. Jason L. Sonnenberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. I would like to hear of any
suggestions for improvement.

=cut

