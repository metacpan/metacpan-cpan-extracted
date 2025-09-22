=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: L_SU_ProjectSelector.pl 
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 1 2018 


DESCRIPTION 
     

 BASED ON:
 Version 1.0.1  May 1 2018  

=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '1.0.1';

use Tk;
use Tk::Pane;
use Tk::Font;

# potentially in all packages
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::param_widgets';
use aliased 'App::SeismicUnixGui::misc::project_selector';
use aliased 'App::SeismicUnixGui::messages::message_director';

my $project_selector = project_selector->new();
my $get              = L_SU_global_constants->new();
my $param_widgets    = param_widgets->new();
my $message_director = message_director->new();

# print("main,package param_widgets: $param_widgets\n");

my $var = $get->var();

=head2

 share the following parameters in same name 
 space

 flow_listbox_l  -left listbox, input by user selection
 flow_listbox_r  -right listbox,input by user selection
 sunix_listbox   -choice of listed sunix modules in a listbox

=cut

my ($mw);
my ( $i, $j, $k );
my ($work_frame);
my ( $buttons_frame, $parameters_pane );
my ($parameter_values_button_frame);
my ( $parameter_names_frame, $parameter_values_frame );
my ($ref_chk_button_variable);
my ( @labels_w, @entries_w );
my ($sunix);
my ( @param, @values, @args, @check_buttons, @labels );
my (@on_off_param);
my $false         = 0;
my $true          = 1;

=head2 Default Tk settings{

 Create scoped hash 

=cut

my $L_SU_project_selector = {
	_FileDialog_option    => '',
	_values_w_aref        => '',
	_labels_w_aref        => '',
	_check_buttons_w_aref => '',
	_mw                   => '',
	_active_project       => $true,
	_create_new_button    => '',
	_prog_name            => 'Project',
};

=head2 Main Window contains

 a top menu frame 
 a middle menu titles frame
 and a
 bottom  work_frame
 font is made to be arial normal 14
 border width is defaulted too

=cut

$mw = MainWindow->new;
$mw->geometry( $var->{project_selector_box_position} );
$mw->resizable( 0, 0 );    #not resizable in either width or height

#$mw->focusFollowsMouse;
$L_SU_project_selector->{_mw}                = $mw;
$L_SU_project_selector->{_param_widgets_pkg} = $param_widgets;

# print("main,package L_SU_project_selector->{_param_widgets}: $L_SU_project_selector->{_param_widgets_pkg}\n");

=head2 Define 
  
  fonts to use in the menu

=cut

$mw->configure( -title => $var->{_project_selector_title}, );

my $garamond = $mw->fontCreate(
	'garamond',
	-family => 'garamond',
	-weight => 'normal',
	-size   => -14
);

my $arial = $mw->fontCreate(
	'arial',
	-family => 'arial',
	-weight => 'normal',
	-size   => -14
);

my $small_garamond = $mw->fontCreate(
	'small_garamond',
	-family => 'garamond',
	-weight => 'normal',
	-size   => -9
);

my $small_arial = $mw->fontCreate(
	'small_arial',
	-family => 'arial',
	-weight => 'normal',
	-size   => -9
);

=head2 Define Work frames

Top frame contains message
Bottom frame contains a list, lables and buttons to choose

=cut

my $message_frame = $mw->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => 'blue',
	-relief      => 'groove'
);

$work_frame = $mw->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => 'yellow',
	-relief      => 'groove'
);

$buttons_frame = $mw->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => 'blue',
	-relief      => 'groove'
);

=head2
Buttons within bottom buttons_frame

=cut

my $save_button = $buttons_frame->Button(
	-text               => 'Create New',
	-font               => $arial,
	-height             => 1,
	-activebackground   => $var->{_my_yellow},
	-activeforeground   => $var->{_my_black},
	-foreground         => $var->{_my_white},
	-background         => $var->{_my_dark_grey},
	-disabledforeground => $var->{_my_white},
	-relief             => 'flat',
	-state              => 'normal',
	-command            => [ \&_project_selector, 'create_new', 1 ]
);
$L_SU_project_selector->{_create_new_button} = $save_button;

my $ok_button = $buttons_frame->Button(
	-text             => 'OK',
	-font             => $arial,
	-height           => 1,
	-activebackground => $var->{_my_yellow},
	-activeforeground => $var->{_my_black},
	-foreground       => $var->{_my_white},
	-background       => $var->{_my_dark_grey},
	-relief           => 'flat',
	-state            => 'normal',
	-command          => [ \&_project_selector, 'ok', 1 ],
);

my $cancel_button = $buttons_frame->Button(
	-text             => 'Cancel',
	-font             => $arial,
	-height           => 1,
	-activebackground => $var->{_my_yellow},
	-activeforeground => $var->{_my_black},
	-foreground       => $var->{_my_white},
	-background       => $var->{_my_dark_grey},
	-relief           => 'flat',
	-state            => 'normal',
	-command          => [ \&_project_selector, 'cancel', 1 ],
);

