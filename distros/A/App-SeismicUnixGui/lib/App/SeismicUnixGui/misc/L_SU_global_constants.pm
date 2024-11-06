package App::SeismicUnixGui::misc::L_SU_global_constants;

use Moose;
our $VERSION = '0.0.1';
use Carp;
use Cwd;

my $path4SeismicUnixGui;

BEGIN {

	if ( length $ENV{'SeismicUnixGui'} ) {

		$path4SeismicUnixGui = $ENV{'SeismicUnixGui'};

	}
	else {
		# When environment variables can not be found in Perl
		my $dir       = 'App/SeismicUnixGui';
		my $pathNfile = $dir . '/sunix/data/data_in.pm';
		my $look      = `locate $pathNfile`;
		my @field     = split( $dir, $look );
		$path4SeismicUnixGui = $field[0] . $dir;

		print(
"\nL22. Warning: Using default L_SU_global_constants, L_SU = $path4SeismicUnixGui\n"
		);
	}

}

=head2 private hash

=cut

my $L_SU_global_constants = {
	_file_name    => '',
	_program_name => '',

};

=head2 Default Tk settings

 _first_entry_num is normally 1 _max_entry_num is defaulted to
 
 The names seen in the gui do not have to be the same as
 the internal program names.
 
 For example 'fk' for the user of the gui
 is the same as Sudipfilt
 internally for the programmer.

=cut

my $alias_superflow_names_h = {
	fk                => 'Sudipfilt',
	ProjectVariables  => 'Project_Variables',
	SetProject        => 'SetProject',
	iPick             => 'iPick',
	iSpectralAnalysis => 'iSpectralAnalysis',
	iVelAnalysis      => 'iVA',
	iTopMute          => 'iTopMute',
	iBottomMute       => 'iBottomMute',
	Project           => 'Project',
	Synseis           => 'Synseis',
	Sseg2su           => 'Sseg2su',
	Sucat             => 'Sucat',
	immodpg           => 'immodpg',
	ProjectBackup     => 'BackupProject',
	ProjectRestore    => 'RestoreProject',	
	temp              => 'temp',                # make last
};

=head2 Default Tk settings

 The names seen in the gui do not have to be the same as
 the internal program names.
 For example 'fk' for the user is the same as Sudipfilt
 internally for the programmer.

=cut
my $alias_superflow_spec_names_h = {
	fk                => 'Sudipfilt',
	ProjectVariables  => 'Project_Variables',
	SetProject        => 'SetProject',
	iPick             => 'iPick',
	iSpectralAnalysis => 'iSpectralAnalysis',
	iVelAnalysis      => 'iVA',
	iVA               => 'iVA',
	iTopMute          => 'iTopMute',
	iBottomMute       => 'iBottomMute',
	Project           => 'Project',
	Synseis           => 'Synseis',
	Sseg2su           => 'Sseg2su',
	Sucat             => 'Sucat',
	Sudipfilt         => 'Sudipfilt',
	immodpg           => 'immodpg',
	ProjectBackup     => 'BackupProject',
	BackupProject     => 'BackupProject',
	ProjectRestore    => 'RestoreProject',
	RestoreProject    => 'RestoreProject',	
	temp              => 'temp',                # make last
};

=head2 

  hash that assigns numbers to each color
  
=cut

my $number_from_color = {
	_grey  => 0,
	_pink  => 1,
	_green => 2,
	_blue  => 3,
};

my $superflow_names_h = {
	_fk                => 'fk',
	_Sudipfilt         => 'Sudipfilt',
	_ProjectVariables  => 'ProjectVariables',
	_iPick             => 'iPick',
	_SetProject        => 'SetProject',
	_iSpectralAnalysis => 'iSpectralAnalysis',
	_iVelAnalysis      => 'iVelAnalysis',
	_iVA               => 'iVA',
	_iTopMute          => 'iTopMute',
	_iBottomMute       => 'iBottomMute',
	_Project           => 'Project',
	_Synseis           => 'Synseis',
	_Sseg2su           => 'Sseg2su',
	_Sucat             => 'Sucat',
	_immodpg           => 'immodpg',
	_BackupProject     => 'BackupProject',
	_ProjectBackup     => 'Project Backup',
	_ProjectRestore    => 'Project Restore',
	_RestoreProject    => 'RestoreProject',	
	_temp              => 'temp',                # make last
};

=head2

 as shown in gui

=cut

my @superflow_names_gui;
$superflow_names_gui[0]  = 'Project';
$superflow_names_gui[1]  = 'Sseg2su';
$superflow_names_gui[2]  = 'Sucat';
$superflow_names_gui[3]  = 'iSpectralAnalysis';
$superflow_names_gui[4]  = 'iVelAnalysis';
$superflow_names_gui[5]  = 'iTopMute';
$superflow_names_gui[6]  = 'iBottomMute';
$superflow_names_gui[7]  = 'fk';
$superflow_names_gui[8]  = 'Synseis';
$superflow_names_gui[9]  = 'iPick';
$superflow_names_gui[10] = 'immodpg';
$superflow_names_gui[11] = 'Project Backup';
$superflow_names_gui[12] = 'Project Restore';
$superflow_names_gui[13] = 'temp';                # make last


=head2

 as shown in gui
 allows reverse aliasing between gui
 names and the internal program names
 ??

=cut

my $superflow_names_gui_h ={
	_Project            => 'Project',
	_Sseg2su   			=> 'Sseg2su',
	_Sucat     			=> 'Sucat',
	_iSpectralAnalysis  => 'iSpectralAnalysis',
	_iVelAnalysis       => 'iVelAnalysis',
	_iTopMute        	=> 'iTopMute',
	_iBottomMute  	    => 'iBottomMute',
	_fk                 => 'fk',
	_Synseis            => 'Synseis',
	_iPick              => 'iPick',
	_immodpg            => 'immodpg',
	_ProjectBackup      => 'Project Backup',
	_ProjectRestore     => 'Project Restore',	
	_temp               => 'temp',                # make last

};

=head2

 as shown in gui

=cut

my @superflow_names;
$superflow_names[0]  = 'fk';
$superflow_names[1]  = 'ProjectVariables';
$superflow_names[2]  = 'SetProject';
$superflow_names[3]  = 'iSpectralAnalysis';
$superflow_names[4]  = 'iVelAnalysis';
$superflow_names[5]  = 'iTopMute';
$superflow_names[6]  = 'iBottomMute';
$superflow_names[7]  = 'Project';
$superflow_names[8]  = 'Synseis';
$superflow_names[9]  = 'Sseg2su';
$superflow_names[10] = 'Sucat';
$superflow_names[11] = 'iPick';
$superflow_names[12] = 'immodpg';
$superflow_names[13] = 'Project Backup';
$superflow_names[14] = 'Project Restore';
$superflow_names[15] = 'temp';                # make last

