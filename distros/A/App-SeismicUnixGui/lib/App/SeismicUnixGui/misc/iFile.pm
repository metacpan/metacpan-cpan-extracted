package App::SeismicUnixGui::misc::iFile;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 Perl package: iFile.pm 
 AUTHOR: Juan Lorenzo
 DATE: Nov 3 2017 

 DESCRIPTION: 
 V 0.1 

 USED FOR:
 
 interactive file and path manipulation

 BASED ON:
 
 CHANGES: Nov 14 2018 now works on user-built
 		as well as pre-built superflows

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_path';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 Instantiation

=cut

my $L_SU_global_constants = L_SU_global_constants->new();
my $L_SU_path             = L_SU_path->new();
my $global_libs           = $L_SU_global_constants->global_libs();
my $alias_superflow_config_names_aref =
  $L_SU_global_constants->alias_superflow_config_names_aref();
my $alias_superflow_spec_names_h =
  $L_SU_global_constants->alias_superflow_spec_names_h();
my $superflow_config_names_aref =
  $L_SU_global_constants->superflow_config_names_aref();

my $default_path   = $global_libs->{_default_path};
my $var            = $L_SU_global_constants->var();
my $base_file_name = $var->{_base_file_name};

=head2 Declare local variables

=cut

my $on                 = $var->{_on};
my $off                = $var->{_off};
my $nu                 = $var->{_nu};
my $true               = $var->{_on};
my $false              = $var->{_off};
my $flow_type_href     = $L_SU_global_constants->flow_type_href();
my $file_dialog_type_h = $L_SU_global_constants->file_dialog_type_href();
my $empty_string       = $var->{_empty_string};

=head2 private hash

15 keys and values

=cut

my $iFile = {
	_dialog_type                        => '',
	_entry_button_label                 => '',
	_is_flow_listbox_grey_w             => '',
	_is_flow_listbox_pink_w             => '',
	_is_flow_listbox_green_w            => '',
	_is_flow_listbox_blue_w             => '',
	_is_flow_listbox_color_w            => '',
	_is_superflow_select_button         => '',
	_last_parameter_index_touched_color => '',
	_last_flow_listbox_touched_w        => '',
	_last_flow_index_touched            => '',
	_parameter_value_index              => '',
	_prog_name                          => '',
	_prog_name_sref                     => '',
	_values_aref                        => '',

};

=head2 _get_DATA_DIR_IN

works for both user-built and pre-built superflows
JML Nov-14-2018
Allows mutiple file  formats (bin,su,txt) within a single program: 6.4.21 

=cut

