package App::SeismicUnixGui::misc::SeismicUnix;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: SeismicUnix.pm 
 AUTHOR: 	Juan Lorenzo
 DATE: 		earlier than 2018 

 DESCRIPTION 
     

 BASED ON:



=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 

=head2 CHANGES and their DATES

@ISA    = qw(Exporter); to our @ISA    = qw(Exporter);
@EXPORT_OK to our @EXPORT_OK
also commented @EXPORT=();
@EXPORT_OK to @EXPORT

    
=cut 

use Moose;
our $VERSION = '1.0.0';
use Exporter;  # Gain export capability
#use vars qw(@ISA @EXPORT @EXPORT_OK );    # pacify strict

=head2 declare

Global variables

=cut

our (@EXPORT_OK, @ISA); #Global variables
@ISA    = 'Exporter';  # Take advantage of Exporter's capabilities

# export all; import at will
@EXPORT_OK = qw($append $ascii $ascii_stdout $bin $cdp $CDP $SP
  $_cdp $_mute $_stkvel
  $day $ep $go $gx $hour $in $max_amp $minute $rms_amp 
  $gather_num_suffix $rms $max $second $surms_ notes $sumax_notes $on $off $true $false $isurf
  $_isurf $isurf_par_ $itemp_surf_picks_ $itemp_surf_num_points_ $itemp_surf_picks_sorted_
  $itemp_surf_picks_sorted_par_ $isurf_check_pickfile_ $isurf_pf_picks_ $isurf_pfile_picks
  $isurf_taufile_picks $ifft $_ifft $ifft_par_ $itemp_fft_picks_ $itemp_fft_num_points_
  $itemp_fft_picks_sorted_ $itemp_fft_picks_sorted_par_ $ifft_check_pickfile_ $ifft_xfile_picks
  $ifft_xfile_picks $ifft_tfile_picks $iSpectralAnalysisPickFile
  $ipicks $itemp_picks_
  $itemp_picks_sorted_
  $itemp_num_points $itemp_picks_sorted_par_
  $ibottom_mute_file_list $itop_mute_file_list
  $ipicks_par_ $ipick_check_pickfile_
  $itop_mute $_itop_mute
  $itop_mute_par_ $itemp_top_mute_picks_ $itemp_top_mute_picks_ttr_ $itemp_top_mute_num_points_
  $itemp_top_mute_num_points $itemp_top_mute_picks_sorted_ $itemp_top_mute_picks_sorted_
  $itemp_top_mute_picks_sorted_par_ $itop_mute_check_pickfile_ $itop_mute_xfile_picks
  $itop_mute_par
  $itop_mute_tfile_picks $ibot_mute $ibot_mute_par $ibot_mute_par_ $itemp_bot_mute_picks
  $itemp_bot_mute_picks_ $itemp_bot_mute_picks_taup_ $itemp_bot_mute_picks_ttr_
  $itemp_bot_mute_num_points $itemp_bot_mute_num_points_ $itemp_bot_mute_picks_sorted
  $itemp_bot_mute_picks_sorted_ $itemp_bot_mute_picks_sorted_par $itemp_bot_mute_picks_sorted_par_
  $ibot_mute_check_pickfile $ibot_mute_check_pickfile_ $ibot_mute_xfile_picks $ibot_mute_tfile_picks
  $temp_single_gather_par_file_mute  
  $mute
  $temp 
  $fldr
  $flip
  $ivpicks_sorted_par_
  $ms2s $us2s
  $offset 
  $pl 
  $profile 
  $ps $pick $report $target $target_tilde
  $DAT $dat $seg2 $segb $segd $sgd $segy $sgy $su $par $empty
  $start_time
  $suffix_DAT $suffix_dat $suffix_ascii $suffix_empty $suffix_par $suffix_text $suffix_bin $suffix_bot_mute $suffix_top_mute $suffix_fft $suffix_fp
  $suffix_geom $suffix_hyphen $suffix_isurf $suffix_lsu $suffix_mute $suffix_null 
  $suffix_ps $suffix_rev
  $suffix_segb $suffix_segd $suffix_sgd $suffix_segy $suffix_sgy $suffix_su $suffix_seg2 $suffix_taup $suffix_top_mute $suffix_usp $suffix_itop_mute
  $suffix_sac $suffix_txt $prefix_taup_picks_ $prefix_taup_picks $out 
  $suffix_target  $suffix_target_tilde $suffix_param $suffix_pick $suffix_profile $suffix_env $suffix_report $sx 
  $to_outpar_file
  $to $txt $text $tracf $tracl $tracr $trid $year
  $tmute $xmute 
  $velan );

