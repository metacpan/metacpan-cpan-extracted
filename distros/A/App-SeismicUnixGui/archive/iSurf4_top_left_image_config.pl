#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: suximage_config.pl 
 AUTHOR: Juan Lorenzo
 DATE:  January 26 2017 
 DESCRIPTION  Incorporate upper-level variable
      definitions for suximage 
      
 Package name is the same as the file name

=cut

=head2 Notes 

=cut 

=head2 EXPORT GLOBAL VARIABLES
   
  to suximage 

=cut 

use Moose;
use Config::Simple;

my $cfg = new Config::Simple('/usr/local/pl/iSurf4_top_left_image.config');
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

  /usr/local/pl/suximage.config

=cut

=head2   WIGGLE PLOT of SEISMIC UNIX DATA FILES 

  set plotting paramters 
 print("xlabel is $suximage_xlabel\n\n");

=cut

my $suximage_windowtitle = $cfg->param("windowtitle");
my $suximage_box_X0      = $cfg->param("box_X0");
my $suximage_box_Y0      = $cfg->param("box_Y0");
my $suximage_box_height  = $cfg->param("box_height");
my $suximage_box_width   = $cfg->param("box_width");
my $suximage_xlabel      = $cfg->param("xlabel");
my $suximage_ylabel      = $cfg->param("ylabel");

$CFG = {
    suximage => {
        1 => {
            windowtitle => quotemeta($suximage_windowtitle),
            box_X0      => $suximage_box_X0,
            box_Y0      => $suximage_box_Y0,
            box_height  => $suximage_box_height,
            box_width   => $suximage_box_width,
            xlabel      => quotemeta($suximage_xlabel),
            ylabel      => quotemeta($suximage_ylabel)
        }
    }
};

