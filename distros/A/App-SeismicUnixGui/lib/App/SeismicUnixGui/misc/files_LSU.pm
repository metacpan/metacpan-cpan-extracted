package App::SeismicUnixGui::misc::files_LSU;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: files_LSU
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 6 2018

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.2 May 6 2018   
 changed _private_* to _*
      
	V 0.0.3 July 24 2018 include data_in, exclude data_out
	V 0.0.4 7.14.21 sets the flow color

=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '0.0.4';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_path';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::oop_text';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su $txt $suffix_txt);
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::L_SU_local_user_constants';
use aliased 'App::SeismicUnixGui::misc::name';
use aliased 'App::SeismicUnixGui::misc::manage_dirs_by';

my $Project               = Project_config->new();
my $L_SU_global_constants = L_SU_global_constants->new();
my $L_SU_path             = L_SU_path->new();
my $oop_text              = oop_text->new();
my $alias_superflow_name  = $L_SU_global_constants->alias_superflow_names_h();
my $alias_superflow_spec_names_h =
  $L_SU_global_constants->alias_superflow_spec_names_h();
my $var               = $L_SU_global_constants->var();
my $global_lib        = $L_SU_global_constants->global_libs();
my $GLOBAL_CONFIG_LIB = $global_lib->{_configs_big_streams};

#WARNING---- watch out for missing underscore!!
# print("files_LSU,alias_superflow_name : $alias_superflow_name->{ProjectVariables}\n");

my $alias_PV = $alias_superflow_name->{ProjectVariables};
my $filehandle;

my $on           = $var->{_on};
my $off          = $var->{_off};
my $nu           = $var->{_nu};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

my ( @param, @values, @checkbutton_on_off );
my ( $i, $j, $k, $size, $ref_cfg );
my @format;

# set default
$format[0] = $var->{_config_file_format};

my $files_LSU = {
	_CFG                     => '',
	_PL_SEISMIC              => '',
	_suffix_type_in          => '',
	_suffix_type_out         => '',
	_flow_color              => '',
	_flow_name_out           => '',
	_filehandle              => '',
	_format_aref             => \@format,
	_is_config               => $false,
	_is_Project_config       => $false,
	_is_data                 => $false,
	_is_data_in              => $false,
	_is_data_out             => $false,
	_is_pl                   => $false,
	_is_suffix_type          => $false,
	_items_versions_aref     => '',
	_message_w               => '',
	_note                    => '',
	_num_params_in_prog      => '',
	_num_progs_in_flow       => '',
	_outbound                => '',
	_outbound2               => '',
	_prog_names_aref         => '',
	_prog_param_values_aref2 => '',
	_prog_param_labels_aref2 => '',
	_program_name            => '',
	_prog_name_sref          => '',
	_program_name_config     => '',
	_program_name_pl         => '',
	_ref_file                => '',
	_Step                    => '',
};

$files_LSU->{_filehandle} = undef;

# will be called again internally by other software
# in case there are changes
# _set_PL_SEISMIC();
$files_LSU->{_PL_SEISMIC} = $Project->PL_SEISMIC();

=head2 sub _close 

=cut

sub _close {
	my ($self) = @_;

	close( $files_LSU->{_filehandle} );

	#	print("files_L_SU,_close, closing perl file for writing\n");

	return ($empty_string);
}

=head2 _get_superflow_config_file_format_aref


=cut

sub _get_superflow_config_file_format_aref {
	my ($self) = @_;

	if ( length $files_LSU->{_format_aref} ) {

		my $ref_format = $files_LSU->{_format_aref};

#		print("files_LSU, _get_config_format,formats=@$ref_format\n");
		return ($ref_format);
	}
	else {
		print("files_LSU, _get_config_format, missing formats\n");
		return ($empty_string);
	}

}

=head2  sub _get_prog_name_config

  needs $L_SU->{_prog_name_sref}
 
=cut 

sub _get_prog_name_config {
	my ($self) = @_;

	if ( $files_LSU->{_prog_name_config} ) {

		my $prog_name_config = $files_LSU->{_prog_name_config};
		return ($prog_name_config);

	}
	else {
		print("files_LSU,_get_prog_name_config, missing prog_name\n");
		return ($empty_string);
	}
}

=head2  sub _get_PL_SEISMIC

=cut 

sub _get_PL_SEISMIC {

	my ($self) = @_;

	_set_PL_SEISMIC();
	if ( defined $files_LSU->{_PL_SEISMIC} ) {

		my $PL_SEISMIC = $files_LSU->{_PL_SEISMIC};
		return ($PL_SEISMIC);

	}
	else {
		print("files_LSU,_get_PL_SEISMIC, missing prog_name\n");
		return ($empty_string);
	}
}

=head2 _open2write

=cut

sub _open2write {
	my ($self) = @_;

	#	print("files_L_SU,_open2write, $files_LSU->{_outbound}\n");

	open( $files_LSU->{_filehandle}, '>', $files_LSU->{_outbound} )
	  or die("Can't open file name, $!\n");

	return ($empty_string);
}

=pod 

suffix_type_set_suffix_suffix_type	TODO: suffix_type out may not
		be always type=$su in the case that
		the program in the list starts with $su
		At that point it will be necessary to 
		investigate the program_spec.pm module suffix_type sub _set_suffix_type_out {
 	my ($type) 			= @_;
	_set_datas files_les_LSU->{_suffix_type_out} 	= $suffix_types_LSU->{_is_suffix_type} 	= $true;	

	return();
}

=cut

=head2 sub _set_PL_SEISMIC

=cut

