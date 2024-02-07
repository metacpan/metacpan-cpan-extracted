package App::SeismicUnixGui::sunix::header::sustatic;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUSTATIC - Elevation static corrections, apply corrections from	

	      headers or from a source and receiver statics file	



     sustatic <stdin >stdout  [optional parameters]	 		



 Required parameters:							

	none								

 Optional Parameters:							

	v0=v1 or user-defined	or from header, weathering velocity	

	v1=user-defined		or from header, subweathering velocity	

	hdrs=0		=1 to read statics from headers		

 				=2 to read statics from files		

				=3 to read from output files of suresstat

	sign=1			apply static correction (add tstat values)

				=-1 apply negative of tstat values	

 Options when hdrs=2 and hdrs=3:					

	sou_file=		input file for source statics (ms) 	

	rec_file=		input file for receiver statics (ms) 	

	ns=240 			number of souces 			

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

 that ns=max shot number and nr=max receiver number).			

 For each shot number (trace header fldr) and each receiver number     

 (trace header tracf) the program will look up the appropriate static  

 correction.  The geometry need not be regular as each trace is treated

 independently.							



 Caveat:  The static shifts are computed with the assumption that the  

 desired datum is sea level (elevation=0). You may need to shift the	

 selev and gelev header values via  suchw.				

 Example: subtracting min(selev,gelev)=25094431			



 suchw < CR290.su key1->selev,gelev key2 -> elev,gelev key3 -> selev,gelev \\ 

            a->-25094431,-25094431 b->1,1 c->0,0 > CR290datum.su		



 Credits:

	CWP: Jamie Burns



	CWP: Modified by Mohammed Alfaraj, 11/10/1992, for reading

	     statics from headers and including sign (+-) option



      CWP: Modified by Timo Tjan, 29 June 1995, to include input of

           source and receiver statics from files. 



	modified by Thomas Pratt, USGS, Feb, 2000 to read statics from

 	     the output files of suresstat



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

my $sustatic			= {
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

	$sustatic->{_Step}     = 'sustatic'.$sustatic->{_Step};
	return ( $sustatic->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sustatic->{_note}     = 'sustatic'.$sustatic->{_note};
	return ( $sustatic->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sustatic->{_elevation}			= '';
		$sustatic->{_hdrs}			= '';
		$sustatic->{_no}			= '';
		$sustatic->{_nr}			= '';
		$sustatic->{_ns}			= '';
		$sustatic->{_rec_file}			= '';
		$sustatic->{_sign}			= '';
		$sustatic->{_sou_file}			= '';
		$sustatic->{_v0}			= '';
		$sustatic->{_v1}			= '';
		$sustatic->{_Step}			= '';
		$sustatic->{_note}			= '';
 }


=head2 sub elevation 


=cut

 sub elevation {

	my ( $self,$elevation )		= @_;
	if ( $elevation ne $empty_string ) {

		$sustatic->{_elevation}		= $elevation;
		$sustatic->{_note}		= $sustatic->{_note}.' elevation='.$sustatic->{_elevation};
		$sustatic->{_Step}		= $sustatic->{_Step}.' elevation='.$sustatic->{_elevation};

	} else { 
		print("sustatic, elevation, missing elevation,\n");
	 }
 }


=head2 sub hdrs 


=cut

 sub hdrs {

	my ( $self,$hdrs )		= @_;
	if ( $hdrs ne $empty_string ) {

		$sustatic->{_hdrs}		= $hdrs;
		$sustatic->{_note}		= $sustatic->{_note}.' hdrs='.$sustatic->{_hdrs};
		$sustatic->{_Step}		= $sustatic->{_Step}.' hdrs='.$sustatic->{_hdrs};

	} else { 
		print("sustatic, hdrs, missing hdrs,\n");
	 }
 }


=head2 sub no 


=cut

 sub no {

	my ( $self,$no )		= @_;
	if ( $no ne $empty_string ) {

		$sustatic->{_no}		= $no;
		$sustatic->{_note}		= $sustatic->{_note}.' no='.$sustatic->{_no};
		$sustatic->{_Step}		= $sustatic->{_Step}.' no='.$sustatic->{_no};

	} else { 
		print("sustatic, no, missing no,\n");
	 }
 }


=head2 sub nr 


=cut

 sub nr {

	my ( $self,$nr )		= @_;
	if ( $nr ne $empty_string ) {

		$sustatic->{_nr}		= $nr;
		$sustatic->{_note}		= $sustatic->{_note}.' nr='.$sustatic->{_nr};
		$sustatic->{_Step}		= $sustatic->{_Step}.' nr='.$sustatic->{_nr};

	} else { 
		print("sustatic, nr, missing nr,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$sustatic->{_ns}		= $ns;
		$sustatic->{_note}		= $sustatic->{_note}.' ns='.$sustatic->{_ns};
		$sustatic->{_Step}		= $sustatic->{_Step}.' ns='.$sustatic->{_ns};

	} else { 
		print("sustatic, ns, missing ns,\n");
	 }
 }


=head2 sub rec_file 


=cut

 sub rec_file {

	my ( $self,$rec_file )		= @_;
	if ( $rec_file ne $empty_string ) {

		$sustatic->{_rec_file}		= $rec_file;
		$sustatic->{_note}		= $sustatic->{_note}.' rec_file='.$sustatic->{_rec_file};
		$sustatic->{_Step}		= $sustatic->{_Step}.' rec_file='.$sustatic->{_rec_file};

	} else { 
		print("sustatic, rec_file, missing rec_file,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sustatic->{_sign}		= $sign;
		$sustatic->{_note}		= $sustatic->{_note}.' sign='.$sustatic->{_sign};
		$sustatic->{_Step}		= $sustatic->{_Step}.' sign='.$sustatic->{_sign};

	} else { 
		print("sustatic, sign, missing sign,\n");
	 }
 }


=head2 sub sou_file 


=cut

 sub sou_file {

	my ( $self,$sou_file )		= @_;
	if ( $sou_file ne $empty_string ) {

		$sustatic->{_sou_file}		= $sou_file;
		$sustatic->{_note}		= $sustatic->{_note}.' sou_file='.$sustatic->{_sou_file};
		$sustatic->{_Step}		= $sustatic->{_Step}.' sou_file='.$sustatic->{_sou_file};

	} else { 
		print("sustatic, sou_file, missing sou_file,\n");
	 }
 }


=head2 sub v0 


=cut

 sub v0 {

	my ( $self,$v0 )		= @_;
	if ( $v0 ne $empty_string ) {

		$sustatic->{_v0}		= $v0;
		$sustatic->{_note}		= $sustatic->{_note}.' v0='.$sustatic->{_v0};
		$sustatic->{_Step}		= $sustatic->{_Step}.' v0='.$sustatic->{_v0};

	} else { 
		print("sustatic, v0, missing v0,\n");
	 }
 }


=head2 sub v1 


=cut

 sub v1 {

	my ( $self,$v1 )		= @_;
	if ( $v1 ne $empty_string ) {

		$sustatic->{_v1}		= $v1;
		$sustatic->{_note}		= $sustatic->{_note}.' v1='.$sustatic->{_v1};
		$sustatic->{_Step}		= $sustatic->{_Step}.' v1='.$sustatic->{_v1};

	} else { 
		print("sustatic, v1, missing v1,\n");
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
