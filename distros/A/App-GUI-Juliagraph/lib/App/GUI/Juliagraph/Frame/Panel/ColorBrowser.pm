
# panel with sliders to select a color

package App::GUI::Juliagraph::Frame::Panel::ColorBrowser;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderCombo;
use App::GUI::Juliagraph::Widget::ColorDisplay;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $type, $init_color ) = @_;
    $init_color = color( $init_color );
    return unless ref $init_color;

    my $self = $class->SUPER::new( $parent, -1);
    $self->{'init_color'} = $init_color->values( as => 'hash' );
    $self->{'call_back'} = sub {};

    my @rgb = $init_color->values('RGB');
    my @hsl = $init_color->values('HSL');

    $self->{'widget'}{'red'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' R  ', "red part of $type color",    0, 255,  $rgb[0]);
    $self->{'widget'}{'green'} =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' G  ', "green part of $type color",  0, 255,  $rgb[1]);
    $self->{'widget'}{'blue'}  =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' B  ', "blue part of $type color",   0, 255,  $rgb[2]);
    $self->{'widget'}{'hue'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' H  ', "hue of $type color",         0, 359,  $hsl[0]);
    $self->{'widget'}{'sat'}   =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' S   ', "saturation of $type color", 0, 100,  $hsl[1]);
    $self->{'widget'}{'light'} =  App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 350, ' L   ', "lightness of $type color",  0, 100,  $hsl[2]);
    $self->{'button'}{'rnd_'.$_} = Wx::Button->new( $self, -1, '?',  [-1,-1], [30,25] ) for qw/red green blue hue sat light/;
    $self->{'button'}{'rnd_red'}->SetToolTip("randomize red value");
    $self->{'button'}{'rnd_green'}->SetToolTip("randomize green value");
    $self->{'button'}{'rnd_blue'}->SetToolTip("randomize blue value");
    $self->{'button'}{'rnd_hue'}->SetToolTip("randomize hue value");
    $self->{'button'}{'rnd_sat'}->SetToolTip("randomize saturation value");
    $self->{'button'}{'rnd_light'}->SetToolTip("randomize lightness value");

    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_red'},  sub { $self->{'widget'}{'red'}->SetValue(int rand 256) });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_green'},sub { $self->{'widget'}{'green'}->SetValue(int rand 256) });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_blue'}, sub { $self->{'widget'}{'blue'}->SetValue(int rand 256) });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_hue'},  sub { $self->{'widget'}{'hue'}->SetValue(int rand 360) });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_sat'},  sub { $self->{'widget'}{'sat'}->SetValue(int rand 101) });
    Wx::Event::EVT_BUTTON( $self, $self->{'button'}{'rnd_light'},sub { $self->{'widget'}{'light'}->SetValue(int rand 101) });

    my $rgb2hsl = sub {
        my @rgb = ($self->{'widget'}{'red'}->GetValue,
                   $self->{'widget'}{'green'}->GetValue,
                   $self->{'widget'}{'blue'}->GetValue );
        my @hsl = color( @rgb )->values('HSL');
        $self->{'widget'}{'hue'}->SetValue( $hsl[0], 1 );
        $self->{'widget'}{'sat'}->SetValue( $hsl[1], 1 );
        $self->{'widget'}{'light'}->SetValue( $hsl[2], 1 );
        $self->{'call_back'}->( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    my $hsl2rgb = sub {
        my @hsl = ($self->{'widget'}{'hue'}->GetValue,
                   $self->{'widget'}{'sat'}->GetValue,
                   $self->{'widget'}{'light'}->GetValue );
        my @rgb = color( 'HSL', @hsl )->values('RGB');
        $self->{'widget'}{'red'}->SetValue( $rgb[0], 1 );
        $self->{'widget'}{'green'}->SetValue( $rgb[1], 1 );
        $self->{'widget'}{'blue'}->SetValue( $rgb[2], 1 );
        $self->{'call_back'}->( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    $self->{'widget'}{'red'}->SetCallBack( $rgb2hsl );
    $self->{'widget'}{'green'}->SetCallBack( $rgb2hsl );
    $self->{'widget'}{'blue'}->SetCallBack( $rgb2hsl );
    $self->{'widget'}{'hue'}->SetCallBack( $hsl2rgb );
    $self->{'widget'}{'sat'}->SetCallBack( $hsl2rgb );
    $self->{'widget'}{'light'}->SetCallBack( $hsl2rgb );

    my $attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxGROW;
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer(5);
    for my $color (qw/red green blue hue sat light/){
        my $sub_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        $sub_sizer->Add( $self->{'widget'}{$color}, 0, $attr| &Wx::wxLEFT, 15 );
        $sub_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        $sub_sizer->Add( $self->{'button'}{'rnd_'.$color}, 0, $attr| &Wx::wxRIGHT, 30 );
        $sizer->Add( $sub_sizer,  0, $attr| &Wx::wxBOTTOM, (($color eq 'blue') ? 25 : 10));
    }
    $self->SetSizer($sizer);
    $self;
}

# better init color set
sub init { $_[0]->set_data( $_[0]->{'init_color'} ) }

sub get_data { {  red => $_[0]->{'widget'}{'red'}->GetValue,
                green => $_[0]->{'widget'}{'green'}->GetValue,
                 blue => $_[0]->{'widget'}{'blue'}->GetValue, } }

sub set_data {
    my ( $self, $data, $silent ) = @_;
    return unless ref $data eq 'HASH'
        and exists $data->{'red'} and exists $data->{'green'} and exists $data->{'blue'};

    $self->{'widget'}{'red'}->SetValue( $data->{'red'}, 1);
    $self->{'widget'}{'green'}->SetValue( $data->{'green'}, 1);
    $self->{'widget'}{'blue'}->SetValue( $data->{'blue'}, 1 );
    my @hsl = color( $data )->values('HSL');
    $self->{'widget'}{'hue'}->SetValue( $hsl[0], 1 );
    $self->{'widget'}{'sat'}->SetValue( $hsl[1], 1 );
    $self->{'widget'}{'light'}->SetValue( $hsl[2], 1 );
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'call_back'} = $code;
}

1;
