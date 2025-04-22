use v5.12;
use warnings;
use Wx;

# combined widget with a slider that dials in a value between 0 and 1
# and 2 butons that trigger and event to add or subtract this value

package App::GUI::Juliagraph::Widget::SliderStep;
use base qw/Wx::Panel/;
my $resolution = 100;

sub new {
    my ( $class, $parent, $slider_length, $slider_pos, $init_value, $max_value, $exponent, $minus_label, $plus_label ) = @_;
    $slider_length //= 50;
    $slider_pos //= 2;
    $slider_pos = int $slider_pos;
    $slider_pos = 2 if $slider_pos < 1 and $slider_pos > 3;
    $minus_label //= '-';
    $plus_label //= '+';
    $init_value //= 0.5;
    $max_value //= 1;
    return if $init_value > $max_value;

    my $self = $class->SUPER::new( $parent, -1);
    $self->{'init_value'} = $init_value;
    $self->{'max_value'} = $max_value;
    $self->{'exponent'} = $exponent;
    $self->{'callback'} = sub {};

    $self->{'btn'}{'-'} = Wx::Button->new( $self, -1, $minus_label, [-1,-1],[40, 30] );
    $self->{'btn'}{'+'} = Wx::Button->new( $self, -1, $plus_label, [-1,-1],[40, 30] );
    $self->{'slider'} = Wx::Slider->new( $self, -1, $self->{'init_value'} * $resolution,
                                         0, $self->{'max_value'} * $resolution,
                                         [-1,-1], [$slider_length, -1],  &Wx::wxSL_HORIZONTAL | &Wx::wxSL_BOTTOM );
    $self->{'btn'}{'-'}->SetToolTip( "decrease value by a step" );
    $self->{'btn'}{'+'}->SetToolTip( "increase value by a step");
    $self->{'slider'}->SetToolTip( 'step size' );

    my $std  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box  = $std | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sizer->Add( $self->{'btn'}{'-'}, 0, $box, 0);
    $sizer->Add( $self->{'btn'}{'+'}, 0, $box, 0);
    $sizer->AddSpacer( 10 );
    $sizer->Insert( $slider_pos, $self->{'slider'}, 0, $box, 3);
    $sizer->Add( 0,                   1, &Wx::wxEXPAND|&Wx::wxGROW);
    $self->SetSizer($sizer);

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'-'}, sub { $self->{'callback'}->( -$self->GetValue ) });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'+'}, sub { $self->{'callback'}->( $self->GetValue ) });
    Wx::Event::EVT_SLIDER( $self, $self->{'slider'},   sub { $self->{'slider'}->SetToolTip( 'step size: '. $self->GetValue ); });

    return $self;
}

sub GetValue { ($_[0]->{'slider'}->GetValue / $resolution) ** $_[0]->{'exponent'} }

sub SetValue {
    my ( $self, $value) = @_;
    return if not efined $value or $value > $self->{'max_value'};
    $self->{'slider'}->SetValue(($value * $resolution) ** (1/$self->{'exponent'}));
}
sub Reset   { $_[0]->SetValue( $_[0]->{'init_value'} ) }

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}


1;
