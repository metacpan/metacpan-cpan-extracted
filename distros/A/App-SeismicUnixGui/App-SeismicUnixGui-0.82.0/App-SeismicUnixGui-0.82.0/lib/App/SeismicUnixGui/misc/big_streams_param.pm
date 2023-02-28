package App::SeismicUnixGui::misc::big_streams_param;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PACKAGE NAME: big_streams_param 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2022

 DESCRIPTION V 0.0.3
 BASED ON: su_params.pm V0.0.3

=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES
	May 5 2018 looks for configurations
	first in the local directory
	then in the default configuration
	directory /usr/local/pl/big_streams/config
	
	V 0.0.3 June 2022 reference to L_SU_local_user_constants
	removed
	L_SU_local_user_constants may create cirularity

=cut 

=head2

 parameters for seismic unix programs
 both macros and individual modules
  
=cut

use Moose;
our $VERSION = '0.0.3';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_path';
use aliased 'App::SeismicUnixGui::misc::developer';
use aliased 'App::SeismicUnixGui::misc::readfiles';

use Shell qw(echo);

my $L_SU_global_constants = L_SU_global_constants->new();
my $L_SU_path             = L_SU_path->new();
my $read                  = readfiles->new();
my $developer             = developer->new();
my $HOME                  = ` echo \$HOME`;
chomp $HOME;

# magic number TODO
my $var                      = $L_SU_global_constants->var();
my $ACTIVE_PROJECT           = $HOME . $var->{_ACTIVE_PROJECT};
my $user_active_project_path = $ACTIVE_PROJECT;

my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

# imports 2 different flow type definisions
my $flow_type_href = $L_SU_global_constants->flow_type_href();

my $big_streams_param = {
	_flow_type                => '',
	_name_space               => 'name_space',
	_local_path               => '',
	_path                     => '',
	_sub_category_directory   => '',
	_program_config           => '',
	_program_sref             => '',
	_user_active_project_path => $user_active_project_path,
	_names_aref               => '',
};

sub set_flow_type {

	my ( $self, $flow_type ) = @_;

	if ( defined $flow_type
		&& $flow_type ne $empty_string )
	{

		$big_streams_param->{_flow_type} = $flow_type;

# print("big_streams_param,  set_flow_type ,flow_type=$big_streams_param->{_flow_type}\n");

	}
	else {
		print("big_streams_param,  set_flow_type , missing value\n");
	}

	return ();
}

sub _check4corruption_config {

	my ($self) = @_;

	my $corruption = $false;

	if (    length $big_streams_param->{_path}
		and length $big_streams_param->{_sub_category_directory} )
	{

		my $program_config = _get_program_config();

  #		print(
  #"big_streams_param, _check4corruption_config, file to read=$program_config\n"
  #		);

		my ( $names_aref, $values_aref ) = $read->configs($program_config);
		my @names  = @$names_aref;
		my $length = scalar @names;

		#		print(
		#"big_streams_param,_check4corruption_config, we have $length pairs\n\n"
		#		);

		for ( my $i = 0 ; $i < $length ; $i++ ) {

			# test for empty names
			if (   $names[$i] eq $empty_string
				or $names[$i] eq '0.000' )
			{

				$corruption = $true;

			 #				print(
			 #					"big_streams_param,_check4corruption_config, $names[$i]\n");
			 #				print(
			 #"big_streams_param,_check4corruption_config, corruption = $true\n"
			 #				);

			}
			else {
				$corruption = $false;

#				print(
#					"big_streams_param,_check4corruption_config, no corruption, $names[$i]\n")
#				  ;
			}
		}

	}
	else {
		$corruption = $true;
		print(
			"big_streams_param,_check4corruption_config, missing variables\n");
		print("as follows: \n");
		print("big_streams_param->{_path}=$big_streams_param->{_path}\n");
		print(
"big_streams_param->{_sub_category_directory}=$big_streams_param->{_sub_category_directory}\n"
		);
	}

	return ($corruption);
}

