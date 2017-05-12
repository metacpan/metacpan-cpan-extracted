#!/usr/bin/perl
use warnings; use strict;

=pod

=head1 NAME Shooter.pl

marble.pl - A demonstration to demonstrate marbles colliding with static circles, rects, and points.

Parameters like the numbers of marbles & static objects, gravity, and speed 
limits are in the code.

Derived from kthakore's shooter.pl.

=cut
use lib 'blib/arch';
use lib 'lib';
use Collision::2D ':all';
use SDL;
use SDL::Video;
use SDL::Surface;;
use SDL::Event;
use SDL::Events;
use SDL::Rect;
use SDL::Color;
use SDL::GFX::Primitives;

use Carp;

=comment 
use SDL::Time;
use Data::Dumper;

=cut


#Initing video
#Die here if we cannot make video init
croak 'Cannot init video ' . SDL::get_error()
  if ( SDL::init(SDL_INIT_VIDEO) == -1 );

#Make our display window
#This is our actual SDL application window
my $app = SDL::Video::set_video_mode( 800, 500, 32, SDL_SWSURFACE );

croak 'Cannot init video mode 800x500x32: ' . SDL::get_error() if !($app);

#constants
my $grav = .31;
my $spd_limit = 11;
my $dot_size = 4; #even though it's a point, it has to be visible

#the things that move & collide
my @crates = map {random_crate()} (1..2);
my @dots = map {random_dot()} (1..8);
my @lamps = map {random_lamp()} (1..5);
my @marbles = map {random_marble()} (1..3);
my @squarbles = map {random_squarble()} (1..3);
#my $marble_surf = init_marble_surf();
#my $crate_surf = init_crate_surf();


# Get an event object to snapshot the SDL event queue
my $event = SDL::Event->new();
my $cont=1;
#Our level game loop
while ( $cont ) {
   while ( SDL::Events::poll_event($event) )
   {    #Get all events from the event queue in our event
      if ($event->type == SDL_QUIT)
      {
         $cont = 0 
      }
   }
   
   for my $marble (@marbles,@squarbles){
      $marble->{interval} = 1;
   }
   for my $marble (@marbles,@squarbles){
      while ($marble->{interval} > 0){
         $marble->{y} -= 600 if $marble->{y} > 560;#wrap y
         $marble->{y} += 600 if $marble->{y} < -60;#wrap y
         $marble->{x} -= 1000 if $marble->{x} > 960;#wrap x
         $marble->{x} += 1000 if $marble->{x} < -60;#wrap x
         $marble->{yv} = $spd_limit if $marble->{yv} > $spd_limit; #y speed limit
         $marble->{yv} = -$spd_limit if $marble->{yv} < -$spd_limit; #y speed limit
         $marble->{xv} = $spd_limit if $marble->{xv} > $spd_limit; #x speed limit
         $marble->{xv} = -$spd_limit if $marble->{xv} < -$spd_limit; #x speed limit
         $marble->{yv} += $grav;
         
         #squarble?
         my $ent = $marble->{h} ? hash2rect($marble) : hash2circle ($marble);
         my @collisions = map {dynamic_collision ($ent, $_->{ent}, interval=>$marble->{interval}, keep_order=>1)} @crates;
         push @collisions, map {dynamic_collision ($ent, $_->{ent}, interval=>$marble->{interval}, keep_order=>1)} @dots;
         push @collisions, map {dynamic_collision ($ent, $_->{ent}, interval=>$marble->{interval}, keep_order=>1)} @lamps;
         push @collisions, #collide with other marbles too
                    map {dynamic_collision (
                        $ent, 
                        $_->{h} ? hash2rect($_) : hash2circle ($_),
                        interval=>$marble->{interval},
                        keep_order=>1
                        )} 
                    grep {$_ != $marble}
                    (@marbles,@squarbles);
         @collisions = grep {$_ and ($_->time>0)} @collisions;
         @collisions = sort {$a->time <=> $b->time} @collisions;
         my $collision = $collisions[0];
         if ($collision and $collision->time) {
            next unless $collision->time;
            $marble->{x} += $marble->{xv} * $collision->time*.94;
            $marble->{y} += $marble->{yv} * $collision->time*.94;
            my $bvec = $collision->bounce_vector(elasticity=>1);
            $marble->{xv} = $bvec->[0];
            $marble->{yv} = $bvec->[1];
            $marble->{interval} -= $collision->time+.1; #leftover frame interval
            #will repeat if interval > 0
         }
         else {
            $marble->{y} += $marble->{yv}*$marble->{interval};
            $marble->{x} += $marble->{xv}*$marble->{interval};
            $marble->{interval} = 0;
         }
      }
   }
   SDL::Video::fill_rect(
      $app,
      SDL::Rect->new( 0, 0, 800, 500 ),
      SDL::Video::map_RGB( $app->format, 0,0,0 )
   );
   for my $crate (@crates, @squarbles){
      SDL::Video::blit_surface(
         $crate->{surf},
         SDL::Rect->new( 0, 0, $crate->{w}, $crate->{h}),
         $app,
         SDL::Rect->new(
            $crate->{x} , $crate->{y},
            $crate->{w} , $crate->{h},
         )
      )
   }
   
   for my $dot (@dots){
      SDL::Video::blit_surface(
         $dot->{surf},
         SDL::Rect->new( 0, 0, $dot_size, $dot_size),
         $app,
         SDL::Rect->new(
            $dot->{x}-2 , $dot->{y}-2,
            $dot_size, $dot_size,
         )
      )
   }
   
   for my $marble (@marbles,@lamps){
      SDL::Video::blit_surface(
         $marble->{surf},
         SDL::Rect->new( 0, 0, 2*$marble->{radius}, 2*$marble->{radius}),
         $app,
         SDL::Rect->new(
            $marble->{x} - $marble->{radius},
            $marble->{y} - $marble->{radius},
            2*$marble->{radius},
            2*$marble->{radius},
         )
      );
   }
   
   #Update the entire window
   #This is one frame!
   SDL::Video::flip($app);
}



