#!/usr/bin/perl -w
####-----------------------------------
### File	: GclkCounter.pm
### Author	: Ch.Minc
### Purpose	: Package for Counter
### Version	: 1.0 2006/1/26
### copyright GNU license
####-----------------------------------

package GclkCounter ;

our $VERSION = '1.0' ;

require Exporter ;
use warnings;
use strict;


use Time::HiRes qw(gettimeofday tv_interval);
use Tk ;
use Tk::Dialog ;

use Chess::GameClock::GclkData qw(:tout) ;

my %cad=%GclkData::cad ;

our @ISA=qw(Exporter) ;

our @EXPORT_OK=qw (&capture &stop $start) ;

sub new {
  my ($class,@args)=@_ ;
  my $self=[{}] ;
  return bless ($self,$class) ;
}


sub init {
  #build  the counter data array
  #usage $self->init(@values) i.e cadence color
  my ($self,$arg,$col)=@_ ;

  #my @default= ( {ct=>'0',   #cadence 1
  #               mv=>'0', # if 0 means KO else number of moves
  #               b=>'0',   # fisher ou bronstein
  #               f=>'0',
  #               byo=>'0'   # byo mode no time glue  
  #                }
  #              ) ;

  my $rec;
  my @default ;
  my ($t,$c,$i)=split(' ',$arg) ;
  # concaténation des cadences si Cadence
  if ($c =~ /Cadence(\d)/) {
    for (1..$1) {
      @default=(@default,$cad{$t}{"Cadence" . $_}[$i]) ;
    }
  } else {
    for my $j (0..$#{$cad{$t}{$c}[$i]} ) {
      @default=(@default,$cad{$t}{$c}[$i][$j]);
    }
    ;
  }

  for (0..$#default) { 
    my $st=$default[$_]{ct} ;
    $default[$_]{'ct'}=eval($st) ;warn $@ if $@;
  }

  @{$self}=( {state=>'Off',
	      newstate=>'Off',
	      color=>$col ,
	      mouse=>'',
	      cmpt=>'0',	# compteur temps joué
	      ct=>'0' ,		# temps disponible
	      mvt=>'0',		# number of moves
              mv=>'0',          # number of moves inside a cadence
	      ts=>'0',		# timestamp
	      indc=>'1'}) ;

  for my $k (0..$#default) { 
    map {$self->[$k+1]{$_}=$default[$k]{$_} }  (qw/ct mv b f byo/)  ;
  }

  #  use Dumpvalue;
  #  my $dumper = new Dumpvalue;
  #  $dumper->dumpValues(@{$self});
}

