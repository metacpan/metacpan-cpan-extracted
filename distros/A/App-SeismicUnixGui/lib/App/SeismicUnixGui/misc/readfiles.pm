package App::SeismicUnixGui::misc::readfiles;

use Moose;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: readfiles 
 AUTHOR: Juan Lorenzo
 DATE: Oct 29 2012
 DESCRIPTION read file operations
 Version 1use aliased 'App::SeismicUnixGui::misc::control'; # '0.0.3'
         2 May 31 2016, Mom's 83 birthday
         2.1 June 29, 2016 
 Add reading configuration file hashes

 Notes: 
 Package name is the same as the file name
 Moose is a package that allows an object-oriented
 syntax to organizing your programs

 STEPS ARE:

USAGE 1 

 Read a file with one colume of text 
 Read each line

 Example
        $readfiles->ref_file($list);
        $readfiles-Step();
=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

my $get = L_SU_global_constants->new();

# my $alias_superflow_name = $get->alias_superflow_names_h;
#print("readfiles, alias_superflow_name, fk is $alias_superflow_name->{fk}\n");
my $global_libs = $get->global_libs;

# my $alias_PV                    = $alias_superflow_name->{_ProjectVariables};
# my $alias_superflow_config_name = $get->alias_superflow_config_names_aref();

#WARNING---- watch out for missing underscore!!
# print("readfiles,fk alias_superflow_config_name : $$alias_superflow_config_name[0]\n");

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $readfiles = {
	_note                => '',
	_ref_file            => '',
	_file_name           => '',
	_parameter           => '',
	_path                => '',
	_program_name        => '',
	_program_name_config => '',
	_skip_lines          => '',
	_sunix_param_path    => $global_libs->{_param},
	_value               => '',
	_Step                => '',
};

=head2 sub clear:

 clean hash of its values

=cut

sub clear {
	$readfiles->{_note}                = '';
	$readfiles->{_ref_file}            = '';
	$readfiles->{_file_name}           = '';
	$readfiles->{_parameter}           = '';
	$readfiles->{_path}                = '';
	$readfiles->{_program_name}        = '';
	$readfiles->{_program_name_config} = '';
	$readfiles->{_skip_lines}          = '';
	$readfiles->{_program_name}        = '';
	$readfiles->{_value}               = '';
	$readfiles->{_Step}                = '';
}

=head2 sub cols_1 

 read files cols 1 in a text file
 open the file of interest
 first item has index=1

=cut

sub cols_1 {

	my ( $variable, $ref_origin ) = @_;

=pod 

 declare local variables  

=cut

	my $line;

=pod 

 counter, a number, row number  

=cut

	my $i = 1;
	my ( $x, $num_rows );
	my (@OFFSET);

	if ($ref_origin) {
		$readfiles->{_ref_file} = $ref_origin;

	   # print ("\n readfiles, cols_1, The input file is called $ref_origin\n");
		open( FILE, $readfiles->{_ref_file} )
		  || print("Can't open file_name, $!\n");

=pod 

 read contents of list, e.g. shotpoint geometry file, file names etc.
 
=cut

		while ( $line = <FILE> ) {

			# print("readfiles, col1,--$line--\n");
			chomp($line);
			my ($x) = $line;
			$OFFSET[$i] = $x;

			# print("\n Reading 1 col file:$OFFSET[$i]\n");
			$i = $i + 1;
		}

		close(FILE);

		$num_rows = $i - 1;

		#print out the number of lines of data for the user
		#print ("This file contains $num_rows rows of data\n\n\n");

	}
	return ( \@OFFSET, $num_rows );

}

=head2 sub cols_1p 

 read files cols 1 in a text file
 open the file of interest
 1st item has index=0
 exclude empty lines

=cut

