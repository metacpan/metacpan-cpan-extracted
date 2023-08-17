package App::SeismicUnixGui::sunix::header::sustaticB;

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
 SUSTATICB - Elevation static corrections, apply corrections from	

	      headers or from a source and receiver statics file	

	      (beta submitted by J. W. Neese)				



     sustaticB <stdin >stdout  [optional parameters]	 		



 Required parameters:							

	none								

 Optional Parameters:							

	v0=v1 or user-defined	or from header, weathering velocity	

	v1=user-defined		or from header, subweathering velocity	

	hdrs=0			=1 to read statics from headers		

 				=2 to read statics from files		

				=3 to read from output files of suresstat

	sign=1			apply static correction (add tstat values)

				=-1 apply negative of tstat values	

 Options when hdrs=2 and hdrs=3:					

	sou_file=		input file for source statics (ms) 	

	rec_file=		input file for receiver statics (ms) 	

	ns=240 		(2)number of sources; (3) max fldr	

	nr=335 			number of receivers 			

	no=96 			number of offsets			



 Notes:								

 For hdrs=1, statics calculation is not performed, statics correction  

 is applied to the data by reading statics (in ms) from the header.	



 For hdrs=0, field statics are calculated, and				

 	input field sut is assumed measured in ms.			

 	output field sstat equals 10^scalel*(sdel - selev + sdepth)/swevel	

 	output field gstat equals sstat - sut/1000.				

 	output field tstat equals sstat + gstat + 10^scalel*(selev - gelev)/wevel



 For hdrs=2, statics are surface consistently obtained from the 	

 statics files. The geometry should be regular.			

 The source- and receiver-statics files should be unformated C binary 	

 floats and contain the statics (in ms) as a function of surface location.



 For hdrs=3, statics are read from the output files of suresstat, with 

 the same options as hdrs=2 (but use no=max traces per shot and assume 

 that ns=max fldr number and nr=max receiver number).			

 For each shot number (trace header fldr) and each receiver number     

 (trace header tracf) the program will look up the appropriate static  

 correction.  The geometry need not be regular as each trace is treated

 independently.							



 Caveat:  The static shifts are computed with the assumption that the  

 desired datum is sea level (elevation=0). You may need to shift the	

 selev and gelev header values via  suchw.				

 Example: subtracting min(selev,gelev)=25094431			



 suchw < CR290.su key1->:selev,gelev key2->:selev,gelev key3->:selev,gelev \\ 

            a->:-25094431,-25094431 b->:1,1 c->:0,0 > CR290datum.su		



 Credits:

	CWP: Jamie Burns



	CWP: Modified by Mohammed Alfaraj, 11/10/1992, for reading

	     statics from headers and including sign (+-) option



      CWP: Modified by Timo Tjan, 29 June 1995, to include input of

           source and receiver statics from files. 



	modified by Thomas Pratt, USGS, Feb, 2000 to read statics from

 	     the output files of suresstat



 Logic changed by JWN to fix options hdrs=2,3 ???



 Trace header fields accessed:  ns, dt, delrt, gelev, selev,

	sdepth, gdel, sdel, swevel, sut, scalel, fldr, tracf

 Trace header fields modified:  sstat, gstat, tstat





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

