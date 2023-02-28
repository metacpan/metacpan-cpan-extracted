use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::ColorBrowser;
use base qw/Wx::Panel/;
use App::GUI::Cellgraph::Widget::SliderCombo;
use App::GUI::Cellgraph::Widget::ColorDisplay;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $type, $init_color ) = @_;
    $init_color = color( $init_color );
    return unless ref $init_color;

    my $self = $class->SUPER::new( $parent, -1);

    $self->{'init'} = $init_color;
    $self->{'call_back'} = sub {};

    $self->{'red'}   =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 290, ' R  ', "red part of $type color",    0, 255,  $init_color->red);
    $self->{'green'} =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 290, ' G  ', "green part of $type color",  0, 255,  $init_color->green);
    $self->{'blue'}  =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 290, ' B  ', "blue part of $type color",   0, 255,  $init_color->blue);
    $self->{'hue'}   =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 290, ' H  ', "hue of $type color",         0, 359,  $init_color->hue);
    $self->{'sat'}   =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 294, ' S   ', "saturation of $type color",  0, 100,  $init_color->saturation);
    $self->{'light'} =  App::GUI::Cellgraph::Widget::SliderCombo->new( $self, 294, ' L   ', "lightness of $type color",   0, 100,  $init_color->lightness);
   # $self->{'display'}->SetToolTip("$type color monitor");

    my $rgb2hsl = sub {
        my @rgb = ($self->{'red'}->GetValue, $self->{'green'}->GetValue, $self->{'blue'}->GetValue);
        my @hsl = Graphics::Toolkit::Color::Value::hsl_from_rgb( @rgb );
        $self->{'hue'}->SetValue( $hsl[0], 1 );
        $self->{'sat'}->SetValue( $hsl[1], 1 );
        $self->{'light'}->SetValue( $hsl[2], 1 );
        $self->{'call_back'}->( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    my $hsl2rgb = sub {
        my @rgb = Graphics::Toolkit::Color::Value::rgb_from_hsl(
            $self->{'hue'}->GetValue,  $self->{'sat'}->GetValue, $self->{'light'}->GetValue );
        $self->{'red'}->SetValue( $rgb[0], 1 );
        $self->{'green'}->SetValue( $rgb[1], 1 );
        $self->{'blue'}->SetValue( $rgb[2], 1 );
        $self->{'call_back'}->( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    $self->{'red'}->SetCallBack( $rgb2hsl );
    $self->{'green'}->SetCallBack( $rgb2hsl );
    $self->{'blue'}->SetCallBack( $rgb2hsl );
    $self->{'hue'}->SetCallBack( $hsl2rgb );
    $self->{'sat'}->SetCallBack( $hsl2rgb );
    $self->{'light'}->SetCallBack( $hsl2rgb );


    my $attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW | &Wx::wxLEFT;
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $self->{'red'},  0, $attr, 10);
    $sizer->Add( $self->{'green'},  0, $attr, 10);
    $sizer->Add( $self->{'blue'},  0, $attr, 10);
    $sizer->AddSpacer( 20 );
    $sizer->Add( $self->{'hue'},  0, $attr, 10);
    $sizer->Add( $self->{'sat'},  0, $attr, 10);
    $sizer->Add( $self->{'light'},  0, $attr, 10);

    $self->SetSizer($sizer);
    $self;
}

sub init {
    my ($self) = @_;
    $self->set_data( $self->{'init'} );
}

sub get_data { $_[0]->{'display'}->get_color( ) }

sub set_data {
    my ( $self, $data, $silent ) = @_;
    return unless ref $data eq 'HASH'
        and exists $data->{'red'} and exists $data->{'green'} and exists $data->{'blue'};
    $self->{'red'}->SetValue( $data->{'red'}, 1);
    $self->{'green'}->SetValue( $data->{'green'}, 1);
    $self->{'blue'}->SetValue( $data->{'blue'}, 1 );
    my @hsl = Graphics::Toolkit::Color::Value::hsl_from_rgb( @$data{qw/red green blue/} );
    $self->{'hue'}->SetValue( $hsl[0], 1 );
    $self->{'sat'}->SetValue( $hsl[1], 1 );
    $self->{'light'}->SetValue( $hsl[2], 1 );
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

1;