sub cols_1p {

	my ( $variable, $ref_origin ) = @_;

=pod 

 declare local variables  

=cut

	my $line;

=pod 

 counter, a number, row number  

=cut

	my $i = 0;
	my ( $x, $num_rows );
	my (@OFFSET);

	if ($ref_origin) {
		$readfiles->{_ref_file} = $ref_origin;

	#	   print ("\n readfiles, cols_1, The input file is called $ref_origin\n");
		open( FILE, $readfiles->{_ref_file} )
		  || print("Can't open file_name, $!\n");

=pod 

 read contents of list, e.g. shotpoint geometry file, file names etc.
 
=cut

		while ( $line = <FILE> ) {

			# print("readfiles, col1,--$line--\n");
			chomp($line);

			if ( $line ne $empty_string ) {

				my ($x) = $line;
				$OFFSET[$i] = $x;

				# print("Reading 1 col file:$OFFSET[$i]\n");
				$i = $i + 1;
			}

		}

		close(FILE);

		$num_rows = $i;

		# print out the number of lines of data for the user
		# print ("This file contains $num_rows rows of data\n\n\n");

	}
	return ( \@OFFSET, $num_rows );

}

=head2 sub cols_2p 

 reads cols 1 and 2 in a text file

=cut

sub cols_2p {

	my ( $files, $ref_file ) = @_;

	$readfiles->{_ref_file} = $$ref_file if defined($ref_file);

	#print '$$ref_file= '.$$ref_file."\n\n";

	# open the file of interest
	open( FILE, $$ref_file ) || print("Can't open file_name, $!\n");

	# set the counter
	# uses the perl convention -- first index is 0
	my $i = 0;
	my ( @TIME, @OFFSET );

	# readfiles contents of shotpoint geometry file
	while ( my $line = <FILE> ) {

		#print("line $i is $line");
		chomp($line);
		my ( $t, $x ) = split( " +", $line );
		$TIME[$i]   = $t;
		$OFFSET[$i] = $x;
		$i          = $i + 1;
	}
	close(FILE);

	my $max_index = $i - 1;

	# print ("\nThis file contains ($max_index +1) row(s) of data\n");

	return ( \@TIME, \@OFFSET, $max_index );
}

=head2 sub cols_2 

 reads cols 1 and 2 in a text file
 
=cut

sub cols_2 {

	my ( $files, $ref_file ) = @_;
	$readfiles->{_ref_file} = $$ref_file if defined($ref_file);

	#print '$$ref_file= '.$$ref_file."\n\n";
	# open the file of interest
	open( FILE, $$ref_file ) || print("Can't open file_name, $!\n");

	#set the counter
	my $i = 1;
	my ( @TIME, @OFFSET );

	# readfiles contents of shotpoint geometry file
	while ( my $line = <FILE> ) {

		#print("\n$line");
		chomp($line);
		my ( $t, $x ) = split( " +", $line );
		$TIME[$i]   = $t;
		$OFFSET[$i] = $x;
		$i          = $i + 1;
	}
	close(FILE);

	my $num_rows = $i - 1;
	my $rows     = $num_rows;

	#print ("\nThis file contains $num_rows row(s) of data\n");

	#   to prevent contaminating outside variables
	my @TIME_OUT   = @TIME;
	my @OFFSET_OUT = @OFFSET;
	return ( \@TIME_OUT, \@OFFSET_OUT, $rows );

}

