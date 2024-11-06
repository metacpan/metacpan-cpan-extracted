package App::SeismicUnixGui::misc::L_SU_local_user_constants;

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::dirs';
use aliased 'App::SeismicUnixGui::misc::big_streams_param';
use aliased 'App::SeismicUnixGui::misc::manage_dirs_by';

my $L_SU_global_constants = L_SU_global_constants->new();

=head2 private hash

=cut

my $L_SU = {
	_ACTIVE_PROJECT                     => '',
	_default_Project_config             => '',
	_user_configuration_Project_config  => '',
	_user_configuration_Project_config2 => '',
	_config_base_name                   => 'Project',
	_PROJECT                            => '',
	_default_project_name               => 'Servilleta',
};

=head2 definitions

=cut

sub get_home {
	my ($self) = @_;
	my $home_directory;

	use Shell qw(echo);

	$home_directory = ` echo \$HOME`;
	chomp $home_directory;

	my $HOME = $home_directory;

	return ($HOME);

}

sub _get_home {
	my ($self) = @_;
	my $home_directory;

	use Shell qw(echo);

	$home_directory = ` echo \$HOME`;
	chomp $home_directory;

	my $HOME = $home_directory;

	return ($HOME);

}

sub _get_PROJECT {
	my ($self) = @_;
	my $PROJECT = $L_SU->{_PROJECT};

	if ($PROJECT) {
		return ($PROJECT);
	}
	else {
#		print("L_SU_local_user_constants,_get_PROJECT, no PROJECT defined\n");
		return ();
	}
}

sub get_PROJECT {
	my ($self) = @_;
	my $PROJECT = $L_SU->{_PROJECT};

	if ($PROJECT) {
		return ($PROJECT);
	}
	else {
		print("L_SU_local_user_constants,_get_PROJECT, no PROJECT defined\n");
		return ();
	}
}

sub _get_CONFIGURATION {
	my ($self) = @_;
	my $CONFIGURATION;

	my $HOME = _get_home;

	$CONFIGURATION = $HOME . '/.L_SU/configuration';

	return ($CONFIGURATION);

}

sub get_CONFIGURATION {
	my ($self) = @_;
	my $CONFIGURATION;

	my $HOME = _get_home;

	$CONFIGURATION = $HOME . '/.L_SU/configuration';

	return ($CONFIGURATION);

}

sub set_PROJECT_name {
	my ( $self, $PROJECT_name ) = @_;
	my $PROJECT;

	my $HOME = _get_home;

	$PROJECT = $HOME . '/.L_SU/' . 'configuration' . '/' . $PROJECT_name;
	$L_SU->{_PROJECT} = $PROJECT;
	return ();

}

sub get_PROJECT_HOMES_aref {
	my ($self) = @_;
	my @PROJECT_HOMES;

	my $HOME               = _get_home;
	my $project_names_aref = _get_project_names();
	my @project_names      = @$project_names_aref;
	my $length             = scalar @project_names;

	for ( my $i = 0 ; $i < $length ; $i++ ) {

		$PROJECT_HOMES[$i] = $HOME . '/' . $project_names[$i];
	}
	return ( \@PROJECT_HOMES );
}

sub _get_default_Project_config {
	my ($self) = @_;
	my $default_Project_config;
	$default_Project_config = $L_SU->{_default_Project_config};

	return ($default_Project_config);
}

sub _get_config_name_new {
	my $self          = @_;
	my $prog_name_new = 'Project';

	return ($prog_name_new);
}

sub get_config_name_new {
	my $self          = @_;
	my $prog_name_new = 'Project';

	return ($prog_name_new);
}

# TODO remove the following and substitute
# with the previous that makes more sense
# Project.config is the generic project configuration file
sub get_prog_name_new {
	my $self          = @_;
	my $prog_name_new = 'Project';

	return ($prog_name_new);
}

sub _get_user_configuration_Project_config {
	my ($self) = @_;

	my $user_configuration_Project_config =
	  $L_SU->{_user_configuration_Project_config};

# print("L_SU_local_user_constants,_get_user_configuration_Project_config, user_configuration_Project_config: $user_configuration_Project_config\n");

	return ($user_configuration_Project_config);
}

sub get_user_configuration_Project_config {
	my ($self) = @_;

	my $user_configuration_Project_config =
	  $L_SU->{_user_configuration_Project_config};

# print("L_SU_local_user_constants,get_user_configuration_Project_config, user_configuration_Project_config: $user_configuration_Project_config\n");

	return ($user_configuration_Project_config);
}