sub _set_PL_SEISMIC {

	my ($self) = @_;

	my $Project = Project_config->new();

	$files_LSU->{_PL_SEISMIC} = $Project->PL_SEISMIC();

  # print("files_LSU, _set_PL_SEISMIC, PL_SEISMIC=$files_LSU->{_PL_SEISMIC}\n");
	return ($empty_string);

}

=head2 _set_data_direction_in


=cut

sub _set_data_direction_in {
	my ($self) = @_;

	$files_LSU->{_is_data_in} = $true;
	_set_data();

	return ($empty_string);
}

=head2 _set_data_direction_out


=cut

sub _set_data_direction_out {
	my ($self) = @_;
	$files_LSU->{_is_data_out} = $true;
	_set_data();

	return ($empty_string);
}

=head2 sub _set_data


=cut 

sub _set_data {

	my ($self) = @_;

	$files_LSU->{_is_data} = $true;

	# print("files_LSU,_set_data,is_data: $files_LSU->{_is_data}\n");

	return ($empty_string);
}

#=head2 sub _set_data_in
#
#
#=cut
#
#sub _set_data_in {
#
#	my ($self) = @_;
#
#	$files_LSU->{_is_data_in} = $true;
#
#	# print("files_LSU,_set_data_in,is_data_in: $files_LSU->{_is_data}\n");
#
#	return($empty_string);
#}

=head2 sub _set_data_out


=cut 

sub _set_data_out {

	my ($self) = @_;

	$files_LSU->{_is_data_out} = $true;

	# print("files_LSU,_set_data_out,
	# is_data_out: $files_LSU->{_is_data}\n");

	return ($empty_string);
}

=head2  sub _set_prog_name_config

  needs $L_SU->{_prog_name_sref}
 
=cut 

sub _set_prog_name_config {
	my ($self) = @_;

	if ( $files_LSU->{_prog_name_sref} ) {

		$files_LSU->{_prog_name_config} =
		  ${ $files_LSU->{_prog_name_sref} } . '.config';
		return ($empty_string);

	}
	else {
		print("files_LSU,_set_prog_name_config, missing prog_name_sref \n");
		return ($empty_string);
	}
}

=head2 sub _set_prog_names_aref 


=cut

sub _set_prog_names_aref {
	my ($self) = @_;

	$oop_text->set_prog_names_aref( $files_LSU->{_prog_names_aref} );

   # print("files_LSU, set_prog_names_aref: $files_LSU->{_prog_names_aref} \n");

	return ($empty_string);
}

=head2 sub _set_prog_version_aref 


=cut

sub _set_prog_version_aref {
	my ($self) = @_;

	$oop_text->set_prog_version_aref($files_LSU);

	# print("files_LSU,_set_prog_version_aref,versions
	# @{$files_LSU->{_items_versions_aref}} \n");

	return ($empty_string);
}

=head2 sub _set_outbound2pl

     print("files_LSU,_set_outbound2pl,program_name $files_LSU->{_program_name}\n");
     print("files_LSU,_set_outbound2pl,program_name_config $files_LSU->{_program_name_config}\n");

=cut 

sub _set_outbound2pl {

	my ($self) = @_;

	if (   length $files_LSU->{_is_pl}
		&& length $files_LSU->{_flow_name_out} )
	{

		# update PL_SEISMIC in case of change
		my $PL_SEISMIC = _get_PL_SEISMIC();
		$files_LSU->{_outbound} =
		  $PL_SEISMIC . '/' . $files_LSU->{_flow_name_out};

	}
	else {
		print("files_LSU,_set_outbound2pl, missing variables\n");
	}

	#	print("files_LSU,_set_outbound2pl, $files_LSU->{_outbound}\n");

	return ($empty_string);
}

=head2 _set_suffix_type_in

=cut

sub _set_suffix_type_in {
	my ($suffix_type) = @_;

	_set_data();
	$files_LSU->{_suffix_type_in} = $suffix_type;
	$files_LSU->{_is_suffix_type} = $true;
	return ($empty_string);
}

=head2 _set_suffix_type_out


=cut

sub _set_suffix_type_out {
	my ($suffix_type) = @_;

	_set_data();
	$files_LSU->{_suffix_type_out} = $suffix_type;
	$files_LSU->{_is_suffix_type}  = $true;
	return ($empty_string);
}

=head2 sub check2write

files_LSU,check2write for pre-built or superflows
except Project.config, which uses sub write2

=cut

sub check2write {
	my (@self) = @_;

#	print("files_LSU, check2write,start\n");

	if ( not -e $files_LSU->{_outbound} ) {
		
        # CASE if configuration file does not already exist
		# e.g., IMMODPG/immodpg.config
		use File::Copy;
		_set_prog_name_config();
		my $prog_name_config = _get_prog_name_config();
		my $from             = $GLOBAL_CONFIG_LIB . '/' . $prog_name_config;
		my $to               = $files_LSU->{_outbound};

		copy( $from, $to );

#		print("files_LSU check2write copying $from to $to \n");

		# Now you can overwrite the file
		_write();

	}
	elsif ( -e $files_LSU->{_outbound} ) {

		# CASE if file doesalready exist
#		print("files_LSU, write_config OK: $files_LSU->{_outbound}\n");
#		print(
#"files_LSU, write_config, configuration file exists and will be overwritten\n"
#		);
		_write();

	}
	else {
		# CASE if file does already exist
		print("files_LSU, write_config, unexpected result\n");
	}

	return ($empty_string);
}

=head2 sub copy_default_config

files_LSU,copy_default_config for 
pre-built/superflows/Tools
(except Project.config, uses sub write2)

=cut