#=head2 sub  sunix_params
#
#sub sunix_params {
#  my ($self,$hash_ref) = @_;
#  my $prog_name  	= $hash_ref;
#  $ref_cfg 		= defaults($prog_name);
#  $size 	  	= ((scalar @$ref_cfg) )/2;
#
#   for ($k=0,$i=0; $k < $size; $k++,$i=$i+2) {
#     $param[$k] 	= @$ref_cfg[$i];
#     $j 		=  $i + 1;
#     $values[$k] 	= @$ref_cfg[$j];
#     if($values[$k] eq $nu) {
#       $checkbutton_on_off[$k]     = $off;
#     }
#     else {
#       $checkbutton_on_off[$k]      = $on;
#     }
#   }
#
#  return(\@param,\@values,\@checkbutton_on_off);
#}
#
#=cut
#=head2  sub config
#deprecated in L_SU V0.3.6
#
# input is hash key and value pair
# Simple reads configuration file and
# cretes a hash with parameters (keys/names) and
# their values as assigned inside the configuration
# file
#
# Debug with
#
# print("1. program name is $program_name\n\n");
#
# local values of the programs have priority
#
# TODO: objectify name changes and
#   variable setting too!
#
# Load variables from local configuration file
#
#  tests: does this file Project_variables.config
#  exist?
#  from ./Project_variables.config
#  my %values 		= %{$cfg->vars()};
#  my $hash_size  		= keys %values;
#  print ("hash size is $hash_size\n\n");
#  print(" program name is $LSU->{_tool_name} \n\n");
#  print(" program name is $choice \n\n");
#else {  # all other normal programs whose configuration
#       #file resides locally
#       #$cfg = Config::Simple($readfiles->{_program_name_config});
#    } #test for iVA2.config
#
#
#  print("progr name is $program_name\n");
#
#=cut
#
#sub config {
#
#	my ( $self, $program_name ) = @_;
#	my @CFG;
#	my $ref_CFG;
#	my $cfg;
#	use Moose;
our $VERSION = '0.0.1';

#	# use Config::Simple;
#	use name;
#use App::SeismicUnixGui::misc::control '0.0.3';
#use aliased 'App::SeismicUnixGui::misc::control';
#	my $name    = name->new();
#	my $control = control->new();
#
#	if ( defined $program_name ) {
#		$readfiles->{_program_name_config} =
#			$name->change_config($program_name);
#		if ( -e "./$readfiles->{_program_name_config}" ) {
#
#=pod
#
# Values taken from the simple,local
# file: iVA2.config called
# LOCAL VARIABLES FOR THIS PROJECT
#     file_name  			= 'All_cmp'
#     cdp_first   			= 15
#     cdp_inc    			= 1
#     cdp_last    			= 100
#     data_scale    		 	= 1
#     freq    		        = '0,3,100,200'
#     number_of_velocities   = 300
#     first_velocity   	    = 3
#     velocity_increment   	= 10
#     min_semblance    	    = .0
#     max_semblance    	    = .75
#
#   print("home is $CFG[0]\n\n");
#   print("Project home is $CFG[1]\n\n");
#
#=cut
#
#			if ( $readfiles->{_program_name_config} eq 'iVA2.config' ) {
#				$cfg = Config::Simple( $readfiles->{_program_name_config} );
#				$CFG[0]  = "file_name";
#				$CFG[1]  = $cfg->param("file_name");
#				$CFG[2]  = "cdp_first";
#				$CFG[3]  = $cfg->param("cdp_first");
#				$CFG[4]  = "cdp_inc";
#				$CFG[5]  = $cfg->param("cdp_inc");
#				$CFG[6]  = "cdp_last";
#				$CFG[7]  = $cfg->param("cdp_last");
#				$CFG[8]  = "data_scale";
#				$CFG[9]  = $cfg->param("data_scale");
#				$CFG[10] = "freq";
#				$CFG[11] = $cfg->param("freq");
#				$CFG[12] = "number_of_velocities";
#				$CFG[13] = $cfg->param("number_of_velocities");
#				$CFG[14] = "first_velocity";
#				$CFG[15] = $cfg->param("first_velocity");
#				$CFG[16] = "velocity_increment";
#				$CFG[17] = $cfg->param("velocity_increment");
#				$CFG[18] = "min_semblance";
#				$CFG[19] = $cfg->param("min_semblance");
#				$CFG[20] = "max_semblance";
#				$CFG[21] = $cfg->param("max_semblance");

