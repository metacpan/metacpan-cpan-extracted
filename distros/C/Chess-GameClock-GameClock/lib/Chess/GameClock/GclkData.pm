####-----------------------------------
### File	: GclkData.pm
### Author	: C.Minc
### Purpose	: Data for Game GameClock
### Version	: 1.8 2007/12/23
####-----------------------------------

package GclkData ;

our $VERSION = '1.8' ;

require Exporter ;
use strict ;
use warnings ;

# declaration des variables externes

our @ISA=qw(Exporter) ;

our @EXPORT_OK=qw (@menu 
		   %sous_menu
		   %soussous
                   %cad
                   %aide
                   @Mode
		  ) ;

our %EXPORT_TAGS=(tout=>[qw(@menu 
			     %sous_menu
			     %soussous
			     %cad
			     %aide
			     @Mode)]) ;

# données du menu principal
our @menu=("Blitz", "RapidesTournois", "ReglagesManuels","Byo-Yomi", "Aide") ;

# données des sous-menus
my @Blitz=("Usuel", "Bronstein","Fischer","Fide") ; 
my @RapideTournoi=("Classique","Fide","Fischer") ;
my @ReglagesManuels=("Cadence1","Cadence2","Cadence3","Cadence4","Mode","Options") ;
my @Aide=("En Bref") ;
my @ByoYomi=("Canadien","Japonais") ;

# Définition des references aux sous-menus
our %sous_menu=(Blitz                =>\@Blitz,
		"RapidesTournois"     =>\@RapideTournoi,
		"ReglagesManuels"     =>\@ReglagesManuels,
                "Byo-Yomi"            =>\@ByoYomi
               ) ;

our    @Mode=("X 0.50",
	      "X 0.75",
	      "X 1.00") ;

my   @Usuel=(" 5mn",
	     "10mn",
	     "15mn"
            ) ;
my   @BU=([{qw/ct 5*60 mv 0 b 0 f 0 byo 1/}],
          [{qw/ct 10*60 mv 0 b 0 f 0 byo 1/}],
          [{qw/ct 15*60 mv 0 b 0 f 0 byo 1/}]) ;

my @Bronstein=("5mn/3sec",
               "20mn/10sec"
	      ) ;
my @BB=([{qw/ct 5*60 mv 0 b 3 f 0 byo 1/}],
        [{qw/ct 20*60 mv 0 b 10 f 0 byo 1/}]) ;


my @Fischer=("3mn+5s/cps") ;

my @BF=([{qw/ct 3*60 mv 0 b 0 f 5 byo 1/}]) ; ;

my @Fide=("3mn puis 2s/cps",
          "20mn puis 5s/cps"
	 ) ;

my @BFi=([{qw/ct 3*60 mv 0 b 0 f 2 byo 1/} ],
         [{qw/ct 20*60 mv 0 b 0 f 5 byo 1/}]) ;

my @Classique=("25mn KO",
               "61mn KO",	#type A
               "2h/40cps+1H KO", #type B
               "2h/40cps+1H/20 cps+30mn KO", #type D
               "2h/40cps+1H/20 cps+ 1H  KO", #type C
               "2h/40cps+1h/20 cps+repeating"
	      );
my @RC=(  [{qw/ct 25*60 mv 0 b 0 f 0 byo 1/}], #0
          [{qw/ct 61*60 mv 0 b 0 f 0 byo 1/}], #1
          [{qw/ct 2*3600 mv 40 b 0 f 0 byo 1/},	#2
           {
	    qw/ct 1*3600 mv 0 b 0 f 0 byo 1/}],
          [{qw/ct 2*3600 mv 40 b 0 f 0 byo 1/},	#3
           {
	    qw/ct 1*3600 mv 20 b 0 f 0 byo 1/},
           {
	    qw/ct 30*60 mv 0 b 0 f 0 byo 1/}],
          [{qw/ct 2*3600 mv 40 b 0 f 0 byo 1/},	#4
           {
	    qw/ct 1*3600 mv 20 b 0 f 0 byo 1/},
           {
	    qw/ct 1*3600 mv 0 b 0 f 0 byo 1/}],
          [{qw/ct 2*3600 mv 40 b 0 f 0 byo 1/},	#5
           {
	    qw/ct 1*3600 mv 20 b 0 f 0 byo 1/}]
       );




