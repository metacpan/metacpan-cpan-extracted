#!/usr/bin/perl 

=head1 NAME

rectangle-coverage.pl - Find the dot maximally covered by (random) rectangles

=head1 SYNOPSIS

You might have to do 

  prompt% sudo cpan Tk 
  prompt% sudo cpan Algorithm::RectanglesContainingDot 

specially this last one, first, since that module is not installed by default with L<Algorithm::Evolutionary>.

  prompt% ./rectangle-coverage.pl <number-of-rectangles> <arena-side> <bits-per-coordinate> <population> <number of generations> <selection rate>

Or

  prompt% ./rectangle-coverage.pl

And change variable values from the user interface

=head1 DESCRIPTION  

A demo that combines the L<Algorithm::Evolutionary::Op::Easy> module
    with L<Tk> to create a visual demo of the evolutionary
    algorithm. It generates randomly a number of rectangles, and shows
    how the population evolves to find the solution. The best point is
    shown in darkening yellow color, the rest of the population in
    green. 

Use "Start" to start the algorithm after setting the variables, and
    then Finish to stop the EA, Exit to close the window.

Default values are as follows

=over

=item * 

I<number of rectangles>: 300

=item * 

I<arena-side>: 10 This is independent from the number of pixels, set
    by default to 600x600.

=item * 

I<bits-per-coordinate>: 32 (this is the chromosome length divided by two;
there are two "genes")

=item * 

I<population size>: 64

=item * 

I<number of generations>: 200 

=item * 

I<selection rate>: 20% (will be replaced each generation); this means it's a steady state algorithm, which only changes a part of the population each generation.

=back

This program also demonstrates the use of caches in the fitness
evaluation, so be careful if you use too many bits or too many
generations, check out memory usage.

Console output shows the number of generations, the winning chromosome, and
fitness. After finishing, it outputs time, cache ratio and some other
things. 

=cut

use Tk;
use strict;
use warnings;

use Algorithm::RectanglesContainingDot;

use lib qw(lib ../lib);
use Algorithm::Evolutionary qw( Individual::BitString Op::Easy 
				Op::Bitflip Op::Crossover );


my $width = 600;
my $height = 500;

# Create MainWindow and configure:
my $mw = MainWindow->new;
$mw->configure( -width=>$width, -height=>$width );
$mw->resizable( 0, 0 ); # not resizable in any direction

my $num_rects = shift || 300;
my $arena_side = shift || 10;

my $bits = shift || 32;
my $pop_size = shift || 64; #Population size
my $number_of_generations = shift || 200; #Max number of generations
my $selection_rate = shift || 0.2;
my $scale_x = $arena_side/$width;
my $scale_y = $arena_side/$height;

my $alg = Algorithm::RectanglesContainingDot->new;
my $fitness;
my $generation;
my @pop;
# Start Evolutionary Algorithm
my $contador=0;
my $dot_size = 6;
my $mini_dot_size = $dot_size/2;
my @dot_population;

# Create and configure the widgets
my $f = $mw->Frame(-relief => 'groove',
		   -bd => 2)->pack(-side => 'top',
				   -fill => 'x');

for my $v ( qw( num_rects arena_side bits pop_size number_of_generations selection_rate ) ){
  create_and_pack( $f, $v );
}

my $canvas = $mw->Canvas( -cursor=>"crosshair", -background=>"white",
              -width=>$width, -height=>$height )->pack;
$mw->Button( -text    => 'Start',
	     -command => \&start,
	   )->pack( -side => 'left',
		    -expand => 1);
$mw->Button( -text    => 'End',
	       -command => \&finished,
	     )->pack( -side => 'left',
		      -expand => 1 );
$mw->Button( -text    => 'Exit',
	     -command => sub { exit(0);},
	   )->pack( -side => 'left',
		    -expand => 1 );

$mw->eventAdd('<<Gen>>' => '<Control-Shift-G>'); # Improbable combination
$mw->eventAdd('<<Fin>>' => '<Control-C>');
$mw->bind('<<Gen>>' => \&generation);
$mw->bind('<<Fin>>' => \&finished );


sub create_and_pack {
  my $frame = shift;
  my $var = shift;
  my $f = $frame->Frame();
  my $label = $f->Label(-text => $var )->pack(-side => 'left');
  my $entry = $f->Entry( -textvariable => eval '\$'.$var )->pack(-side => 'right' );
  $f->pack();
}

