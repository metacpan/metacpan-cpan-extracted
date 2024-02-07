package App::SeismicUnixGui::sunix::header::suascii;

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
 SUASCII - print non zero header values and data in various formats    



 suascii <stdin >ascii_file                                            



 Optional parameter:                                                   

    bare=0     print headers and data                                  

        =1     print only data                                         

        =2     print headers only                                      

        =3     print data in print data in .csv format, e.g. for Excel 

        =4     print data as tab delimited .txt file, e.g. for GnuPlot 

        =5     print data as .xyz file, e.g. for plotting with GMT     



    ntr=50     maximum number of output traces (bare=3 or bare=4 only) 

    index=0    don't include time/depth index in ascii file (bare=4)   

         =1    include time/depth index in ascii file                  



    key=       if set, name of keyword containing x-value              

               in .xyz output (bare=5 only)                            

    sep=       if set, string separating traces in .xyz output         

               (bare=5; default is no separation)                      



    verbose=0  =1 for detailed information                             



 Notes:                                                                

    The programs suwind and suresamp provide trace selection and       

    subsampling, respectively.                                         

    With bare=0 and bare=1 traces are separated by a blank line.       



    With bare=3 a maximum of ntr traces are output in .csv format      

    ("comma-separated value"), e.g. for import into spreadsheet      

    applications like Excel.                                           



    With bare=4 a maximum of ntr traces are output in as tab delimited 

    columns. Use bare=4 for plotting in GnuPlot.                       



    With bare=5 traces are written as "x y z" triples as required    

    by certain plotting programs such as the Generic Mapping Tools     

    (GMT). If sep= is set, traces are separated by a line containing   

    the string provided, e.g. sep=">" for GMT multisegment files.    



    "option=" is an acceptable alias for "bare=".                  



 Related programs: sugethw, sudumptrace                                





 Credits:

    CWP: Jack K. Cohen  c. 1989

    CENPET: Werner M. Heigl 2006 - bug fixes & extensions

    RISSC:  Nils Maercklin 2006



 Trace header field accessed: ns, dt, delrt, d1, f1, trid



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

my $suascii			= {
	_bare					=> '',
	_index					=> '',
	_key					=> '',
	_ntr					=> '',
	_option					=> '',
	_sep					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suascii->{_Step}     = 'suascii'.$suascii->{_Step};
	return ( $suascii->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suascii->{_note}     = 'suascii'.$suascii->{_note};
	return ( $suascii->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suascii->{_bare}			= '';
		$suascii->{_index}			= '';
		$suascii->{_key}			= '';
		$suascii->{_ntr}			= '';
		$suascii->{_option}			= '';
		$suascii->{_sep}			= '';
		$suascii->{_verbose}			= '';
		$suascii->{_Step}			= '';
		$suascii->{_note}			= '';
 }


=head2 sub bare 


=cut

 sub bare {

	my ( $self,$bare )		= @_;
	if ( $bare ne $empty_string ) {

		$suascii->{_bare}		= $bare;
		$suascii->{_note}		= $suascii->{_note}.' bare='.$suascii->{_bare};
		$suascii->{_Step}		= $suascii->{_Step}.' bare='.$suascii->{_bare};

	} else { 
		print("suascii, bare, missing bare,\n");
	 }
 }


=head2 sub index 


=cut

 sub index {

	my ( $self,$index )		= @_;
	if ( $index ne $empty_string ) {

		$suascii->{_index}		= $index;
		$suascii->{_note}		= $suascii->{_note}.' index='.$suascii->{_index};
		$suascii->{_Step}		= $suascii->{_Step}.' index='.$suascii->{_index};

	} else { 
		print("suascii, index, missing index,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$suascii->{_key}		= $key;
		$suascii->{_note}		= $suascii->{_note}.' key='.$suascii->{_key};
		$suascii->{_Step}		= $suascii->{_Step}.' key='.$suascii->{_key};

	} else { 
		print("suascii, key, missing key,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$suascii->{_ntr}		= $ntr;
		$suascii->{_note}		= $suascii->{_note}.' ntr='.$suascii->{_ntr};
		$suascii->{_Step}		= $suascii->{_Step}.' ntr='.$suascii->{_ntr};

	} else { 
		print("suascii, ntr, missing ntr,\n");
	 }
 }


=head2 sub option 


=cut

 sub option {

	my ( $self,$option )		= @_;
	if ( $option ne $empty_string ) {

		$suascii->{_option}		= $option;
		$suascii->{_note}		= $suascii->{_note}.' option='.$suascii->{_option};
		$suascii->{_Step}		= $suascii->{_Step}.' option='.$suascii->{_option};

	} else { 
		print("suascii, option, missing option,\n");
	 }
 }


=head2 sub sep 


=cut

 sub sep {

	my ( $self,$sep )		= @_;
	if ( $sep ne $empty_string ) {

		$suascii->{_sep}		= $sep;
		$suascii->{_note}		= $suascii->{_note}.' sep='.$suascii->{_sep};
		$suascii->{_Step}		= $suascii->{_Step}.' sep='.$suascii->{_sep};

	} else { 
		print("suascii, sep, missing sep,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suascii->{_verbose}		= $verbose;
		$suascii->{_note}		= $suascii->{_note}.' verbose='.$suascii->{_verbose};
		$suascii->{_Step}		= $suascii->{_Step}.' verbose='.$suascii->{_verbose};

	} else { 
		print("suascii, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1; 