my @FideT=("1H puis 10s/cps",
           "1H15+30s/40cps puis 15mn+30s/cps KO",
	   #1h 15 + 30 secondes pour 40 coups puis 15 minutes + 30 secondes pour terminer la partie
           "2H puis 20s/cps"
	  ) ;

my @RFi=( [{qw/ct 1*3600 mv 40 b 0 f 0 byo 1/}, 
           {
	    qw/ct 0 mv 0 b 0 f 10 byo 1/}], 
          [{qw/ct 1*3600+15*60 mv 40 b 0 f 0 byo 1/},
           {
	    qw/ct 15*60 mv 0 b 0 f 30 byo 1/}],
          [{qw/ct 2*3600 mv 40 b 0 f 0 byo 1/}, 
           {
	    qw/ct 0  mv 0 b 0 f 20 byo 1/}],
	);

my @FischerT=("20mn+10/cps",
	      "80mn/40cps,40mn/20cps,1mn/cps",
	      "50mn+10s/cps",	#type A
	      "1H40+30s/cps -40cps,40mn+30s/cps", #type B
	      "1H40+30s/cps -40cps,50mn+30s/cps -20cps,40mn+30s/cps", #type C
	      "1H40+30s/cps -40cps,50mn+30s/cps -20cps,10mn+30s/cps" #type D
             ) ;

my @RF=(  [ {qw/ct 20*60 mv 0 b 0 f 10 byo 1/}],    
          [{qw/ct 80*60 mv 40 b 0 f 0 byo 1/},
           {
	    qw/ct 40*60 mv 20 b 0 f 0 byo 1/},
           {
	    qw/ct 0     mv 0 b 0 f 60 byo 1/}],
	  [{qw/ct 50*60 mv 0 b 0 f 10 byo 1/}],
	  [{qw/ct 100*60 mv 40 b 0 f 30 byo 1/},
	   {
	    qw/ct 40*60 mv 0 b 0 f 30 byo 1/}],
	  [{qw/ct 100*60 mv 40 b 0 f 30 byo 1/},
           {
	    qw/ct 50*60 mv 20 b 0 f 30 byo 1/},
           {
	    qw/ct 40*60 mv 0 b 0 f 30 byo 1/}],
	  [{qw/ct 100*60 mv 40 b 0 f 30 byo 1/},
           {
	    qw/ct 50*60 mv 20 b 0 f 30 byo 1/},
           {
	    qw/ct 10*60 mv 0 b 0 f 30 byo 1/}]
       ) ;

#<main time>/<byo-yomi time period>/<number of moves
my @Canadien=("20mn+15mn/25cps"
	     ) ;
#<maintime> + <byo-yomi time period>x<number of byo-yomi time periods>.
my @Japonais=("60mn+5x60s",
              "60mn+1x20s",
              "120mn+1x30s"
	     );

my @RCN=([{qw/ct 20*60 mv 0 b 0 f 0 byo 0/},    
          {
	   qw/ct 15*60  mv 25 b 0 f 0 byo 0/}]
	);

my @RJ=([{qw/ct 60*60 mv 0 b 0 f 0 byo 0/},    
	 {
	  qw/ct 60*5 mv 1 b 60 f 0 byo 0/}],
	[{qw/ct 60*60 mv 0 b 0 f 0 byo 0/},    
	 {
	  qw/ct 20*1 mv 1 b 20 f 0 byo 0/}],
	[{qw/ct 60*60 mv 0 b 0 f 0 byo 0/},    
	 {
	  qw/ct 30*1 mv 1 b 30 f 0 byo 0/}]
       );

