
=head1 DOCUMENTATION

=head2 SYNOPSIS 

	NAME:     Project 
	Author:   Juan M. Lorenzo 
	Date:     Jan 1 2017
	          from SetProject December 15, 2011 
	Purpose:  Create Project Directories  
 		      Establishes system-wide and local directories
 		      via configuration files
        Details:  "sub-packages" use
                  Project_Variables package 

        Usage:    directories can be turned
                  on/off with comment marks ("#")
                  
=head2 NEEDS

		Project

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();

$Project->basic_dirs();
$Project->system_dirs();
$Project->make_local_dirs();
#$Project->update_configuration_files();