my $sustaticB			= {
	_elevation					=> '',
	_hdrs					=> '',
	_no					=> '',
	_nr					=> '',
	_ns					=> '',
	_rec_file					=> '',
	_sign					=> '',
	_sou_file					=> '',
	_v0					=> '',
	_v1					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sustaticB->{_Step}     = 'sustaticB'.$sustaticB->{_Step};
	return ( $sustaticB->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sustaticB->{_note}     = 'sustaticB'.$sustaticB->{_note};
	return ( $sustaticB->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sustaticB->{_elevation}			= '';
		$sustaticB->{_hdrs}			= '';
		$sustaticB->{_no}			= '';
		$sustaticB->{_nr}			= '';
		$sustaticB->{_ns}			= '';
		$sustaticB->{_rec_file}			= '';
		$sustaticB->{_sign}			= '';
		$sustaticB->{_sou_file}			= '';
		$sustaticB->{_v0}			= '';
		$sustaticB->{_v1}			= '';
		$sustaticB->{_Step}			= '';
		$sustaticB->{_note}			= '';
 }


=head2 sub elevation 


=cut

 sub elevation {

	my ( $self,$elevation )		= @_;
	if ( $elevation ne $empty_string ) {

		$sustaticB->{_elevation}		= $elevation;
		$sustaticB->{_note}		= $sustaticB->{_note}.' elevation='.$sustaticB->{_elevation};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' elevation='.$sustaticB->{_elevation};

	} else { 
		print("sustaticB, elevation, missing elevation,\n");
	 }
 }


=head2 sub hdrs 


=cut

 sub hdrs {

	my ( $self,$hdrs )		= @_;
	if ( $hdrs ne $empty_string ) {

		$sustaticB->{_hdrs}		= $hdrs;
		$sustaticB->{_note}		= $sustaticB->{_note}.' hdrs='.$sustaticB->{_hdrs};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' hdrs='.$sustaticB->{_hdrs};

	} else { 
		print("sustaticB, hdrs, missing hdrs,\n");
	 }
 }


=head2 sub no 


=cut

 sub no {

	my ( $self,$no )		= @_;
	if ( $no ne $empty_string ) {

		$sustaticB->{_no}		= $no;
		$sustaticB->{_note}		= $sustaticB->{_note}.' no='.$sustaticB->{_no};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' no='.$sustaticB->{_no};

	} else { 
		print("sustaticB, no, missing no,\n");
	 }
 }


=head2 sub nr 


=cut

 sub nr {

	my ( $self,$nr )		= @_;
	if ( $nr ne $empty_string ) {

		$sustaticB->{_nr}		= $nr;
		$sustaticB->{_note}		= $sustaticB->{_note}.' nr='.$sustaticB->{_nr};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' nr='.$sustaticB->{_nr};

	} else { 
		print("sustaticB, nr, missing nr,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$sustaticB->{_ns}		= $ns;
		$sustaticB->{_note}		= $sustaticB->{_note}.' ns='.$sustaticB->{_ns};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' ns='.$sustaticB->{_ns};

	} else { 
		print("sustaticB, ns, missing ns,\n");
	 }
 }


=head2 sub rec_file 


=cut

 sub rec_file {

	my ( $self,$rec_file )		= @_;
	if ( $rec_file ne $empty_string ) {

		$sustaticB->{_rec_file}		= $rec_file;
		$sustaticB->{_note}		= $sustaticB->{_note}.' rec_file='.$sustaticB->{_rec_file};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' rec_file='.$sustaticB->{_rec_file};

	} else { 
		print("sustaticB, rec_file, missing rec_file,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sustaticB->{_sign}		= $sign;
		$sustaticB->{_note}		= $sustaticB->{_note}.' sign='.$sustaticB->{_sign};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' sign='.$sustaticB->{_sign};

	} else { 
		print("sustaticB, sign, missing sign,\n");
	 }
 }


=head2 sub sou_file 


=cut

 sub sou_file {

	my ( $self,$sou_file )		= @_;
	if ( $sou_file ne $empty_string ) {

		$sustaticB->{_sou_file}		= $sou_file;
		$sustaticB->{_note}		= $sustaticB->{_note}.' sou_file='.$sustaticB->{_sou_file};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' sou_file='.$sustaticB->{_sou_file};

	} else { 
		print("sustaticB, sou_file, missing sou_file,\n");
	 }
 }


=head2 sub v0 


=cut

 sub v0 {

	my ( $self,$v0 )		= @_;
	if ( $v0 ne $empty_string ) {

		$sustaticB->{_v0}		= $v0;
		$sustaticB->{_note}		= $sustaticB->{_note}.' v0='.$sustaticB->{_v0};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' v0='.$sustaticB->{_v0};

	} else { 
		print("sustaticB, v0, missing v0,\n");
	 }
 }


=head2 sub v1 


=cut

 sub v1 {

	my ( $self,$v1 )		= @_;
	if ( $v1 ne $empty_string ) {

		$sustaticB->{_v1}		= $v1;
		$sustaticB->{_note}		= $sustaticB->{_note}.' v1='.$sustaticB->{_v1};
		$sustaticB->{_Step}		= $sustaticB->{_Step}.' v1='.$sustaticB->{_v1};

	} else { 
		print("sustaticB, v1, missing v1,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 9;

    return($max_index);
}
 
 
1;