sub start {
  #Generate random rectangles
  for my $i (0 .. $num_rects) {
    
    my $x_0 = rand( $arena_side );
    my $y_0 = rand( $arena_side);
    my $side_x = rand( $arena_side - $x_0 );
    my $side_y = rand($arena_side-$y_0);
    $alg->add_rectangle("rectangle_$i", $x_0, $y_0, 
			$x_0+$side_x, $x_0+$side_y );
    my $val = 255*$i/$num_rects;
    my $color = sprintf( "#%02x%02x%02x", $val, $val, $val );
    $canvas->createRectangle( $x_0/$scale_x, $y_0/$scale_y, 
			      $side_x/$scale_x, $side_y/$scale_y, 
			    -outline =>$color );
  }

  #Declare fitness function
  $fitness = sub {
    my $individual = shift;
    my ( $dot_x, $dot_y ) = $individual->decode($bits/2,0, $arena_side);
    my @contained_in = $alg->rectangles_containing_dot($dot_x, $dot_y);
    return scalar @contained_in;
  };



  #----------------------------------------------------------#
  #Initial population
  #Creamos $pop_size individuos
  for ( 0..$pop_size ) {
    my $indi = Algorithm::Evolutionary::Individual::BitString->new( $bits );
    push( @pop, $indi );
  }

#----------------------------------------------------------#
  # Variation operators
  my $m = Algorithm::Evolutionary::Op::Bitflip->new; # Rate = 1
  my $c = Algorithm::Evolutionary::Op::Crossover->new(2, 9 ); # Rate = 9
  
  #----------------------------------------------------------#
  #Usamos estos operadores para definir una generación del algoritmo. Lo cual
  # no es realmente necesario ya que este algoritmo define ambos operadores por
  # defecto. Los parámetros son la función de fitness, la tasa de selección y los
  # operadores de variación.
  $generation = Algorithm::Evolutionary::Op::Easy->new( $fitness , $selection_rate , [$m, $c] ) ;


#----------------------------------------------------------#
  for ( @pop ) {
    if ( !defined $_->Fitness() ) {
      my $this_fitness = $fitness->($_);
      $_->Fitness( $this_fitness );
    }
  }

  #Start the music
  $mw->eventGenerate( '<<Gen>>', -when => 'tail' );
}

sub as_point {
    my $individual = shift || die "Nobody here!n";
    my @point = $individual->decode($bits/2,0, $arena_side);
    return ($point[0]/$scale_x, $point[1]/$scale_y);
}

sub generation {
    while (@dot_population) {
	$canvas->delete( shift @dot_population );
    }
    $generation->apply( \@pop );
    print "Pop size $#pop\n";
    
    my $val = 255*$contador/$number_of_generations;
    my $color = sprintf( "#%02x%02x00", 255-$val, 255-$val );
    my ($point_x, $point_y) = as_point( $pop[0] );
    print "$contador : ", $pop[0]->asString(), ", Color $color\n\tDecodes to $point_x, $point_y\n" ;
    $contador++;
    
    $canvas->createOval($point_x-$dot_size, $point_y-$dot_size, 
			$point_x+$dot_size, $point_y+$dot_size, 
			-fill => $color );

    for my $p ( @pop ) {
	my @point = as_point( $p );
	push @dot_population,$canvas->createOval($point[0]-$mini_dot_size, $point[1]-$mini_dot_size, 
						 $point[0]+$mini_dot_size, $point[1]+$mini_dot_size, 
						 -fill => "#00ff00" ); 
    }
    $canvas->update();
    if  ( ($contador < $number_of_generations) 
	  && ($pop[0]->Fitness() < $num_rects)) {
	$mw->eventGenerate( '<<Gen>>', -when => 'tail' );
    } else {
	$mw->eventGenerate( '<<Fin>>' );
    }
}


sub finished {
#----------------------------------------------------------#
#leemos el mejor resultado
    
#Mostramos los resultados obtenidos
    print "Best is:\n\t ",$pop[0]->asString()," Fitness: ",$pop[0]->Fitness(),"\n";
}

MainLoop;
=head1 SEE ALSO


First, you should obviously check
    L<Algorithm::Evolutionary::Op::Easy>, and then these other classes.

=over 4

=item *

L<Algorithm::Evolutionary::Op::Base>.

=item *

L<Algorithm::Evolutionary::Individual::Base>.

=item *

L<Algorithm::Evolutionary::Fitness::Base>.

=back

L<Tk> is a prerrequisite for this program, as well as
    L<Algorithm::RectanglesContainingDot>. Obviously,
    L<Algorithm::Evolutionary> should be installed too, just in case
    you got this independently.

=head1 AUTHOR

J. J. Merelo, C<jj (at) merelo.net>

=cut

=head1 Copyright
  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2012/12/08 10:12:37 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/scripts/rectangle-coverage.pl,v 3.5 2012/12/08 10:12:37 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.5 $

=cut