=head2 parameters frame
Contains name_values_frame at the top, 
and a message_frame at the bottom 

=cut

$parameters_pane = $work_frame->Scrolled(
	"Pane",
	-background => $var->{_light_grey},
	-relief     => 'groove',
	-scrollbars => "e",
	-sticky     => 'ns',
	-width      => 600,
	-height     => 280,
);

$parameter_names_frame = $parameters_pane->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => $var->{_light_grey},
	-relief      => 'groove',

);

#-width          => '1',

$parameter_values_button_frame = $parameters_pane->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => $var->{_light_grey},

	-relief => 'groove',
);

#-width          => '10',
$parameter_values_frame = $parameters_pane->Frame(
	-borderwidth => $var->{_one_pixel_borderwidth},
	-background  => $var->{_my_purple},

	-relief => 'groove',
);

#-width          => '200',

=head2 Initialize 

  Initially, checkbutton widgets and values 
  are green ("on") or red ("off"), and
  Labels and Entry Widgets are made blank.

=cut

$param_widgets->set_labels_frame( \$parameter_names_frame );
$param_widgets->set_values_frame( \$parameter_values_frame );
$param_widgets->set_check_buttons_frame( \$parameter_values_button_frame );
$param_widgets->initialize_labels();
$param_widgets->initialize_values();
$param_widgets->initialize_check_buttons();

# pack and show widgets
$param_widgets->show_labels();
$param_widgets->show_values();
$param_widgets->show_check_buttons();

=head2   	


=cut

=head2 message area 

      to notify user of important evets 

=cut

my $message_box = $message_frame->Text(
	-height     => 3,
	-font       => $arial,
	-foreground => $var->{_my_black},
	-background => $var->{_my_light_grey},
);
$L_SU_project_selector->{_message_box_w} = $message_box;
$message_box->delete( "1.0", 'end' );
my $message = $message_director->project_selector(2);    # only one button can be chosen
$message_box->insert( 'end', $message );
$L_SU_project_selector->{_message_box_w}->insert( 'end', "\n   \n" );

$message_frame->pack(
	-side => "top",
	-fill => 'x',
);

$work_frame->pack(
	-side => "top",
	-fill => "y",
);

$buttons_frame->pack(
	-side => "top",
	-fill => "y",
);
$message_box->pack(
	-side => "top",
	-fill => 'x',
);
$save_button->pack(
	-side => "left",
	-fill => 'x',
);
$ok_button->pack(
	-side => "left",
	-fill => 'x',
);
$cancel_button->pack(
	-side => "left",
	-fill => 'x',
);
$parameters_pane->pack(
	-side => "left",
	-fill => "y",
);
$parameter_names_frame->pack(
	-side => "left",
	-fill => "y",
);
$parameter_values_button_frame->pack(
	-side => "left",
	-fill => "y",
);
$parameter_values_frame->pack(
	-side => "top",
	-fill => "x",
);

# When the program first starts, the following is executed

# populate widgets IN PROJECT_SELECTOR MODULE
$L_SU_project_selector->{_values_w_aref}        = $param_widgets->get_values_w_aref();
$L_SU_project_selector->{_labels_w_aref}        = $param_widgets->get_labels_w_aref();
$L_SU_project_selector->{_check_buttons_w_aref} = $param_widgets->get_check_buttons_w_aref();

$project_selector->set_hash_ref($L_SU_project_selector);

# pass the package reference to another package
# MUST be called before the first gui is started (i.e., set_gui)
# TODO See if the following lines are included already in the hash transger
# a few lines above
$project_selector->set_param_widgets_pkg( $L_SU_project_selector->{_param_widgets_pkg} );
$project_selector->set_current_program_name( $L_SU_project_selector->{_prog_name} );
$project_selector->set_message_box_w( $L_SU_project_selector->{_message_box_w} );
$project_selector->set_create_new_button_w( $L_SU_project_selector->{_create_new_button} );

# FINALLY call the starting gui
# automatically populate gui if one or more projects exist
# otherwise the gui will be blank
$project_selector->set_gui();

MainLoop;

=head2 sub _project_selector

controls the following actions: 
-create a new project ( always possible: if projects >=0 )
-reset the active project ( always possible but only meaningful if # projects >1)
-cancel ( if projects >=0)

=cut

sub _project_selector {
	my ( $set_method, $value ) = @_;

	if ( length $set_method && length $value ) {
		
#		print("L_SU_project_selector,method:$set_method, value:$value\n");
		
		$project_selector->$set_method($value);
#		$project_selector->set_hash_ref($L_SU_project_selector);
        
	} else {
		print("_project_selector,no method: $set_method error 1,\n");
	}

	return ();
}
