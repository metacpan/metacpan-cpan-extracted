use strict;
use warnings;

=head1 README

=head2 DIRECTORY CONTENTS (INCOMPLETE)

Aug. 30, 2022

=over 5

=item convert2V07.pl

Update old flows to latest
version of main

=item change_a_line_everywhere.pl

Set text to find and change

=item sudocpm_nameNnumber.pm

Name of the program
and its program-group number
which will be used to incorporate this sunix module 
into the L_SU GUIB

sudoc2pm_pt1.pl uses this package

=item program_name_changes.txt

File that describes which rows in the GUI

Will automatically be linked
to opening relevant directories.

ONLY sudoc2pm_pt2.pl uses this file
but after sudoc2pm_pt1.pl is run
susynlv 7

=item sudoc2pm_pt1.pl

First stage in creating *.pm, *_spec.pm
and *_config.pm modules for each 
Seismic unix program

You will need to

0. make sure that the documentation
exists for the program in the 
"Stripped"  directory

1. populate the following file:
~/developer/code/sunix/nameNnumber.txt

sukdmig3d 6

The first item is the module name
The second item list is theThe name of the number of
the program group (migration=6)
You can take these definitions from the
module: sudocpm_nameNnumber.pm

 Program group names and numbers:

$developer_sunix_categories[0]  = 'data'; 22
$developer_sunix_categories[1]  = 'datum'; 4
$developer_sunix_categories[2]  = 'plot'; 40
$developer_sunix_categories[3]  = 'filter'; 21
$developer_sunix_categories[4]  = 'header'; 37
$developer_sunix_categories[5]  = 'inversion'; 3
$developer_sunix_categories[6]  = 'migration'; 21
$developer_sunix_categories[7]  = 'model'; 39
$developer_sunix_categories[8]  = 'NMO_Vel_Stk'; 32
$developer_sunix_categories[9]  = 'par'; 16
$developer_sunix_categories[10] = 'picks'; NA
$developer_sunix_categories[11] = 'shapeNcut'; 11
$developer_sunix_categories[12] = 'shell'; 4 (of which 2 are My linux)
$developer_sunix_categories[13] = 'statsMath'; 19
$developer_sunix_categories[14] = 'transform'; 15
$developer_sunix_categories[15] = 'well'; 6
$developer_sunix_categories[16] = 'unix'; NA
$developer_sunix_categories[17] = '';
total modules: 290, of which 2 are for linux commands
Total Tools; 13 2-linux, 1-C, 1 sioseis, 1 fortran



2. Finally, before your run sudoc2pm.pt1.pl enter a line in
L_SU_global_constants.pm e.g., 

  _sukdmig3d    => $developer_sunix_categories[6],
  
 (TODO: these lines can be written by sudoc2pm_pt1.pl)

=item sudoc2pm_pt2.pl

Second stage in creating *.pm, *_spec.pm
and *_config.pm modules for each 
Seismic unix program

After running sudoc2pm_pt1.pl but BEFORE
running sudoc2pm_pt2.pl:

1. populate the following
file if needed:

~/developer/Stripped/group_name/program_name_changes.txt

See for example ~/developer/Stripped/migration/sukdmig3d_changes.txt

3 su
2 bin
4 su
7 bin

The number points to the parameter label seen in the gui
The data type abbreviation binds a clicking action to
open the correct directory for that file type. For example,
su will open $DATA_SEISMIC_SU

2. Also check to see in
~/configs/

program_name.config

e.g.,
~/configs/statsMath/suop.config


=item

Before running code in the GUI
Add the following lines in L_SU_path.pm:

	_sukdmig3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	  
	  and 
	  
	 	_sukdmig3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	  
	 (TODO: these lines can be written by sudoc2pm_pt2.pl)

=back



=cut