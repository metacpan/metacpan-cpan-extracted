####-----------------------------------
### File	: GclkDisplay.pm
### Author	: Ch.Minc
### Purpose	: Display counters for GameClock
### Version	: 1.1 2007/12/23
####-----------------------------------

package GclkDisplay ;

our $VERSION = '1.1' ;

require Exporter ;
use strict ;
use warnings ;

use Tk ;
use Time::HiRes qw(gettimeofday tv_interval);
use Chess::GameClock::GclkData  qw (:tout) ;

our @ISA=qw(Exporter) ;

our @EXPORT_OK=qw (&display hmnsec loupe) ;

my $varset ;
my %sous_menuref ;
my %soussous_ref ;
my %rb ;
my $aff ;
my @setaff=(qw/Blitz RapidesTournois/) ;
push(@setaff,$aff=shift(@setaff)) ;

my $whites ;			#our
my $blacks ;
my $mw ;
my $screensz ;

sub display {
  ($whites,$blacks,$screensz)=@_ ;

  # window where the timestamps of the game are written by GclkCounter
  my $mwt=MainWindow->new(-title=>"LogTime") ;
  my $spytext = $mwt->Text(qw/-width 120 -height 30/)->pack;
  $mwt->iconify ;
  tie *STDOUT, ref $spytext, $spytext;


  # draw the clock windows 
  $mw=MainWindow->new(-title=>'Perl Chess Clock') ;

  my ($l,$v1,$v2)=&loupe($screensz) ;


  my $fr=$mw->Frame->pack  ;
  my %option_mv=(qw/-height 1 -width 3 -anchor center / ) ;
  #  my $wmv='W' ;
  #  my $bmv='B' ;
  my  $white_mv=$fr->Button(# -textvariable=>\$whites->[0]{mvt},   x
			     -foreground=>'yellow',
			     -font=>' Arial 24 bold',
			     -activeforeground=>'yellow' 
			   )->pack(-side=>'left') ;
  my $black_mv=$fr->Button(	#-textvariable=>\$blacks->[0]{mvt},
			   -font=>' Arial 24 bold',
			   -activeforeground=>'black',
			  )->pack(-side=>'left')  ;
#  $white_mv->configure(%option_mv) ;                               x
  $white_mv->configure(-textvariable=>\$whites->[0]{mvt},%option_mv) ;   # modif x
  $black_mv->configure(-textvariable=>\$blacks->[0]{mvt},%option_mv) ;


  my $cn1=$mw->Canvas(-height=>'15c',-width=>'30c')->pack ;
  ;
  my $txt1=$cn1->createText($l,$v1,
			    -text=>'00:00:00',
			    -font=>'Helvetica 200 bold',
			    -fill=>'yellow',
			    -justify=>'right',
			    -activefill=>'yellow',
			    -tags=>['txt1','box','r1']
			   ) ;

  my $txt2=$cn1->createText($l,$v2,-text=>'00:00:00',
			    -font=>'Helvetica 200 bold',
			    -fill=>'black',
			    -justify=>'right',
			    -activefill=>'black',
			    -tags=>['txt2','box','r2']
			   ) ;


  my $rect1=$cn1->createRectangle('0.5c','1c','29c','7c',-width=>'0.3c',-outline=>'white',-tags=>['rect1', 'box', 'r1']) ;
  my $rect2=$cn1->createRectangle('0.5c','7.5c','29c','14c',-width=>'0.3c',-outline=>'black',-tags=>['rect2', 'box' ,'r2']) ;

  my $fm=$mw->Frame() ;
  $fm->pack(-side=>'bottom'
	   )  ;

  my $start=$fm->Button(-text=>'Start') ;
  #			-command=>['start',$whites,$whites,$blacks,$mw,$black_mv]);                      
  my $stop=$fm->Button(-text=>'Halt') ;
  my $quit=$fm->Button(-text=>"Quit") ;
  #		       -command=>\&Tk::exit)  ;

  my %cmd_opt=(qw/-anchor center -width 20 -height 4/);
  $start->configure(%cmd_opt) ; 
  $stop->configure(%cmd_opt)  ; 
  $quit->configure(%cmd_opt)  ; 
  $start->pack(-side=>'left')  ; 
  $stop->pack(-side=>'left')  ; 
  $quit->pack(-side=>'left')  ; 

  # cancel mouse bindings for Button mv  and set Alt-c keyboard command

  $white_mv->bindtags(['TrickyButton',$white_mv->toplevel,'all']) ;
  $black_mv->bindtags(['TrickyButton',$black_mv->toplevel,'all']) ;
  $mw->bind('<<counting_mode>>'=>[\&cnttype,'w']) ;
  $mw->eventAdd('<<counting_mode>>'=>'<Alt-c><KeyRelease-c>') ;

  # cancel mouse bindings for Button $stop $start $quit
  $stop->bindtags(['TrickyButton',$stop->toplevel,'all']) ;
  $mw->bind('<<stop_mode>>'=>['GclkCounter::stop',$stop,$whites,$blacks]) ;
  $mw->eventAdd('<<stop_mode>>'=>"<Control-h>") ;
 
  $start->bindtags(['TrickyButton',$start->toplevel,'all']) ;
  $mw->bind('<<start_mode>>'=>['GclkCounter::start',
			       $whites,$blacks,$mw,$white_mv,$black_mv]);                      
  $mw->eventAdd('<<start_mode>>'=>"<Control-0>") ;

  $quit->bindtags(['TrickyButton',$quit->toplevel,'all']) ;
  $mw->bind('<<quit_mode>>'=>sub{&Tk::exit(0)} ) ;
  $mw->eventAdd('<<quit_mode>>'=>"<Control-q>") ;

  # bind keyboard to toggle counters
  map{$mw->bind("<KeyPress-$_><KeyRelease-$_>",['GclkCounter::capture', 'B1-',$whites,$blacks])}(qw/a z e r t y q s d f g < w x c v b/) ;
  map{$mw->bind("<KeyPress-$_><KeyRelease-$_>",['GclkCounter::capture', 'B3-',$whites,$blacks])}(qw/u i o p Multi_key $ j k l m ugrave * n comma ; : \/ ! /) ;

  # force the focus on window Chess Clock
  $mw->focusForce ;


  $mw->repeat(1000=>sub {
		{  
		  #my $wmv=$whites->[0]{mv} ;
		  #                   my $bmv=$blacks->[0]{mv} ;
		  #                   $fr->update ;
		  my $elapsed =($whites->[0]{state} eq 'On')? tv_interval ($whites->[0]{ts}):0 ;
		  #print $whites->[0]{state} ;
		  my $td=$whites->[0]{ct} ;
		  my $tj=$whites->[0]{cmpt} ;
		  $td -=$elapsed ;
		  $tj +=$elapsed ;
		  $cn1->dchars($txt1,0,7) ;
		  my $taff= $aff=~ /Blitz/ ? $td : $tj  ;
		  my $str1=sprintf("%02d:%02d:%02d",&hmnsec($taff)) ;
		  $cn1->insert($txt1,1,$str1) ;
		}
		;
		# affichage suivant la cadence Blitz-Fisher-Bronstein temps restant
		#                              KO  temps écoulé/temps restant
		{
		  my $elapsed =($blacks->[0]{state} eq 'On')? tv_interval ($blacks->[0]{ts}):0 ;
		  my $td=$blacks->[0]{ct} ;
		  my $tj=$blacks->[0]{cmpt} ;
		  $td -=$elapsed ;
		  $tj +=$elapsed ;
		  $cn1->dchars($txt2,0,7) ;
		  my $taff= $aff=~ /Blitz/ ? $td : $tj  ;
		  my $str2=sprintf("%02d:%02d:%02d",&hmnsec($taff) ) ;
		  $cn1->insert($txt2,1,$str2) ;
		}
		; 
		#$mw->update ;
	      } ) ;

}

