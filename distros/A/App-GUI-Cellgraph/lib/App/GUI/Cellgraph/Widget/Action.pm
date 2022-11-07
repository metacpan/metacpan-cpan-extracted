use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Widget::Action;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $cell_size, $color) = @_;
    return unless ref $color eq 'ARRAY' and @$color == 3;
    my $cell_count = 3;
    my $x = ($cell_size + 1) * $cell_count + 1;
    my $y = $cell_size + 2;
    my $mid = 1 + int $cell_size / 2;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);
    $self->{'callback'} = sub {};
    
    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
        $dc->DrawLine(  0,    0, $x-1,    0 );
        $dc->DrawLine(  0, $y-1, $x-1, $y-1 );
        $dc->DrawLine( $_,    0,   $_, $y-1 ) for map { ($cell_size + 1) * $_ }  0 .. $cell_count;
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 2, &Wx::wxPENSTYLE_SOLID ) );
        for my $i (0 .. 2) {
            if ($self->{'value'}[ $i ]){
                $dc->DrawCircle( (($cell_size + 1) * $i) + $mid , $mid, int($cell_size / 2) - 4 );
                # $dc->DrawCircle( (($cell_size + 1) * $i) + $mid , $mid, 1 );
            }
        }
    } );
    
    Wx::Event::EVT_LEFT_DOWN( $self, sub {
        my $x = $_[1]->GetPosition->x;
        my $i = ($x < ($cell_size + 1)) ? 0 : ($x < ($cell_size * 2 + 2)) ? 1 : 2;
        $self->{'value'}[ $i ] = ! $self->{'value'}[ $i ];
        $self->Refresh;
        $self->{'callback'}->( $self->{'value'}  );
    });

    $self->init;
    $self;
}


sub init {
    my ($self) = @_;
    $self->SetValue( 2 );
    $self->Refresh;
    $self->GetValue;
}

sub grid {
    my ($self) = @_;
    $self->SetValue( 5 );
    $self->Refresh;
    $self->GetValue;
}

sub invert {
    my ($self) = @_;
    $self->{'value'}[ 0 ] = !$self->{'value'}[ 0 ];
    $self->{'value'}[ 1 ] = !$self->{'value'}[ 1 ];
    $self->{'value'}[ 2 ] = !$self->{'value'}[ 2 ];
    $self->Refresh;
    $self->GetValue;
}

sub rand {
    my ($self) = @_;
    $self->{'value'}[ 0 ] = int rand 2;
    $self->{'value'}[ 1 ] = int rand 2;
    $self->{'value'}[ 2 ] = int rand 2;
    $self->Refresh;
    $self->GetValue;
}

sub GetValue {
    my ($self) = @_;
    ($self->{'value'}[ 0 ] * 4) +
    ($self->{'value'}[ 1 ] * 2) +
    ($self->{'value'}[ 2 ] * 1);
}

sub SetValue {
    my ($self, $value) = @_;
    $self->{'value'}[ 0 ] = $value & 4 ? 1 : 0;
    $self->{'value'}[ 1 ] = $value & 2 ? 1 : 0;
    $self->{'value'}[ 2 ] = $value & 1 ? 1 : 0;
    $self->Refresh;
}

sub SetCallBack {    
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}


1;