#=podfor iVA
#
# package control corrects for missing commas in number strings
# and file names with a suffix
#
#=cut
#
#			 #print(" 1. readfiles,config, for iVA2, freq is $CFG[11]\n\n");
#			 #print(" 1. readfiles,config, for iVA2, file_name is $CFG[1]\n\n");
#				$CFG[11] = $control->commas( \$CFG[11] );
#				$CFG[1]  = $control->su_file_name( \$CFG[1] );
#
#			 #print(" 2. readfiles,config, for iVA2, freq is $CFG[11]\n\n");
#			 #print(" 1. readfiles,config, for iVA2, file_name is $CFG[1]\n\n");
#
#			}
#
#			if ( $readfiles->{_program_name_config} eq
#				( $$alias_superflow_config_name[0] . '.config' ) )
#			{
#
## print("readfiles,fk alias_superflow_config_name : $$alias_superflow_config_name[0]\n");
#				$cfg = Config::Simple( $readfiles->{_program_name_config} );
#				$CFG[0]  = "file_name";
#				$CFG[1]  = $cfg->param("file_name");
#				$CFG[2]  = "sudipfilter_1_dt";
#				$CFG[3]  = $cfg->param("sudipfilter_1_dt");
#				$CFG[4]  = "sudipfilter_1_dx";
#				$CFG[5]  = $cfg->param("sudipfilter_1_dx");
#				$CFG[6]  = "sudipfilter_1_slopes";
#				$CFG[7]  = $cfg->param("sudipfilter_1_slopes");
#				$CFG[8]  = "sudipfilter_1_bias";
#				$CFG[9]  = $cfg->param("sudipfilter_1_bias");
#				$CFG[10] = "sudipfilter_1_amps";
#				$CFG[11] = $cfg->param("sudipfilter_1_amps");
#				$CFG[12] = "sudipfilter_2_dt";
#				$CFG[13] = $cfg->param("sudipfilter_2_dt");
#				$CFG[14] = "sudipfilter_2_dx";
#				$CFG[15] = $cfg->param("sudipfilter_2_dx");
#				$CFG[16] = "sudipfilter_2_slopes";
#				$CFG[17] = $cfg->param("sudipfilter_2_slopes");
#				$CFG[18] = "sudipfilter_2_bias";
#				$CFG[19] = $cfg->param("sudipfilter_2_bias");
#				$CFG[20] = "sudipfilter_2_amps";
#				$CFG[21] = $cfg->param("sudipfilter_2_amps");
#				$CFG[22] = "sufilter_1_freq";
#				$CFG[23] = $cfg->param("sufilter_1_freq");
#				$CFG[24] = "sufilter_1_amplitude";
#				$CFG[25] = $cfg->param("sufilter_1_amplitude");
#				$CFG[26] = "suspecfk_1_dt";
#				$CFG[27] = $cfg->param("suspecfk_1_dt");
#				$CFG[28] = "suspecfk_1_dx";
#				$CFG[29] = $cfg->param("suspecfk_1_dx");
#				$CFG[30] = "suwind_1_tmin";
#				$CFG[31] = $cfg->param("suwind_1_tmin");
#				$CFG[32] = "suwind_1_tmax";
#				$CFG[33] = $cfg->param("suwind_1_tmax");
#				$CFG[34] = "suwind_2_key";
#				$CFG[35] = $cfg->param("suwind_2_key");
#				$CFG[36] = "suwind_2_min";
#				$CFG[37] = $cfg->param("suwind_2_min");
#				$CFG[38] = "suwind_2_max";
#				$CFG[39] = $cfg->param("suwind_2_max");
#				$CFG[40] = "TOP_LEFT_sugain_pbal_switch";
#				$CFG[41] = $cfg->param("TOP_LEFT_sugain_pbal_switch");
#				$CFG[42] = "TOP_LEFT_sugain_pbal_switch";
#				$CFG[43] = $cfg->param("TOP_LEFT_sugain_pbal_switch");
#				$CFG[44] = "TOP_LEFT_sugain_pbal_switch";
#				$CFG[45] = $cfg->param("TOP_LEFT_sugain_pbal_switch");
#				$CFG[46] = "TOP_LEFT_sugain_pbal_switch";
#				$CFG[47] = $cfg->param("TOP_LEFT_sugain_pbal_switch");
#
#=pod
#
# Config::Simple interprets configuration values improperly
# for cases of numbers separated by commas
# Also, filename is file, without a suffix!
#
#=cut
#
#				$CFG[1]  = $control->su_file_name( \$CFG[1] );
#				$CFG[7]  = $control->commas( \$CFG[7] );
#				$CFG[11] = $control->commas( \$CFG[11] );
#				$CFG[17] = $control->commas( \$CFG[17] );
#				$CFG[21] = $control->commas( \$CFG[21] );
#				$CFG[23] = $control->commas( \$CFG[23] );
#				$CFG[25] = $control->commas( \$CFG[25] );
#			}
#			if ( $readfiles->{_program_name_config} eq 'Project' . '.config' ) {
#
#			}
#
#			if ( $readfiles->{_program_name_config} eq $alias_PV . '.config' ) {
#
#				$cfg = Config::Simple( $readfiles->{_program_name_config} );
#
#=head2
#
# contains all the configuration variables in
# perl script
#   HOME                 ='/home/gom';
#   PROJECT_HOME			= '/FalseRiver';;
#   site					= 'Bueche';
#   spare_dir			= '';
#   date					= '051216';
#   component			= 'H';
#   line					= '1';
#   subUser				= 'gom';
#   geomaps				= 'no'
#   print("home is $CFG[0]\n\n");
#   print("Project home is $CFG[1]\n\n");
#   $ref_CFG          	= default_Tkcfg($program_name);
#   $cfg -> write($CFG);
#   ($ref_labels_w,$ref_values_w) =  disappear(\@param,\@values,$entries);
#
#=cut
#
#				$CFG[0]  = "HOME";
#				$CFG[1]  = $cfg->param("HOME");
#				$CFG[2]  = "PROJECT_HOME";
#				$CFG[3]  = $cfg->param("PROJECT_HOME");
#				$CFG[4]  = "site";
#				$CFG[5]  = $cfg->param("site");
#				$CFG[6]  = "spare_dir";
#				$CFG[7]  = $cfg->param("spare_dir");
#				$CFG[8]  = "date";
#				$CFG[9]  = $cfg->param("date");
#				$CFG[10] = "component";
#				$CFG[11] = $cfg->param("component");
#				$CFG[12] = "line";
#				$CFG[13] = $cfg->param("line");
#				$CFG[14] = "subUser";
#				$CFG[15] = $cfg->param("subUser");
#				$CFG[14] = "geomaps";
#				$CFG[15] = $cfg->param("geomaps");
#
#=pod
#
# package control corrects for empty string
#
#=cut
#
#				$CFG[7] = $control->empty_string( \$CFG[7] );
#
#			}
#			else {    # all other normal programs whose configuration
#				 #file resides locally
#				 #$cfg = Config::Simple($readfiles->{_program_name_config});
#			}    #test for Project_Variables.config
#		}
#		else {
#			print(
#				"file $readfiles->{_program_name} should exist in current directory\n"
#			);
#			print(
#				"A new file:$readfiles->{_program_name}.config  will be created in the local directory\n"
#			);
#
#		}
#
#		return ( \@CFG );
#
#	}    # test entries
#}    #sub config