sub copy_default_config {
	my (@self) = @_;

#	print("files_LSU, copy_default_config,start\n");

	if ( not -e $files_LSU->{_outbound} ) {    # double check

		# CASE if configuration file does not already exist
		# e.g. IMMODPG/immodpg.config
		use File::Copy;
		_set_prog_name_config();
		my $prog_name_config = _get_prog_name_config();
		my $from             = $GLOBAL_CONFIG_LIB . '/' . $prog_name_config;
		my $to               = $files_LSU->{_outbound};

		copy( $from, $to );

		# print("files_LSU copy_default_config copy $from to $to \n");

	}
	else {
		# CASE if file already exists
#		print("files_LSU, write_config OK: $files_LSU->{_outbound}\n");
#		print("files_LSU, write_config, configuration file exists; NADA\n");
	}
	return ($empty_string);

}

=head2 sub outbound

needs prog_name_sref and
is_Project_config or
or _is_config

Why use App::SeismicUnixGui::misc::name module?;
 To modify input names--
 adapt them to infer
 which spec and parameter
 files to read
 
 Program names in GUI
 and configuration file names
 in the local (!!) directory
 may be different.

=cut

sub outbound {

	my ($self) = @_;

	if ( $files_LSU->{_prog_name_sref} ) {

		my $name = name->new();

		$files_LSU->{_program_name} = ${ $files_LSU->{_prog_name_sref} };

		# conveniently shorter local variable name
		my $program_name = $files_LSU->{_program_name};

		if ( $files_LSU->{_is_Project_config} ) {

			# CASE 1 for Project_config
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);

			# Find out HOME directory and configuration path for user
			my $user_constants = L_SU_local_user_constants->new();

			my $exists =
			  $user_constants->user_configuration_Project_config_exists;
			my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT();
			$user_constants->set_user_configuration_Project_config;
			my $Project_config =
			  $user_constants->get_user_configuration_Project_config;

			if ($exists)
			{    # if it exists: .L_SU/configuration/active/Project.config
				$files_LSU->{_outbound} = $Project_config;

# print("files_LSU, outbound, outbounds are Project_config: $Project_config\n");

			}
			else {
				print(
"files_LSU, outbound, WARNING, no user configuration Project.config exists\n"
				);
				print("TEMP solution is to write Project.config locally\n");
			}

		}
		elsif ( $files_LSU->{_is_config} ) {    # double check

			my $DATA_PATH_IN;

			$L_SU_path->set_program_name($program_name);

			my $pathNmodule_spec_w_slash_pm =
			  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
			my $pathNmodule_spec_w_colon =
			  $L_SU_path->get_pathNmodule_spec_w_colon();

			require $pathNmodule_spec_w_slash_pm;

			# INSTANTIATE
			my $package = $pathNmodule_spec_w_colon->new();

			# collect specifications of output directory
			# from a program_spec.pm module
			my $specs_h = $package->variables();
			my $CONFIG  = $specs_h->{_CONFIG};

			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);
			$files_LSU->{_outbound} =
			  $CONFIG . '/' . $files_LSU->{_program_name_config};

#	print("Case 2 files_LSU, outbound, outbound: $files_LSU->{_outbound} \n");

		}
		elsif ($files_LSU->{_is_pl}
			&& $files_LSU->{_PL_SEISMIC} )
		{

			#CASE 3 for user-built flows
			# write to PL_SEISMIC
			my $PL_SEISMIC = $files_LSU->{_PL_SEISMIC};
			$files_LSU->{_program_name_pl} = $program_name;
			$files_LSU->{_outbound} =
			  $PL_SEISMIC . '/' . $files_LSU->{_program_name_pl};

# print("Case 3 files_LSU, outbound, outbound _is_pl: $files_LSU->{_is_pl} \n");

		}
		else {
			print("WARNING: files_LSU,set_outbound,$files_LSU->{_outbound}\n");
		}

		#		print("files_LSU, outbound,$files_LSU->{_outbound}\n");
	}

	return ($empty_string);
}

=head2 sub outbound2

 needs prog_name_sref
       is_Project_config or _is_config
       TODO: make exclusive for cases that are NOT Project_config

=cut

sub outbound2 {

	my ($self) = @_;

	if ( $files_LSU->{_prog_name_sref} ) {

		my $name = name->new();

		$files_LSU->{_program_name} = ${ $files_LSU->{_prog_name_sref} };
		my $program_name = $files_LSU->{_program_name};    #conveniently shorter

		if ( $files_LSU->{_is_Project_config} ) {
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);

			# Find out HOME directory and configuration path for user
			my $user_constants = L_SU_local_user_constants->new();
			my $exists =
			  $user_constants->user_configuration_Project_config_exists;
			my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT();
			$user_constants->set_user_configuration_Project_config2;
			my $Project_config2 =
			  $user_constants->get_user_configuration_Project_config2;

			if ($exists)
			{    # if it exists: .L_SU/configuration/active/Project.config
				$files_LSU->{_outbound2} = $Project_config2;

# print("files_LSU, outbound, outbounds are Project_config2: $Project_config2\n");

			}
			elsif ( $files_LSU->{_is_config} && $files_LSU->{_PL_SEISMIC} ) {
				my $PL_SEISMIC = $files_LSU->{_PL_SEISMIC};
				$files_LSU->{_program_name_config} =
				  $name->change_config($program_name);
				$files_LSU->{_outbound2} =
				  $PL_SEISMIC . '/' . $files_LSU->{_program_name_config};
#				print(
#"files_LSU, outbound2, outbound2 _is_config: $files_LSU->{_outbound2} \n"
#				);
			}
			else {
				print(
"files_LSU, outbound, WARNING, no user configuration Project.config exists\n"
				);
				print("TEMP solution is to write Project.config locally\n");
			}
		}
		else {

			print("WARNING: files_LSU,outbound2\n");
		}

		# print("files_LSU, outbound,$files_LSU->{_outbound2}\n");
	}

	return ($empty_string);
}

