package App::SeismicUnixGui::sunix::shell::cat_su;

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
Usage for cat module in L_SU

cat derives from unix command of the same name



Added: by Juan Lorenzo Jan. 2022

  

 Usage: cat base_file_name1='sufile1' base_file_name2='sufile2' > output_file



  base_file_name1=first (su file)

  base_file_name2=second optional (su file)

  output file is handled by module data_out.pm

=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use App::SeismicUnixGui::misc::L_SU_global_constants;
use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii 
$suffix_bin $suffix_ps $suffix_segy $suffix_su);

use App::SeismicUnixGui::configs::big_streams::Project_config;

=head2 instantiation of packages

=cut

my $get					= App::SeismicUnixGui::misc::L_SU_global_constants->new();
my $Project				= App::SeismicUnixGui::configs::big_streams::Project_config->new();

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

my $cat_su			= {
	_base_file_name1					=> '',
	_base_file_name2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$cat_su->{_Step}     = 'cat'.$cat_su->{_Step};
	return ( $cat_su->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$cat_su->{_note}     = 'cat'.$cat_su->{_note};
	return ( $cat_su->{_note} );

 }


=head2 sub clear

=cut

 sub clear {

		$cat_su->{_base_file_name1}			= '';
		$cat_su->{_base_file_name2}			= '';
		$cat_su->{_Step}			= '';
		$cat_su->{_note}			= '';
 }


=head2 sub base_file_name1 


=cut

 sub base_file_name1 {

	my ( $self,$base_file_name1 )		= @_;
	if ( $base_file_name1 ne $empty_string ) {

		$cat_su->{_base_file_name1}		= $base_file_name1;
		$cat_su->{_note}		= $cat_su->{_note}.' '.$cat_su->{_base_file_name1};
		$cat_su->{_Step}		= $cat_su->{_Step}.' '.$cat_su->{_base_file_name1};

	} else { 
		print("cat_su, base_file_name1, missing base_file_name1,\n");
	 }
 }


=head2 sub base_file_name2 


=cut

 sub base_file_name2 {

	my ( $self,$base_file_name2 )		= @_;
	if ( $base_file_name2 ne $empty_string ) {

		$cat_su->{_base_file_name2}		= $base_file_name2;
		$cat_su->{_note}		= $cat_su->{_note}.' '.$cat_su->{_base_file_name2};
		$cat_su->{_Step}		= $cat_su->{_Step}.' '.$cat_su->{_base_file_name2};

	} else { 
		print("cat_su, base_file_name2, missing base_file_name2,\n");
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
