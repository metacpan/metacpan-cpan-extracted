
=head1 DOCUMENTATION

=head2 SYNOPSIS 

	NAME:     SetProject 
	Author:   Juan M. Lorenzo 
	Date:     December 15, 2011 
	Purpose:  Create Project Directories  
 		      makes system-wide and local directories
        Details:  "sub-packages" use~/Servilleta_demos/seismics/
                  Project_Variables package 

        Usage:    directories can be turned
                  on/off with comment marks ("#")
=head2 NEEDS

 App::SeismicUnixGui::misc::manage_dirs_by package

=cut
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();
use aliased 'App::SeismicUnixGui::misc::manage_dirs_by';

my ($DATA_SEISMIC)      = $Project->DATA_SEISMIC();
my ($DATA_SEISMIC_DAT)  = $Project->DATA_SEISMIC_DAT();
my ($TEMP_DATA_GEOMAPS) = $Project->TEMP_DATA_GEOMAPS();

#my ($ANTELOPE)                    = $Project->ANTELOPE();
my ($ISOLA)                        = $Project->ISOLA();
my ($PROJECT_HOME)                 = $Project->PROJECT_HOME();
my ($DATA_GAMMA_WELL_TXT)          = $Project->DATA_GAMMA_WELL_TXT();
my ($DATA_GEOMAPS)                 = $Project->DATA_GEOMAPS();
my ($DATA_GEOMAPS_BIN)             = $Project->DATA_GEOMAPS_BIN();
my ($DATA_GEOTECH_WELL_TXT)        = $Project->DATA_GEOTECH_WELL_TXT();
my ($DATA_GEOTECH_WELL_XL)         = $Project->DATA_GEOTECH_WELL_XL();
#my ($GEOTECH)                     = $Project->GEOTECH();
my ($GEOMAPS_IMAGES)               = $Project->GEOMAPS_IMAGES();
my ($GEOMAPS_IMAGES_JPEG)          = $Project->GEOMAPS_IMAGES_JPEG();
my ($GEOMAPS_IMAGES_PNG)           = $Project->GEOMAPS_IMAGES_PNG();
my ($GEOMAPS_IMAGES_TIF)           = $Project->GEOMAPS_IMAGES_TIF();
my ($GEOMAPS_IMAGES_PS)            = $Project->GEOMAPS_IMAGES_PS();
my ($DATA_GEOMAPS_TEXT)            = $Project->DATA_GEOMAPS_TEXT();
my ($DATA_GEOMAPS_TOPO)            = $Project->DATA_GEOMAPS_TOPO();
my ($DATA_RESISTIVITY_SURFACE)     = $Project->DATA_RESISTIVITY_SURFACE();
my ($DATA_RESISTIVITY_SURFACE_TXT) = $Project->DATA_RESISTIVITY_SURFACE_TXT();
my ($DATA_RESISTIVITY_WELL)        = $Project->DATA_RESISTIVITY_WELL();
my ($DATA_RESISTIVITY_WELL_TXT)    = $Project->DATA_RESISTIVITY_WELL_TXT();
my ($DATA_SEISMIC_BIN)             = $Project->DATA_SEISMIC_BIN();
my ($DATA_SEISMIC_XL)              = $Project->DATA_SEISMIC_XL();
my ($DATA_SEISMIC_ININT)           = $Project->DATA_SEISMIC_ININT();
my ($DATA_SEISMIC_MATLAB)          = $Project->DATA_SEISMIC_MATLAB();
my ($DATA_SEISMIC_R)               = $Project->DATA_SEISMIC_R();
my ($DATA_SEISMIC_RSEIS)           = $Project->DATA_SEISMIC_RSEIS();
my ($DATA_SEISMIC_SAC)             = $Project->DATA_SEISMIC_SAC();
my ($DATA_SEISMIC_PASSCAL_SEGY)    = $Project->DATA_SEISMIC_PASSCAL_SEGY();
my ($DATA_SEISMIC_SIERRA_SEGY)     = $Project->DATA_SEISMIC_SIERRA_SEGY();
my ($DATA_SEISMIC_SEGY)            = $Project->DATA_SEISMIC_SEGY();
my ($DATA_SEISMIC_SU)              = $Project->DATA_SEISMIC_SU();
my ($DATA_SEISMIC_SEG2)            = $Project->DATA_SEISMIC_SEG2();
my ($DATA_SEISMIC_SEGB)            = $Project->DATA_SEISMIC_SEGB();
my ($DATA_SEISMIC_SEGD)            = $Project->DATA_SEISMIC_SEGD();
my ($DATA_SEISMIC_SEGY_RAW)        = $Project->DATA_SEISMIC_SEGY_RAW();
my ($DATA_SEISMIC_TXT)             = $Project->DATA_SEISMIC_TXT();
my ($DATA_SEISMIC_SU_RAW)          = $Project->DATA_SEISMIC_SU_RAW();
my ($DATABASE_SEISMIC_SQLITE)      = $Project->DATABASE_SEISMIC_SQLITE;
my ($GEOPSY)                       = $Project->GEOPSY;
my ($GIF_SEISMIC)                  = $Project->GIF_SEISMIC();
my ($GMT_SEISMIC)                  = $Project->GMT_SEISMIC();
my ($GMT_GEOMAPS)                  = $Project->GMT_GEOMAPS();
my ($JPEG_SEISMIC)                 = $Project->JPEG_SEISMIC();
my ($LIBRE_IMPRESS_SEISMIC)        = $Project->LIBRE_IMPRESS_SEISMIC();
my ($C_SEISMIC)                    = $Project->C_SEISMIC();
my ($CPP_SEISMIC)                  = $Project->CPP_SEISMIC();
my ($MATLAB_SEISMIC)               = $Project->MATLAB_SEISMIC();
my ($MATLAB_WELL)                  = $Project->MATLAB_WELL();
my ($MATLAB_GEOMAPS)               = $Project->MATLAB_GEOMAPS();
my ($IMMODPG)                      = $Project->IMMODPG();
my ($IMMODPG_INVISIBLE)            = $Project->IMMODPG_INVISIBLE();
my ($MMODPG)             		   = $Project->MMODPG();
my ($PL_RESISTIVITY_SURFACE) = $Project->PL_RESISTIVITY_SURFACE();
my ($PL_SEISMIC)                   = $Project->PL_SEISMIC();
my ($PL_GEOMAPS)                   = $Project->PL_GEOMAPS();
my ($PNG_SEISMIC)                 = $Project->PNG();
#my ($R_WELL)                       = $Project->R_WELL();
my ($PL_WELL)                      = $Project->PL_WELL();
my ($PS_SEISMIC)                   = $Project->PS_SEISMIC();
my ($PS_WELL)                      = $Project->PS_WELL();
my ($R_RESISTIVITY_SURFACE)        = $Project->R_RESISTIVITY_SURFACE();
my ($R_RESISTIVITY_WELL)           = $Project->R_RESISTIVITY_WELL();
my ($R_GAMMA_WELL)                 = $Project->R_GAMMA_WELL();
my ($R_SEISMIC)                    = $Project->R_SEISMIC();
my ($SH_SEISMIC)                   = $Project->SH_SEISMIC();
my ($TEMP_DATA_SEISMIC)            = $Project->TEMP_DATA_SEISMIC();
my ($TEMP_DATA_SEISMIC_SU)         = $Project->TEMP_DATA_SEISMIC_SU();
my ($TEMP_FAST_TOMO)               = $Project->TEMP_FAST_TOMO();
my ($WELL)                         = $Project->WELL();
#my ($DATA_WELL)                    = $Project->DATA_WELL();