=head2 sub set_PL_SEISMIC

=cut

sub set_PL_SEISMIC {

	my ($self) = @_;

	my $Project = Project_config->new();
	$files_LSU->{_PL_SEISMIC} = $Project->PL_SEISMIC();

	return ($empty_string);

}

=head2 set_Project_config
turn file type
definitions on and off 

=cut

sub set_Project_config {
	my ($self) = @_;
	$files_LSU->{_is_config}         = $false;
	$files_LSU->{_is_Project_config} = $true;

	return ($empty_string);
}

=head2 set_config


=cut

sub set_config {
	my ($self) = @_;
	$files_LSU->{_is_config}         = $true;
	$files_LSU->{_is_Project_config} = $false;

	return ($empty_string);
}

=head2 set_superflow_config_file_format


=cut

sub set_superflow_config_file_format {
	my ( $self, $ref_format ) = @_;

	$files_LSU->{_format_aref} = $ref_format;

	return ($empty_string);
}

=head2 set_data

		detects and attempts to rectify program order error
		$oop_text->set_bin_out();
		Expects suprograms that start with "su" or "uni"
		
=cut

sub set_data {
	my ($self)         = @_;
	
	my $num_progs4flow = scalar @{ $files_LSU->{_prog_names_aref} };
	my @prog_names     = @{ $files_LSU->{_prog_names_aref} };

	for ( my $i = 0 ; $i < $num_progs4flow ; $i++ ) {

		if ( $prog_names[$i] eq 'data_in' ) {
			my $first_2_char = substr( $prog_names[$i], 0, 2 );

			#			if ( $first_2_char eq 'da' ) {
			#
			#				print("1. files_LSU,set_data,data_in detected\n");
			#				print("1. files_LSU,set_data,flow_item=$i\n");
			#
			#			} else {
			#				print("files_LSU,set_data,su missing data_in program");
			#			}

			# 2nd program must exist
			if ( $num_progs4flow > 1 ) {

				# suprog can follow
				my $first_2_char = substr( $prog_names[ ( $i + 1 ) ], 0, 2 );
				my $first_3_char = substr( $prog_names[ ( $i + 1 ) ], 0, 3 );

#                print( "files_LSU,set_data, second program name starts with first_2_char =$first_2_char\n");

				if ( $first_2_char eq $su ) {

					# print("1. files_LSU,set_data,su data_in suffix_type\n");
					_set_suffix_type_in($su);
					_set_data_direction_in();

				}
				elsif ( $first_3_char eq 'uni' ) {

			 #				    print("1. files_LSU,set_data, txt data_in suffix_type\n");
					_set_suffix_type_in($txt);
					_set_data_direction_in();

				}
				else {

	  #					print("Warning: files_LSU, set_data, missing su,txt suffix type\n");
				}

			}
			else {

				#				print("files_LSU,only data and no suffix_type \n");
				_set_suffix_type_in($su);    # TODO
				_set_data_direction_in();
			}

		}
		else {

  #			print("1. files_LSU,set_data, acceptable second program detected NADA\n");
		}

		if ( $prog_names[$i] eq 'data_out' ) {

			# prior program must exist
			if ( $num_progs4flow > 1 ) {

				# suprog must lead
				my $first_2_char = substr( $prog_names[ ( $i - 1 ) ], 0, 2 );
				if ( $first_2_char eq $su ) {

# print("2. files_LSU,set_data,leading sunix program detected, dasuffix_typellows\n");
					_set_suffix_type_out($su);
					_set_data_direction_out();

				}
				else {

				  # print("2. files_LSU,set_data,first 2 csuffix_typeot $su\n");
					_set_suffix_type_out($su);    # TODO
					_set_data_direction_out();
				}

			}
			else {

				# print("files_LSU,only data and no psuffix_typex program\n");
				_set_suffix_type_out($su);    # TODO
				_set_data_direction_out();
			}

		}
		else {

			# NADA print("2. files_LSU,set_data,program detected\n");
		}
	}
	return ($empty_string);
}

=head2 sub set_flow_color

=cut 

sub set_flow_color {
	my ( $self, $flow_color ) = @_;

	if ( length $flow_color ) {

		$files_LSU->{_flow_color} = $flow_color;

		#		print("files_LSU, set_flow_color:$files_LSU->{_flow_color}\n");

	}
	else {
		print("files_LSU, set_flow_color, missing color\n");
	}
	return ($empty_string);
}

=head2 set_message

	relay messages via the main message widget in GUI

=cut

sub set_message {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {

		$files_LSU->{_message_w} = $hash_ref->{_message_w};

	}
	else {
		print("files_LSU, set_message, missing message widget \n");
	}
	return ($empty_string);
}

=head2 set2pl

	saved files are local perl flows

=cut

sub set2pl {
	my ( $self, $hash_ref ) = @_;
	$files_LSU->{_is_pl} = $true;

	if (   length $files_LSU->{_flow_color}
		&& length $hash_ref )
	{

		my $this_color           = $files_LSU->{_flow_color};
		my $_flow_name_out_color = '_flow_name_out_' . $this_color;

   #		print("files_LSU,set2pl, _flow_name_out_color =$_flow_name_out_color \n");
		$files_LSU->{_flow_name_out} = $hash_ref->{$_flow_name_out_color};

#		print(
#			"files_LSU,set2pl, is $files_LSU->{_is_pl} \n
#		self,hash_ref: $self,$hash_ref\n"
#		);
#		print("files_LSU,set2pl, _flow_name_out =$hash_ref->{$_flow_name_out_color} \n");

		_set_outbound2pl();

	}
	else {
		print("files_LSU,set2pl, missing flow color assignment/hash ref \n");
	}

	return ($empty_string);
}

