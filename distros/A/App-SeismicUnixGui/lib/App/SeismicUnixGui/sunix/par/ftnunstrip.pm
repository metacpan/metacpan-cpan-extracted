package App::SeismicUnixGui::sunix::par::ftnunstrip;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 FTNUNSTRIP - convert C binary floats to Fortran style floats	



 ftnunstrip <stdin >stdout 					



 Required parameters:						

 	none							



 Optional parameters:						

 	n1=1		floats per line in output file 		



 	outpar=/dev/tty output parameter file, contains the	

			number of lines (n=)			

 			other choices for outpar are: /dev/tty,	

 			/dev/stderr, or a name of a disk file	



 Notes: This program assumes that the record length is constant

 throughout the input and output files. 			

 In fortran code reading these floats, the following implied	

 do loop syntax would be used: 				

        DO i=1,n2						

                 READ (10) (someARRAY(j), j=1,n1) 		

        END DO							

 Here n1 is the number of samples per record, n2 is the number 

 of records, 10 is some default file (fort.10, for example), and

 someArray(j) is an array dimensioned to size n1		





 Credits:

	CWP: John Stockwell, Feb 1998,

            based on ftnstrip by: Jack K. Cohen



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

my $ftnunstrip			= {
	_i					=> '',
	_j					=> '',
	_n					=> '',
	_n1					=> '',
	_outpar					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$ftnunstrip->{_Step}     = 'ftnunstrip'.$ftnunstrip->{_Step};
	return ( $ftnunstrip->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$ftnunstrip->{_note}     = 'ftnunstrip'.$ftnunstrip->{_note};
	return ( $ftnunstrip->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$ftnunstrip->{_i}			= '';
		$ftnunstrip->{_j}			= '';
		$ftnunstrip->{_n}			= '';
		$ftnunstrip->{_n1}			= '';
		$ftnunstrip->{_outpar}			= '';
		$ftnunstrip->{_Step}			= '';
		$ftnunstrip->{_note}			= '';
 }


=head2 sub i 


=cut

 sub i {

	my ( $self,$i )		= @_;
	if ( $i ne $empty_string ) {

		$ftnunstrip->{_i}		= $i;
		$ftnunstrip->{_note}		= $ftnunstrip->{_note}.' i='.$ftnunstrip->{_i};
		$ftnunstrip->{_Step}		= $ftnunstrip->{_Step}.' i='.$ftnunstrip->{_i};

	} else { 
		print("ftnunstrip, i, missing i,\n");
	 }
 }


=head2 sub j 


=cut

 sub j {

	my ( $self,$j )		= @_;
	if ( $j ne $empty_string ) {

		$ftnunstrip->{_j}		= $j;
		$ftnunstrip->{_note}		= $ftnunstrip->{_note}.' j='.$ftnunstrip->{_j};
		$ftnunstrip->{_Step}		= $ftnunstrip->{_Step}.' j='.$ftnunstrip->{_j};

	} else { 
		print("ftnunstrip, j, missing j,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$ftnunstrip->{_n}		= $n;
		$ftnunstrip->{_note}		= $ftnunstrip->{_note}.' n='.$ftnunstrip->{_n};
		$ftnunstrip->{_Step}		= $ftnunstrip->{_Step}.' n='.$ftnunstrip->{_n};

	} else { 
		print("ftnunstrip, n, missing n,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$ftnunstrip->{_n1}		= $n1;
		$ftnunstrip->{_note}		= $ftnunstrip->{_note}.' n1='.$ftnunstrip->{_n1};
		$ftnunstrip->{_Step}		= $ftnunstrip->{_Step}.' n1='.$ftnunstrip->{_n1};

	} else { 
		print("ftnunstrip, n1, missing n1,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$ftnunstrip->{_outpar}		= $outpar;
		$ftnunstrip->{_note}		= $ftnunstrip->{_note}.' outpar='.$ftnunstrip->{_outpar};
		$ftnunstrip->{_Step}		= $ftnunstrip->{_Step}.' outpar='.$ftnunstrip->{_outpar};

	} else { 
		print("ftnunstrip, outpar, missing outpar,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 4;

    return($max_index);
}
 
 
1;
