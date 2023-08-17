package App::SeismicUnixGui::big_streams::iVA;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iVA.pm 
 AUTHOR: Juan Lorenzo
 DATE:   Nov 1 2012,
         sept. 13 2013
         oct. 21 2013
         July 15 2015
         Aug 18 2016
         Jan 7 2017

 DESCRIPTION: 
 Version: 1.0
 Package used for interactive velocity analysis
 Version 1.0.1 separates graphics from calculations
 Version 1.0.2 removes dependency on Config-Simple
 Version 1.0.3 considers scaleco or scalel in header

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES

Jan 13 2020 Version 1.0.3
_get_data_scale is now calculated internally
data_scale parameter removed from gui


=cut

=head2 STEPS

=cut

=head2

set defaults

VELAN DATA 
 m/s
 
=cut

=head2 import and then

 instantiate iclasses

=cut

use Moose;
our $VERSION = '1.0.3';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::big_streams::iSunmo';
use aliased 'App::SeismicUnixGui::configs::big_streams::iVA_config';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::big_streams::iSuvelan';
use aliased 'App::SeismicUnixGui::big_streams::iWrite_All_iva_out';
use aliased 'App::SeismicUnixGui::big_streams::iVpicks2par';
use aliased 'App::SeismicUnixGui::big_streams::iVrms2Vint';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use aliased 'App::SeismicUnixGui::sunix::shell::xk';
use aliased 'App::SeismicUnixGui::sunix::header::header_values';

=head2 establish hash of shared variables

=cut 

my $iVA = {
	_anis1  			  => '',
	_anis2  			  => '',	
	_cdp_last             => '',
	_cdp_first            => '',
	_cdp_num              => '',
	_cdp_num_suffix       => '',
	_cdp_inc              => '',
	_data_scale           => '',
	_dtratio      		  => '',
	_dt_s                 => '',
	_base_file_name       => '',
	_freq                 => '',
	_instructions         => '',
	_min_semblance        => '',
	_max_semblance        => '',
	_message_type         => 'iva',
	_next_step            => '',
	_nsmooth  			  => '',
	_number_of_tries      => '',
	_number_of_velocities => '',
	_old_data             => '',
	_pwr				  => '',
	_smute  			  => '',
	_tmax_s               => '',
	_Tvel_inbound         => '',
	_Tvel_outbound        => '',
	_textfile_in          => '',
	_textfile_out         => '',
	_type                 => '',
	_velocity_increment   => '',
	_velocity_min         => '',
	_velocity_max         => '',
};

=head2 Instantiate classes:

 Option to create a new version of the package 
 with a unique name

=cut

my $read    = readfiles->new();
my $control = control->new();

my $suxwigb            = suxwigb->new();
my $semblance          = iSuvelan->new();
my $iWrite_All_iva_out = iWrite_All_iva_out->new();
my $iVpicks2par        = iVpicks2par->new();
my $iVrms2Vint         = iVrms2Vint->new();
my $test               = manage_files_by2->new();
my $SuMessages         = SuMessages->new();
my $iSunmo             = iSunmo->new();
my $get                = L_SU_global_constants->new();
#my $global_libs        = $get->global_libs();
my $Project            = Project_config->new();
my $iVA_config         = iVA_config->new();
my $xk                 = xk->new();

=head2 Import Special Variables

=cut

my $var          = $get->var();
my $empty_string = $var->{_empty_string};


=head2 Get configuration information
from gui

=cut 

my ( $CFG_h, $CFG_aref ) = $iVA_config->get_values();

$iVA->{_base_file_name} = $CFG_h->{iva}{1}{base_file_name};
$iVA->{_cdp_first}      = $CFG_h->{iva}{1}{cdp_first};
$iVA->{_cdp_inc}        = $CFG_h->{iva}{1}{cdp_inc};
$iVA->{_cdp_last}       = $CFG_h->{iva}{1}{cdp_last};
$iVA->{_tmax_s}         = $CFG_h->{iva}{1}{tmax_s};

