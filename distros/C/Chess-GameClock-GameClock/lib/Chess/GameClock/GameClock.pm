#!/usr/bin/perl -w
####-----------------------------------
### File	: GameClock.pm
### Author	: Ch.Minc
### Purpose	: Main Package for GameClock
### Version	: 1.2 2007/12/23
### copyright GNU license
####-----------------------------------

package GameClock ;

our $VERSION = '1.2' ;

use warnings;
use strict;

use Chess::GameClock::GclkData qw(:tout) ; 
use Chess::GameClock::GclkSettings qw(&menu &reglage) ;
use Chess::GameClock::GclkCounter ;
use Chess::GameClock::GclkDisplay qw(display);

# Aliases modif 2007/1/8
#my %cad=%Chess::GameClock::GclkData::cad ;
#my %sous_menu=%Chess::GameClock::GclkData::sous_menu ;

my %cad=%GclkData::cad ;
my %sous_menu=%GclkData::sous_menu ;


=head1 FUNCTIONS

=head2 new

Create object of GameClock

=cut

sub new {
  my ($class,@args)=@_ ;
  my $self={} ;             # a surveiller
  return bless ($self,$class) ;
}



=head2 set

Set the parameters of the GclkCounter
with or without GUI.

=cut

sub set {
my ($self,$cadence)=@_ ;

# build counters
my $whites=GclkCounter->new ;
my $blacks=GclkCounter->new ;

# build menu 
# if $cadence is a string that defines a cadence:
# $type in (@menu),$cad in $sous-menus ,Array subscripts ex "Blitz Usuel 0"
# if cadence is empty call reglage right away
if(!defined($cadence)) {&GclkSettings::menu($whites,$blacks,"") ;
&GclkSettings::reglage($whites,$blacks,"") ;
return($whites,$blacks) ;
}
# if cadence is compatible with data array
elsif ( ref($cadence)  =~ /ARRAY/ ) {
print "$cadence\n";
for my $i (0..$#{$cadence} ){
my $cadname="Cadence" . ($i+1) ;
print " $cadname \n" ;
  for my $k (keys %{$cadence->[$i]}) {
$cad{ReglagesManuels}{$cadname}[0]{$k}=$cadence->[$i]{$k};
print "\n $k $cadence->[$i]{$k} " ;
} 

#&reglage($whites,$blacks,$cadname) ;
}
$whites->init("ReglagesManuels Cadence" . @{$cadence} . " 0",'blancs') ;
$blacks->init("ReglagesManuels Cadence" . @{$cadence} . " 0",'noirs') ;
return($whites,$blacks) ;
}
else{
my ($type,$cad,$i)=split(' ',$cadence) ;
if ( defined($sous_menu{$type}) ){
&GclkSettings::reglage($whites,$blacks,$cadence) ;
return($whites,$blacks) ;
}
}
}

=head2 display

Embedded &GclkDisplay::display

=cut

sub display{

my ($self,$whites,$blacks,$scaling)=@_ ;
&GclkDisplay::display($whites,$blacks,$scaling) ;
}

=head1 NAME

GameClock - Chess and Go clock

=head1 VERSION

Version 1.2

=cut

=head1 SYNOPSIS

use strict ;

use Tk ;

use Chess::GameClock::GclkDisplay qw(display);

use Chess::GameClock::GameClock ;

#Three Modes for settings counters:

#With Gui to set the time (no parameters):

my ($whites,$blacks)=$clock->set ;

# or from the GUI like menu

# here the set is Blitz,Usuel, 10mn (indice 1)

my ($whites,$blacks)=$clock->set("Blitz Usuel 1") ;

# or a direct cadence with the following

#array of hashes

# first cadence 15 mn/25 moves then 15 mn dead time

our ($whites,$blacks)=$clock->set( [{qw/ct 15*60 mv 25 b 0 f 0 byo 1/},

                                   {qw/ct 15*60 mv 0 b 0 f 0 byo 1/}] ) ;

# example of japonese  byo-yomi

# main time 7s, then 3s per move and five byo-yomi time periods

#my ($whites,$blacks)=$clock->set(
#                                 [{qw/ct 7 mv 0 b 0 f 0 byo 0/},    
#                                  {qw/ct 3*5 mv 1 b 3 f 0 byo 

# display the counters

&GclkDisplay::display($whites,$blacks,0.75) ;

# and at last the Perl/Tk necessary statement

MainLoop ;

=head1 DESCRIPTION

 The module Chess::GameClock  do the job of a Chess or Go electronic
 clock. You can set any types of cadences like Fisher, Bronstein,
 Byo-yomi selecting preset cadences or by manual interface. 
 The left and right mouse buttons are the clock buttons for whites
 & blacks. 
 The keyboard is also divided into two zones right and left who emulates
 the actions of the mouse, as an extended facility (letter h, at the keyboard
 center has been excluded). 
 The time counters are large on the screen and move counters are also
 displayed. The window could be adjusted with the "$scaling" parameter,
that is a floating number generally between 0.5 and 2.0 .

 The counter display has three commands only accessed by keyboard keys:

 Control-q , forces application to quit.

 Control-h , make counters to toggle between the counting and
 halt (pause)  mode. 

 Start accessed by Control-Shift-0, Start or Restart  the counters from the beginning.

 You can also toggling the display between the elapsed or remaining time with Alt-c.

Note: The window "Perl Chess Clock" must have the focus for that commands could be effective.
 
=head1 AUTHOR

Charles Minc, C<< <charles.minc\ at wanadoo.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gameclock at rt.cpan.org>, or through the web interface at
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

1; # End of GameClock
