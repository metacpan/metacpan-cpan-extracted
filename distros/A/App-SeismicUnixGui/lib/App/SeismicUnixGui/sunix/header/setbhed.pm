package App::SeismicUnixGui::sunix::header::setbhed;

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
 SETBHED - SET the fields in a SEGY Binary tape HEaDer file, as would be

 	    produced by segyread and segyhdrs				

 setbhed par= [optional parameters]					


 Required parameter:							

 	none								

 Optional parameters:							

	bfile=binary		output binary tape header file		

	par=			=parfile				

 Set field by field, if desired:					

 	jobid=			job id field				

 	lino=			line number (only one line per reel)	

 	reno=			reel number				

 	format=			data format				

 ... etc....								

 To set any binary header field, use sukeyword to find out		

 the appropriate keyword, then use the getpar form:			

 	keyword=value	to set keyword to value				

 Notes:								

 As with all other programs in the CWP/SU package that use getpars, 	

 (GET PARameters from the command line) a file filled with such	

 statments may be included via option par=parfile. In particular, a	

 parfile created by   "bhedtopar"  may be used as input for the program

 "setbhed".								



 The binary header file that results from running segyread may have the

 wrong byte order. You will need to use "swapbhed" to change the byte,"

 order before applying this program. 					



 Example:								

   segyread tape=yourdata.segy bfile=yourdata.b > yourdata.su		

 If  									

   bhedtopar < yourdata.b | more 					

 shows impossible values, then apply 					

   swapbhed < yourdata.b > swapped.b					

 then apply 								

   bhedtopar < swapped.b | more 					

   bhedtopar < swapped.b outpar=parfile				

 hand edit parfile, and then apply 					

  setbhed par=parfile bfile=swapped.b > new.b				

 then apply 								

   segywrite tape=fixeddata.segy bfile=new.b < yourdata.su		



 Caveat: This program breaks if a "short" isn't 2 bytes since	

         the SEG-Y standard demands a 2 byte integer for ns.		



 Credits:



	CWP: John Stockwell  11 Nov 1994
	
=head2 User's notes

V0.0.1 -untested



=head2 CHANGES and their DATES

September 3, 2021

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $setbhed			= {
	_bfile					=> '',
	_format					=> '',
	_jobid					=> '',
	_keyword					=> '',
	_lino					=> '',
	_outpar					=> '',
	_par					=> '',
	_reno					=> '',
	_tape					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$setbhed->{_Step}     = 'setbhed'.$setbhed->{_Step};
	return ( $setbhed->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$setbhed->{_note}     = 'setbhed'.$setbhed->{_note};
	return ( $setbhed->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$setbhed->{_bfile}			= '';
		$setbhed->{_format}			= '';
		$setbhed->{_jobid}			= '';
		$setbhed->{_keyword}			= '';
		$setbhed->{_lino}			= '';
		$setbhed->{_outpar}			= '';
		$setbhed->{_par}			= '';
		$setbhed->{_reno}			= '';
		$setbhed->{_tape}			= '';
		$setbhed->{_Step}			= '';
		$setbhed->{_note}			= '';
 }


=head2 sub bfile 


=cut

 sub bfile {

	my ( $self,$bfile )		= @_;
	if ( $bfile ne $empty_string ) {

		$setbhed->{_bfile}		= $bfile;
		$setbhed->{_note}		= $setbhed->{_note}.' bfile='.$setbhed->{_bfile};
		$setbhed->{_Step}		= $setbhed->{_Step}.' bfile='.$setbhed->{_bfile};

	} else { 
		print("setbhed, bfile, missing bfile,\n");
	 }
 }


=head2 sub format 


=cut

 sub format {

	my ( $self,$format )		= @_;
	if ( $format ne $empty_string ) {

		$setbhed->{_format}		= $format;
		$setbhed->{_note}		= $setbhed->{_note}.' format='.$setbhed->{_format};
		$setbhed->{_Step}		= $setbhed->{_Step}.' format='.$setbhed->{_format};

	} else { 
		print("setbhed, format, missing format,\n");
	 }
 }


=head2 sub jobid 


=cut

 sub jobid {

	my ( $self,$jobid )		= @_;
	if ( $jobid ne $empty_string ) {

		$setbhed->{_jobid}		= $jobid;
		$setbhed->{_note}		= $setbhed->{_note}.' jobid='.$setbhed->{_jobid};
		$setbhed->{_Step}		= $setbhed->{_Step}.' jobid='.$setbhed->{_jobid};

	} else { 
		print("setbhed, jobid, missing jobid,\n");
	 }
 }


=head2 sub keyword 


=cut

 sub keyword {

	my ( $self,$keyword )		= @_;
	if ( $keyword ne $empty_string ) {

		$setbhed->{_keyword}		= $keyword;
		$setbhed->{_note}		= $setbhed->{_note}.' keyword='.$setbhed->{_keyword};
		$setbhed->{_Step}		= $setbhed->{_Step}.' keyword='.$setbhed->{_keyword};

	} else { 
		print("setbhed, keyword, missing keyword,\n");
	 }
 }


=head2 sub lino 


=cut

 sub lino {

	my ( $self,$lino )		= @_;
	if ( $lino ne $empty_string ) {

		$setbhed->{_lino}		= $lino;
		$setbhed->{_note}		= $setbhed->{_note}.' lino='.$setbhed->{_lino};
		$setbhed->{_Step}		= $setbhed->{_Step}.' lino='.$setbhed->{_lino};

	} else { 
		print("setbhed, lino, missing lino,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$setbhed->{_outpar}		= $outpar;
		$setbhed->{_note}		= $setbhed->{_note}.' outpar='.$setbhed->{_outpar};
		$setbhed->{_Step}		= $setbhed->{_Step}.' outpar='.$setbhed->{_outpar};

	} else { 
		print("setbhed, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$setbhed->{_par}		= $par;
		$setbhed->{_note}		= $setbhed->{_note}.' par='.$setbhed->{_par};
		$setbhed->{_Step}		= $setbhed->{_Step}.' par='.$setbhed->{_par};

	} else { 
		print("setbhed, par, missing par,\n");
	 }
 }


=head2 sub reno 


=cut

 sub reno {

	my ( $self,$reno )		= @_;
	if ( $reno ne $empty_string ) {

		$setbhed->{_reno}		= $reno;
		$setbhed->{_note}		= $setbhed->{_note}.' reno='.$setbhed->{_reno};
		$setbhed->{_Step}		= $setbhed->{_Step}.' reno='.$setbhed->{_reno};

	} else { 
		print("setbhed, reno, missing reno,\n");
	 }
 }


=head2 sub tape 


=cut

 sub tape {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

		$setbhed->{_tape}		= $tape;
		$setbhed->{_note}		= $setbhed->{_note}.' tape='.$setbhed->{_tape};
		$setbhed->{_Step}		= $setbhed->{_Step}.' tape='.$setbhed->{_tape};

	} else { 
		print("setbhed, tape, missing tape,\n");
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