#=head2 sub defaults
#
# Read a default specification file
# Debug with
#    print ("self is $self,program is $program_name\n");
# print("params are @$ref_CFG\n");
# program name is a hash
#    print("params are @$ref_cfg\n");
#    print ("self is $self,program is $program_name\n");
#
#=cut
#
# sub defaults {
#  my ($self,$program_name) = @_ ;
#  my ($ref_cfg,$size);
#  use su_param;
#  my $su_param  = su_param->new();
#   if (defined $program_name) {
#    ($ref_cfg) =  $su_param->get($program_name);
#    $size      =  $su_param->size($program_name);
#    return ($ref_cfg);
#   }
# }
#

=head2 sub cfg

 file is a character array scalar 
 actually a scalar reference to a string

# my $file1 = '/usr/local/pl/System_Variables_config.pl';
# 					 print("readfiles,cfg,HOME=$CFG->{Project_Variables}{1}{HOME}\n")
#      print ("readfiles,cfg,Doing $file \n\n");
#      print ("A hash: variables $variables \n\n");
#                       #print ("log is $CFG->{log}{level} \n\n");
#                                   ## Check for errors
#my $file = '/usr/local/pl/System_Variables_config.pl';
#  my $file1 = '/usr/local/pl/Sudipfilt_config.pl';

