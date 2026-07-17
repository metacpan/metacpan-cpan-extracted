
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

=head4 Examples

=head3 NOTES

A "program_name"_changes.txt file may be needed,
but is not necessary always.
If this file is not found, then no changes.

This file will prepare the *_spec.pm file
with the correct bindings for the screen
parameters.	

Selected changes are taken from files:
"program_name"_changes.txt
i.e., A *changes file in required

A "program_name"_changes.txt file is found
within the Stripped/"program_group_name"/ directory
e.g., for suk2mig3d: as ~migration/suk2mig3d_changes.txt:

3 su
2 bin
4 su
7 bin

You are now ready to run the current scripy.
You may have to run this current script manually
from within its directory e.g., ~developer/code/sunix/

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
  	

=head2 CHANGES and their DATES

Automatically modify *_spec to include bindings to directories by
in including a file within the correct category directory
e.g., :
~/Stripped/migration/sumigps_changes.txt

Bindings are used to link a right-click to a directory
where the output files are stored.


=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sudoc2pm_nameNnumber';
use aliased 'App::SeismicUnixGui::developer::code::sunix::update';

my $sudoc2pm_nameNnumber    = sudoc2pm_nameNnumber->new();
my $update = update->new();

my $selected_program_name = $sudoc2pm_nameNnumber->get_selected_program_name();
my $sunix_category_number = $sudoc2pm_nameNnumber->get_category_number();

my $spec_changes_base_file_name = $selected_program_name.'_changes';

$update->set_program( $selected_program_name, $sunix_category_number );
$update->set_spec_changes_base_file_name($spec_changes_base_file_name);
$update->set_spec_changes();
$update->spec_changes();
$update->set_changes();