=head2

 internal names for configuration files
 missing _fk and _Sudipfilter TODO

=cut

my @alias_superflow_names;
$alias_superflow_names[0]  = 'Sudipfilt';
$alias_superflow_names[1]  = 'SetProject';
$alias_superflow_names[2]  = 'SetProject';
$alias_superflow_names[3]  = 'iSpectralAnalysis';
$alias_superflow_names[4]  = 'iVA';
$alias_superflow_names[5]  = 'iTopMute';
$alias_superflow_names[6]  = 'iBottomMute';
$alias_superflow_names[7]  = 'Project';
$alias_superflow_names[8]  = 'Synseis';
$alias_superflow_names[9]  = 'Sseg2su';
$alias_superflow_names[10] = 'Sucat';
$alias_superflow_names[11] = 'iPick';
$alias_superflow_names[12] = 'immodpg';
$alias_superflow_names[13] = 'BackupProject';
$alias_superflow_names[14] = 'RestoreProject';
$alias_superflow_names[15] = 'temp';                # make last

# to match each alias_superflow_names (above)
# Tools subdirectories
my @developer_Tools_categories;
$developer_Tools_categories[0]  = 'big_streams';
$developer_Tools_categories[1]  = '.';
$developer_Tools_categories[2]  = '.';
$developer_Tools_categories[3]  = 'big_streams';
$developer_Tools_categories[4]  = 'big_streams';
$developer_Tools_categories[5]  = 'big_streams';
$developer_Tools_categories[6]  = 'big_streams';
$developer_Tools_categories[7]  = '.';
$developer_Tools_categories[8]  = 'big_streams';
$developer_Tools_categories[9]  = 'big_streams';
$developer_Tools_categories[10] = 'big_streams';
$developer_Tools_categories[11] = 'big_streams';
$developer_Tools_categories[12] = 'big_streams';
$developer_Tools_categories[13] = 'big_streams';
$developer_Tools_categories[14] = 'big_streams';




=head2

internal names for programs

=cut

my @superflow_config_names;
$superflow_config_names[0]  = 'Sudipfilt';
$superflow_config_names[1]  = 'ProjectVariables';
$superflow_config_names[2]  = 'ProjectVariables';
$superflow_config_names[3]  = 'iSpectralAnalysis';
$superflow_config_names[4]  = 'iVA';
$superflow_config_names[5]  = 'iTopMute';
$superflow_config_names[6]  = 'iBottomMute';
$superflow_config_names[7]  = 'Project';
$superflow_config_names[8]  = 'Synseis';
$superflow_config_names[9]  = 'Sseg2su';
$superflow_config_names[10] = 'Sucat';
$superflow_config_names[11] = 'iPick';
$superflow_config_names[12] = 'immodpg';
$superflow_config_names[13] = 'BackupProject';
$superflow_config_names[14] = 'RestoreProject';
$superflow_config_names[15] = 'temp';                # make last


=head2

internal names for configuration files

=cut

my @alias_superflow_config_names;
$alias_superflow_config_names[0]  = 'Sudipfilt';
$alias_superflow_config_names[1]  = 'Project_Variables';
$alias_superflow_config_names[2]  = 'Project# make last_Variables';
$alias_superflow_config_names[3]  = 'iSpectralAnalysis';
$alias_superflow_config_names[4]  = 'iVA';
$alias_superflow_config_names[5]  = 'iTopMute';
$alias_superflow_config_names[6]  = 'iBottomMute';
$alias_superflow_config_names[7]  = 'Project';
$alias_superflow_config_names[8]  = 'Synseis';
$alias_superflow_config_names[9]  = 'Sseg2su';
$alias_superflow_config_names[10] = 'Sucat';
$alias_superflow_config_names[11] = 'iPick';
$alias_superflow_config_names[12] = 'immodpg';
$alias_superflow_config_names[13] = 'BackupProject';
$alias_superflow_config_names[14] = 'RestoreProject';
$alias_superflow_config_names[15] = 'temp';                          # make last

# for the visible buttons in the GUI only
# e.g., Path and PL_SEISMIC are not visible to the user
# but Flow and SaveAs are.
my @alias_FileDialog_button_label;

$alias_FileDialog_button_label[0] = 'Open';
$alias_FileDialog_button_label[1] = 'SaveAs';
$alias_FileDialog_button_label[2] = 'Delete';

my @file_dialog_type;

# for the visible Help button in the GUI
my @alias_help_menubutton_label;
$alias_help_menubutton_label[0] = 'About';
$alias_help_menubutton_label[1] = 'InstallationGuide';
$alias_help_menubutton_label[2] = 'Tutorial';

my $alias_help_menubutton_label_h = { 
		_About             => 'About', 
        _InstallationGuide => 'InstallationGuide',
        _Tutorial          => 'Tutorial',
};

# in spec files for when Data_PL_SEISMIC, may
# not necessarily informed by DATA_DIR_IN and DATA_DIR_OUT
$file_dialog_type[0] = 'Data_PL_SEISMIC',

# in spec files, for when Data is informed
# by DATA_DIR_IN and DATA_DIR_OUT
$file_dialog_type[1] = 'Data';
$file_dialog_type[2] = 'Path';
$file_dialog_type[3] = 'Open';
$file_dialog_type[4] = 'SaveAs';
$file_dialog_type[5] = 'last_dir_in_path';
$file_dialog_type[5] = 'Delete';
$file_dialog_type[6] = 'Data_SEISMIC_TXT';
$file_dialog_type[7] = 'Home';

my $file_dialog_type_h = {
	_Data_PL_SEISMIC  => 'Data_PL_SEISMIC',
	_Data_SEISMIC_TXT => 'Data_SEISMIC_TXT',
	_Data             => 'Data',
	_Delete           => 'Delete',
	_Home             => 'Home',
	_Path             => 'Path',
	_last_dir_in_path => 'last_dir_in_path',
	_Flow             => 'Flow',
	_Open             => 'Open',
	_SaveAs           => 'SaveAs',
	_Save             => 'Save',
};
my @flow_type;
$flow_type[0] = 'user_built';
$flow_type[1] = 'pre_built_superflow';

my $flow_type_h = {
	_user_built          => 'user_built',
	_pre_built_superflow => 'pre_built_superflow',
};

my $help_menubutton_type_h = { _About             => 'About', 
							   _InstallationGuide => 'InstallationGuide',
							   _Tutorial          => 'Tutorial',
};

my $purpose = { _geopsy => 'geopsy', };

