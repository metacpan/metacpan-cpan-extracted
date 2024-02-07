package App::SeismicUnixGui::sunix::shapeNcut::suflip;

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
 SUFLIP - flip a data set in various ways			



 suflip <data1 >data2 flip=1 verbose=0				



 Required parameters:						

 	none							



 Optional parameters:						

 	flip=1 	rotational sense of flip			

 			+1  = flip 90 deg clockwise		

 			-1  = flip 90 deg counter-clockwise	

 			 0  = transpose data			

 			 2  = flip right-to-left		

 			 3  = flip top-to-bottom		

 	tmpdir=	 if non-empty, use the value as a directory path

		 prefix for storing temporary files; else if	

	         the CWP_TMPDIR environment variable is set use	

	         its value for the path; else use tmpfile()	



 	verbose=0	verbose = 1 echoes flip info		



 NOTE:  tr.dt header field is lost if flip=-1,+1.  It can be	

        reset using sushw.					



 EXAMPLE PROCESSING SEQUENCES:					

   1.	suflip flip=-1 <data1 | sushw key=dt a=4000 >data2	



   2.	suflip flip=2 <data1 | suflip flip=2 >data1_again	



   3.	suflip tmpdir=/scratch <data1 | ...			



 Caveat:  may fail on large files.				



 Credits:

	CWP: Chris Liner, Jack K. Cohen, John Stockwell



 Caveat:

	right-left flip (flip = 2) and top-bottom flip (flip = 3)

	don't require the matrix approach.  We sacrificed efficiency

	for uniform coding.



 Trace header fields accessed: ns, dt

 Trace header fields modified: ns, dt, tracl



=head2 CHANGES and their DATES

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

my $suflip			= {
	_flip					=> '',
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

	$suflip->{_Step}     = 'suflip'.$suflip->{_Step};
	return ( $suflip->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suflip->{_note}     = 'suflip'.$suflip->{_note};
	return ( $suflip->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suflip->{_flip}			= '';
		$suflip->{_tmpdir}			= '';
		$suflip->{_verbose}			= '';
		$suflip->{_Step}			= '';
		$suflip->{_note}			= '';
 }



=head2 sub flip 


=cut

 sub flip {

	my ( $self,$flip )		= @_;
	if ( $flip ne $empty_string ) {

		$suflip->{_flip}		= $flip;
		$suflip->{_note}		= $suflip->{_note}.' flip='.$suflip->{_flip};
		$suflip->{_Step}		= $suflip->{_Step}.' flip='.$suflip->{_flip};

	} else { 
		print("suflip, flip, missing flip,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$suflip->{_tmpdir}		= $tmpdir;
		$suflip->{_note}		= $suflip->{_note}.' tmpdir='.$suflip->{_tmpdir};
		$suflip->{_Step}		= $suflip->{_Step}.' tmpdir='.$suflip->{_tmpdir};

	} else { 
		print("suflip, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suflip->{_verbose}		= $verbose;
		$suflip->{_note}		= $suflip->{_note}.' verbose='.$suflip->{_verbose};
		$suflip->{_Step}		= $suflip->{_Step}.' verbose='.$suflip->{_verbose};

	} else { 
		print("suflip, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 2;

    return($max_index);
}
 
 
1; 