sub _get_global_lib {

	my ($elf) = @_;

	my $global_libs_href = $L_SU_global_constants->global_libs();

	if (   defined $global_libs_href
		&& $global_libs_href ne $empty_string
		&& defined $big_streams_param->{_flow_type} )
	{

		my $result;

		if ( $big_streams_param->{_flow_type} eq
			$flow_type_href->{_pre_built_superflow} )
		{

			$big_streams_param->{_lib_path} = $global_libs_href->{_param};

# print("big_streams_param, _get_global_lib,lib_path= $big_streams_param->{_lib_path}\n");
			$result = $big_streams_param->{_lib_path};
			return ($result);

		}
		elsif (
			$big_streams_param->{_flow_type} eq $flow_type_href->{_user_built} )
		{

			$big_streams_param->{_lib_path} = $global_libs_href->{_param};

# print("big_streams_param, _get_global_lib, lib_path: $big_streams_param->{_lib_path}\n");
			$result = $big_streams_param->{_lib_path};
			return ($result);

		}
		else {
			print("big_streams_param, _get_global_lib, unexpected value\n");
			return ();
		}

	}
	else {
		print("big_streams_param, _get_global_lib, missing value\n");
	}

	return ();

}

sub _set_sub_category_directory {

	my ($sub_category_directory) = @_;

	if ( defined $sub_category_directory
		&& $sub_category_directory ne $empty_string )
	{

		$big_streams_param->{_sub_category_directory} = $sub_category_directory;

	}
	else {
		print(
			"big_streams_param, _set_sub_category_directory, missing value\n");

	#		print(
	#"big_streams_param, _set_sub_category_directory, $sub_category_directory\n"
	#		);
	}

	return ();
}

sub _set_path {

	my ($path) = @_;

	if ( length $path
		&& $path ne $empty_string )
	{

		$big_streams_param->{_path} = $path;

		#		print("big_streams_param, _set_path, path=$path\n");

	}
	else {
		print("big_streams_param, _set_path, missing value\n");
	}

	return ();
}

sub _set_program_sref {

	my ($program_sref) = @_;

	if ( defined $$program_sref
		&& $$program_sref ne $empty_string )
	{

		$big_streams_param->{_program_sref} = $program_sref;

	}
	else {
		print("big_streams_param, _set_program_config, missing value\n");
		return ();
	}

	return ();
}

sub _get_program_config {

	my ($path) = @_;

	my ( $program_config, $sub_category_directory, $program_sref );

	$path                   = $big_streams_param->{_path};
	$sub_category_directory = $big_streams_param->{_sub_category_directory};
	$program_sref           = $big_streams_param->{_program_sref};

#	print("big_streams_param, get_program_config, path = $path\n");
#	print(
#"big_streams_param, get_program_config, sub_category_directory = $sub_category_directory\n"
#	);
#	print("big_streams_param, get_program_config, program_sref= $$program_sref\n");

	if (   defined $path
		&& $path ne $empty_string
		&& defined $sub_category_directory
		&& $sub_category_directory ne $empty_string
		&& defined $$program_sref
		&& $$program_sref ne $empty_string )
	{

		$program_config =
			$path . '/'
		  . $sub_category_directory . '/'
		  . $$program_sref
		  . '.config';

		$big_streams_param->{_program_config} = $program_config;
		my $result = $program_config;
		return ($result);

	}
	else {
		print("big_streams_param, _set_program_config, missing value\n");
		return ();
	}

}

=head2 sub get

  returns values
  as an array
  input is a scalar reference
  used both by superflow/pre-built flows and seismic unix configuration files
  
 Read a default specification file 
 If default specification file does not exist locally (PL_SEISMIC),
 look in the user's configuration directory
 ~HOME/.L_SU/configuration/active and if that does not exist,
 then use the default one defined under global libs
 
 Check that the configuration file in the local directory is not corrupt

  Debug with
    print ("this is $this\n");
    print ("self is $self,program is $program\n");

  Changing the namespace variables to lower
  case is not a general solution because
  original variables can have mixed upper and lower
  case names
  
  DEPRECATED:
  Older versions may use Config::Simple
    my $a = Config::Simple->import_from($this,'Z');
     foreach my $key ( keys %Z:: )
    {
       my $x = lc $key;
        print "key is $x\n";
        print "$cfg->param($key)\n";
    }