my $var = {
	_1_character            => '1',
	_14_characters          => '14',
	_13_characters          => '13',
	_12_characters          => '12',
	_11_characters          => '11',
	_2_characters           => '2',
	_3_characters           => '3',
	_4_characters           => '4',
	_5_characters           => '5',
	_6_characters           => '6',
	_7_characters           => '7',
	_8_characters           => '8',
	_10_characters          => '10',
	_15_characters          => '15',
	_20_characters          => '20',
	_30_characters          => '30',
	_32_characters          => '32',
	_35_characters          => '35',
	_37_characters          => '37',
	_40_characters          => '40',
	_45_characters          => '45',
	_ACTIVE_PROJECT         => '/.L_SU/configuration/active',
	_App                    => 'App',
	_SeismicUnixGui         => 'SeismicUnixGui',
	_Project_config         => 'Project.config',
	_skip_directory         => 'archive',
	_base_file_name         => 'base_file_name',
	_clear_text             => '',
	_color_default          => 'grey',           # first color listbox to select
	_config_file_format     => '%-35s%1s%-20s',
	_eight_characters       => '8',
	_empty_string           => '',
	_failure                => -1,
	_false                  => 0,
	_data_name              => 'data_name',
	_base_file_name         => 'base_file_name',
	_five_pixels            => '5',
	_five_pixel_borderwidth => 5,
	_five_lines             => '5',
	_forward_slash          => "/",
	_1_line                 => '1',
	_2_lines                => '2',
	_3_lines                => '3',
	_4_lines                => '4',
	_8_lines                => '8',
	_7_lines                => '7',
	_1_pixel                => '1',
	_3_pixels               => '3',
	_6_pixels               => '6',
	_24_pixels              => '24',
	_12_pixels              => '12',
	_18_pixels              => '18',
	_NaN                    => 'NaN',
	_five_characters        => '5',
	_flow                   => 'frame',
	_half_tiny_width        => '6',
	_hundred_characters     => '100',
	_large__width           => '200',
	_light_gray             => 'gray90',
	_literal_empty_string   => '\'\'',
	_l_suplot_box_positionNsize    => '600x800+1000+1000',
	_l_suplot_width                => '500',
	_l_suplot_height               => '300',
	_log_file_txt                  => 'log.txt',
	_main_window_geometry          => '1100x750+100+100',
	_medium_width                  => '100',
	_message_box_geometry          => '400x250+400+400',
	_min_clicks4save_button        => 45,     # B4:19; fixing leaky param_widget memory
	_min_clicks4flow_select        => 8,      # fixing leaky param_widget memory
	_ms2s                          => 0.001,
	_my_arial                      => "-*-arial-normal-r-*-*-*-120-*-*-*-*-*-*",
#	_my_purple                     => 'MediumPurple1',
    _my_purple                     => 'LightSteelBlue',
	_my_white                      => 'white',
#	_my_yellow                     => 'LightGoldenrod1',
    _my_yellow                     => 'white',
	_my_dark_grey                  => 'DarkGrey',
	_my_black                      => 'black',
	_my_light_green                => 'LightGreen',
	_my_light_grey                 => 'LightGrey',
	_my_pink                       => 'pink',
	_my_light_blue                 => 'LightBlue',
	_my_dialog_box_geometry        => '400x250+400+400',
	_neutral                       => 'neutral',
	_no_pixel                      => '0',
	_no_dir                        => '/',
	_no_borderwidth                => '0',
	_nu                            => 'nu',
	_no                            => 'no',
	_on                            => 'on',
	_off                           => 'off',
	_one_character                 => '1',
	_one_pixel                     => '1',
	_one_pixel_borderwidth         => '1',
	_program_title                 => 'SeismicUnixGui V0.87.2',
	_project_selector_title        => 'Project Selector',
	_l_suplot_title                => 'L_suplot',
	_project_selector_title        => 'Project Selector',
	_project_selector              => 'Project',
	_project_selector_box_position => '600x600+100+100',
	_null_sunix_value              => '',
	_reservation_color_default     =>
	  'grey',    # first choice for reserving a color listbox
	_suffix_pl              => '.pl',
	_suffix_pm              => '.pm',
	_superflow              => 'menubutton',
	_small_width            => '50',
	_string2startFlowSetUp  => '->clear\(\);',    # for regex in perl_flow
	_string2endFlowSetUp    => '->Step\(\);',     # for regex in perl_flow
	_standard_width         => '20',
	_sunix_select           => 'sunix_select',
	_ten_characters         => '10',
	_test_dir_name          => 't',
	_eleven_characters      => '11',
	_five_characters        => '5',
	_thirty_characters      => '30',
	_18_characters          => '18',
	_thirty_five_characters => '35',
	_tiny_width             => '12',
	_true                   => 1,
	_us_per_s               => 1000000,
	_twenty_characters      => '20',
	_us2s                   => 0.000001,
	_username               => 'tester',
	_very_small_width       => '25',
	_very_large_width       => '500',
	_yes                    => 'yes',
	_white                  => 'white',

};

=pod
    _length = (max number of entries + 1)

=cut

my $param = {
	_max_entry_num   => 90,
	_first_entry_num => 0,
	_first_entry_idx => 0,
	_final_entry_num => 90,
	_final_entry_idx => 90,
	_default_index   => 0,
	_length          => 90,    # max number of allowable parameters in GUI
};

my @developer_sunix_categories;
$developer_sunix_categories[0]  = 'data';
$developer_sunix_categories[1]  = 'datum';
$developer_sunix_categories[2]  = 'plot';
$developer_sunix_categories[3]  = 'filter';
$developer_sunix_categories[4]  = 'header';
$developer_sunix_categories[5]  = 'inversion';
$developer_sunix_categories[6]  = 'migration';
$developer_sunix_categories[7]  = 'model';
$developer_sunix_categories[8]  = 'NMO_Vel_Stk';
$developer_sunix_categories[9]  = 'par';
$developer_sunix_categories[10] = 'picks';
$developer_sunix_categories[11] = 'shapeNcut';
$developer_sunix_categories[12] = 'shell';
$developer_sunix_categories[13] = 'statsMath';
$developer_sunix_categories[14] = 'transform';
$developer_sunix_categories[15] = 'well';
$developer_sunix_categories[16] = '';
$developer_sunix_categories[17] = '';

=head2 Classify
programs

=cut

=head2 sub get_developer_sunix_category
=cut