$iVA->{_dt_s}                 	= $CFG_h->{iva}{1}{dt_s};
$iVA->{_freq}                 	= $CFG_h->{iva}{1}{freq};
$iVA->{_first_velocity}       	= $CFG_h->{iva}{1}{first_velocity};
$iVA->{_min_semblance}        	= $CFG_h->{iva}{1}{min_semblance};
$iVA->{_max_semblance}        	= $CFG_h->{iva}{1}{max_semblance};
$iVA->{_number_of_velocities} 	= $CFG_h->{iva}{1}{number_of_velocities};
$iVA->{_velocity_increment}   	= $CFG_h->{iva}{1}{velocity_increment};
$iVA->{_anis1}   				= $CFG_h->{iva}{1}{anis1};
$iVA->{_anis2}   				= $CFG_h->{iva}{1}{anis2};
$iVA->{_dtratio}   				= $CFG_h->{iva}{1}{dtratio};
$iVA->{_nsmooth}   				= $CFG_h->{iva}{1}{nsmooth};
$iVA->{_smute}   				= $CFG_h->{iva}{1}{smute};
$iVA->{_pwr}   					= $CFG_h->{iva}{1}{pwr};

# remove ticks at the start and end of base_file_names
$control->set_infection( $iVA->{_base_file_name} );
$iVA->{_base_file_name} = $control->get_ticksBgone();

# remove ticks at the start and end of freqquncy series
$control->set_infection( $iVA->{_freq} );
$iVA->{_freq} = $control->get_ticksBgone();

# print("1. iVA, file name --without su extension -- is $iVA->{_base_file_name}\n\n");

# get data scale from headers of the sunix data file
$iVA->{_data_scale} = _get_data_scale();

=head2 

 VELAN DATA 
 must be in units of: m/s
 must seed first cdp

 Set the type of messages you will receive
 for now it also sets the CDP number to use
 so keep it after setting cdp numbers

=cut

=head2

 Import directory definitions

=cut 

my ($PL_SEISMIC) = $Project->PL_SEISMIC();

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
	$iVA->{_anis1}                = '';
	$iVA->{_anis2}                = '';
	$iVA->{_cdp_num}              = '';
	$iVA->{_cdp_first}            = '';
	$iVA->{_cdp_last}             = '';
	$iVA->{_cdp_inc}              = '';
	$iVA->{_data_scale}           = '';
	$iVA->{_dtratio}              = '';
	$iVA->{_dt_s}                 = '';
	$iVA->{_base_file_name}       = '';
	$iVA->{_freq}                 = '';
	$iVA->{_instructions}         = '';
	$iVA->{_min_semblance}        = '';
	$iVA->{_max_semblance}        = '';
	$iVA->{_message_type}         = '';
	$iVA->{_next_step}            = '';
	$iVA->{_nsmooth}              = '';
	$iVA->{_number_of_tries}      = '';
	$iVA->{_number_of_velocities} = '';
	$iVA->{_old_data}             = '';
	$iVA->{_smute}                = '';
	$iVA->{_pwr}              	   = '';
	$iVA->{_test}                 = '';
	$iVA->{_tmax_s}               = '';
	$iVA->{_Tvel_inbound}         = '';
	$iVA->{_Tvel_outbound}        = '';
	$iVA->{_velocity_min}         = '';
	$iVA->{_velocity_max}         = '';
	$iVA->{_velocity_increment}   = '';
}

=head2 sub _get_data_scale

get scalco or scalel from file header

=cut

sub _get_data_scale {
	my ($self) = @_;

=head2 instantiate class

=cut

	my $header_values = header_values->new();

	if ( defined $iVA->{_base_file_name}
		&& $iVA->{_base_file_name} ne $empty_string )
	{
		$header_values->set_base_file_name( $iVA->{_base_file_name} );
		$header_values->set_header_name('scalel');
		my $data_scale = $header_values->get_number();
		
		my $result     = $data_scale;
		# print("2. iVA, _get_data_scale, data_scale = $data_scale\n");
		return($result);
		
	} else {
		
		my $data_scale = 1;
		my $result     = $data_scale;
		# print("iVA, _get_data_scale, data_scale = 1:1\n");
		return ($result);
		
	}
}


