
=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: BakupProject 
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE:    July 2024
 Version  1.0 
 

=head2 DESCRIPTION

         Backup (tar -czvf) a Project plus
         its Project.config file

=head2 USE

perl BackupProject.pl

=head2 Steps

1. Read the BackupProject.config file in the user's 
Project directory. This Project directory does not have to 
be the same one that is being tarred

2. Read configuration file to determine the directory that is being 
tarred

3. Confirm that the directory is a project. Otherwise output a warning.

4. tar -czvf

5. Message that process is complete 


=head2 NOTES 

 We are using Moose.
 Moose already declares that you need debuggers turned on
 so you don't need a line like the following:
 use warnings;


=cut

use Moose;
our $VERSION = '0.1.0';

use aliased 'App::SeismicUnixGui::misc::L_SU_local_user_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::BackupProject_config';
use aliased 'App::SeismicUnixGui::misc::control';
use File::Copy;
use Cwd;

=head2 Instantiate classes:

 Create a new versions of the packages 

=cut

my $BackupProject_config      = BackupProject_config->new();
my $L_SU_local_user_constants = L_SU_local_user_constants->new();
my $control                   = control->new();

=head2

  Internal definitions
  
=cut

my $success_counter = 0;
my $CWD             = getcwd();

=head2 Get configuration information

Assume Project is at least soft-linked
from the home dirctory

=cut

my ( $CFG_h, $CFG_aref ) = $BackupProject_config->get_values();
my $project_directory    = $CFG_h->{BackupProject}{1}{directory_name};
$control->set_infection( $project_directory );
$project_directory       = $control->get_ticksBgone();

print("BackupProject.pl, project_directory = $project_directory \n");

my $HOME           = $L_SU_local_user_constants->get_home();
my $tar_input      = $HOME . '/'. $project_directory;

=head2 Verify project is a true SUG project

collect project names
compare backup project against project names

=cut

my @PROJECT_HOME_aref = $L_SU_local_user_constants->get_PROJECT_HOMES_aref();
my @project_name_aref = $L_SU_local_user_constants->get_project_names();
my $CONFIGURATION     = $L_SU_local_user_constants->get_CONFIGURATION();

my @project_pathNname = @{ $PROJECT_HOME_aref[0] };
my @project_name      = @{ $project_name_aref[0] };

my $length             = scalar @project_pathNname;

print("BackupProject.pl,project_pathNnames are=@project_pathNname\n");
#print("BackupProject.pl,CONFIGURATION= $CONFIGURATION\n");
#print("BackupProject.pl,project names=@project_name\n");
#print("Backup_PROJECT_PROJECTProject.pl,There are $length existant projects in /.L_SU/configuration\n");

=pod
 
 check to see that the project directory 
 that is to be backed up exists.
 
=cut

 $L_SU_local_user_constants->set_PROJECT_name($project_directory);
 my $project_exists = $L_SU_local_user_constants->get_PROJECT_exists();
 print("BackupProject.pl,Does project $project_directory exist? ans=$project_exists\n");

=pod
 
 check to see that the project directory contains Project.config
 If Project.config exists then
 copy this file with the Project during the backup
 
=cut

if ( $project_exists ) {

	my $Project_configuration_exists = $L_SU_local_user_constants->user_configuration_Project_config_exists();
    print("BackupProject.pl, Project_configuration_exists=$Project_configuration_exists \n");

	if ($Project_configuration_exists) {

		print("Found a real SeismicUnixGui project!\n");
		my $from = $CONFIGURATION.'/'.$project_directory.'/'.'Project.config';
		my $to   = $tar_input;
		
		copy( $from, $to );
		
        print("BackupProject.pl, copying $from to $to \n");
	}
	else {
		print("BackupProject.pl,unsuccessful\n");
		print("Not a real SeismicUnixGui project!\n");
	}

} else {
	print("BackupProject.pl, Project for backing up does not exist \n");
}

=head2 Tarring a project

remove the local path

=cut

my $ORIGDIR          = '.';
my $tar_options      = "-hczvf ";
my $project2tar      = './'.$project_directory;

my $perl_instruction = ("cd $HOME; tar $tar_options $project_directory.tz $project2tar");

print("$perl_instruction\n");
print("Generic \"Project.tz\" file is assumed to live in user\'s home directory\n");
print("Tarring will follow any symbolic links to their origin\n");

system($perl_instruction);