=head2 Creates necessary directories

=cut

#manage_dirs_by->make_dir($DATA_SEISMIC);
#manage_dirs_by->make_dir($DATA_SEISMIC_DAT);
#manage_dirs_by->make_dir($TEMP_DATA_GEOMAPS);

# manage_dirs_by->make_dir($HOME);
manage_dirs_by->make_dir($PROJECT_HOME);

# manage_dirs_by->make_dir($ANTELOPE);
# manage_dirs_by->make_dir($DATA_GAMMA_WELL_TXT);
manage_dirs_by->make_dir($DATA_GEOMAPS);

#manage_dirs_by->make_dir($GEOMAPS_IMAGES);
manage_dirs_by->make_dir($GEOMAPS_IMAGES_JPEG);
manage_dirs_by->make_dir($GEOMAPS_IMAGES_PNG);

#manage_dirs_by->make_dir($GEOMAPS_BIN);
#manage_dirs_by->make_dir($GEOMAPS_IMAGES_TIF);
manage_dirs_by->make_dir($GEOMAPS_IMAGES_PS);

# manage_dirs_by->make_dir($DATA_GEOMAPS_TEXT);
manage_dirs_by->make_dir($DATA_GEOMAPS_TOPO);

manage_dirs_by->make_dir($DATA_GEOTECH_WELL_TXT);
manage_dirs_by->make_dir($DATA_GEOTECH_WELL_XL);