=head2 subroutine  set_message

  define the message family to use
  alsoset the cdp nuber (TODO: move option elsewhere)

=cut

sub set_message {
	my ( $variable, $type ) = @_;
	$iVA->{_message_type} = $type if defined($type);

	#print("message type is $iVA->{_message_type}\n\n");
	$SuMessages->set( $iVA->{_message_type} );
	$SuMessages->cdp_num( $iVA->{_cdp_num} );

}

=head2 subroutine  message

  instructions 

=cut

sub _message {
	my ($instructions) = @_;

	if ($instructions) {
		$iVA->{_instructions} = $instructions
		  if defined($instructions);
		$SuMessages->instructions( $iVA->{_instructions} );

		#print("Instructions are $iVA->{_instructions} \n\n");
	}
}

=head2 

 subroutine TV pick file out

=cut

sub refresh_Tvel_outbound {
	$iVA->{_textfile_out} =
	  'ivpicks_' . $iVA->{_base_file_name} . $iVA->{_cdp_num_suffix};
	$iVA->{_Tvel_outbound} = $PL_SEISMIC . '/' . $iVA->{_textfile_out};

	#print("output file is $iVA->{_Tvel_outbound} \n\n");
}

=head2 

 subroutine TV pick file in 

=cut

sub refresh_Tvel_inbound {
	$iVA->{_textfile_in} =
	  'ivpicks_old' . '_' . $iVA->{_base_file_name} . $iVA->{_cdp_num_suffix};
	$iVA->{_Tvel_inbound} = $PL_SEISMIC . '/' . $iVA->{_textfile_in};
}

=head2 look for old data

  There is an old pick file to read
  textfile_in: ivpicks_old
  Requires knowing current cdp number
  becaus we are at the start of the process
  we will provide the lowest cdp as an indicator
  TODO: check all old cdp data files before going on
     to subsequent analyses

=cut

sub old_data {
	my ( $variable, $old_data ) = @_;
	my $ans;

	# print("variable and old_data $variable, $old_data\n\n");
	#switches old data of velan type
	if ($old_data) {
		$iVA->{_type} = $old_data;
		if ( $iVA->{_type} eq 'velan' ) {

			cdp_num( $iVA->{_cdp_first} );
			cdp_num_suffix( $iVA->{_cdp_num} );

			$iVA->{_textfile_in} =
			    'ivpicks_old' . '_'
			  . $iVA->{_base_file_name}
			  . $iVA->{_cdp_num_suffix};

			if ($PL_SEISMIC) {
				$iVA->{_Tvel_inbound} =
				  $PL_SEISMIC . '/' . $iVA->{_textfile_in};
				$ans = $test->does_file_exist( \$iVA->{_Tvel_inbound} );

				if (   $iVA->{_base_file_name}
					&& $iVA->{_cdp_num_suffix} )
				{
					$iVA->{_textfile_out} =
					    'ivpicks_'
					  . $iVA->{_base_file_name}
					  . $iVA->{_cdp_num_suffix};
					$iVA->{_Tvel_outbound} =
					  $PL_SEISMIC . '/' . $iVA->{_textfile_out};
				}
			}

			# print("TV in is $iVA->{_Tvel_inbound}\n\n");
			#print("TV out is $iVA->{_Tvel_outbound}\n\n");

			if ($ans) {
				
# TODO put a message into the gui
#				use App::SeismicUnixGui::messages::message_director;
#				
#=head2 sub set_hash_ref
#
#	copies with simplified names are also kept (40) so later
#	the hash can be returned to a calling module
#	
#	imports external hash into private settings via gui_history 
#	accessory
#
#print("color_flow,set_hash_ref,hash_ref->{_log_view}: $ans\n");
#my $ans = $gui_history->get_log_view();
#print("2. color_flow,set_hash_ref: gui_history->get_log_view:$ans \n");
# 	
#=cut
#
#sub set_hash_ref {
#	my ( $self, $hash_ref ) = @_;
#
#	$gui_history->set_defaults($hash_ref);
#	$color_flow_href = $gui_history->get_defaults();
#
#	# REALLY?
#	# set up param_widgets for later use
#	# give param_widgets the needed values
#	$param_widgets->set_hash_ref($color_flow_href);
#
#	$flow_color = $color_flow_href->{_flow_color};
#
#	# $gui_history_aref = $color_flow_href->{_gui_history_aref};
#
#	# for local use
#	$last_flow_color               = $color_flow_href->{_last_flow_color};                 # used in flow_select
#	$message_w                     = $color_flow_href->{_message_w};
#	$parameter_values_frame        = $color_flow_href->{_parameter_values_frame};
#	$parameter_values_button_frame = $color_flow_href->{_parameter_values_button_frame};
#
#	# $sunix_listbox                 = $color_flow_href->{_sunix_listbox};
#
#	# print("color_flow, set_hash_ref _check_buttons_settings_aref: @{$color_flow_href->{_check_buttons_settings_aref}}\n");
#
#	# print("color_flow,set_hash_ref: print gui_history->view\n");
#	# $gui_history->view();
#
#	return ();
#}		
#				my $message_w;
#					$message_w                     = $color_flow_href->{_message_w};
#				my $iva_messages = message_director->new();
#				my $message = $color_flow_messages->null_button(0);
#				$message_w->delete( "1.0", 'end' );
#				$message_w->insert( 'end', $message );

				print("Old picks already exist.\n");
				print("Delete \(\"rm -rf \*old\*\"\) or, \n");
				print("Save old picks (in: $PL_SEISMIC), and then restart\n\n");
				exit;
			}
			return ($ans);
		}

	}
}