=head2 sub set_outbound

print("files_LSU,set_outbound,program_name $files_LSU->{_program_name}\n");
print("files_LSU,set_outbound,program_name_config $files_LSU->{_program_name_config}\n");

=cut 

sub set_outbound {

	my ( $self, $out_scalar_ref ) = @_;
	my $program_name = $$out_scalar_ref;

	if ($out_scalar_ref) {

		my $name = name->new();

		$files_LSU->{_program_name} = $$out_scalar_ref;

		if ( $files_LSU->{_is_Project_config} ) {
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);

			# Find out HOME directory and configuration path for user
			my $user_constants = L_SU_local_user_constants->new();
			my $exists =
			  $user_constants->user_configuration_Project_config_exists;
			my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT();
			$user_constants->set_user_configuration_Project_config;
			my $Project_config =
			  $user_constants->get_user_configuration_Project_config;

			if ($exists)
			{    # if it exists: .L_SU/configuration/active/Project.config
				$files_LSU->{_outbound} = $Project_config;

# print("files_LSU, set_outbound, outbound is $Project_config; the currently active project\n");

			}
			else {
				print(
"files_LSU, set_outbound, WARNING, no user configuration Project.config exists\n"
				);
				print("TEMP solution is to write Project.config locally\n");
			}

		}
		elsif ( $files_LSU->{_is_config} ) {
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);
			$files_LSU->{_outbound} = $files_LSU->{_program_name_config};

		}
		elsif ( $files_LSU->{_is_pl} && $files_LSU->{_PL_SEISMIC} ) {
			my $PL_SEISMIC = $files_LSU->{_PL_SEISMIC};
			$files_LSU->{_program_name_pl} = $program_name;
			$files_LSU->{_outbound} =
			  $PL_SEISMIC . '/' . $files_LSU->{_program_name_pl};

		}
		else {

			print("WARNING: files_LSU,set_outbound,$files_LSU->{_outbound}\n");
		}

		# print("files_LSU,set_outbound,$files_LSU->{_outbound}\n");
	}

	return ($empty_string);
}

=head2 sub set_outbound2



=cut 

sub set_outbound2 {

	my ( $self, $out_scalar_ref ) = @_;
	my $program_name = $$out_scalar_ref;

	if ($out_scalar_ref) {

		my $name = name->new();

		$files_LSU->{_program_name} = $$out_scalar_ref;

		if ( $files_LSU->{_is_Project_config} ) {
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);

			# Find out HOME directory and configuration path for user
			my $user_constants = L_SU_local_user_constants->new();
			my $exists =
			  $user_constants->user_configuration_Project_config_exists;
			my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT();
			$user_constants->set_user_configuration_Project_config2;
			my $Project_config2 =
			  $user_constants->get_user_configuration_Project_config2;

			if ($exists)
			{    # if it exists: .L_SU/configuration/active/Project.config
				$files_LSU->{_outbound2} = $Project_config2;

		  # print("files_LSU, set_outbound2, outbounds is: $Project_config2\n");
			}
			else {
				print(
"files_LSU, set_outbound, WARNING, no user configuration Project.config exists\n"
				);
				print("TEMP solution is to write Project.config locally\n");
			}

		}
		elsif ( $files_LSU->{_is_config} ) {
			$files_LSU->{_program_name_config} =
			  $name->change_config($program_name);
			$files_LSU->{_outbound2} = $files_LSU->{_program_name_config};

		}
		else {

			print("WARNING: files_LSU,set_outbound,$files_LSU->{_outbound}\n");
		}

		# print("files_LSU,set_outbound,$files_LSU->{_outbound}\n");
	}

	return ($empty_string);
}

=head2 sub set_items_versions_aref


=cut

sub set_items_versions_aref {

	my ( $self, $hash_aref ) = @_;
	$files_LSU->{_items_versions_aref} = $hash_aref->{_items_versions_aref};

	# print("files_LSU,set_items_versions_aref,
	#	   @{$files_LSU->{_items_versions_aref}}\n");

	return ($empty_string);
}

=head2 sub set_prog_param_values_aref2

=cut

sub set_prog_param_values_aref2 {

	my ( $self, $hash_aref2 ) = @_;
	$files_LSU->{_prog_param_values_aref2} = $hash_aref2->{_good_values_aref2};

	return ($empty_string);
}

