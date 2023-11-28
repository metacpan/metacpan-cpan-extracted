use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Part::ColorBrowser;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderCombo;
use App::GUI::Juliagraph::Widget::ColorDisplay;
use Graphics::Toolkit::Color qw/color/;

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

sub new {
    my ( $class, $parent, $type, $init_color ) = @_;
    $init_color = color( $init_color );
    return unless ref $init_color;

    my $self = $class->SUPER::new( $parent, -1);

    $self->{'init'} = $init_color;
    $self->{'call_back'} = sub {};

    my @rgb = $init_color->values('RGB');
    my @hsl = $init_color->values('HSL');

    $self->{'red'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 290, ' R  ', "red part of $type color",    0, 255,  $rgb[0]);
    $self->{'green'} =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 290, ' G  ', "green part of $type color",  0, 255,  $rgb[1]);
    $self->{'blue'}  =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 290, ' B  ', "blue part of $type color",   0, 255,  $rgb[2]);
    $self->{'hue'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 290, ' H  ', "hue of $type color",         0, 359,  $hsl[0]);
    $self->{'sat'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 294, ' S   ', "saturation of $type color", 0, 100,  $hsl[1]);
    $self->{'light'} =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 294, ' L   ', "lightness of $type color",  0, 100,  $hsl[2]);
   # $self->{'display'}->SetToolTip("$type color monitor");

    my $rgb2hsl = sub {
        my @rgb = ($self->{'red'}->GetValue, $self->{'green'}->GetValue, $self->{'blue'}->GetValue);
        my @hsl = $HSL->deconvert( [$RGB->normalize( \@rgb )], 'RGB');
        @hsl = $HSL->denormalize( \@hsl );
        $self->{'hue'}->SetValue( $hsl[0], 1 );
        $self->{'sat'}->SetValue( $hsl[1], 1 );
        $self->{'light'}->SetValue( $hsl[2], 1 );
        $self->{'call_back'}->( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    my $hsl2rgb = sub {
        my @hsl = ($self->{'hue'}->GetValue, $self->{'sat'}->GetValue, $self->{'light'}->GetValue);
        my @rgb = $HSL->convert( [$HSL->normalize( \@hsl )], 'RGB');
        @rgb = $RGB->denormalize( \@rgb );
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
    my @rgb = @$data{qw/red green blue/};
    my @hsl = $HSL->deconvert( [$RGB->normalize( \@rgb )], 'RGB');
    @hsl = $HSL->denormalize( \@hsl );
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

