# This example is a port of Breakable.h from the Box2D Testbed. Click
# the window to create a breakable.
use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDL::Events qw(:type);
use SDLx::App;
use Math::Trig qw(:pi);

package Breakable;
use Moose;

use List::Util qw(max);
use namespace::autoclean;

# Initial coordinates, angle and size
has [qw( x y angle w h )] => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has color => (
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    default => sub { [ 255, 255, 255 ] },
);

has world => (
    is       => 'ro',
    isa      => 'Box2D::b2World',
    required => 1,
);

has body1 => (
    is      => 'ro',
    isa     => 'Box2D::b2Body',
    lazy    => 1,
    builder => '_build_body1',
);

# Used after the break
has body2 => (
    is  => 'rw',
    isa => 'Box2D::b2Body',
);

has velocity => (
    is      => 'rw',
    isa     => 'Box2D::b2Vec2',
    default => sub { Box2D::b2Vec2->new( 0.0, 0.0 ) },
);

has angularVelocity => (
    is      => 'rw',
    isa     => 'Num',
    default => 0.0,
);

has shape1 => (
    is      => 'ro',
    isa     => 'Box2D::b2PolygonShape',
    lazy    => 1,
    builder => '_build_shape1',
);

has shape2 => (
    is      => 'ro',
    isa     => 'Box2D::b2PolygonShape',
    lazy    => 1,
    builder => '_build_shape2',
);

has piece1 => (
    is      => 'ro',
    isa     => 'Box2D::b2Fixture',
    lazy    => 1,
    builder => '_build_piece1',
);

has piece2 => (
    is      => 'rw',
    isa     => 'Box2D::b2Fixture',
    lazy    => 1,
    builder => '_build_piece2',
);

has [qw( broke break )] => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has listener => (
    is      => 'ro',
    isa     => 'Box2D::PerlContactListener',
    default => sub { Box2D::PerlContactListener->new() },
);

sub BUILD {
    my ($self) = @_;
    $self->listener->SetPostSolveSub( sub { $self->PostSolve(@_) } );
    $self->world->SetContactListener( $self->listener );

    # These are lazy, but must be created now. There is probably a
    # better option than this, but I can't think of anything.
    $self->piece1;
    $self->piece2;
}

sub _build_body1 {
    my ($self) = @_;
    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    $bodyDef->position->Set( $self->x, $self->y );
    $bodyDef->angle( $self->angle );
    my $body1 = $self->world->CreateBody($bodyDef);
    return $body1;
}

sub _build_shape1 {
    my ($self) = @_;
    my $shape1 = Box2D::b2PolygonShape->new();
    $shape1->SetAsBox(
        $self->w / 4.0,
        $self->h / 2.0,
        Box2D::b2Vec2->new( -$self->w / 4.0, 0.0 ), 0.0
    );
    return $shape1;
}

sub _build_shape2 {
    my ($self) = @_;
    my $shape2 = Box2D::b2PolygonShape->new();
    $shape2->SetAsBox(
        $self->w / 4.0,
        $self->h / 2.0,
        Box2D::b2Vec2->new( $self->w / 4.0, 0.0 ), 0.0
    );
    return $shape2;
}

sub _build_piece1 {
    my ($self) = @_;
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape1 );
    $fixtureDef->density(0.5);
    $fixtureDef->friction(0.5);
    $fixtureDef->restitution(0.5);
    return $self->body1->CreateFixtureDef($fixtureDef);
}

sub _build_piece2 {
    my ($self) = @_;
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape2 );
    $fixtureDef->density(0.5);
    $fixtureDef->friction(0.5);
    $fixtureDef->restitution(0.5);
    return $self->body1->CreateFixtureDef($fixtureDef);
}

sub PostSolve {
    my ( $self, $contact, $impulse ) = @_;

    return if $self->broke;

    my $maxImpulse = max( map { $impulse->normalImpulses($_) }
            ( 0 .. $contact->GetManifold()->pointCount() - 1 ) );

    $self->break(1) if $maxImpulse > 1.0;
}