=head2 sub set_prog_param_labels_aref2

	my $num_progs4flow = scalar @{$files_LSU->{_prog_param_labels_aref2}};
         	print("\nfiles_LSU,set_prog_param_labels_aref2, num_progs4flow: $num_progs4flow\n");
				for (my $i=0; $i < $num_progs4flow; $i++ ) {
				print("files_LSU,set_prog_param_labels_aref2,
				@{@{$files_LSU->{_prog_param_labels_aref2}}[$i]}\n");
					}

	my $num_progs4flow = scalar @{$files_LSU->{_prog_param_values_aref2}};
         	print("\nfiles_LSU,set_prog_param_values_aref2, num_progs4flow: $num_progs4flow\n");
				for (my $i=0; $i < $num_progs4flow; $i++ ) {
				print("files_LSU,set_prog_param_values_aref2,
				@{@{$files_LSU->{_prog_param_values_aref2}}[$i]}\n");
}
					

=cut

sub set_prog_param_labels_aref2 {

	my ( $self, $hash_aref2 ) = @_;

	$files_LSU->{_prog_param_labels_aref2} = $hash_aref2->{_good_labels_aref2};

	return ($empty_string);
}

=head2 sub set_prog_names_aref


=cut

sub set_prog_name_sref {
	my ( $self, $sref ) = @_;

	if ($sref) {

		$files_LSU->{_prog_name_sref} = $sref;

# print("files_LSU, set_prog_name_sref, prog_name:${$files_LSU->{_prog_name_sref}}\n");
		return ($empty_string);

	}
	else {
		print("files_LSU, set_prog_name_sref, prog name missing\n");
		return ($empty_string);
	}
}

=head2 sub set_prog_names_aref


=cut

sub set_prog_names_aref {

	my ( $self, $hash_aref ) = @_;
	$files_LSU->{_prog_names_aref} = $hash_aref->{_prog_names_aref};

# print("files_LSU, set_prog_names_aref, prog_names:@{$files_LSU->{_prog_names_aref}}\n");

	return ($empty_string);
}

=head2 sub set_superflow_specs 

  Output parameters for superflows
  A Tool is a superflow
  i/p $hash_ref to obtain entry labels and
  values and parameters from widgets to build @CFG 

DB
  print("prog name $program_name\n");
  print(" save_button,save,configure,write_LSU,tool_specs $files_LSU->{_program_name_config}\n");
  print("save,superflow,write_LSU, key/value pairs:$CFG[$i], $CFG[$j]\n");
  #use Config::Simple;
  #my $cfg 		= Config::Simple(syntax=>'ini');
  #$cfg->write($files_LSU->{_program_name_config});   
  # print "@CFGpa\n";
     #$cfg->ram($CFG[$i] ,$CFG[$j]); 
	  #print "@CFG\n";
        # print("write_LSU,tool_specs \nprog_name:${$files_LSU->{_program_name}}\n");
        # print("\n   prog_name_config: $files_LSU->{_program_name_config}\n");
        # print("  labels: @{$hash_ref->{_ref_labels}}\n");
        # print("  values: @{$hash_ref->{_ref_values}}\n");
        
        # no. of variables comes from specs file directly
        $length = scalar @{$hash_ref->{_ref_labels}};-- old version

=cut

sub set_superflow_specs {
	my ( $self, $hash_ref ) = @_;

#					foreach my $key (sort keys %$hash_ref) {
#      					print (" files_LSU,set_superflow_specs, key is $key, value is $hash_ref->{$key}\n");
# 					}
#
# print ("1. files_LSU,set_superflow_specs,prog_name_sref: ${$files_LSU->{_prog_name_sref}} \n");

	if ( $hash_ref && $files_LSU->{_prog_name_sref} ) {

		my $name = name->new();

		my ( @CFG, @info );
		my $length;

		my $base_program_name = ${ $files_LSU->{_prog_name_sref} };
		my $alias_program_name =
		  $alias_superflow_spec_names_h->{$base_program_name};

		$L_SU_path->set_program_name($alias_program_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		# INSTANTIATE
		my $program_name_spec = $pathNmodule_spec_w_colon->new();

  	    # print ("2. files_LSU,set_superflow_specs, instantiate $program_name_spec\n");

		my $max_index = $program_name_spec->get_max_index();
		$length = $max_index + 1;

		# get length from corresponding spec file
		# length-1 : is largest occupied index
		# print("3. files_LSU, set_superflow_specs, length=$length\n");

		for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

			# last value is at j+1
			$CFG[$j] = @{ $hash_ref->{_ref_labels} }[$i];
			$CFG[ ( $j + 1 ) ] = @{ $hash_ref->{_ref_values} }[$i];

# print ("files_LSU,set_superflow_specs,label=$CFG[$j]  value=$CFG[ ( $j + 1 ) ]\n");

		}

		$files_LSU->{_CFG} = \@CFG;

# my $ref_lines  = $messages->get_config($files_LSU->{_program_name_config} )
# my $num_lines  = scalar @$ref_lines;
# my @lines      = @$ref_lines;
# for (my $i=0; $i<$num_lines; $i++) {
# printf OUT $lines[$i];
# print("files_LSU,set_superflow_specs,program_name_config: $files_LSU->{_program_name_config}\n");

		if ( $files_LSU->{_program_name_config} eq $alias_PV . '.config' ) {

			# CASE 1 legacy case--for deprecation

			$info[0] = (" # ENVIRONMENT VARIABLES FOR THIS PROJECT\n");
			$info[1] = (" # Notes:\n");
			$info[2] = (" # 1. Default DATE format is DAY MONTH YEAR\n");
			$info[3] = (" # 2. only change what lies between single\n");
			$info[4] = (" # inverted commas\n");
			$info[5] = (" # 3. the directory hierarchy is\n");
			$info[6] = (" # \$PROJECT_HOME/\$date/\$line\n");
			$info[7] = (" # Warning: Do not modify \$HOME\n");
			$info[8] = ("  \n");
		}

		$files_LSU->{_info} = \@info;

	}
	else {
		print(
"files_LSU,set_superflow_specs, missing hash_ref or prog_name_sref\n"
		);
	}

	return ($empty_string);
}

=head2 sub sizes 


=cut

sub sizes {
	$size = ( ( scalar @$ref_cfg ) ) / 2;
	return ($size);
}

=head2 sub _write

Write out configuration files to script

=cut

sub _write {

	my ($self) = @_;

	my $control = control->new();
	my @format;
	my $length                  = ( scalar @{ $files_LSU->{_CFG} } ) / 2;
	my $length_info             = scalar @{ $files_LSU->{_info} };
	my @info                    = @{ $files_LSU->{_info} };
	my @CFG                     = @{ $files_LSU->{_CFG} };
	my $config_file_format_aref = _get_superflow_config_file_format_aref();
	my $num_formats             = scalar @$config_file_format_aref;

	# print("files_LSU, _write,num_formats=$num_formats\n");

	if ( $num_formats == 1 ) {

		for ( my $i = 0 ; $i < $length ; $i++ ) {

			$format[$i] = @{$config_file_format_aref}[0];

#			print("1. files_LSU,_write,$format[$i]\n");

		}

	}
	elsif ( $num_formats > 1 ) {

		@format = @$config_file_format_aref;

	}
	else {
		print("3. files_LSU, _write, unexpected result\n");
	}

	
	open( my $fh, '>', $files_LSU->{_outbound} )
	  or die "Can't open parameter file:$!";

	for ( my $i = 0 ; $i < $length_info ; $i++ ) {
		
		# skipped in many cases
		# length_info=0 formmany tools, e.g. immodpg

		printf $fh $info[$i];
		print("5. files_LSU,_write,info is $info[$i]\n");
	}

	for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

		my $old_value = $CFG[ ( $j + 1 ) ];
		my $new_value = $control->get_no_quotes($old_value);

		printf $fh $format[$i] . "\n", $CFG[$j], "= ", $new_value;
#		print("7.files_LSU,_write,$j, $CFG[$j]=$CFG[ ( $j + 1 ) ]\n");
	}
	close($fh);
}

=head2 sub write

  all files if outbound includes the existing
  file path as well

=cut

sub write {

	my ($self) = @_;

	my $length      = ( scalar @{ $files_LSU->{_CFG} } ) / 2;
	my $length_info = scalar @{ $files_LSU->{_info} };
	my @info        = @{ $files_LSU->{_info} };
	my @CFG         = @{ $files_LSU->{_CFG} };

#	print("files_LSU, write, length:$length,length_info:$length_info \n");
#	print("files_LSU,write,files_LSU->{_outbound}: $files_LSU->{_outbound} \n");

	open( my $fh, '>', $files_LSU->{_outbound} )
	  or die "Can't open parameter file:$!";

	for ( my $i = 0 ; $i < $length_info ; $i++ ) {

		#		printf $fh $info[$i];
	}

	for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

		if ( defined $CFG[$j] && defined $CFG[ $j + 1 ] ) {

			# print ("    $CFG[$j],= ,$CFG[($j+1)]\n");;
			printf $fh "%-35s%1s%-20s\n", $CFG[$j], "= ", $CFG[ ( $j + 1 ) ];

		}
		else {
#			print("files_LSU, write, undefined value or name NADA\n");
		}

	}
	close($fh);

	#	print("files_LSU, write, done\n");
	return ();
}