manage_dirs_by->make_dir($DATA_RESISTIVITY_SURFACE);
manage_dirs_by->make_dir($PL_RESISTIVITY_SURFACE);
manage_dirs_by->make_dir($DATA_RESISTIVITY_SURFACE_TXT);
#  manage_dirs_by->make_dir($DATA_RESISTIVITY_WELL);
# manage_dirs_by->make_dir($DATA_RESISTIVITY_WELL_TXT);
# manage_dirs_by->make_dir($DATA_SEISMIC_BIN);
manage_dirs_by->make_dir($DATA_SEISMIC_XL);
# manage_dirs_by->make_dir($DATA_SEISMIC_ININT);
manage_dirs_by->make_dir($DATA_SEISMIC_MATLAB);
manage_dirs_by->make_dir($DATA_SEISMIC_R);

# manage_dirs_by->make_dir($DATA_SEISMIC_RSEIS);
# manage_dirs_by->make_dir($DATA_SEISMIC_SAC);
# manage_dirs_by->make_dir($DATA_SEISMIC_PASSCAL_SEGY);
# manage_dirs_by->make_dir($DATA_SEISMIC_SIERRA_SEGY);
# manage_dirs_by->make_dir($DATA_SEISMIC_SEGD);
# manage_dirs_by->make_dir($DATA_SEISMIC_SEG2);
# manage_dirs_by->make_dir($DATA_SEISMIC_SEGB);
# manage_dirs_by->make_dir($DATA_SEISMIC_SEGY);
# manage_dirs_by->make_dir($DATA_SEISMIC_SU);
# manage_dirs_by->make_dir($DATA_SEISMIC_SEGY_RAW);
# manage_dirs_by->make_dir($DATA_SEISMIC_SU_RAW);
# manage_dirs_by->make_dir($DATA_SEISMIC_TXT);
#manage_dirs_by->make_dir($DATA_WELL);

# manage_dirs_by->make_dir($DATABASE_SEISMIC_SQLITE);
# manage_dirs_by->make_dir($GEOPSY);
# manage_dirs_by->make_dir($ISOLA);
# manage_dirs_by->make_dir($GIF_SEISMIC);
# manage_dirs_by->make_dir($GMT_SEISMIC);
manage_dirs_by->make_dir($GMT_GEOMAPS);
#manage_dirs_by->make_dir($JPEG_SEISMIC);
# manage_dirs_by->make_dir($C_SEISMIC);
# manage_dirs_by->make_dir($CPP_SEISMIC);
# manage_dirs_by->make_dir($MATLAB_SEISMIC);
manage_dirs_by->make_dir($MATLAB_GEOMAPS);

# manage_dirs_by->make_dir($MATLAB_WELL);
# manage_dirs_by->make_dir($MMODPG);
# print("SetProject.pl,MMODPG_INVISIBLE=$MMODPG_INVISIBLE\n");
# manage_dirs_by->make_dir($IMMODPG_INVISIBLE);
manage_dirs_by->make_dir($PL_GEOMAPS);
# manage_dirs_by->make_dir($PNG_SEISMIC);
# manage_dirs_by->make_dir($PL_RESISTIVITY_SURFACE);
# manage_dirs_by->make_dir($PL_SEISMIC);

# manage_dirs_by->make_dir($PL_WELL);
# manage_dirs_by->make_dir($PS_SEISMIC);
# manage_dirs_by->make_dir($PS_WELL);
# manage_dirs_by->make_dir($R_RESISTIVITY_SURFACE);
# manage_dirs_by->make_dir($R_RESISTIVITY_WELL);
# manage_dirs_by->make_dir($R_GAMMA_WELL);
manage_dirs_by->make_dir($R_SEISMIC);

# manage_dirs_by->make_dir($R_WELL);
# manage_dirs_by->make_dir($SH_SEISMIC);
# manage_dirs_by->make_dir($TEMP_DATA_SEISMIC);
# manage_dirs_by->make_dir($TEMP_DATA_SEISMIC_SU);
# manage_dirs_by->make_dir($TEMP_FAST_TOMO);
manage_dirs_by->make_dir($WELL);
