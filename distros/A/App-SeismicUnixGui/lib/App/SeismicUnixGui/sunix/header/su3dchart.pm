package App::SeismicUnixGui::sunix::header::su3dchart;

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
 SU3DCHART - plot x-midpoints vs. y-midpoints for 3-D data	



 su3dchart <stdin >stdout					



 Optional parameters:						

 outpar=null	name of parameter file				

 degree=0	=1 convert seconds of arc to degrees		



 The output is the (x, y) pairs of binary floats		



 Example:							

 su3dchart <segy_data outpar=pfile >plot_data			

 psgraph <plot_data par=pfile \\				

	linewidth=0 marksize=2 mark=8 | ...			

 rm plot_data 							



 su3dchart <segy_data | psgraph n=1024 d1=.004 \\		

	linewidth=0 marksize=2 mark=8 | ...			



 Note:  sx, etc., are declared double because float has only 7

 significant numbers, that's not enough, for example,    

 when tr.scalco=100 and coordinates are in second of arc    

 and located near 30 degree latitude and 59 degree longitude           

                                                            





 Credits:

	CWP: Shuki Ronen

	Toralf Foerster



 Trace header fields accessed: sx, sy, gx, gy, counit, scalco.





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

my $su3dchart			= {
	_degree					=> '',
	_linewidth					=> '',
	_n					=> '',
	_outpar					=> '',
	_par					=> '',
	_scalco					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$su3dchart->{_Step}     = 'su3dchart'.$su3dchart->{_Step};
	return ( $su3dchart->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$su3dchart->{_note}     = 'su3dchart'.$su3dchart->{_note};
	return ( $su3dchart->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$su3dchart->{_degree}			= '';
		$su3dchart->{_linewidth}			= '';
		$su3dchart->{_n}			= '';
		$su3dchart->{_outpar}			= '';
		$su3dchart->{_par}			= '';
		$su3dchart->{_scalco}			= '';
		$su3dchart->{_Step}			= '';
		$su3dchart->{_note}			= '';
 }


=head2 sub degree 


=cut

 sub degree {

	my ( $self,$degree )		= @_;
	if ( $degree ne $empty_string ) {

		$su3dchart->{_degree}		= $degree;
		$su3dchart->{_note}		= $su3dchart->{_note}.' degree='.$su3dchart->{_degree};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' degree='.$su3dchart->{_degree};

	} else { 
		print("su3dchart, degree, missing degree,\n");
	 }
 }


=head2 sub linewidth 


=cut

 sub linewidth {

	my ( $self,$linewidth )		= @_;
	if ( $linewidth ne $empty_string ) {

		$su3dchart->{_linewidth}		= $linewidth;
		$su3dchart->{_note}		= $su3dchart->{_note}.' linewidth='.$su3dchart->{_linewidth};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' linewidth='.$su3dchart->{_linewidth};

	} else { 
		print("su3dchart, linewidth, missing linewidth,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$su3dchart->{_n}		= $n;
		$su3dchart->{_note}		= $su3dchart->{_note}.' n='.$su3dchart->{_n};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' n='.$su3dchart->{_n};

	} else { 
		print("su3dchart, n, missing n,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$su3dchart->{_outpar}		= $outpar;
		$su3dchart->{_note}		= $su3dchart->{_note}.' outpar='.$su3dchart->{_outpar};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' outpar='.$su3dchart->{_outpar};

	} else { 
		print("su3dchart, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$su3dchart->{_par}		= $par;
		$su3dchart->{_note}		= $su3dchart->{_note}.' par='.$su3dchart->{_par};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' par='.$su3dchart->{_par};

	} else { 
		print("su3dchart, par, missing par,\n");
	 }
 }


=head2 sub scalco 


=cut

 sub scalco {

	my ( $self,$scalco )		= @_;
	if ( $scalco ne $empty_string ) {

		$su3dchart->{_scalco}		= $scalco;
		$su3dchart->{_note}		= $su3dchart->{_note}.' scalco='.$su3dchart->{_scalco};
		$su3dchart->{_Step}		= $su3dchart->{_Step}.' scalco='.$su3dchart->{_scalco};

	} else { 
		print("su3dchart, scalco, missing scalco,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 1;

    return($max_index);
}
 
 
1;
