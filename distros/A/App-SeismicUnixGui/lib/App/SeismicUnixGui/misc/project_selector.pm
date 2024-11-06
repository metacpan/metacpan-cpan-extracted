package App::SeismicUnixGui::misc::project_selector;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME:  project_selector
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 3, 2018
 VERSION:   1.0.1

 DESCRIPTION Package containing methods
 and objects for managing the 
 project on which user works
     

 BASED ON:
  
     
=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 

=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '1.0.1';
use Tk;

use aliased 'App::SeismicUnixGui::misc::param_widgets';
use aliased 'App::SeismicUnixGui::misc::L_SU_local_user_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use aliased 'App::SeismicUnixGui::misc::manage_dirs_by';

my $param_widgets = param_widgets->new();

=head2 Instantiate
new modules

=cut

my $Project        = Project_config->new();
my $user_constants = L_SU_local_user_constants->new();
my $get            = L_SU_global_constants->new();

my $false = 0;
my $true  = 1;

=head2  private hash

=cut

my $project_selector = {
	_create_new           => $false,
	_create_new_button_w  => '',
	_active_project       => '',
	_first_idx            => 0,
	_labels_aref          => '',
	_length               => '',
	_labels_w_aref        => '',
	_message_box_w        => '',
	_current_program_name => '',
	_values_aref          => '',
	_values_w_aref        => '',
	_check_buttons_w_aref => '',
	_max_index            => '',
	_project_names_aref   => '',
	_PROJECT_HOMES_aref   => '',
	_mw                   => '',
	_param_widgets_pkg    => '',
	_widget               => '',
};

=head2 define

lcoal variables

=cut

=head2 sub _continue
 
=cut

sub _continue {
	my ($self) = @_;

#	print("project_selector, _continue\n");
	my $mw = $project_selector->{_mw};
	$mw->destroy() if Tk::Exists($mw);
	exit(1);
}

=head2 sub _cancel
 
=cut

sub _cancel {
	my ($self) = @_;

	# print("project_selector, _cancel\n");
	my $mw = $project_selector->{_mw};
	$mw->destroy() if Tk::Exists($mw);
	exit(1);
}

=head2 sub cancel
 
=cut

sub cancel {
	my ( $self, $value ) = @_;
	if ($value) {
		_cancel();

		#		print("project_select,cancel,value: $value\n");
	}
	else {
		print("project_select,cancel,error, value: $value\n");
	}
	return ();
}

=head2 sub _create_new

	derives from L_SU.pl
	The following widget references MUST exist already
	These references are set in the main that calls this package:

	$project_selector	->set_check_buttons_w_aref($L_SU_project_selector->{_check_buttons_w_aref});
	$project_selector	->set_labels_w_aref($L_SU_project_selector->{_labels_w_aref});
	$project_selector	->set_values_w_aref($L_SU_project_selector->{_values_w_aref});
	
	The current subroutine must set the length, and the first index
	so it is best to keep it at the end of the package after "set_length and set_fist_index"

=cut

