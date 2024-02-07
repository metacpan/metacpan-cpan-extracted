package App::SeismicUnixGui::sunix::header::supaste;

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
 SUPASTE - paste existing SU headers on existing binary data	



 supaste <bare_data >segys  ns= head=headers ftn=0		



 Required parameter:						

	ns=the number of samples per trace			



 Optional parameters:						

 	head=headers	file with segy headers			

	ftn=0		Fortran flag				

			0 = unformatted data from C		

			1 = ... from Fortran			

	verbose=0	1 equals echo number of traces pasted		

 Caution:							

	An incorrect ns field will munge subsequent processing.	



 Notes:							

 This program is used when the option head=headers is used in	

 sustrip. See:   sudoc sustrip    for more details. 		



 Related programs:  sustrip, suaddhead				



 Credits:

	CWP:  Jack K. Cohen, November 1990



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

my $supaste			= {
	_ftn					=> '',
	_head					=> '',
	_ns					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supaste->{_Step}     = 'supaste'.$supaste->{_Step};
	return ( $supaste->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supaste->{_note}     = 'supaste'.$supaste->{_note};
	return ( $supaste->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supaste->{_ftn}			= '';
		$supaste->{_head}			= '';
		$supaste->{_ns}			= '';
		$supaste->{_verbose}			= '';
		$supaste->{_Step}			= '';
		$supaste->{_note}			= '';
 }




=head2 sub ftn 


=cut

 sub ftn {

	my ( $self,$ftn )		= @_;
	if ( $ftn ne $empty_string ) {

		$supaste->{_ftn}		= $ftn;
		$supaste->{_note}		= $supaste->{_note}.' ftn='.$supaste->{_ftn};
		$supaste->{_Step}		= $supaste->{_Step}.' ftn='.$supaste->{_ftn};

	} else { 
		print("supaste, ftn, missing ftn,\n");
	 }
 }


=head2 sub head 


=cut

 sub head {

	my ( $self,$head )		= @_;
	if ( $head ne $empty_string ) {

		$supaste->{_head}		= $head;
		$supaste->{_note}		= $supaste->{_note}.' head='.$supaste->{_head};
		$supaste->{_Step}		= $supaste->{_Step}.' head='.$supaste->{_head};

	} else { 
		print("supaste, head, missing head,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$supaste->{_ns}		= $ns;
		$supaste->{_note}		= $supaste->{_note}.' ns='.$supaste->{_ns};
		$supaste->{_Step}		= $supaste->{_Step}.' ns='.$supaste->{_ns};

	} else { 
		print("supaste, ns, missing ns,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supaste->{_verbose}		= $verbose;
		$supaste->{_note}		= $supaste->{_note}.' verbose='.$supaste->{_verbose};
		$supaste->{_Step}		= $supaste->{_Step}.' verbose='.$supaste->{_verbose};

	} else { 
		print("supaste, verbose, missing verbose,\n");
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