sub _get_user_configuration_Project_config2 {
	my ($self) = @_;

	if ( $L_SU->{_user_configuration_Project_config2} ) {

		my $user_configuration_Project_config2 =
		  $L_SU->{_user_configuration_Project_config2};
		print(
"L_SU_local_user_constants,_get_user_configuration_Project_config2, user_configuration_Project_config2: $user_configuration_Project_config2\n"
		);

		return ($user_configuration_Project_config2);

	}
	else {
		print(
"L_SU_local_user_constants,_get_user_configuration_Project_config, missing user_configuration_Project_config2\n"
		);
	}
}

sub get_user_configuration_Project_config2 {
	my ($self) = @_;

	if ( $L_SU->{_user_configuration_Project_config2} ) {

		my $user_configuration_Project_config2 =
		  $L_SU->{_user_configuration_Project_config2};

# print("L_SU_local_user_constants,_get_user_configuration_Project_config2, user_configuration_Project_config2: $user_configuration_Project_config\n");
		return ($user_configuration_Project_config2);

	}
	else {
		print(
"L_SU_local_user_constants,_get_user_configuration_Project_config, missing user_configuration_Project_config2\n"
		);
	}

}

sub get_Project_config {
	my ($self) = @_;

	my $Project_config = 'Project.config';
	return ($Project_config);
}

sub _get_Project_config {
	my ($self) = @_;

	my $Project_config = 'Project.config';
	return ($Project_config);
}

=head2 sub _get_ACTIVE_PROJECT{

upper case ACTIVE_PROJECT 
PATH to the defatul Project.config

=cut

sub _get_ACTIVE_PROJECT {
	my ($self) = @_;
	my $ACTIVE_PROJECT;

	my $HOME = _get_home();

	$ACTIVE_PROJECT = $HOME . '/.L_SU/configuration/active';
	return ($ACTIVE_PROJECT);
}

=head2 sub get_ACTIVE_PROJECT{

upper case ACTIVE_PROJECT 
PATH to the default Project.config

=cut

sub get_ACTIVE_PROJECT {
	my ($self) = @_;
	my $ACTIVE_PROJECT;

	my $HOME = _get_home();

	$ACTIVE_PROJECT = $HOME . '/.L_SU/configuration/active';
	return ($ACTIVE_PROJECT);
}

=head2 sub get_active_project_name 

lower case active project is the project name
but must have a _name as suffix get_ACTIVE_PROJECT
because Perl does not distinguish between upper and lower-
case cases.
Get the project name from the Project.config file
within the active-project dirctory:

   .L_SU/configuration/active/Project.config

=cut

sub get_active_project_name {
	my ($self) = @_;

	# default config file is 'Project'
	my $project_name = $L_SU->{_config_base_name};

#    print("L295 L_SU_local_user_constants,get_active_project,project_name=$project_name\n");
#    L_SU_local_user_constants->set_program_name( \$project_name );

	my $namesNvalues_aref = _get_local_or_defaults($project_name);
	my @namesNvalues_aref = @$namesNvalues_aref;

#print("L_SU_local_user_constants,get_active_project,namesNvalues_aref: @$namesNvalues_aref\n");

	my $ACTIVE_PROJECT_name = $namesNvalues_aref[3];

# print("1. L_SU_local_user_constants,get_active_project,name:$ACTIVE_PROJECT_name\n");
# matches last word after last "/"
# last element of array is the active project name
	my @words = split /\//, $ACTIVE_PROJECT_name;

   # print("1. L_SU_local_user_constants,get_active_project,name:$words[-1]\n");
	my $active_project_name = $words[-1];

	#remove any quote if it exists
	$active_project_name =~ s/'//;

	return ($active_project_name);
}

=head2 sub _get_local_or_defaults

 via big_streams_param:
 
 Read a default specification file 
 1) If default specification file# does not exist locally (PL_SEISMIC)
 2) then check the user's configuration area: .LSU/configuration/active/Project.config
 and if not,
 3) then use the default one defined under global libs


 Debug with
    print ("self is $self,program is $program_name\n");
 print("params are @$ref_CFG\n");
 program name is a hash
    print("params are @$ref_cfg\n");
    print ("self is $self,program is $program_name\n");
       print("L_SU_local_user_constants,_get_local_or_defaults,program_name:$$program_name_sref\n"); 
       print("L_SU_local_user_constants,_get_local_or_defaults,program_name:$$name_sref\n"); 
       print("L_SU_local_user_constants,_get_local_or_defaults,program_name:$$program_name_sref\n"); 
    print("L_SU_local_user_constants,_get_local_or_defaults, length:$L_SU_local_user_constants->{_length}\n");

