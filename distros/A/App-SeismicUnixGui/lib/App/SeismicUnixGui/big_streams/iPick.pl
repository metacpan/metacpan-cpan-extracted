
=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: iPick (interactive Picking) 
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE:  June 15 2019 

=head2 DESCRIPTION

   Interactively pick points

=head2 USE

=head2 Examples

=head2 SEISMIC UNIX NOTES

=head2 STEPS

=head2 NOTES 

 We are using Moose
 Moose already declares that you need debuggers turned on
 so you don't need a line like the following:
 use warnings;
 
 For the iPick tool and in  order to prevent redefining subroutines
 we implement new modulesB,C,D ...
 
 Both of the following instantiate iPick_spec.pm
 --iPick_config 
 			calls 
 		config_superflows 
 		    calls 
 		big_streams_param 
 			which requires and instantiates iPick_spec
 --iPick.pm
 		uses and instantiates iPick_specB.pm
 		uses iShowNselect_picks
 		      which instantiates iPick_specC
 		uses iSelect_xt
 			  which instantiates iPick_specD

=cut

use Moose;
our $VERSION = '0.0.1';

use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::readfiles';

use aliased 'App::SeismicUnixGui::configs::big_streams::iPick_config';
use aliased 'App::SeismicUnixGui::big_streams::iPick';
use App::SeismicUnixGui::misc::SeismicUnix qw($true $false);
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use aliased 'App::SeismicUnixGui::sunix::shell::xk';

my $iPick_Tk = {_prompt => ''};

=head2 Instantiate classes:

 Create a new version of the package 
 with a unique name

=cut set defaults

my $iPick_config = iPick_config->new();
my $iPick        = iPick->new();
my $get          = L_SU_global_constants->new();
my $message      = SuMessages->new();
my $var          = $get->var();
my $xk			 = xk->new();

=head2 Get configuration information

=cut

my ( $CFG_h, $CFG_aref ) = $iPick_config->get_values();

my $gather_header  = $CFG_h->{suximage}{1}{gather_header};
my $offset_type    = $CFG_h->{suximage}{1}{offset_type};
my $base_file_name = $CFG_h->{base_file_name};
my $first_gather   = $CFG_h->{suximage}{1}{first_gather};
my $last_gather    = $CFG_h->{suximage}{1}{last_gather};
my $gather_inc     = $CFG_h->{suximage}{1}{gather_inc};
my $freq           = $CFG_h->{sugain}{1}{freq};
my $gather_type    = $CFG_h->{suximage}{1}{gather_type};
my $min_amplitude  = $CFG_h->{suximage}{1}{min_amplitude};
my $max_amplitude  = $CFG_h->{suximage}{1}{max_amplitude};
my $min_x1         = $CFG_h->{suximage}{1}{min_x1};
my $max_x1         = $CFG_h->{suximage}{1}{max_x1};
my $purpose        = $CFG_h->{suximage}{1}{purpose};


=head2 Declare variables 

 in local memory space

=cut

my ( $calc_rb, $exit_rb, $pick_rb, $next_rb, $saveNcont_rb );
my $rb_value          = "red";
my $gather            = $first_gather;
my $next_step         = 'stop';
my $number_of_tries   = 0;
my $there_is_old_data = 0;
our $mw;

$iPick->number_of_tries($number_of_tries);
$iPick->file_in($base_file_name);
$iPick->gather_type($gather_type);
$iPick->gather_header($gather_header);
$iPick->offset_type($offset_type);
$iPick->freq($freq);
$iPick->min_amplitude($min_amplitude);
$iPick->max_amplitude($max_amplitude);
$iPick->min_x1($min_x1);
$iPick->max_x1($max_x1);
$iPick->gather_num($gather);
$iPick->set_purpose($purpose);
$iPick->set_message_type('iPick_xt');


=head2

  Check for old data

=cut

$iPick->set_data_type('Pick_xt');
$there_is_old_data = $iPick->get4data_type();

if ($there_is_old_data) {
    print("Old picks already exist.\n");
    print(
        "Delete \(\"rm \*old\*\"\)or Save        old picks, and then restart\n\n"
    );
    exit;
}


=head2 Display

     data first time

=cut

if ( !$there_is_old_data ) {

     print("NEW PICKS\n");

    $message->set('iPick_xt');
    $message->gather_num($gather);
    $message->instructions('first_pick_xt');

    $iPick->number_of_tries($false);
    $iPick->gather_num($gather);

    $iPick->iSelect_xt();

=head2 Create Main Window 

 Start event-driven loop
 Interaction with user
 initialize values
 If picks are new, show
 message on how to pick data

=cut

=head2 Decide whether to 

	PICK or move on to NEXT GATHER
	Place windows (2) near the left side
	of the screen
     
	Changing geometry of the toplevel window
	my $h = $mw->screenheight();
	my $w = $mw->screenwidth();
	print("width and height of screen are $w,$h\n\n");
	print("geometry of screen is $geom\n\n");

=cut

    $mw = MainWindow->new;
    $mw->geometry("400x50+40+0");
    $mw->title("Interactive Picking");

    $mw->configure( -background => $var->{_my_purple} );

    $calc_rb = $mw->Radiobutton(
        -text       => 'CALC',
        -background => $var->{_my_yellow},
        -value      => 'calc',
        -variable   => \$rb_value,
        -command    => [ \&set_calc ]
    )->pack( -side => 'left' );

    $next_rb = $mw->Radiobutton(
        -text       => 'NEXT',
        -background => $var->{_my_yellow},
        -value      => 'next',
        -variable   => \$rb_value,
        -command    => [ \&set_next ]
    )->pack( -side => 'left' );

    $pick_rb = $mw->Radiobutton(
        -text       => 'PICK',
        -background => $var->{_my_yellow},
        -value      => 'pick',
        -variable   => \$rb_value,
        -command    => [ \&set_pick ]
    )->pack( -side => 'left' );
    $saveNcont_rb = $mw->Radiobutton(
        -text       => 'Save and Continue',
        -background => $var->{_my_yellow},
        -value      => 'saveNcont',
        -variable   => \$rb_value,
        -command    => [ \&set_saveNcont ]
    )->pack( -side => 'left' );

    $exit_rb = $mw->Radiobutton(
        -text       => 'EXIT',
        -background => $var->{_my_yellow},
        -value      => 'exit',
        -variable   => \$rb_value,
        -command    => [ \&set_exit ]
    )->pack( -side => 'left' );

    MainLoop;     # for Tk widgets
}   # for new data


