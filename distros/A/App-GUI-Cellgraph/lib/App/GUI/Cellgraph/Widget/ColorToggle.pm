use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Widget::ColorToggle;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $colors, $start  ) = @_;
    return unless ref $colors eq 'ARRAY' and @$colors > 1;
    for (@$colors){ return unless ref $_ eq 'ARRAY' and @$_ == 3 }

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x+2, $y+2]);
    $self->{'colors'} = $colors;
    $self->{'init'} = $start // 0;
    $self->{'callback'} = sub {};

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( @{$self->{'colors'}[ $self->{'value'} ]} );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
        $dc->DrawLine(    0,    0, $x+1,    0 );
        $dc->DrawLine(    0, $y+1, $x+1, $y+1 );
        $dc->DrawLine(    0,    0,    0, $y+1 );
        $dc->DrawLine( $x+1,    0, $x+1, $y+1 );
    } );

    Wx::Event::EVT_LEFT_DOWN( $self, sub {
        my $value = $self->GetValue;
        $value++;
        $value = 0 if $value >= @{$self->{'colors'}};
        $self->SetValue( $value );
        $self->{'callback'}->( $self->{'value'}  );
    });

    $self->init();
    $self;
}

sub init { $_[0]->SetValue( $_[0]->{'init'} ) }    

sub GetValue { $_[0]->{'value'} }
sub SetValue {
    my ( $self, $value ) = @_;
    return unless defined $value and $value > -1 and $value < @{$self->{'colors'}};
    $self->{'value'} = $value;
    $self->Refresh;
}

sub SetCallBack {    
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;

