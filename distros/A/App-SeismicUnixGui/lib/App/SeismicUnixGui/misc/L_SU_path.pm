package App::SeismicUnixGui::misc::L_SU_path;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: L_SUV_path 
 AUTHOR: 	Juan Lorenzo
 DATE: 		October 5, 2022

 DESCRIPTION 
 V0.01 set global paths    

 
=cut

=head2 USE

=head3 NOTES

Sets the environment variables on
first pass using BEGIN

getcwd points to the "local" directory from
which SeismicUnixGui is commanded

=head4 Examples


=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '0.0.1';
use Carp;
use Shell qw(echo);
use Cwd;

my $path4SeismicUnixGui_slash;
my $path4SeismicUnixGui_colon;
my $SeismicUnixGui;
#		my $local = getcwd();
#		print("L_SU_path, local=$local\n");
		
BEGIN {

	if ( length $ENV{'SeismicUnixGui'} ) {

		$path4SeismicUnixGui_slash = $ENV{'SeismicUnixGui'};
		
		my @pieces = split( /\/App\//, $path4SeismicUnixGui_slash );
		$path4SeismicUnixGui_colon = 'App/' . $pieces[1];
		$path4SeismicUnixGui_colon =~ s/\//::/g;
		# print("\n1.L_SU_path: path4SeismicUnixGui_slash = $path4SeismicUnixGui_slash\n");
		# print("\n1.L_SU_path: path4SeismicUnixGui_colon = $path4SeismicUnixGui_colon\n");
	}
	else {
		my $dir       = 'App/SeismicUnixGui';
		my $pathNfile = $dir . '/sunix/data/data_in.pm';
		my $look  = `locate $pathNfile`;
		my @field = split( $dir, $look );
		$path4SeismicUnixGui_slash = $field[0] . $dir;
		
		my @pieces = split( /\/App\//, $path4SeismicUnixGui_slash );
        $path4SeismicUnixGui_colon    = 'App/' . $pieces[1];
        $path4SeismicUnixGui_colon    =~ s/\//::/g;
		print("\nWarning: L_SU_path uses default: path4SeismicUnixGui_slash = $path4SeismicUnixGui_slash\n");
		#print("\n2.L_SU_path: path4SeismicUnixGui_slash = $path4SeismicUnixGui_slash\n");
		#print("\n2.L_SU_path: path4SeismicUnixGui_colon = $path4SeismicUnixGui_colon\n");		
		
	}
}

=head2 private hash

L_SU_path

=cut

my $L_SU_path = {

	_program_name => '',

};

my $global_libs_w_colon = {
	_big_streams         => $path4SeismicUnixGui_colon . '::big_streams',
	_configs             => $path4SeismicUnixGui_colon . '::configs',
	_configs_big_streams => $path4SeismicUnixGui_colon
	  . '::configs::big_streams',
	_messages          => $path4SeismicUnixGui_colon . '::messages',
	_misc              => $path4SeismicUnixGui_colon . '::misc',
	_specs             => $path4SeismicUnixGui_colon . '::specs',
	_specs_big_streams => $path4SeismicUnixGui_colon . '::specs',
	_sunix             => $path4SeismicUnixGui_colon . '::sunix',
};

my $global_libs_w_slash = {
	_big_streams         => $path4SeismicUnixGui_slash . '/big_streams/',
	_configs             => $path4SeismicUnixGui_slash . '/configs',
	_configs_big_streams => $path4SeismicUnixGui_slash . '/configs',
	_messages            => $path4SeismicUnixGui_slash . '/messages',
	_misc                => $path4SeismicUnixGui_slash . '/misc',
	_specs               => $path4SeismicUnixGui_slash . '/specs',
	_specs_big_streams   => $path4SeismicUnixGui_slash . '/specs',
	_sunix               => $path4SeismicUnixGui_slash . '/sunix',
};

my @developer_sunix_categories;
my @developer_tools_categories;

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
$developer_tools_categories[99] = 'big_streams';

=head2 Define paths

  for programs with a colon format instead of forward slashed

=cut

my $specifications_path_w_colon = {

	_BackupProject => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_RestoreProject => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_Sudipfilt => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_ProjectVariables => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_SetProject => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_iSpectralAnalysis => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_iVA => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_iTopMute => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_iBottomMute => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_Project => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_Synseis => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_Sseg2su => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_Sucat => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_immodpg => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],
	_iPick => $global_libs_w_colon->{_specs_big_streams} . '::'
	  . $developer_tools_categories[99],

	_ctrlstrip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_data_in => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_data_out => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_dt1tosu => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_segbread => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_segdread => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_segyread => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_segyscan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_segywrite => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_suoldtonew => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_supack1 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_supack2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_suswapbytes => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_suunpack1 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_suunpack2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wpc1uncomp2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wpccompress => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wpcuncompress => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wptcomp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wptuncomp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wtcomp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],
	_wtuncomp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[0],

	_sudatumk2dr => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[1],
	_sudatumk2ds => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[1],
	_sukdmdcr => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[1],
	_sukdmdcs => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[1],

	_subfilt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_succfilt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sucddecon => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sudipfilt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sueipofi => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sufilter => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sufrac => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sufwatrim => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sufxdecon => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sugroll => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_suk1k2filter => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sukfilter => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sulfaf => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sumedian => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_supef => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_suphase => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_suphidecon => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_supofilt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_supolar => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_susmgauss2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],
	_sutvband => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[3],

	_segyclean => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_segyhdrmod => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_segyhdrs => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_setbhed => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_su3dchart => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suabshw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suaddhead => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suaddstatics => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suahw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suascii => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suazimuth => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sucdpbin => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suchart => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suchw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sucliphead => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sucountkey => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4], 
	_sudumptrace => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suedit => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sugethw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suhtmath => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sukeycount => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sulcthw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sulhead => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_supaste => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_surandhw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_surange => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suresstat => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],	  
	_susehw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sushw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sustatic => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sustaticB => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sustaticrrs => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sustrip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_sutrcount => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suutm => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_suxedit => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],
	_swapbhed => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[4],

	_suinvco3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[5],
	_suinvvxzco => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[5],
	_suinvzco3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[5],

	_sudatumfd => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sugazmig => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sukdmig2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sukdmig3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_suktmig2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigfd => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigffd => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumiggbzo => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumiggbzoan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigprefd => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigpreffd => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigprepspi => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigpresp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigps => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigpspi => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigpsti => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigsplit => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigtk => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sumigtopo2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sustolt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],
	_sutifowler => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[6],

	_cat_su => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[12],
	_evince => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[12],
	_sugetgthr => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[12],
	_suputgthr => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[12],

	_addrvl3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_cellauto => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_elacheck => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_elamodel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_elaray => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_elasyn => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_elatriuni => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_gbbeam => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_grm => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_normray => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_raydata => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suaddevent => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suaddnoise => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sudgwaveform => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suea2df => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sufctanismod => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sufdmod1 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sufdmod2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sufdmod2_pml => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sugoupillaud => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sugoupillaudpo => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suimp2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suimp3d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suimpedance => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sujitter => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sukdsyn2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_sunull => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suplane => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_surandspike => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_surandstat => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suremac2d => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suremel2dan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_suspike => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susyncz => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susynlv => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susynlvcw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susynlvfti => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susynvxz => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],
	_susynvxzcs => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[7],

	_dzdv => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sucvs4fowler => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudivstack => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudmofk => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudmofkcw => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudmotivz => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudmotx => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sudmovz => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suilog => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suintvel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sulog => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sunmo => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sunmo_a => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_supws => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_surecip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sureduce => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_surelan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_surelanan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suresamp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sushift => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sustack => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sustkvel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sutaupnmo => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sutihaledmo => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sutivel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_sutsq => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suttoz => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suvel2df => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suvelan => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suvelan_nccs => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suvelan_nsel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],
	_suztot => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[8],

	_a2b => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_a2i => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_b2a => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_bhedtopar => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_cshotplot => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_float2ibm => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_ftnstrip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_ftnunstrip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_makevel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_mkparfile => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_transp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_unif2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_unif2aniso => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_unisam => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_unisam2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],
	_vel2stiff => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[9],

	_elaps => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_lcmap => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_lprop => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psbbox => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pscontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pscube => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pscubecontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psepsi => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psgraph => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psimage => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pslabel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psmanager => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psmerge => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_psmovie => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pswigb => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_pswigp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_scmap => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_spsplot => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supscontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supscube => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supscubecontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supsgraph => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supsimage => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supsmax => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supsmovie => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supswigb => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_supswigp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxcontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxgraph => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suximage => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxmax => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxmovie => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxpicker => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_suxwigb => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_xcontour => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],	  
	_xgraph => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_ximage => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_xmovie => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],
	_xpicker => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],	  
	_xwigb => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[2],

	_suflip => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_sugain => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_sugprfb => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_sukill => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_sumute => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_supad => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
    _suramp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],  
	_susort => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_susplit => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_suvcat => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],
	_suwind => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[11],

	_cpftrend => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_entropy => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_farith => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suacor => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suacorfrac => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_sualford => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suattributes => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suconv => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_sufwmix => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suhistogram => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suhrot => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suinterp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_sumax => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_sumean => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_sumix => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suop => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suop2 => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suxcor => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],
	_suxmax => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[13],

	_dctcomp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suamp => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_succepstrum => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_sucepstrum => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_sucwt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_succwt => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_sufft => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_sugabor => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suicepstrum => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suifft => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suminphase => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suphasevel => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suspecfk => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_suspecfx => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],
	_sutaup => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[14],

	_las2su => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],
	_subackus => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],
	_subackush => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],
	_sugassman => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],
	_sulprime => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],
	_suwellrf => $global_libs_w_colon->{_specs} . '::'
	  . $developer_sunix_categories[15],

};