=cut

sub get {

	my ( $self, $program_sref ) = @_;

	if (   defined $program_sref
		&& ( defined $big_streams_param->{_flow_type} )
		&& ( $big_streams_param->{_flow_type} ne $empty_string ) )
	{

		my (@CFG);
		my ( $length, $names_aref, $values_aref );
		my ( $i, $j, $program_config, $path );
		my $sub_category_directory;
		my $config_corrupt;

		$developer->set_program_name($$program_sref);
		$developer->set_flow_type( $big_streams_param->{_flow_type} );
		_set_program_sref($program_sref);

		# reset the following tests to 0 (false)
		my $local_config_exists = _check4local_config($program_sref);
		my $user_active_project_path_exists = _check4user_config($program_sref);

#		print(
#"B. big_streams_param,get,local_config_exists:$local_config_exists\n"
#		);
#
#		print(
#"C. big_streams_param,get,user_active_project_path_exists:$user_active_project_path_exists\n"
#		);
#		print(
#"D. big_streams_param,get,big_streams_param->{_flow_type}:$big_streams_param->{_flow_type}\n"
#		);
#		print(
#"E. big_streams_param,get,flow_type_href->{_pre_built_superflow}:$flow_type_href->{_pre_built_superflow}\n"
#		);

		if ( $big_streams_param->{_flow_type} eq
			$flow_type_href->{_pre_built_superflow} )
		{

			if ($local_config_exists) {

	 # CASE for previously run
	 # Tools except Project
	 #				print(
	 #"big_streams_param, get,CASE 1A: If progam_sref = a pre-built superflow\n"
	 #				);

				# e.g., with tools like Sseg2su.config
				# but not with Project.config

				use Module::Refresh;    # reload updated module
				my $refresher = Module::Refresh->new();

				my $program_name = $$program_sref;
				$L_SU_path->set_program_name($program_name);

				my $pathNmodule_spec_w_slash_pm =
				  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
				my $pathNmodule_spec_w_colon =
				  $L_SU_path->get_pathNmodule_spec_w_colon();

				$refresher->refresh_module($pathNmodule_spec_w_slash_pm);

				# INSTANTIATE
				my $package = $pathNmodule_spec_w_colon->new();

				# collect specifications of output directory
				# from a program_spec.pm module
				my $specs_h = $package->variables();
				my $CONFIG  = $specs_h->{_CONFIG};

				$big_streams_param->{_local_path} = $CONFIG;
				my $local_path             = $big_streams_param->{_local_path};
				my $sub_category_directory = '.';

				_set_path($local_path);
				_set_sub_category_directory($sub_category_directory);
				$config_corrupt = _check4corruption_config();

			}
			elsif ($user_active_project_path_exists) {

			   # CASE 1B:
			   # If progam_sref= Project
			   # and ONLY applies to  ./L_SU/configuration/active/Project.config
				$path = $big_streams_param->{_user_active_project_path};
				$sub_category_directory =
				  $developer->get_program_sub_category();

#				print(
#"CASE 1B big_streams_param,get,user_active_project_path_exists= $user_active_project_path_exists\n"
#				);
#				print(
#"1B big_streams_param,get,active path is now $big_streams_param->{_user_active_project_path} \n"
#				);

				_set_path($path);
				_set_sub_category_directory($sub_category_directory);
				$config_corrupt = $false;    #_check4corruption_config();

			}
			elsif ( not $local_config_exists ) {

				# CASE 1C: for a previously unused pre-built superflow
				# except Project
				$path = _get_global_lib();
				$sub_category_directory =
				  $developer->get_program_sub_category();

#				print(
#					"1C big_streams_param,get,using global lib: path is $path\n"
#				);
				_set_path($path);
				_set_sub_category_directory($sub_category_directory);
				$config_corrupt = $false;
			}

		}
		elsif (
			$big_streams_param->{_flow_type} eq $flow_type_href->{_user_built} )
		{
			# CASE 2A: for use of sunix programs in user_built_flows
			$path           = _get_global_lib();
			$config_corrupt = $false;

#			print(
#"CASE 2.A big_streams_param,get,using global lib: path for sunix programs is $path\n"
#			);
			$sub_category_directory = $developer->get_program_sub_category();

#			print(
#"2.A big_streams_param,get,using sub_category_directory:  for sunix programs is $sub_category_directory\n"
#			);
			_set_path($path);
			_set_sub_category_directory($sub_category_directory);
			$config_corrupt = $false;
		}
		else {
			print("big_streams_param,get,unexpected\n");
		}

		if ( $config_corrupt eq $false ) {

			# CASE:3A use the local configuration file
			#			print("CASE 3.A big_streams_param,get\n");
			# share local variables with the package namespace
			$program_config = _get_program_config();

		#			print("big_streams_param, get,configuration file is NOT corrupt\n");

			( $names_aref, $values_aref ) = $read->configs($program_config);
			$big_streams_param->{_names_aref} = $names_aref;
			$length = scalar @$names_aref;

			#		print("big_streams_param,get:we have $length pairs\n\n");
			for ( $i = 0, $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

				$CFG[$j] = $$names_aref[$i];
				$CFG[ ( $j + 1 ) ] = $$values_aref[$i];

				#			print("big_streams_param,get,values:--$CFG[$j+1]--\n");
			}

			return ( \@CFG );

		}

		elsif ( $config_corrupt eq $true ) {

			# CASE: use the default file
			# as if if were a pristine pre-built superflow

			if ($user_active_project_path_exists) {

				# CASE for Project ONLY
				carp("Warning: Project_configuration file is corrupt\n");
				$program_config = _get_program_config();

				( $names_aref, $values_aref ) = $read->configs($program_config);
				$big_streams_param->{_names_aref} = $names_aref;
				$length = scalar @$names_aref;

				# print("big_streams_param,get:we have $length pairs\n\n");
				for ( $i = 0, $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

					$CFG[$j] = $$names_aref[$i];
					$CFG[ ( $j + 1 ) ] = $$values_aref[$i];

					# print("big_streams_param,get,values:--$CFG[$j+1]--\n");
				}

				return ( \@CFG );

			}
			elsif ( not $user_active_project_path_exists ) {

				# CASE: All Tools except Project
				# get variables from the default files

				$path = _get_global_lib();
				$sub_category_directory =
				  $developer->get_program_sub_category();
				_set_path($path);
				_set_sub_category_directory($sub_category_directory);
				$program_config = _get_program_config();

		   #				print("big_streams_param, get,configuration file is corrupt\n");
		   #				print(
		   #					"big_streams_param, get,program_config=$program_config\n");
				( $names_aref, $values_aref ) = $read->configs($program_config);
				$big_streams_param->{_names_aref} = $names_aref;
				$length = scalar @$names_aref;

				# print("big_streams_param,get:we have $length pairs\n\n");
				for ( $i = 0, $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

					$CFG[$j] = $$names_aref[$i];
					$CFG[ ( $j + 1 ) ] = $$values_aref[$i];

			  #	print("big_streams_param,get,values:--$CFG[$j+1]--\n");
				}

				return ( \@CFG );

			}

		}
		else {
			print("big_streams_param, get, unexpected variable\n");
		}

	}
	else {
		print(
			"big_streams_param,get, missing either program_sref or flow type\n"
		);
		print("big_streams_param,get,program_sref:$$program_sref\n");
		print(
"big_streams_param,get, big_streams_param->{_flow_type}: $big_streams_param->{_flow_type}\n"
		);
		return ();
	}

}

