package App::SeismicUnixGui::misc::config_superflows;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 Perl package: config_superflows.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 22 2017 

 DESCRIPTION: 
 V 0.1 June 22 2017
 V 0.2 June 23 2017
   change class name from sunix.pm     

 USED FOR: 

 BASED ON: param_sunix
 inherits from: param_sunix (e.g., sub first_idx)
 TODO: fully inherit from param_sunix 

=cut

use Moose;
our $VERSION = '1.0.0';
use Carp;

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::big_streams::immodpg_global_constants';
use aliased 'App::SeismicUnixGui::misc::big_streams_param';
use aliased 'App::SeismicUnixGui::misc::files_LSU';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=pod

 private hash_ref
 for widgets

=cut

my $config_superflows = {
	_program_name_sref         => '',
	_program_name_sref         => '',
	_label_boxes_w             => '',
	_entry_boxes_w             => '',
	_check_buttons_w           => '',
	_all_aref                  => '',
	_first_idx                 => '',
	_length                    => '',
	_inbound                   => '',
	_program_name_config       => '',
	_size                      => '',
};

my $get                   = L_SU_global_constants->new();
my $get_immodpg           = immodpg_global_constants->new();
my $var                   = $get->var();
my $var_immodpg           = $get_immodpg->var();
my $on                    = $var->{_on};
my $off                   = $var->{_off};
my $nu                    = $var->{_nu};
my $yes                   = $var->{_yes};
my $no                    = $var->{_no};
my $empty_string          = $var->{_empty_string};
my $superflow_names       = $get->superflow_names_h();
my $superflow_names_gui_h = $get->superflow_names_gui_h();

my $alias             = $get->alias_superflow_names_h;
my $global_lib        = $get->global_libs();
my $GLOBAL_CONFIG_LIB = $global_lib->{_param};

=head2 sub  _get_program_name


=cut 

sub _get_program_name {

	my ($self) = @_;

	my $result;

	if ( length $config_superflows->{_program_name_sref} ) {

		$result = $config_superflows->{_program_name_sref};

	}
	else {
		print("config_superlows,_get_program_name,missing program name\n");
		$result = $empty_string;
	}

	return ($result);

}

sub get_names {
	my ($self) = @_;

	my $cfg_aref = $config_superflows->{_all_aref};
	my $length   = $config_superflows->{_length};
	my ( $i, $j );
	my @names;

	for ( $i = 0, $j = 0 ; $i < $length ; $i = $i + 2, $j++ ) {
		$names[$j] = @$cfg_aref[$i];

	   #		print(" config_superflows, get_names :index $j names:  $names[$j]\n");
	}
	return ( \@names );
}

sub get_check_buttons_settings {
	my ($self)   = @_;
	my $cfg_aref = $config_superflows->{_all_aref};
	my $length   = $config_superflows->{_length};
	my ( $i, $j );
	my @on_off;
	my @values;

	for ( $i = 1, $j = 0 ; $i < $length ; $i = $i + 2, $j++ ) {
		$values[$j] = @$cfg_aref[$i];

# print("config_superflows, get_check_buttons_settings :index $j values: $values[$j]\n");

		if ( $values[$j] eq $nu || $values[$j] eq $no ) {

			$on_off[$j] = $off;

# print("1 config_superflows: get_check_buttons_settings 'nu' or no :index $j setting: $on_off[$j]\n");

		}
		elsif ( $values[$j] eq "" ) {    # test form empty string
			$on_off[$j] = $off;

# print("2 config_superflows: get_check_buttons_settings, empty string :index $j setting: $on_off[$j]\n");
		}
		else {
			$on_off[$j] = $on;

# print("3 config_superflows: get_check_buttons_settings, else, :index $j setting: $on_off[$j]\n");
		}

# print("config_superflows: get_check_buttons_settings :index $j setting: $on_off[$j]\n");
	}
	return ( \@on_off );
}

sub get_values {

	my ($self) = @_;

	my $cfg_aref = $config_superflows->{_all_aref};
	my $length   = $config_superflows->{_length};
	my ( $i, $j );
	my @values;

	#	print("cfg_aref is @$cfg_aref\n");

	for ( $i = 1, $j = 0 ; $i < $length ; $i = $i + 2, $j++ ) {
		$values[$j] = @$cfg_aref[$i];

	#	print("config_superflows, get_values :index $j values:--$values[$j]--\n");
	}

	return ( \@values );
}

