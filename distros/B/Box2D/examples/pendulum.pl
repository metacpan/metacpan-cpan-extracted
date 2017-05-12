# This example uses b2DistanceJoint to simulate a pendulum.
use strict;
use warnings;
use Box2D;
use SDL;
use SDL::Video;
use SDLx::App;

my $segments = $ARGV[0] || 2;

# The number of steps to apply to each frame,
# This seems to make joint correction lose less energy.
my $precision = 40;

# pixels
my $width  = 450;
my $height = 450;

# pixels per meter
my $ppm = 30;

# meters per pixel
my $mpp = 1.0 / $ppm;

# frames per second
my $fps      = 60.0;
my $timestep = 1.0 / $fps;

# velocity iterations
my $vIters = 8;

# position iterations
my $pIters = 8;

my $gravity = Box2D::b2Vec2->new( 0, -8.0 / $precision**2 );

# no sleep. don't lose energy.
my $world = Box2D::b2World->new( $gravity, 0 );

my $rodColor  = 0x00CC70FF;
my $pathColor = 0xFFFFCFFF;

my $pivot = {
    x0     => s2w( $width / 2 ),
    y0     => s2w( $height / 2 ),
    radius => s2w(4),
    color  => 0x5CCC00FF,
};
$pivot->{body}   = make_static_circle( @$pivot{qw( x0 y0 radius )} );
$pivot->{anchor} = Box2D::b2Vec2->new( @$pivot{qw( x0 y0 )} );

my $prev_pivot = $pivot;
my @bobs;
for ( 1 .. $segments ) {

    my $bob = {
        y0 => s2w( $height / 2 + .9 * $height * $_ / ( 2 * $segments ) ),
        x0 => s2w( $width / 2 + 1 ),
        radius => s2w(6),
        color  => 0xCC005CFF,
    };
    $bob->{body}   = make_dynamic_circle( @$bob{qw( x0 y0 radius )} );
    $bob->{anchor} = Box2D::b2Vec2->new( @$bob{qw( x0 y0 )} );

    my $jointDef = Box2D::b2DistanceJointDef->new();
    $jointDef->Initialize(
        $prev_pivot->{body},   $bob->{body},
        $prev_pivot->{anchor}, $bob->{anchor}
    );

    # high frequency means less energy lost from joint correction
    $jointDef->frequencyHz( 1 / $timestep );
    $jointDef->dampingRatio(0);
    $world->CreateJoint($jointDef);

    $prev_pivot = $bob;
    push @bobs, $bob;
}

my $app = SDLx::App->new(
    width  => $width,
    height => $height,
    dt     => $timestep,
    min_t  => $timestep / 2,
    flags  => SDL_DOUBLEBUF | SDL_HWSURFACE,
    eoq    => 1,
);
my $bg = $app->duplicate;
$bg->draw_rect( [ 0, 0, $width, $height ], [ 0, 0, 0, 255 ] );

my $realFps = $fps;
my $frames  = 1;
my $ticks   = SDL::get_ticks();

# last location of end of pendulum
my $prev_path_pos;

$app->add_show_handler(
    sub {
        for (1..$precision){
            $world->Step( $timestep, $vIters, $pIters );
            $world->ClearForces();
        }
        
        my $endpoint = $bobs[$#bobs]{body}->GetPosition();
        my $current_path_pos
            = [ w2s( $endpoint->x ), w2s( s2w($height) - $endpoint->y ) ];

        # trace path on bg
        $bg->draw_line( $prev_path_pos, $current_path_pos, $pathColor )
            if $prev_path_pos;
        $prev_path_pos = $current_path_pos;

        # draw bg
        $bg->blit( $app, [ 0, 0, $width, $height ] );

        # draw 1st pendulum
        my $p1 = $pivot->{body}->GetPosition();
        my $p2 = $bobs[0]->{body}->GetPosition();
        $app->draw_line( [ w2s( $p1->x ), w2s( s2w($height) - $p1->y ) ],
            [ w2s( $p2->x ), w2s( s2w($height) - $p2->y ) ], $rodColor );

        # draw the other pendulums
        for ( 0 .. $#bobs - 1 ) {
            my $b1 = $bobs[$_]->{body}->GetPosition();
            my $b2 = $bobs[ $_ + 1 ]->{body}->GetPosition();
            $app->draw_line( [ w2s( $b1->x ), w2s( s2w($height) - $b1->y ) ],
                [ w2s( $b2->x ), w2s( s2w($height) - $b2->y ) ], $rodColor );
        }
        draw_circle($pivot);
        draw_circle($_) for @bobs;

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

    return $body;
}

sub make_dynamic_circle {
    my ( $x, $y, $r ) = @_;

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);

    $bodyDef->position->Set( $x, $y );
    my $body = $world->CreateBody($bodyDef);

    my $dynamicCircle = Box2D::b2CircleShape->new();
    $dynamicCircle->m_radius($r);

    return $body;
}

sub draw_circle {
    my ($circle) = @_;
    my $p = $circle->{body}->GetPosition();
    my ( $x, $y ) = ( $p->x, $p->y );
    $y = s2w($height) - $y;
    my ( $r, $c ) = @$circle{qw( radius color )};
    $app->draw_circle_filled( [ w2s($x), w2s($y) ], w2s($r), $c );
}