sub get_developer_sunix_category_h {

	my ($self) = @_;
	my $developer_sunix_category_h = {

		_ctrlstrip     => $developer_sunix_categories[0],
		_data_in       => $developer_sunix_categories[0],
		_data_out      => $developer_sunix_categories[0],
		_dt1tosu       => $developer_sunix_categories[0],
		_segbread      => $developer_sunix_categories[0],
		_segdread      => $developer_sunix_categories[0],
		_segyread      => $developer_sunix_categories[0],
		_segyscan      => $developer_sunix_categories[0],
		_segywrite     => $developer_sunix_categories[0],
		_suoldtonew    => $developer_sunix_categories[0],
		_supack1       => $developer_sunix_categories[0],
		_supack2       => $developer_sunix_categories[0],
		_suswapbytes   => $developer_sunix_categories[0],
		_suunpack1     => $developer_sunix_categories[0],
		_suunpack2     => $developer_sunix_categories[0],
		_wpc1uncomp2   => $developer_sunix_categories[0],
		_wpccompress   => $developer_sunix_categories[0],
		_wpcuncompress => $developer_sunix_categories[0],
		_wptcomp       => $developer_sunix_categories[0],
		_wptuncomp     => $developer_sunix_categories[0],
		_wtcomp        => $developer_sunix_categories[0],
		_wtuncomp      => $developer_sunix_categories[0],

		_sudatumk2dr => $developer_sunix_categories[1],
		_sudatumk2ds => $developer_sunix_categories[1],
		_sukdmdcr    => $developer_sunix_categories[1],
		_sukdmdcs    => $developer_sunix_categories[1],

		_subfilt      => $developer_sunix_categories[3],
		_succfilt     => $developer_sunix_categories[3],
		_sucddecon    => $developer_sunix_categories[3],
		_sudipfilt    => $developer_sunix_categories[3],
		_sueipofi     => $developer_sunix_categories[3],
		_sufilter     => $developer_sunix_categories[3],
		_sufrac       => $developer_sunix_categories[3],
		_sufwatrim    => $developer_sunix_categories[3],
		_sufxdecon    => $developer_sunix_categories[3],
		_sugroll      => $developer_sunix_categories[3],
		_suk1k2filter => $developer_sunix_categories[3],
		_sukfilter    => $developer_sunix_categories[3],
		_sulfaf       => $developer_sunix_categories[3],
		_sumedian     => $developer_sunix_categories[3],
		_supef        => $developer_sunix_categories[3],
		_suphase      => $developer_sunix_categories[3],
		_suphidecon   => $developer_sunix_categories[3],
		_supofilt     => $developer_sunix_categories[3],
		_supolar      => $developer_sunix_categories[3],
		_susmgauss2   => $developer_sunix_categories[3],
		_sutvband     => $developer_sunix_categories[3],

		_segyclean    => $developer_sunix_categories[4],
		_segyhdrmod   => $developer_sunix_categories[4],
		_segyhdrs     => $developer_sunix_categories[4],
		_setbhed      => $developer_sunix_categories[4],
		_su3dchart    => $developer_sunix_categories[4],
		_suabshw      => $developer_sunix_categories[4],
		_suaddhead    => $developer_sunix_categories[4],
		_suaddstatics => $developer_sunix_categories[4],
		_suahw        => $developer_sunix_categories[4],
		_suascii      => $developer_sunix_categories[4],
		_suazimuth    => $developer_sunix_categories[4],
		_sucdpbin     => $developer_sunix_categories[4],
		_suchart      => $developer_sunix_categories[4],
		_suchw        => $developer_sunix_categories[4],
		_sucliphead   => $developer_sunix_categories[4],
		_sucountkey   => $developer_sunix_categories[4],
		_sudumptrace  => $developer_sunix_categories[4],
		_suedit       => $developer_sunix_categories[4],
		_sugethw      => $developer_sunix_categories[4],
		_suhtmath     => $developer_sunix_categories[4],
		_sukeycount   => $developer_sunix_categories[4],
		_sulcthw      => $developer_sunix_categories[4],
		_sulhead      => $developer_sunix_categories[4],
		_supaste      => $developer_sunix_categories[4],
		_surandhw     => $developer_sunix_categories[4],
		_surange      => $developer_sunix_categories[4],
		_suresstat    => $developer_sunix_categories[4],		
		_susehw       => $developer_sunix_categories[4],
		_sushw        => $developer_sunix_categories[4],
		_sustatic     => $developer_sunix_categories[4],
		_sustaticB    => $developer_sunix_categories[4],
		_sustaticrrs  => $developer_sunix_categories[4],
		_sustrip      => $developer_sunix_categories[4],
		_sutrcount    => $developer_sunix_categories[4],
		_suutm        => $developer_sunix_categories[4],
		_suxedit      => $developer_sunix_categories[4],
		_swapbhed     => $developer_sunix_categories[4],

		_suinvco3d  => $developer_sunix_categories[5],
		_suinvvxzco => $developer_sunix_categories[5],
		_suinvzco3d => $developer_sunix_categories[5],

		_sudatumfd    => $developer_sunix_categories[6],
		_sugazmig     => $developer_sunix_categories[6],
		_sukdmig2d    => $developer_sunix_categories[6],
		_suktmig2d    => $developer_sunix_categories[6],
		_sukdmig3d    => $developer_sunix_categories[6],
		_sumigfd      => $developer_sunix_categories[6],
		_sumigffd     => $developer_sunix_categories[6],
		_sumiggbzo    => $developer_sunix_categories[6],
		_sumiggbzoan  => $developer_sunix_categories[6],
		_sumigprefd   => $developer_sunix_categories[6],
		_sumigpreffd  => $developer_sunix_categories[6],
		_sumigprepspi => $developer_sunix_categories[6],
		_sumigpresp   => $developer_sunix_categories[6],
		_sumigps      => $developer_sunix_categories[6],
		_sumigpspi    => $developer_sunix_categories[6],
		_sumigpsti    => $developer_sunix_categories[6],
		_sumigsplit   => $developer_sunix_categories[6],
		_sumigtk      => $developer_sunix_categories[6],
		_sumigtopo2d  => $developer_sunix_categories[6],
		_sustolt      => $developer_sunix_categories[6],
		_sutifowler   => $developer_sunix_categories[6],

		_cat_su     => $developer_sunix_categories[12],
		_evince    => $developer_sunix_categories[12],
		_sugetgthr => $developer_sunix_categories[12],
		_suputgthr => $developer_sunix_categories[12],

		_addrvl3d       => $developer_sunix_categories[7],
		_cellauto       => $developer_sunix_categories[7],
		_elacheck       => $developer_sunix_categories[7],
		_elamodel       => $developer_sunix_categories[7],
		_elaray         => $developer_sunix_categories[7],
		_elasyn         => $developer_sunix_categories[7],
		_elatriuni      => $developer_sunix_categories[7],
		_gbbeam         => $developer_sunix_categories[7],
		_grm            => $developer_sunix_categories[7],
		_normray        => $developer_sunix_categories[7],
		_raydata        => $developer_sunix_categories[7],
		_suaddevent     => $developer_sunix_categories[7],
		_suaddnoise     => $developer_sunix_categories[7],
		_sudgwaveform   => $developer_sunix_categories[7],
		_suea2df        => $developer_sunix_categories[7],
		_sufctanismod   => $developer_sunix_categories[7],
		_sufdmod1       => $developer_sunix_categories[7],
		_sufdmod2       => $developer_sunix_categories[7],
		_sufdmod2_pml   => $developer_sunix_categories[7],
		_sugoupillaud   => $developer_sunix_categories[7],
		_sugoupillaudpo => $developer_sunix_categories[7],
		_suimp2d        => $developer_sunix_categories[7],
		_suimp3d        => $developer_sunix_categories[7],
		_suimpedance    => $developer_sunix_categories[7],
		_sujitter       => $developer_sunix_categories[7],
		_sukdsyn2d      => $developer_sunix_categories[7],
		_sunull         => $developer_sunix_categories[7],
		_suplane        => $developer_sunix_categories[7],
		_surandspike    => $developer_sunix_categories[7],
		_surandstat     => $developer_sunix_categories[7],
		_suremac2d      => $developer_sunix_categories[7],
		_suremel2dan    => $developer_sunix_categories[7],
		_suspike        => $developer_sunix_categories[7],
		_susyncz        => $developer_sunix_categories[7],
		_susynlv        => $developer_sunix_categories[7],
		_susynlvcw      => $developer_sunix_categories[7],
		_susynlvfti     => $developer_sunix_categories[7],
		_susynvxz       => $developer_sunix_categories[7],
		_susynvxzcs     => $developer_sunix_categories[7],

		_dzdv         => $developer_sunix_categories[8],
		_sucvs4fowler => $developer_sunix_categories[8],
		_sudivstack   => $developer_sunix_categories[8],
		_sudmofk      => $developer_sunix_categories[8],
		_sudmofkcw    => $developer_sunix_categories[8],
		_sudmotivz    => $developer_sunix_categories[8],
		_sudmotx      => $developer_sunix_categories[8],
		_sudmovz      => $developer_sunix_categories[8],
		_suilog       => $developer_sunix_categories[8],
		_suintvel     => $developer_sunix_categories[8],
		_sulog        => $developer_sunix_categories[8],
		_sunmo        => $developer_sunix_categories[8],
		_sunmo_a      => $developer_sunix_categories[8],
		_supws        => $developer_sunix_categories[8],
		_surecip      => $developer_sunix_categories[8],
		_sureduce     => $developer_sunix_categories[8],
		_surelan      => $developer_sunix_categories[8],
		_surelanan    => $developer_sunix_categories[8],
		_suresamp     => $developer_sunix_categories[8],
		_sushift      => $developer_sunix_categories[8],
		_sustack      => $developer_sunix_categories[8],
		_sustkvel     => $developer_sunix_categories[8],
		_sutaupnmo    => $developer_sunix_categories[8],
		_sutihaledmo  => $developer_sunix_categories[8],
		_sutivel      => $developer_sunix_categories[8],
		_sutsq        => $developer_sunix_categories[8],
		_suttoz       => $developer_sunix_categories[8],
		_suvel2df     => $developer_sunix_categories[8],
		_suvelan      => $developer_sunix_categories[8],
		_suvelan_nccs => $developer_sunix_categories[8],
		_suvelan_nsel => $developer_sunix_categories[8],
		_suztot       => $developer_sunix_categories[8],

		_a2b        => $developer_sunix_categories[9],
		_a2i        => $developer_sunix_categories[9],
		_b2a        => $developer_sunix_categories[9],
		_bhedtopar  => $developer_sunix_categories[9],
		_cshotplot  => $developer_sunix_categories[9],
		_float2ibm  => $developer_sunix_categories[9],
		_ftnstrip   => $developer_sunix_categories[9],
		_ftnunstrip => $developer_sunix_categories[9],
		_makevel    => $developer_sunix_categories[9],
		_mkparfile  => $developer_sunix_categories[9],
		_transp     => $developer_sunix_categories[9],
		_unif2      => $developer_sunix_categories[9],
		_unif2aniso => $developer_sunix_categories[9],
		_unisam     => $developer_sunix_categories[9],
		_unisam2    => $developer_sunix_categories[9],
		_vel2stiff  => $developer_sunix_categories[9],

		_elaps           => $developer_sunix_categories[2],
		_lcmap           => $developer_sunix_categories[2],
		_lprop           => $developer_sunix_categories[2],
		_psbbox          => $developer_sunix_categories[2],
		_pscontour       => $developer_sunix_categories[2],
		_pscube          => $developer_sunix_categories[2],
		_pscubecontour   => $developer_sunix_categories[2],
		_psepsi          => $developer_sunix_categories[2],
		_psgraph         => $developer_sunix_categories[2],
		_psimage         => $developer_sunix_categories[2],
		_pslabel         => $developer_sunix_categories[2],
		_psmanager       => $developer_sunix_categories[2],
		_psmerge         => $developer_sunix_categories[2],
		_psmovie         => $developer_sunix_categories[2],
		_pswigb          => $developer_sunix_categories[2],
		_pswigp          => $developer_sunix_categories[2],
		_scmap           => $developer_sunix_categories[2],
		_spsplot         => $developer_sunix_categories[2],
		_supscontour     => $developer_sunix_categories[2],
		_supscube        => $developer_sunix_categories[2],
		_supscubecontour => $developer_sunix_categories[2],
		_supsgraph       => $developer_sunix_categories[2],
		_supsimage       => $developer_sunix_categories[2],
		_supsmax         => $developer_sunix_categories[2],
		_supsmovie       => $developer_sunix_categories[2],
		_supswigb        => $developer_sunix_categories[2],
		_supswigp        => $developer_sunix_categories[2],
		_suxcontour      => $developer_sunix_categories[2],
		_suxgraph        => $developer_sunix_categories[2],
		_suximage        => $developer_sunix_categories[2],
		_suxmax          => $developer_sunix_categories[2],
		_suxmovie        => $developer_sunix_categories[2],
		_suxpicker       => $developer_sunix_categories[2],
		_suxwigb         => $developer_sunix_categories[2],
		_xcontour        => $developer_sunix_categories[2],		
		_xgraph          => $developer_sunix_categories[2],
		_ximage          => $developer_sunix_categories[2],
		_xmovie          => $developer_sunix_categories[2],
		_xpicker         => $developer_sunix_categories[2],		
		_xwigb           => $developer_sunix_categories[2],

		_suflip  => $developer_sunix_categories[11],
		_sugain  => $developer_sunix_categories[11],
		_sugprfb => $developer_sunix_categories[11],
		_sukill  => $developer_sunix_categories[11],
		_sumute  => $developer_sunix_categories[11],
		_suramp  => $developer_sunix_categories[11],
		_supad   => $developer_sunix_categories[11],
		_susort  => $developer_sunix_categories[11],
		_susplit => $developer_sunix_categories[11],
		_suvcat  => $developer_sunix_categories[11],
		_suwind  => $developer_sunix_categories[11],

		_cpftrend     => $developer_sunix_categories[13],
		_entropy      => $developer_sunix_categories[13],
		_farith       => $developer_sunix_categories[13],
		_suacor       => $developer_sunix_categories[13],
		_suacorfrac   => $developer_sunix_categories[13],
		_sualford     => $developer_sunix_categories[13],
		_suattributes => $developer_sunix_categories[13],
		_suconv       => $developer_sunix_categories[13],
		_sufwmix      => $developer_sunix_categories[13],
		_suhistogram  => $developer_sunix_categories[13],
		_suhrot       => $developer_sunix_categories[13],
		_suinterp     => $developer_sunix_categories[13],
		_sumax        => $developer_sunix_categories[13],
		_sumean       => $developer_sunix_categories[13],
		_sumix        => $developer_sunix_categories[13],
		_suop         => $developer_sunix_categories[13],
		_suop2        => $developer_sunix_categories[13],
		_suxcor       => $developer_sunix_categories[13],
		_suxmax       => $developer_sunix_categories[13],

		_dctcomp     => $developer_sunix_categories[14],
		_suamp       => $developer_sunix_categories[14],
		_succepstrum => $developer_sunix_categories[14],
		_sucepstrum  => $developer_sunix_categories[14],
		_sucwt       => $developer_sunix_categories[14],
		_succwt      => $developer_sunix_categories[14],
		_sufft       => $developer_sunix_categories[14],
		_sugabor     => $developer_sunix_categories[14],
		_suicepstrum => $developer_sunix_categories[14],
		_suifft      => $developer_sunix_categories[14],
		_suminphase  => $developer_sunix_categories[14],		
		_suphasevel  => $developer_sunix_categories[14],
		_suspecfk    => $developer_sunix_categories[14],
		_suspecfx    => $developer_sunix_categories[14],
		_sutaup      => $developer_sunix_categories[14],

		_las2su    => $developer_sunix_categories[15],
		_subackus  => $developer_sunix_categories[15],
		_subackush => $developer_sunix_categories[15],
		_sugassman => $developer_sunix_categories[15],
		_sulprime  => $developer_sunix_categories[15],
		_suwellrf  => $developer_sunix_categories[15],

	};

	return ($developer_sunix_category_h);

}