sub random_dot{
   my $dot = {x=>30+rand(740), y=>200+rand(250), xv=>0, yv=>0};
   $dot->{surf} = init_dot_surf($dot);
   $dot->{ent} = hash2point $dot;
   return $dot
}
sub random_lamp{
   my $lamp = {x=>100+rand(600), y=>200+rand(250), radius => 5+rand(25), xv=>0, yv=>0};
   $lamp->{surf} = init_marble_surf($lamp);
   $lamp->{ent} = hash2circle $lamp;
   return $lamp
}
sub random_marble{
   my $marble = {x=>100+rand(600), y=>100+rand(300), radius=>10+rand(20), xv=>0, yv=>0};
   $marble->{surf} = init_marble_surf($marble);
   return $marble
}
sub random_crate{
   my $crate = {x=>rand(700), y=>150+rand(100), w=>rand(50)+150, h=>rand(50)+50};
   $crate->{surf} = init_crate_surf($crate);
   $crate->{ent} = hash2rect $crate;
   return $crate
}
sub random_squarble{
   my $sqbl = {x=>rand(700), y=>150+rand(100), w=>20+rand(30), h=>20+rand(30), xv=>0, yv=>0};
   $sqbl->{surf} = init_crate_surf($sqbl);
   return $sqbl
}


sub init_dot_surf {
   my $dot = shift;
   my $surf =
      SDL::Surface->new( SDL_SWSURFACE, $dot_size,$dot_size, 32, 0, 0, 0,
      255 );
   SDL::Video::fill_rect(
      $surf,
      SDL::Rect->new( 0, 0, $dot_size,$dot_size ),
      SDL::Video::map_RGB( $app->format, map {rand( 0x100 - 0x44 ) + 0x44} (1..3) )
   );
   return $surf;
}
sub init_crate_surf {
   my $crate = shift;
   my $w = $crate->{w};
   my $h = $crate->{h};

   my $surf =
      SDL::Surface->new( SDL_SWSURFACE, $w, $h, 32, 0, 0, 0,
      255 );

   SDL::Video::fill_rect(
      $surf,
      SDL::Rect->new( 0, 0, $w, $h ),
      SDL::Video::map_RGB( $app->format, 200, 200, 200 )
   );
   return $surf;
}

#from shooter.pl
# Make an initial surface for the marble
# so we only use it once
sub init_marble_surf {
   my $marble = shift;
   my $size = $marble->{radius}*2;

   #make a surface based on the size
   my $particle =
      SDL::Surface->new( SDL_SWSURFACE|SDL_SRCALPHA, $size + 15, $size + 15, 32, 0, 0, 0,
      127 );

      SDL::Video::fill_rect(
         $particle,
         SDL::Rect->new( 0, 0, $size + 15, $size + 15 ),
         SDL::Video::map_RGBA( $app->format, 0,0,0,127 )
      );

   #draw a circle on it with a random color
   SDL::GFX::Primitives::filled_circle_color( $particle, $size / 2, $size / 2,
      $size / 2 - 2,
      rand_color() );

   SDL::GFX::Primitives::aacircle_color( $particle, $size / 2, $size / 2,
      $size / 2 - 2, 0x000000FF );
   SDL::GFX::Primitives::aacircle_color( $particle, $size / 2, $size / 2,
      $size / 2 - 1, 0x000000FF );
   
   my $pixel = SDL::Color->new( 0, 0, 0 );
   SDL::Video::set_color_key( $particle, SDL_SRCCOLORKEY, $pixel );
   $particle = SDL::Video::display_format_alpha($particle);
   
   return $particle;
}

#Gets a random color for our particle
sub rand_color {
    my $r = rand( 0x100 - 0x44 ) + 0x44;
    my $b = rand( 0x100 - 0x44 ) + 0x44;
    my $g = rand( 0x100 - 0x44 ) + 0x44;

    return ( 0x000000FF | ( $r << 24 ) | ( $b << 16 ) | ($g) << 8 );

}