sub _get_DATA_DIR_IN {
	my ($self) = @_;

	my $Project = Project_config->new();

	my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN();
	my $DATA_SEISMIC_SEGB = $Project->DATA_SEISMIC_SEGB();
	my $DATA_SEISMIC_SEGD = $Project->DATA_SEISMIC_SEGD();
	my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY();
	my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU();
	my $PL_SEISMIC        = $Project->PL_SEISMIC();
	my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT();
	my $prog_name;
	my $result;

	# correct the superflow alias for _spec_name
	# N.B. that a hyphen is not needed inside the value of $prog_name
	if ( $iFile->{_flow_type} eq $flow_type_href->{_pre_built_superflow} ) {

		my $alias_prog_name = _get_prog_name();
		$prog_name = $alias_superflow_spec_names_h->{$alias_prog_name};

		#		print("iFile,_get_DATA_DIR_IN, my unaliased program = $prog_name\n");

	}
	elsif ( $iFile->{_flow_type} eq $flow_type_href->{_user_built} ) {

		$prog_name = _get_prog_name();

	}
	else {
		print("iFile, unexpected flow type \n");
	}

	if (   length $prog_name
		&& length( $iFile->{_parameter_value_index} ) )
	{

		$L_SU_path->set_program_name($prog_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		# INSTANTIATE
		my $package = $pathNmodule_spec_w_colon->new();

		#		my $L_SU_global_constants = L_SU_global_constants->new();
		#		my $module_spec_pm        = $prog_name . '_spec.pm';
		#
		#		$L_SU_global_constants->set_file_name($module_spec_pm);
		#		my $slash_path4spec = $L_SU_global_constants->get_path4spec_file();
		#		my $slash_pathNmodule_spec_pm =
		#		  $slash_path4spec . '/' . $module_spec_pm;
		#
		#		$L_SU_global_constants->set_program_name($prog_name);
		#		my $colon_pathNmodule_spec =
		#		  $L_SU_global_constants->get_colon_pathNmodule_spec();
		#
##	 	print("1. iFile _get_suffix_aref, prog_name: $slash_pathNmodule_spec_pm\n");
##	 	print("1.iFile, _get_suffix_aref, prog_name: $colon_pathNmodule_spec\n");
		#		require $slash_pathNmodule_spec_pm;
		#
		#		# INSTANTIATE
		#		my $package = $colon_pathNmodule_spec->new();

		# collect specifications of input and output directories
		# from a "program_spec".pm module
		my $specs_h      = $package->variables();
		my $DATA_PATH_IN = $specs_h->{_DATA_DIR_IN};

		$package->prefix_aref();
		my @prefix = @{ $package->get_prefix_aref() };
		my $index  = $iFile->{_parameter_value_index};

		if ( length $DATA_PATH_IN
			and ( length $index ) )
		{

			if ( $prefix[$index] ne $empty_string ) {

 # Case 1.A: Many possible defined prefixes
 # print("iFile, _get_DATA_DIR_IN, Case 1.A: Many possible defined prefixes\n");

 # Case 1.A: Many possible defined prefixes
 # print("iFile, _get_DATA_DIR_IN, Case 1.A: Many possible defined prefixes\n");

				if ( $prefix[$index] eq ( '$DATA_SEISMIC_SU' . ".'/'." ) ) {

					$result = $DATA_SEISMIC_SU;

				}
				elsif ( $prefix[$index] eq ( '$DATA_SEISMIC_BIN' . ".'/'." ) ) {

					$result = $DATA_SEISMIC_BIN;

#					print("iFile, _get_DATA_DIR_IN,for BIN; prefix[$index] =$prefix[$index]\n");

				}
				elsif ( $prefix[$index] eq ( '$DATA_SEISMIC_SEGB' . ".'/'." ) )
				{

					$result = $DATA_SEISMIC_SEGB;

#					print("iFile, _get_DATA_DIR_IN,for SEGB; prefix[$index] =$prefix[$index]\n");

				}
				elsif ( $prefix[$index] eq ( '$DATA_SEISMIC_SEGD' . ".'/'." ) )
				{

					$result = $DATA_SEISMIC_SEGD;

#					print("iFile, _get_DATA_DIR_IN,for SEGD; prefix[$index] =$prefix[$index]\n");

				}
				elsif ( $prefix[$index] eq ( '$DATA_SEISMIC_SEGY' . ".'/'." ) )
				{

					$result = $DATA_SEISMIC_SEGY;

#					print("iFile, _get_DATA_DIR_IN,for SEGY; prefix[$index] =$prefix[$index]\n");

				}
				elsif ( $prefix[$index] eq ( '$DATA_SEISMIC_TXT' . ".'/'." ) ) {

#					print("iFile, _get_DATA_DIR_IN for TXT; prefix[$index] =$prefix[$index]\n");
					$result = $DATA_SEISMIC_TXT;

				}
				elsif ( $prefix[$index] eq '$PL_SEISMIC/' ) {
					
					print("iFile, _get_DATA_DIR_IN for PL_SEISMIC; prefix[$index] =$prefix[$index]\n");

					$result = $PL_SEISMIC;

				}
				else {
					print("iFile, _get_DATA_DIR_IN, unexpected result \n");

#					print("iFile, _get_DATA_DIR_IN,  DATA_PATH_IN= $DATA_PATH_IN \n");
#					print("2. iFile, _get_DATA_DIR_IN,prefix[$index] ='$prefix[$index]'\n");
#					print( "3. iFile, _get_DATA_DIR_IN, 'DATA_SEISMIC_BIN' ='$DATA_SEISMIC_BIN' . " . '/' . "\n" );
#					print( "4. iFile, _get_DATA_DIR_IN, 'DATA_SEISMIC_TXT' ='$DATA_SEISMIC_TXT' . " . '/' . "\n" );
				}

			}
			elsif ( $prefix[$index] eq $empty_string ) {

				# Case 2.
				# No defined prefix
				# Skips ancillary prefix definitions and only
				# uses the first key value of _DATA_DIR_IN
				$result = $DATA_PATH_IN;

			}
			else {
				print("iFile, _get_DATA_DIR_IN, unexpected \n");
			}

		}
		else {
			print("iFile, _get_DATA_DIR_IN, mising values \n");

			#			print("iFile, $DATA_PATH_IN=$DATA_PATH_IN \n");
			#			print("iFile, index=$index\n");
		}

	}
	else {
		print("iFile,_get_DATA_DIR_IN, missing prog_name=$prog_name, OR \n");
		print(
"iFile,_get_DATA_DIR_IN, missing iFile->{_parameter_value_index}=$iFile->{_parameter_value_index}\n"
		);
	}

	#	print("iFile,get_Data_path, DATA_DIR_IN = $result\n");
	return ($result);
}

=head2 _get_DATA_DIR_OUT

=cut

sub _get_DATA_DIR_OUT {
	my ($self) = @_;
	my $DATA_PATH_OUT;

	my $prog_name = _get_prog_name();

	# print("iFile,get_Data_path, my program = $prog_name\n");

	if ($prog_name) {

		$L_SU_path->set_program_name($prog_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		# INSTANTIATE
		my $package = $pathNmodule_spec_w_colon->new();

  #		 use Module::Refresh; # reload updated module
  #	    my $refresher = Module::Refresh->new;
  #
  #		my $manage_files_by2 = manage_files_by2->new();
  #
  #		$manage_files_by2->set_program_name($prog_name);
  #		my $pathNmodule_pm   = $manage_files_by2->get_pathNmodule_pm();
  #		my $pathNmodule_spec = $manage_files_by2->get_pathNmodule_spec();
  #
  #	 #	print("1. _get_suffix_aref, prog_name: $program_name$pathNmodule_pm \n");
  #
  #		require $pathNmodule_pm;
  #
  #		#$refresher->refresh_module("$module_spec_pm");
  #
  #		# INSTANTIATE
  #		my $package = $pathNmodule_spec->new();

		#		my $module_spec    = $prog_name . '_spec';
		#		my $module_spec_pm = $module_spec . '.pm';
		#
		#		$L_SU_global_constants->set_file_name($module_spec_pm);
		#		my $path           = $L_SU_global_constants->get_path4spec_file();
		#		my $pathNmodule_pm = $path . '/' . $module_spec_pm;
		#
		#		require $pathNmodule_pm;
		#
		#		#		$refresher->refresh_module("$module_spec_pm");
		#		my $package = $module_spec->new;

		# collect specifications of input and output directories
		# fromt a program_spec.pm module
		my $specs_h = $package->variables();
		$DATA_PATH_OUT = $specs_h->{_DATA_DIR_OUT};

		# print("iFile,get_Data_path, DATA_PATH_OUT = $DATA_PATH_OUT\n");
		return ($DATA_PATH_OUT);

	}
	else {
		print("iFile,_get_DATA_DIR_OUT, missing prog_name\n");
		return ();
	}
}

=head2 sub get_Open_perl_flow_path 

=cut

sub get_Open_perl_flow_path {

	my ($self) = @_;

	my $Project    = Project_config->new();
	my $PL_SEISMIC = $Project->PL_SEISMIC();

	$iFile->{_path} = $PL_SEISMIC;

	my $path = $iFile->{_path};

	return ($path);
}

=head2 sub get_Open_path 

=cut

sub get_Open_path {

	my ($self) = @_;

	my $Project    = Project_config->new();
	my $PL_SEISMIC = $Project->PL_SEISMIC();

	$iFile->{_path} = $PL_SEISMIC;

	my $path = $iFile->{_path};
	return ($path);
}

=head2 sub get_SaveAs_path 

=cut

sub get_SaveAs_path {

	my ($self) = @_;

	my $Project    = Project_config->new();
	my $PL_SEISMIC = $Project->PL_SEISMIC();

	$iFile->{_path} = $PL_SEISMIC;

	my $path = $iFile->{_path};
	return ($path);
}

=head2 sub get_Data_path

 get DATA path from SPEC file
 corresponding to the program name
 make sure to remove unneeded ticks in strings
 
 used in user-built flows 
 for very specific programs (data_in, suop2)
 
 and for pre-built user flows in the general case
 
 TODO: separate the determination of data paths for user-built flows 
 and pre-built flows
 
=cut

sub get_Data_path {

	my ($self) = @_;

	my $entry_label = $iFile->{_entry_button_label};
	my $dialog_type = $iFile->{_dialog_type};

 #	print("iFile, get_Data_path, parameter label or name = $entry_label\n");
 #	print("iFile, Data_File,get_Data_path, base_file_name  = $base_file_name\n");
 #	print("iFile,get_Data_path,flow_type =$iFile->{_flow_type}\n");

	my $Project                   = Project_config->new();
	my $DATA_SEISMIC_BIN          = $Project->DATA_SEISMIC_BIN();
	my $DATA_SEISMIC_SU           = $Project->DATA_SEISMIC_SU();
	my $PL_SEISMIC                = $Project->PL_SEISMIC();
	my $DATA_SEISMIC_SEGB         = $Project->DATA_SEISMIC_SEGB();
	my $DATA_SEISMIC_SEGD         = $Project->DATA_SEISMIC_SEGD();
	my $DATA_SEISMIC_SEGY         = $Project->DATA_SEISMIC_SEGY();
	my $DATA_SEISMIC_TXT          = $Project->DATA_SEISMIC_TXT();
	my $DATA_SEISMIC_WELL_SYNSEIS = $Project->DATA_SEISMIC_WELL_SYNSEIS();
	my $PS_SEISMIC                = $Project->PS_SEISMIC();
	my $Data_PL_SEISMIC           = $Project->PL_SEISMIC();

	if ( $iFile->{_flow_type} eq $flow_type_href->{_user_built} ) {

		if ( $entry_label eq $base_file_name ) {

	   # CASE 1 user-built flows
	   # CASE 1A first label/name is base_file_name
	   #	print("CASE 1 iFile,get_Data_path,flow_type = $iFile->{_flow_type}\n");
	   # FOR A VERY SPECIFIC CASE (TODO: move all cases to the _spec files)

			my $suffix_type = @{ $iFile->{_values_aref} }[1];

			#	print("CASE 1 iFile,get_Data_path,suffix_type = $suffix_type\n");

			if ( $suffix_type eq 'su' or $suffix_type eq "'su'" ) {

				# CASE 1A.1
				# second (index=1)
				# second label/name = 'type' &&  value = 'su'
				# print("iFile,get_path,entry_button_label= $entry_label\n");
				# print("CASE 1A.1 iFile,get_Data_path=$DATA_SEISMIC_SU\n");
				$iFile->{_path} = $DATA_SEISMIC_SU;

			}
			elsif ($suffix_type eq 'segb'
				or $suffix_type eq "'segb'"
				or $suffix_type eq 'SEGB'
				or $suffix_type eq "'SEGB'"
				or $suffix_type eq 'sgb'
				or $suffix_type eq "'sgb'"
				or $suffix_type eq 'SGB'
				or $suffix_type eq "'SGB'" )
			{

				# CASE 1A.2
				# and second (index=1) 'segy\b'
				# if second label/name = 'type' &&  value = 'segb'

			   #				print("iFile,get_path,entry_button_label= $entry_label\n");
			   #				print("CASE 1A.2 iFile,get_Data_path,$DATA_SEISMIC_SEGB\n");
				$iFile->{_path} = $DATA_SEISMIC_SEGB;

			}
			elsif ($suffix_type eq 'segd'
				or $suffix_type eq "'segd'"
				or $suffix_type eq 'SEGD'
				or $suffix_type eq "'SEGD'"
				or $suffix_type eq 'sgd'
				or $suffix_type eq "'sgd'"
				or $suffix_type eq 'SGD'
				or $suffix_type eq "'SGD'" )
			{

				# CASE 1A.2
				# and second (index=1) 'segy\d'
				# if second label/name = 'type' &&  value = 'segd'

			   #				print("iFile,get_path,entry_button_label= $entry_label\n");
			   #				print("CASE 1A.2 iFile,get_Data_path,$DATA_SEISMIC_SEGD\n");
				$iFile->{_path} = $DATA_SEISMIC_SEGD;

			}
			elsif ($suffix_type eq 'segy'
				or $suffix_type eq "'segy'"
				or $suffix_type eq 'SEGY'
				or $suffix_type eq "'SEGY'"
				or $suffix_type eq 'sgy'
				or $suffix_type eq "'sgy'"
				or $suffix_type eq 'SGY'
				or $suffix_type eq "'SGY'" )
			{

				# CASE 1A.3
				# and second (index=1) 'segy'
				# if second label/name = 'type' &&  value = 'segy'

			   #				print("iFile,get_path,entry_button_label= $entry_label\n");
			   #				print("CASE 1A.3 iFile,get_Data_path,$DATA_SEISMIC_SEGY\n");
				$iFile->{_path} = $DATA_SEISMIC_SEGY;

			}
			elsif ($suffix_type eq 'txt'
				or $suffix_type eq 'TXT'
				or $suffix_type eq "'txt'"
				or $suffix_type eq "'TXT'"
				or $suffix_type eq 'text'
				or $suffix_type eq 'TEXT'
				or $suffix_type eq "'text'"
				or $suffix_type eq "'TEXT'"
				or $suffix_type eq 'ascii'
				or $suffix_type eq 'ASCII'
				or $suffix_type eq "'ascii'"
				or $suffix_type eq "'ASCII'" )
			{

				# CASE 1A.4
				# and second (index=1) text
				# if second label/name = 'type' &&  value is text

				# print("iFile,get_path,entry_button_label= $entry_label\n");
				# print("CASE 1A.4. iFile,get_Data_path,$DATA_SEISMIC_TXT\n");
				$iFile->{_path} = $DATA_SEISMIC_TXT;

			}
			elsif ($suffix_type eq 'bin'
				or $suffix_type eq 'BIN'
				or $suffix_type eq "'bin'"
				or $suffix_type eq "'BIN'" )
			{

				# CASE 1A.5
				# and second (index=1) entry value = binary data
				# if second label/name = 'type' &&  value = bin

				# print("iFile,get_path,entry_button_label= $entry_label\n");
				#				print("CASE 1A.5 iFile,get_Data_path,$DATA_SEISMIC_BIN\n");
				$iFile->{_path} = $DATA_SEISMIC_BIN;

			}
			elsif ($suffix_type eq 'ps'
				or $suffix_type eq 'PS'
				or $suffix_type eq "'ps'"
				or $suffix_type eq "'PS'" )
			{

				# CASE 1A.6
				# and second (index=1) entry value = postscript file
				# if second label/name = 'type' &&  value = ps

				# print("iFile,get_path,entry_button_label= $entry_label\n");
				# print("CASE 1A.6 iFile,get_Data_path,$DATA_SEISMIC_BIN\n");
				$iFile->{_path} = $PS_SEISMIC;

			}
			elsif ( $suffix_type eq $empty_string ) {

				# CASE 1A.7
				$iFile->{_path} = $PL_SEISMIC;

				#print("iFile,get_path,path=$iFile->{_path}\n");

			}
			else {
				$iFile->{_path} = $default_path;

				# CASE 1A.8	unrecognized data type
				print(
"CASE 1A.8 iFile,get_Data_path, unrecognized data type ... TB Added\n"
				);
			}

		}
#		elsif ($entry_label eq 'file1'
#			or $entry_label eq 'file2' )
#		{
#
#		# FOR ANOTHER VERY SPECIFIC CASE
#		# TODO remove?? becuase it is updated by prefix values inthe *_spec file?
#		# CASE 1B.1 : suop2
#		# first label/name   = 'file1'
#		# second label/name  = 'file2'
#			$iFile->{_path} = $DATA_SEISMIC_SU;
#
#			# print("CASE 1B.1 : iFile,get_path,path=$iFile->{_path}\n");
#
#		}
		elsif ( $entry_label ne $empty_string
			and $iFile->{_dialog_type} eq
			$file_dialog_type_h->{_Data_PL_SEISMIC} )
		{

# case 1B.2
# print("case 1B.2 iFile,get_Data_path, dialog_type=$iFile->{_dialog_type} \n");
			$iFile->{_path} = $Data_PL_SEISMIC;

		}
		elsif ( $entry_label ne $empty_string ) {

			# CASE 1B.3
			# which are pre-defined within the relevant spec files
			# by DATA_DIR_IN and DATA_DIR_OUT

			$iFile->{_path} = _get_DATA_DIR_IN;

	 #			print("CASE 1B.3 iFile,get_Data_path, DATA_DIR_IN= $iFile->{_path}\n");

		}
		elsif ( $entry_label eq $empty_string ) {

			# unlikely
			# CASE 1B.4
			#			print("CASE1B.4 1iFile,get_Data_path, entry_label is empty \n");
			#			print("iFile,get_Data_path, PL_SEISMIC is new chosen path \n");
			$iFile->{_path} = $PL_SEISMIC;

		}
		else {

			# CASE 1B.5
			$iFile->{_path} = $default_path;

#			print("CASE1B.5 iFile,get_Data_path, entry_label is empty \n");
# print("iFile,get_path,path=$iFile->{_path}\n");
# print("iFile, get_Data_path, entry label is neither base_file_name (i.e. without suffix) nor fileX \n");
		}

	}
	elsif ( $iFile->{_flow_type} eq $flow_type_href->{_pre_built_superflow} ) {

		# CASES 2: for superflows

		if ( $entry_label eq $base_file_name ) {

			# CASE 2A.1:
			# first label/name = 'base_file_name
			# and second label/name  = 'type',
			# and second (index=1) entry value = 'su', 'segy' etc.
			#			print("CASE 2A.1: iFile,get_Data_path, $DATA_SEISMIC_SU\n");
			$iFile->{_path} = _get_DATA_DIR_IN();

		}
		elsif ( $entry_label ne $empty_string
			and $iFile->{_dialog_type} eq
			$file_dialog_type_h->{_Data_PL_SEISMIC} )
		{

# case 2A.2
#			print("case 2A.2 iFile,get_Data_path, dialog_type=$iFile->{_dialog_type} \n");
			$iFile->{_path} = $Data_PL_SEISMIC;

		}
		elsif ( $entry_label eq $empty_string ) {

	   # CASE 2A.3
	   #			print("iFile,get_Data_path, entry_label is empty \n");
	   #			print("CASE 2A.3 File,get_Data_path, new PL_SEISMIC path chosen \n");
			$iFile->{_path} = $PL_SEISMIC;

		}
		else {

			# CASE 2A.4
			$iFile->{_path} = $default_path;

#			print("iFile, get_Data_path, superflow entry label is unexpected \n");
#			print("case 2A.4 iFile,get_Data_path, dialog_type=$iFile->{_dialog_type} \n");
#			print("CASE 2A.4, iFile,get_path,path=$iFile->{_path}\n");
		}

	}
	else {

		# CASE 3: all other cases
		$iFile->{_path} = $default_path;

		#		print("CASE 3: iFile,get_Data_path, unsuitable flow type \n");

		# print("CASE 3: iFile,get_path,path=$iFile->{_path}\n");
	}

	my $result = $iFile->{_path};

	#	print("2. iFile,get_Data_path,result=$iFile->{_path}\n");
	return ($result);
}

=head2 sub get_Path

	get DATA path from SPEC file
	corresponding to the program name
	make sure to remove unneeded ticks in strings
	Only used by _pre_built_superflow_open_path
	 
	prepend appropriately the path to the 
				final path in the parameter value
	e.g. Z becomes /home/gom/ProjectHome/site/spare_directory/etc..../Z
	you can do this by using 
	the current index
	current program name
	the current value of the parameter
	the previous indices
	the values or the previous parameters
 
=cut

sub get_Path {

	my ($self) = @_;

	my $result;
	my $Path;

	if ( $iFile->{_flow_type} ne $empty_string ) {

		my $Project      = Project_config->new();
		my $program_name = _get_prog_name();

		# print("iFile,get_Path,flow_type: $iFile->{_flow_type}\n");

		if ( $iFile->{_flow_type} eq $flow_type_href->{_user_built} ) {

			#CASE 1B
			# first get values from the Project
			my $PROJECT_HOME = $Project->PROJECT_HOME();

	   # print("iFile,get_Path for $program_name PROJECT_HOME=$PROJECT_HOME\n");

			my $entry_label = $iFile->{_entry_button_label};
			my $index       = $iFile->{_parameter_value_index};
			my @values      = @{ $iFile->{_values_aref} };

			my $forPROJECT_HOME = $PROJECT_HOME;
			my $forSITE         = $forPROJECT_HOME . '/seismics/pl/';

			# make base path
			# print("5.iFile,get_Path, forSITE: $forSITE \n");
			# print("6.iFile,get_Path,for program_name: $program_name \n");
			$Path = $forSITE;

		}
		elsif ( $flow_type_href->{_pre_built_superflow} ) {

			if (
				$program_name eq 'Project'

				# CASE 1A
				and defined $iFile->{_values_aref}
				&& defined $iFile->{_parameter_value_index}
				&& defined $iFile->{_prog_name_sref}
				&& $iFile->{_values_aref} ne $empty_string
				&& $iFile->{_parameter_value_index} ne $empty_string
				&& $iFile->{_prog_name_sref} ne $empty_string
			  )

			{
	  # print("1.iFile,get_Path, _values_aref: @{$iFile->{_values_aref}}[0]\n");

				my $entry_label = $iFile->{_entry_button_label};
				my $index       = $iFile->{_parameter_value_index};
				my @values      = @{ $iFile->{_values_aref} };

	   # print("iFile,get_Path,parameter label or name 	=---$entry_label---\n");
	   # print("1.iFile,get_Path, _values_aref: @{$iFile->{_values_aref}}\n");
	   #				for(my $i=0; $i <8; $i++) {
	   #					print ("iFile, get_Path, values[$i] = $values[$i]\n");
	   #				}

				my $forHOME         = $values[0];
				my $forPROJECT_HOME = $values[0];
				my $forSITE         = $values[1]
				  . '/seismics/pl/'
				  ;    # seismics/pl chosen out of convenience; could be gmt/pl
				my $forSPARE_DIR = $forSITE . $values[2] . '/';
				my $forDATE      = $forSPARE_DIR . $values[3] . '/';
				my $forCOMPONENT = $forDATE . $values[4] . '/';
				my $forLINE      = $forCOMPONENT . $values[5] . '/';
				my $forSUBUSER =
				  $forLINE . $values[6];  # assumes each previous one is correct

				if ( $index == 0 ) {
					$Path = $forHOME;

				}
				elsif ( $index == 1 ) {
					$Path = $forPROJECT_HOME;

				}
				elsif ( $index == 2 ) {
					$Path = $forSITE;

				}
				elsif ( $index == 3 ) {
					$Path = $forSPARE_DIR;

				}
				elsif ( $index == 4 ) {
					$Path = $forDATE;

				}
				elsif ( $index == 5 ) {
					$Path = $forCOMPONENT;

				}
				elsif ( $index == 6 ) {
					$Path = $forLINE;

				}
				elsif ( $index == 7 ) {
					$Path = $forSUBUSER;

				}
				else {
					print("2.iFile,get_Path, unexpected index \n");
					$Path = $empty_string;
				}

			}
			elsif ( $program_name eq 'Sucat' ) {

				# CASE 1 B first get values from the Project
				my $PROJECT_HOME = $Project->PROJECT_HOME();

	#				print("iFile,get_Path for $program_name PROJECT_HOME=$PROJECT_HOME\n");

				my $entry_label = $iFile->{_entry_button_label};
				my $index       = $iFile->{_parameter_value_index};
				my @values      = @{ $iFile->{_values_aref} };

				my $forPROJECT_HOME = $PROJECT_HOME;
				my $forSITE         = $forPROJECT_HOME . '/seismics/pl/';

			  # make base path p
			  #				print("5.iFile,get_Path, forSITE: $forSITE \n");
			  #				print("6.iFile,get_Path,for program_name: $program_name \n");

				$Path = $forSITE;

			}
			else {
				print(
"iFile,get_Path, missing values,program name or parameter index\n"
				);
				return ();
				$Path = $empty_string;
			}
		}
	}
	else {
		print("iFile,get_Path, missing file type \n");
		$Path = $empty_string;
	}    # end of flow types

	$iFile->{_path} = $Path;
	$result = $iFile->{_path};

	#	print("7. iFile,get_Path,path=$iFile->{_path}\n");
	return ($result);
}

=head2 sub get_prog_name_href


=cut

sub get_prog_name_href {

	my ( $self, $hash_ref ) = @_;
	my ($program_name);
	if ($hash_ref) {
		my ( $ans, $first_name, $suffix, $length );
		my @names = @$alias_superflow_config_names_aref;
		$length     = scalar(@names);
		$first_name = $hash_ref->{_selected_first_name};

		#		print("iFile,get_prog_name_href,first_name=$first_name\n");

		for ( my $i = 0 ; $i < $length ; $i++ ) {
			if ( $names[$i] eq $first_name ) {
				$ans = $i;
			}
		}
		$program_name = $names[$ans];

		#		print("iFile,get_prog_name,superflow name = $names[$ans]\n");
	}
	return ($program_name);
}

=head2 sub get_prog_name_s

	match the names of configuration files using aliases,
	which have hyphens, e.g. Project_Variables

	However, program names may be different: e.g. ProjectVariables


=cut

sub get_prog_name_s {

	my ( $self, $scalar ) = @_;
	my ( $alias_program_name, $program_name );
	if ($scalar) {
		my ( $ans, $first_name, $length );
		$first_name = $scalar;
		my @alias_names = @$alias_superflow_config_names_aref;
		my @names       = @$superflow_config_names_aref;
		$length = scalar(@names);

		# print("iFile,get_prog_name_s,first_name=$first_name\n");

		for ( my $i = 0 ; $i < $length ; $i++ ) {
			if ( $alias_names[$i] eq $first_name ) {
				$ans          = $i;
				$program_name = $names[$ans];
			}
		}
		if ($program_name) {

			#			print("iFile,get_prog_name_s,superflow name = $program_name\n");
		}
		else {
			print("iFile,get_prog_name_s,superflow name = NO MATCH\n");
		}
	}
	return ($program_name);
}

=head2 sub _get_prog_name

	give scalar reference to program name 

=cut

sub _get_prog_name {

	my ($self) = @_;

	if ( defined $iFile->{_prog_name_sref}
		&& $iFile->{_prog_name_sref} ne $empty_string )
	{

# print("iFile,set_prog_name_sref,-- if assumed a scalar ref: ${$iFile->{_prog_name_sref}}\n");

		my $program_name = ${ $iFile->{_prog_name_sref} };
		return ($program_name);

	}
	else {
		print("iFile,set_prog_name_sref, no prog name is available to read\n");
		return ();
	}
}

=head2 sub _set4getpath

=cut

sub _set4get_path {

	my ($self) = @_;
	my $conditions;

	return ($conditions);
}

=head2 sub set_dialog_type

=cut

sub set_dialog_type {

	my ( $self, $dialog_type ) = @_;
	if ( $dialog_type ne $empty_string ) {

		$iFile->{_dialog_type} = $dialog_type;

	  #		print("iFile, set_dialog_type, dialog_type=$iFile->{_dialog_type} \n");

	}
	else {
		print("iFile, set_dialog_type, missing dialog_type\n");
	}

	return ();
}

=head2 sub set_dialog_type

=cut

sub set_dialog_type_h {

	my ( $self, $href ) = @_;
	if ( $href ne $empty_string ) {

		$iFile->{_dialog_type} = $href->{_dialog_type};

	  #		print("iFile, set_dialog_type, dialog_type=$iFile->{_dialog_type} \n");

	}
	else {
		print("iFile, set_dialog_type, missing dialog_type\n");
	}

	return ();
}

=head2 sub set_entry 

	force entry point from gui to be an Entry widget

=cut

sub set_entry {

	my ( $self, $hash_ref ) = @_;

	if ( defined $hash_ref ) {

# print("iFile,set_entry, entry_button label=$hash_ref->{_entry_button_label}___\n");

		if ( $hash_ref->{_entry_button_label} ne $empty_string ) {

			$iFile->{_entry_button_label} = $hash_ref->{_entry_button_label};

		}
		else {
			print("iFile,set_entry, unexpected hash_ref\n");
		}

	}

	return ();
}

=head2 sub set_flow_type_h

	user_built_flow
	or
	pre_built_superflow
	
=cut

sub set_flow_type_h {

	my ( $self, $how_built ) = @_;

	if ( defined $how_built ) {

		$iFile->{_flow_type} = $how_built->{_flow_type};

		# print("iFile, set_flow_type_h : $iFile->{_flow_type}\n");

	}
	else {
		print("iFile, set_flow_type_h , missing how_built\n");
	}

	return ();
}

=head2 sub set_parameter_value_index

	Index of selected parameter

=cut

sub set_parameter_value_index {

	my ( $self, $hash_ref ) = @_;

	if ( defined $hash_ref ) {

#		print("iFile,set_parameter_value_index, index=$hash_ref->{_parameter_value_index}----\n");

		if ( $hash_ref->{_parameter_value_index} ne $empty_string ) {

			$iFile->{_parameter_value_index} =
			  $hash_ref->{_parameter_value_index};

		}
		else {
			print("iFile,set_parameter_value_index, unexpected hash_ref\n");
		}
	}
	my $result = $iFile->{_parameter_value_index};
	return ($result);
}

=head2 sub set_prog_name_sref

	give scalar reference to program name 

=cut

sub set_prog_name_sref {

	my ( $self, $hash_ref ) = @_;
	if ( $hash_ref->{_prog_name_sref} ) {

#		print("iFile,set_prog_name_sref,raw: $hash_ref->{_prog_name_sref}\n");
#		print("iFile,set_prog_name_sref,-- if assumed a scalar ref: ${$hash_ref->{_prog_name_sref}}\n");
		$iFile->{_prog_name_sref} = $hash_ref->{_prog_name_sref};

	}
	else {
		print("iFile,set_prog_name_sref, no prog name given\n");
	}
	return ();
}

=head2 sub set_values_aref
Introduce array or parameter values
 
=cut

sub set_values_aref {

	my ( $self, $hash_ref ) = @_;
	if ( $hash_ref->{_values_aref} ) {

#		print("iFile,set_values_aref,raw: @{$hash_ref->{_values_aref}}[0],@{$hash_ref->{_values_aref}}[1]\n");
		$iFile->{_values_aref} = $hash_ref->{_values_aref};

	}
	else {
		print("iFile,set_values_aref, missing values_aref \n");
	}
	return ();
}

1;