# suffix_types
our $DAT  = 'DAT;';
our $dat  = 'dat';
our $seg2 = 'seg2';
our $su   = 'su';
our $segb = 'segb';
our $segd = 'segd';
our $sgd   = 'sgd';
our $segy = 'segy';
our $sgy  = 'sgy';
our $bin  = 'bin';
our	$empty = '';
our $par  = 'par';
our $text = 'text';

# SURFACE WAVE ANALYSIS
our $isurf                        = 'isurf';
our $_isurf                       = '_isurf';
our $isurf_par_                   = 'isurf_par_';
our $itemp_surf_picks_            = '.itemp_surf_picks_';
our $itemp_surf_num_points_       = '.itemp_surf_num_points_';
our $itemp_surf_picks_sorted_     = '.itemp_surf_picks_sorted_';
our $itemp_surf_picks_sorted_par_ = '.itemp_surf_picks_sorted_par_';
our $isurf_check_pickfile_        = '.isurf_pickfile_exists_';
our $isurf_pfile_picks            = 'isurf_pfile_picks';
our $isurf_taufile_picks          = 'isurf_taufile_picks';
our $isurf_pf_picks_              = 'isurf_pf_picks_';

# SUMUTING
our $itop_mute                        = 'itop_mute';
our $_itop_mute                       = '_itop_mute';
our $itop_mute_par_                   = 'itop_mute_par_';
our $itop_mute_par                    = 'itop_mute_par';
our $itemp_top_mute_picks_ttr_        = '.itemp_top_mute_picks_ttr_';
our $itemp_top_mute_picks_            = '.itemp_top_mute_picks_';
our $itemp_top_mute_num_points        = '.itemp_top_mute_num_points';
our $itemp_top_mute_picks_sorted_     = '.itemp_top_mute_picks_sorted_';
our $itemp_top_mute_picks_sorted_par_ = '.itemp_top_mute_picks_sorted_par_';
our $itop_mute_check_pickfile_        = '.itopmute_pickfile_exists_';
our $itop_mute_xfile_picks            = 'top_mute_xfile_picks';
our $itop_mute_tfile_picks            = 'top_mute_tfile_picks';
our $ibot_mute                        = 'ibot_mute';
our $ibot_mute_par_                   = 'ibot_mute_par_';
our $ibot_mute_par                    = 'ibot_mute_par_';
our $itemp_bot_mute_picks_            = '.itemp_bot_mute_picks_';
our $itemp_bot_mute_picks_taup_       = '.itemp_bot_mute_picks_taup_';
our $itemp_bot_mute_picks_ttr_        = '.itemp_bot_mute_picks_ttr_';
our $itemp_bot_mute_picks             = '.itemp_bot_mute_picks_';
our $itemp_bot_mute_num_points_       = '.itemp_bot_mute_num_points_';
our $itemp_bot_mute_num_points        = '.itemp_bot_mute_num_points_';
our $itemp_bot_mute_picks_sorted_     = '.itemp_bot_mute_picks_sorted_';
our $itemp_bot_mute_picks_sorted      = '.itemp_bot_mute_picks_sorted_';
our $itemp_bot_mute_picks_sorted_par_ = '.itemp_bot_mute_picks_sorted_par_';
our $itemp_bot_mute_picks_sorted_par  = '.itemp_bot_mute_picks_sorted_par_';
our $ibot_mute_check_pickfile_        = '.ibotmute_pickfile_exists_';
our $ibot_mute_check_pickfile         = '.ibotmute_pickfile_exists_';
our $ibot_mute_xfile_picks            = 'bot_mute_xfile_picks';
our $ibot_mute_tfile_picks            = 'bot_mute_tfile_picks';
our $mute                             = 'mute';
our $temp_single_gather_par_file_mute = '.temp_single_gather_par_file_mute';
our $temp                             = 'temp';
our $tmute							  = 'tmute';
our $xmute							  = 'xmute';

our $gather_numo_suffix = '_gather';

=head2 for iVelocityAnalysis


=cut

our $ivpicks_sorted_par_ = 'ivpicks_sorted_par_';
our $velan               = 'velan';

# FFT
our $ifft                        = 'ifft';
our $_ifft                       = '_ifft';
our $ifft_par_                   = 'ifft_par_';
our $itemp_fft_picks_            = '.itemp_fft_picks_';
our $itemp_fft_num_points_       = '.itemp_fft_num_points_';
our $itemp_fft_picks_sorted_     = '.itemp_fft_picks_sorted_';
our $itemp_fft_picks_sorted_par_ = '.itemp_fft_picks_sorted_par_';
our $ifft_check_pickfile_        = '.ifft_pickfile_exists_';
our $ifft_xfile_picks            = 'fft_xfile_picks';
our $ifft_tfile_picks            = 'fft_tfile_picks';