=cut

sub _get_local_or_defaults {
	my ($config_base_name) = @_;

#	print("L_SU_local_user_constants, _get_local_or_defaults,program name=$config_base_name\n");

	if ( length $config_base_name ) {

		my $big_streams_param = big_streams_param->new();

		my $flow_type =
		  $L_SU_global_constants->flow_type_href->{_pre_built_superflow};
		$big_streams_param->set_flow_type($flow_type);

		my ( $cfg_aref, $size );

		my $name_sref = \$config_base_name;

#	print("L359 L_SU_local_user_constants, _get_local_or_defaults,program name=$$name_sref\n");
#	print("L359 L_SU_local_user_constants, _get_local_or_defaults,flow_type=$flow_type\n");
#	print("L_SU_local_user_constants, _get_local_or_defaults,SCALAR program name=$name_sref\n");

		$cfg_aref = $big_streams_param->get($name_sref);

#  		print("L_SU_local_user_constants, _get_local_or_defaults,cfg_aref = @{$cfg_aref}\n");
		return ($cfg_aref);
	}
	else {
		print(
"L_SU_local_user_constants, L_SU_local_user_constants,missing program_name_sref\n"
		);
		return ();
	}

}

=head2 sub _get_active_project_name 

lower case active project is the project name
but must have a _name as suffix get_ACTIVE_PROJECT
because Perl does not distinguish between upper and lower
case cases.
Get the project name from the Project.config file
within the active-project dirctory:

   .L_SU/configuration/active/Project.config

=cut

sub _get_active_project_name {
	my ($self) = @_;

	# default config file is 'Project'
	my $project_name = $L_SU->{_config_base_name};

	#    L_SU_local_user_constants->set_program_name( \$project_name );

	my $namesNvalues_aref = _get_local_or_defaults($project_name);
	my @namesNvalues_aref = @$namesNvalues_aref;

# print("L_SU_local_user_constants,get_active_project,namesNvalues_aref: @$namesNvalues_aref\n");

	my $ACTIVE_PROJECT_name = $namesNvalues_aref[3];

# print("1. L_SU_local_user_constants,_get_active_project,name:$ACTIVE_PROJECT_name\n");
# matches last word after last "/"
# last element of array is the active project name
	my @words = split /\//, $ACTIVE_PROJECT_name;

  # print("1. L_SU_local_user_constants,_get_active_project,name:$words[-1]\n");
	my $active_project_name = $words[-1];

	#remove any quote if it exists
	$active_project_name =~ s/'//;

	return ($active_project_name);
}

sub _set_default_Project_config {
	my ($self) = @_;

	my $ACTIVE_PROJECT;
	my $global_lib        = $L_SU_global_constants->global_libs();
	my $GLOBAL_CONFIG_LIB = $global_lib->{_configs_big_streams};
	my $get               = $L_SU_global_constants->var();
	my $Project_config    = $get->{_Project_config};

	my $HOME = _get_home;

	my $inbound_Project_config       = $GLOBAL_CONFIG_LIB .'/'. $Project_config;
	$L_SU->{_default_Project_config} = $inbound_Project_config;

# print(" L_SU_local_user_constants,_set_default_Project_config,default_Project_config: $L_SU->{_default_Project_config} \n");

	return ();
}

=head2 sub get_ACTIVE PROJECT_exists

	does ACTIVE_PROJECT (path)
	exist
	
=cut

sub get_ACTIVE_PROJECT_exists {
	my ($self) = @_;

	my $false = 0;
	my $ans   = $false;
	my $true  = 1;

	my $ACTIVE_PROJECT = _get_ACTIVE_PROJECT();

   print("L_SU_local_user_constants,get_ACTIVE_PROJECT_exists,ACTIVE_PROJECT =$ACTIVE_PROJECT \n");
   # includes path
   
	if ( length $ACTIVE_PROJECT ) {

		if ( -d $ACTIVE_PROJECT ) {

			$ans = $true;
	        print("L_SU_local_user_constants,get_ACTIVE_PROJECT_exists,TRUE :$ans\n");

		}
		else {
			$ans = $false;
		  print("L_SU_local_user_constants,get_ACTIVE_PROJECT_exists,FALSE :$ans\n");
		  print("$ACTIVE_PROJECT does not exist\n");
		}
		return ($ans);

	}
	else {
		
      $ans = $false;
#	  print("L_SU_local_user_constants,get_PROJECT_exists,is an empty variable \n");
      return ($ans);
	}

}