my @sunix_data_programs = (
	"ctrlstrip",   "data_in",       "data_out",  "dt1tosu",
	"segbread",    "segdread",      "segyread",  "segyscan",
	"segywrite",   "suoldtonew",    "supack1",   "supack2",
	"suswapbytes", "suunpack1",     "suunpack2", "wpc1uncomp2",
	"wpccompress", "wpcuncompress", "wptcomp",   "wptuncomp",
	"wtcomp",      "wtuncomp",
);

my @sunix_datum_programs =
  ( "sudatumk2dr", "sudatumk2ds", "sukdmdcr", "sukdmdcs", );

my @sunix_filter_programs = (
	"subfilt", "succfilt", "sucddecon", "sudipfilt",
	"sueipofi", "sufilter", "sufrac", 	"sufwatrim",
	"sufxdecon",
	"sugroll", "suk1k2filter", "sukfilter", "sulfaf",
	"sumedian", "supef", "suphase", "suphidecon",
	"supofilt", "supolar", "susmgauss2", "sutvband",
);

my @sunix_header_programs = (
	"segyclean", "segyhdrmod", "segyhdrs", "setbhed",
	"su3dchart", "suabshw", "suaddhead", "suaddstatics",
	"suahw", "suascii", "suazimuth", "sucdpbin",
	"suchart", "suchw", "sucliphead", "sucountkey",
	"sudumptrace", "suedit", "sugethw", "suhtmath",
	"sukeycount", "sulcthw", "sulhead", "supaste",
	"surandhw", "surange", "suresstat", "susehw",
	"sushw",
	"sustatic", "sustaticB", "sustaticrrs", "sustrip",
	"sutrcount", "suutm", "suxedit", "swapbhed",
);

