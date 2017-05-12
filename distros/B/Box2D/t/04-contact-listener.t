use strict;
use warnings;
use Box2D;
use Test::More;



for my $listenerType ("normal","TestContactListener") {
    my $vec = Box2D::b2Vec2->new(10,-10);
    my $world = Box2D::b2World->new($vec, 1);

    my $body_def = Box2D::b2BodyDef->new();

    $body_def->position->Set(0.0, -10.0);

    my $groundBody = $world->CreateBody($body_def); 

    my $groundBox = Box2D::b2PolygonShape->new();

    $groundBox->SetAsBox(50.0, 10.0);

    $groundBody->CreateFixture( $groundBox, 0.0 ); 

    my $bodyDef = Box2D::b2BodyDef->new();
    $bodyDef->type(Box2D::b2_dynamicBody);
    is( $bodyDef->type(), 2, "returning enum" );
    $bodyDef->position->Set(0.0, 4.0);

    my $body = $world->CreateBody($bodyDef);
    
    pass( "Create body for world " );
    
    my $dynamicBox = Box2D::b2PolygonShape->new();
    $dynamicBox->SetAsBox( 1.0, 1.0 );
    
    pass( "Create box" );
    
    my $fixtureDef = Box2D::b2FixtureDef->new();
    $fixtureDef->shape( $dynamicBox );
    $fixtureDef->density(1.0);
    $fixtureDef->friction(0.3);
    
    
    $body->CreateFixtureDef($fixtureDef);
    
    pass( "Create fixture Def" );
    my $timeStep = 1.0/60.0;
    my $velocityIterations = 6;
    my $positionIterations = 2;
#$world->SetContactListener( undef );
    

    my $beginContact = 0;
    my $endContact = 0;
    my $preSolve = 0;
    my $postSolve = 0;
    my $listener;
    if ($listenerType eq "normal") {
        $listener = Box2D::PerlContactListener->new();
        # if this runs at least callback fixtures work as well!
        $listener->SetBeginContactSub(
            sub { 
                #warn "BeginContact!"; warn @_;
                $beginContact++;
                my ($contact) = @_;
                my $fixA = $contact->GetFixtureA();
                my $fixB = $contact->GetFixtureB();
                #warn "$fixA $fixB";
                my $posA = $fixA->GetBody()->GetPosition();
                my $posB = $fixB->GetBody()->GetPosition();
                #warn $posA->x() . " " . $posA->y(). " ".$fixA->GetDensity();
                #warn $posB->x() . " " . $posB->y(). " ".$fixB->GetDensity();
                
            } );
        $listener->SetEndContactSub(sub { #warn "EndContact!"; warn @_;
            $endContact++;  } );
        $listener->SetPreSolveSub(sub { #warn "PreSolve!"; warn @_; 
            $preSolve++;  } );
        $listener->SetPostSolveSub(sub {# warn "PostSolve!"; warn @_; 
            $postSolve++; });
        
        #warn "In Perl Code setting listener";
        $world->SetContactListener( $listener );
    } else {
        $listener = TestContactListener->new();
        ok(  UNIVERSAL::isa($listener,"Box2D::b2ContactListener"), "Not a contactlistener??");

        #warn "Setting listener!";
        $world->SetContactListener(  $listener );
    }

    foreach ( 0.. 20000 )
    {

	$world->Step( $timeStep, $velocityIterations, $positionIterations );
	$world->ClearForces();

	my $position = $body->GetPosition();
	my $angle = $body->GetAngle();
	#warn( "Position ". $position->x(). ", ". $position->y() ."\n" );
	#warn( "Angle ".$angle."\n");
    }

    if ($listenerType ne "normal") {
        $beginContact = $listener->{BeginContact};
        $endContact = $listener->{EndContact};
        $preSolve = $listener->{PreSolve};
        $postSolve = $listener->{PostSolve};

    }

    ok( $beginContact > 0, "beginContact doesn't work? $beginContact");
    ok( $endContact > 0, "endContact doesn't work?");
    ok( $preSolve > 0, "preSolve doesn't work?");
    # disabling postSolve test til I understand it more
    ok( $postSolve > 0, "postSolve doesn't work?");
    

    pass( "Run step and clear forces");

    pass("Made stuff and survived");

    $world->DestroyBody( $body );
    $body = undef;
    pass("Destroyed the body");

}

done_testing;

1;
package TestContactListener;
use Box2D;
#use Box2D::b2ContactListener;
use base qw(Box2D::b2ContactListener);

sub BeginContact {
    my ($self, $contact) = @_;
    #warn "TestContact BeginContact";
    $self->{BeginContact}++;
}
sub EndContact {
    my ($self, $contact) = @_;
    #warn "TestContact EndContact";
    $self->{EndContact}++;
}
sub PreSolve {
    my ($self) = @_;
    #warn "TestContact PreSolve";
    $self->{PreSolve}++;
}
sub PostSolve {
    my ($self) = @_;
    #warn "TestContact PostSolve";
    $self->{PostSolve}++;
}
        
1;
