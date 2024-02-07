package App::SeismicUnixGui::sunix::header::segyhdrs;

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
 SEGYHDRS - make SEG-Y ascii and binary headers for segywrite		



 segyhdrs [ < sudata ] [optional parameters] [ > copy of sudata ]      



 Required parameters:							

	ns=  if no input trace header					

	dt=  if no input trace header					

 Optional parameters:							

 	ns=tr.ns from header    number of samples on input traces	

 	dt=tr.dt from header	sample rate (microseconds) from traces	

 	bfile=binary		name of file containing binary block	

 	hfile=header		name of file containing ascii block	

   Some binary header fields are set:					

 	jobid=1			job id field				

 	lino=1			line number (only one line per reel)	

 	reno=1			reel number				

 	format=1		data format				



 All other fields are set to 0, by default.				

 To set any binary header field, use sukeyword to find out		

 the appropriate keyword, then use the getpar form:			

 	keyword=value	to set keyword to value				



 The header file is created as ascii and is translated to ebcdic	

 by segywrite before being written to tape.  Its contents are		

 formal but can be edited after creation as long as the forty		

 line format is maintained.						



 Caveat: This program has not been tested under XDR for machines       

	 not having a 2 byte unsigned short integral data type.	





 Credits:



	CWP: Jack K. Cohen,  John Stockwell 

      MOBIL: Stew Levin



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

my $segyhdrs			= {
	_bfile					=> '',
	_dt					=> '',
	_format					=> '',
	_hfile					=> '',
	_jobid					=> '',
	_keyword					=> '',
	_lino					=> '',
	_ns					=> '',
	_reno					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$segyhdrs->{_Step}     = 'segyhdrs'.$segyhdrs->{_Step};
	return ( $segyhdrs->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segyhdrs->{_note}     = 'segyhdrs'.$segyhdrs->{_note};
	return ( $segyhdrs->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segyhdrs->{_bfile}			= '';
		$segyhdrs->{_dt}			= '';
		$segyhdrs->{_format}			= '';
		$segyhdrs->{_hfile}			= '';
		$segyhdrs->{_jobid}			= '';
		$segyhdrs->{_keyword}			= '';
		$segyhdrs->{_lino}			= '';
		$segyhdrs->{_ns}			= '';
		$segyhdrs->{_reno}			= '';
		$segyhdrs->{_Step}			= '';
		$segyhdrs->{_note}			= '';
 }


=head2 sub bfile 


=cut

 sub bfile {

	my ( $self,$bfile )		= @_;
	if ( $bfile ne $empty_string ) {

		$segyhdrs->{_bfile}		= $bfile;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' bfile='.$segyhdrs->{_bfile};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' bfile='.$segyhdrs->{_bfile};

	} else { 
		print("segyhdrs, bfile, missing bfile,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$segyhdrs->{_dt}		= $dt;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' dt='.$segyhdrs->{_dt};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' dt='.$segyhdrs->{_dt};

	} else { 
		print("segyhdrs, dt, missing dt,\n");
	 }
 }


=head2 sub format 


=cut

 sub format {

	my ( $self,$format )		= @_;
	if ( $format ne $empty_string ) {

		$segyhdrs->{_format}		= $format;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' format='.$segyhdrs->{_format};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' format='.$segyhdrs->{_format};

	} else { 
		print("segyhdrs, format, missing format,\n");
	 }
 }


=head2 sub hfile 


=cut

 sub hfile {

	my ( $self,$hfile )		= @_;
	if ( $hfile ne $empty_string ) {

		$segyhdrs->{_hfile}		= $hfile;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' hfile='.$segyhdrs->{_hfile};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' hfile='.$segyhdrs->{_hfile};

	} else { 
		print("segyhdrs, hfile, missing hfile,\n");
	 }
 }


=head2 sub jobid 


=cut

 sub jobid {

	my ( $self,$jobid )		= @_;
	if ( $jobid ne $empty_string ) {

		$segyhdrs->{_jobid}		= $jobid;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' jobid='.$segyhdrs->{_jobid};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' jobid='.$segyhdrs->{_jobid};

	} else { 
		print("segyhdrs, jobid, missing jobid,\n");
	 }
 }


=head2 sub keyword 


=cut

 sub keyword {

	my ( $self,$keyword )		= @_;
	if ( $keyword ne $empty_string ) {

		$segyhdrs->{_keyword}		= $keyword;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' keyword='.$segyhdrs->{_keyword};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' keyword='.$segyhdrs->{_keyword};

	} else { 
		print("segyhdrs, keyword, missing keyword,\n");
	 }
 }


=head2 sub lino 


=cut

 sub lino {

	my ( $self,$lino )		= @_;
	if ( $lino ne $empty_string ) {

		$segyhdrs->{_lino}		= $lino;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' lino='.$segyhdrs->{_lino};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' lino='.$segyhdrs->{_lino};

	} else { 
		print("segyhdrs, lino, missing lino,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$segyhdrs->{_ns}		= $ns;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' ns='.$segyhdrs->{_ns};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' ns='.$segyhdrs->{_ns};

	} else { 
		print("segyhdrs, ns, missing ns,\n");
	 }
 }


=head2 sub reno 


=cut

 sub reno {

	my ( $self,$reno )		= @_;
	if ( $reno ne $empty_string ) {

		$segyhdrs->{_reno}		= $reno;
		$segyhdrs->{_note}		= $segyhdrs->{_note}.' reno='.$segyhdrs->{_reno};
		$segyhdrs->{_Step}		= $segyhdrs->{_Step}.' reno='.$segyhdrs->{_reno};

	} else { 
		print("segyhdrs, reno, missing reno,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
