
=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Sucat.pl
  Purpose: Concatenate a series files 
  AUTHOR:  Juan M. Lorenzo DEPENDS: on cat from bash 
  DATE:    May 25 2018
  
           Includes access to a simple configuration file
           Simple file is called Sucat.config
           Access to simple file is via Sucat2_config.pl
           Sucat2_config.pl uses Config::Simple (jdhedden)
           as well as SeismicUnix and SystemVariables 
           packages V 2.10
           
           April 9 2018
           removed dependency on Config::Simple (CPAN)
           
           V0.1.5 Now uses sucat.pm instead of bash commands

  DESCRIPTION: 

=head2 USAGE
 
 Sucat 
 Needs a local configuration file Sucat.config
 GUI will generate a new one if needed one, but will
 prefer to use the contents of an existant configuration file. 

=head2 Example Cases

Square brackets show abbreviations of default directories.
[$DATA_SEISMIC_TXT]:  is at: ~/txt/"subUser"/

 CASE 1A

 Use a list of complete file names (include suffixes if they have them
 but exclude the directory paths)
 for concatenating iVelan "pick files" (Vrms,time pairs)
 into the correct format.

 A "list.txt", which is found in the $DATA_SEISMIC_TXT directory contains, 
 e.g.,:
 ivpicks_sorted_par_L28Hz_Ibeam_geom4_cdp1
 ivpicks_sorted_par_L28Hz_Ibeam_geom4_cdp11

 The starting input format in "par" format is as follows:

 (for ivpicks_sorted_par_L28Hz_Ibeam_geom4_cdp1)
 tnmo=0.0189974,0.113193,0.153562,0.231926
 vnmo=59.4778,160.806,195.689,273.761

 (for ivpicks_sorted_par_L28Hz_Ibeam_geom4_cdp11)
 tnmo=0.0316623,0.0759894,0.129815
 vnmo=101.006,130.906,263.794

 The final output format is:

 cdp=3,5
 tnmo=0.0189974,0.113193,0.153562,0.231926
 vnmo=59.4778,160.806,195.689,273.761
 tnmo=0.0316623,0.0759894,0.129815
 vnmo=101.006,130.906,263.794
 
  (See ~sunix/shell/sucat.pm)
 If "data_type" = "velan" then the concatenated output file
 will automatically be reformatted for input into sunmo.

CASE 1B

 Use a list of complete file names (include suffixes if they have them
 but exclude the directory paths),
 for concatenating picked "mute files" (time, x-coordinate pairs)
 into the correct format.

 For example, a "list" called ""ute_list.txt"" [in $DATA_SEISMIC_TXT] contains:

itop_mute_par_All_SH_geom3_ep3
itop_mute_par_All_SH_geom3_ep4

 The starting input format in each  in "par" format:
tmute=0.0122645,0.0122645,0.00947713,0.0133795,0.0462707,0.0819493,0.134352,0.20
5152
xmute=1.18683,0.58898,2.75617,4.21343,10.9766,19.8322,36.9455,60.1121

tmute=0.0328725,0.0223064,0.0540049,0.105662,0.207214
xmute=0.397959,4.11054,13.7934,28.7942,60.7526

 For the final output format:
 Data_type is determined by parsing the file names and normally contains:
 "itop_mute", "ibot_mute" etc." '
    
 (See ~sunix/shell/sucat.pm)   
 If "data_type" = "itop_mute" or "ibot_mute" then the concatenated 
 output file will automatically be reformatted for input into
 "sumute". 

    GUI EXAMPLE:    
    
 Note that a list can only be used when the values of the prior
 6 parameters are BLANK, i.e., be sure to
 exclude values for first 6 parameters in GUI. 

 The input name should have an suffix= ".txt"
 SUG will recognize the extension but will not show the suffix
 in the GUI.
 An output name is also required. The suffix ".su"
 will be added automatically to whatever name you choose.
 Alternative directories are optional.

    first_file_number_in               =               
    last_file_number_in                =                
    number_of_files_in                 =                            
    input_suffix                       =               
    input_name_prefix                  =                  
    input_name_extension               =              
    list                               =  list [$DATA_SEISMIC_TXT]
    output_base_file_name              =  base_file_name
    alternative_inbound_directory      =               
    alternative_outbound_directory     =   
  
  
  An example of what can be inside the file: "list.txt":
  
  25.su
  26.su
  27.su       