sub cntupdate {
  # active increment of counter
  my $self=shift ;
  my $tod=shift ;
  my $icad=$self->[0]{indc} ;	# indc pointe sur la cadence en cours

  if ( $self->[0]{state} eq "Off" &&  $self->[0]{newstate} eq "On") {
    #    $self->[0]{b}= $self->[$icad]{b} ; ### f ???
    $self->[0]{state}= $self->[0]{newstate} ;
    $self->[0]{ts}=$tod ;
  }

  # add on time when fisher is on and elapsed time or substracted 
  # bronstein time
  if ( $self->[0]{state} eq "On" &&  $self->[0]{newstate} eq "Off") {
    my $delta=tv_interval($self->[0]{ts}); 
    $self->[0]{cmpt}+=$delta ;

    if ($self->[$icad]{byo}==1) {
      $self->[0]{ct}-=$delta ; 
      $self->[0]{ct}+=$self->[$icad]{f}+ ($delta <= $self->[$icad]{b} ?$delta: $self->[$icad]{b}) ;
    }
    $self->[0]{state}= $self->[0]{newstate} ;

    # update move
    ($self->[0]{mv})++ ;
    ($self->[0]{mvt})++ ;

    # check limits
    #if mv = 0 means KO unless byo==0
    #if mv !=0 && last cadence loop on that cadence

    if (( $self->[0]{mv} ==  $self->[$icad]{mv}) && $self->[$icad]{mv} !=0 ) {

      # update  time limit & next cadence ,time checked in on-on
 
      $self->[0]{mv}=0 ;
      $self->[0]{indc}=$icad<$#{$self}? ++$icad : $#{$self} ;
      if ( $self->[$icad]{byo} ==0 && $self->[$icad]{b} !=0 ) { # japonais
	$self->[0]{ct}=
	  $self->[$icad]{b}*(int($self->[0]{ct}/$self->[$icad]{b})-int($delta/$self->[$icad]{b}));
      } else {
	$self->[0]{ct}=$self->[$icad]{ct}+ $self->[0]{ct}*$self->[$icad]{byo} ; # si b=0  canadien

      }
    }
  

    # byo-yomi japonais
    # deux cadences main time
    if ($self->[$icad]{mv} ==0 && $self->[$icad]{byo} ==0 ) {
      $self->[0]{ct} -=$delta ;  
      #  main time épuisé passage au byo-yomi (dans $self->[icad]{b} !=0 )
      if ($self->[0]{ct} <= 0 ) {
        $self->[0]{mv}=0 ;
	$self->[0]{indc}=$icad<$#{$self}? ++$icad : $#{$self} ;
	$self->[0]{ct} +=$self->[$icad]{ct} ;  
	# normalisation byo-yomi
	#	my $d1=int($self->[0]{ct}/$self->[$icad]{b}) ;
	#	my $d2=int($delta/$self->[$icad]{b}) ;
	#	$self->[0]{ct}=$self->[$icad]{b}*($d1-$d2) ;
      }

    }

  }


  #  if( $self->[0]{state} eq "Off" &&  $self->[0]{newstate} eq "Off"){
  #  # nothing to do
  #$self->print ;
  #  }


  if ( $self->[0]{state} eq "On" &&  $self->[0]{newstate} eq "On") {
 
    my $tchk ;
    # time limit
    if ($self->[$icad]{byo} ) {
      $tchk=$self->[$icad]{b} + $self->[0]{ct}-tv_interval($self->[0]{ts}) ;

    } else {
      # valable avant le byo-yomi -----$icad=2
      $tchk=$self->[0]{ct}-tv_interval($self->[0]{ts})  ;
      
    }
    unless (0<=$tchk ) {
      print "lost \n" ;
      my $lmw=MainWindow->new ;
      $lmw->withdraw ;
      $lmw->messageBox(-icon =>'info',
		       -message =>"GameOver for (Dépassement de temps pour les) $self->[0]{color}",
		       -title => 'GameClock Warning',
		       -type => 'Ok',
		       -default => 'Ok' ) ;
      $lmw->destroy ;
      return ;
    }
  }

}
sub start{

  #$cnt->start($cnt,$cnt_black,Mouse) 
  #bouton start (re)initialise
  #mais ce sont les Noirs  mettent en marche
  my ($self,$wself,$bself,$mw,$white_mv,$black_mv)=@_ ;

  undef($wself->[0]{mouse}) ;
  undef($bself->[0]{mouse}) ;
  $wself->[0]{indc}=1 ;
  $bself->[0]{indc}=1 ;
  # time limits
  $wself->[0]{ct}=$wself->[1]{ct} ;
  $bself->[0]{ct}=$bself->[1]{ct} ;
  $wself->[0]{cmpt}=0 ;
  $bself->[0]{cmpt}=0 ;
  # reset move counters
  $wself->[0]{mv}=0 ;
  $bself->[0]{mv}=0 ;  
  $wself->[0]{mvt}=0 ;
  $bself->[0]{mvt}=0 ;
  # state
  $wself->[0]{newstate}='Off';
  $bself->[0]{newstate}='Off' ;
  $wself->[0]{state}='Off';
  $bself->[0]{state}='Off' ;
  # Fix a bug :move counter don't show the value
  # after a setting with &reglage ?
  $white_mv->configure(-textvariable=>\$wself->[0]{mvt}) ; 
  $black_mv->configure(-textvariable=>\$bself->[0]{mvt}) ;

  $mw->bind('<ButtonRelease>',[\&capture, Ev('s'),$wself,$bself]) ;
  ##
  print "Counters ready to start\n" ;

}

sub stop{
  our @pile ;
  my ($mw,$but,$wself,$bself,@arg)=@_ ;

  # etat du bouton
  my $col=$but->cget(-background) ;
  if ($col eq 'red') {
    # etat rouge -arret
    $but->configure(-background=>pop @pile) ;
    $but->configure(-activebackground=>pop @pile) ;
    $bself->[0]{state}=pop @pile ;
    $wself->[0]{state}=pop @pile ;

    # actualise le timestamp
    my $self=$wself->[0]{state} eq 'On'?$wself:$bself ;
    $self->[0]{ts}=[gettimeofday];
    $mw->bind('<ButtonRelease>',[\&capture, Ev('s'),$wself,$bself]) ;
  } else {
    # etat non rouge - marche
    # actualise les compteurs- passe à l'arret
    my $self=$wself->[0]{state} eq 'On'?$wself:$bself ;
    my $delta=tv_interval($self->[0]{ts}); 
    $self->[0]{cmpt}+=$delta ;
    $self->[0]{ct}-=$delta ;
    $mw->bind('<ButtonRelease>',"") ;

    # sauve l'etat du bouton et des compteurs
    push(@pile,$wself->[0]{state} ) ;
    push(@pile,$bself->[0]{state} ) ;
    push(@pile,$but->cget(-activebackground)) ;
    push(@pile,$col) ;

    # bloque les compteurs
    $wself->[0]{state}='Off' ;
    $bself->[0]{state}='Off' ;
    $but->configure(-activebackground=>'red') ;
    $but->configure(-background=>'red') ;
  }
  ;
  ## a faire reactiver start en arret
  #print "pile:@pile \n" ;
}