my @sunix_inversion_programs = ( "suinvco3d", "suinvvxzco", "suinvzco3d", );

my @sunix_migration_programs = (
	"sudatumfd", "sugazmig", "sukdmig2d", "suktmig2d",
	"sukdmig3d", "sumigfd", "sumigffd", "sumiggbzo",
	"sumiggbzoan", "sumigprefd", "sumigpreffd", "sumigprepspi",
	"sumigpresp", "sumigps", "sumigpspi", "sumigpsti",
	"sumigsplit",
	"sumigtk", "sumigtopo2d", "sustolt", "sutifowler",
);

my @sunix_shell_programs = ( "cat_su", "evince", "sugetgthr", "suputgthr", );

=pod


=cut

my @sunix_model_programs = (
	"addrvl3d",       "cellauto",     "elacheck",     "elamodel",
	"elaray",         "elasyn",       "elatriuni",    "gbbeam",
	"grm",            "normray",      "raydata",      "suaddevent",
	"suaddnoise",     "sudgwaveform", "suea2df",      "sufctanismod",
	"sufdmod1",       "sufdmod2",     "sufdmod2_pml", "sugoupillaud",
	"sugoupillaudpo", "suimp2d",      "suimp3d",      "suimpedance",
	"sujitter",       "sukdsyn2d",    "sunull",       "suplane",
	"surandspike",    "surandstat",   "suremac2d",    "suremel2dan",
	"suspike",        "susyncz",      "susynlv",      "susynlvcw",
	"susynlvfti",     "susynvxz",     "susynvxzcs",
);

my @sunix_NMO_Vel_Stk_programs = (
	"dzdv",      "sucvs4fowler", "sudivstack",   "sudmofk",
	"sudmofkcw", "sudmotivz",    "sudmotx",      "sudmovz",
	"suilog",    "suintvel",     "sulog",        "sunmo",
	"sunmo_a",   "supws",        "surecip",      "sureduce",
	"surelan",   "surelanan",    "suresamp",     "sushift",
	"sustack",   "sustkvel",     "sutaupnmo",    "sutihaledmo",
	"sutivel",   "sutsq",        "suttoz",       "suvel2df",
	"suvelan",   "suvelan_nccs", "suvelan_nsel", "suztot",
);

