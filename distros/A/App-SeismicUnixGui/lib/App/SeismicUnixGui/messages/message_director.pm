package App::SeismicUnixGui::messages::message_director;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::messages::FileDialog_button_messages';
use aliased 'App::SeismicUnixGui::messages::FileDialog_close_messages';
use aliased 'App::SeismicUnixGui::messages::color_listbox_messages';
use aliased 'App::SeismicUnixGui::messages::help_button_messages';
use aliased 'App::SeismicUnixGui::misc::save_button_messages';
use aliased 'App::SeismicUnixGui::messages::flows_messages';
use aliased 'App::SeismicUnixGui::messages::immodpg_messages';
use aliased 'App::SeismicUnixGui::messages::iPick_messages';
use aliased 'App::SeismicUnixGui::messages::run_button_messages';
use aliased 'App::SeismicUnixGui::messages::null_messages';
use aliased 'App::SeismicUnixGui::messages::project_selector_messages';
use aliased 'App::SeismicUnixGui::messages::superflow_messages';

my $flows             = flows_messages->new();
my $FileDialog_button = FileDialog_button_messages->new();
my $FileDialog_close  = FileDialog_button_messages->new();
my $help_button       = help_button_messages->new();
my $run_button        = run_button_messages->new();
my $save_button       = save_button_messages->new();
my $superflow         = superflow_messages->new();
my $null              = null_messages->new();
my $project_selector  = project_selector_messages->new();
my $iPick             = iPick_messages->new();
my $immodpg			  = immodpg_messages->new();
my $color_listbox	  = color_listbox_messages->new();

=head1 DOCUMENTATION

=head2 SYNOPSIS 
PACKAGE NAME: message_director 
 AUTHOR: Juan Lorenzo
         Nov 21 2017 

 DESCRIPTION: 
 Version: 1.0

 Messages to user in L_SU

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES

=cut

=head2 private hash 

 
=cut

my $message_director = {
    _cdp_num       => '',
    _gather_num    => '',
    _gather_type   => '',
    _gather_header => '',
    _type          => '',
    _instructions  => ''
};

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {

    $message_director->{_cdp_num}       = '';
    $message_director->{_gather_num}    = '';
    $message_director->{_gather_type}   = '';
    $message_director->{_gather_header} = '';
    $message_director->{_type}          = '';
    $message_director->{_instructions}  = '';
}

sub flows {
    my ( $self, $number ) = @_;
    my $message_ref = $flows->get();
    my $message     = @$message_ref[$number];

    # print("message_director,flows,message =$message\n");
    return ($message);
}

sub FileDialog_button {
    my ( $self, $number ) = @_;
    my $message_ref = $FileDialog_button->get();
    my $message     = @$message_ref[$number];

    # print("message_director,FileDialog_button,message =$message\n");
    return ($message);
}

sub FileDialog_close {
    my ( $self, $number ) = @_;
    my $message_ref = $FileDialog_close->get();
    my $message     = @$message_ref[$number];

    # print("message_director,FileDialog_close,message =$message\n");
    return ($message);
}

sub color_listbox {
    my ($self, $number ) = @_;

    my $message_ref = $color_listbox->get();
    my $message     = @$message_ref[$number];
#    print("message_director,color_listbox,message =$message\n");
    
    return ($message);
}

sub help_button {
    my ($self, $item ) = @_;

    my $message_item  = $item;
    $help_button->set($message_item);
    $help_button->get();  
#    print("message_director,help_button,message =$message_item\n");
    
    return ();
}

sub immodpg {
    my ( $self, $number ) = @_;

    my $message_ref = $immodpg->get();
    my $message     = @$message_ref[$number];
    # print("message_director,immodpg,message =$message\n");
    
    return ($message);
}

sub iPick {
    my ( $self, $number ) = @_;
    my $message_ref = $iPick->get();
    my $message     = @$message_ref[$number];
    print("message_director,iPick,message =$message\n");
    return ($message);
}

sub null_button {
    my ( $self, $number ) = @_;
    my $message_ref = $null->get();
    my $message     = @$message_ref[$number];

    # print("message_director,null,message =$message\n");
    return ($message);
}

sub project_selector {
    my ( $self, $number ) = @_;
    my $message_ref = $project_selector->get();
    my $message     = @$message_ref[$number];

    # print("message_director,project_selector,message =$message\n");
    return ($message);
}

sub run_button {
    my ( $self, $number ) = @_;
    my $message_ref = $run_button->get();
    my $message     = @$message_ref[$number];

    # print("message_director,run_button,message =$message\n");
    return ($message);
}

sub save_button {
    my ( $self, $number ) = @_;
    my $message_ref = $save_button->get();
    my $message     = @$message_ref[$number];

    # print("message_director,save_button,message =$message\n");
    return ($message);
}

sub superflow {
    my ( $self, $number ) = @_;
    my $message_ref = $superflow->get();
    my $message     = @$message_ref[$number];

    # print("message_director,sueprflow,message =$message\n");
    return ($message);
}

1;