sub _create_new {
	my ($self) = @_;

	my $config_superflows = config_superflows->new();

	if (    length( $project_selector->{_current_program_name} )
		and length( $project_selector->{_param_widgets_pkg} ) )
	{

		my $name              = $project_selector->{_current_program_name};
		my $param_widgets_pkg = $project_selector->{_param_widgets_pkg};

#		print("project_selector,_create_new, name =$name (is Project by default)\n");

=pod private hash
 	
=cut

		my $message_box_w    = _get_message_box_w();
		my $message_director = message_director->new();

		$message_box_w->delete( "1.0", 'end' );

		my $project = {
			_prog_name_sref              => \$name,
			_names_aref                  => '',
			_values_aref                 => '',
			_check_buttons_settings_aref => '',
			_is_superflow                => $true, # needed for param_widgets.pm
			_superflow_first_idx         => '',
			_superflow_length            => '',
		};

		_set_length();
		_set_first_idx();

		# first clean the current gui parameter and values in the window
		my $length = $project_selector->{_length};
		$param_widgets_pkg->set_first_idx;
		$param_widgets_pkg->set_length($length);
		$param_widgets_pkg->gui_full_clear;

		# get values names and checkbuttons from a
		# default the Project.config file

		$config_superflows->set_program_name( $project->{_prog_name_sref} )
		  ;    # really sref
			   # parameter names from superflow configuration file
		$project->{_names_aref} = $config_superflows->get_names();

		# parameter values from superflow configuration file
		$project->{_values_aref} = $config_superflows->get_values();

		#		print(
		#			"project_selector,_create_new,values=@{$project->{_values_aref}}\n"
		#		);

		$project->{_check_buttons_settings_aref} =
		  $config_superflows->get_check_buttons_settings();

#		print(
#"project_selector,_create_new,chkb=@{$project->{_check_buttons_settings_aref}}\n"
#		);

		$project->{_superflow_first_idx} = $config_superflows->first_idx();
		$project->{_superflow_length}    = $config_superflows->length();

		# assign the new parameter names and values to the widgets in the gui
		$param_widgets_pkg->range($project);
		$param_widgets_pkg->set_labels( $project->{_names_aref} );
		$param_widgets_pkg->set_values( $project->{_values_aref} );
		$param_widgets_pkg->set_check_buttons(
			$project->{_check_buttons_settings_aref} );

		# update the length
		$param_widgets_pkg->set_length( $project->{_superflows_length} );
		$param_widgets_pkg->redisplay_labels();
		$param_widgets_pkg->redisplay_values();
		$param_widgets_pkg->redisplay_check_buttons();

	}
	else {
		print("project_select,_create_new, variables are missing n");
	}
	return ();
}

=head2 sub _get_labels_from_gui

Extract labels from the user screen
The user may have modified the labels
TODO not working

=cut

sub _get_labels_from_gui {

	my ($self) = @_;
	my $result = ();

	$project_selector->{_max_index} = $Project->get_max_index();

	if (    length $project_selector->{_labels_w_aref}
		and length $project_selector->{_max_index} )
	{

		my @labels_w = @{ $project_selector->{_labels_w_aref} };
		my $length   = $project_selector->{_max_index} + 1;
		my @labels;

		for ( my $i = 0 ; $i < $length ; $i++ ) {

			$labels[$i] = $labels_w[$i]->get();
		}

		print("project_selector, _get_labels_from_gui, @labels\n");

		if ( scalar @labels ) {    # not 0!

			$project_selector->{_labels_aref} = \@labels;
			$result = $project_selector->{_labels_aref};

		}
		else {
			print("project_selector, _get_labels_from_gui, labels missing\n");

		}

	}
	else {
		print("project_selector, _get_labels_from_gui, missing items\n");
		print("label widgets:, $project_selector->{_labels_w_aref}\n");
		print("max_index:, $project_selector->{_max_index}\n");
	}

	return ($result);
}

=head2 _get_message_box_w

=cut

sub _get_message_box_w {
	my ($self) = @_;

	if ( $project_selector->{_message_box_w} ) {

		return ( $project_selector->{_message_box_w} );

	}
	else {
		print("project_select,_get_message_box_w missing \n");
	}

}

=head2 sub _get_project_names_aref
 Find simple Project names rom configuration path for user

=cut

sub _get_project_names_aref {

	my ($self) = @_;

	my @ls_ref;
	my $ls_ref = $user_constants->get_project_names;

	# print("project_selector, project names: @$ls_ref\n");
	my $length = scalar @$ls_ref;
	return ($ls_ref);
}

=head2 sub _get_values_from_gui

Extract labels from the user screen
The user may have modified the labels

=cut

sub _get_values_from_gui {

	my ($self) = @_;
	my $result = ();

	$project_selector->{_max_index} = $Project->get_max_index();

	if (    length $project_selector->{_values_w_aref}
		and length $project_selector->{_max_index} )
	{

		my @values_w = @{ $project_selector->{_values_w_aref} };
		my $length   = $project_selector->{_max_index} + 1;
		my @values;

		for ( my $i = 0 ; $i < $length ; $i++ ) {

			$values[$i] = $values_w[$i]->get();
		}

		#		print("project_selector, _get_values_from_gui, @values\n");

		if ( scalar @values ) {    # not 0!

			$project_selector->{_values_aref} = \@values;
			$result = $project_selector->{_values_aref};

		}
		else {
			print("project_selector, _get_values_from_gui, values missing\n");

		}

	}
	else {
		print("project_selector, _get_values_from_gui, missing items\n");
		print("label widgets:, $project_selector->{_values_w_aref}\n");
		print("max_index:, $project_selector->{_max_index}\n");
	}

	return ($result);
}