my @sunix_par_programs = (
	"a2b", "a2i", "b2a", "bhedtopar",
	"cshotplot", "float2ibm", "ftnstrip", "ftnunstrip",
	"makevel", "mkparfile", "transp", "unif2",
	"unif2aniso", "unisam", "unisam2","vel2stiff",

);

my @sunix_picks_programs = (

);

my @sunix_plot_programs = (
    "elaps", "lcmap", "lprop", "psbbox",
	"pscontour", "pscube", "pscubecontour", "psepsi",
	"psgraph", "psimage", "pslabel", "psmanager",
	"psmerge", "psmovie", "pswigb", "pswigp",
	"scmap", "spsplot", "supscontour", "supscube",
	"supscubecontour", "supsgraph", "supsimage", "supsmax",
	"supsmovie", "supswigb", "supswigp", "suxcontour",
	"suxgraph", "suximage", "suxmax", "suxmovie",
	"suxpicker", "suxwigb", "xcontour","xgraph", 
	"ximage", "xmovie", "xpicker", "xwigb",
);

my @sunix_shapeNcut_programs = (
	"suflip", "sugain", "sugprfb", "sukill", "sumute", "susort",
	"suramp",
	"susplit", "suwind", "supad", "suvcat",
);

my @sunix_statsMath_programs = (
	"cpftrend",   "entropy",     "farith",       "suacor",
	"suacorfrac", "sualford",    "suattributes", "suconv",
	"sufwmix",    "suhistogram", "suhrot",       "suinterp",
	"sumax",      "sumean",      "sumix",        "suop",
	"suop2",      "suxcor",      "suxmax",
);

my @sunix_transform_programs = (
	"dctcomp", "suamp", "succepstrum", "sucepstrum",
	"sucwt", "succwt", "sufft", "sugabor",
	"suicepstrum", "suifft", "suphasevel", "suspecfk",
	"suminphase",
	"suspecfx", "sutaup",
);

my @sunix_well_programs =
  ( "las2su", "subackus", "subackush", "sugassman", "sulprime", "suwellrf", );

$var->{_sunix_data_programs}        = \@sunix_data_programs;
$var->{_sunix_datum_programs}       = \@sunix_datum_programs;
$var->{_sunix_plot_programs}        = \@sunix_plot_programs;
$var->{_sunix_filter_programs}      = \@sunix_filter_programs;
$var->{_sunix_inversion_programs}   = \@sunix_inversion_programs;
$var->{_sunix_header_programs}      = \@sunix_header_programs;
$var->{_sunix_migration_programs}   = \@sunix_migration_programs;
$var->{_sunix_shell_programs}       = \@sunix_shell_programs;
$var->{_sunix_model_programs}       = \@sunix_model_programs;
$var->{_sunix_NMO_Vel_Stk_programs} = \@sunix_NMO_Vel_Stk_programs;
$var->{_sunix_par_programs}         = \@sunix_par_programs;
$var->{_sunix_picks_programs}       = \@sunix_picks_programs;
$var->{_sunix_shapeNcut_programs}   = \@sunix_shapeNcut_programs;
$var->{_sunix_statsMath_programs}   = \@sunix_statsMath_programs;
$var->{_sunix_transform_programs}   = \@sunix_transform_programs;
$var->{_sunix_well_programs}        = \@sunix_well_programs;

sub _get_global_libs {
	my (@self) = @_;

	# empty string is predefined herein
	if ( length $path4SeismicUnixGui ) {

		print(
"L_SU_global_constants _get_global_libs L_SU = $path4SeismicUnixGui\n"
		);

		my $global_libs = {
			_configs             => $path4SeismicUnixGui . '/configs',
			_configs_big_streams => $path4SeismicUnixGui
			  . '/configs/big_streams',
			_developer    => $path4SeismicUnixGui . '/developer/Stripped',
			_misc         => $path4SeismicUnixGui . '/misc',
			_param        => $path4SeismicUnixGui . '/configs/',
			_script       => $path4SeismicUnixGui . '/script/',
			_specs        => $path4SeismicUnixGui . '/specs',
			_sunix        => $path4SeismicUnixGui . '/sunix',
			_big_streams  => $path4SeismicUnixGui . '/big_streams/',
			_images       => $path4SeismicUnixGui . '/images/',
			_default_path => './',
		};

		return ($global_libs);

	}
	else {
		my $path4SeismicUnixGui = _default_path();

 #		print("L1042, L_SU_global_constants, global_libs, L_SU was missing\n");
 #		print(
 #"\nL1044. L_SU_global_constants, Using default  L_SU = $path4SeismicUnixGui\n"
 #		);

		my $global_libs = {
			_configs             => $path4SeismicUnixGui . '/configs',
			_configs_big_streams => $path4SeismicUnixGui
			  . '/configs/big_streams',
			_developer    => $path4SeismicUnixGui . '/developer/Stripped',
			_misc         => $path4SeismicUnixGui . '/misc',
			_param        => $path4SeismicUnixGui . '/configs/',
			_script       => $path4SeismicUnixGui . '/script/',
			_specs        => $path4SeismicUnixGui . '/specs',
			_sunix        => $path4SeismicUnixGui . '/sunix',
			_big_streams  => $path4SeismicUnixGui . '/big_streams/',
			_images       => $path4SeismicUnixGui . '/images/',
			_default_path => './',
		};

		return ($global_libs);
	}

}

=head2 sub default_path

When Environment variables
can not be found within Perl

=cut

sub _default_path {

	my ($self) = @_;

#	my $dir = 'App-SeismicUnixGui/lib/App/SeismicUnixGui';
#	my $pathNfile =
#	  'App-SeismicUnixGui/lib/App/SeismicUnixGui/sunix/data/data_in.pm';
#	my $look  = `locate $pathNfile`;
#	my @field = split( $dir, $look );
#	$path4SeismicUnixGui = $field[0] . $dir;

	my $dir       = 'App/SeismicUnixGui';
	my $pathNfile = $dir . '/sunix/data/data_in.pm';
	my $look      = `locate $pathNfile`;
	my @field     = split( $dir, $look );
	$path4SeismicUnixGui = $field[0] . $dir;

	my $result = $path4SeismicUnixGui;

	#	my $local_dir= getcwd();
	#    my $up2dir = '/../../';
	#	$path4SeismicUnixGui = $local_dir.$up2dir;
	#	my $result = $path4SeismicUnixGui;
	#	print("L_SU_global_constants,_default_path=$result\n");

	return ($result);
}

