package App::SeismicUnixGui::sunix::data::wptcomp;

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
 WPTCOMP - Compression by Wavelet Packet Compression 			



   wptcomp < stdin n1= n2=   [optional parameter] > sdtout		



 Required Parameters:							

 n1=			number of samples in the fast (first) dimension	

 n2=			number of samples in the slow (second) dimension



 Optional Parameters:							

 nfilter1=11		number of filters in direction 1		

 nfilter2=11		number of filters in direction 2		

 nstage1=		filter stages (automatically set based on n1)	

 nstage2=		filter stages (automatically set based on n2)	

 error=0.01		acceptable error				







 Author:  CWP: Tong Chen, Dec 1995



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

my $wptcomp			= {
	_error					=> '',
	_n1					=> '',
	_n2					=> '',
	_nfilter1					=> '',
	_nfilter2					=> '',
	_nstage1					=> '',
	_nstage2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$wptcomp->{_Step}     = 'wptcomp'.$wptcomp->{_Step};
	return ( $wptcomp->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$wptcomp->{_note}     = 'wptcomp'.$wptcomp->{_note};
	return ( $wptcomp->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$wptcomp->{_error}			= '';
		$wptcomp->{_n1}			= '';
		$wptcomp->{_n2}			= '';
		$wptcomp->{_nfilter1}			= '';
		$wptcomp->{_nfilter2}			= '';
		$wptcomp->{_nstage1}			= '';
		$wptcomp->{_nstage2}			= '';
		$wptcomp->{_Step}			= '';
		$wptcomp->{_note}			= '';
 }


=head2 sub error 


=cut

 sub error {

	my ( $self,$error )		= @_;
	if ( $error ne $empty_string ) {

		$wptcomp->{_error}		= $error;
		$wptcomp->{_note}		= $wptcomp->{_note}.' error='.$wptcomp->{_error};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' error='.$wptcomp->{_error};

	} else { 
		print("wptcomp, error, missing error,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$wptcomp->{_n1}		= $n1;
		$wptcomp->{_note}		= $wptcomp->{_note}.' n1='.$wptcomp->{_n1};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' n1='.$wptcomp->{_n1};

	} else { 
		print("wptcomp, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$wptcomp->{_n2}		= $n2;
		$wptcomp->{_note}		= $wptcomp->{_note}.' n2='.$wptcomp->{_n2};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' n2='.$wptcomp->{_n2};

	} else { 
		print("wptcomp, n2, missing n2,\n");
	 }
 }


=head2 sub nfilter1 


=cut

 sub nfilter1 {

	my ( $self,$nfilter1 )		= @_;
	if ( $nfilter1 ne $empty_string ) {

		$wptcomp->{_nfilter1}		= $nfilter1;
		$wptcomp->{_note}		= $wptcomp->{_note}.' nfilter1='.$wptcomp->{_nfilter1};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' nfilter1='.$wptcomp->{_nfilter1};

	} else { 
		print("wptcomp, nfilter1, missing nfilter1,\n");
	 }
 }


=head2 sub nfilter2 


=cut

 sub nfilter2 {

	my ( $self,$nfilter2 )		= @_;
	if ( $nfilter2 ne $empty_string ) {

		$wptcomp->{_nfilter2}		= $nfilter2;
		$wptcomp->{_note}		= $wptcomp->{_note}.' nfilter2='.$wptcomp->{_nfilter2};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' nfilter2='.$wptcomp->{_nfilter2};

	} else { 
		print("wptcomp, nfilter2, missing nfilter2,\n");
	 }
 }


=head2 sub nstage1 


=cut

 sub nstage1 {

	my ( $self,$nstage1 )		= @_;
	if ( $nstage1 ne $empty_string ) {

		$wptcomp->{_nstage1}		= $nstage1;
		$wptcomp->{_note}		= $wptcomp->{_note}.' nstage1='.$wptcomp->{_nstage1};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' nstage1='.$wptcomp->{_nstage1};

	} else { 
		print("wptcomp, nstage1, missing nstage1,\n");
	 }
 }


=head2 sub nstage2 


=cut

 sub nstage2 {

	my ( $self,$nstage2 )		= @_;
	if ( $nstage2 ne $empty_string ) {

		$wptcomp->{_nstage2}		= $nstage2;
		$wptcomp->{_note}		= $wptcomp->{_note}.' nstage2='.$wptcomp->{_nstage2};
		$wptcomp->{_Step}		= $wptcomp->{_Step}.' nstage2='.$wptcomp->{_nstage2};

	} else { 
		print("wptcomp, nstage2, missing nstage2,\n");
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
