package App::SeismicUnixGui::sunix::model::suspike;

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
 SUSPIKE - make a small spike data set 			



 suspike [optional parameters] > out_data_file  		



 Creates a common offset su data file with up to four spikes	

 for impulse response studies					



 Optional parameters:						

	nt=64 		number of time samples			

	ntr=32		number of traces			

 	dt=0.004 	time sample rate in seconds		

 	offset=400 	offset					

	nspk=4		number of spikes			

	ix1= ntr/4	trace number (from left) for spike #1	

	it1= nt/4 	time sample to spike #1			

	ix2 = ntr/4	trace for spike #2			

	it2 = 3*nt/4 	time for spike #2			

	ix3 = 3*ntr/4;	trace for spike #3			

	it3 = nt/4;	time for spike #3			

	ix4 = 3*ntr/4;	trace for spike #4			

	it4 = 3*nt/4;	time for spike #4			





 Credits:

	CWP: Shuki Ronen, Chris Liner



 Trace header fields set: ns, dt, offset



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

my $suspike			= {
	_dt					=> '',
	_it1					=> '',
	_it2					=> '',
	_it3					=> '',
	_it4					=> '',
	_ix1					=> '',
	_ix2					=> '',
	_ix3					=> '',
	_ix4					=> '',
	_nspk					=> '',
	_nt					=> '',
	_ntr					=> '',
	_offset					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suspike->{_Step}     = 'suspike'.$suspike->{_Step};
	return ( $suspike->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suspike->{_note}     = 'suspike'.$suspike->{_note};
	return ( $suspike->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suspike->{_dt}			= '';
		$suspike->{_it1}			= '';
		$suspike->{_it2}			= '';
		$suspike->{_it3}			= '';
		$suspike->{_it4}			= '';
		$suspike->{_ix1}			= '';
		$suspike->{_ix2}			= '';
		$suspike->{_ix3}			= '';
		$suspike->{_ix4}			= '';
		$suspike->{_nspk}			= '';
		$suspike->{_nt}			= '';
		$suspike->{_ntr}			= '';
		$suspike->{_offset}			= '';
		$suspike->{_Step}			= '';
		$suspike->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suspike->{_dt}		= $dt;
		$suspike->{_note}		= $suspike->{_note}.' dt='.$suspike->{_dt};
		$suspike->{_Step}		= $suspike->{_Step}.' dt='.$suspike->{_dt};

	} else { 
		print("suspike, dt, missing dt,\n");
	 }
 }


=head2 sub it1 


=cut

 sub it1 {

	my ( $self,$it1 )		= @_;
	if ( $it1 ne $empty_string ) {

		$suspike->{_it1}		= $it1;
		$suspike->{_note}		= $suspike->{_note}.' it1='.$suspike->{_it1};
		$suspike->{_Step}		= $suspike->{_Step}.' it1='.$suspike->{_it1};

	} else { 
		print("suspike, it1, missing it1,\n");
	 }
 }


=head2 sub it2 


=cut

 sub it2 {

	my ( $self,$it2 )		= @_;
	if ( $it2 ne $empty_string ) {

		$suspike->{_it2}		= $it2;
		$suspike->{_note}		= $suspike->{_note}.' it2='.$suspike->{_it2};
		$suspike->{_Step}		= $suspike->{_Step}.' it2='.$suspike->{_it2};

	} else { 
		print("suspike, it2, missing it2,\n");
	 }
 }


=head2 sub it3 


=cut

 sub it3 {

	my ( $self,$it3 )		= @_;
	if ( $it3 ne $empty_string ) {

		$suspike->{_it3}		= $it3;
		$suspike->{_note}		= $suspike->{_note}.' it3='.$suspike->{_it3};
		$suspike->{_Step}		= $suspike->{_Step}.' it3='.$suspike->{_it3};

	} else { 
		print("suspike, it3, missing it3,\n");
	 }
 }


=head2 sub it4 


=cut

 sub it4 {

	my ( $self,$it4 )		= @_;
	if ( $it4 ne $empty_string ) {

		$suspike->{_it4}		= $it4;
		$suspike->{_note}		= $suspike->{_note}.' it4='.$suspike->{_it4};
		$suspike->{_Step}		= $suspike->{_Step}.' it4='.$suspike->{_it4};

	} else { 
		print("suspike, it4, missing it4,\n");
	 }
 }


=head2 sub ix1 


=cut

 sub ix1 {

	my ( $self,$ix1 )		= @_;
	if ( $ix1 ne $empty_string ) {

		$suspike->{_ix1}		= $ix1;
		$suspike->{_note}		= $suspike->{_note}.' ix1='.$suspike->{_ix1};
		$suspike->{_Step}		= $suspike->{_Step}.' ix1='.$suspike->{_ix1};

	} else { 
		print("suspike, ix1, missing ix1,\n");
	 }
 }


=head2 sub ix2 


=cut

 sub ix2 {

	my ( $self,$ix2 )		= @_;
	if ( $ix2 ne $empty_string ) {

		$suspike->{_ix2}		= $ix2;
		$suspike->{_note}		= $suspike->{_note}.' ix2='.$suspike->{_ix2};
		$suspike->{_Step}		= $suspike->{_Step}.' ix2='.$suspike->{_ix2};

	} else { 
		print("suspike, ix2, missing ix2,\n");
	 }
 }


=head2 sub ix3 


=cut

 sub ix3 {

	my ( $self,$ix3 )		= @_;
	if ( $ix3 ne $empty_string ) {

		$suspike->{_ix3}		= $ix3;
		$suspike->{_note}		= $suspike->{_note}.' ix3='.$suspike->{_ix3};
		$suspike->{_Step}		= $suspike->{_Step}.' ix3='.$suspike->{_ix3};

	} else { 
		print("suspike, ix3, missing ix3,\n");
	 }
 }


=head2 sub ix4 


=cut

 sub ix4 {

	my ( $self,$ix4 )		= @_;
	if ( $ix4 ne $empty_string ) {

		$suspike->{_ix4}		= $ix4;
		$suspike->{_note}		= $suspike->{_note}.' ix4='.$suspike->{_ix4};
		$suspike->{_Step}		= $suspike->{_Step}.' ix4='.$suspike->{_ix4};

	} else { 
		print("suspike, ix4, missing ix4,\n");
	 }
 }


=head2 sub nspk 


=cut

 sub nspk {

	my ( $self,$nspk )		= @_;
	if ( $nspk ne $empty_string ) {

		$suspike->{_nspk}		= $nspk;
		$suspike->{_note}		= $suspike->{_note}.' nspk='.$suspike->{_nspk};
		$suspike->{_Step}		= $suspike->{_Step}.' nspk='.$suspike->{_nspk};

	} else { 
		print("suspike, nspk, missing nspk,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suspike->{_nt}		= $nt;
		$suspike->{_note}		= $suspike->{_note}.' nt='.$suspike->{_nt};
		$suspike->{_Step}		= $suspike->{_Step}.' nt='.$suspike->{_nt};

	} else { 
		print("suspike, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$suspike->{_ntr}		= $ntr;
		$suspike->{_note}		= $suspike->{_note}.' ntr='.$suspike->{_ntr};
		$suspike->{_Step}		= $suspike->{_Step}.' ntr='.$suspike->{_ntr};

	} else { 
		print("suspike, ntr, missing ntr,\n");
	 }
 }


=head2 sub offset 


=cut

 sub offset {

	my ( $self,$offset )		= @_;
	if ( $offset ne $empty_string ) {

		$suspike->{_offset}		= $offset;
		$suspike->{_note}		= $suspike->{_note}.' offset='.$suspike->{_offset};
		$suspike->{_Step}		= $suspike->{_Step}.' offset='.$suspike->{_offset};

	} else { 
		print("suspike, offset, missing offset,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