=head2 sub _ok

	Save a configuration file and a project
	Create all the directories

For the case that a project that already exists 
chosen:

     raise alarm if more than one project is checked
     overwrite the current project configuration file 
     with the one belonging to the newly selected
     active project

For the case that a new project is created:
 	create a new folder:
 		/home/username/configuration/New Project/
 		and make a copy of the Project.config inside:
 		/home/username/configuration/New Project/Project.config
 	Also copy the Project.config to the active directory as:
 	   /home/username/configuration/active/Project.config
 	   
 	TODO: Run the new configuration file so that the directories
 	are created
 	   
 
=cut  

sub _ok {
	my ($self) = @_;

	# expect messaging
	my $message_director = message_director->new();
	my $message_box_w    = _get_message_box_w();
	my $global_libs      = $get->global_libs();
	my $run_name         = $get->var->{_project_selector};

	# 1. CASES when an existing project is selected
	# active_project default is true
	if ( $project_selector->{_active_project} ) {

		# extra security
#		print(
#			"CASE 1. project_select,_ok, active project already exists-Good\n");

		my $param_widgets_pkg = $project_selector->{_param_widgets_pkg};
		my $length_check_buttons_on =
		  $param_widgets_pkg->get_length_check_buttons_on();

#		print(
#"project_selector,_ok, length_check_buttons_on: $length_check_buttons_on\n"
#		);

		# CASE 1.A More than one button is selected
		if ( $length_check_buttons_on > 1 ) {    # possible mistake by user

#			print(
#"CASE 1A: project_selector,_ok, >1 length_check_buttons_on: $length_check_buttons_on\n"
#			);
#			print(
#"project_selector,_ok, length_check_buttons_on: $length_check_buttons_on\n"
#			);
			$message_box_w->delete( "1.0", 'end' );
			my $message = $message_director->project_selector(0)
			  ;    # only one button can be chosen
			$message_box_w->insert( 'end', $message );

		}

		# CASE 1.B no buttons are selected ('on')
		elsif ( $length_check_buttons_on == 0 )
		{    # implies that no projects exist

			my $list_ref = $user_constants->get_project_names();
			my $length   = scalar @$list_ref;

			if ( $length == 0 ) {

				# i.e. no project names exist is confirmed
#				print(
#"CASE 1.B :project_selector,_ok, length_project names $length\n"
#				);

				$message_box_w->delete( "1.0", 'end' );
				my $message = $message_director->project_selector(2);
				;    # Create New or select old project
				$message_box_w->insert( 'end', $message );

			}
		}

		# CASE 1.C  an existing project is chosen
		elsif ( $length_check_buttons_on == 1 ) {

#			print(
#"CASE 1.C: project_selector,_ok, length_check_buttons_on: $length_check_buttons_on\n"
#			);
			use File::Copy;
			my $CONFIGURATION  = $user_constants->get_CONFIGURATION;
			my $ACTIVE_PROJECT = $user_constants->get_ACTIVE_PROJECT;
			my $active_indices_aref =
			  $param_widgets_pkg->get_index_check_buttons_on();

	 #		 # print(" project_selector,_ok,active_index: @$active_indices_aref\n");

			my @active_indices = @$active_indices_aref;
			my $active_index   = $active_indices[0];

			#			print(" project_selector,_ok,active_index: $active_index\n");
			# print(" project_selector,_ok,message widget: $message_box_w\n");

			# get the label of the active index
			my @labels = @{ $param_widgets_pkg->get_labels_aref() };
			my $new_active_Project_name = $labels[$active_index];

# print(" project_selector,_ok,active label/project name is: $labels[$active_index]\n");

			# copy the .Project.config file to the active directory
			my $from =
				$CONFIGURATION . '/'
			  . $new_active_Project_name
			  . '/Project.config';
			my $to = $ACTIVE_PROJECT . '/Project.config';

			copy( $from, $to );

	  # Instruction to create the new directories runs in system
#	  print("project_selector,_ok,create new Project and its directories \n");
	  #	  print("project_selector,_ok,copy FROM:$from TO:$to \n");

   #		    print("project_selector,_ok, sh $global_libs->{_script}$run_name \n");
   #			system("sh $global_libs->{_script}$run_name");

#      print("project_selector,_ok,copying new active project configuration file \n FROM:$from TO:$to");
# kill LSU_project_selector exit with 1
			_continue();

		}
		else {
			print(
"project_selector,_ok,length_check_buttons_on, unexpected $length_check_buttons_on\n"
			);
		}
	}

	# CASES 2 and 3 for NEWLY created Project Configuration File and New Project
	elsif ( $project_selector->{_create_new} ) {

		use File::Copy;

#		print("CASES 2 A,B,C project_select,_ok, New project creation \n");

		# save the new .Project configure to
		# /home/username/configuration/active

		my $config_superflows = config_superflows->new();
		my $param_widgets_pkg = $project_selector->{_param_widgets_pkg};

		my $project = {
			_names_aref         => '',
			_values_aref        => '',
			_check_buttons_aref => '',
			_prog_name_sref     => '',
		};

		# from an existant project, default or active
		$project->{_names_aref}  = $param_widgets_pkg->get_labels_aref();
		$project->{_values_aref} = $param_widgets_pkg->get_values_aref();

		my $default_name = $project_selector->{_current_program_name};
		$project->{_prog_name_sref} = \$default_name;

		# get a possible new project name defined by the user
		# TODO, next line not working
		#  my $labels_aref = _get_labels_from_gui();

		my $values_aref          = _get_values_from_gui();
		$project->{_values_aref} = $values_aref;

		# get the new project name to create, from the GUI
		my @values           = @$values_aref;
		my $pathNProject     = $values[1];
		my @parts            = split( '/', $pathNProject );
		my $new_project_name = $parts[3];

#		print("project_selector,_ok, pathNProject=$pathNProject\n");
		# print("project_selector,_ok, labels @{$project->{_labels_aref}}\n");
		# print("project_selector,_ok, values @{$project->{_values_aref}}\n");

        # saves the configuration file ONLY to 
        # ./L_SU/configuration/active/Project.config
		$config_superflows->save($project);

		# only after previous save
		my $active_project_name = $user_constants->get_active_project_name();

		#		print(
		#			"project_selector,_ok, active_project_name $active_project_name \n"
		#		);
		my $CONFIGURATION   = $user_constants->get_CONFIGURATION();
		my $DEFAULT_PROJECT = $CONFIGURATION . '/' . $active_project_name;
		my $ACTIVE_PROJECT  = $user_constants->get_ACTIVE_PROJECT();

		# creates new directory plus its own configuration file
		# make sure project does not already exist
		$user_constants->set_PROJECT_name($active_project_name);
		my $DEFAULT_PROJECT_exists = $user_constants->get_PROJECT_exists();

		if ( not $DEFAULT_PROJECT_exists ) {

			# CASE 2.A First-time creation of
			# a project for user.
			# No prior projects exist
			# if new project does not already exist
			# it is ok to create a new configuration directory and
			# file for the new project

			manage_dirs_by->make_dir($DEFAULT_PROJECT);

# update active project to lates changed Entry widget values in the project_selector GUI
			my $FROM_project_config =
			  $ACTIVE_PROJECT . '/' . $default_name . '.config';
			$user_constants->set_user_configuration_Project_config();

			my $TO_project_config =
			  $DEFAULT_PROJECT . '/' . $default_name . '.config';

#			print(
#"project_selector,_ok, CASE 2A of new project copying from $FROM_project_config to $TO_project_config\n"
#			);
			copy( $FROM_project_config, $TO_project_config );

	# Instruction to create the new directories runs in system
	#			print("project_selector,_ok,create new Project and its directories \n");
			system("sh $global_libs->{_script}$run_name");

			# kill windows but exit with 1
			_continue();

		}
		elsif ( $DEFAULT_PROJECT_exists
			and $project->{_prog_name_sref} ne $new_project_name )
		{

			# But old default project.config exists
			manage_dirs_by->make_dir($DEFAULT_PROJECT);

			# Also update active project to latest
			# changed Entry widget values in the project_selector GUI

			my $FROM_project_config =
			  $ACTIVE_PROJECT . '/' . $default_name . '.config';
			$user_constants->set_user_configuration_Project_config();

			# Note the new project name
			my $TO_project_config =
			  $DEFAULT_PROJECT . '/' . $new_project_name . '.config';

#			print(
#"project_selector,_ok, CASE 2B of new project copying from $FROM_project_config to $TO_project_config\n"
#			);
			copy( $FROM_project_config, $TO_project_config );

	# Instruction to create the new directories runs in system
	#			print("project_selector,_ok,create new Project and its directories \n");
			system("sh $global_libs->{_script}$run_name");

			# kill windows but exit with 1
			_continue();

			print("project_selector,_ok, kill windows but exit with 1 \n");

		}
		else {
			# CASE 2C new project seems to already exist

			$message_box_w->delete( "1.0", 'end' );
			my $message =
			  $message_director->project_selector(1);   # project already exists
			$message_box_w->insert( 'end', $message );

			print(
"project_selector,_ok, CASE 2C A project with that name exists already. Try again \n"
			);
		}
	}
	else {
		print(
"project_selector,_ok, CASE 3  project with that name exists already. NADA \n"
		);

		#			 kill windows but exit with 1
		#			_continue();
		#
		#			print("project_selector,_ok, kill windows but exit with 1 \n");

	}

	return ();
}