=head2 subroutine cdp

  sets cdp number to consider and is used only 
  by sub start 

=cut

sub cdp_num {
	my ($cdp_num) = @_;
	$iVA->{_cdp_num} = $cdp_num if defined($cdp_num);

	#print("cdp_num is $cdp_num\n\n");
}

=head2 subroutine cdp_num_suffix

  sets cdp number suffix to consider 
  used by subs start and next

=cut

sub cdp_num_suffix {
	my ($cdp_num) = @_;
	if ($cdp_num) {
		$iVA->{_cdp_num_suffix} = '_cdp' . $cdp_num;

		#print("cdp_num suffix in iVA.pm is $iVA->{_cdp_num_suffix}\n\n");
	}
}

=head2 subroutine start 

  sets first cdp  to use internally
    and display in the messages 
  sets the type of messages to relay
  sets the counter for attempts at velocity
  analysis for a particular cdp

=cut

sub start {

	print("NEW PICKS\n");
	set_message( $iVA->{_message_type} );
	$SuMessages->cdp_num( $iVA->{_cdp_first} );

	cdp_num( $iVA->{_cdp_first} );
	cdp_num_suffix( $iVA->{_cdp_first} );

	# print("cdp_num_suffix is $iVA->{_cdp_num_suffix}\n\n");
	_message('first_velan');
	$iVA->{_number_of_tries} = 0;
	semblance();

}

=head2 subroutine pick
 
  Picking data
  send cdp number to subroutine 
  update cdp_num_suffix
  and update the Tvel_outbound.
  delete output of previous semblance
  
    -replot 1st semblance
    -PICK V-T pairs
    -Increment number of tries.
     Semblance display becomes interactive
     when number_of_tries >= 1
     Because display blocks flow,
     place message before semblance
     
=cut

sub pick {

	print("Picking...cdp $iVA->{_cdp_num}\n");
	print("NOW, PICK\n\n");
	cdp_num_suffix( $iVA->{_cdp_num} );
	refresh_Tvel_inbound();
	refresh_Tvel_outbound();

	#$xk->kill_this('suximage');
	#$xk->kill_this('suxwigb');
	_message('pre_pick_velan');
	$iVA->{_number_of_tries}++;
	semblance();

}