sub Break {
    my ($self) = @_;

    my $body1  = $self->body1;
    my $center = $body1->GetWorldCenter();

    $body1->DestroyFixture( $self->piece2 );

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    my $p = $body1->GetPosition();
    $bodyDef->position->Set( $p->x, $p->y );
    $bodyDef->angle( $body1->GetAngle() );

    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $self->shape2 );
    $fixtureDef->density(1.0);
    $fixtureDef->restitution(0.5);
    my $body2 = $self->world->CreateBody($bodyDef);
    $self->piece2( $body2->CreateFixtureDef($fixtureDef) );

    my $center1 = $body1->GetWorldCenter();
    my $center2 = $body2->GetWorldCenter();

    my $velocity1 = Box2D::b2Math::b2CrossSV2( $self->angularVelocity,
        $center1 - $center );
    my $velocity2 = Box2D::b2Math::b2CrossSV2( $self->angularVelocity,
        $center2 - $center );

    $body1->SetAngularVelocity( $self->angularVelocity );
    $body1->SetLinearVelocity($velocity1);

    $body2->SetAngularVelocity( $self->angularVelocity );
    $body2->SetLinearVelocity($velocity2);

    $self->body2($body2);
}

sub Step {
    my ($self) = @_;

    if ( $self->break ) {
        $self->Break();
        $self->broke(1);
        $self->break(0);
    }

    if ( !$self->broke ) {
        $self->velocity( $self->body1->GetLinearVelocity() );
        $self->angularVelocity( $self->body1->GetAngularVelocity() );
    }
}

__PACKAGE__->meta->make_immutable();

package main;

# screen dimensions in pixels
my ( $width, $height ) = ( 300, 300 );

# pixels per meter
my $ppm = 30;

# meters per pixel
my $mpp = 1.0 / $ppm;

# frames per second
my $fps      = 60.0;
my $timestep = 1.0 / $fps;

# velocity iterations
my $vIters = 10;

# position iterations
my $pIters = 10;

my $gravity = Box2D::b2Vec2->new( 0, 9.8 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $ground = make_ground();

my @breakables;

my $app = SDLx::App->new(
    width  => $width,
    height => $height,
    dt     => $timestep,
    min_t  => $timestep / 2,
    flags  => SDL_DOUBLEBUF | SDL_HWSURFACE,
    eoq    => 1,
);

$app->add_event_handler(
    sub {
        my ( $event, $app ) = @_;
        return unless $event->type == SDL_MOUSEBUTTONDOWN;
        my ( undef, $x, $y ) = @{ SDL::Events::get_mouse_state() };
        push @breakables, make_breakable( $x, $y );
    }
);

$app->add_show_handler(
    sub {
        $_->Step() foreach @breakables;
        $world->Step( $timestep, $vIters, $pIters );
        $world->ClearForces();

        $app->draw_rect( undef, 0x000000FF );
        draw_breakable($_) foreach @breakables;
        $app->update();
    }
);

$app->run();

# screen to world
sub s2w { return $_[0] * $mpp }

# world to screen
sub w2s { return $_[0] * $ppm }

sub make_breakable {
    my ( $x, $y ) = @_;

    my $breakable = Breakable->new(
        world => $world,
        x     => s2w($x),
        y     => s2w($y),
        angle => rand(pi),
        w     => s2w( 20.0 + rand(20.0) ),
        h     => s2w( 20.0 + rand(20.0) ),
        color => [ int rand(255), int rand(255), int rand(255) ],
    );

    return $breakable;
}

sub make_ground {
    my $bodyDef = Box2D::b2BodyDef->new();
    my $ground  = $world->CreateBody($bodyDef);
    my $shape   = Box2D::b2PolygonShape->new();

    $shape->SetAsEdge(
        Box2D::b2Vec2->new( 0.0,         s2w($height) ),
        Box2D::b2Vec2->new( s2w($width), s2w($height) ),
    );
    $ground->CreateFixture( $shape, 0.0 );

    return $ground;
}

sub draw_breakable {
    my ($breakable) = @_;

    my @parts = (
        [ $breakable->body1, $breakable->shape1 ],
        [   $breakable->broke ? $breakable->body2 : $breakable->body1,
            $breakable->shape2
        ]
    );

    foreach my $part (@parts) {
        my ( $body, $shape ) = @$part;

        my @verts = map { [ w2s( $_->x ), w2s( $_->y ) ] }
            map { $body->GetWorldPoint( $shape->GetVertex($_) ) }
            ( 0 .. $shape->GetVertexCount() - 1 );

        $app->draw_polygon_filled( \@verts, $breakable->color );
    }
}