#
#sub _get_path4SeismicUnixGui {
#	my ($self) = @_;
#	if ( length $path4SeismicUnixGui ) {
#
#		my $result = $path4SeismicUnixGui;
#		return ($result);
#
#	}
#	else {
#		print(
#			"L_SU_global_constants, _get_path4SeismicUnixGui,missing variable\n"
#		);
#	}
#	return ();
#}
#

sub alias_superflow_names_h {

	my ($self) = @_;
	return ($alias_superflow_names_h);

}

sub alias_FileDialog_button_label_aref {    # array ref
											#my 	$self = @_;
	return ( \@alias_FileDialog_button_label );
}

sub alias_help_menubutton_label_aref {
#	my ($self,$variable) = @_; # array ref
	my $result = \@alias_help_menubutton_label;
	return ( $result );

}

sub alias_help_menubutton_label_h {    # hash ref

	return ($alias_help_menubutton_label_h);
}

sub alias_superflow_names_aref {

	return ( \@alias_superflow_names );

}

sub alias_superflow_spec_names_h {

	return ($alias_superflow_spec_names_h);
}

sub developer_sunix_categories_aref {

	return ( \@developer_sunix_categories );

}

sub developer_Tools_categories_aref {

	return ( \@developer_Tools_categories );

}

#sub developer_Tools_categories_h {
#
#	return ( $developer_Tools_categories_h );
#
#}

sub file_dialog_type_aref {

	return ( \@file_dialog_type );
}

sub file_dialog_type_href {

	return ($file_dialog_type_h);
}

sub flow_type_aref {

	return ( \@flow_type );
}

sub flow_type_href {

	return ($flow_type_h);
}

sub get_path4SeismicUnixGui {
	my ($self) = @_;
	if ( length $path4SeismicUnixGui ) {

		my $result = $path4SeismicUnixGui;
		return ($result);

	}
	else {
		print(
			"L_SU_global_constants, get_path4SeismicUnixGui,missing variable\n"
		);
	}
	return ();
}
#
#=head2 sub get_pathNmodule_spec
#
#=cut
#
#sub get_pathNmodule_spec {
#	my ($self) = @_;
#
#	if ( length $L_SU_global_constants->{_program_name} ) {
#
#		my $program_name   = $L_SU_global_constants->{_program_name};
#		my $module_spec    = $program_name . '_spec';
#		my $module_spec_pm = $module_spec . '.pm';
#		_set_file_name($module_spec_pm);
#
#		my $path4spec = _get_path4spec_file();
#
#		my $pathNmodule_spec = $path4spec . '/' . $module_spec;
#
#		# carp "pathNmodule_pm = $pathNmodule_pm";
#		my $result = $pathNmodule_spec;
#		return ($result);
#
#	}
#	else {
#		carp "missing program name";
#		return ();
#	}
#
#}
#
#=head2 sub get_pathNmodule_spec_pm
#
#=cut
#
#sub get_pathNmodule_spec_pm {
#	my ($self) = @_;
#
#	if ( length $L_SU_global_constants->{_program_name} ) {
#
#		my $program_name   = $L_SU_global_constants->{_program_name};
#		my $module_spec_pm = $program_name . '_spec.pm';
#		_set_file_name($module_spec_pm);
#
#		my $path4spec = _get_path4spec_file();
#
#		my $pathNmodule_spec_pm = $path4spec . '/' . $module_spec_pm;
#
#		# carp"pathNmodule_pm = $pathNmodule_pm";
#		my $result = $pathNmodule_spec_pm;
#		return ($result);
#
#	}
#	else {
#		carp "missing program name";
#		return ();
#	}
#
#}

sub help_menubutton_type_href {

	return ($help_menubutton_type_h);
}

sub number_from_color_href {

	my ($self) = @_;
	return ($number_from_color);

}

sub alias_superflow_config_names_aref {
	return ( \@alias_superflow_config_names );
}

sub set_file_name {

	my ( $self, $file_name ) = @_;

	if ( length $file_name ) {

		$L_SU_global_constants->{_file_name} = $file_name;

#		print("L_SU_global_constants,set_file_name,set_file_name = $L_SU_global_constants->{_file_name}\n");

	}
	else {
		print("L_SU_global_constants,set_file_name,missing variable");
	}

}

sub superflow_config_names_aref {
		my (@self) = @_;
	return ( \@superflow_config_names );
}

sub superflow_names_aref {
		my (@self) = @_;
	return ( \@superflow_names );
}

sub superflow_names_gui_aref {
	my (@self) = @_;
	return ( \@superflow_names_gui );

}

sub superflow_names_gui_h {
	my (@self) = @_;
	return ( $superflow_names_gui_h );

}

sub global_libs {
	my (@self) = @_;

	# empty string is predefined herein
	if ( length $path4SeismicUnixGui ) {

#		print(
#"1. L_SU_global_constants, global_libs,my L_SU = $path4SeismicUnixGui\n"
#		);

		my $global_libs = {
			_configs             => $path4SeismicUnixGui . '/configs',
			_configs_big_streams => $path4SeismicUnixGui
			  . '/configs/big_streams',
			_developer    => $path4SeismicUnixGui . '/developer/Stripped',
			_misc         => $path4SeismicUnixGui . '/misc',
			_param        => $path4SeismicUnixGui . '/configs/',
			_script       => $path4SeismicUnixGui . '/script/',
			_specs        => $path4SeismicUnixGui . '/specs',
			_sunix        => $path4SeismicUnixGui . '/sunix',
			_big_streams  => $path4SeismicUnixGui . '/big_streams/',
			_images       => $path4SeismicUnixGui . '/images/',
			_default_path => './',
		};

		return ($global_libs);

	}
	else {
		my $path4SeismicUnixGui = _default_path();

#		print("2. L_SU_global_constants, global_libs,my L_SU = $path4SeismicUnixGui\n");

		my $global_libs = {
			_configs             => $path4SeismicUnixGui . '/configs',
			_configs_big_streams => $path4SeismicUnixGui
			  . '/configs/big_streams',
			_developer    => $path4SeismicUnixGui . '/developer/Stripped',
			_misc         => $path4SeismicUnixGui . '/misc',
			_param        => $path4SeismicUnixGui . '/configs/',
			_script       => $path4SeismicUnixGui . '/script/',
			_specs        => $path4SeismicUnixGui . '/specs',
			_sunix        => $path4SeismicUnixGui . '/sunix',
			_big_streams  => $path4SeismicUnixGui . '/big_streams/',
			_images       => $path4SeismicUnixGui . '/images/',
			_default_path => './',
		};

		return ($global_libs);
	}

}

sub purpose {
	return ($purpose);
}

sub superflow_names_h {
	return ($superflow_names_h);
}

sub var {
	my ($self) = @_;

	#	print "got to var\n";
	return ($var);
}

sub param {
	return ($param);
}

1;
