use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Dialog::Function;
use base qw/Wx::Dialog/;

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'How does a Harmonograph work?' );
    my @lblb_pro = ( [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL );
    my $f1 = Wx::StaticText->new( $self, -1, 'The classic Harmonograph is sturdy metal rack which does not move while 3 pendula swing independently.' );
    my $f2 = Wx::StaticText->new( $self, -1, 'Let us call the first pendulum X, because it only moves along the x-axis (left to right and back).' );
    my $f3 = Wx::StaticText->new( $self, -1, 'In the same fashion the second (Y) only moves up and down. When both are connected to a pen, ' );
    my $f4 = Wx::StaticText->new( $self, -1, 'we get a combination of both movements. As long as X and Y swing at the same speed, the result' );
    my $f5 = Wx::StaticText->new( $self, -1, 'is a diagonal line. Because when X goes right Y goes up and vice versa.' );
    my $f6 = Wx::StaticText->new( $self, -1, 'But if we start one pendulum at the center and the other at the upmost position we get a circle.' );
    my $f7 = Wx::StaticText->new( $self, -1, 'In other words: we added an offset of 90 degrees to Y (or X). Our third pendulum Z moves the paper' );
    my $f8 = Wx::StaticText->new( $self, -1, 'and does exactly the already described circular movement without rotating around its center.' );
    my $f9 = Wx::StaticText->new( $self, -1, 'If both circular movements (of X, Y and Z) are concurrent the pen just stays at one point,' );
    my $f10 = Wx::StaticText->new( $self, -1, 'If both are countercurrent - we get a circle. Interesting things start to happen, if we alter' );
    my $f11 = Wx::StaticText->new( $self, -1, 'the speed of of X, Y and Z. And for even more complex drawings I added R, which is not really' );
    my $f12 = Wx::StaticText->new( $self, -1, 'a pendulum, but an additional rotary movement of Z around its center.' );
    my $f13 = Wx::StaticText->new( $self, -1, 'The pendula out of metal do of course fizzle out with time, which you can see in the drawing,' );
    my $f14 = Wx::StaticText->new( $self, -1, 'in a spiraling movement toward the center. We emulate this with a damping factor.' );

    $self->{'close'} = Wx::Button->new( $self, -1, '&Close', [10,10], [-1, -1] );
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->EndModal(1) });

    my $sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL );
    my $t_attrs = &Wx::wxGROW | &Wx::wxLEFT | &Wx::wxALIGN_LEFT;
    $sizer->AddSpacer( 10 );
    $sizer->Add( $f1,         0, $t_attrs, 20 );
    $sizer->Add( $f2,         0, $t_attrs, 20 );
    $sizer->Add( $f3,         0, $t_attrs, 20 );
    $sizer->Add( $f4,         0, $t_attrs, 20 );
    $sizer->Add( $f5,         0, $t_attrs, 20 );
    $sizer->Add( $f6,         0, $t_attrs, 20 );
    $sizer->Add( $f7,         0, $t_attrs, 20 );
    $sizer->Add( $f8,         0, $t_attrs, 20 );
    $sizer->Add( $f9,         0, $t_attrs, 20 );
    $sizer->Add( $f10,        0, $t_attrs, 20 );
    $sizer->Add( $f11,        0, $t_attrs, 20 );
    $sizer->Add( $f12,        0, $t_attrs, 20 );
    $sizer->AddSpacer( 20 );
    $sizer->Add( $f13,        0, $t_attrs, 20 );
    $sizer->Add( $f14,        0, $t_attrs, 20 );
    $sizer->Add( 0,                1, &Wx::wxEXPAND | &Wx::wxGROW);
    $sizer->Add( $self->{'close'}, 0, &Wx::wxGROW | &Wx::wxALL, 25 );
    $self->SetSizer( $sizer );
    $self->SetAutoLayout( 1 );
    $self->SetSize( 700, 370 );
    return $self;
}

1;
