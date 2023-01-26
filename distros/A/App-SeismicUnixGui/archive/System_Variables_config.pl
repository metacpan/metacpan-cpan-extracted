#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: System_Variables_config.pl 
 AUTHOR: Juan Lorenzo
 DATE: July 29 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR 
      Upper-level variable
      definitions in iTop_Mute3 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
 Version 1  Based on linux command "cat"
 Version 2 based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)

 Oct. 19 2016    
 Version 2.1 Includes option for multiple users in every directory 
   
 Needs: Simple (ASCII) local configuration 
      file is Project_Variables.config

=cut

=head2 Notes 

 Simple reads configuration file and
 cretes a hash with parameters (keys/names) and
 their values as assigned inside the configuration
 file
 
=cut 

use Moose;
use Config::Simple;
use control 0.0.3;
my $control = control->new();
my $cfg     = new Config::Simple('Project_Variables.config');

=head2 anonymous hash array reference $CFG
       class: cfg
       method: param
       returns: value


 contains all the configuration variables in
 perl script

   HOME                ='/home/gom';
   PROJECT_HOME		= '/FalseRiver';;
   site			= 'Bueche';
   spare_dir		= '';
   date			= '051216';
   component		= 'H';
   line			= '1';
   subUser		= 'gom';

 -In case specifications are blank,
  control package rectifies.

 DB
 print("1.System_Variables_config.pl,spare_dir is $spare_dir\n");
 print("2.System_Variables,spare_dir is $$spare_dir\n");
 print("1.System_Variables,spare_dir is $spare_dir-\n");
 print("3.System_Variables,spare_dir is $spare_dir-\n");
 print("4.System_Variables,site is $site\n");
 print("1.System_Variables_config.pl,HOME is $HOME\n");

=cut 

my $HOME         = $cfg->param("HOME");
my $PROJECT_HOME = $cfg->param("PROJECT_HOME");
my $site         = $cfg->param("site");
my $spare_dir    = $cfg->param("spare_dir");
my $date         = $cfg->param("date");
my $component    = $cfg->param("component");
my $line         = $cfg->param("line");
my $subUser      = $cfg->param("subUser");

=pod

 package control corrects for empty string 

=cut

$spare_dir = $control->empty_string( \$spare_dir );

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

our $CFG = {
    Project_Variables => {
        1 => {
            HOME         => $HOME,
            PROJECT_HOME => $PROJECT_HOME,
            site         => $site,
            spare_dir    => $spare_dir,
            date         => $date,
            component    => $component,
            line         => $line,
            subUser      => $subUser,
        }
    }
};

# print("2. System_Variables_config.pl,HOME=$CFG->{Project_Variables}{1}{HOME}\n");