our %soussous=(    Blitz =>{ Usuel =>\@Usuel,
			     Bronstein =>\@Bronstein,
			     Fischer =>\@Fischer,
			     Fide =>\@Fide
			   },

		   "RapidesTournois"=>{Classique=>\@Classique,
				       Fide=>\@FideT,
				       Fischer=>\@FischerT
				      },
 
		   "Byo-Yomi"       =>{Canadien=>\@Canadien,
                                       Japonais=>\@Japonais
                                      },

                   "ReglagesManuels"=>{Cadence1=>['Cadence1'],
				       Cadence2=>['Cadence2'],
				       Cadence3=>['Cadence3'],
				       Cadence4=>['Cadence4']}
		   #                   "Aide"           =>{About=>['Help']}
              ) ;

# cadences de base pour les compteurs
# $type $cadence $paramètres

our %cad=(Blitz =>{ Usuel =>\@BU,
		    Bronstein =>\@BB,
		    Fischer =>\@BF,
		    Fide =>\@BFi
		  },
	  "RapidesTournois"=>{Classique=>\@RC,
			      Fide=>\@RFi,
			      Fischer=>\@RF},
 
          "Byo-Yomi"       =>{Canadien=>\@RCN,
			      Japonais=>\@RJ
			     },
          "ReglagesManuels"=> {} #{ [{},{},{},{}]},

	 ) ;

our %aide ;

$aide{En}= <<END
1. Select a clock rate (cadence) in the menu window \n
2. Press Ctrl-shift-0 (with "Perl Chess Clock" 
   selected)\n
3. When Blacks clicks on one of the mouse
   button, they start the Whites counter and
   get this button as their clock game button \n
4. You can stop the counters by pushing Ctrl-h
  (The button Halt changes to red color) and so on.
   Times shown, toggle between the  elapsed or
   remaining time with Alt-c \n
END
  ;
$aide{Fr}= <<END
     +++++++++++++++++++++++ 
        GameClock V1.0      
     +++++++++++++++++++++++

1. Choississez une cadence dans les menus\n
2. Appuyer sur les touches Ctrl-shift-0\n
3. Lorsque les Noirs appuie sur une touche,
   le compteur des Blancs démarre et la touche
   pressée est affectée à l'usage des Noirs.\n
4. La pendule peut être arrêtée en pressant
   Ctrl-h (le bouton Halt devient rouge et vice-versa)
   et l'on choisit l'affichage soit du temps
   écoulé soit du temps restant par Alt-C.\n
-------------------------------------------

END
  ;

=head1 NAME

GclkData - The Package thats holds the datas for GameClock
           most of them are dedicated to the set the cadence
           (clock rate) of the game.

=head1 VERSION

Version 1.8

=cut


=head1 SYNOPSIS

 [{qw/ct 15*60 mv 25 b 0 f 0 byo 1/},
  {qw/ct 15*60 mv 0 b 0 f 0 byo 1/}]

The Array here above has to be understood as having
two sequences.

The first one: {qw/ct 15*60 mv 25 b 0 f 0 byo 1/}
will set the counting time avalaible "ct" 15*60 seconds thats means
900 seconds or 15 minutes. 

ct is evaluated so it can be written as a product for sake of lisibility.

mv is the move number at which  checking time will be done.

b is the Bronstein time and f is the Fisher time. They are both a kind
of bonus. 

All the time are finally expressed in seconds.

For Byo-Yomi, there some trick because it exists two kind for these
cadences:

Canadian byo-yomi.

Japonese byo-yomi.

Byo-Yomi mode is  set when byo=0.

So finally, the rules for setting the clock rate are the following:

ct : maintime could be time*60 | time*3600 | time

if byo=1 means no Byo-Yomi

         b !=0 or f !=0 set the Bronstein or Fischer cadence.

         mv=0 sets the Sudden death or Guillotine.

         Loop on the cadence except Sudden death of course.

If byo=0 
         First cadence is for maintime defined with ct (note here mv=0).

         Next cadence could be of Japonese type: b!=0 and ct=k*b where k
                                                 is an integer.
         or Canadian type when b=0.

         Generally, for Canadian Byo-Yomi mv is an integer and for Japonese mv=1.

=head1 AUTHOR

Charles Minc, C<< <charles.minc@wanadoo.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gclkdata at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GameClock>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GameClock

You can also look for information at:
http://en.wikipedia.org/wiki/Go_intro#Timing


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

1;				# End of GclkData



