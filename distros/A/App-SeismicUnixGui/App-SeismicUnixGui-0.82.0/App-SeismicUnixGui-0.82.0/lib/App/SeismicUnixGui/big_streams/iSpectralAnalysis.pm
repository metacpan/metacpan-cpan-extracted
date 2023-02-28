package App::SeismicUnixGui::big_streams::iSpectralAnalysis;

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: iSpectralAnalysis.pm
  Purpose: Simple viewing of an su file 
           extract waveforms an analysze in the spectral domain  
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    Aigust 1 2016 V1.
  DESCRIPTION:  based upon non-oop Xtract.pl  

=head2 NOTES 

 We are using Moose 
 Moose already declares that you need debuggers turned on
 so you don't need a line like the following:

 use warnings;
 
=head2 USES

 (for subroutines) 
     System_Variables (for subroutines)

     (for variable definitions)
     SeismicUnix (Seismic Unix modules)


=head3 STEPS IN THE PROGRAM 


=head2  REQUIRES

   /usr/local/pl/iSpectralAnalysis.pl to bring configuration values (TODO)
  configuration file is local (~/iSpectralAnalysis.config)

=head2  USED by

   /usr/local/pl/iSA (Tk control) to interact with user (TODO)

=cut

use Moose;
our $VERSION = '1.0.0';
use aliased 'App::SeismicUnixGui::configs::big_streams::iSpectralAnalysis_config';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $off $suffix_su $iSpectralAnalysisPickFile);
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::misc::su_xtract_waveform';
use aliased 'App::SeismicUnixGui::misc::su_select_waveform';
use aliased 'App::SeismicUnixGui::misc::su_spectral_analysis';

=head2

  1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish

     Use classes:
     flow
     log
     message
     readfiles 
     su_xtract_waveform
     su_select_waveform
     su_spectral_analysis
     
=cut

my $iSpectralAnalysis_config = iSpectralAnalysis_config->new();
my $log                      = message->new();
my $Project                  = Project_config->new();
my $run                      = flow->new();
my $read                     = readfiles->new();
my $xtract                   = su_xtract_waveform->new();
my $select                   = su_select_waveform->new();
my $analyze                  = su_spectral_analysis->new();
my $get                      = L_SU_global_constants->new();
my $var                      = $get->var();
my ($DATA_SEISMIC_SU)        = $Project->DATA_SEISMIC_SU();

=head2

  3. Declare local variables 

=cut

my ( @flow, @file_in, @sufile_in, @xtract_sufile, @sufile_out );
my ( @inbound, @outbound );
my (@items);
my ( @read, @xtract, @select, @analyze );
my ($ref_flows);
my $picks_file;

$picks_file = $iSpectralAnalysisPickFile;

# print("iSpectralAnalysis, picks file is $picks_file\n\n");

=head2 Get configuration information


=cut

my ( $CFG_h, $CFG_aref ) = $iSpectralAnalysis_config->get_values();

my $base_file_name = $CFG_h->{base_file_name};
my $freq           = $CFG_h->{sufilter}{1}{freq};
my $agc_gain_width = $CFG_h->{sugain}{1}{agc_gain_width};
my $absclip        = $CFG_h->{suxwigb}{1}{absclip};
my $headerWord     = $CFG_h->{suxwigb}{1}{headerWord};
my $absclip_phase  = $CFG_h->{suxwigb}{1}{absclip_phase};
my $absclip_freq   = $CFG_h->{suxwigb}{1}{absclip_freq};

# print ("iSpectralAnalysis,freq is $freq\n\n");
# print ("iSpectralAnalysis,base_file_name is $base_file_name\n\n");
# print("iSpectralAnalysis,absclip is $absclip\n\n");

=head2 Declare

   file names 

=cut

$file_in[1]   = $base_file_name;
$sufile_in[1] = $file_in[1] . $suffix_su;
$inbound[1]   = $DATA_SEISMIC_SU . '/' . $sufile_in[1];

=head2 sub SELECT 

 waveform

=cut

sub select {

    $select->clear();
    $select->picks_file($picks_file);
    $select->inbound( $inbound[1] );
    $select->window_title( $file_in[1] );
    $select->title( $file_in[1] );
    $select->absclip($absclip);

=head3 Set

  filtering parameters 

=cut

    $select->filter_freq($freq);
    $select->agc_gain_width($agc_gain_width);
    $ref_flows = $select->Step();

=head2 View waveform in suxwimage

   then pick in suxwigb   

=cut

    $select[1] = @$ref_flows[1];
    $select[2] = @$ref_flows[2];

=head2 DEFINE FLOW(S)

=cut

    $flow[1] = $select[1];
    $flow[2] = $select[2];

=head2

  RUN FLOW(S)
  flow 3 should not run until flow 
  is completed

=cut

    $run->flow( \$flow[1] );
    $run->flow( \$flow[2] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    # print  "iSpectralAnalysis, flow1= $flow[1]\n";
    # $log->file($flow[1]);

    # print  "iSpectralAnalysis,flow2= $flow[2]\n";
    # $log->file($flow[2]);

}

=head2 sub xtract

 waveform to a file and QC the waveform
 flow 3 saves a copy of the file to disk

=cut

sub xtract {

=head2 Prepare 

  to Extract waveform

=cut

    $xtract->clear();
    $xtract->ref_picks_file( \$picks_file );
    $xtract->header_word($headerWord);    # critical
    $xtract->inbound( $inbound[1] );
    $xtract->window_title( $file_in[1] );
    $xtract->absclip($absclip);

    $xtract_sufile[1] = $xtract->file_out( \$picks_file, $inbound[1] );
    $ref_flows        = $xtract->Step();
    $xtract[1]        = $$ref_flows[1];
    $flow[3]          = $xtract[1];

    $run->flow( \$flow[3] );

=head2 LOG FLOW(S)

  TO SCREEN AND FILE

=cut

    print "$flow[3]\n";

    #$log->file($flow[3]);

}

=head2 Spectral Analysis of Waveform

 do not start flow 4 until 
 flow 3 is complete

 flow 4 plots the extracted waveform 
 flow 5 plots the frequency analysis
 flow 6 plots the phase analysis 

 We placed a cmd line
 prompt that requires user to press
 return on keyboard.

=cut

sub analyze {

=head2 Prepare 

  to Analyze extracted waveform

=cut

    my $inbound = $DATA_SEISMIC_SU . '/' . $xtract_sufile[1];
    $analyze->clear();
    $analyze->inbound($inbound);
    $analyze->window_title( $file_in[1] );
    $analyze->absclip_phase($absclip_phase);
    $analyze->absclip_freq($absclip_freq);

    $ref_flows  = $analyze->Step();
    $analyze[1] = $$ref_flows[1];
    $analyze[2] = $$ref_flows[2];
    $analyze[3] = $$ref_flows[3];

    $flow[4] = $analyze[1];
    $flow[5] = $analyze[2];
    $flow[6] = $analyze[3];

    $run->flow( \$flow[4] );
    $run->flow( \$flow[5] );
    $run->flow( \$flow[6] );

=head2 LOG FLOW(S)

  TO SCREEN AND FILE

=cut

    # print  "$flow[4]\n";
    #$log->file($flow[4]);

    # print  "$flow[5]\n";
    #$log->file($flow[5]);

    # print  "$flow[6]\n";
    #$log->file($flow[6]);
    #
}