sub loupe{
  my $x=shift ;
  $mw->scaling($x) ;
  my $scale=0.76*$x ;
  my($l,$v1,$v2)=('550','150','400') ;
  $l  *=$scale ;
  $v1 *=$scale ;
  $v2 *=$scale ;
  return($l,$v1,$v2) ;
}

sub cnttype{
  # change counter aspect up or down 
  push(@setaff,$aff=shift(@setaff)) ;
}



sub hmnsec{
  # convert time in sec to hh:mm:ss
  my $sec=shift ;
  if ($sec < 0 || !defined($sec) ) {
    return(0,0,0);
  }
  my $h=int($sec / 3600) ;
  my $mn=int(($sec% 3600)/60) ;
  my $s=$sec%60 ;
  return ($h,$mn,$s) ;
}

=head1 NAME

GclkDisplay - Display the counters

=head1 VERSION

Version 1.1

=cut

=head1 SYNOPSIS

Draw the Chess Counter Window

    use GclkDisplay;

   &display($whites,$blacks,$scaling)

where $whites and $blacks are GclkCounter object and $scaling a scalar
for changing the size of the window displayed.

=head1 EXPORT

display

=head1 FUNCTIONS

=head2 display

see SYNOPSIS

=cut

=head2 cnttype

an internal routine for toggling counters time
between time elased and time remaining.

Global parameters

=cut


=head2 hmnsec

convert time in sec to hh:mm:ss format

my($h,$mn,$s)=hmnsec(time_in_seconds) ;

=head2 loupe

adjust the parameters for the window size.

my ($l,$v1,$v2)=&loupe($scaling) ;

where $scaling is between 0.5 and 2.0

(Note:This function is perhaps screen type/graphics board 
dependant, in case of malfunction).

=head1 AUTHOR

Charles Minc, C<< <charles.minc@wanadoo.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gclkdisplay at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GameClock>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GameClock

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GameClock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GameClock>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GameClock>

=item * Search CPAN

L<http://search.cpan.org/dist/GameClock>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Charles Minc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;				# End of GclkDisplay