sub capture{
  my ($hashref,$mouse,$whites,$blacks )=@_ ;
  my $tod=[gettimeofday];
  my   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime(time);
  # appel à l'init sans click
  $mouse=~ s/-// ;		# Ev('s') return Bn-
  if (!defined($whites->[0]{mouse})) {
    my $cb=$mouse eq 'B1' ;
    ($mouse eq 'B1') ? $blacks->[0]{mouse}='B1': $whites->[0]{mouse}='B1' ;
    ($mouse eq 'B3') ? $blacks->[0]{mouse}='B3': $whites->[0]{mouse}='B3' ;
  }
  # set the new counters state
  if ( $mouse eq $whites->[0]{mouse}) {
    $whites->[0]{newstate} ="Off" ;
    $blacks->[0]{newstate} ="On" ;
  } else {
    $whites->[0]{newstate} ="On" ;
    $blacks->[0]{newstate} ="Off" ;
  }
  $whites->cntupdate($tod) ;
  $blacks->cntupdate($tod) ;

  # print into the log

  my $str=sprintf("%02d:%02d:%02d",$hour,$min,$sec) ;
  print
    "Time: $str \n
     Whites move: $whites->[0]{mvt} whites time Av.:$whites->[0]{ct} #$whites->[0]{mv}\n 
     Blacks move: $blacks->[0]{mvt} Blacks time Av.:$blacks->[0]{ct} #$blacks->[0]{mv}\n" ;

   }

sub print{
  my $self=shift ;
  #print " Counter elem: $$self[0]{state} \n" ; 
  #print " Counter elem: $self->[0]->{state} \n" ; 
  #print " Counter elem: $self->[0]{state} \n" ;  
  # print the whole thing with refs
  for my $href ( @{$self} ) {
    print "{ ";
    for my $t ( keys %$href ) {
      print "$t=$href->{$t} ";
    }
    print "}\n";
  }
}


=head1 NAME

  GclkCounter - The Heart of GameClock

=head1 VERSION

Version 1.0

=cut

=head1 SYNOPSIS

This module does everythings at counter level.
It makes counters,inits them, update them, captures events,
start , halt , eventually print the internal datas

    use GclkCounter;

    $whites=GclkCounter->new ;
    $whites->init($arg,$color) ;
    $whites-> cntupdate{$timestamp);
    $whites->print ;
#  the functions hereafter are only used  inside callbacks
    &start($whites,$blacks,$mainwindow,$white_move_button,$black_move_button)= ;
    &stop($halt_button,$whites,$blacks) ;
    &capture($mouse_event,$whites,$blacks ) ;

=head1 EXPORT

&capture
&stop
$start

=head1 FUNCTIONS

=head2 new ;

Create object GclkCounter 

=cut
 
=head2 init

  Get the parameters from GameClock directly or via Gamesettings
  and adapts the datas for the counters

=head2 cntupdate

When an event more precisely a mouse button is
released the state of the counter changes.
This determines the following actions:

=over 4

=item * Change the counter states.

=item * Check times

=item * Update the time counters

=item * Update the move counters

=item * Update the sequence pointers

=back

=head2 capture

When a mouse event occurs the first time
after enabling the start mode, it determines
the mouse button for each player, knowing that
the Blacks must push the button at first.
It set the newsate of each counter accorging
to the mouse button pressed, and after that,
it gets a timestamp for calling the methode cntupdate.

=cut

=head2 start

Initialization of the program to begin
the counting mode.

=cut

=head2 stop

This routines halt counters , necessary if
one player receive a phone call in a friendly
situation ;=) or in some case, when people need
that an arbiter comes.

=cut

=head2 print

Could help for people that wants add new cadences.

=cut


=head1 AUTHOR

Charles Minc, C<< <charles.minc@wanadoo.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gclkcounter at rt.cpan.org>, or through the web interface at
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

  1;				# End of GclkCounter
