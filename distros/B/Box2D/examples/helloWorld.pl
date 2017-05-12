use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDLx::App;

my $app = SDLx::App->new( width => 300, height => 300, flags => SDL_DOUBLEBUF | SDL_HWSURFACE, eoq => 1 );

my $vec = Box2D::b2Vec2->new(2.5,-10);
my $world = Box2D::b2World->new($vec, 1);

my $body_def = Box2D::b2BodyDef->new();

$body_def->position->Set(0.0, -2.0);

my $groundBody = $world->CreateBody($body_def); 

my $groundBox = Box2D::b2PolygonShape->new();

$groundBox->SetAsBox(50.0, 10.0);

$groundBody->CreateFixture( $groundBox, 0.0 ); 

my $pos = $groundBody->GetPosition();

$app->update();

my $bodyDef = Box2D::b2BodyDef->new();
$bodyDef->type(Box2D::b2_dynamicBody);
$bodyDef->position->Set(0.0, 100.0);

my $body = $world->CreateBody($bodyDef);


my $dynamicBox = Box2D::b2PolygonShape->new();
$dynamicBox->SetAsBox( 1.0, 1.0 );


my $fixtureDef = Box2D::b2FixtureDef->new();
$fixtureDef->shape( $dynamicBox );
$fixtureDef->density(1.0);
$fixtureDef->friction(0.01);


$body->CreateFixtureDef($fixtureDef);

my $timeStep = 1.0/60.0;
my $velocityIterations = 6;
my $positionIterations = 2;
$app->add_move_handler(
sub {

	$world->Step( $timeStep, $velocityIterations, $positionIterations );
	$world->ClearForces();


}
);

$app->add_show_handler( sub 
{
	$app->draw_rect([0,0,300,300],[0,0,0,255]);
	$app->draw_rect( [$pos->x(), 250-$pos->y(), 50, 10], [0,255,0,255] );
	my $position = $body->GetPosition();
	my $angle = $body->GetAngle();
warn $angle;
$app->draw_rect( [$position->x(), 250-$position->y(), 1*16, 1*16], [255,255,0,255] );
$app->update();

} );

$app->run();