---------------------------------------------------------------------------

CASE 2
 General concatenation of files with patterns in their names

 DO NOT use a list. 
 Instead, include values for at least the first 3 
 parameters in the GUI, 
 and up to and including values for all the remaining parametfile nameers,
 except the list name. A

 An output name is possible but not required. Note that it is assumed
 that the suffix and therefore directory of the output file has the
 same origin directory as the input files.  The input suffix is used
 to determine the origin directory. For example an su input suffix will
 point to a $DATA_SEISMIC_SU directory.
 
 Example:
  
    first_file_number_in                = 1000                
    last_file_number_in                 = 1001                
    number_of_files_in                  = 2                           
    input_suffix                        = su                  
    input_name_prefix                   = cdp                 
    input_name_extension                = _clean              
    list                               	=                
    output_base_file_name               = 1000_01 
    alternative_inbound_directory       =                   
    alternative_outbound_directory      =  
    
    The above case will produce carries out the following instruction:
    
    cat DIR1/cdp1000_clean.su DIR1/cdp1001_clean.su > DIR2/1000_01.su 
   
    
    A list CAN NOT be in use when 
    values exist for any of the following parameters:
    
    first_file_number_in                  = 1000                
    last_file_number_in                   = 1010                
    number_of_files_in                    = 11                               
    input_suffix                          = su           
    input_name_prefix                     = cdp                 
    input_name_extension                  = _clean
    
    
CASE 3
  
 If you want to use a list, the list
 is a file that contains one
 or more file names


 first_file_number_in                  = 
 last_file_number_in                   = 
 number_of_files_in                    = 
 input_suffix                          = 
 input_name_prefix                     = 
 input_name_extension                  = 
 list                                  = cat_list_good_sp [$DATA_SEISMIC_TXT]
 output_base_file_name                 = All_good_sp [$DATA_SEISMIC_SU]
 alternative_inbound_directory         = 
 alternative_outbound_directory        =


 CASE 4:
 
  first_file_number_in            = 1000 [$DATA_SEISMIC_SU]
  last_file_number_in             = 1010 [$DATA_SEISMIC_SU]
  number_of_files_in              = 11   [$DATA_SEISMIC_SU]
  input_suffix                    = _clean.su [$DATA_SEISMIC_SU]
  input_name_prefix               = 
  input_name_extension            = 
  output_base_file_name           = 1000_10 [$DATA_SEISMIC_SU]
  alternative_inbound_directory   = 
  alternative_outbound_directory  =

=head2 NOTES 

  The input and output default directories are 
  but these can be overridden by the values of the 
  alternative directories
    
 
=head2 CHANGES
 
  V 0.1.2 considers empty file_names May 30, 2019; NM
  V 0.1.3 includes additional concatenation for:
  (1) sorted ivpicks
  V 0.1.4 update NOTES 9.9.21
  V 0.1.5 improved USAGE 11.8.22
  V 0.1.6 requires lists to have a ".txt" suffix
      The Input directories for a generic
      "list.txt" is [$DATA_SEISMIC_TXT] May, 2023, NM

=cut

use Moose;
our $VERSION = '0.1.6';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::shell::sucat';
use aliased 'App::SeismicUnixGui::misc::manage_files_by';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($_cdp $_mute $in $itop_mute_par_ $ivpicks_sorted_par_ $out $on $go $to $suffix_ascii $off $suffix_su $suffix_txt);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Sucat_config';
use aliased 'App::SeismicUnixGui::specs::big_streams::Sucat_specB';

=head2 Declare variables 

    in local memory space

=cut

my ( @file_out, @flow, @items, @cat, @sufile_out );
my $outbound_directory;
my $inbound_directory;
my ( @ref_array, @sucat );
my $ref_array;
my $num_cdps;
my $outbound;

=head2 2. Instantiate classes:

 Create a new version of the package  with a unique name

=cut

my $Project     = Project_config->new();
my $control     = control->new();
my $log         = message->new();
my $run         = flow->new();
my $sucat       = sucat->new();
my $read        = readfiles->new();
my $Sucat_specB = Sucat_specB->new();