=head2 sub _set_gui

	show project 
	names, and their paths
	taken from user configuration file
	$param_widgets_pkg must previously exist
	
	Using default labels and values from
	a previous ("default")Project configuration
	If there is an active project the "default"
	is the active one.
	
=cut

sub _set_gui {
	my ($self) = @_;

	# print("project_selector,_set_gui\n");
	_set_length();
	_set_project_names_aref();
	_set_PROJECT_HOMES_aref();

	my $param_widgets_pkg = $project_selector->{_param_widgets_pkg};

	#	print(" project_selector,param_widgets_pkg: $param_widgets_pkg\n");

	if ($param_widgets_pkg) {
		my $project_names_aref = $project_selector->{_project_names_aref};
		my $PROJECT_HOMES_aref = $project_selector->{_PROJECT_HOMES_aref};

		$param_widgets_pkg->set_labels($project_names_aref);
		$param_widgets_pkg->redisplay_labels();

	# print("labels are @{$project_names_aref}\n"); # only part of array is full

		$param_widgets_pkg->set_values($PROJECT_HOMES_aref);
		$param_widgets_pkg->redisplay_values();

# print("project_selector,PROJECT HOMES are @$PROJECT_HOMES_aref\n");# only part of array is full

		if ( $project_selector->{_length} == 0 ) {    # no project name
			my @check_buttons = ('off');
			$param_widgets_pkg->set_check_buttons( \@check_buttons );
			$param_widgets_pkg->redisplay_check_buttons;

		}
		elsif ( $project_selector->{_length} == 1 ) {    # only one project name
			my @check_buttons = ('on');
			$param_widgets_pkg->set_check_buttons( \@check_buttons );
			$param_widgets_pkg->redisplay_check_buttons;

		}
		elsif ( $project_selector->{_length} > 1 )
		{    # more than one project name

			my $length = $project_selector->{_length};
			my @check_buttons;

			# find out which is the most recently active by interpreting
			# second line of L_SU/configuration/active/Project.config

			my $active_project_name =
			  $user_constants->get_active_project_name();

# print("project_selector,_set_gui,active_project_name = $active_project_name\n");

			# TODO turn on the currently active project
			# turn off all buttons

			for ( my $i = 0 ; $i < $length ; $i++ ) {
				$check_buttons[$i] = 'off';
			}

			# turn on button with matching label -- extra security
			my $default_labels_aref = $param_widgets_pkg->get_labels_aref();
			my @default_labels      = @$default_labels_aref;

			for ( my $i = 0 ; $i < $length ; $i++ ) {

				if ( $default_labels[$i] eq $active_project_name ) {
					$check_buttons[$i] = 'on';

	  # print("project_selector,_set_gui i=$i,active project match chkn ON \n");

				}
				else {
					$check_buttons[$i] = 'off';

 # print("project_selector,_set_gui,i=$i, NO active project match chkn OFF \n");
				}
			}

# print("project_selector,_set_gui,default_labels: @$default_labels_aref n");  # most default_label spaces are empty

			$param_widgets_pkg->set_check_buttons( \@check_buttons );
			$param_widgets_pkg->redisplay_check_buttons;

		}
		else {
			print("project_selector, _set_gui, lost logic\n");
			return ();
		}

	}
	else {
		print(
"project_selector,_set_gui, param_widgets_pkg must be first created\n"
		);
		return ();
	}
}

