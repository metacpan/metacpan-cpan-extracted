package App::SeismicUnixGui::sunix::header::sudumptrace;

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
 SUDUMPTRACE - print selected header values and data.              

               Print first num traces.                             

               Use SUWIND to skip traces.                          



 sudumptrace < stdin [> ascii_file]                                



 Optional parameters:                                              

     num=4                    number of traces to dump             

     key=key1,key2,...        key(s) to print above trace values   

     hpf=0                    header print format is float         

                              =1 print format is exponential       



 Examples:                                                         

   sudumptrace < inseis.su            PRINTS: 4 traces, no headers 

   sudumptrace < inseis.su key=tracf,offset                        

   sudumptrace < inseis.su num=7 key=tracf,offset > info.txt       

   sudumptrace < inseis.su num=7 key=tracf,offset hpf=1 > info.txt 



 Related programs: suascii, sugethw                                





 Credits:

   MTU: David Forel, Jan 2005



 Trace header field accessed: nt, dt, delrt



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

my $sudumptrace			= {
	_hpf					=> '',
	_key					=> '',
	_num					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudumptrace->{_Step}     = 'sudumptrace'.$sudumptrace->{_Step};
	return ( $sudumptrace->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudumptrace->{_note}     = 'sudumptrace'.$sudumptrace->{_note};
	return ( $sudumptrace->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudumptrace->{_hpf}			= '';
		$sudumptrace->{_key}			= '';
		$sudumptrace->{_num}			= '';
		$sudumptrace->{_Step}			= '';
		$sudumptrace->{_note}			= '';
 }


=head2 sub hpf 


=cut

 sub hpf {

	my ( $self,$hpf )		= @_;
	if ( $hpf ne $empty_string ) {

		$sudumptrace->{_hpf}		= $hpf;
		$sudumptrace->{_note}		= $sudumptrace->{_note}.' hpf='.$sudumptrace->{_hpf};
		$sudumptrace->{_Step}		= $sudumptrace->{_Step}.' hpf='.$sudumptrace->{_hpf};

	} else { 
		print("sudumptrace, hpf, missing hpf,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sudumptrace->{_key}		= $key;
		$sudumptrace->{_note}		= $sudumptrace->{_note}.' key='.$sudumptrace->{_key};
		$sudumptrace->{_Step}		= $sudumptrace->{_Step}.' key='.$sudumptrace->{_key};

	} else { 
		print("sudumptrace, key, missing key,\n");
	 }
 }


=head2 sub num 


=cut

 sub num {

	my ( $self,$num )		= @_;
	if ( $num ne $empty_string ) {

		$sudumptrace->{_num}		= $num;
		$sudumptrace->{_note}		= $sudumptrace->{_note}.' num='.$sudumptrace->{_num};
		$sudumptrace->{_Step}		= $sudumptrace->{_Step}.' num='.$sudumptrace->{_num};

	} else { 
		print("sudumptrace, num, missing num,\n");
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