=head2 sub next

  1. increment cdp
     update variable variables
        (cdp_num_suffix, Tvel_inbound and Tvel_outbound)
     Exit if beyond last cdp 
  2. reset prompt
     reset the number of tries to zero again
  3. Otherwise display the first semblance
    -Based on semblance,
      decide whether to PICK or move on to NEXT CDP
     -radio_buttons stop flow

   delete output of previous semblance
   delete the output of semblance and iSunmo
   delete the output of Vrms2Vint 

=cut

sub next {

	$iVA->{_cdp_num} = $iVA->{_cdp_num} + $iVA->{_cdp_inc};
	cdp_num_suffix( $iVA->{_cdp_num} );
	refresh_Tvel_inbound();
	refresh_Tvel_outbound();
	$iVA->{_number_of_tries} = 0;

	#print("Next CDP_NUM IS $iVA->{_cdp_num}");

	#$xk->kill_this('suximage');
	#$xk->kill_this('suxwigb');
	#$xk->kill_this('xgraph');
	if ( $iVA->{_cdp_num} > $iVA->{_cdp_last} ) {
		exit();
	}

	semblance();
	$SuMessages->cdp_num( $iVA->{_cdp_num} );
	_message('first_velan');

}

=head2 subroutine exit

=cut

sub exit {

	print("Good bye.\n");
	print("Not continuing to next cdp\n");
	$xk->kill_this('suximage');
	$xk->kill_this('suxwigb');
	$xk->kill_this('xgraph');
	exit(1);

}

=head2 Calculate NMO 

    0. Message to user
    1. delete the output of previous semblance 
    2. calculations
    3. message is needed because semblance halts flow
       when number_of_tries >0

=cut

sub calc {

#	 print("iVA, calc, Calculating...\n");

	#$xk->kill_this('suximage');
	#$xk->kill_this('suxwigb');
	_iWrite_All_iva_out();
	_iVrms2Vint();
	_icp_sorted2oldpicks();
	_iVpicks2par();
	# print("iVA, calc, Calculating...\n");
	_iSunmo();
	$iVA->{_number_of_tries}++;
	_message('post_pick_velan');
	semblance();

}

=head2

 subroutine icp_sorted_2_old_picks
 When user wants to recheck the data  velocity_increment
 this subroutine will allow the user to recheck  using an old sorted file
 Juan M. Lorenzo
 Jan 10 2010

    input file is ivpicks_sorted
    output pick file 
    text file out: ivpicks_old 


=cut 

sub _icp_sorted2oldpicks {

	my ( @cdp_num,     @sorted_suffix, @suffix );
	my ( @sufile_in,   @vpicks_in,     @vpicks_out );
	my ( @sortfile_in, @inbound,       @outbound );
	my (@writefile_out);
	my (@flow);

	$cdp_num[1] = $iVA->{_cdp_num};

	# suffixes
	$sorted_suffix[1] = '_sorted';
	$suffix[3]        = '_cdp' . $iVA->{_cdp_num};

	# su file names
	$sufile_in[1] = $iVA->{_base_file_name};    # any itnernal ticks removed

	#V file names
	$vpicks_in[1]  = 'ivpicks_old' . $sorted_suffix[1];
	$vpicks_out[1] = 'ivpicks_old';

	# sort file names
	$sortfile_in[1] = $vpicks_in[1];
	$inbound[1] =
	  $PL_SEISMIC . '/' . $sortfile_in[1] . '_' . $sufile_in[1] . $suffix[3];

	# Velocity write file names
	$writefile_out[1] = $vpicks_out[1];
	$outbound[1] =
	  $PL_SEISMIC . '/' . $writefile_out[1] . '_' . $sufile_in[1] . $suffix[3];

	#  DEFINE FLOW(S)
	$flow[1] = (
		" 						\\
		cp 	 							\\
		 $inbound[1] 					\\
		 $outbound[1]					\\
		"
	);

	# RUN FLOW(S)
	system $flow[1];

	# system 'echo', $flow[1];
	#end of copy of Vrms old picks sorted to ivpicks_old
}