sub _set_start_of_create_new {
	my ($self) = @_;

	$project_selector->{_create_new}     = 1;
	$project_selector->{_active_project} = 0;

	my $create_new_button_w = $project_selector->{_create_new_button_w};
	$create_new_button_w->configure( -state => 'disable' );

	return ();

}

=head2 sub _set_length

From HOME directory and configuration path for user
estimate the number of projects available

=cut

sub _set_first_idx {

	my ($self) = @_;
	$project_selector->{_first_idx} = 0;

 # print("project_selector, _set_first_idx: $project_selector->{_first_idx}\n");
	return ();
}

=head2 sub _set_length

From HOME directory and configuration path for user
estimate the number of projects available

=cut

sub _set_length {

	my ($self) = @_;

	my @ls_ref;
	my $ls_ref = $user_constants->get_project_names;

	# print("project_selector, _set_length project names: @$ls_ref\n");
	my $length = scalar @$ls_ref;
	$project_selector->{_length} = $length;

	# print("project_selector, _set_length no. projects: $length\n");

	return ();
}

=head2 sub _set_PROJECT_HOMES_aref
 
 Find out HOME directory from configuration
 directories of user

=cut

sub _set_PROJECT_HOMES_aref {

	my ($self) = @_;

	my @ls_aref;
	my $ls_aref = $user_constants->get_PROJECT_HOMES_aref;

	# print("project_selector, _set_PROJECT_HOMES: @$ls_aref\n");
	$project_selector->{_PROJECT_HOMES_aref} = $ls_aref;
	return ();
}