=head2 sub length

 length is not the last index but one beyond
 print("config_superflows, lengthis $config_superflows->{_length}\n");
 	 print("config_superflows, length (x2) is $config_superflows->{_length}\n");
 	TODO: subroutine will fail unless _defaults are first called

=cut 

sub length {

	my ($self) = @_;

	_get_all();

	if ( $config_superflows->{_length} ) {

		$config_superflows->{_length} = $config_superflows->{_length} / 2;
		return ( $config_superflows->{_length} );
	}
	else {
		print("config_superflows,length. length is missing\n");
		return ();
	}
}

=pod

 export all the private hash references

=cut

sub _get_all {

	my ($self) = '';

	# print("config_superflows,_get_all \n");
	_local_or_defaults( $config_superflows->{_program_name_sref} );
	return ();
}

=head2 sub _local_or_defaults

 Read a default specification file 
 If default specification file# does not exist locally, 
 which is in PL_SEISMIC  for general superflow conguration files
 and and in legacy cases for Project.config
 If Project.config is not found check the user's configuration area: .LSU/configuration/active/Project.config
 and if not,
 then use the default one defined under global libs 
 Similary if a general superflow.configuration file is not found under PL_SEISMIC
 check for one default case under global libs

 Debug with
    print ("self is $self,program is $program_name\n");
 print("params are @$ref_CFG\n");
 program name is a hash
    print("params are @$ref_cfg\n");
    print ("self is $self,program is $program_name\n");
       print("config_superflows,_local_or_defaults,program_name:$$program_name_sref\n"); 
       print("config_superflows,_local_or_defaults,program_name:$$name_sref\n"); 
       print("config_superflows,_local_or_defaults,program_name:$$program_name_sref\n"); 

=cut

sub _local_or_defaults {
	my ($self) = @_;
	my $name_sref = $config_superflows->{_program_name_sref};

	#	print(
	#"config_superflows, _local_or_defaults,SCALAR program name=$$name_sref\n"
	#	);

	my $big_streams_param   = big_streams_param->new();
	my $flow_type           = $get->flow_type_href();
	my $pre_built_superflow = $flow_type->{_pre_built_superflow};

	# set flow type before big_streams_param->get
	$big_streams_param->set_flow_type($pre_built_superflow);

# print("1. config_superflows, _local_or_defaults,pre_built_superflow=$pre_built_superflow\n");
	my $cfg_aref = $big_streams_param->get($name_sref);
	$config_superflows->{_all_aref} = $cfg_aref;
	$config_superflows->{_length}   = $big_streams_param->my_length();

# length seems > true length + 1, TODO
# print("config_superflows, _local_or_defaults,length=$config_superflows->{_length}\n");
	return ();
}

=head2 sub get_local_or_defaults

 via big_streams_param:
 
 Read a default specification file 
 1) If default specification file does not exist locally (PL_SEISMIC),
 2) then check the user's configuration area: .LSU/configuration/active/Project.config
 and if if still does not exist there,
 3) then use the default one defined under global libs.

 Debug with
    print ("self is $self,program is $program_name\n");
 print("params are @$ref_CFG\n");
 program name is a hash
    print("params are @$ref_cfg\n");
    print ("self is $self,program is $program_name\n");
       print("config_superflows,get_local_or_defaults,program_name:$$program_name_sref\n"); 
       print("config_superflows,get_local_or_defaults,program_name:$$name_sref\n"); 
       print("config_superflows,get_local_or_defaults,program_name:$$program_name_sref\n"); 
    print("config_superflows,get_local_or_defaults, length:$config_superflows->{_length}\n");

=cut

