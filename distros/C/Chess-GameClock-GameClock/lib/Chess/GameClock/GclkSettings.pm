####-----------------------------------
### File	: GclkSettings.pm
### Author	: Ch.Minc
### Purpose	: Settings for GameClock
### Version	: 1.0 2006/1/26
####-----------------------------------


package GclkSettings ;

our $VERSION = '1.0' ;

use strict ;
use warnings ;

use Tk ;
use Tk::Radiobutton ;
use Tk::ProgressBar;
use Tk::Scale;
require Exporter ;

use Chess::GameClock::GclkData qw(:tout)  ; 
#use Chess::GameClock::GclkDisplay qw(hmnsec loupe) ;

# aliasing
my @menu=@GclkData::menu ;
my %sous_menu=%GclkData::sous_menu ;
my %soussous=%GclkData::soussous ;
my %aide=%GclkData::aide ;
my @Mode=@GclkData::Mode ;
my %cad=%GclkData::cad ;

#use Chess::GameClock::GclkDisplay qw(hmnsec loupe) ;

our @ISA=qw(Exporter) ;

our @EXPORT_OK=qw (&menu &reglage $screensz) ;

our $varset ;
our $screensz ;

my %sous_menuref ;
my %soussous_ref ;
my %rb ;
my $wmv ;
my $wmb ;

our $whites ;			
our $blacks ;			
our $cadinit;		       