=head2 sub write2

 used for dealing with ONLY Project.config

=cut 

sub write2 {
	my ($self) = @_;
	use File::Copy;

	my $user_constants = L_SU_local_user_constants->new();
	my $control        = control->new();

	my $length      = ( scalar @{ $files_LSU->{_CFG} } ) / 2;
	my $length_info = scalar @{ $files_LSU->{_info} };
	my @info        = @{ $files_LSU->{_info} };
	my @CFG         = @{ $files_LSU->{_CFG} };

	my $CONFIGURATION  = $user_constants->get_CONFIGURATION();
	my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT();
	my $Project_config = $user_constants->get_Project_config();

	my $active_project_name = $user_constants->get_active_project_name();
	my $FROM                = $ACTIVE_PROJECT . '/' . $Project_config;
	my $TO =
	  $CONFIGURATION . '/' . $active_project_name . '/' . $Project_config;

	my $PATH = $CONFIGURATION . '/' . $active_project_name;

	#	print("files_LSU,write2, active_project_name: $active_project_name\n");
	#	print("files_LSU,write2, CONFIGURATION: $CONFIGURATION\n");
	#	print("files_LSU,write2, Project_config: $Project_config\n");
	manage_dirs_by->make_dir($PATH);
	copy( $FROM, $TO );

	#	 print("files_LSU,write2, copy from:$FROM to:$TO \n");

	if ( $files_LSU->{_outbound2} ) {

#         print("files_LSU, write2, files_LSU->{_outbound2}: $files_LSU->{_outbound2} \n");

		open( my $fh, '>', $files_LSU->{_outbound2} )
		  or die "Can't open parameter file:$!";

		for ( my $i = 0 ; $i < $length_info ; $i++ ) {

			my $a = $info[$i];

			# remove terminal quotes
			$a = $control->no_quotes($a);

			printf $fh $a;
		}

		for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

			if ( defined $CFG[ ( $j + 1 ) ] ) {

				my $cfg = $CFG[ ( $j + 1 ) ];

				# remove all terminal quotes
				$cfg = $control->get_no_quotes($cfg);

				if ( defined $cfg )
				{    # because removing quotes from an empty string does this

#			    print (" files_LSU, write2, only Project.config, j:   $CFG[$j]=$cfg\n");
					printf $fh "%-35s%1s%-20s\n", $CFG[$j], "= ", $cfg;

				}
				else {

# print("1 files_LSU,write2, cfg is not defined NADA\n");
# printf $fh "                                                        \n", $CFG[$j], "= ",
#	$empty_string;
				}

			}
			else {

# print("2 files_LSU,write2, cfg is not defined NADA\n");
# printf $fh "                                                        \n", $CFG[$j], "= ", $empty_string;
			}
		}

		close($fh);

	}
	else {
		print("files_LSU,write2, missing files_LSU->{_outbound2}\n");
	}
}

