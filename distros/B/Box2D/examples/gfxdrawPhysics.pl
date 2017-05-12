use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDLx::App;
use SDLx::Sprite;
use SDL::Events ':all';

use Math::Trig 'rad2deg';

my $WIDTH = 300;
my $HEIGHT = 300;

# record the mouse info
my %mouse = ( X => 0, Y =>0, left => 0);

my $app = SDLx::App->new( 
	dt => 1.0/60,
	min_t => 1.0/120,
	width => $WIDTH, height => $HEIGHT, flags => SDL_DOUBLEBUF | SDL_HWSURFACE, eoq => 1 
);

# Box sprite
my $bodySurface = SDLx::Surface->new( width => 20, height => 20 ); 

$bodySurface->draw_rect( [2,2,18,18], [255,255,0,255]);
$bodySurface->update(); 



# default forces 0 x and -10 y
my $vec = Box2D::b2Vec2->new(0,-10);

# start the world
my $world = Box2D::b2World->new($vec, 1);

# update the app
$app->update();

# this will store the falling bodies
my %bodies = ();
my $bodyCount = 0; 
my $bodySize = 10.0;


sub makeBody {
    my ($x, $y) = @_;
    # make a new body definition
    # this is the structure that stores the physics info
    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    # set position
    $bodyDef->position->Set( $x, $y );
    
    # create the body from that definition
    my $body = $world->CreateBody($bodyDef);
    
    # It's a polygonal shape 16x16
    # this is the shape information that the fixture holds
    my $dynamicBox = Box2D::b2PolygonShape->new();
    $dynamicBox->SetAsBox( $bodySize, $bodySize );
    
    # make the fixture
    my $fixtureDef = Box2D::b2FixtureDef->new();
    # the shape
    $fixtureDef->shape( $dynamicBox );
    # the density
    $fixtureDef->density(0.1 + 2*rand());
    # friction
    $fixtureDef->friction(0.1+0.9*rand());
    # attach fixture to body to give it properties and shape
    $body->CreateFixtureDef($fixtureDef);
    # record the body
     $bodies{ $bodyCount++ } = $body; 

	$body->SetUserData( sub{ warn "Ok so subroutines can be done: Body count".$bodyCount; } );
	 
    return $body;
}

# simulation timestep
my $timeStep = 1.0/60.0;
# iterate to solve velocity
my $velocityIterations = 6;
# position solver
my $positionIterations = 3;

# if a key is pressed down, make a body under the mouse!
$app->add_event_handler( 
	sub{
		my ($event, $app) = @_;
		return 0 unless ($event->type == SDL::Events::SDL_KEYDOWN);
                # note Y is flipped
		makeBody( $mouse{X}, $HEIGHT - $mouse{Y}  );
	}
);

# radius of ground boxes (walls)
my $groundRad = 8.0;
# store the walls
my @walls = ();
sub makeGround {
    my ($x,$y) = @_;
    my $body_def = Box2D::b2BodyDef->new();
    
    my ($grx, $gry) = ($x, $y);
    my ($grw, $grh) = ( $groundRad, $groundRad);

    # position of ground
    $body_def->position->Set( $grx, $gry );

    # create body from definition
    my $groundBody = $world->CreateBody($body_def); 

    # set the shape as a box
    my $groundBox = Box2D::b2PolygonShape->new();
    $groundBox->SetAsBox( $grw, $grh );

    # attach the fixture
    $groundBody->CreateFixture( $groundBox, 0.0 ); 
    
    # record the wall
    push @walls, $groundBody;
    return $groundBody;
    
}

# 
$app->add_event_handler( 
	sub{
		my ($event, $app) = @_;
                my $type = $event->type;
		return 0 unless ($type == SDL::Events::SDL_MOUSEMOTION || $type == SDL::Events::SDL_MOUSEBUTTONUP || $type == SDL::Events::SDL_MOUSEBUTTONDOWN);

                # update mouse state
                my ($mask,$x,$y) = @{ SDL::Events::get_mouse_state( ) };
                $mouse{X} = $x;
                $mouse{Y} = $y;
                my $left = ($mask & SDL_BUTTON_LMASK);
                $mouse{left} = $left;
                
                # draw walls if dragging
                if ($left) {
                    push @walls, makeGround( $x, $HEIGHT - $y);
                }
	}
);



my $listener = Box2D::PerlContactListener->new();
my $beginContact = 0;
my $endContact = 0;
my $preSolve = 0;
my $postSolve = 0;

# These listeners fire when a contact occurs

$listener->SetBeginContactSub(
	sub { 
		my $contact = shift; 
		my $fix_a = $contact->GetFixtureA(); 
		my $fix_b = $contact->GetFixtureB();   
		my $body_a = $fix_a->GetBody();
		my $body_b = $fix_b->GetBody(); 


		my $sub_a =  $body_a->GetUserData(); 
		$sub_a->() if $sub_a;
		my $sub_b = $body_b->GetUserData();
		$sub_b->() if $sub_b;
		$beginContact++;  } 
	);
$listener->SetEndContactSub(sub {  $endContact++;  } );
#$listener->SetPreSolveSub(sub { warn "PreSolve!"; warn @_; $preSolve++;  } );
#$listener->SetPostSolveSub(sub { warn "PostSolve!"; warn @_; $postSolve++; });

$world->SetContactListener( $listener );


$app->add_show_handler( 
                       sub {
                           
                           # simulate 
                           $world->Step( $timeStep, $velocityIterations, $positionIterations );
                           $world->ClearForces();

                           # draw walls
                           $app->draw_rect([0,0,$WIDTH,$HEIGHT],[0,0,0,255]);
                           foreach my $wall (@walls) {
                               my $pos = $wall->GetPosition();
                               my ($x,$y) = ($pos->x(), $pos->y());
                               # draw around the middle of the object
                               $app->draw_rect( [$x - $groundRad, 
                                                 $HEIGHT-$y-$groundRad, 
                                                 $groundRad*2, $groundRad*2], 
                                                [0,255,0,255] );
                           }

                           # draw bodies
                           foreach (keys %bodies) {
							   my $body_n = $_; 
							   my $body = $bodies{$body_n};
                               my $position = $body->GetPosition();
                               my $angle = rad2deg($body->GetAngle());
							# Box sprite
							my $bodySprite = SDLx::Sprite->new( surface => $bodySurface );

								if( $HEIGHT - $position->y()  > 308 )
								{
								
									$world->DestroyBody($body); 
									delete $bodies{$body_n}; 
								}
								$bodySprite->rotation($angle, 1);
								$bodySprite->draw_xy( $app, $position->x() - $bodySize, 
                              						  $HEIGHT-$position->y()-$bodySize );

                           }
                           $app->update();
                           
                       }
                      );

# run the application
$app->run();
