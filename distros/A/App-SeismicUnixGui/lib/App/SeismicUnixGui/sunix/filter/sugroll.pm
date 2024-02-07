package App::SeismicUnixGui::sunix::filter::sugroll;

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
 SUGROLL - Ground roll supression using Karhunen-Loeve transform	



    sugroll <infile >outfile  [optional parameters]                 	



 Optional Parameters:                                                  

 dt=tr.dt (from header) 	time sampling interval (secs)           

 nx=ntr   (counted from data)	number of horizontal samples (traces)	

 sb=0      1 for the graund-roll                                       

 verbose=0	verbose = 1 echoes information			

 nrot=3        the principal components for the m largest eigenvalues 

 tmpdir= 	 if non-empty, use the value as a directory path

		 prefix for storing temporary files; else if the

	         the CWP_TMPDIR environment variable is set use	

	         its value for the path; else use tmpfile()	



 Notes:                                                                

 The method developed here is to extract the ground-roll from the	

 common-shot gathers using Karhunen-Loeve transform, and then to substract  

 it from the original data. The advantage is the ground-roll is suppresed  

 with negligible distortion of the signal.	







 Credits: BRGM: Adnand Bitri, 1999.



 Reference:       

    Xuewei Liu, F., 1999, Ground roll supresion using the Karhunen-Loeve transform 

         Geophysics vol. 64 No. 2 pp 564-566



 Trace header fields accessed: ns, dt

 Trace header fields modified: dt



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

my $sugroll			= {
	_dt					=> '',
	_nrot					=> '',
	_nx					=> '',
	_sb					=> '',
	_tmpdir					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sugroll->{_Step}     = 'sugroll'.$sugroll->{_Step};
	return ( $sugroll->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sugroll->{_note}     = 'sugroll'.$sugroll->{_note};
	return ( $sugroll->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sugroll->{_dt}			= '';
		$sugroll->{_nrot}			= '';
		$sugroll->{_nx}			= '';
		$sugroll->{_sb}			= '';
		$sugroll->{_tmpdir}			= '';
		$sugroll->{_verbose}			= '';
		$sugroll->{_Step}			= '';
		$sugroll->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sugroll->{_dt}		= $dt;
		$sugroll->{_note}		= $sugroll->{_note}.' dt='.$sugroll->{_dt};
		$sugroll->{_Step}		= $sugroll->{_Step}.' dt='.$sugroll->{_dt};

	} else { 
		print("sugroll, dt, missing dt,\n");
	 }
 }


=head2 sub nrot 


=cut

 sub nrot {

	my ( $self,$nrot )		= @_;
	if ( $nrot ne $empty_string ) {

		$sugroll->{_nrot}		= $nrot;
		$sugroll->{_note}		= $sugroll->{_note}.' nrot='.$sugroll->{_nrot};
		$sugroll->{_Step}		= $sugroll->{_Step}.' nrot='.$sugroll->{_nrot};

	} else { 
		print("sugroll, nrot, missing nrot,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$sugroll->{_nx}		= $nx;
		$sugroll->{_note}		= $sugroll->{_note}.' nx='.$sugroll->{_nx};
		$sugroll->{_Step}		= $sugroll->{_Step}.' nx='.$sugroll->{_nx};

	} else { 
		print("sugroll, nx, missing nx,\n");
	 }
 }


=head2 sub sb 


=cut

 sub sb {

	my ( $self,$sb )		= @_;
	if ( $sb ne $empty_string ) {

		$sugroll->{_sb}		= $sb;
		$sugroll->{_note}		= $sugroll->{_note}.' sb='.$sugroll->{_sb};
		$sugroll->{_Step}		= $sugroll->{_Step}.' sb='.$sugroll->{_sb};

	} else { 
		print("sugroll, sb, missing sb,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sugroll->{_tmpdir}		= $tmpdir;
		$sugroll->{_note}		= $sugroll->{_note}.' tmpdir='.$sugroll->{_tmpdir};
		$sugroll->{_Step}		= $sugroll->{_Step}.' tmpdir='.$sugroll->{_tmpdir};

	} else { 
		print("sugroll, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sugroll->{_verbose}		= $verbose;
		$sugroll->{_note}		= $sugroll->{_note}.' verbose='.$sugroll->{_verbose};
		$sugroll->{_Step}		= $sugroll->{_Step}.' verbose='.$sugroll->{_verbose};

	} else { 
		print("sugroll, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
