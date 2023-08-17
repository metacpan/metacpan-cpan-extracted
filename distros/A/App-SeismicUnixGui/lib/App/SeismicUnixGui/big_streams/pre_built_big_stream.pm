package App::SeismicUnixGui::big_streams::pre_built_big_stream;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: pre_built_big_stream
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 19 2018 

 DESCRIPTION 
     
 BASED ON:
 previous versions of the main L_SU.pm V0.1.1
  
=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
 During refactoring of 2017 V 0.1.0 L_SU.pl

=cut

use Moose;
our $VERSION = '0.1.0';

extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::gui_history';
my $pre_built_big_stream_href_sub_ref;    # $pre_built_big_stream_href->{_sub_ref} does not transfer in namespace between subs
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_local_user_constants';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::whereami';
use aliased 'App::SeismicUnixGui::misc::param_widgets4pre_built_streams';
use aliased 'App::SeismicUnixGui::misc::binding';
use aliased 'App::SeismicUnixGui::misc::name';
use aliased 'App::SeismicUnixGui::misc::config_superflows';

=head2 Instantiation

=cut

my $get 					  = L_SU_global_constants->new();
my $param_widgets 	          = param_widgets4pre_built_streams->new();
my $whereami      			  = whereami->new();
my $gui_history  			  = gui_history->new();
my $pre_built_big_stream_href = $gui_history->get_defaults();


=head2

 share the following parameters in same name 
 space

=cut

my $message_w;
my ($values_aref,$names_aref,$check_buttons_settings_aref);

=head2 sub get_hash_ref

	return ALL values of the private hash, supposedly
	important external widgets have not been reset ... only conditions
	are reset
	TODO: perhaps it is better to have a specific method
		to return one specific widget address at a time?
	}	
		foreach my $key (sort keys %$pre_built_big_stream_href) {
         print (" pre_built_big_stream,key is $key, value is $pre_built_big_stream_href->{$key}\n");
      }
	
	104
	 
=cut

sub get_hash_ref {
    my ($self) = @_;

    if ($pre_built_big_stream_href) {
        # print("pre_built_big_stream, get_hash_ref ,values_aref=@{$values_aref}\n");
        # print("pre_built_big_stream, get_hash_ref ,check_buttons_settings_aref=@{$check_buttons_settings_aref}\n");

        return ($pre_built_big_stream_href);

    }
    else {
        print("superflow, get_hash_ref , missing superflow hash_ref\n");
    }
}

=head2 sub set_flowNsuperflow_name_w

=cut

sub set_flowNsuperflow_name_w {

    my ( $self, $flowNsuperflow_name_w ) = @_;

    if ($flowNsuperflow_name_w) {

        $pre_built_big_stream_href->{_flowNsuperflow_name_w} = $flowNsuperflow_name_w;

        if ( $pre_built_big_stream_href->{_prog_name_sref} ) {    # previously loaded

            my $flowNsuperflow_name = ${ $pre_built_big_stream_href->{_prog_name_sref} };
            $flowNsuperflow_name_w->configure( -text => $flowNsuperflow_name, );
        }
        else {
            print( "pre_built_big_stream, set_flowNsuperflow_name_w, missing widget name\n" );
        }

    }
    else {
        print( "pre_built_big_stream, set_flowNsuperflow_name_w, missing program name\n" );
    }

    return ();
}


=head2 sub select

 Chosen big stream
 displays the parameter names and their values
 but does not write them to a file
   	
 foreach my $key (sort keys %$pre_built_big_stream_href) {
         print (" pre_built_big_stream,key is $key, value is $pre_built_big_stream_href->{$key}\n");
 }
 
=cut