=head2 Define paths
for programs
in standard linux format

=cut

my $specifications_path_w_slash = {

	_BackupProject => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_RestoreProject => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_Sudipfilt => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_ProjectVariables => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_SetProject => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_iSpectralAnalysis => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_iVA => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_iTopMute => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_iBottomMute => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_Project => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_Synseis => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_Sseg2su => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_Sucat => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_immodpg => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],
	_iPick => $global_libs_w_slash->{_specs_big_streams} . '/'
	  . $developer_tools_categories[99],

	_ctrlstrip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_data_in => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_data_out => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_dt1tosu => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_segbread => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_segdread => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_segyread => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_segyscan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_segywrite => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_suoldtonew => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_supack1 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_supack2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_suswapbytes => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_suunpack1 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_suunpack2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wpc1uncomp2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wpccompress => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wpcuncompress => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wptcomp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wptuncomp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wtcomp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],
	_wtuncomp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[0],

	_sudatumk2dr => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[1],
	_sudatumk2ds => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[1],
	_sukdmdcr => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[1],
	_sukdmdcs => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[1],

	_subfilt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_succfilt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sucddecon => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sudipfilt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sueipofi => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sufilter => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sufrac => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sufwatrim => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],	  
	_sufxdecon => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sugroll => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_suk1k2filter => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sukfilter => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sulfaf => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sumedian => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_supef => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_suphase => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_suphidecon => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_supofilt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_supolar => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_susmgauss2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],
	_sutvband => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[3],

	_segyclean => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_segyhdrmod => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_segyhdrs => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_setbhed => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_su3dchart => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suabshw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suaddhead => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suaddstatics => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suahw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suascii => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suazimuth => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sucdpbin => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suchart => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suchw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sucliphead => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sucountkey => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],  
	_sudumptrace => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suedit => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sugethw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suhtmath => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sukeycount => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sulcthw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sulhead => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_supaste => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_surandhw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_surange => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suresstat => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],	  
	_susehw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sushw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sustatic => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sustaticB => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sustaticrrs => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sustrip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_sutrcount => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suutm => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_suxedit => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],
	_swapbhed => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[4],

	_suinvco3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[5],
	_suinvvxzco => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[5],
	_suinvzco3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[5],

	_sudatumfd => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sugazmig => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sukdmig2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_suktmig2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sukdmig3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigfd => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigffd => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumiggbzo => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumiggbzoan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigprefd => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigpreffd => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigprepspi => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigpresp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigps => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],	  
	_sumigpspi => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigpsti => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigsplit => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigtk => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sumigtopo2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sustolt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],
	_sutifowler => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[6],

	_cat_su => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[12],
	_evince => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[12],
	_sugetgthr => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[12],
	_suputgthr => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[12],

	_addrvl3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_cellauto => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_elacheck => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_elamodel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_elaray => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_elasyn => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_elatriuni => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_gbbeam => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_grm => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_normray => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_raydata => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suaddevent => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suaddnoise => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sudgwaveform => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suea2df => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sufctanismod => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sufdmod1 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sufdmod2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sufdmod2_pml => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sugoupillaud => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sugoupillaudpo => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suimp2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suimp3d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suimpedance => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sujitter => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sukdsyn2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_sunull => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suplane => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_surandspike => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_surandstat => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suremac2d => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suremel2dan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_suspike => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susyncz => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susynlv => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susynlvcw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susynlvfti => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susynvxz => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],
	_susynvxzcs => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[7],

	_dzdv => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sucvs4fowler => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudivstack => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudmofk => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudmofkcw => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudmotivz => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudmotx => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sudmovz => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suilog => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suintvel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sulog => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sunmo => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sunmo_a => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_supws => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_surecip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sureduce => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_surelan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_surelanan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suresamp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sushift => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sustack => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sustkvel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sutaupnmo => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sutihaledmo => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sutivel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_sutsq => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suttoz => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suvel2df => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suvelan => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suvelan_nccs => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suvelan_nsel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],
	_suztot => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[8],

	_a2b => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_a2i => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_b2a => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_bhedtopar => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_cshotplot => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_float2ibm => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_ftnstrip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_ftnunstrip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_makevel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_mkparfile => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_transp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_unif2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_unif2aniso => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_unisam => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],
	_unisam2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],	  
	_vel2stiff => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[9],

	_elaps => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_lcmap => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_lprop => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psbbox => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pscontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pscube => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pscubecontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psepsi => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psgraph => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psimage => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pslabel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psmanager => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psmerge => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_psmovie => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pswigb => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_pswigp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_scmap => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_spsplot => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supscontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supscube => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supscubecontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supsgraph => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supsimage => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supsmax => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supsmovie => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supswigb => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_supswigp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxcontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxgraph => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suximage => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxmax => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxmovie => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxpicker => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_suxwigb => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_xcontour => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],	  
	_xgraph => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_ximage => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_xmovie => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],
	_xpicker => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],	  
	_xwigb => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[2],

	_suflip => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_sugain => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_sugprfb => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_sukill => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_sumute => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_supad => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_suramp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],	  
	_susort => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_susplit => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_suvcat => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],
	_suwind => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[11],

	_cpftrend => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_entropy => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_farith => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suacor => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suacorfrac => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_sualford => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suattributes => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suconv => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_sufwmix => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suhistogram => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suhrot => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suinterp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_sumax => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_sumean => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_sumix => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suop => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suop2 => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suxcor => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],
	_suxmax => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[13],

	_dctcomp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suamp => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_succepstrum => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_sucepstrum => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_sucwt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_succwt => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_sufft => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_sugabor => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suicepstrum => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suifft => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suminphase => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suphasevel => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suspecfk => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_suspecfx => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],
	_sutaup => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[14],

	_las2su => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],
	_subackus => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],
	_subackush => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],
	_sugassman => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],
	_sulprime => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],
	_suwellrf => $global_libs_w_slash->{_specs} . '/'
	  . $developer_sunix_categories[15],

};

