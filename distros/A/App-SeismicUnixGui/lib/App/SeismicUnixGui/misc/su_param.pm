package App::SeismicUnixGui::misc::su_param;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: su_param 
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 5 2018 

 DESCRIPTION V 0.2
     

 BASED ON: 0.1


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

=head2 Instantiation

=cut

my $L_SU_global_constants = L_SU_global_constants->new();
my $L_SU_path             = L_SU_path->new();

my $HOME = ` echo \$HOME`;
chomp $HOME;

# magic number TODO
my $var                      = $L_SU_global_constants->var();
my $ACTIVE_PROJECT           = $HOME . $var->{_ACTIVE_PROJECT};
my $user_active_project_path = $ACTIVE_PROJECT;

my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

my $flow_type_href = $L_SU_global_constants->flow_type_href();

my $su_param = {
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

		$su_param->{_flow_type} = $flow_type;

	   # print("su_param,  set_flow_type ,flow_type=$su_param->{_flow_type}\n");

	}
	else {
		print("su_param,  set_flow_type , missing value\n");
	}

	return ();
}

sub _get_global_lib {

	my ($elf) = @_;

	my $global_libs_href = $L_SU_global_constants->global_libs();

	if (   defined $global_libs_href
		&& $global_libs_href ne $empty_string
		&& defined $su_param->{_flow_type} )
	{

		my $result;

		if (
			$su_param->{_flow_type} eq $flow_type_href->{_pre_built_superflow} )
		{

			$su_param->{_lib_path} = $global_libs_href->{_param};

		# print("su_param, _get_global_lib,lib_path= $su_param->{_lib_path}\n");
			$result = $su_param->{_lib_path};
			return ($result);

		}
		elsif ( $su_param->{_flow_type} eq $flow_type_href->{_user_built} ) {

			$su_param->{_lib_path} = $global_libs_href->{_param};

	   # print("su_param, _get_global_lib, lib_path: $su_param->{_lib_path}\n");
			$result = $su_param->{_lib_path};
			return ($result);

		}
		else {
			print("su_param, _get_global_lib, unexpected value\n");
			return ();
		}

	}
	else {
		print("su_param, _get_global_lib, missing value\n");
	}

	return ();

}

sub _set_sub_category_directory {

	my ($sub_category_directory) = @_;

	if ( defined $sub_category_directory
		&& $sub_category_directory ne $empty_string )
	{

		$su_param->{_sub_category_directory} = $sub_category_directory;

	}
	else {
		print("su_param, _set_sub_category_directory, missing value\n");
		print(
			"su_param, _set_sub_category_directory, $sub_category_directory\n");
	}

	return ();
}

sub _set_path {

	my ($path) = @_;

	if ( length $path
		&& $path ne $empty_string )
	{

		$su_param->{_path} = $path;

		#		print("su_param, _set_path, path=$path\n");

	}
	else {
		print("su_param, _set_path, missing value\n");
	}

	return ();
}

sub _set_program_sref {

	my ($program_sref) = @_;

	if ( defined $$program_sref
		&& $$program_sref ne $empty_string )
	{

		$su_param->{_program_sref} = $program_sref;

	}
	else {
		print("su_param, _set_program_config, missing value\n");
	}

	return ();
}

sub _get_program_config {

	my ($path) = @_;

	my ( $program_config, $sub_category_directory, $program_sref );

	$path                   = $su_param->{_path};
	$sub_category_directory = $su_param->{_sub_category_directory};
	$program_sref           = $su_param->{_program_sref};

#	print("su_param, get_program_config, path = $path\n");
#	print(
#"su_param, get_program_config, sub_category_directory = $sub_category_directory\n"
#	);
#	print("su_param, get_program_config, program_sref= $$program_sref\n");

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

		$su_param->{_program_config} = $program_config;
		my $result = $program_config;
		return ($result);

	}
	else {
		print("su_param, _set_program_config, missing value\n");
		return ();
	}

}