sub get_local_or_defaults {
	my ( $self, $config_base_name ) = @_;

	print(
"config_superflows, get_local_or_defaults,program name=$config_base_name\n"
	);

	if ( $config_superflows->{_program_name_sref} ) {

		my $big_streams_param = big_streams_param->new();
		my ( $cfg_aref, $size );

		my $name_sref = $config_superflows->{_program_name_sref};

 # print("config_superflows, get_local_or_defaults,program name=$$name_sref\n");
		print(
"config_superflows, get_local_or_defaults,SCALAR program name=$name_sref\n"
		);

		$cfg_aref = $big_streams_param->get($name_sref);

		print(
			"config_superflows, get_local_or_defaults,cfg_aref = @{$cfg_aref}\n"
		);
		return ($cfg_aref);

		#		}
	}
	else {
		print(
"config_superflows, get_local_or_defaults,missing program_name_sref\n"
		);
	}

}

=head2 sub save

	i/p: has a reference with the names values and program name
	names are in an array reference
	values are too
	no need for checkbuttons
        # print("config_superflows,save\nprog_name: ${$out_hash_ref->{_prog_name}}");
        # print("  labels: @{$out_hash_ref->{_ref_labels}}\n");
        # print("  values: @{$out_hash_ref->{_ref_values}}\n");

=cut

sub save {

	my ( $self, $in_hash_ref ) = @_;
#		print(
#"config_superflows,save,in_hash_ref:...${$in_hash_ref->{_prog_name_sref}}...)\n"
#		);
	if ( defined $in_hash_ref
      &&  ${$config_superflows->{_program_name_sref}}  ne $empty_string )
	{

		my $out_hash_ref = {
			_ref_labels     => '',
			_ref_values     => '',
			_prog_name_sref => '',
		};

		my $files_LSU = files_LSU->new();

		$out_hash_ref->{_ref_labels} = $in_hash_ref->{_names_aref};
		$out_hash_ref->{_ref_values} = $in_hash_ref->{_values_aref};

# N.B. IT is NOT $in_hash_ref->{_prog_name_sref};
		$out_hash_ref->{_prog_name_sref} =
		  $config_superflows->{_program_name_sref}; # backup

# print("config_superflows,save,out_hash_ref, ${$out_hash_ref->{_prog_name_sref}}\n");
# print("config_superflows,save,out_hash_ref,@{$out_hash_ref->{_ref_values}}[1]\n");
# print("config_superflows,save,out_hash_ref,@{$out_hash_ref->{_ref_labels}}\n");
# print("config_superflows,save,values are,@{$out_hash_ref->{_ref_values}}\n");

		if ( ${ $out_hash_ref->{_prog_name_sref} } eq 'Project' ) {

			# Single special case
#			print("CASE config_superflows,save, for special Project case\n");
			$files_LSU->set_Project_config();
			# NEXT 3 are scalar ref
			$files_LSU->set_prog_name_sref( $out_hash_ref->{_prog_name_sref} );
			$files_LSU->set_outbound( $out_hash_ref->{_prog_name_sref} ); 
			$files_LSU->set_superflow_specs($out_hash_ref);
			
			# to /home/gom/.L_SU/configuration/active/Project.config	  
			$files_LSU->write(); 
			
			# also create additional directory and file in the configuration area
			# of the project. 
			# to /home/gom/.L_SU/configuration/ProjectName/Project.config
			# If directories are missing some will be created.
			# scalar ref
			$files_LSU->set_outbound2( $out_hash_ref->{_prog_name_sref} ); 
			
			$files_LSU->write2();    
	    

		}
		else {
			my @format;

	        # CASE 2 all other superflow configuration files except for Project.config
	  		
			$files_LSU->set_config();
			$files_LSU->set_prog_name_sref( $out_hash_ref->{_prog_name_sref} )
			  ;    # scalar ref
#			print("CASE 2 config_superflows,save, for other cases\n");
#			print(" config_superflows,save,program name = ${$out_hash_ref->{_prog_name_sref}}\n");
			$files_LSU->outbound();
			$files_LSU->set_superflow_specs($out_hash_ref);    # scalar ref

			my $program_name_sref = _get_program_name();

			if ( $$program_name_sref ne $empty_string ) {

				if ( $$program_name_sref eq 'immodpg' ) {

	 # carp("config_superflows,save,progam_name_sref= ${$program_name_sref}\n");

					@format = @{ $var_immodpg->{_format_aref} };

		  #		        print("1. config_superflows, _write,formats =@format  \n");
					$files_LSU->set_superflow_config_file_format( \@format );

				}
				else {
					# All other superflows/big_streams
					$format[0] = $var->{_config_file_format};
#					print("2. config_superflows, _write,formats =@format  \n");
					$files_LSU->set_superflow_config_file_format( \@format );
				}

				# Just before return statement
				$files_LSU->check2write();    # to $PL_SEISMIC/prog_name.config

			}
		}

	}
	else {
		print("config_superflows,save, missing values");
	}
	return ();

}