=head2 Set the prompt

	value according
	to which button is pressed
	then exit the MainLoop
	destroy the main window after the prompt
	is properly set

=cut  

=head2 sub  set_pick

	callbacks
	
	send gather number to $iPick
	delete output of previous displays

=cut

sub set_pick {

    my ($self) = @_;
    my $pick = 'pick';
    $pick_rb->configure( -state => 'normal' );
    $iPick_Tk->{_prompt} = $pick;

    print("Picking...\n");

    $iPick->gather_num($gather);

=item Delete output 

  of previous muting

=cut

    # $xk->kill_this('suximage');
    # $xk->kill_this('suxwigb');

=head2 
number_of_tries
    -replot 1st data 
    -PICK X-T pairs
    -Increment number of tries to make
       data display interact with user
       (number_of_tries = 1)

=cut

    $message->set('iPick_xt');
    $message->gather_num($gather);
    $message->instructions('pre_pick_xt');
    $number_of_tries++;
    $iPick->number_of_tries($number_of_tries);

    # print("1. iPick.pl,set_pick,number_of_tries: $number_of_tries\n");

    if ( $number_of_tries >= 2 ) {

        # print("2. iPick.pl,set_pick,number_of_tries: $number_of_tries\n");
        $iPick->iPicks_shownNselect();

    }
    elsif ( $number_of_tries == 1 ) {

        # print("3. iPick.pl,set_pick,number_of_tries: $number_of_tries\n");
        $iPick->iPicks_select_xt();

    }
    else {
        print("iPick.pl,bad number of tries\n");
    }

}

=head2 sub  set_calc

      -PRESS the CALC button
      -Increment number of tries to make
       display and show old picks
       (if number_of_tries >1)

=cut

sub set_calc {

    my ($self) = @_;
    my $calc = 'calc';
    $calc_rb->configure( -state => 'normal' );
    $iPick_Tk->{_prompt} = $calc;
    print("Calculating...\n");

=head2 Delete 

   the previous display

=cut

    # $xk->kill_this('suximage');
    # $xk->kill_this('suxwigb');

    $iPick->iPicks_par();
    $iPick->iPicks_sort();
    $number_of_tries++;
    $iPick->number_of_tries($number_of_tries);
    $iPick->iPicks_shownNselect();
    $iPick->iPicks_save();

=head2 Message 

       to halt flow
       when number_of_tries >0

=cut

    $message->set('iPick_xt');
    $message->gather_num($gather);
    $message->instructions('post_pick_xt');

}


=head2 sub  set_saveNcont

   same as next

=cut

sub set_saveNcont {

    my ($self) = @_;
    my $saveNcont = 'saveNcont';
    $saveNcont_rb->configure( -state => 'normal' );
    $iPick_Tk->{_prompt} = $saveNcont;
    print("Saving and Continuing...\n");

    &set_next();

}


=head2 sub  set_next

  In this case $self is empty
  1. increment gather
     Exit if beyond last gather 
  2. reset prompt
  3. Otherwise display the first semblance
  4 ... see following callbacks

=cut

sub set_next {

    my ($self) = @_;
    print("Next...\n");
    $next_rb->configure( -state => 'normal' );
    my $next = '';
    $iPick_Tk->{_prompt} = $next;
    $gather = $gather + $gather_inc;

    print("new gather is $gather \n\n");

=head2  Delete output 

   of previous top mute

=cut

    # $xk->kill_this('suximage');
    # $xk->kill_this('suxwigb');
    # $xk->kill_this('xgraph');

    if ( $gather > $last_gather ) {
        set_exit();

    }
    elsif ( $gather <= $last_gather ) {

=head2 Display

       update gather number in memory
       first x,t again
       Show user message
       Select the xt values
=cut

        $iPick->gather_num($gather);
        $iPick->iPicks_message('first_pick_xt');
        $iPick->iPicks_select_xt();

    }
    else {
        print("iPick.pl, unexpected gather number\n");
    }

}

=head2  sub  set_exit

  say goodbye 
  clear old images
  kill window
  stop script

=cut

sub set_exit {

    my ($self) = @_;
    my $exit = 'exit';
    $exit_rb->configure( -state => 'normal' );
    $iPick_Tk->{_prompt} = $exit;

    print("Good bye.\n");
    print("Not continuing to next gather\n");

    # $xk->kill_this('suximage');
    # $xk->kill_this('suxwigb');
    # $xk->kill_this('xgraph');

    $mw->destroy() if Tk::Exists($mw);
    exit 1;

}
