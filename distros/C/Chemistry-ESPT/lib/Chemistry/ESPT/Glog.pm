package Chemistry::ESPT::Glog;

use base qw(Chemistry::ESPT::ESSfile);
use Chemistry::ESPT::Glib 0.01;
use strict;
use warnings;

our $VERSION = '0.08';

=head1 NAME

Chemistry::ESPT::Glog - Gaussian log file object.

=head1 SYNOPSIS

   use Chemistry::ESPT::Glog;

   my $log = Chemistry::ESPT::Glog->new();

=head1 DESCRIPTION

This module provides methods to quickly access data contained in a Gaussian log file.
Guassian log files can only be read currently.

=begin comment

### Version History ###
 0.01	digest closed-shell DFT log files
 0.02	adjust total energy for Opt/Freq runs
 0.03	added TPSS functional, fixed issue with large negative eigenvalues,
	store all PG, E(elec), Eigenvalues, MO symm, and Occupations values, 
 	get method for 1 & 2D arrays
 0.04	fixed Version regexp to handle GDV
 0.05	set MO symmetry labels if PG = C(1)
 0.06	Extract <S^2> & Electronic State, consolidated get & get2D methods,
	Debug options, fixed MOsymm regexp for D(*H) species, fixed G98 
 	Total MO bug
 0.07	Switched to ESPT namespace, total cpu times, fix for * notation
	in basis sets, route parsing for theory/basis syntax, enumerate
	the * & ** basis notations, "keyword(option, option)" keywords 
	properly split in the route parser, handle + in revision numbers,
	use Glib, thermal corrections to E, H, and G; Delta G(solv), complete flag,
	extensive perldoc, optimized flag, saddle-point order,
 0.08	Updated S**2 regex,

### To Do ###
 -enable/disable storage of all reoccuring data values
 -store only most recent data from reoccuring data by default
 -TS vector decomposition
 -Improved handling of % commands: place into a hash by splitting over =
  this will keep memory useage down and simplify the regexs
 -More info for Gen basis sets
 -Handle non #p log files
 -Internal coordinates
 -Multi-job Link1 log files
 -Handle RO(Theory)
 -Nonstd routes
 -Handle correlation method energies properly
 -Digest scan data

=end comment

=head1 ATTRIBUTES

All attributes are currently read-only and get populated by reading the assigned ESS 
file.  Attribute values
are accessible through the B<$Glog-E<gt>get()> method.

=over 15

=item BASISLABELS

Rank two tensor containing the labels for each basis function.

=item C

A rank three tensor containing the NBASIS x NBASIS coefficient matrices. The coefficients 
correspond to Alpha or Beta depending upon what spin was passesd to 
B<$Glog-E<gt>analyze()>.

=item COMPILE

Architecture for which the employed version of Gaussian was compiled.

=item COMPILEDATE

Date when the employed version of Gaussian was compiled.

=item EELEC

Electronic energy for the theory level employed.

=item ESCF

Array of SCF energies. This will be either the Hartree-Fock or the DFT energy.

=item EIGEN

A rank two tensor containing the eigenvalues.  The eigenvalues correspond to Alpha or
Beta depending upon what spin was passesd to B<$Glog-E<gt>analyze()>.

=item ETHERM

Thermal corrections to energy.

=item EZPE

Current zero-point energy.

=item FUNCTIONAL

String containing the DFT functional utlized in this job.

=item GSOLV

Current Delta G of solvation.

=item GTHERM

Thermal corrections to G.

=item HOMO

Number corresponding to the highest occupied molecular orbital. The value corresponds
to either Alpha or Beta electrons depending upon what spin was passesd to
B<$Glog-E<gt>analyze()>.

=item HTHERM

Thermal corrections to H.

=item KEYWORDS

Array containing Gaussian keywords used in this job.

=item LINK0

Array containing the Gaussian Link0 commands. Only the value passed to the 
Link0 command is stored. This data will be accessible via a Link0 method in future 
releases. The contents of the array positions are as follows:

=back

=over 15

=over 5

=item 0

%nproc or %nprocshared

=item 1

%mem

=item 2

%chk

=item 3

%subst

=item 4

%nproclinda or %lindaworkers

