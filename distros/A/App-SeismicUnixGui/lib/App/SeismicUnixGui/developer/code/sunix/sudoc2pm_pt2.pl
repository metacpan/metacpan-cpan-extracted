
=head1 DOCUMENTATION

=head2 SYNOPSIS

PROGRAM NAME:  sudoc2pm_pt2.pl							

 AUTHOR: Juan Lorenzo
 DATE:   Septmber 11, 2021 
 DESCRIPTION: update 
 			  spec-file to include correct
 			  bindings of the screen parameters 
 			  
 Version: 0.0.1

=head2 USE

=head3 NOTES

A *changes file in required

=head4 Examples

=head3 NOTES

 	Program group array and the directory names:
 		
$developer_sunix_categories[0]  = 'data';
$developer_sunix_categories[1]  = 'datum';
$developer_sunix_categories[2]  = 'plot';
$developer_sunix_categories[3]  = 'filter';
$developer_sunix_categories[4]  = 'header';
$developer_sunix_categories[5]  = 'inversion';
$developer_sunix_categories[6]  = 'migration';
$developer_sunix_categories[7]  = 'model';
$developer_sunix_categories[8]  = 'NMO_Vel_Stk';
$developer_sunix_categories[9]  = 'par';
$developer_sunix_categories[10] = 'picks';
$developer_sunix_categories[11] = 'shapeNcut';
$developer_sunix_categories[12] = 'shell';
$developer_sunix_categories[13] = 'statsMath';
$developer_sunix_categories[14] = 'transform';
$developer_sunix_categories[15] = 'well';
$developer_sunix_categories[16] = '';
  	
 	QUESTION 1:
Which group number do you want to use to create
for *.pm, *.config, and *_spec.pm files ?

e.g., for transforms use:
$sunix_category_number = 15
	

=head2 CHANGES and their DATES

selected changes are taken from files:
program_name_changes.txt


After running this script do the following:

check the *spec file

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sudoc2pm_nameNnumber';
use aliased 'App::SeismicUnixGui::developer::code::sunix::update';

my $sudoc2pm_nameNnumber    = sudoc2pm_nameNnumber->new();
my $update = update->new();

=head2 QUESTION 1:
Which group number do you want ?
QUESTION 2:
Which program do you want to work on?

For example=
'sugetgthr';
'sugain';
'suputgthr';
'suifft';
'sufctanismod'
'vel2stiff
'unif2aniso'
'transp'
'suflip'

=cut

my $selected_program_name = $sudoc2pm_nameNnumber->get_selected_program_name();
my $sunix_category_number = $sudoc2pm_nameNnumber->get_category_number();

my $spec_changes_base_file_name = $selected_program_name.'_changes';

$update->set_program( $selected_program_name, $sunix_category_number );
$update->set_spec_changes_base_file_name($spec_changes_base_file_name);
$update->set_spec_changes();
$update->spec_changes();
$update->set_changes();