=head2 sub get

  returns values
  as an array
  input is a scalar reference
  used both by superflow/pre-built flows and seismic unix configuration files
  
 Read a default specification file 
 If default specification file# does not exist locally
 then look in the user's configuration directory
 ~HOME/.L_SU/configuration/active and if that does not exist
 then use the default one defined under global libs

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
		&& ( defined $su_param->{_flow_type} )
		&& ( $su_param->{_flow_type} ne $empty_string ) )
	{

		my (@CFG);
		my ( $length, $names_aref, $values_aref );
		my ( $i, $j, $program_config, $path );
		my $sub_category_directory;

		my $read      = readfiles->new();
		my $developer = developer->new();

		$developer->set_program_name($$program_sref);
		$developer->set_flow_type( $su_param->{_flow_type} );
		_set_program_sref($program_sref);

		# reset the following tests to 0 (false)
		my $local_config_exists = _check4local_config($program_sref);
		my $user_active_project_path_exists = _check4user_config($program_sref);

#		print("B. su_param, get, local_config_exists: $local_config_exists\n");
#		print(
#"C. su_param, get,user_active_project_path_exists: $user_active_project_path_exists\n"
#		);

		if (
			$su_param->{_flow_type} eq $flow_type_href->{_pre_built_superflow} )
		{

			if ($local_config_exists) {

				use Module::Refresh;    # reload updated module
				my $refresher = Module::Refresh->new;

				# CASE 1A: If progam_sref = a pre-built superflow
				# e.g., tools like Sseg2su.config
				# but not with Project.config

			  #				my $module_spec    = $$program_sref . '_spec';
			  #				my $module_spec_pm = $module_spec . '.pm';
			  #
			  #				$L_SU_global_constants->set_file_name($module_spec_pm);
			  #				my $spec_path = $L_SU_global_constants->get_path4spec_file();
			  #				my $pathNmodule_pm = $spec_path . '/' . $module_spec_pm;

				$L_SU_path->set_program_name($$program_sref);

				my $pathNmodule_spec_w_slash_pm =
				  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
				my $pathNmodule_spec_w_colon =
				  $L_SU_path->get_pathNmodule_spec_w_colon();
				$refresher->refresh_module($pathNmodule_spec_w_slash_pm);

				# INSTANTIATE
				my $package = $pathNmodule_spec_w_colon->new();

				#	my $package = $module_spec->new;

				# collect specifications of output directory
				# from a program_spec.pm module
				my $specs_h = $package->variables();
				my $CONFIG  = $specs_h->{_CONFIG};

				$su_param->{_local_path} = $CONFIG;
				$path                    = $su_param->{_local_path};
				$sub_category_directory  = '.';
				my $local_path = $su_param->{_local_path};
				my $sub_category_directory =
				  $developer->get_program_sub_category();

   # print("1.1 su_param,get,local configuration files exists\n");
   # print("1.2 su_param,get,local_path:$CONFIG \n");
   # print("1.3 su_param,get,sub_category_directory=$sub_category_directory\n");

			}
			elsif ($user_active_project_path_exists) {

			   # su_param, missing either program_sref CASE 1B:
			   # If progam_sref= Project
			   # and ONLY applies to  ./L_SU/configuration/active/Project.config
				$path = $su_param->{_user_active_project_path};
				$sub_category_directory = '.';

#				print("CASE 1B su_param,get,user_active_project_path_exists= $user_active_project_path_exists\n");
#				print("1B su_param,get,active path is now $su_param->{_user_active_project_path} \n");

			}
			elsif ( not $local_config_exists ) {

				# CASE 1C: for  previously unused pre-built superflow
				$path = _get_global_lib();
				$sub_category_directory =
				  $developer->get_program_sub_category();

				#				print("1C su_param,get,using global lib: path is $path\n");
			}

		}
		elsif ( $su_param->{_flow_type} eq $flow_type_href->{_user_built} ) {

			# CASE 2A: for use of sunix programs in user_built_flows
			$path = _get_global_lib();

#			print("CASE 2.A su_param,get,using global lib: path for sunix programs is $path\n");
			$sub_category_directory = $developer->get_program_sub_category();

#			print("2.A su_param,get,using sub_category_directory:  for sunix programs is $sub_category_directory\n");

		}
		else {
			print("su_param,get,unexpected\n");

		}

		# share local variables with the package namespace
		_set_path($path);
		_set_sub_category_directory($sub_category_directory);

		$program_config = _get_program_config();

		#		print("su_param, get,configuration file to read=$program_config\n");

		( $names_aref, $values_aref ) = $read->configs($program_config);
		$su_param->{_names_aref} = $names_aref;
		$length = scalar @$names_aref;

#		print("su_param,get:we have $length pairs\n\n");
		for ( $i = 0, $j = 0 ; $i < $length ; $i++, $j = $j + 2 ) {

			$CFG[$j] = $$names_aref[$i];
			$CFG[ ( $j + 1 ) ] = $$values_aref[$i];

			#			print("su_param,get,values:--$CFG[$j+1]--\n");
		}

		return ( \@CFG );

	}
	else {
		print("su_param, missing either program_sref or flow type\n");
		print("program_sref: $program_sref\n");
		print("su_param->{_flow_type}: $su_param->{_flow_type}\n");
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
		#      	print (" su_param,_check4local_config, , key is $key, value is $a->{$key}\n");
		#	}
		#		my $ans= $a->{_CONFIG};
		#		print("2. su_param,_check4local_config,package=$ans\n");

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
		  
		 # 	print("1. su_param,_get_suffix_aref, prog_name: $pathNmodule_spec_w_slash_pm\n");
		 #	 	print("1. _get_suffix_aref, prog_name: $colon_pathNmodule_spec\n");

		if ( length $pathNmodule_spec_w_slash_pm ) {

			require $pathNmodule_spec_w_slash_pm;

			#		INSTANTIATE
			my $package = $pathNmodule_spec_w_colon->new();

			# collect specifications of output directory
			# from a program_spec.pm module
			my $specs_h = $package->variables();
			my $CONFIG  = $specs_h->{_CONFIG};

			#			print("3. su_param,_check4local_config, CONFIG=$CONFIG \n");
			my $prog_name_config = $CONFIG . '/' . $$name_sref . '.config';

		   #			print(
		   #"su_param,_check4local_config,prog_name_config =$prog_name_config\n"
		   #			);
			if ( -e ($prog_name_config) ) {

#				print(
#"su_param,_check4local_config,found: $prog_name_config. Using local configuration file\n"
#				);
				$ans = $true;

			}
			else {
				$ans = $false;

		  # print("su_param,_check4local_config, $prog_name_config not found\n")
			}
		}    # module is found
	}
	else {
		print("su_param,_check4local_config, missing name_sref \n");
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
#				"su_param,_check4user_config, ACTIVE_PROJECT=$ACTIVE_PROJECT\n"
#			);
#			print("su_param,_check4user_config, name =$$name_sref\n");
#			print(
#				"su_param,_check4user_config,$$name_sref not found. \n
# 				Going forward will use default (GLOBAL LIBS) configuration file\n"
#			);
#			print(
#"su_param,_check4user_config,$$name_sref.config found, Using user configuration file\n"
#			);
#			print("su_param,_check4user_config=$ans\n");
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

# print("su_param,check4user_config,$$name_sref.config found, Using user configuration file\n");
# print("su_param,check4user_config=$ans\n");
		}
		else {
			$ans = $false;

# print("su_param,check4user_config,$$name_sref not found. Using default (GLOBAL LIBS) configuration file\n")
		}
	}
	return ($ans);
}

=head2 sub my_length 
not found
 This length is twice the number of parameter
  names
  print("su_param,length: is $length\n");

=cut

sub my_length {

	my ($self) = @_;
	if ( $su_param->{_names_aref} ) {
		my $my_length = ( scalar @{ $su_param->{_names_aref} } ) * 2;
		return ($my_length);
	}
	else {

		# print ("su_param,my_length, empty names array reference\n");
	}

}

1;
