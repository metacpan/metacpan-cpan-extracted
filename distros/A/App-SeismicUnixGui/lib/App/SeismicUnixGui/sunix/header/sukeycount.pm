package App::SeismicUnixGui::sunix::header::sukeycount;

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
 SUKEYCOUNT - sukeycount writes a count of a selected key    



   sukeycount key=keyword < infile [> outfile]                  



 Required parameters:                                        

 key=keyword      One key word.                                 



 Optional parameters:                                        

 verbose=0  quiet                                            

        =1  chatty                                           



 Writes the key and the count to the terminal or a text      

   file when a change of key occurs. This does not provide   

   a unique key count (see SUCOUNTKEY for that).             

 Note that for key values  1 2 3 4 2 5                       

   value 2 is counted once per occurrence since this program 

   only recognizes a change of key, not total occurrence.    



 Examples:                                                   

    sukeycount < stdin key=fldr                              

    sukeycount < stdin key=fldr > out.txt                    





 Credits:



   MTU: David Forel, Jan 2005



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

my $sukeycount			= {
	_key					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sukeycount->{_Step}     = 'sukeycount'.$sukeycount->{_Step};
	return ( $sukeycount->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sukeycount->{_note}     = 'sukeycount'.$sukeycount->{_note};
	return ( $sukeycount->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sukeycount->{_key}			= '';
		$sukeycount->{_verbose}			= '';
		$sukeycount->{_Step}			= '';
		$sukeycount->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sukeycount->{_key}		= $key;
		$sukeycount->{_note}		= $sukeycount->{_note}.' key='.$sukeycount->{_key};
		$sukeycount->{_Step}		= $sukeycount->{_Step}.' key='.$sukeycount->{_key};

	} else { 
		print("sukeycount, key, missing key,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sukeycount->{_verbose}		= $verbose;
		$sukeycount->{_note}		= $sukeycount->{_note}.' verbose='.$sukeycount->{_verbose};
		$sukeycount->{_Step}		= $sukeycount->{_Step}.' verbose='.$sukeycount->{_verbose};

	} else { 
		print("sukeycount, verbose, missing verbose,\n");
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