sub get_path4spec_file_w_slash {
	my ($self) = @_;

	return ($specifications_path_w_slash);
}

sub get_path4spec_file_w_colon {
	my ($self) = @_;

	return ($specifications_path_w_colon);
}

sub get_pathNmodule_spec_w_colon {
	my ($self) = @_;

	if ( length $L_SU_path->{_program_name} ) {

		my $key         = '_' . $L_SU_path->{_program_name};
		my $module_spec = $L_SU_path->{_program_name} . '_spec';
		my $pathNmodule_spec_w_colon_pm =
		  $specifications_path_w_colon->{$key} . '::' . $module_spec;
		return ($pathNmodule_spec_w_colon_pm);
		carp "missing program name";

	}
	else {
		carp "missing program name";
	}
}

sub get_pathNmodule_spec_w_slash_pm {
	my ($self) = @_;

	if ( length $L_SU_path->{_program_name} ) {
		
#		print ("L_SU_path,get_pathNmodule_spec_w_slash_pm, program name: $L_SU_path->{_program_name}\n");

		my $key            = '_' . $L_SU_path->{_program_name};
		my $module_spec_pm = $L_SU_path->{_program_name} . '_spec' . '.pm';
		my $pathNmodule_spec_w_slash_pm =
		$specifications_path_w_slash->{$key} . '/' . $module_spec_pm;
#		print ("L_SU_path,get_pathNmodule_spec_w_slash_pm, $pathNmodule_spec_w_slash_pm\n");
		  
		return ($pathNmodule_spec_w_slash_pm);

	}
	else {
		carp "missing program name";
	}

}

sub set_program_name {

	my ( $self, $file ) = @_;

	if ( length $file ) {

		#		carp("my file is $file\n");
		$L_SU_path->{_program_name} = $file;

	}
	else {
		carp "missing program name";
	}

}