=head2 sub create_new

new current settings

=cut

sub create_new {
	my ( $self, $value ) = @_;

	#	print("project_selector,create_new,value: $value\n");

	if ($value) {
		_create_new();
		_set_start_of_create_new();

	}
	else {
		# print("project_selector,save,error, value: $value\n");
	}
	return ();
}

=head2 sub ok

continue
 
=cut  

sub ok {
	my ( $self, $value ) = @_;

	#	print("project_selector,ok,value: $value\n");

	if ($value) {

		#		print("project_selector,ok,value: $value\n");
		_ok();

	}
	else {
		print("project_selector,ok,error, value: $value\n");
	}

	return ();
}

=head2 sub set_check_buttons_w_aref


=cut

sub set_check_buttons_w_aref {
	my ( $self, $check_buttons_w_aref ) = @_;

	if ($check_buttons_w_aref) {

		$project_selector->{_check_buttons_w_aref} = my $check_buttons_w_aref;

	}
	else {
		print(
"project_selector, set_check_buttons_w_aref,missing check_buttons_w_aref \n"
		);
	}
	return ();
}

=head2 sub set_create_new_button_w


=cut

sub set_create_new_button_w {

	my ( $self, $create_new_button_w ) = @_;

	if ($create_new_button_w) {

		$project_selector->{_create_new_button_w} = $create_new_button_w;

	}
	else {
		print("project_selector, set_,missing  create_new_button_w \n");
	}
	return ();
}

=head2 sub set_gui

	Always carried out when main LSU_project_selector begins
 
=cut

sub set_gui {
	my ($self) = @_;

	# print("project_selector, set_gui\n");
	_set_gui();
	return ();
}

=head2 sub set_hash_ref

Transfer hash of variables from the main program
#$L_SU_project_selector->{_labels_w_aref} 			= $param_widgets	-> get_labels_w_aref();
#$L_SU_project_selector->{_check_buttons_w_aref} 	= $param_widgets	-> get_check_buttons_w_aref();
#print($hash-ref->{_});

=cut

