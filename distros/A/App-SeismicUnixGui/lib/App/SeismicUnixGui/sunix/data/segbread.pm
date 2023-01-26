package App::SeismicUnixGui::sunix::data::segbread;

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
 SEGBREAD - read an SEG-B tape						



 segbread > stdout tape=						





 Required parameters:							

	tape=	   input tape device					

 Optional parameters:							



	ns=		number of samples.This overrides the number	

			that is obtained from the file header		 

			Usefull for variable trace length		



	auxf=0		1 output auxiliary channels			

	ntro=0		Number of traces per record.This overrides the	

			computed value (useful for some DFS-V		

			instruments) if specified.			



 ONLY READS DISK SEGB FILES! I tested it on files created by		

 TransMedia Technologies Calgary Alberta, Canada			

 In their format each data block is preceded by an eight byte header	

 2  unsigned 32 bit IBM format integer.				

 First number is the block number, second is the length of block given	

 in bytes.								

  (This program is largely untested. Testing reports on SEG B data	

 and improvements to the code 									



 

 Credits: Balasz Nemeth, Potash Corporation Saskatechwan

 given to CWP in 2008

 Based on SEGDREAD by Stew Levin of Landmark Graphics and others.
 
 
 
 =head2 User's (Juan Lorenzo) notes
 
 Untested



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

my $segbread			= {
	_auxf					=> '',
	_ns					=> '',
	_ntro					=> '',
	_tape					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$segbread->{_Step}     = 'segbread'.$segbread->{_Step};
	return ( $segbread->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segbread->{_note}     = 'segbread'.$segbread->{_note};
	return ( $segbread->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segbread->{_auxf}			= '';
		$segbread->{_ns}			= '';
		$segbread->{_ntro}			= '';
		$segbread->{_tape}			= '';
		$segbread->{_Step}			= '';
		$segbread->{_note}			= '';
 }


=head2 sub auxf 


=cut

 sub auxf {

	my ( $self,$auxf )		= @_;
	if ( $auxf ne $empty_string ) {

		$segbread->{_auxf}		= $auxf;
		$segbread->{_note}		= $segbread->{_note}.' auxf='.$segbread->{_auxf};
		$segbread->{_Step}		= $segbread->{_Step}.' auxf='.$segbread->{_auxf};

	} else { 
		print("segbread, auxf, missing auxf,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$segbread->{_ns}		= $ns;
		$segbread->{_note}		= $segbread->{_note}.' ns='.$segbread->{_ns};
		$segbread->{_Step}		= $segbread->{_Step}.' ns='.$segbread->{_ns};

	} else { 
		print("segbread, ns, missing ns,\n");
	 }
 }


=head2 sub ntro 


=cut

 sub ntro {

	my ( $self,$ntro )		= @_;
	if ( $ntro ne $empty_string ) {

		$segbread->{_ntro}		= $ntro;
		$segbread->{_note}		= $segbread->{_note}.' ntro='.$segbread->{_ntro};
		$segbread->{_Step}		= $segbread->{_Step}.' ntro='.$segbread->{_ntro};

	} else { 
		print("segbread, ntro, missing ntro,\n");
	 }
 }


=head2 sub tape 


=cut

 sub tape {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

		$segbread->{_tape}		= $tape;
		$segbread->{_note}		= $segbread->{_note}.' tape='.$segbread->{_tape};
		$segbread->{_Step}		= $segbread->{_Step}.' tape='.$segbread->{_tape};

	} else { 
		print("segbread, tape, missing tape,\n");
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