=cut

sub cfg {

	my ( $variables, $file_char ) = @_;

	#print("1. readfiles,cfg,variables=$variables,file_char=$file_char\n");
	if ($file_char) {
		my $file = $file_char;
		our $err;
		{    # Put config file data into the namespace
			 # of this package

			package CFG;

			# Run $file
			# $file internally shares
			# global $CFG as a hash
			our $CFG;
			our $rc = do($file);

			# print("2. readfiles,cfg,file_name=$CFG->{file_name}\n");
			if ($@) {
				$::err = "ERROR: Failure compiling '$file' - $@";
			}
			elsif ( !defined($rc) ) {
				$::err = "ERROR: Failure reading '$file' - $!";
			}
			elsif ( !$rc ) {
				$::err = "ERROR: Failure processing '$file'";
			}
			return ( $err, $CFG );
		}

	}
}

=head2 sub configs 

  read configuration parameter files
  for seismic unix modules
  and for tool (superflow) modules
  (not for user-built flows)

  TODO: since sub configs= sub params
        ONLY NEED TO USE ONE OF THEM 
        AMONG ANY PROGRAM

=cut

sub configs {
	my ( $self, $program ) = @_;

	my @parameter;
	my @value;

	if ( length $program ) {

		my $control = control->new();
		my ( $this, $eq );

		$this = $program;

#		print("readfiles,configs,this program is:$this\n");
		my ($t, $t_whole, $x, $line, $max_index );
		
		my $index=0;

		open( my $IN, '<', $this )
		  or die "readfiles,configs: Can't open parameter file: '$this' $!";

=pod

   set the counter
   uses the perl convention -- first index is 0
   readfiles contents of a file
   print ("\nThis file contains ($max_index +1) row(s) of data\n");	
   print("line $i is $line");
   print ("\nThis file contains $num_rows row(s) of data\n");
  regex:
   trim white spaces from both ends
   split on '=' and its surrounding spaces
   
    control does the following:
     # 1. remove double quotes if they exist
     #  anywhere in the line
	$x =~ tr/"//d;
			
     # 2. remove extra single quotes if they exist at the start of the string
     $x =~ s/^'//;
     		
    # 3. remove extra single quotes if they exist at the end of the string     							
	$x =~ s/'$//; 
	# print("after removing only a last single quote: $x\n ");
	     		# 4. determine whether we have a string or a number
			my $fmt	=	0;
			$fmt  	= 	looks_like_number($x);
			
			if ($fmt) {
				# printf("$x looks like a number \n");
				# do nothing
				
			} else {		
				# printf("$x does not look like a number \n");
				my $x_as_string = '\''.$x.'\'';
				print (" Made $x into a string: $x_as_string\n");
				$x				= $x_as_string;
			}

=cut

		while ( $line = <$IN> ) {

#			print("1. readfiles,configs:raw line $index is $line\n");
			chomp($line);

   # skip lines starting where first non-white character is
   # modify 'm' starts ^ and ends $ as pertaining to each line and not each file
#      print("2. readfiles,configs:chomped line num is $line\n");
			next if $line =~ /^\s*#/m;

#	print("3.0 readfiles,configs:these lines have no starting '#' is $line\n");

			# trim white spaces from both ends
			$line =~ s/^\s+|\s+$//g;

#	print("3-1. readfiles,configs white spaces removed from ends,line is $line\n");

			# split line using =
			( $t_whole, $x ) = split( /\s+=\s*/, $line );
			$t = $t_whole;    # redundant in long run unless the
							  # following changes

#			print("3-1b. readfiles,configs $t\t$x \n");

			$x = $control->get_no_quotes($x);

#			print("3-1b. readfiles,configs $t\t$x \n");

			$x = $control->get_string_or_number($x);

#			print("3-1c. readfiles,configs $t\t$x \n");

			# only print out lines that are not empty
			if ($t) {

# print("3-2. readfiles,configs, line: $line\n parameter name, value: $t,$x\n");

				# save value and increment index
				# only if there is something to keep

				# test for "bad" x values
				if ( not defined $x ) {

#					print( "readfiles,configs, x is undefined\n");
					# print("                    replace x=$x  with ''\n");
					$x = '';

				}
				elsif ( $x eq "''" ) {

#			  print( "readfiles,configs, x is --$x--i.e., an empty string\n");
			  # print("                    replace x=$x  with ''\n");
				}
				elsif ( $x =~ /^ *$/ ) {

#				   print( "readfiles,configs, x contains 0 or more spaces\n");
				   # print("                    replace x=$x  with ''\n");
					$x = '';
				}
				elsif ( $x eq "'nu'" ) {
					$x = '';

					# print("                    replace x=$x  with ''\n");
				}

				# assume ALL bad x values have been caught , including x=0

#		        print("5-1. readfiles,configs:parameter name, value : $t,$x\n");
				$parameter[$index] = $t;
				$value[$index]     = $x;

#				print(
#					"5-2. index=$index; readfiles,configs: parameter,value :
#				 --$parameter[$index]--,--$value[$index]--\n"
#				);
			} # only non-empty lines
			
		$index++;	
		} # end of while

#		my $long = scalar @parameter;
#		print("L 837 long = $long\n");
# N.B. Read many times
		close($IN);
		$readfiles->{_parameter} = \@parameter;
		$readfiles->{_value}     = \@value;

		return ( \@parameter, \@value );

	}    # end program

}    # end sub