=head2 sub  set_program_name

 i/p is scalar ref
 o/p is scalar ref
 print("config_superflows, program_name,:$alias->{ProjectVariables}\n"); 

=cut 

sub set_program_name {
	my ( $self, $program_name_sref ) = @_;

# print("config_superflows, set_program_name, program_name=$$program_name_sref\n");
# print("config_superflows, set_program_name, program_name=$superflow_names->{_fk}\n");
	if ($program_name_sref) {
		my $name_sref;

		if (
			$$program_name_sref eq $superflow_names->{_fk} # alias does not work
			or $$program_name_sref eq $superflow_names->{_Sudipfilt}
		  )
		{
			# print("config_superflows, fk name = $superflow_names->{_fk}\n");
			$name_sref = \$alias->{fk};

# print("config_superflows, alias of $superflow_names->{_fk} is $$name_sref\n");
		}

		if ( $$program_name_sref eq $superflow_names->{_iBottomMute} ) {
			$name_sref = \$alias->{iBottomMute};
		}

		if ( $$program_name_sref eq $superflow_names->{_iSpectralAnalysis} ) {
			$name_sref = \$alias->{iSpectralAnalysis};
		}

		if ( $$program_name_sref eq $superflow_names->{_iTopMute} ) {
			$name_sref = \$alias->{iTopMute};
		}

		if (   $$program_name_sref eq $superflow_names->{_iVelAnalysis}
			or $$program_name_sref eq $superflow_names->{_iVA} )
		{

   # print("config_superflows, iVA name = $superflow_names->{_iVelAnalysis}\n");
			$name_sref = \$alias->{iVelAnalysis};

		   # print("config_superflows, alias of program name is $$name_sref\n");
		}

		if ( $$program_name_sref eq $superflow_names->{_Project} ) {

# warning: must omit underscore
			$name_sref = \$alias->{Project};
		}

		if ( $$program_name_sref eq $superflow_names->{_ProjectVariables} ) {

# warning: must omit underscore
			$name_sref = \$alias->{ProjectVariables};
		}

		if ( $$program_name_sref eq $superflow_names->{_Synseis} ) {

# warning: must omit underscore
			$name_sref = \$alias->{Synseis};
		}

		if ( $$program_name_sref eq $superflow_names->{_Sseg2su} ) {

# warning: must omit underscore
			$name_sref = \$alias->{Sseg2su};
		}

		if ( $$program_name_sref eq $superflow_names->{_Sucat} ) {

# warning: must omit underscore
			$name_sref = \$alias->{Sucat};
		}

		if ( $$program_name_sref eq $superflow_names->{_iPick} ) {

			# warning: must omit underscore
			$name_sref = \$alias->{iPick};
		}

		if ( $$program_name_sref eq $superflow_names->{_immodpg} ) {

# warning: must omit underscore
#print("config_superflows, set_program_name,superflow_names=$superflow_names->{_immodpg}\n");
# print("config_superflows, set_program_name,alias superflow_names=$superflow_names->{_immodpg}\n");

			$name_sref = \$alias->{immodpg};

		   # print("config_superflows, alias of program name is $$name_sref\n");
		}

		# accounts for when gui name differs from internal program name
		if (
			$$program_name_sref eq $superflow_names_gui_h->{_ProjectBackup}

			# accounts for when gui name equals internal program name
			or $$program_name_sref eq $superflow_names->{_BackupProject}
		  )
		{

# warning: must omit underscore
# specifies internal program names
			$name_sref = \$alias->{ProjectBackup};

#		   print("config_superflows, alias of program name is $$name_sref\n");
		}
		
				# accounts for when gui name differs from internal program name
		if (
			$$program_name_sref eq $superflow_names_gui_h->{_ProjectRestore}

			# accounts for when gui name equals internal program name
			or $$program_name_sref eq $superflow_names->{_RestoreProject}
		  )
		{

# warning: must omit underscore
# specifies internal program names
			$name_sref = \$alias->{ProjectRestore};

#		   print("config_superflows, alias of program name is $$name_sref\n");
		}

		if ( $$program_name_sref eq $superflow_names->{_temp} ) {

# warning: must omit underscore
			$name_sref = \$alias->{temp};
		}

		$config_superflows->{_program_name_sref} = $name_sref;
#		print(
#			"config_superflows,set_program_name internal name: ${$config_superflows->{_program_name_sref}}\n");
		_get_all();

	}
	else {
		print("config_superflows,set_program_name alias, missing value\n");
	}
	return ();
}

