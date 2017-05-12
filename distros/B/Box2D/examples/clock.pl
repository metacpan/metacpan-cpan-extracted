# This example uses b2RevoluteJoint and it's motor feature to simulate a
# clock. Instead of showing the correct time, which would be boring, the
# clock hand move wildly. A collision group is also used to demonstrate
# how to prevent collisions using a group index. Without this feature,
# the clock hands would collide with one another.
use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDL::GFX::Primitives;
use SDLx::App;

# pixels
my $width  = 300;
my $height = 300;

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

my $gravity = Box2D::b2Vec2->new( 0, -10.0 );
my $world = Box2D::b2World->new( $gravity, 1 );

my $pivot = {
    x0     => s2w( $width / 2 ),
    y0     => s2w( $height / 2 ),
    radius => s2w(4),
    color  => 0x3F5400FF,
};
$pivot = { %$pivot, %{ make_static_circle( @$pivot{qw( x0 y0 radius )} ) } };

my $anchor = Box2D::b2Vec2->new( @$pivot{qw( x0 y0 )} );

my $hourHand = {
    x0    => s2w( $width / 2 - 2 ),
    y0    => s2w( $height / 2 ),
    w     => s2w(5),
    h     => s2w(70),
    color => 0x3F5400FF,
};
$hourHand
    = { %$hourHand, %{ make_dynamic_rect( @$hourHand{qw( x0 y0 w h )} ) } };

my $minuteHand = {
    x0    => s2w( $width / 2 - 1 ),
    y0    => s2w( $height / 2 - 110 ),
    w     => s2w(3),
    h     => s2w(110),
    color => 0x3F5400FF,
};
$minuteHand = { %$minuteHand,
    %{ make_dynamic_rect( @$minuteHand{qw( x0 y0 w h )} ) } };

my $secondHand = {
    x0    => s2w( $width / 2 ),
    y0    => s2w( $height / 2 - 10 ),
    w     => s2w(1),
    h     => s2w(120),
    color => 0x541500FF,
};
$secondHand = { %$secondHand,
    %{ make_dynamic_rect( @$secondHand{qw( x0 y0 w h )} ) } };

make_revolute_joint( $pivot->{body}, $hourHand->{body}, $anchor, 0.5, 100 );
make_revolute_joint( $pivot->{body}, $minuteHand->{body}, $anchor, -1.1,
    100 );
make_revolute_joint( $pivot->{body}, $secondHand->{body}, $anchor, 2.0, 100 );

my $app = SDLx::App->new(
    width  => $width,
    height => $height,
    dt     => $timestep,
    min_t  => $timestep / 2,
    flags  => SDL_DOUBLEBUF | SDL_HWSURFACE,
    eoq    => 1,
);

my $realFps = $fps;
my $frames  = 1;
my $ticks   = SDL::get_ticks();

$app->add_show_handler(
    sub {
        $world->Step( $timestep, $vIters, $pIters );
        $world->ClearForces();

        # clear surface
        $app->draw_rect( undef, 0x000000FF );

        draw_clock_face();
        draw_circle($pivot);
        draw_polygon($hourHand);
        draw_polygon($minuteHand);
        draw_polygon($secondHand);

        if ( $frames % $fps == 0 ) {
            my $t = SDL::get_ticks();
            $realFps = $fps / ( $t - $ticks ) * 1000;
            $ticks = $t;
        }
        $app->draw_gfx_text( [ 10, 10 ],
            0xFFFFFFFF, sprintf( "FPS: %0.2f", $realFps ) );

        $app->update();

        $frames++;
    }
);

$app->run();

# screen to world
sub s2w { return $_[0] * $mpp }

# world to screen
sub w2s { return $_[0] * $ppm }

sub make_static_circle {
    my ( $x, $y, $r ) = @_;

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->position->Set( $x, $y );
    my $body = $world->CreateBody($bodyDef);

    my $circle = Box2D::b2CircleShape->new();
    $circle->m_radius($r);

    $body->CreateFixture( $circle, 0.0 );

    return { body => $body, shape => $circle };
}

sub make_dynamic_rect {
    my ( $x, $y, $w, $h ) = @_;

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    $bodyDef->position->Set( $x + $w / 2, $y + $h / 2 );
    my $body = $world->CreateBody($bodyDef);

    my $rect = Box2D::b2PolygonShape->new();
    $rect->SetAsBox( $w / 2, $h / 2 );

    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape($rect);
    $fixtureDef->density(1.0);
    $fixtureDef->friction(0.1);

    # Fixtures with the same negative groupIndex will not collide
    # with each other.
    $fixtureDef->filter->groupIndex(-1);

    $body->CreateFixtureDef($fixtureDef);

    return { body => $body, shape => $rect };
}

sub make_revolute_joint {
    my ( $bodyA, $bodyB, $anchor, $speed, $torque ) = @_;
    my $jointDef = Box2D::b2RevoluteJointDef->new();
    $jointDef->Initialize( $bodyA, $bodyB, $anchor );
    $jointDef->enableMotor(1);
    $jointDef->motorSpeed($speed);
    $jointDef->maxMotorTorque($torque);
    $world->CreateJoint($jointDef);
}

sub draw_clock_face {
    my $x = $width / 2;
    my $y = $height / 2;
    $app->draw_circle_filled( [ $x, $y ], 140, 0x003F54FF );
    foreach ( 0 .. 11 ) {
        my $dx = cos( $_ * ( 2 * 3.14 / 12 ) ) * 120;
        my $dy = sin( $_ * ( 2 * 3.14 / 12 ) ) * 120;
        $app->draw_circle_filled( [ $x + $dx, $y + $dy ], 10, 0x150054FF );
    }
}

sub draw_circle {
    my ($circle) = @_;
    my $p = $circle->{body}->GetPosition();
    my ( $x, $y ) = ( $p->x, $p->y );
    $y = s2w($height) - $y;
    my ( $r, $c ) = @$circle{qw( radius color )};
    $app->draw_circle_filled( [ w2s($x), w2s($y) ], w2s($r), $c );
}

sub draw_polygon {
    my ($polygon) = @_;

    my ( $body, $shape, $color ) = @$polygon{qw( body shape color )};

    my @verts = map { $body->GetWorldPoint( $shape->GetVertex($_) ) }
        ( 0 .. $shape->GetVertexCount() - 1 );

    my @vx = map { w2s( $_->x ) } @verts;
    my @vy = map { w2s( $_->y ) } @verts;

    SDL::GFX::Primitives::filled_polygon_color( $app, \@vx, \@vy,
        scalar @verts, $color );
}