=head2 sub get_cols_3 

 reads cols 1 through 3 in a text file
 
=cut

sub get_cols_3 {

	my ($self) = @_;

	if (   $readfiles->{_skip_lines} ne $empty_string
		&& $readfiles->{_file_name} ne $empty_string
		&& $readfiles->{_path} ne $empty_string )
	{

		my $num_lines2skip = $readfiles->{_skip_lines};
		my $inbound_fh;
		my $inbound = $readfiles->{_path} . '/' . $readfiles->{_file_name};

		print("readfiles,get_cols_3 inbound = $inbound\n");

		open( $inbound_fh, '<', $inbound )
		  || print(
			"readfiles,cols_8,Can't open $readfiles->{_file_name}, $!\n");

		# set the counter
		my $ip_counter = 1;
		my $op_counter = 0;
		my $lines;
		my ( @A, @B, @C );

		# read contents of file
		while ( $lines = <$inbound_fh> ) {

			if ( $ip_counter > $num_lines2skip ) {

				#print("$lines");
				chomp($lines);
				my ( $a, $b, $c ) = split( " ", $lines );

				# print("\n $a $b, $c \n");

				$A[$op_counter] = $a;
				$B[$op_counter] = $b;
				$C[$op_counter] = $c;

				$op_counter++;

			}

			$ip_counter++;
		}

		# number of geophones stations in file
		my $num_rows = $op_counter;

		print(
			"readfiles, cols_3, The input file contains $num_rows row(s)\n\n");

		# close the file of interest
		close($inbound_fh);

		my @array_refs = ( \@A, \@B, \@C );

		return ( \@array_refs );

	}
	else {
		print(
			"readfiles,cols_3,missing either #skip_lines, path or file_name\n");
		print("file_name 				= $readfiles->{_file_name}\n");
		print("path 					= $readfiles->{_path}\n");
		print("number of skipped lines	= $readfiles->{_skip_lines}\n");
		return ();
	}

}

=head2 sub get_cols_8 

 reads cols 1 through 7 in a text file
 
=cut