=head2

=cut

sub get_prog_name_config {
	my ($self) = @_;

	if ( $config_superflows->{_program_name_config} ) {

		my $prog_name_config = $config_superflows->{_program_name_config};

		# print("config_superflows,get_prog_name_config: $prog_name_config\n");
		return ($prog_name_config);

	}
	else {
		print("config_superflows, get_prog_name_config: missing \n");
		return ();
	}
}

=head2

=cut

sub _get_prog_name_config {
	my ($self) = @_;

	if ( $config_superflows->{_program_name_config} ) {

		my $prog_name_config = $config_superflows->{_program_name_config};
		return ($prog_name_config);

	}
	else {
		print(
"config_superflows, _get_prog_name_config: $config_superflows->{_program_name_sref}\n"
		);
		return ();
	}
}

=head2 sub first_idx

 first usable index is set to 0

=cut 

sub first_idx {

	my ($self) = @_;

	$config_superflows->{_first_idx} = 0;

	my $result = $config_superflows->{_first_idx};
	return ($result);

}

=head2 sub set_prog_name_config

needs $config_superflows->{_program_name_sref}

=cut

sub set_prog_name_config {
	my ( $self, $program_name_sref ) = @_;
	if ($program_name_sref) {

		my $prog_name = $$program_name_sref;
		$config_superflows->{_program_name_config} = $prog_name . '.config';

	}
	else {

		print(
"config_superflows, set_prog_name_config,_program_name_sref: missing\n"
		);
	}
	return ();
}

=head2 sub inbound

		print("config_superflows, inbound, prog_name: $prog_name\n");
		print("config_superflows, inbound, outbound: $config_superflows->{_program_name_config}\n");
		print("config_superflows, inbound, outbound: $config_superflows->{_inbound}\n");

=cut

sub inbound {
	my ($self) = @_;

	if ( $config_superflows->{_program_name_sref} ) {

		my $Project    = Project_config->new();
		my $PL_SEISMIC = $Project->PL_SEISMIC();

		my $prog_name = ${ $config_superflows->{_program_name_sref} };
		$config_superflows->{_program_name_config} = $prog_name . '.config';
		$config_superflows->{_inbound} =
		  $PL_SEISMIC . '/' . $config_superflows->{_program_name_config};

   #	    print("config_superflows, inbound:: $config_superflows->{_inbound}\n");

		return ();

	}
	else {

		print("config_superflows, inbound, missing program_name_sref\n");

	}

}


=head2 sub check2read

needs $config_superflows->{_inbound}
first look in $PL_SEISMIC and then 
look in the default global library

=cut

sub check2read {
	my ($self) = @_;

	if ( $config_superflows->{_inbound} ) {

		if ( not -e $config_superflows->{_inbound} ) {   #if file does not exist

			use File::Copy;
			my $prog_name_config = _get_prog_name_config();

			my $from = $GLOBAL_CONFIG_LIB . $prog_name_config;
			my $to   = $config_superflows->{_inbound};

			copy( $from, $to );

			# print("config_superflows copy $from to $to \n");

		}
		else {

# print("config_superflows, write_config, configuration file exists and will be overwritten\n");

		}
	}
	return ();
}

# removes Moose exports
# no Moose;
# increases speed
#__PACKAGE__->meta->make_immutable;
1;
