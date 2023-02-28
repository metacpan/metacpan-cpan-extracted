
=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: iSA (interactive Spectral Analysis) 
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE:    August 1 2016
 Version  1.0 
          read iSpectralAnalysis.config text file
 Version 1.1 Nov 8 2020use Moose;
 		 accepts NaN as undeclared gather number

=head2 DESCRIPTION

   Interactively pick muting parameters

=head2 USE

=head2 Examples

=head2 SEISMIC UNIX NOTES

=head2 STEPS

 1.  use the local library of the user
 1.1 bring is user variables from a local file
 2.  create instances of the needed subroutines

=head2 NOTES 

 We are using Moose.
 Moose already declares that you need debuggers turned on
 so you don't need a linewlike the following:
 use warnings;
 
 USES the following classes:
 sucat
 and packages of subroutines
 System_Variables
 SeismicUnix

=cut

use Moose;
our $VERSION = '1.1.0';
use Tk;
use Tk::Pretty;
use aliased 'App::SeismicUnixGui::big_streams::iSpectralAnalysis';
use aliased 'App::SeismicUnixGui::sunix::shell::xk';
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $iSA_Tk = {_prompt => ''};


=head2 Instantiate classes:

 Create a new version of the package 
 with a unique name

=cut

my $iSA     = iSpectralAnalysis->new();
my $xk      = xk->new();
my $message = SuMessages->new();
my $get     = L_SU_global_constants->new();
my $var     = $get->var();

=head2 Declare variables 

    in local memory space

=cut

my ( $calc_rb, $exit_rb, $pick_rb, $next_rb, $saveNcont_rb );
my $rb_value = "red";
our $mw;
my $NaN = $var->{_NaN};


=head2 Create Main Window 

 Sstart event-driven loop
 Interaction with user
 initialize values
 If picks are new, show
 message on how to pick data

 set Message type to iSpectralAnalysis
 Show instructions for first SpectralAnalysis

=cut

=head2 Decide whether to 

     PICK or move on to NEXT CDP
     Place window near the upper left corner
     of the screen
  Changing geometry of the toplevel window
  my $h = $mw->screenheight();
  my $w = $mw->screenwidth();
  print("width and height of screen are $w,$h\n\n");
  print("geometry of screen is $geom\n\n");

=cut

$mw = MainWindow->new;
$mw->geometry("200x50+40+0");
$mw->title("Spectra");
$mw->configure(
    -highlightcolor => 'blue',

    #-borderwidth 	=> $var->{_no_borderwidth},
    -background => $var->{_my_purple},
);


=head2 Display

     data first time

=cut	

print("NEW PICKS\n");
$message->set('iSpectralAnalysis');
$message->gather_num($NaN);
$message->instructions('firstSpectralAnalysis');

=head2 Print

  configuration
  my @config = $mw->configure();
  print Pretty @config;


=cut

$calc_rb = $mw->Radiobutton(
    -text       => 'CALC',
    -background =>,
    $var->{_my_yellow},
    -value    => 'calc',
    -variable => \$rb_value,
    -command  => [ \&set_calc ]
)->pack( -side => 'left' );

$pick_rb = $mw->Radiobutton(
    -text       => 'PICK',
    -background => $var->{_my_yellow},
    -value      => 'pick',
    -variable   => \$rb_value,
    -command    => [ \&set_pick ]
)->pack( -side => 'left' );


$exit_rb = $mw->Radiobutton(
    -text       => 'EXIT',
    -background =>,
    $var->{_my_yellow},
    -value    => 'pick',
    -variable => \$rb_value,
    -command  => [ \&set_exit ]
)->pack( -side => 'left' );

MainLoop;     # for Tk widgets


=head2 Set the prompt

 value according
 to which button is pressed
 then exit the MainLoop
 destroy the main window after the prompt
 is properly set

=cut  

=head2 sub set_pick

 callbacks

  send gather number to $iSA
  delete output of previous semblance
  plus more callbacks following...


=cut

sub set_pick {
    my $pick = 'pick';
    $pick_rb->configure( -state => 'normal' );
    $iSA_Tk->{_prompt} = $pick;
    print("Picking...\n");
    $iSA->select();
}

=head2 sub set_calc

      -PRESS the CALC button
=cut

sub set_calc {
    my $calc = 'calc';
    $calc_rb->configure( -state => 'normal' );
    $iSA_Tk->{_prompt} = $calc;
    print("Calculating...\n");

=head2 Delete 

   the previous display

=cut

    #$xk->kill_this('suximage');
    #$xk->kill_this('suxwigb');

    $iSA->xtract();
    $iSA->analyze();

}

=head2  sub set_exit

  saying goodbye 
  clear old images
  kill window
  stop script

=cut

sub set_exit {
    my $exit = 'exit';
    $exit_rb->configure( -state => 'normal' );
    $iSA_Tk->{_prompt} = $exit;
    print("Good bye.\n");
    $xk->kill_this('suximage');
    $xk->kill_this('suxwigb');
    $mw->destroy() if Tk::Exists($mw);
    exit 1;
}
