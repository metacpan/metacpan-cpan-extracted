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

You will need to have the following file:
~/developer/code/sunix/nameNnumber.txt

sukdmig3d 6

The first item is the module name
The second item list is theThe name of the number of
the program group (migration=6)
You can take these definitions from the
module: sudocpm_nameNnumber.pm

=item sudoc2pm_pt2.pl

Second stage in creating *.pm, *_spec.pm
and *_config.pm modules for each 
Seismic unix program

After running sudoc2pm_pt1.pl but before
running sudoc2pm_pt2.pl, populate the following
file if needed:

~/developer/Stripped/group_name/program_name_changes.txt

See for example ~~/developer/Stripped/migration/sukdmig3d_changes.txt

Also check to see in
~/configs/

program_name.config

e.g.,
~/congifs/statsMath/suop.config

=back

=cut