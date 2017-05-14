#!/usr/bin/perl -w
  use strict;

=head1 NAME

Invaders -- A Space Invaders Game

=head1 DESCRIPTION

  A small application to test out a Sprite class that I'm using 
  for another project.  The documentation applies to the Sprite
  class.  The NOTES below will address the game, as well as inline
  coments.

  (c) Clinton Pierce 2001

  Feel free to redistribute.  Enjoy!

=head1 EXAMPLE

      my $s=new Sprite();
      $s->name('spaceship', 'player1');
      $s->image($shipdata);
      $s->place(10,10);
      
      if ($s->collide()=~/asteroid/) {
          $s->image($blowup, 1);
          sleep(2);
          $s->delete();
      }


=over 4

=cut

  package Sprite;

=item $Sprite::keycode

  These keypress codes work for Windows and Linux (XFree86).
  There''s problems, of course, with using these to control a 
  game.  See IMPROVEMENTS below.

=cut

  $Sprite::keycode::left=($^O=~/Win32/)?37:100;
  $Sprite::keycode::right=($^O=~/Win32/)?39:102;
  $Sprite::keycode::fire=($^O=~/Win32/)?17:37;

=item C<new>

  Create a new sprite.

=item C<names([spritenames...])>

  Assigns a name to the sprite.  Calling with no arguments
  returns the names.  Calling with a list of strings assigns those
  names to the sprite.

=item C<image(imagedata, [changeflag])>

  Create a sprite with an image.  If changeflag is true, then
  the existing sprite is overwritten with the new image.

=item C<delete>

  Remove the sprite

=item C<draw( createPolygon_args... )>

  Calls createPolygon to draw a new object here.

=item C<place( x, y )>

  Place the image at the specified location.

=item C<collide>

  Will return a string of comma-separated sprite names that the 
  current object is touching.  So if:
      
      $rocketship->collide()=~/asteroid/

  You''d want to blow up.  Note: You''re always in collision with
  yourself.

=back


=cut 

  sub new {
      my($class, $canvas)=@_;
      my $self={ canvas => $canvas, id => "", names => []  };
      bless $self, $class;
  }
  sub names {
      my($self,@names)=@_;
      return @{$self->{names}} unless (@names);
      $self->{names}=[@names];
      foreach(@names) {
          $self->{canvas}->addtag($_, 'withtag', $self->{id} );
      }
  }
  sub image {
      my($self, $bitmap, $change)=@_;  # -data takes base-64 encoded.
      my $pic=$self->{canvas}->Photo(-data => $bitmap, -format => 'gif');
      $self->{picture}=$pic;
      if (! $change) {
          $self->{id}=$self->{canvas}->createImage(0, 0,
              -image => $pic, -tags => [ @{$self->{names}} ]);
      } else {
          $self->{canvas}->itemconfigure($self->{id}, -image => $pic);
      }
  }
  sub remove { $_[0]->{canvas}->delete($_[0]->{id}); }
  sub draw {
      my($self,@args)=@_;
      $self->{id}=$self->{canvas}->createPolygon(@args,
          -tags => [ @{$self->{names}} ]);
  }
  sub place {
      my($self, $x, $y)=@_;
      if (! defined $x) {
          return(@{$self->{coord}});
      }
      $self->{canvas}->coords($self->{id}, $x, $y);
      $self->{coord}=[$x,$y];
  }

  sub collide {
      join ',', map
              { $_[0]->{canvas}->gettags($_) }
          $_[0]->{canvas}->find('overlapping',
              $_[0]->{canvas}->bbox(($_[0]->names)[0]));
  }

=head1 GAME

  Left/Right arrow moves the ship, Control key fires.  Alien
  bombs or aliens reaching the bottom of the screen will kill you.
  To reset, kill the app and start again.

=head1 IMPROVEMENTS

  All kinds of improvements can be made trivially
  (with 3 or fewer lines of code):

      * limited number of shots onscreen at once.
            (this cures one sure-fire winning strategy.)
      * make aliens shoot more when there are fewer 
        of them.
      * make aliens faster when there are fewer of
        them.
      * "mothership" hovering above for bonus points
      * animate the aliens.
      * missles should have some momentum after being 
        released.
            (this kills the other.)
      * missles should themselves blow up

  Some less trivially (still fewer than 20 lines):

      * independant movement of aliens left/right,
        up/down
      * "galaxian" style swooping aliens
      * multiple lives
      * etc...

  Control difficulties:

      * Pressing "fire" stops left/right movement.
        perhaps someone with a better understanding of
        X11/Tk key bindings can help with this.