sub select {
    my ($self) = @_;

    my $binding            				= binding->new();
    my $name               				= name->new();
    my $pre_built_big_stream_messages 	= message_director->new();
    my $config_superflows  				= config_superflows->new();
    my $Project            				= 'Project';

    my $prog_name_sref = $pre_built_big_stream_href->{_prog_name_sref};

    # print("1. pre_built_big_stream,select,prog=${$pre_built_big_stream_href->{_prog_name_sref}}\n");
    my $message = $pre_built_big_stream_messages->null_button(0);

    # print("pre_built_big_stream,select,message_w:$pre_built_big_stream_href->{_message_w}\n");
    $message_w->delete( "1.0", 'end' );
    $message_w->insert( 'end', $message );

    # print("1. pre_built_big_stream,select,should be NO values=@{$pre_built_big_stream_href->{_values_aref}}\n");
    # local location within GUI
    # gui_history->set_gui_widgets($pre_built_big_stream_href);  
    gui_history->set_hash_ref($pre_built_big_stream_href); 
    gui_history->set4start_of_superflow_select(); 
    $pre_built_big_stream_href = gui_history->get_hash_ref(); 

    # print("pre_built_big_stream,select,_is_pre_built_big_stream: $pre_built_big_stream_href->{_is_pre_built_superflow}\n");
    # print("pre_built_big_stream,select,_flow_type: $pre_built_big_stream_href->{_flow_type}\n");
    # set location in gui
    $whereami->set4superflow_select_button();

    # print("1. pre_built_big_stream,_is_superflow_select_button,$pre_built_big_stream_href->{_is_superflow_select_button}\n");
    $config_superflows->set_program_name($prog_name_sref); 
    $config_superflows->set_prog_name_config($prog_name_sref); 
    my $prog_name_config = $config_superflows->get_prog_name_config(); 

    # case for Project.config
    if ( $prog_name_config eq $Project . '.config' ) {

        my $user_constants = L_SU_local_user_constants->new();

        if ( $user_constants->user_configuration_Project_config_exists() ) {
            # read active configuration file

        }
        elsif ( not $user_constants->user_configuration_Project_config_exists ) {

            # need to tell the user that they have to go back and create a Project
            my $message = $pre_built_big_stream_messages->superflow(0);
            $pre_built_big_stream_href->{_message_w}->delete( "1.0", 'end' );
            $pre_built_big_stream_href->{_message_w}->insert( 'end', $message );

            # print("pre_built_big_stream,superflow_select,prog_name_config = $prog_name_config\n");

        }
        else {
            print("pre_built_big_stream,superflow_select, bad file name\n");
        }
    }
    else {
    	 # Case for any OTHER big stream
        $config_superflows->inbound();
        $config_superflows->check2read();
    }

    # parameter names from superflow configuration file
    $pre_built_big_stream_href->{_names_aref} = $config_superflows->get_names();

    # print("pre_built_big_stream,superflow_select,parameter labels=@{$pre_built_big_stream_href->{_names_aref}}\n");

    # parameter values from superflow configuration file
    $pre_built_big_stream_href->{_values_aref} = $config_superflows->get_values();

    # print("2. pre_built_big_stream,select,values=@{$pre_built_big_stream_href->{_values_aref}}\n");
    # print("3. pre_built_big_stream,_is_superflow_select,$pre_built_big_stream_href->{_is_superflow_select_button}\n");

    $pre_built_big_stream_href->{_check_buttons_settings_aref} = $config_superflows->get_check_buttons_settings();

    # print("1 pre_built_big_stream,superflow_select,chkb=@{$pre_built_big_stream_href->{_check_buttons_settings_aref}}\n");

    $pre_built_big_stream_href->{_superflow_first_idx} = $config_superflows->first_idx();
    $pre_built_big_stream_href->{_superflow_length}    = $config_superflows->length();

    # print("4. pre_built_big_stream,_is_superflow_select,$pre_built_big_stream_href->{_is_superflow_select_button}\n");
    # Blank out all the widget parameter names and their values
    # print("3. pre_built_big_stream,select,values=@{$pre_built_big_stream_href->{_values_aref}}\n");
    # print("3. pre_built_big_stream,length,values=@{$pre_built_big_stream_href->{_values_aref}}\n");
    # print("pre_built_big_stream,length = maximum default! $pre_built_big_stream_href->{_superflow_length}\n");
    my $here = $whereami->get4superflow_select_button();
    
    # widgets were initialized in a super class
    #$param_widgets		->set_labels_w_aref($pre_built_big_stream_href->{_labels_w_aref} );
    #$param_widgets		->set_values_w_aref($pre_built_big_stream_href->{_values_w_aref} );
    #$param_widgets		->set_check_buttons_w_aref($pre_built_big_stream_href->{_check_buttons_w_aref} );
    # print("5. pre_built_big_stream,_is_superflow_select,$pre_built_big_stream_href->{_is_superflow_select_button}\n");
    $param_widgets->gui_full_clear();

    # print("6. pre_built_big_stream,_is_superflow_select_button,$pre_built_big_stream_href->{_is_superflow_select_button}\n");
    $param_widgets->range($pre_built_big_stream_href);
    $param_widgets->set_labels( $pre_built_big_stream_href->{_names_aref} );
    $param_widgets->set_values( $pre_built_big_stream_href->{_values_aref} );
    $param_widgets->set_check_buttons( $pre_built_big_stream_href->{_check_buttons_settings_aref} );
    $param_widgets->set_current_program($prog_name_sref);

    $param_widgets->redisplay_labels();
    $param_widgets->redisplay_values();
    $param_widgets->redisplay_check_buttons();

    # print("2 pre_built_big_stream,superflow_select,chkb=@{$pre_built_big_stream_href->{_check_buttons_settings_aref}}\n");
    # put focus on first entry widget in new value and paramter list
    my @Entry_widget = @{ $param_widgets->get_values_w_aref() };

    # print("L_SU,flow_select,Entry_widgets@Entry_widget\n");
    $Entry_widget[0]->focus;

    # print("3 pre_built_big_stream,superflow_select,chkb=@{$pre_built_big_stream_href->{_check_buttons_settings_aref}}\n");
    # Here is where you rebind the different buttons depending on the
    # program name that is selected (i.e. through *_spec.pm)
    # send superflow names through an alias filter
    # that links their GUI name to their program name
    # e.g. iVelAnalysis (GUI) is actually IVA.pm (shortened)

    my $run_name = $name->get_alias_superflow_names($prog_name_sref);

    # print("pre_built_big_stream,select,run_name: $run_name\n");

    $binding->set_prog_name_sref( \$run_name );
    $binding->set_values_w_aref( $param_widgets->get_values_w_aref );

    # print("pre_built_big_stream, select sub_ref: $pre_built_big_stream_href_sub_ref\n");
    $binding->setFileDialog_button_sub_ref($pre_built_big_stream_href_sub_ref);
    $binding->set();

    # print("4 pre_built_big_stream,superflow_select,chkb=@{$pre_built_big_stream_href->{_check_buttons_settings_aref}}\n");

    # in order to export this private hash we need to send if back via a private variable
    # values_aref that will be assigned in pre_built_big_stream, get_hash_ref.
    $values_aref = $pre_built_big_stream_href->{_values_aref};

    # print("4. pre_built_big_stream,select,values=@{$pre_built_big_stream_href->{_values_aref}}\n");

    # gui_history->set_gui_widgets($pre_built_big_stream_href);
    gui_history->set_hash_ref($pre_built_big_stream_href);
    gui_history->set4end_of_superflow_select();
    $pre_built_big_stream_href = gui_history->get_hash_ref();     
    # print("6. pre_built_big_stream,_is_superflow_select,$pre_built_big_stream_href->{_is_superflow_select_button}\n");

    # for export via get_hash_ref
    # $pre_built_big_stream_href_first_idx  	 			= $config_superflows->first_idx();
    # $pre_built_big_stream_href_length  	     			= $config_superflows->length();
    $names_aref                  = $pre_built_big_stream_href->{_names_aref};
    $values_aref                 = $pre_built_big_stream_href->{_values_aref};
    $check_buttons_settings_aref = $pre_built_big_stream_href->{_check_buttons_settings_aref};

    # print("5 pre_built_big_stream,superflow_select,chkb=@{$pre_built_big_stream_href->{_check_buttons_settings_aref}}\n");
    # print("5 pre_built_big_stream,superflow_select,values=@{$pre_built_big_stream_href->{_values_aref}}\n");

}


