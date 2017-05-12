use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDL::Events ':type';
use SDLx::App;

# pixels
my $width  = 400;
my $height = 400;

# pixels per meter
my $ppm = 10;

# meters per pixel
my $mpp = 1.0 / $ppm;

# frames per second
my $fps      = 60.0;
my $timestep = 1.0 / $fps;

# velocity iterations
my $vIters = 30;

# position iterations
my $pIters = 30;

my $gravity = make_vec2( 0, 9.8 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $ground = make_ground();

my $platformA = make_platform(
    x       => s2w( $width / 4.0 ),
    y       => s2w( $height / 2.0 ),
    width   => s2w( $width / 3.0 ),
    height  => s2w( $width / 20.0 ),
    density => 0.11,
    color   => 0xFF0000FF,
);

my $platformB = make_platform(
    x       => s2w( 3.0 * $width / 4.0 ),
    y       => s2w( $height / 2.0 ),
    width   => s2w( $width / 3.0 ),
    height  => s2w( $width / 20.0 ),
    density => 0.1,
    color   => 0x00FF00FF,
);

my $groundAnchorA = make_vec2( $platformA->{body}->GetWorldCenter->x,
    s2w( $height * 0.1 ) );
my $groundAnchorB = make_vec2( $platformB->{body}->GetWorldCenter->x,
    s2w( $height * 0.1 ) );

my $joint = make_pulley_joint(
    bodyA         => $platformA->{body},
    bodyB         => $platformB->{body},
    groundAnchorA => $groundAnchorA,
    groundAnchorB => $groundAnchorB,
    anchorA       => $platformA->{body}->GetWorldCenter(),
    anchorB       => $platformB->{body}->GetWorldCenter(),
    ratio         => 1.0,
    maxLengthA    => s2w( $height * 0.8 ),
    maxLengthB    => s2w( $height * 0.8 ),
);

my $app = SDLx::App->new(
    width  => $width,
    height => $height,
    dt     => $timestep,
    min_t  => $timestep / 2,
    flags  => SDL_DOUBLEBUF | SDL_HWSURFACE,
    eoq    => 1,
);

my @balls;

$app->add_event_handler(
    sub {
        my ($event) = @_;
        return unless $event->type == SDL_MOUSEBUTTONDOWN;
        my ( undef, $x, $y ) = @{ SDL::Events::get_mouse_state() };
        push @balls,
            make_ball(
            x       => s2w($x),
            y       => s2w($y),
            radius  => s2w( rand(5.0) + 5.0 ),
            color   => [ int rand(255), int rand(255), int rand(255) ],
            density => 1.0,
            );
    }
);

$app->add_show_handler(
    sub {
        $world->Step( $timestep, $vIters, $pIters );
        $world->ClearForces();

        # clear surface
        $app->draw_rect( undef, 0x000000FF );

        my ( $gA, $gB, $pA, $pB ) = map { [ w2s( $_->x ), w2s( $_->y ) ] } (
            $groundAnchorA, $groundAnchorB,
            $platformA->{body}->GetWorldCenter,
            $platformB->{body}->GetWorldCenter
        );
        $app->draw_line( $gA, $gB, 0xFFFFFFFF );
        $app->draw_line( $pA, $gA, 0xFFFFFFFF );
        $app->draw_line( $pB, $gB, 0xFFFFFFFF );

        draw_polygon($platformA);
        draw_polygon($platformB);

        draw_circle($_) foreach @balls;

        $app->update();
    }
);

$app->run();

# screen to world
sub s2w { return $_[0] * $mpp }

# world to screen
sub w2s { return $_[0] * $ppm }

sub make_vec2 {
    my ( $x, $y ) = @_;
    return Box2D::b2Vec2->new( $x, $y );
}

sub make_ground {
    my $body = make_body(
        x => $width / 2.0,
        y => $height,
    );
    my $edge
        = make_edge( [ 0.0, s2w($height) ], [ s2w($width), s2w($height) ] );
    my $fixture = make_fixture(
        shape => $edge,
        body  => $body,
    );
    return {
        shape   => $edge,
        body    => $body,
        fixture => $fixture,
    };
}

sub make_platform {
    my (%options) = @_;
    my ( $x, $y, $w, $h, $density )
        = @options{qw( x y width height density )};

    my $body = make_body(
        x    => $x,
        y    => $y,
        type => 'dynamic',
    );

    my $rect = make_rect(
        width  => $w,
        height => $h,
    );

    my $fixture = make_fixture(
        shape   => $rect,
        body    => $body,
        density => $density,
    );

    return {
        body   => $body,
        shape  => $rect,
        fiture => $fixture,
        color  => $options{color},
    };
}

sub make_ball {
    my (%options) = @_;
    my ( $x, $y, $r, $d ) = @options{qw( x y radius density )};

    my $body = make_body(
        x    => $x,
        y    => $y,
        type => 'dynamic',
    );

    my $circle = make_circle( radius => $r );

    my $fixture = make_fixture(
        shape   => $circle,
        body    => $body,
        density => $d,
    );

    return {
        body   => $body,
        shape  => $circle,
        fiture => $fixture,
        color  => $options{color},
    };
}

# shapes
sub make_edge {
    my ( $p1, $p2 ) = @_;
    my $edge = Box2D::b2PolygonShape->new();
    $edge->SetAsEdge( make_vec2(@$p1), make_vec2(@$p2) );
    return $edge;
}

sub make_rect {
    my (%options) = @_;
    my ( $width, $height ) = @options{qw( width height )};
    my $rect = Box2D::b2PolygonShape->new();
    $rect->SetAsBox( $width / 2, $height / 2 );
    return $rect;
}

sub make_circle {
    my (%options) = @_;
    my $circle = Box2D::b2CircleShape->new();
    $circle->m_radius( $options{radius} );
    return $circle;
}

# bodies
sub make_body {
    my (%options) = @_;
    my ( $x, $y ) = @options{qw( x y )};
    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->position->Set( $x, $y );
    $bodyDef->type(Box2D::b2_dynamicBody)
        if exists $options{type} && $options{type} eq 'dynamic';
    return $world->CreateBody($bodyDef);
}

# fixtures
sub make_fixture {
    my (%options) = @_;
    my ( $shape, $body, $density ) = @options{qw( shape body density )};
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape($shape);
    $fixtureDef->density($density);
    return $body->CreateFixtureDef($fixtureDef);
}

# joints
sub make_pulley_joint {
    my (%options) = @_;
    my $jointDef = Box2D::b2PulleyJointDef->new();
    $jointDef->Initialize(
        @options{
            qw( bodyA bodyB groundAnchorA groundAnchorB anchorA anchorB ratio )
            }
    );
    $jointDef->maxLengthA( $options{maxLengthA} );
    $jointDef->maxLengthB( $options{maxLengthB} );
    return $world->CreateJoint($jointDef);
}

# drawing
sub draw_circle {
    my ($circle) = @_;
    my ( $body, $shape, $c ) = @$circle{qw( body shape color )};
    my $p = $body->GetPosition();
    my ( $x, $y ) = ( $p->x, $p->y );
    my $r = $shape->m_radius;
    $app->draw_circle_filled( [ w2s($x), w2s($y) ], w2s($r), $c );
}

sub draw_polygon {
    my ($polygon) = @_;
    my ( $body, $shape, $color ) = @$polygon{qw( body shape color )};
    my @verts = map { [ w2s( $_->x ), w2s( $_->y ) ] }
        map { $body->GetWorldPoint( $shape->GetVertex($_) ) }
        ( 0 .. $shape->GetVertexCount() - 1 );
    $app->draw_polygon_filled( \@verts, $color );
}