sub get_cols_8 {

	my ($self) = @_;

	if (   $readfiles->{_skip_lines} ne $empty_string
		&& $readfiles->{_file_name} ne $empty_string
		&& $readfiles->{_path} ne $empty_string )
	{

		my $num_lines2skip = $readfiles->{_skip_lines};
		my $inbound_fh;
		my $inbound = $readfiles->{_path} . '/' . $readfiles->{_file_name};

		print("readfiles,cols_8 inbound = $inbound\n");

		open( $inbound_fh, '<', $inbound )
		  || print(
			"readfiles,cols_8,Can't open $readfiles->{_file_name}, $!\n");

		# set the counter
		my $ip_counter = 1;
		my $op_counter = 0;
		my $lines;
		my ( @A, @B, @C, @D, @E, @F, @G, @H );

		# read contents of file
		while ( $lines = <$inbound_fh> ) {

			if ( $ip_counter > $num_lines2skip ) {

				#print("$lines");
				chomp($lines);
				my ( $a, $b, $c, $d, $e, $f, $g, $h ) = split( " ", $lines );

				# print("\n $a $b, $c, $d, $e, $f, $g,$h \n");

				$A[$op_counter] = $a;
				$B[$op_counter] = $b;
				$C[$op_counter] = $c;
				$D[$op_counter] = $d;
				$E[$op_counter] = $e;
				$F[$op_counter] = $f;
				$G[$op_counter] = $g;
				$H[$op_counter] = $h;

				$op_counter++;

			}

			$ip_counter++;
		}

		# number of geophones stations in file
		my $num_rows = $op_counter;

		print(
			"readfiles, cols_8, The input file contains $num_rows row(s)\n\n");

		# close the file of interest
		close($inbound_fh);

		my @array_refs = ( \@A, \@B, \@C, \@D, \@E, \@F, \@G, \@H );

		return ( \@array_refs );

	}
	else {
		print(
			"readfiles,cols_8,missing either #skip_lines, path or file_name\n");
		print("file_name 				= $readfiles->{_file_name}\n");
		print("path 					= $readfiles->{_path}\n");
		print("number of skipped lines	= $readfiles->{_skip_lines}\n");
		return ();
	}

}

=head2 sub params

  read parameter files
  for seismic unix modules
    print("readfiles,params,this:$this\n");

=cut

sub params {
	my ( $self, $program ) = @_;
	if ($program) {
		my ( @parameter, @value );
		my ( $this,      $eq );

		$this = $program;
		my ( $i, $t, $x, $line, $max_index );
		open( FILE, $this ) || print(
			"readfiles,params: Can't open parameter file, $!\n
"
		);

=pod

   set the counter
   uses the perl convention -- first index is 0

   readfiles contents of shotpoint geometry file
 print ("\nThis file contains ($max_index +1) row(s) of data\n");	
   print("line $i is $line");
   print ("\nThis file contains $num_rows row(s) of data\n");

  regex:
   trim white spaces from both ends
   split on '=' and its surrounding spaces
=cut

		$i = 0;
		while ( $line = <FILE> ) {
			chomp($line);

			#print("line $i is $line\n");
			$line =~ s/^\s+|\s+$//g;    # trim white spaces from both ends
			( $t, $x ) = split( /\s+=\s+/, $line );

			#print("parameter  value : $t,$x\n");
			$parameter[$i] = $t;
			$value[$i]     = $x;

			#print("parameter,value : $parameter[$i],$value[$i]\n");
			$i++;
		}
		close(FILE);
		return ( \@parameter );
	}
}

=head2 sub set_file_name

=cut

sub set_file_name {
	my ( $self, $file_name ) = @_;

	if ( $file_name ne $empty_string ) {

		$readfiles->{_file_name} = $file_name;
		print("readfiles,set_file_name,path = $readfiles->{_file_name}\n");

	}
	else {
		print("readfiles,set_file_name,missing file_name\n");
	}
}

=head2 sub set_path

=cut

sub set_path {
	my ( $self, $path ) = @_;

	if ( $path ne $empty_string ) {

		$readfiles->{_path} = $path;

		# print("readfiles,set_path,path = $readfiles->{_path} \n");

	}
	else {
		print("readfiles,set_path,missing path\n");
	}

}

=head2 sub set_skip_lines

=cut

sub set_skip_lines {
	my ( $self, $skip_lines ) = @_;

	if ( $skip_lines ne $empty_string ) {

		$readfiles->{_skip_lines} = $skip_lines;

   # print("readfiles,set_skip_lines,skip_lines = $readfiles->{_skip_lines}\n");

	}
	else {
		print("readfiles,set_skip_lines,missing skip_lines\n");
	}
}

1;