=cut

  package main;

use Tk;
use Tk::Photo;
my $id=0;
my $left=5;
my $right=300;
my $top=10;
my $bot=280;
my $alienmove=2;
my $score=0;
my $mw=new MainWindow();
my $c=$mw->Canvas(-background => 'black', -height => $bot,
       -width => $right)->pack(-fill => 'both', -expand => 'true');
my($f,%img)=("");
  while(<DATA>) {
      chomp;
      if (/^begin\s(.*)/) { $f=$1; next; }
      if (/^N(\d+)N$/) {  $_.=("/"x78)x$1; } # Compression
      $img{$f}.=$_;
  }

  # Left & right edges
  my $le=new Sprite($c);
  $le->draw($left,$top,$left,$bot,$left+1,$bot,$left+1,$top,$left,$top, -fill => 'black');
  $le->names('left');
  my $re=new Sprite($c);
  $re->draw($right,$top,$right,$bot,$right+1,$bot,$right+1,$top,$right,$top, -fill => 'black');
  $re->names('right');
  my $be=new Sprite($c);
  $be->draw(0,230,$right,230);
  $be->names('bottom');
  $c->createText($right/2,10, -text => $score, -tags => [ 'score' ], -fill => 'white');

  my @missles;
  # Missles go up and down here, are removed if offscreen
  sub missles {
      my @di=();
      for(@missles) {
          ($t::x,$t::y)=$_->{sprite}->place;
          $t::y+=$alienmove*4*$_->{direction};
          $_->{sprite}->place($t::x,$t::y);
          if ($t::x<$left or $t::y<$top or
              $t::x>$right or $t::y>$bot) {
              $_->{sprite}->remove;
          } else {
              push(@di, $_);
          }
      }
      @missles=@di;
  }

  # My ship and Controls
  my $ship=new Sprite($c);
  $ship->image($img{"ship1.gif"});
  $ship->names("me");
  $ship->place(30,250);
  $mw->bind('<Key>', [ sub {
      ($t::x,$t::y)=$ship->place;
      if ($_[1] == $Sprite::keycode::right) { $t::x2=$t::x+5; }
      elsif ($_[1] == $Sprite::keycode::left ) { $t::x2=$t::x-5; }
      elsif ($_[1] == $Sprite::keycode::fire ) {
          my $gun=new Sprite($c);
          $gun->image($img{"missle.gif"});
          $gun->names("missle","weapon");
          $gun->place($t::x, $t::y);
          push(@missles, {
              direction => -1,
              sprite => $gun,
              });
      }
      else { return; }
      $ship->place($t::x2,$t::y);
      if ( $ship->collide =~/right|left/) {
          $ship->place($t::x,$t::y);
      } }, Ev('k') ] );

  # Enemies
  my @badguys=();
  my $direction=1;    # Pos is right
  my $deathdelay=-3;  # How long splat is visible
  my $startrow=50;
  sub mkbadguys {
      @badguys=();
      $c->delete('alien');
      $c->delete('weapon');
      for my $t (1..2) {
          for my $i (1..9) {
              push(@badguys, { sprite=> new Sprite($c) });
              for($badguys[-1]) {
                  $_->{sprite}->image($img{"alien.gif"});
                  $_->{sprite}->place(25*$i, $startrow+$t*25);
                  $_->{sprite}->names("alien$t$i","alien");
              }
          }
      }
      $startrow+=10;
  }
  sub maint {
      march();
      missles();
      $c->update;
      if ($ship->collide=~/bomb/ or $be->collide=~/alien/) {
          $ship->image($img{"splat.gif"},1);
          $c->createText(100,10,-text => "Game Over");
          $mw->bind('<Key>', undef);
      } elsif (!@badguys) {
          mkbadguys();
          $c->after(100, \&maint);
      } else {
          $c->after(100, \&maint);
      }
  }
  my $downrow;
  sub march {
      my($collisions,$alive)=(0,0);
      for (@badguys) {
          delete $_->{oldloc};
          if ($_->{dead} && $_->{dead}<0 ) {
              if ($_->{dead} == $deathdelay) {
                  $_->{sprite}->names("");
                  $_->{sprite}->image($img{"splat.gif"},1);
                  $_->{dead}++;
                  $c->itemconfigure('score', -text => $score);
              }
              unless (++$_->{dead}) {
                  $_->{sprite}->remove;
                  $_->{dead}++;
              }
          }
          $alive++ unless $_->{dead};
      }
      @badguys=() unless $alive;
      for (@badguys) {
          next if $_->{dead};
          $_->{oldloc}=[ $_->{sprite}->place ];
          ($t::x, $t::y)=@{ $_->{oldloc} };
          $t::x+=$alienmove*$direction;
          $t::y+=$alienmove*4 if ($downrow);
          $_->{sprite}->place($t::x,$t::y);
          $a=$_->{sprite}->collide;
          if ($a=~/right|left/) {
              $collisions=1; last;
          }
          if ($a=~/missle/) {
              $_->{dead}=$deathdelay;
              $score+=10;
          }
          if (rand(1000)<5) {
              my $gun=new Sprite($c);
              $gun->image($img{"bomb.gif"});
              $gun->names("bomb","weapon");
              $gun->place($t::x, $t::y);
              push(@missles, { direction => 1, sprite => $gun, });
          }
      }
      $downrow=0;
      if ($collisions) {
          for(@badguys) {
              next if $_->{dead};
              next unless $_->{oldloc};
              $_->{sprite}->place(@{$_->{oldloc}});
          }
          $downrow=$direction*=-1;
      }
  }
  mkbadguys();
  $c->after(100, \&maint);
  $mw->MainLoop;

