package App::SeismicUnixGui::sunix::header::suhtmath;

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
 SUHTMATH - do unary arithmetic operation on segy traces with 	

	     headers values					



 suhtmath <stdin >stdout				



 Required parameters:						

	none							



 Optional parameter:						

	key=tracl	header word to use			

	op=nop		operation flag				

			nop   : no operation			

			add   : add header to trace		

			mult  : multiply trace with header	

			div   : divide trace by header		



	scale=1.0	scalar multiplier for header value	

	const=0.0	additive constant for header value	



 Operation order:						",      



 op=add:	out(t) = in(t) + (scale * key + const)		

 op=mult:	out(t) = in(t) * (scale * key + const)		

 op=div:	out(t) = in(t) / (scale * key + const)		



 Credits:

	Matthias Imhof, Virginia Tech, Fri Dec 27 09:17:29 EST 2002



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

my $suhtmath			= {
	_const					=> '',
	_key					=> '',
	_op					=> '',
	_scale					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suhtmath->{_Step}     = 'suhtmath'.$suhtmath->{_Step};
	return ( $suhtmath->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suhtmath->{_note}     = 'suhtmath'.$suhtmath->{_note};
	return ( $suhtmath->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suhtmath->{_const}			= '';
		$suhtmath->{_key}			= '';
		$suhtmath->{_op}			= '';
		$suhtmath->{_scale}			= '';
		$suhtmath->{_Step}			= '';
		$suhtmath->{_note}			= '';
 }


=head2 sub const 


=cut

 sub const {

	my ( $self,$const )		= @_;
	if ( $const ne $empty_string ) {

		$suhtmath->{_const}		= $const;
		$suhtmath->{_note}		= $suhtmath->{_note}.' const='.$suhtmath->{_const};
		$suhtmath->{_Step}		= $suhtmath->{_Step}.' const='.$suhtmath->{_const};

	} else { 
		print("suhtmath, const, missing const,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$suhtmath->{_key}		= $key;
		$suhtmath->{_note}		= $suhtmath->{_note}.' key='.$suhtmath->{_key};
		$suhtmath->{_Step}		= $suhtmath->{_Step}.' key='.$suhtmath->{_key};

	} else { 
		print("suhtmath, key, missing key,\n");
	 }
 }


=head2 sub op 


=cut

 sub op {

	my ( $self,$op )		= @_;
	if ( $op ne $empty_string ) {

		$suhtmath->{_op}		= $op;
		$suhtmath->{_note}		= $suhtmath->{_note}.' op='.$suhtmath->{_op};
		$suhtmath->{_Step}		= $suhtmath->{_Step}.' op='.$suhtmath->{_op};

	} else { 
		print("suhtmath, op, missing op,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$suhtmath->{_scale}		= $scale;
		$suhtmath->{_note}		= $suhtmath->{_note}.' scale='.$suhtmath->{_scale};
		$suhtmath->{_Step}		= $suhtmath->{_Step}.' scale='.$suhtmath->{_scale};

	} else { 
		print("suhtmath, scale, missing scale,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 3;

    return($max_index);
}
 
 
1;