# iPicks
our $ipicks                  = 'ipicks';
our $ipick_check_pickfile_   = '.ipickfile_exists_';
our $ipicks_par_             = '.ipicks_par_';
our $itemp_picks_            = '.itemp_picks_';
our $itemp_num_points        = '.itemp_num_points';
our $itemp_picks_par_        = '.itemp_picks_par_';
our $itemp_picks_sorted_     = '.itemp_picks_sorted_';
our $itemp_picks_sorted_par_ = '.itemp_picks_sorted_par_';
our $ibottom_mute_file_list  = 'ibottom_mute_file_list';
our $itop_mute_file_list     = 'itop_mute_file_list';

#iSpectralAnalysis

our $iSpectralAnalysisPickFile = 'waveform';

our $append 		= ' >> ';
# used in sumax
our $ascii          = 'ascii';
our $ascii_stdout   = 'geom';
our $max            = 'max';
our $rms            = 'rms';
our $max_amp        = 'max_amp';
our $rms_amp        = 'rms_amp';
our $sumax_notes    = ("sumax: max amplitude");
our $surms_notes    = ("sumax: max amplitude");
our $to_outpar_file = 0;

our $off = 0;

our $on = 1;

our $true = 1;

our $false = 0;

#print("Array name is $$ref_key1_array[1]\n\n");

our $go = ' & ';

our $in = ' < ';

our $out = ' > ';

our $_cdp = '_cdp';

our $_mute = '_mute';

our $flip  = 'flip';

our $pick  = 'pick';

our $pl    = 'pl';

our $profile = 'profile';

our $ps		= 'ps';

our $report		= 'report';

our $_stkvel = '_stkvel';

our $suffix_ascii = '.asc';

our $suffix_bin = '.bin';

our $suffix_empty=	'';

our $suffix_par = '.par';

our $start_time = 'start_time';

our $suffix_bot_mute = '_bottom_mute';

our $suffix_env = '.env';

our $suffix_isurf = '_isurf';

our $suffix_itop_mute = '_itop_mute';

our $suffix_fft = '_fft';

#print("Array name is $$ref_key1_array[1]\n\n");

our $suffix_fp = '_fp';

our $suffix_geom = '_geom';

our $suffix_hyphen = '_';

our $suffix_lsu = '_lsu';

our $suffix_mute = '_mute';

our $suffix_rev = '_rev';

our $suffix_null = '';

our $suffix_ps	 = '.ps';

our $suffix_sac = '.sac';

our $suffix_segd = '.segd';

our $suffix_sgd = '.sgd';

our $suffix_seg2 = '.seg2';

our $suffix_segb = '.segb';

our $suffix_DAT = '.DAT';

our $suffix_dat = '.dat';

our $suffix_param = '.param';

our $suffix_pick = '.pick';

our $suffix_profile = '.profile';

our $suffix_report = '.report';

our $suffix_target = '.target';

our $suffix_target_tilde = '.target~';

our $suffix_segy = '.segy';

our $suffix_sgy = '.sgy';

our $suffix_su = '.su';

#print("Array name is $$ref_key1_array[1]\n\n");
our $suffix_taup = '_taup';

our $suffix_top_mute = '_top_mute';

our $suffix_usp = '.usp';

our $prefix_taup_picks_ = 'taup_picks_';

our $prefix_taup_picks = 'taup_picks';

our $suffix_txt = '.txt';

our $suffix_text = '.text';

our $target      	= 'target';

our $target_tilde	= 'target~';

# for unit conversion
our $ms2s = 1000;
our $us2s = 1000000;

# ENVIRONMENT VARIABLES FOR THIS PROJECT
# declare local arrays
my ( $ref_key1_array, $ref_key2_array );
my ( $num_rows,       $num_rows_key1 );
my ( @array_key1,     @array_key2 );
my @return_seconds;
my ( $i,               $array_list );
my ( $DATA_SEISMIC_SU, $TEMP_DATA_SEISMIC_SU );
my ( $ref_day,         $ref_hour, $ref_minute, $ref_sec );
my ( @ref_day,         @ref_hour, @ref_minute, @ref_sec );
my ($sugethw);
my ( @sugethw, @sugethw_sufile, @sugethw_outbound, @sugethw_inbound );

# SEGY HEADERS
our $cdp    = 'cdp';
our $CDP   = 'CDP';
our $SP     = 'SP';
our $ep     = 'ep';
our $fldr   = 'fldr';
our $day    = 'day';
our $gx     = 'gx';
our $hour   = 'hour';
our $minute = 'minute';
our $second = 'sec';
our $sx     = 'sx';
our $year   = 'year';
our $to     = ' | ';
our $offset = 'offset';
our $txt    = 'txt';
our $tracf  = 'tracf';
our $tracl  = 'tracl';
our $tracr  = 'tracr';
our $trid   = 'trid';

