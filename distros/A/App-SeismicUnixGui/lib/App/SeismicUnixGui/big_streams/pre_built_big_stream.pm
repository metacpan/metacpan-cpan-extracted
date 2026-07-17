package App::SeismicUnixGui::big_streams::pre_built_big_stream;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: pre_built_big_stream  
 AUTHOR: Juan Lorenzo  
 DATE: May 19, 2018  

 DESCRIPTION:  
 Handles setup and selection of predefined “big streams” in SeismicUnixGui.  

 BASED ON:  
 Previous versions of the main L_SU.pm (V0.1.1)

=cut

use Moose;
our $VERSION = '0.1.0';

extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };

use aliased 'App::SeismicUnixGui::misc::gui_history';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::L_SU_local_user_constants';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::whereami';
use aliased 'App::SeismicUnixGui::misc::param_widgets4pre_built_streams';
use aliased 'App::SeismicUnixGui::misc::binding';
use aliased 'App::SeismicUnixGui::misc::program_name';
use aliased 'App::SeismicUnixGui::misc::config_superflows';

#---------------------------------------------------------
# Instantiation
#---------------------------------------------------------

my $get                       = L_SU_global_constants->new();
my $param_widgets              = param_widgets4pre_built_streams->new();
my $whereami                   = whereami->new();
my $gui_history                = gui_history->new();
my $pre_built_big_stream_href  = $gui_history->get_defaults();
my $program_name               = program_name->new();
my $pre_built_big_stream_href_sub_ref;

#---------------------------------------------------------
# Shared parameters
#---------------------------------------------------------

my $message_w;
my ( $values_aref, $names_aref, $check_buttons_settings_aref );

#=========================================================
# Subroutines
#=========================================================

=head2 sub get_hash_ref

Return all values of the private hash reference.

=cut

sub get_hash_ref {
    my ($self) = @_;

    if ($pre_built_big_stream_href) {
        return $pre_built_big_stream_href;
    }
    else {
        print("superflow, get_hash_ref: missing superflow hash_ref\n");
    }
}


=head2 sub set_flowNsuperflow_name_w

Assigns a widget name for the current flow or superflow.

=cut

sub set_flowNsuperflow_name_w {
    my ( $self, $flowNsuperflow_name_w ) = @_;

    if ($flowNsuperflow_name_w) {
        $pre_built_big_stream_href->{_flowNsuperflow_name_w} = $flowNsuperflow_name_w;

        if ( $pre_built_big_stream_href->{_prog_name_sref} ) {
            my $flowNsuperflow_name = ${ $pre_built_big_stream_href->{_prog_name_sref} };
            $flowNsuperflow_name_w->configure( -text => $flowNsuperflow_name );
        }
        else {
            print("pre_built_big_stream: missing widget name\n");
        }
    }
    else {
        print("pre_built_big_stream: missing program name\n");
    }

    return ();
}


=head2 sub select

Choose and display a big stream configuration, including parameters and widgets.

=cut