=head2 sub _check4local_config

needs name_sref

CASE for any type of flow 
big streams/superflows or for
or sunix programs in user-built flows

Check for local versions of the configuration files in PL_SEISMIC
and also look in specified _CONFIG folder
 _CONFIG folder is defined as PL_SEISMIC for all but 
 pre-built big streams/superflows (e.g., immodpg)
 
(For pre-built big streams, look at  program_spec to find 
the definition for _CONFIG)

		#		my $a       = $package->variables();
		#		foreach my $key (sort keys %$a) {
		#      	print (" big_streams_param,_check4local_config, , key is $key, value is $a->{$key}\n");
		#	}
		#		my $ans= $a->{_CONFIG};
		#		print("2. big_streams_param,_check4local_config,package=$ans\n");

=cut

sub _check4local_config {

	my ($name_sref) = @_;

	my $ans = $false;

	if ( length $name_sref
		&& $name_sref ne $empty_string )
	{

		my $program_name = $$name_sref;
		$L_SU_path->set_program_name($program_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		if (    length $pathNmodule_spec_w_slash_pm
			and length $pathNmodule_spec_w_colon )
		{
			require $pathNmodule_spec_w_slash_pm;

			# INSTANTIATE
			my $package = $pathNmodule_spec_w_colon->new();

			# collect specifications of output directory
			# from a program_spec.pm module
			my $specs_h = $package->variables();
			my $CONFIG  = $specs_h->{_CONFIG};

			my $prog_name_config = $CONFIG . '/' . $$name_sref . '.config';

  #			print(
  #"big_streams_param,_check4local_config,prog_name_config =$prog_name_config\n"
  #			);
			if ( -e ($prog_name_config) ) {

#				print(
#"big_streams_param,_check4local_config,found: $prog_name_config. Using local configuration file\n"
#				);
				$ans = $true;

			}
			else {
				$ans = $false;

		 #				print(
		 #"big_streams_param,_check4local_config, $prog_name_config not found\n"
		 #				);
			}
		}    # module is found
	}
	else {
		print("big_streams_param,_check4local_config, missing name_sref \n");
		$ans = $false;
	}
	return ($ans);
}

=head2 sub _check4user_config

 check for versions of the configuration files
 in the user's configuration directory:
 .L_SU/configuration/active
 only needed for Project.config
 e.g., not for Sseg2su

=cut

sub _check4user_config {

	my ($name_sref) = @_;

	my $ans = $false;

	if (    length $ACTIVE_PROJECT
		and length $name_sref )
	{

		if ( -e ( $ACTIVE_PROJECT . '/' . $$name_sref . '.config' ) ) {
			$ans = $true;
		}
		else {
			$ans = $false;

	   #			print(
	   #"big_streams_param,_check4user_config, ACTIVE_PROJECT=$ACTIVE_PROJECT\n"
	   #			);

#			print("big_streams_param,_check4user_config, name =$$name_sref\n");
#			print(
#				"big_streams_param,_check4user_config,$$name_sref not found. \n
# 				Going forward will use default (GLOBAL LIBS) configuration file\n"
#			);
#			print(
#"big_streams_param,_check4user_config,$$name_sref.config found, Using user configuration file\n"
#			);
#			print("big_streams_param,_check4user_config=$ans\n");
		}
	}
	return ($ans);    #sub check4local_config
}

=head2 sub check4user_config

 check for versions of the Project.config file
 in the user's configuration directory:
 .L_SU/configuration/active
 for Project.config
 True when for $$name_sref='Project';

=cut

sub check4user_config {

	my ( $self, $name_sref ) = @_;

	my $ans = $false;

	if ($name_sref) {
		if ( -e ( $ACTIVE_PROJECT . '/' . $$name_sref . '.config' ) ) {
			$ans = $true;

# print("big_streams_param,check4user_config,$$name_sref.config found, Using user configuration file\n");
# print("big_streams_param,check4user_config=$ans\n");
		}
		else {
			$ans = $false;

# print("big_streams_param,check4user_config,$$name_sref not found. Using default (GLOBAL LIBS) configuration file\n")
		}
	}
	return ($ans);
}

=head2 sub my_length 
not found
 This length is twice the number of parameter
  names
  print("big_streams_param,length: is $length\n");

=cut

sub my_length {

	my ($self) = @_;
	if ( $big_streams_param->{_names_aref} ) {
		my $my_length =
		  ( scalar @{ $big_streams_param->{_names_aref} } ) * 2;
		return ($my_length);
	}
	else {

		print ("big_streams_param,my_length, empty names array reference\n");
	}

}

1;