=head2 sub get_PROJECT_exists

	tests  if a PROJECT (path)
	exists
	
=cut

sub get_PROJECT_exists {
	my ($self) = @_;

	my $false = 0;
	my $ans   = $false;
	my $true  = 1;

	my $PROJECT = _get_PROJECT();

#   print("L_SU_local_user_constants,get_PROJECT_exists,PROJECT =$PROJECT \n");
   # includes path
	if ( length $PROJECT ) {

		if ( -d $PROJECT ) {

			$ans = $true;
#	        print("L_SU_local_user_constants,get_PROJECT_exists,TRUE :$ans\n");

		}
		else {
			$ans = $false;
#		  print("L_SU_local_user_constants,get_PROJECT_exists,FALSE :$ans\n");
#		  print("$PROJECT does not exist\n");
		}
		return ($ans);

	}
	else {
		
      $ans = $false;
#	  print("L_SU_local_user_constants,get_PROJECT_exists,is an empty variable \n");
      return ($ans);
	}

}

=head2 sub _get_project_names

o/p array ref of list names

=cut

sub _get_project_names {
	  my ($self) = @_;

	  my @filtered;
	  my $i    = 0;
	  my $dirs = dirs->new();

	  my $HOME          = _get_home();
	  my $CONFIGURATION = $HOME . '/.L_SU/configuration';

# print ("LSU_local_user_constants,get_Project_names CONFIGURATION: $CONFIGURATION\n");
	  $dirs->set_dir($CONFIGURATION);
	  my $ls_ref = $dirs->get_ls;

	  foreach my $file (@$ls_ref) {

# exclude any files whose full name contains the string 'active' i.e., only one.
		  next if $file =~ /active/;

		  # print all other files
		  $filtered[$i] = $file;
		  $i++;
	  }

	  # print ("LSU_local_user_constants,get_Project_names @$ls_ref\n");
	  return ( \@filtered );
}

=head2 sub get_project_names

o/p array ref of list names

=cut

sub get_project_names {
	  my ($self) = @_;
	  my @filtered;
	  my $i    = 0;
	  my $dirs = dirs->new();

	  my $HOME          = _get_home();
	  my $CONFIGURATION = $HOME . '/.L_SU/configuration';

# print ("LSU_local_user_constants,get_project_names CONFIGURATION: $CONFIGURATION\n");
	  $dirs->set_dir($CONFIGURATION);
	  my $ls_ref = $dirs->get_ls;

	  foreach my $file (@$ls_ref) {

  # exclude any files whose full name contains the string 'active' i.e. only one
  # print("LSU_local_user_constants,get_project_names listing: $file  \n");
		  if ( !( $file =~ /active/ ) ) {

	  # print("LSU_local_user_constants,get_project_names filtered: $file  \n");
	  # print all other files
			  $filtered[$i] = $file;
			  $i++;
		}
	  }

	  # print ("1 L_SU_local_user_constants,get_project_names @filtered\n");
	  return ( \@filtered );
}

sub set_user_configuration_Project_config {
	  my $self = @_;

	  my $HOME           = _get_home;
	  my $ACTIVE_PROJECT = _get_ACTIVE_PROJECT;

	  my $user_configuration_Project_config =
		$ACTIVE_PROJECT . '/Project.config';
	  $L_SU->{_user_configuration_Project_config} =
		$user_configuration_Project_config;

# print("  L_SU_local_user_constants,_set_user_configuration_Project_config \n");
# print("	1 user_configuration_Project_config: $user_configuration_Project_config \n");
# print("	2 user_configuration_Project_config: $L_SU->{_user_configuration_Project_config}\n");

	  return ();
}