=item 5

%save - stored as 1 if present, 0 otherwise

=item 6

%nosave - stored as 1 if present, 0 otherwise

=item 7 

%kjob

=item 8

%rwf

=item 9

%int

=item 10

%d2e

=back

=back

=over 15

=item MOSYMM

A rank two tensor containing the symmmetry labels for each molecular orbital.

=item NCARTESIAN

Current number of Cartesian basis functions.

=item NPRIMITIVE

Current number of primitive Guassians in the basis set.

=item OCC

Rank two tensor containing the molecular orbital occupations.

=item OPTIMIZED

Flag indicating successful optimization (1).  Defaults to 0.

=item PG

Array of molecular point group values.

=item REVISION

Gaussian revision label.

=item ROUTE

Gaussian route line

=item RUNTIME

Date when the calculation was run.

=item SADDLEPOINT

Current Saddle-point order.  Ground states are order 0 and transition states are order 1.

=item SSQUARED

Array of <S**2> expectation values.

=item VERSION

Gaussian version.

=back

=head1 METHODS

Method parameters denoted in [] are optional.

=over 15

=item B<$log-E<gt>new()>

Creates a new Glog object

=cut

## the object constructor **

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $log = Chemistry::ESPT::ESSfile->new();

	$log->{TYPE} = "log";

	# program info
	$log->{PROGRAM} = "Gaussian";
	$log->{VERSION} = undef;
	$log->{REVISION} = undef;
	$log->{COMPILE} = undef;
	$log->{COMPILEDATE} = undef;
	
	# Link 0 & Route commands
	$log->{LINK0} = [];
	$log->{KEYWORDS} = [];
	$log->{ROUTE} = undef;

	# calc info
	$log->{FUNCTIONAL} = undef;
	$log->{NPRIMITIVE} = undef;
	$log->{NCARTESIAN} = undef;
	$log->{OPTIMIZED} = undef;	# flag indicating successful optimization
	$log->{RUNTIME} = undef;
	
	# molecular info
	$log->{BASISLABELS} = [];
	$log->{C} = [];			# coefficient matrix
	$log->{EELEC} = undef;		# electronic energy for the current method
	$log->{ETHERM} = undef;		# Thermal corrections to E
	$log->{EIGEN} = [];
	$log->{EINFO} = "E(elec)";	# total energy description
	$log->{ESCF} = [];		# SCF electronic energy
	$log->{EZPE} = undef;		# ZPE
	$log->{GSOLV} = undef;		# Delta G of Solvation
	$log->{GTHERM} = undef;		# Thermal corrections to G
	$log->{HOMO} = undef;
	$log->{HTHERM} = undef;		# Thermal corrections to H
	$log->{MOSYMM} = [];
	$log->{SADDLEPOINT} = undef;	# Saddle-point Order
	$log->{OCC} =[];		# MO occupation info 
	$log->{PG} = [];
	$log->{SSQUARED} = [];		# S squared values

	bless($log, $class);
	return $log;
}


## methods ##

=item B<$log-E<gt>analyze(filename [spin])>

Analyze the spin results in file called filename.  Spin defaults to Alpha.

=cut

# set filename & spin then digest the file
sub analyze : method {
	my $log = shift;
	$log->prepare(@_);
	$log->_digest();
	return;
}