=head2 sub write_config


=cut 

sub write_config {
	my ($self) = @_;

	my $length      = ( scalar @{ $files_LSU->{_CFG} } ) / 2;
	my $length_info = scalar @{ $files_LSU->{_info} };
	my @info        = @{ $files_LSU->{_info} };
	my @CFG         = @{ $files_LSU->{_CFG} };

	open( my $OUT, '>', $files_LSU->{_outbound} );

	for ( my $i = 0 ; $i < $length_info ; $i++ ) {
		printf $OUT $info[$i];
	}

	for ( my $i = 0, my $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {
		printf $OUT "    %-SET_OU35s%1s%-20s\n", $CFG[$j], "= ",
		  $CFG[ ( $j + 1 ) ];
	}
	close($OUT);
}

=head2 sub save

	write out user-built *.pl flow files

	for (my $i=0, my $j=0;  $i<$length; $i++, $j=$j+2){
    	printf  $OUT "                                                        \n",$CFG[$j],"= ",$CFG[($j+1)];
    }

=cut 

sub save {
	my ($self) = @_;

	_open2write();
	_set_prog_names_aref();
	_set_prog_version_aref();    # already collected in sub set_data

#	print("files_LSU, save, is data:files_LSU->{_is_data}?:$files_LSU->{_is_data}\n");

	# for suffix type
	$oop_text->set_data_io_L_SU($files_LSU)
	  ;    # already collected in sub set_data;

	$oop_text->set_message($files_LSU);    # already collected in sub set_data;
	$oop_text->set_filehandle( $files_LSU->{_filehandle} );
	$oop_text->set_num_progs4flow( $files_LSU->{_prog_names_aref} );
	my $num_progs4flow = scalar @{ $files_LSU->{_prog_names_aref} };

	#	print("\nfiles_LSU,save,num_progs4flow: $num_progs4flow\n");

	# principal documentation for the program
	$oop_text->get_pod_header();

	# for message and flow
	$oop_text->get_use_pkg();

	# for all programs in the flow
	$oop_text->instantiation();

	# establish local variables e.g., my @sugain
	$oop_text->get_pod_declare();

	#	print("1. files_LSU_ save, declaring packages\n");
	$oop_text->get_declare_pkg();

	# insert a macro start here
	# $oop_text->set_macro_head(pkg);

	# DECLARE DATA
	for ( my $j = 0 ; $j < $num_progs4flow ; $j++ ) {

		# check each program
		my $prog_name = @{ $files_LSU->{_prog_names_aref} }[$j];

		if ( $prog_name eq 'data_in' ) {

			if ( $files_LSU->{_is_data_in} ) {

				my @params =
				  @{ @{ $files_LSU->{_prog_param_values_aref2} }[$j] };
				my $file_name = $params[0];
				$oop_text->set_file_name_in($file_name);

				#				print("1. files_LSU_ save, prog_name=$prog_name\n");

			}
			else {

#				print("2. files_LSU, save, missing,files_LSU->{_is_data_in}=$files_LSU->{_is_data_in}\n ");
#				print("2. files_LSU, save, missing, we have data\n ");
			}    # we have data
		}

		if ( $prog_name eq 'data_out' ) {    #TODO
				# print("1. files_LSU, got to declare data \n");
				# we have data
			if ( $files_LSU->{_is_data_out} ) {

				my @params =
				  @{ @{ $files_LSU->{_prog_param_values_aref2} }[$j] };
				my $file_name = $params[0];
				$oop_text->set_file_name_out($file_name);

				#				print("2. files_LSU_ save, prog_name=$prog_name\n");

			}
		}
	}

	# print $files_LSU->{_filehandle}  'here\n';
	#	# pod_instantiation();
	#	# instantiation();

	# declare programs and their parameters
	for ( my $j = 0 ; $j < $num_progs4flow ; $j++ ) {

		my $prog_name = @{ $files_LSU->{_prog_names_aref} }[$j];
		my $version   = @{ $files_LSU->{_items_versions_aref} }[$j];
		my $num_params4prog =
		  scalar @{ @{ $files_LSU->{_prog_param_values_aref2} }[$j] };

		# fix one program name
		$oop_text->set_prog_name($prog_name);

		# fix current version
		$oop_text->set_prog_version($version);

		# pod setup of parameter values
		$oop_text->set_pod_prog_param_setup();

		my @values = @{ @{ $files_LSU->{_prog_param_values_aref2} }[$j] };
		my @labels = @{ @{ $files_LSU->{_prog_param_labels_aref2} }[$j] };

		# print("files_LSU,save,prog_name:$prog_name\n");
		# print("files_LSU,save,prog_values_aref:@values\n");
		# print("files_LSU,save,prog_labels_aref:@labels\n");
		# print("files_LSU,save,version:$version\n");

		$oop_text->set_prog_version($version);
		$oop_text->set_prog_param_values_aref( \@values );
		$oop_text->set_prog_param_labels_aref( \@labels );

		# printing to executable file
		$oop_text->get_program_params();

	}

	$oop_text->get_pod_flows();
	$oop_text->get_define_flows();

	$oop_text->get_pod_run_flows();
	$oop_text->get_run_flows();

	$oop_text->get_pod_log_flows();
	$oop_text->get_print_flows();
	$oop_text->get_log_flows();

	# insert a macro end here
	# $oop_text->set_macro_tail()

	_close();
}

1;