sub set_hash_ref {

	my ( $self, $hash_ref ) = @_;

	if ( length $hash_ref ) {

		$project_selector = $hash_ref;

	}
	else {
		print("project_selector,set_hash_ref, no hash-ref detecred\n");
	}
	return ();
}

=head2 sub set_labels_frame

 a widget reference

=cut

sub set_labels_frame {
	my ( $self, $label ) = @_;

	print("my label-$label\n");

}

=head2 set_labels_w_aref

=cut

sub set_labels_w_aref {
	my ( $self, $labels_w_aref ) = @_;

	if ( length $labels_w_aref ) {

		$project_selector->{_labels_w_aref} = my $labels_w_aref;
		print(
"project_selector,set_labels_w_aref: $project_selector->{_labels_w_aref} \n"
		);
	}
	else {
		print("project_selector,set_labels_w_aref, missing labels_w_aref \n");
	}
	return ();
}

=head2 sub set_length

 Find out HOME directory and configuration path for user

=cut

sub set_length {

	my ($self) = @_;

	my @ls_ref;
	my $ls_ref = $user_constants->get_project_names;

	# print("project_selector, project names: @$ls_ref\n");
	my $length = scalar @$ls_ref;
	$project_selector->{_length} = $length;

	# print("project_selector, no. projects: $length\n");

	return ();
}

=head2 set_message_box_w

=cut

sub set_message_box_w {
	my ( $self, $widget_ref ) = @_;

	if ($widget_ref) {

		$project_selector->{_message_box_w} = $widget_ref;

	}
	else {
		print("project_selector, set_message_box_w, no message box widget\n");
	}

	return ();
}

=head2 sub set_mw

main window widget

=cut

sub set_mw {
	my ( $self, $mw ) = @_;

	if ($mw) {

		$project_selector->{_mw} = my $mw;

	}
	else {
		# print("project_selector, set_mw,missing check_buttons_w_aref \n");
	}
	return ();
}

=head2 sub set_param_widgets_pkg

get project names from
user configuration directory

=cut

sub set_param_widgets_pkg {
	my ( $self, $pkg_ref ) = @_;

	if ( length $pkg_ref ) {

		$project_selector->{_param_widgets_pkg} = $pkg_ref;

#		print("project_selector, set_param_widgets_pkg: $project_selector->{_param_widgets_pkg}\n");

	}
	else {
		print("project_selector, no package reference\n");
	}
	return ();
}

=head2 sub set_current_program_name

set project names from
user configuration directory

=cut

sub set_current_program_name {
	my ( $self, $current_program_name ) = @_;

	if (    length($current_program_name)
		and length( $project_selector->{_param_widgets_pkg} ) )
	{

		$project_selector->{_current_program_name} = $current_program_name;
		( $project_selector->{_param_widgets_pkg} )
		  ->set_current_program_name($current_program_name);

#		 print("project_selector, set_current_program_name: $current_program_name\n");

	}
	else {
		print(
"project_selector, set_current_program_name: missing name or package \n"
		);
	}
	return ();
}

=head2 sub _set_project_names_aref

gset project names from
user configuration directory

=cut

sub _set_project_names_aref {
	my ($self) = @_;

	my $project_names_aref = _get_project_names_aref();
	$project_selector->{_project_names_aref} = $project_names_aref;

 # print("project_selector, _set_project_names_aref: @{$project_names_aref}\n");
	return ();
}

#=head2 set_values_w_aref
#
#=cut

#sub set_values_w_aref {
#	my ( $self, $values_w_aref ) = @_;
#
#	if ($values_w_aref) {
#
#		my $project_selector->{_values_w_aref} = $values_w_aref;
#
#	}
#	else {
#		print("project_selector,set_values_w_aref, missing values_w_aref \n");
#	}
#	return ();
#}

#=head2 sub set_value_w_aref
#
#
#=cut
#
#sub set_value_w_aref{
#	my ( $self, $widget ) = @_;
#
#	if ( length($widget) ) {
#
#		$project_selector->{_value_w_aref} = $widget;
#
#		print("project_selector, set_value_w_aref=$widget\n");
#
#	}
#	else {
#		print("project_selector, set_widget,missing widget \n");
#	}
#	return ();
#}

1;
