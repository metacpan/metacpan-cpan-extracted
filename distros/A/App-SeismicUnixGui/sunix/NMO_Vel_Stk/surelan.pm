package App::SeismicUnixGui::sunix::NMO_Vel_Stk::surelan;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SURELAN - compute residual-moveout semblance for cdp gathers based	

	on z(h)*z(h) = z(0)*z(0) + r*h*h where z depth and h offset.	



 surelan <stdin >stdout   [optional parameters]			



 Optional Parameters:							

 nr=51			number of r-parameter samples   		

 dr=0.01               r-parameter sampling interval			

 fr=-0.25               first value of b-parameter			

 smute=1.5             samples with RMO stretch exceeding smute are zeroed

 dzratio=5             ratio of output to input depth sampling intervals

 nsmooth=dzratio*2+1   length of semblance num and den smoothing window

 verbose=0             =1 for diagnostic print on stderr		



 Note: 								

 1. This program is part of Zhenyue Liu's velocity analysis technique.	

 2. Input migrated traces should be sorted by cdp - surelan outputs a 	

    group of semblance traces every time cdp changes.  Therefore, the  

    output will be useful only if cdp gathers are input.  		

 3. The parameter r may take negative values. The range of r can be 	

     controlled by maximum of (z(h)*z(h)-z(0)*z(0))/(h*h)   		

=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $surelan			= {
	_dr					=> '',
	_dzratio					=> '',
	_fr					=> '',
	_nr					=> '',
	_nsmooth					=> '',
	_smute					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$surelan->{_Step}     = 'surelan'.$surelan->{_Step};
	return ( $surelan->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$surelan->{_note}     = 'surelan'.$surelan->{_note};
	return ( $surelan->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$surelan->{_dr}			= '';
		$surelan->{_dzratio}			= '';
		$surelan->{_fr}			= '';
		$surelan->{_nr}			= '';
		$surelan->{_nsmooth}			= '';
		$surelan->{_smute}			= '';
		$surelan->{_verbose}			= '';
		$surelan->{_Step}			= '';
		$surelan->{_note}			= '';
 }


=head2 sub dr 


=cut

 sub dr {

	my ( $self,$dr )		= @_;
	if ( $dr ne $empty_string ) {

		$surelan->{_dr}		= $dr;
		$surelan->{_note}		= $surelan->{_note}.' dr='.$surelan->{_dr};
		$surelan->{_Step}		= $surelan->{_Step}.' dr='.$surelan->{_dr};

	} else { 
		print("surelan, dr, missing dr,\n");
	 }
 }


=head2 sub dzratio 


=cut

 sub dzratio {

	my ( $self,$dzratio )		= @_;
	if ( $dzratio ne $empty_string ) {

		$surelan->{_dzratio}		= $dzratio;
		$surelan->{_note}		= $surelan->{_note}.' dzratio='.$surelan->{_dzratio};
		$surelan->{_Step}		= $surelan->{_Step}.' dzratio='.$surelan->{_dzratio};

	} else { 
		print("surelan, dzratio, missing dzratio,\n");
	 }
 }


=head2 sub fr 


=cut

 sub fr {

	my ( $self,$fr )		= @_;
	if ( $fr ne $empty_string ) {

		$surelan->{_fr}		= $fr;
		$surelan->{_note}		= $surelan->{_note}.' fr='.$surelan->{_fr};
		$surelan->{_Step}		= $surelan->{_Step}.' fr='.$surelan->{_fr};

	} else { 
		print("surelan, fr, missing fr,\n");
	 }
 }


=head2 sub nr 


=cut

 sub nr {

	my ( $self,$nr )		= @_;
	if ( $nr ne $empty_string ) {

		$surelan->{_nr}		= $nr;
		$surelan->{_note}		= $surelan->{_note}.' nr='.$surelan->{_nr};
		$surelan->{_Step}		= $surelan->{_Step}.' nr='.$surelan->{_nr};

	} else { 
		print("surelan, nr, missing nr,\n");
	 }
 }


=head2 sub nsmooth 


=cut

 sub nsmooth {

	my ( $self,$nsmooth )		= @_;
	if ( $nsmooth ne $empty_string ) {

		$surelan->{_nsmooth}		= $nsmooth;
		$surelan->{_note}		= $surelan->{_note}.' nsmooth='.$surelan->{_nsmooth};
		$surelan->{_Step}		= $surelan->{_Step}.' nsmooth='.$surelan->{_nsmooth};

	} else { 
		print("surelan, nsmooth, missing nsmooth,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$surelan->{_smute}		= $smute;
		$surelan->{_note}		= $surelan->{_note}.' smute='.$surelan->{_smute};
		$surelan->{_Step}		= $surelan->{_Step}.' smute='.$surelan->{_smute};

	} else { 
		print("surelan, smute, missing smute,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$surelan->{_verbose}		= $verbose;
		$surelan->{_note}		= $surelan->{_note}.' verbose='.$surelan->{_verbose};
		$surelan->{_Step}		= $surelan->{_Step}.' verbose='.$surelan->{_verbose};

	} else { 
		print("surelan, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
