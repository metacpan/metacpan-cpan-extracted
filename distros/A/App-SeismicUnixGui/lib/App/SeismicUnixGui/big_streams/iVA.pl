
=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: iVA 
 AUTHOR: Juan Lorenzo
 DATE:  April 2 2009 
        October 2014
        July 	2015 updated to oop
        August 	2015 introduced Tk widgets
        August 	16 made all event-driven
		Aug 18 	2016 made configuration files simple

 DESCRIPTION: Interactively test NMO in data
 Verstion 2.0 MainWIndow in subroutine 
              leads to multiple segementation faults
              when MainWindow is destroyed > 1
 Version: 2.1 is fully event driven

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES
=head4 CHANGES and their DATES


=cut


=head2 STEPS 

 1.  use the local library of the user
 1.1 bring is user variables from a local file
 2.  create instances of the needed subroutines

=cut

=head2 Import
 
 packages

=cut 

use Moose;
our $VERSION = '0.0.1';
use Tk;
use aliased 'App::SeismicUnixGui::big_streams::iVA';
use App::SeismicUnixGui::misc::SeismicUnix qw($true $false );

=head2 instantiate methods

=cut

my $iVA = iVA->new();

=head2 Declare variables 

   in local memory space

=cut

my $iVA_Tk = {_prompt => ''};

my ( $calc_rb, $exit_rb, $pick_rb, $next_rb, $saveNcont_rb );
my $rb_value = "red";
my $old_data;
my $next_step       = 'stop';
my $number_of_tries = 0;
our $mw;

=head2 Check 

  for old data

=cut

$old_data = $iVA->old_data('velan');

=head2 Create Main Window 

 and start event-driven loop
 Interaction with user
 initialize values
 If picks are new, show
 message to user on how to pick data
  -Based on semblance,
      decide whether to PICK or move on to NEXT CDP
   -radio_buttons stop flow
   Must be AFTR semblance

 set the prompt value according
 to which button is pressed
 then exit the MainLoop
 destroy the main window after the prompt
 is properly set

=cut

if ( !$old_data ) {

	print("iVelocityAnalysis, no old data\n");
    $iVA->start();

    $mw = MainWindow->new;
    $mw->title("Options");
    $mw->geometry("300x50+40+0");
    $mw->title("iVA");

    $calc_rb = $mw->Radiobutton(
        -text     => 'CALC',
        -value    => 'calc',
        -variable => \$rb_value,
        -command  => [ \&set_calc ]
    )->pack( -side => 'left' );

    $next_rb = $mw->Radiobutton(
        -text     => 'NEXT',
        -value    => 'next',
        -variable => \$rb_value,
        -command  => [ \&set_next ]
    )->pack( -side => 'left' );

    $pick_rb = $mw->Radiobutton(
        -text     => 'PICK',
        -value    => 'pick',
        -variable => \$rb_value,
        -command  => [ \&set_pick ]
    )->pack( -side => 'left' );


    $exit_rb = $mw->Radiobutton(
        -text     => 'EXIT',
        -value    => 'exit',
        -variable => \$rb_value,
        -command  => [ \&set_exit ]
    )->pack( -side => 'bottom' );

    MainLoop;     # for Tk widgets

}   # for new data


=pod sub set_pick

 A callback to:
 send cdp number to $iVA
 delete output of previous semblance
 plus more callbacks following...

=cut

sub set_pick {

    my $pick = 'pick';
    $next_rb->configure( -state => 'disabled' );

    #$pick_rb->configure(-state => 'normal');
    $calc_rb->configure( -state => 'normal' );
    $iVA_Tk->{_prompt} = $pick;
    $iVA->pick();
}

=pod sub set_calc

      -PRESS the CALC button
      -Increment number of tries to make
         semblance display interact and show old picks
         (number_of_tries >1)
		-radio_buttons stop flow
           Must be AFTR semblance
           B4  iWrite_All_iva_out

=cut

sub set_calc {

    my $calc = 'calc';
    $next_rb->configure( -state => 'normal' );
    $iVA_Tk->{_prompt} = $calc;
    $iVA->calc();

}

=pod sub set_next

  In this case the $variable is empty
  1. increment cdp
     Exit if beyond last cdp 
  2. reset prompt
  3. Otherwise display the first sembance
  4 ... see following callbacks

=cut


sub set_next {
    print("Next...\n");
    $next_rb->configure( -state => 'normal' );
    $calc_rb->configure( -state => 'disabled' );
    my $next = '';
    $iVA_Tk->{_prompt} = $next;
    $iVA->next();

}

=pod  sub set_exit

  saying goodbye 
  clear old images
  kill window
  stop script

=cut

sub set_exit {
    my $exit = 'exit';
    $exit_rb->configure( -state => 'normal' );
    $iVA_Tk->{_prompt} = $exit;
    $mw->destroy() if Tk::Exists($mw);
    $iVA->exit();
}

=pod sub prompt

 return which prompt has been set

=cut

sub prompt {
    our $variable = $iVA_Tk->{_prompt};
    return ($variable);
}
