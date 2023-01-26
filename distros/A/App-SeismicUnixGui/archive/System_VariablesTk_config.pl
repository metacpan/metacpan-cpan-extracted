#!/usr/bin/perl  -w
#
package System_VariablesTk_config;

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
my $cfg = new Config::Simple('Project_Variables.config');
my @CFG;

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

  print("home is $CFG[2]\n\n");

=cut 

my $number_of_param = 8;

$CFG[1]  = "HOME";
$CFG[3]  = "PROJECT_HOME";
$CFG[5]  = "site";
$CFG[7]  = "spare_dir";
$CFG[9]  = "date";
$CFG[11] = "component";
$CFG[13] = "line";
$CFG[15] = "subUser";
$CFG[2]  = $cfg->param("HOME");
$CFG[4]  = $cfg->param("PROJECT_HOME");
$CFG[6]  = $cfg->param("site");
$CFG[8]  = $cfg->param("spare_dir");
$CFG[10] = $cfg->param("date");
$CFG[12] = $cfg->param("component");
$CFG[14] = $cfg->param("line");
$CFG[16] = $cfg->param("subUser");

return ( \@CFG );

1;

