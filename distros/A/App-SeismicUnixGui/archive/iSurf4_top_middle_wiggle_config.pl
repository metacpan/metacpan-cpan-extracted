#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: suxwigb_config.pl 
 AUTHOR: Juan Lorenzo
 DATE:  January 26 2017 
 DESCRIPTION  Incorporate upper-level variable
      definitions for suxwigb 
      
 Package name is the same as the file name

=cut

=head2 Notes 

=cut 

=head2 EXPORT GLOBAL VARIABLES
   
  to suxwigb 

=cut 

use Moose;
use Config::Simple;

my $cfg = new Config::Simple('/usr/local/pl/iSurf4_top_middle_wiggle.config');
use App::SeismicUnixGui::configs::big_streams::Project_config;
my $Project = Project_config->new();
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
our $CFG;

=head2 anonymous array reference is CFG

 contains all the configuration variables in
 perl script

=cut

=head2 LOCAL VARIABLES 

 taken from the file called:

  /usr/local/pl/suxwigb.config

=cut

=head2   WIGGLE PLOT of SEISMIC UNIX DATA FILES 

  set plotting paramters 
 print("xlabel is $suxwigb_xlabel\n\n");

=cut

my $suxwigb_windowtitle = $cfg->param("windowtitle");
my $suxwigb_box_X0      = $cfg->param("box_X0");
my $suxwigb_box_Y0      = $cfg->param("box_Y0");
my $suxwigb_box_height  = $cfg->param("box_height");
my $suxwigb_box_width   = $cfg->param("box_width");
my $suxwigb_xlabel      = $cfg->param("xlabel");
my $suxwigb_ylabel      = $cfg->param("ylabel");

$CFG = {
    suxwigb => {
        1 => {
            windowtitle => quotemeta($suxwigb_windowtitle),
            box_X0      => $suxwigb_box_X0,
            box_Y0      => $suxwigb_box_Y0,
            box_height  => $suxwigb_box_height,
            box_width   => $suxwigb_box_width,
            xlabel      => quotemeta($suxwigb_xlabel),
            ylabel      => quotemeta($suxwigb_ylabel)
        }
    }
};