my $get          = L_SU_global_constants->new->new();
my $Sucat_config = Sucat_config->new();

=head2 Get configuration information

Establish default variables using a *_spec file
and defaults defined hereinf or the location of the list file;
in DATA_SEISMIC_TXT

=cut

my ( $CFG_h, $CFG_aref ) = $Sucat_config->get_values();
my $Sucat_spec_variables = $Sucat_specB->variables();

# defaults are for su-type data
my $DATA_DIR_IN_default  = $Sucat_spec_variables->{_DATA_DIR_IN};
my $DATA_DIR_OUT_default = $Sucat_spec_variables->{_DATA_DIR_OUT};
my $DATA_SEISMIC_TXT     = $Project->DATA_SEISMIC_TXT;

my $inbound_directory_default  = $DATA_DIR_IN_default;
my $outbound_directory_default = $DATA_DIR_OUT_default;
my $list_directory_default     = $DATA_SEISMIC_TXT;

$inbound_directory  = $inbound_directory_default;
$outbound_directory = $outbound_directory_default;
my $list_directory = $list_directory_default;

$sucat->list_directory($list_directory);

=head2 set global imported variables

=cut

my $var                  = $get->var();
my $empty_string         = $var->{_empty_string};
my $literal_empty_string = $var->{_literal_empty_string};

# print("Sucat.pl, literal_empty_string: ->$literal_empty_string<- \n");

=head2 set the different parameters

  includes  variables

=cut

my $alternative_outbound_directory = '';
my $alternative_inbound_directory  = '';

my $first_file_number_in = $CFG_h->{sucat}{1}{first_file_number_in};
my $last_file_number_in  = $CFG_h->{sucat}{1}{last_file_number_in};
my $number_of_files_in   = $CFG_h->{sucat}{1}{number_of_files_in};
my $output_base_file_name = $CFG_h->{sucat}{1}{output_base_file_name};
my $input_suffix         = $CFG_h->{sucat}{1}{input_suffix};
my $input_name_prefix    = $CFG_h->{sucat}{1}{input_name_prefix};
my $input_name_extension = $CFG_h->{sucat}{1}{input_name_extension};
my $list                 = $CFG_h->{sucat}{1}{list};
$alternative_inbound_directory =
  $CFG_h->{sucat}{1}{alternative_inbound_directory};
$alternative_outbound_directory =
  $CFG_h->{sucat}{1}{alternative_outbound_directory};

# print("0. Sucat.pl, selected inbound_directory=$inbound_directory  \n");

=head2 correct input format values

=cut

$list = $control->get_no_quotes($list);

# print("Sucat.pl, list: $list\n\n");
# print("Sucat.pl, output_base_file_name: $output_base_file_name\n\n");
# print("Sucat.pl, outbound_directory: $outbound_directory\n\n");

=head2 3. Consider compatible

parameter inputs with and without
a list

=cut

# CASE 1: new inbound and or/outbound directories replace defaults
if ( $alternative_outbound_directory ne $empty_string ) {

	$outbound_directory = $alternative_outbound_directory;

# print("1. Sucat.pl, selected alternative_outbound_directory  $outbound_directory\n");

}
elsif ( $alternative_outbound_directory eq $empty_string ) {

	if ( $list ne $empty_string ) {

		$outbound_directory = $DATA_DIR_OUT_default;

	}
	else {
		$outbound_directory = $DATA_DIR_OUT_default;
	}

   # print("2. Sucat.pl, selected outbound_directory $outbound_directory  \n");
}
else {
	# print("Sucat.pl, unexpected alternative_outbound_directory  \n");
}

if ( $alternative_inbound_directory ne $empty_string ) {

	$inbound_directory = $alternative_inbound_directory;

# print("3A. Sucat.pl, selected inbound_directory=$inbound_directory  \n");
# print("3B. Sucat.pl, selected alternative inbound_directory=$alternative_inbound_directory  \n");

}
elsif ( $alternative_inbound_directory eq $empty_string ) {

	if ( $list ne $empty_string ) {

		$inbound_directory = $list_directory_default;

	}
	else {
		#NADA $inbound_directory = $DATA_DIR_IN_default;
	}

	# print("4. Sucat.pl, selected inbound_directory=$inbound_directory  \n");
}
else {
	print("Sucat.pl, unexpected alternative_inbound_directory  \n");
}