#sub start_time_s {
## extract start times from su files
## output is in seconds since the start of the year
#
#  use App::SeismicUnixGui::configs::big_streams::Project_config;
#  my $Project 					= Project_config->new();
#  my $DATA_SEISMIC_SU			= $Project->DATA_SEISMIC_SU();
#  my $TEMP_DATA_SEISMIC_SU		= $Project->TEMP_DATA_SEISMIC_SU();
#  my (@flow,@rm,@touch,$sugethw_sufile);
#
##  variables from function
## input is an array of file names
##
#      my $ref_key1_array		= shift @_;
#      my $num_rows_key1			= scalar (@$ref_key1_array);
#      my $start_time			= 'start_time';
#      my $day					= 'day';
#      my $hour					= 'hour';
#      my $minute				= 'minute';
#      my $sec					= 'sec';
#      my $ascii_stdout		    = 'geom';
#
#
#  #print("num_rows_key1 = $num_rows_key1 \n\n");
#
#
## SET VARIABLES: sugethw
# $sugethw_sufile[1]		= $start_time;
#
# $sugethw_outbound[1]		= $TEMP_DATA_SEISMIC_SU.'/'.$sugethw_sufile[1].$suffix_ascii;
## The following line is only to restrict the number
## of output files during testing
## $num_rows_key1		= 2;
# 	for (my $i=0; $i < $num_rows_key1; $i++) {
# 		$sugethw_inbound[$i]	= $DATA_SEISMIC_SU.'/'.$$ref_key1_array[$i];
# 			print("Array name is $$ref_key1_array[$i]\n\n");
#  	}
#
## DEFINE VARIABLES: sugethw
# 	$sugethw[1] = (" sugethw						\\
#		   	key=$day,$hour,$minute,$sec,laga  		\\
#		   	output=$ascii_stdout					\\
#	   	   	verbose=$false							\\
#			");
#
#			# DEFINE VARIABLES: rm
#			# create a fle if it does not exist
#
# 	$rm[1]		= (" rm								\\
#		  			");
#
#			# DEFINE VARIABLES: touch
# 	$touch[1]	= (" touch							\\
#		  			");
#
#
#			# DEFINE FLOW(s)
#  $flow[0]	= (" $rm[1] $sugethw_outbound[1];		\\
#		      $touch[1] $sugethw_outbound[1]		\\
#		  ");
#
#
#			# DEFINE FLOW(s)
#   for (my $i=0,my $j=1; $i < $num_rows_key1; $i++,$j++) {
#	 $flow[$j] =  (" $sugethw[1] 				\\
#			       < $sugethw_inbound[$i]		\\
#			       >> $sugethw_outbound[1]		\\
#			    ");
#   }
#
#
#		# RUN FLOW(S)
# system $flow[0];
#
#		# RUN FLOW(S)
#  	for (my $j=1; $j < ($num_rows_key1+1); $j++) {
#  		system $flow[$j];
#   	}
#
## LOG FLOWS
#  	for (my $j=0; $j < ($num_rows_key1 + 1); $j++) {
# 	 # 	system 'echo', $flow[$j];
#  	}
#
## READ ASCII FILE THAT CONTAINS DAY HOUR MINUTE SECOND
#  my ($ref_day,$ref_hour,$ref_minute,$ref_second,$ref_ms) = manage_files_by::read_5cols_p(\@sugethw_outbound);
#
# my $secs_in_hour   = 3600.;
# my $secs_in_day    = $secs_in_hour * 24.;
# my $secs_in_minute = 60.;
# my $secs_in_ms     = .001;
# my $num_rows       = scalar (@$ref_day);
# my @return_seconds;
#
# #print("rows=$num_rows\n\n");
# # uses perl convention of indexing arrays
# # from 0 onward
#
# for (my $i=0; $i < $num_rows; $i++) {
#  #print(" day=$$ref_day[$i]\n\n");
#	$return_seconds[$i] = ($$ref_day[$i]    -1) * $secs_in_day    +
#			      ($$ref_hour[$i]     ) * $secs_in_hour   +
#			      ($$ref_minute[$i]   ) * $secs_in_minute +
#			      ($$ref_second[$i]) +
#                              ($$ref_ms[$i])        * $secs_in_ms;
#  }
#
## RETURN CALCULATION
# 	return (\@return_seconds);
#}
#
#
#sub suwind {
#
#     my $trid  = 'trid';
#     return ($trid);
#
#}
#
1;