sub select {
    my ($self) = @_;

    my $binding                    = binding->new();
    my $program_name               = program_name->new();
    my $msg_director               = message_director->new();
    my $config_superflows          = config_superflows->new();
    my $Project                    = 'Project';

    my $prog_name_sref             = $pre_built_big_stream_href->{_prog_name_sref};
    my $external_name              = $$prog_name_sref;

    # Convert GUI name into internal program name
    $program_name->set($external_name);
    my $internal_name = $program_name->get();
    $prog_name_sref   = \$internal_name;

    my $message = $msg_director->null_button(0);
    $message_w->delete( "1.0", 'end' );
    $message_w->insert( 'end', $message );

    # Prepare GUI history
    gui_history->set_hash_ref($pre_built_big_stream_href);
    gui_history->set4start_of_superflow_select();
    $pre_built_big_stream_href = gui_history->get_hash_ref();

    # Update GUI position and configuration
    $whereami->set4superflow_select_button();
    $config_superflows->set_program_name($prog_name_sref);
    $config_superflows->set_prog_name_config($prog_name_sref);
    my $prog_name_config = $config_superflows->get_prog_name_config();

    # Handle Project.config or other streams
    if ( $prog_name_config eq $Project . '.config' ) {
        my $user_constants = L_SU_local_user_constants->new();

        if ( $user_constants->user_configuration_Project_config_exists() ) {
            # Valid configuration exists
        }
        elsif ( not $user_constants->user_configuration_Project_config_exists ) {
            my $message = $msg_director->superflow(0);
            $pre_built_big_stream_href->{_message_w}->delete( "1.0", 'end' );
            $pre_built_big_stream_href->{_message_w}->insert( 'end', $message );
        }
        else {
            print("pre_built_big_stream: invalid Project.config file name\n");
        }
    }
    else {
        $config_superflows->inbound();
        $config_superflows->check2read();
    }

    # Get parameter data
    $pre_built_big_stream_href->{_names_aref}                = $config_superflows->get_names();
    $pre_built_big_stream_href->{_values_aref}               = $config_superflows->get_values();
    $pre_built_big_stream_href->{_check_buttons_settings_aref} = $config_superflows->get_check_buttons_settings();
    $pre_built_big_stream_href->{_superflow_first_idx}       = $config_superflows->first_idx();
    $pre_built_big_stream_href->{_superflow_length}          = $config_superflows->length();

    # GUI refresh
    $param_widgets->gui_full_clear();
    $param_widgets->range($pre_built_big_stream_href);
    $param_widgets->set_labels( $pre_built_big_stream_href->{_names_aref} );
    $param_widgets->set_values( $pre_built_big_stream_href->{_values_aref} );
    $param_widgets->set_check_buttons( $pre_built_big_stream_href->{_check_buttons_settings_aref} );
    $param_widgets->set_current_program($prog_name_sref);

    $param_widgets->redisplay_labels();
    $param_widgets->redisplay_values();
    $param_widgets->redisplay_check_buttons();

    # Focus on first entry field (no highlighting)
    my @Entry_widget = @{ $param_widgets->get_values_w_aref() };
    $Entry_widget[0]->focus;

    # Bind callbacks and actions
    my $run_name = $internal_name;
    $binding->set_prog_name_sref( \$run_name );
    $binding->set_values_w_aref( $param_widgets->get_values_w_aref );
    $binding->setFileDialog_button_sub_ref($pre_built_big_stream_href_sub_ref);
    $binding->set();

    # Update reference data for export
    $values_aref                 = $pre_built_big_stream_href->{_values_aref};
    gui_history->set_hash_ref($pre_built_big_stream_href);
    gui_history->set4end_of_superflow_select();
    $pre_built_big_stream_href   = gui_history->get_hash_ref();

    $names_aref                  = $pre_built_big_stream_href->{_names_aref};
    $values_aref                 = $pre_built_big_stream_href->{_values_aref};
    $check_buttons_settings_aref = $pre_built_big_stream_href->{_check_buttons_settings_aref};

    return ();
}


=head2 sub set_hash_ref

Imports an external hash reference into local scope and updates widget references.

=cut

sub set_hash_ref {
    my ( $self, $hash_ref ) = @_;

    $gui_history->set_defaults($hash_ref);
    $pre_built_big_stream_href = $gui_history->get_defaults();

    $param_widgets->set_hash_ref($pre_built_big_stream_href);
    $message_w = $pre_built_big_stream_href->{_message_w};

    return ();
}


=head2 sub set_name_sref

Optionally assigns a program name reference.

=cut

sub set_name_sref {
    my ( $self, $prog_name_sref ) = @_;

    if ($prog_name_sref) {
        $pre_built_big_stream_href->{_prog_name_sref} = $prog_name_sref;
    }
    else {
        print("pre_built_big_stream: missing program name\n");
    }

    return ();
}


=head2 sub set_sub_ref

Stores a subroutine reference for later binding within the namespace.

=cut

sub set_sub_ref {
    my ( $self, $sub_ref ) = @_;

    if ( length $sub_ref ) {
        $pre_built_big_stream_href_sub_ref = $sub_ref;
    }
    else {
        print("pre_built_big_stream: missing subroutine reference\n");
    }

    return ();
}

1;