# print("Sucat.pl,inbound_directory:---$inbound_directory--\n");
# print("Sucat.pl,outbound_directory:---$outbound_directory--\n");

=head2 3. Declare output file names and their paths

  inbound and outbound directories
  are defaulted but can be different

=cut

$file_out[1] = $output_base_file_name;    # always needed

if ( length $output_base_file_name ) {
	
	if ( $input_suffix ne $empty_string ) {

		$outbound =
		  $outbound_directory . '/' . $file_out[1] . '.' . $input_suffix;

	}
	elsif ( $input_suffix eq $empty_string ) {

		$outbound = $outbound_directory . '/' . $file_out[1];

	}
	else {
		print("Sucat.pl,unexpected empty string\n");
	}
	
	print("Sucat.pl,outbound=$outbound\n");
}
else {
	print("Sucat.pl, missing output  filename\n");
}

=header set up sucat

=cut

$sucat->clear();
$sucat->first_file_number_in($first_file_number_in);
$sucat->last_file_number_in($last_file_number_in);
$sucat->number_of_files_in($number_of_files_in);
$sucat->input_suffix($input_suffix);
$sucat->input_name_prefix($input_name_prefix);
$sucat->input_name_extension($input_name_extension);
$sucat->output_base_file_name($output_base_file_name);
$sucat->list($list);
$sucat->list_directory($list_directory);
$sucat->inbound_directory($inbound_directory);
$sucat->outbound_directory($outbound_directory);

=head2 4. create script to concatenate files

files may use either a default directory
or an alternative directory provided by the user
Also consider incompatible as well as compatible
parameter inputs

=cut

# CASE 1 If there is a list, we do not need numbers or
# other forms of names
if (    $list ne $empty_string
	and $first_file_number_in eq $empty_string
	and $last_file_number_in eq $empty_string
	and $number_of_files_in eq $empty_string
	and $input_suffix eq $empty_string
	and $input_name_prefix eq $empty_string
	and $input_name_extension eq $empty_string )
{

	#	print("2. Sucat.pl, list:---$list---\n");
	#	print("2. Sucat.pl, list_directory:---$list_directory---\n");
	#	print("2. Sucat.pl, list:---0:@$ref_array[0], 1:@$ref_array[1]\n");
	#	my $ans =scalar @$ref_array;
	#	print("2. Sucat.pl, num_rows---$ans\n");
	my $inbound_list = $list_directory . '/' . $list . $suffix_txt;

	#	print("1. Sucat.pl, inbound_list:---$inbound_list---\n");
	( $ref_array, $num_cdps ) = $read->cols_1p($inbound_list);
	$sucat->set_list_aref($ref_array);
	$sucat->data_type();

	# print("ref_array is num_cdps is $num_cdps\n\n");
}

# CASE 2 If there is no list but at least the first 3 file parameters exist
elsif ( $list eq $empty_string
	and $first_file_number_in ne $empty_string
	and $last_file_number_in ne $empty_string
	and $number_of_files_in ne $empty_string )
{

	# print("3. Sucat.pl, OK, NADA\n");

}
else {
	print(
		"Warning: Incorrect settings. Either: 
\t 1) Use a list without values for first 6 parameters. Include the output
\t name (the alternative directories are optional).
\t That is, a list can only be used when the values of the prior
\t 6 parameters are blank
\t 2) Do not use a list. Instead include values for at least the first 3 
\t parameters and up to and including values for all the remaining parameters,
\t except the list\n"
	);
}

$sucat[1] = $sucat->Step();

# outbound includes a suffix if su data is detected
# outbound also chooses DATA_SEISMIC_TXT path if
# data_type = $txt

$sucat->set_outbound($outbound);
my $new_outbound = $sucat->get_outbound();

=head2 A. DEFINE FLOW(S)

=cut 

@items   = ( $sucat[1], $out, $new_outbound, $go );

$flow[1] = $run->modules( \@items );

=head2  B. RUN FLOW(S)

=cut

$run->flow( \$flow[1] );

=head2 C. LOG FLOW(S)TO SCREEN AND FILE

=cut

$log->screen( $flow[1] );

#my $time = localtime;
#$log->time;
#$log->file( $flow[1] );