sub menu {
  ($whites,$blacks,$cadinit)=@_ ;

  $varset= $cadinit || "Blitz Usuel 0" ;
  $screensz=$screensz ||  2 ;

  # build main window menu

  my $mw=MainWindow->new(-title=>qq(Réglages Pendule)) ;
  $mw->geometry("320x6") ;
  #$mw->grabGlobal ;
  my $top=$mw->toplevel;

  my $menubar =$top->Menu(-type => 'menubar');
  $top->configure(-menu => $menubar);

  foreach my $m (@menu) {

    # creation des sous-menus en cascade
    $sous_menuref{$m} = $menubar->cascade(-label=>$m) ;
    
    # entrées des données des sous-menus

    map($soussous_ref{$m}{$_}= $sous_menuref{$m}->cascade(-label=>$_),@{$sous_menu{$m}});

  }
 
  foreach my $type (keys %soussous_ref) {
    for my $cadence (keys %{$soussous_ref{$type} }) {
      map {$rb{$type}{$cadence}[$_]=$soussous_ref{$type}{$cadence}->radiobutton(
										-indicatoron =>'1',
										-command=>[\&reglage,$whites,$blacks,""],
										-label=>${$soussous{$type}{$cadence} }[$_],
										-variable=>\$varset,
										-value =>$type." ".$cadence . " ". $_) }   ( 0..$#{$soussous{$type}{$cadence} } ) ;
    }
  }
  for (qw/Cadence2 Cadence3 Cadence4/) {
    $rb{ReglagesManuels}{$_}[0]->configure (-state=>'disabled') ;
  }


  #$soussous_ref{Aide}{Bref}= $sous_menuref{Aide}->cascade(-label=>'En Bref') ;
  #my $cmd=$soussous_ref{Aide}{Bref}->command(-label=>'voir',-command=>\&voir) ;
  $sous_menuref{Aide}->command(-label=>'En Bref',-command=>[\&voir,%aide]) ;

  $soussous_ref{ReglagesManuels}{Options}->command(-label=>'Adjust',-command=>\&adjust) ;

  map {$rb{ReglagesManuels}{Mode}[$_]=$soussous_ref{ReglagesManuels}{Mode}->radiobutton(
											-indicatoron =>'1',
											-command=>sub{
											  #0=>x0.5,1,=>x0.75 2=>x1.00
											  &GclkDisplay::loupe(0.5+$screensz*0.25)},
											-label=>$Mode[$_],
											-variable=>\$screensz,
											-value =>$_) }   ( 0..$#Mode ) ;

  map {$rb{ReglagesManuels}{Mode}[$_]->configure (-state=>'disabled')} ( 0..$#Mode ) ; ;
}

sub adjust{
  use Tk::Spinbox ;

  my $sbxctw=MainWindow->new(-title=>qq(Adjustement Temps Blancs))
    ->Spinbox(-from=>'0',-to=>'1E6',-increment=>'1.0',-width=>'40' ) ;
  my $parentctw=$sbxctw->parent ;
  $parentctw->geometry("300x20+500+0") ;
  # my $val =$sbxctw->cget(-validate);
  # $sbxctw->configure(-validate => $val);
  $sbxctw->set($whites->[0]{ct})  ;
  $sbxctw->configure(-validate => 'key',
		     -command=>	sub{
		       $whites->[0]{ct}=$sbxctw->get ;
		     } 
		    );
  $sbxctw->pack ;

  my $sbxctb=MainWindow->new(-title=>qq(Adjustement Temps Noirs))
    ->Spinbox(-from=>'0',-to=>'1E6',-increment=>'1.0',-width=>'40' ) ;
  my $parentctb=$sbxctb->parent ;
  $parentctb->geometry("300x20+500+50") ;
  $sbxctb->set($blacks->[0]{ct})  ;
  $sbxctb->configure(-validate => 'key',
		     -command=>	sub{
		       $blacks->[0]{ct}=$sbxctb->get ;
		     } 
		    );
  $sbxctb->pack ;

  my $sbxmvw=MainWindow->new(-title=>qq(Adjustement Coups Blancs))
    ->Spinbox(-from=>'0',-to=>'1E6',-increment=>'1.0',-width=>'40' ) ;
  my $parentmvw=$sbxmvw->parent ;
  $parentmvw->geometry("300x20+820+0") ;
  $sbxmvw->set($whites->[0]{mv})  ;
  $sbxmvw->configure(-validate => 'key',
		     -command=>	sub{
		       my $diff=$whites->[0]{mv}-$sbxmvw->get ;
		       $whites->[0]{mv}-=$diff ;
                       $whites->[0]{mvt}-=$diff ;
		     } 
		    );
  $sbxmvw->pack ;

  my $sbxmvb=MainWindow->new(-title=>qq(Adjustementcoups Noirs))
    ->Spinbox(-from=>'0',-to=>'1E6',-increment=>'1.0',-width=>'40' ) ;
  my $parentmvb=$sbxmvb->parent ;
  $parentmvb->geometry("300x20+820+50") ;
  $sbxmvb->set($blacks->[0]{mv})  ;
  $sbxmvb->configure(-validate => 'key',
		     -command=>	sub{
		       my $diff= $blacks->[0]{mv}-$sbxmvb->get ;
		       $blacks->[0]{mv}-=$diff ;
		       $blacks->[0]{mvt}-=$diff ;
		     }
		    );
  $sbxmvb->pack ;
}

sub voir {
  my %aide=@_ ;
  my $mwaide=MainWindow->new(-title=>"Help") ;
  my $b=$mwaide->Button(-text=>$aide{Fr}.$aide{En},
			-anchor=>'nw',
			-justify=>'left',
			-wraplength=>'250', # 0 par défaut
			-width=>'45')->pack(-fill=>'both') ;
  $b->configure(-text=>$aide{Fr}.$aide{En},
		-anchor=>'nw',
		-justify=>'left',
                -wraplength=>'250', # 0 par défaut
                -width=>'45');
}

sub reglage {

  ($whites,$blacks, my $cadence)=@_ ;

  # if $varset != Reglages Manuels init counter with $varset
  # note a call to menu before must call reglage as ($w,$b,"")
  # for not smashing $varset

  $varset= $cadence || $varset;

  print "reglage : $varset \n" ;

  
  my  @default= ({ ct=>'0',	#cadence 1
		   mv=>'0',	# if 0 means KO else number of moves
		   b=>'0',	# fisher ou bronstein
		   f=>'0',
		   byo=>'1'},  {qw/ct 0 mv 0 b 0 f 0 byo 1/}) ;  

  my @status_var_h ;
  my @status_var_m ;
  my @status_var_s ;
  my @status_var_mv ;
  my $status_var_both=0 ;
  my $status_var_byo=1 ;
  my @status_var_bf ;
  my $status_bf ;
  my @set_hour ;
  my @set_mn ;
  my @set_sec ;
  my @set_mv ;
  my @set_fb ;
  my %proch1 ;

  if ($varset =~ /ReglagesManuels/) {
    my $mw = MainWindow->new(-title=>'Reglages Manuels');
    #$mw->configure(-background=>'blue') ;
    foreach (0,1) {
      $set_hour[$_]=$mw->Scale(-from =>0,-to =>12,-length=>'5c',-label=>"hrs ",-troughcolor=>'green',
			       -background=>'yellow',-variable=>\$status_var_h[$_])  ->pack(-side=>'left');
      $set_mn[$_]=  $mw->Scale(-from =>0,-to =>60,-length=>'5c',-label=>"mns ",-variable=>\$status_var_m[$_])  ->pack(-side=>'left');
      $set_sec[$_]= $mw->Scale(-from =>0,-to =>60,-length=>'5c',-label=>"secs",-variable=>\$status_var_s[$_])  ->pack(-side=>'left');
      $set_mv[$_]=  $mw->Scale(-from =>0,-to =>60,-length=>'5c',-label=>"coups",-variable=>\$status_var_mv[$_])->pack(-side=>'left');
      $set_fb[$_]=  $mw->Scale(-from =>0,-to =>60,-length=>'5c',-label=>"sec F/B",-variable=>\$status_var_bf[$_])->pack(-side=>'left');

      $set_fb[$_]->configure(	# -wraplength  =>'8',
				# -sliderlength=>'10',
				# -tickinterval=>'10',
			     -width       =>'10' ) ;
    }
    # backannotate
    my $t="ReglagesManuels" ;
    my @f=split(' ',$varset);
    my $c=$f[1] ;
    my $n=substr($c,7,1) ;
    my $i=0 ;			# mais cadence =[%cad1,%cad2,%cad3,%cad4]

    if (defined($whites->[$n]{ct})) {
      ($status_var_h[0],$status_var_m[0],$status_var_s[0])=&GclkDisplay::hmnsec($whites->[$n]{ct}) ;
      $status_var_mv[0]=$whites->[$n]{mv} ;
      $status_var_bf[0]=$whites->[$n]{b} + $whites->[$n]{f} ;
      $status_bf=$whites->[$n]{b} ? 0 : 1 ; 
      $status_var_byo=$whites->[$n]{byo} ;
      ($status_var_h[1],$status_var_m[1],$status_var_s[1])=&GclkDisplay::hmnsec($blacks->[$n]{ct}) ;
      $status_var_mv[1]=$blacks->[$n]{mv} ;
      $status_var_bf[1]=$blacks->[$n]{b} + $blacks->[$n]{f} ;
      #$status_var_byo[1]=$blacks->[$n]{byo} ;  unicity of type
    }
    my $b=$mw->Button(-text=>'valider',
                      -command=>sub{
			foreach (0..1) {
			  $default[$_]{byo}=$status_var_byo ? 0 : 1 ;
			  my $j ; 
			  $j=$status_var_both ==1 ? 0 :$_ ;
			  $default[$_]{ct}=60*($status_var_h[$j]*60+$status_var_m[$j])+$status_var_s[$j] ;
			  $default[$_]{mv}=$status_var_mv[$j] ;
			  $status_bf ?  $default[$_]{f}=$status_var_bf[$j] : $default[$_]{b}=$status_var_bf[$j] ;
			}
			;
			#			my $t="ReglagesManuels" ;
			#  my $c="Cadence1" ;
			#			my @f=split(' ',$varset);
			#			my $c=$f[1] ;
			#			my $i=0 ; # mais cadence =[%cad1,%cad2,%cad3,%cad4]
			map{ $cad{$t}{$c}[$i]{$_}=$default[0]{$_} } (qw/ct mv b f byo/)  ;
			$whites->init($varset,'blancs') ;
			map {$cad{$t}{$c}[$i]{$_}=$default[1]{$_}} (qw/ct mv b f byo/)  ;
			$blacks->init($varset,'noirs') ;
			# enable next cadence selection
			map {$proch1{"Cadence" . $_}="Cadence". ($_+1) } (0..4);                                  
			$rb{ReglagesManuels}{$proch1{$c}}[0]->configure(-state=>'normal') if(defined($rb{ReglagesManuels}{$proch1{$c} }[0])) ;
			$mw->destroy ; })->pack(-side=>'bottom') ;

    my $bb=  $mw->Radiobutton(-text=>'Bronstein',-variable=>\$status_bf,-value=>'0')->pack(-side=>'bottom') ;
    my $bf=  $mw->Radiobutton(-text=>'Fisher   ',-variable=>\$status_bf,-value=>'1')->pack(-side=>'bottom') ;
    $status_bf ? $bf->select:$bb->select ;
    my $both=$mw->Checkbutton(-text=>'Jumelé   ',
                              -variable=>\$status_var_both,
                              -command=>sub{
				my $i=$status_var_both ? 0 : 1 ; 
				$set_hour[1]->configure(-variable => \$status_var_h[$i]);
				$set_mn[1]  ->configure(-variable => \$status_var_m[$i]);
				$set_sec[1] ->configure(-variable => \$status_var_s[$i]);
				$set_mv[1]  ->configure(-variable => \$status_var_mv[$i]);
				$set_fb[1]  ->configure(-variable => \$status_var_bf[$i]);
			      }
			     )->pack(-side=>'bottom') ;
    my $byoyomi=$mw->Checkbutton(-text=>'Byo-Yomi ',
				 -variable=>\$status_var_byo
				)->pack(-side=>'bottom') ;
    $status_var_byo ? $byoyomi->deselect: $byoyomi->select ;
    $both->deselect ;
    #$both->invoke ;

  } else {
    $whites->init($varset,'blancs') ;
    $blacks->init($varset,'noirs') ;
  }
}
=head1 NAME

  GclkSettings - For setting the parameters with a GUI.

=head1 VERSION

Version 1.0

=cut


=head1 SYNOPSIS

This module is a GUI to set the parameters of GameClock.

=head1 EXPORT

&menu
&reglage

=head1 FUNCTIONS

=head2 menu

Generate the menu window of the GUI

=cut

=head2 adjust

This routine is done to adjust the time and
move number of each players, not for the initial setting.

The main reason is for correcting mistakes
or for arbiters, when playing.

Of course, this must be done in halt mode,
but there is no check.

Note: the return key does not validate,
only the spin buttons can do that. 

=head2 reglage

This routine provides the interface for
the manuel setting of data via ProgressBars

=cut

=head2 voir

A routine to show a hint in the menu

=cut

=head1 AUTHOR

Charles Minc, C<< <charles.minc@wanadoo.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gclksettings at rt.cpan.org>, or through the web interface at
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

  1;				# End of GclkSettings