## subroutines ##
sub _digest {
# Files larger than 1Mb should be converted to binary and then
# processed to ensure maximum speed. -D. Ennis, OSC

# For items with multiple occurances, the last value is reported 

my $log = shift;

# flags & counters
my $Cflag = 0;
my $symmflag = 0;
my $rparsed = 0;
my $Sflag = 0;
my $Scount = 0;
my $Ccount = 0;
my $dcount = 0;
my $eigcount = 0;
my $Ecount = 0;
my $ESTATEcount = 0;
my $orbcount = -1;
my $MOcount = 0;
my $PGcount = 0;

# open filename for reading or display error
open(LOGFILE,$log->{FILENAME}) || die "Could not read $log->{FILENAME}\n$!\n";

# grab everything which may be useful
while (<LOGFILE>){
	# skip blank lines
	next if /^$/;

	# dashed line (signaling route, title, etc)
	if ( /^\s-{4,}$/ ) {
		++$dcount;
		next;
	}
	# parse route
	if ( $rparsed == 0 && $dcount >= 4 ){
		rparser($log);
		$rparsed = 1;
	}
        # version info
        if ( /^\s+Gaussian\s+([0-9DV]+):\s+([a-zA-Z0-9-]+)-G\1Rev([a-zA-Z]+\.[\d\+]+)\s+(\d{1,2}-[a-zA-Z]+-\d{4})\s*/ ) {
		$log->{VERSION} = $1;
              	$log->{REVISON} = $3;
               	$log->{COMPILE} = $2;
        	$log->{COMPILEDATE} = $4;
		next;
        }
        # run date
        if ( /^\s+(\d{1,2}-[a-zA-Z]+-\d{4})\s*/ ) {
        	$log->{RUNTIME} = $1;
		next;
	}
	# % commands
        if ( /^\s+\%nproc(?:shared)*=(\d+)/ ) {
		$log->{LINK0} [0] = $_;
		next;
	}
	if ( /^\s+\%mem=(\d+)/ ) { 
		$log->{LINK0} [1] = $1;
		next;
	}
	if ( /^\s+\%chk=(.+)/ ) { 
		$log->{LINK0} [2] = $1;
		next;
	}
	if ( /^\s+\%subst\s+(L.+)/ ) { 
		$log->{LINK0} [3] = $1;
		next;
	}
	if ( /^\s+\%(?:nproc)*linda(?:workers)*=(\d+)/ ) { 
		$log->{LINK0} [4] = $1;
		next;
	}
	if ( /^\s+\%save/ ) { 
		$log->{LINK0} [5] = 1;
		next;
	}
	if ( /^\s+\%nosave/ ) { 
		$log->{LINK0} [6] = 1;
		next;
	}
	if ( /^\s+\%kjob\s+(.+)/ ) { 
		$log->{LINK0} [7] = $1;
		next;
	}
	if ( /^\s+\%rwf=(.+)/ ) { 
		$log->{LINK0} [8] = $1;
		next;
	}
	if ( /^\s+\%int=(.+)/ ) { 
		$log->{LINK0} [9] = $1;
		next;
	}
	if ( /^\s+\%d2e=(.+)/ ) { 
		$log->{LINK0} [10] = $1;
		next;
	}
	# route card
	if ( /^\s(#\s*[\+\/a-zA-Z0-9\*=\(\-,\)\s]+)\Z/ ) {
		$log->{ROUTE} = lc($1);
		$log->{ROUTE}=~ s/\s+$//;
		next;
	}
	elsif ( /^\s([\+\/a-zA-Z0-9=\(\-,\)\s]+)\Z/ && $dcount == 3 ) {
		$log->{ROUTE} = $log->{ROUTE}.$1;
		$log->{ROUTE}=~ s/\s+$//;
		next;
	}
        # charge & multiplicity (multiple values and occurances)
        if ( /^\s+Charge\s+=\s+(-*\d+)\s+Multiplicity\s+=\s+(\d+)\s*/ ) {   
                $log->{CHARGE} = $1;
                $log->{MULTIPLICITY} = $2;
		next;
        }
        # full point group (multiple occurances)
        if ( /^\s+Full\s+point\s+group\s+([CDSIOT])([0-9DHISV\*]+)\s+.*/ ) {
		$log->{PG} [$PGcount] = "$1($2)";
		$PGcount++;
		next;
	}
        # basis functions (multiple occurances)
        if ( /^\s+(\d+)\s+basis functions,*\s+(\d+)\s+primitive gaussians,*\s*(\d+)*\s*(cartesian basis functions)*\s*/ ) {
		$log->{NBASIS} = $1;
                $log->{NPRIMITIVE} = $2;
		$log->{NCARTESIAN} = $3;
		next;
        }
        # electrons (multiple occurances)
	# figure HOMO & LUMO, alphas fill first
        if ( /^\s+(\d+)\s+alpha electrons\s+(\d+)\s+beta electrons/ ) {
                $log->{ALPHA} = $1;
                $log->{BETA} = $2;
		$log->{HOMO} = $log->{uc($log->{SPIN})};
		next;
        }
                                                                                                        
        # orbital symmetries (multiple occurances)
        if ( /^\s+Orbital (?i:S)ymmetries:\s*/ || /^\s+$log->{SPIN}\s+Orbitals:\s*/ ) {
		$symmflag = 1;
		$orbcount++;
		next;
	} 
        if ( $symmflag == 1 && /^\s+(\w*)\s+(?:\([123ABDEGHILMPSTU\?'"]{1,4}\)\s*){1,}$/ ) {
                (my $junk, my $tmp) = split /^\s+\w*/;
                $tmp =~ s/\s|\(//g;
                $tmp =~ tr/A-Z/a-z/;
                my @sym = split /\)/, $tmp;
		$orbcount++ if $orbcount == -1;  	# temporary hack
                for (my $i=0; $i<scalar(@sym); $i++) {
                        $log->{MOSYMM} [$orbcount] [$MOcount] = $sym[$i];
			$MOcount++;
                        $MOcount = $symmflag = 0 if ($MOcount == $log->{NBASIS} -1 && $log->{VERSION} eq "98");
                        $MOcount = $symmflag = 0 if $MOcount == $log->{NBASIS};
               }
                next;                                     
        }
	# SCF electronic energy (multiple occurances)
	if ( /^\s+SCF\s+Done:\s+.*\s+=\s+(-*\d+\.\d+)/ ) {
		$log->{ESCF} [$Ecount]= $1;
		$log->{EELEC} = $1;
		$log->{ENERGY} = $1;
		$Ecount++;
		next;
	}
	# <S^2> vlaue (multiple occurances)
	# generally not printed for closed shell theories
	if ( /^\s+.*?<*S\*\*2>*\s*=\s+(\d+\.\d+)/ ) {
		$log->{SSQUARED} [$Scount] = $1;
		$Scount++;
		next;
	}
	# Delta G of solvation (occurs each SCF cycle on SCRF jobs)
	if ( /^\s+DeltaG\s+\(solv\)\s+\(kcal\/mol\)\s+=\s+(-*\d+\.\d+)/ ) {
		$log->{GSOLV} = $1;
		next;
	}
	# Optimization completion
	if ( /^\s+Optimization\s+completed\./ ){
		$log->{OPTIMIZED} = 1;
		next;
	}
	# Electronic State (multiple occurances)
	if ( /^\s+The\s+electronic\s+state\s+is\s+(\d+-[123ABDEGHILMPSTU\?'"]{1,3})/ ) {
		$log->{ESTATE} [$ESTATEcount] = $1;
		$ESTATEcount++;
		next;
	}
        # eigenvalues
        if ( /^\s+$log->{SPIN}\s+([ocvirt]+\.)\s+eigenvalues\s+--\s+(?:-*\d+\.\d+\s*){1,}$/ ) {
		my $pop = $1;
                (my $junk,my $tmp) = split /^\s+$log->{SPIN}\s+\w+\.\s+eigenvalues\s+--\s+/;              
		$tmp =~ s/(\d)-(\d)/$1 -$2/;	# separate large negative eigenvalues 
		my @eig = split /\s+/, $tmp;
		$orbcount++ if $orbcount == -1;
                for (my $i=0; $i<scalar(@eig); $i++) {
                       	$log->{EIGEN} [$orbcount] [$eigcount] = $eig[$i];
			$log->{OCC} [$orbcount] [$eigcount] = $pop;
			$eigcount++;
                        $eigcount = 0 if ($eigcount == $log->{NBASIS}-1 && $log->{VERSION} eq "98");
                        $eigcount = 0 if $eigcount == $log->{NBASIS};
                }
		next;
        }
	# MO coeffients (square matrix, multiple occurances)
	if ( /\s+($log->{SPIN})*Molecular Orbital Coefficients/ ) {
		$Cflag = 1;
		$log->{C} = undef;
		next;
	}
	if ( $Cflag == 1 && /\s*(\d+)\s(\d+)\s*(\w+)\s+(\d+[A-Z]+\s?\-?\+?[0-9]*)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*/ ) {
		$log->{BASISLABELS}[$Ccount] = [$1, $2, $3, $4];
		push @{ $log->{C}[$Ccount] }, $5, $6, $7, $8, $9;
		$Ccount++;
		$Ccount = 0 if $Ccount == $log->{NBASIS};
		next;
	} elsif ( $Cflag == 1 && /\s*(\d+)\s*(\d+[A-Z]+\s?\-?\+?[0-9]*)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*(\-*\d+\.\d+)\s*/ ) {
              	$log->{BASISLABELS}[$Ccount] = [$1, $log->{BASISLABELS}[$Ccount - 1] [1], $log->{BASISLABELS}[$Ccount - 1] [2], $2];
		push @{ $log->{C}[$Ccount] }, $3, $4, $5, $6, $7;
               	$Ccount++;
               	$Ccount = 0 if $Ccount == $log->{NBASIS};
		next;
	}
	# density matrix
        if (/\s+DENSITY MATRIX./){
                $Cflag = 0;
		next;
        }
	# Saddle-point Order
	# appears only in freq runs that are not minima
	if ( /^\s+\*+\s+(\d+)\s+imaginary\sfrequencies\s\(negative\sSigns\)\s+\*+/ ){
		$log->{SADDLEPOINT} = $1;
		next;
	}
	# ZPE (frequency runs only)
	if ( /^\s+Zero-point\s+correction=\s+(-*\d*.\d+)/ ){
		$log->{EZPE} = $1;
		$log->{ENERGY} = $log->get("ESCF") + $log->{EZPE};
		$log->{EINFO} = "E(elec) + E(ZPE)";
		next;
	}
	# Thermal corrections to E (freq runs only)
	if ( /^\s+Thermal\scorrection\sto\sEnergy=\s+(\d\.\d+)/ ) {
		$log->{ETHERM} = $1;
		next;
	}
	# Thermal corrections to H (freq runs only)
	if ( /^\s+Thermal\scorrection\sto\sEnthalpy=\s+(\d\.\d+)/ ) {
		$log->{HTHERM} = $1;
		next;
	}
	# Thermal corrections to G (freq runs only)
	if ( /^\s+Thermal\scorrection\sto\sGibbs\sFree\sEnergy=\s+(\d\.\d+)/ ) {
		$log->{GTHERM} = $1;
		next;
	}
	# Successful Job completion
	if ( /^\s+Normal\s+termination\s+of\s+$log->{PROGRAM}/ ){
		$log->{COMPLETE} = 1;
		next;
	}
	# Calculation time stored as days, hours, minutes, seconds.
	# add code for tracking individual times.
	if ( /\s+Job\s+cpu\s+time:\s+(\d+)\s+days\s+(\d+)\s+hours\s+(\d+)\s+minutes\s+(\d+\.\d)\s+seconds/ ) {
		$log->{TIME} [0] = $1 + $log->{TIME} [0];
		$log->{TIME} [1] = $2 + $log->{TIME} [1];
		$log->{TIME} [2] = $3 + $log->{TIME} [2];
		$log->{TIME} [3] = $4 + $log->{TIME} [3];
		next;
	}
}

# Saddle-point Order for minima
if ( $log->get("JOBTYPE") =~ /FREQ/ && $log->{COMPLETE} == 1 ){
	$log->{SADDLEPOINT} = 0 unless defined $log->{SADDLEPOINT};
}

# C(1) symmetry label hack
if ( $log->{"PG"} eq "C(1)" ) {
	if ( $log->{VERSION} eq "98" ) {
		for (my $i=0; $i<$log->{NBASIS}-1; $i++) {
			$log->{MOSYMM} [0] [$i] = "a";
		}
	} else {
		for (my $i=0; $i<$log->{NBASIS}; $i++) {
			$log->{MOSYMM} [0] [$i] = "a";
		}
	}		
}
}

1;
__END__

=back

=head1 VERSION

0.07

=head1 SEE ALSO

L<Chemistry::ESPT::ESSfile>, L<Chemistry::ESPT::Glib>, L<http://www.gaussian.com>

=head1 AUTHOR

Dr. Jason L. Sonnenberg, E<lt>sonnenberg.11@osu.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Dr. by Jason L. Sonnenberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. I would like to hear of any
suggestions for improvement.

=cut