=head2 sub _iVrms2Vint

 Purpose: Convert Vrms to Vinterval  
 Juan M. Lorenzo
 April 7 2009 
 Nov. 19 2013

=cut

sub _iVrms2Vint {

	$iVrms2Vint->first_velocity( $iVA->{_first_velocity} );
	$iVrms2Vint->number_of_velocities( $iVA->{_number_of_velocities} );
	$iVrms2Vint->velocity_increment( $iVA->{_velocity_increment} );
	$iVrms2Vint->file_in( $iVA->{_base_file_name} );
	$iVrms2Vint->cdp_num( $iVA->{_cdp_num} );
	$iVrms2Vint->tmax_s( $iVA->{_tmax_s} );
	$iVrms2Vint->calcNdisplay();

}

=head2 sub iVpicsk2par_Vpicks

 Purpose: Prepare velocity picks for
 input to Sunmo 
 Interactive mode
 Juan M. Lorenzo
 April 7 2009
 Adapted from Forel and Pennington's iva.sh script
 Nov 19 2013

=cut

sub _iVpicks2par {
	
	my ($self) = @_;

	$iVpicks2par->file_in( $iVA->{_base_file_name} )
	  ;    # only if internal ticks have been removed
	$iVpicks2par->cdp_num( $iVA->{_cdp_num} );
	$iVpicks2par->flows();

}

sub _iSunmo {
	
	my ($self) = @_;
	
	print(" iVA, _iSunmo base_file_name=$iVA->{_base_file_name}\n\n");
	
	$iSunmo->file_in( $iVA->{_base_file_name} );
	$iSunmo->cdp_num( $iVA->{_cdp_num} );
	$iSunmo->freq( $iVA->{_freq} );
	$iSunmo->tmax_s( $iVA->{_tmax_s} );
	$iSunmo->calcNdisplay();

}

=head2 sub semblance

 Purpose: Generate Velocity Analysis 
          and Plot the results 

=cut

sub semblance {

	# print(" running semblance\n");
	# print(" iVA, semblance, number of tries is $iVA->{_number_of_tries}\n\n");

	$semblance->clear();
	$semblance->cdp_num( $iVA->{_cdp_num} );
	$semblance->cdp_num_suffix( $iVA->{_cdp_num} );
	$semblance->file_in( $iVA->{_base_file_name} );
	$semblance->set_data_scale( $iVA->{_data_scale} );
	$semblance->dt_s( $iVA->{_dt_s} );
	$semblance->tmax_s( $iVA->{_tmax_s} );
	$semblance->first_velocity( $iVA->{_first_velocity} );
	$semblance->freq( $iVA->{_freq} );
	$semblance->max_semblance( $iVA->{_max_semblance} );
	$semblance->min_semblance( $iVA->{_min_semblance} );
	$semblance->number_of_tries( $iVA->{_number_of_tries} );
	$semblance->number_of_velocities( $iVA->{_number_of_velocities} );
	$semblance->set_anis1($iVA->{_anis1} );
	$semblance->set_anis2($iVA->{_anis2} );
	$semblance->set_smute($iVA->{_smute} );
	$semblance->set_dtratio($iVA->{_dtratio} );
	$semblance->set_nsmooth($iVA->{_nsmooth} );
	$semblance->set_pwr($iVA->{_pwr} );
#	$semblance->set_verbose(} );;
	$semblance->velocity_increment( $iVA->{_velocity_increment} );
	$semblance->Tvel_inbound( $iVA->{_Tvel_inbound} );
	$semblance->Tvel_outbound( $iVA->{_Tvel_outbound} );
	$semblance->calcNdisplay();
}

=head2

 subroutine Write_All_iva_out.pl
 Purpose: Write out best vpicked files from iVA 
 needs sufile name and cdp number

=cut

sub _iWrite_All_iva_out {

	$iWrite_All_iva_out->file_in( $iVA->{_base_file_name} );
	$iWrite_All_iva_out->cdp_num( $iVA->{_cdp_num} );
	$iWrite_All_iva_out->flows();

}

1;