=cut


=head2 sub set_hash_ref 

	imports external hash into private settings
	print(" pre_built_big_stream,set_hash_refderefed _prog_name_sref: ${$pre_built_big_stream_href->{_prog_name_sref}}\n");	 	 	 
 
  78 off, 78 off
  new variables are created with abbreviated names out of convenience
  
=cut

sub set_hash_ref {

    my ( $self, $hash_ref ) = @_;
	
	$gui_history->set_defaults($hash_ref);
	$pre_built_big_stream_href = $gui_history->get_defaults();
	
	# set up param_widgets for later use
	# give param_widgets the needed values
	$param_widgets->set_hash_ref($pre_built_big_stream_href);
	$message_w     = $pre_built_big_stream_href->{_message_w};
	

    return ();
}

=head2 sub set_name_sref
  is this sub needed?
  $pre_built_big_stream_href->{_prog_name_sref} can also be imported via
  set_hash_ref if the calling module has set the program name previously
 
=cut

sub set_name_sref {
    my ( $self, $prog_name_sref ) = @_;

    if ($prog_name_sref) {
        $pre_built_big_stream_href->{_prog_name_sref} = $prog_name_sref;

        # print("pre_built_big_stream, set_name_sref, $$prog_name_sref\n");

    }
    else {
        print("pre_built_big_stream, set_name_sref, missing name\n");
    }
    return ();
}
=head2
 
 The $pre_built_big_stream_href->{_sub_ref} is collected but
and transferred from the current namespace 
into the selected subroutine in the superclass

=cut

sub set_sub_ref {
    my ( $self, $sub_ref ) = @_;

    if (length $sub_ref) {

        # $pre_built_big_stream_href->{_sub_ref} = $sub_ref; does not transfer to other subroutine within
        # in the namespace ???
        $pre_built_big_stream_href_sub_ref = $sub_ref;

       #  print("pre_built_big_stream, set_sub_ref, sub_ref: $pre_built_big_stream_href_sub_ref \n");
    }
    else {
        print("pre_built_big_stream, set_sub_ref, missing sub ref\n");
    }

    return ();
}

1;