__DATA__
begin ship1.gif
R0lGODlhFAAUAPcAAAAAADH/796l9/echPf/GP8pEP//////////////////////////////////
N12N
/////////////////////////////////////////////////////ywAAAAAFAAUAAAIcwABCBw4
0ADBgwgLCjCYsKEBARAZNjz4MOJEihAzSpxYcaHGiwAqGggg8qIBkSQjbsQYMaXFhB0Xnsy4EGFM
mjhXdjz5kOdHhRYLEBBAoEDIn0drAhggtMAAgSWTbmT6FKjBngirEsR6EuTWlV7Dih0rMCAAOw==
begin alien.gif
R0lGODlhFAAUAPcAAAAAAADWEBiECKX37/9KGP//EP//////////////////////////////////
N12N
/////////////////////////////////////////////////////ywAAAAAFAAUAAAIfAABCAQw
YMDAgwQNIiwoUOFBhQwHOiT4sCJCAQUzahwgAGFDAAIEEChAsgCBkBQfkiTAsqTJlgUmDnBJk6ZM
lwEKBMiZs+TEhCV79oz5U+JMm0U9bkzqMaHGpkoNMowINWNDiFQXPpTZNKvXoj+zpjS6MCxWs2I3
lr1aNiAAOw==
begin bomb.gif
R0lGODlhCgAKAPcAAAAAAP//////////////////////////////////////////////////////
N12N
/////////////////////////////////////////////////////ywAAAAACgAKAAAIJAABAAgg
cGDBgwQPCkxoEKFBhg4VNpxYkCDEhgkvWpTIkGFAAAA7
begin missle.gif
R0lGODlhCgAKAPcAAAAAAKXn9/8pEP//GP//////////////////////////////////////////
N12N
/////////////////////////////////////////////////////ywAAAAACgAKAAAIMAABCAQQ
IMDAgwYJHhSYMCFChgsLMnRosKHCghgzJhQwQABHAQc7euS4EMCAAQcDAgA7
begin splat.gif
R0lGODlhCgAKAPcAAAAAAOfvAP9CAP/GSv/nEP//////////////////////////////////////
N12N
/////////////////////////////////////////////////////ywAAAAACgAKAAAIQAABCAxA
AMCAAAEAJBRgEEBBhRAFDJA4oCBCAgIkMnzocKLGiA4lWkw4oOJEAAwhJiQ4wKHAhwcRCpzZcqbA
gAAAOw==
