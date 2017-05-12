package My::RayCastCallback;
use strict;
use warnings;
use Box2D;

use base qw(Box2D::b2RayCastCallback);

sub new {
    my ( $class, $objects ) = @_;

    my $self = $class->SUPER::new();

    $self->{objects} = $objects;

    return bless $self, $class;
}

sub ReportFixture {
    my ( $self, $fixture, $point, $normal, $fraction ) = @_;

    my $id = $fixture->GetUserData();

    $self->{objects}->[$id]->{color} = 0xFF0000FF;

    return 0;
}

package main;
use strict;
use warnings;
use List::Util qw(min);
use Math::Trig qw(:pi);
use SDLx::App;
use Box2D;

my $width  = 400;
my $height = 400;

my $fps      = 60;
my $timestep = 1 / $fps;

my $gravity = Box2D::b2Vec2->new( 0, 0 );
my $world = Box2D::b2World->new( $gravity, 1 );

my %radar = (
    x     => $width / 2,
    y     => $height / 2,
    r     => min( $width / 2, $height / 2 ),
    theta => 0,
    speed => 0.01,
);

my @objects;

for ( 0 .. 20 ) {
    my $object = make_object();

    # Record index in @objects
    $object->{fixture}->SetUserData($_);

    push @objects, $object;
}

my $rayCastCallback = My::RayCastCallback->new( \@objects );

my $app = SDLx::App->new(
    w     => $width,
    h     => $height,
    dt    => $timestep,
    min_t => $timestep,
    delay => $timestep * 900,
    eoq   => 1,
);

$app->add_move_handler(
    sub {
        my ($step) = @_;

        $radar{theta} += $radar{speed} * $step;

        my $p1 = Box2D::b2Vec2->new( @radar{qw( x y )} );
        my $p2 = Box2D::b2Vec2->new(
            $p1->x + $radar{r} * cos( $radar{theta} ),
            $p1->y + $radar{r} * sin( $radar{theta} )
        );
        $world->RayCast( $rayCastCallback, $p1, $p2 );
    }
);

$app->add_show_handler(
    sub {

        # Clear surface
        $app->draw_rect( undef, 0 );

        draw_polygon($_) for @objects;
        draw_radar( \%radar );

        # Reset colors
        $_->{color} = 0xFFFFFFFF for @objects;

        $app->update();
    }
);

$app->run();

sub make_object {
    my $x = rand $width;
    my $y = rand $height;
    my $w = 10 + rand 20;
    my $h = 10 + rand 20;

    my $polygon = make_polygon( w => $w, h => $h );

    my $body = make_body( x => $x, y => $y );

    my $fixture = make_fixture(
        shape => $polygon,
        body  => $body,
    );

    return {
        shape   => $polygon,
        body    => $body,
        fixture => $fixture,
        color   => 0xFFFFFFFF,
    };
}

sub make_body {
    my (%args) = @_;
    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->position->Set( @args{qw( x y )} );
    $bodyDef->type(Box2D::b2_dynamicBody);
    $bodyDef->angle( rand pi );
    return $world->CreateBody($bodyDef);
}

sub make_polygon {
    my (%args) = @_;
    my ( $w, $h ) = @args{qw( w h )};
    my $shape = Box2D::b2PolygonShape->new();
    $shape->SetAsBox( $w / 2.0, $h / 2.0 );
    return $shape;
}

sub make_fixture {
    my (%args) = @_;
    my ( $shape, $body ) = @args{qw( shape body )};
    return $body->CreateFixture( $shape, 1.0 );
}

sub draw_radar {
    my ($radar) = @_;

    my @p1 = @radar{qw( x y )};
    my @p2 = (
        $p1[0] + $radar{r} * cos( $radar{theta} ),
        $p1[1] + $radar{r} * sin( $radar{theta} )
    );

    $app->draw_line( \@p1, \@p2, 0xFFFFFFFF, 1 );
}

sub draw_polygon {
    my ($polygon) = @_;

    my ( $shape, $body, $color ) = @$polygon{qw( shape body color )};

    my @verts = map { [ $_->x, $_->y ] }
        map { $body->GetWorldPoint( $shape->GetVertex($_) ) }
        ( 0 .. $shape->GetVertexCount() - 1 );

    $app->draw_polygon_filled( \@verts, $color );
}

