use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDLx::App;
use SDL::Events ':all';

my $WIDTH = 300;
my $HEIGHT = 300;

# record the mouse info
my %mouse = ( X => 0, Y =>0, left => 0);

my $app = SDLx::App->new( 
	dt => 1.0/60,
	min_t => 1.0/120,
	width => $WIDTH, height => $HEIGHT, flags => SDL_DOUBLEBUF | SDL_HWSURFACE, eoq => 1 
);

# default forces 0 x and -10 y
my $vec = Box2D::b2Vec2->new(0,-10);

# start the world
my $world = Box2D::b2World->new($vec, 1);

# update the app
$app->update();

# this will store the falling bodies
my @bodies = ();
my $bodySize = 8.0;
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
    push @bodies, $body;
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
                           my @nextbodies = ();
                           my @deletebodies = ();
                           foreach my $body (@bodies) {
                               my $pos = $body->GetPosition();
                               my ($x,$y) = ($pos->x(), $pos->y());
                               my $angle = $body->GetAngle();
                               # print join(" ",$position->x(),$position->y(),$angle,$/);
                               $app->draw_rect( [$x - $bodySize, 
                                                 $HEIGHT - $y - $bodySize, 
                                                 $bodySize*2, $bodySize*2], 
                                                [255,255,0,255] );
                               # arbitrary threshold before we delete an object;
                               if ($y > -200) {
                                   push @nextbodies, $body;
                               }
                           }
                           @bodies = @nextbodies;
                           # DestroyBody is dangerous, you want to destroy it in perl pretty quickly too
                           while (@deletebodies) {
                               $world->DestroyBody(pop @deletebodies);
                           }


                           $app->update();
                           
                       }
                      );

# run the application
$app->run();