sub set_user_configuration_Project_config2 {
	  my $self = @_;

	  my $HOME          = _get_home;
	  my $CONFIGURATION = _get_CONFIGURATION;

	  my $project_name = _get_active_project_name();
	  my $user_configuration_Project_config2 =
		$CONFIGURATION . '/' . $project_name . '/Project.config';
	  $L_SU->{_user_configuration_Project_config2} =
		$user_configuration_Project_config2;

# print("  L_SU_local_user_constants, set_user_configuration_Project_config\n");
# print("	2 _user_configuration_Project_config2: $L_SU->{_user_configuration_Project_config2}\n");
# print("	2 active_project_name: $project_name\n");

	  return ();
}

sub _set_user_configuration_Project_config {
	  my $self = @_;

	  my $HOME           = _get_home;
	  my $ACTIVE_PROJECT = _get_ACTIVE_PROJECT;

	  my $user_configuration_Project_config =
		$ACTIVE_PROJECT . '/Project.config';
	  $L_SU->{_user_configuration_Project_config} =
		$user_configuration_Project_config;

# print("  L_SU_local_user_constants,_set_user_configuration_Project_config \n");
# print("	1 user_configuration_Project_config: $user_configuration_Project_config \n");
# print("	2 user_configuration_Project_config: $L_SU->{_user_configuration_Project_config}\n");

	  return ();
}

sub _set_user_configuration_Project_config2 {
	  my $self = @_;


	  my $HOME           = _get_home;
	  my $ACTIVE_PROJECT = _get_ACTIVE_PROJECT;

	  my $user_configuration_Project_config =
		$ACTIVE_PROJECT . '/Project.config';
	  $L_SU->{_user_configuration_Project_config} =
		$user_configuration_Project_config;

# print("  L_SU_local_user_constants,_set_user_configuration_Project_config \n");
# print("	1 user_configuration_Project_config: $user_configuration_Project_config \n");
# print("	2 user_configuration_Project_config: $L_SU->{_user_configuration_Project_config}\n");

	  return ();
}

=head2 sub makconfig

  make ALL configuration directories and files for
  the first time that L_SU is used
  

=cut

sub makconfig {

	  my ($self) = @_;
	  use File::Copy;

	  my $ACTIVE_PROJECT = _get_ACTIVE_PROJECT();
	  my $PATH_N_file = $ACTIVE_PROJECT . '/Project.config';

#    print("L_SU_local_user_constants,makconfig,PATH_N_file 	: $PATH_N_file\n");
	  _set_default_Project_config();
	  my $default_Project_config = _get_default_Project_config();

#    print(
#"L_SU_local_user_constants,makconfig, default_Project_config: $default_Project_config\n"
#    );
	  manage_dirs_by->make_dir($ACTIVE_PROJECT);
	  copy( $default_Project_config, $PATH_N_file );

#	  print("L_SU_local_user_constants,makconfig, created $PATH_N_file\n");

	  my $config_name_new = _get_config_name_new();
	  my $PATH_N_config_name =
		  $ACTIVE_PROJECT . '/'
		. $config_name_new
		. '.config';  # e.g., /home/username/.L_SU/configuration/active/Project.config

	  my $CONFIGURATION = _get_CONFIGURATION();

	  # REQUIRES /home/gom/.L_SU/configuration/active/Project.config
	  # reads internals of file Project.config
	  my $active_project_name = _get_active_project_name();
	  my $new_PATH            = $CONFIGURATION . '/'. $active_project_name;
	  my $new_PATH_N_file     = $new_PATH. '/'
	                         . $config_name_new
	                         . '.config';  
	  # e.g., /home/username/.L_SU/configuration/Servilleta/Project.config

#	  print("L_SU_local_user_constants, created ci=onfiguration $new_PATH_N_file\n");
	  manage_dirs_by->make_dir($new_PATH);
	  copy( $default_Project_config, $new_PATH_N_file );
#	  print("L_SU_local_user_constants, copied default Project.config to $new_PATH_N_file\n");
}

=head2 sub Project_config_exists

	tests  if a user configuration
	Project.config file exists
	i.e. should be found inside
	.L_SU/configuration/active
	
=cut

sub user_configuration_Project_config_exists {
	  my ($self) = @_;

	  my $false = 0;
	  my $ans   = $false;
	  my $true  = 1;
	  _set_user_configuration_Project_config();
	  my $Project_config = _get_user_configuration_Project_config();

	  # incldues path
	  if ( -e $Project_config ) {
		  $ans = $true;

# print("L_SU_local_user_constants,user_configuration_Project_config_exists,i.e., $Project_config exists\n");
	  }
	  else {
		  $ans = $false;
	  }
	  return ($ans);
}

1;
