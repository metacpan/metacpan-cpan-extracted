use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::ColorBrowser;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::SliderCombo;
use App::GUI::Harmonograph::ColorDisplay;
use App::GUI::Harmonograph::Color;

sub new {
    my ( $class, $parent, $type, $init  ) = @_;
    return unless ref $init eq 'HASH' and exists $init->{'red'}and exists $init->{'green'}and exists $init->{'blue'};
    
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'init'} = $init;
    
    $self->{'red'}   =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' R  ', "red part of $type color",    0, 255,  0);
    $self->{'green'} =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' G  ', "green part of $type color",  0, 255,  0);
    $self->{'blue'}  =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' B  ', "blue part of $type color",   0, 255,  0);
    $self->{'hue'}   =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' H  ', "hue of $type color",         0, 359,  0);
    $self->{'sat'}   =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' S  ', "saturation of $type color",  0, 100,  0);
    $self->{'light'} =  App::GUI::Harmonograph::SliderCombo->new( $self, 100, ' L  ', "lightness of $type color",   0, 100,  0);
    $self->{'display'}= App::GUI::Harmonograph::ColorDisplay->new( $self, 25, 10, $init);
    $self->{'display'}->SetToolTip("$type color monitor");
    
    my $rgb2hsl = sub {
        my @rgb = ($self->{'red'}->GetValue, $self->{'green'}->GetValue, $self->{'blue'}->GetValue);
        my @hsl = App::GUI::Harmonograph::Color::Value::hsl_from_rgb( @rgb );
        $self->{'hue'}->SetValue( $hsl[0], 1 );
        $self->{'sat'}->SetValue( $hsl[1], 1 );
        $self->{'light'}->SetValue( $hsl[2], 1 );
        $self->{'display'}->set_color( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    my $hsl2rgb = sub {
        my @rgb = App::GUI::Harmonograph::Color::Value::rgb_from_hsl( 
            $self->{'hue'}->GetValue,  $self->{'sat'}->GetValue, $self->{'light'}->GetValue );
        $self->{'red'}->SetValue( $rgb[0], 1 );
        $self->{'green'}->SetValue( $rgb[1], 1 );
        $self->{'blue'}->SetValue( $rgb[2], 1 );
        $self->{'display'}->set_color( { red => $rgb[0], green => $rgb[1], blue => $rgb[2] } );
    };
    $self->{'red'}->SetCallBack( $rgb2hsl );
    $self->{'green'}->SetCallBack( $rgb2hsl );
    $self->{'blue'}->SetCallBack( $rgb2hsl );
    $self->{'hue'}->SetCallBack( $hsl2rgb );
    $self->{'sat'}->SetCallBack( $hsl2rgb );
    $self->{'light'}->SetCallBack( $hsl2rgb );


    my $rh_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $rh_sizer->Add( $self->{'red'},  0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $rh_sizer->Add( $self->{'hue'},  0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $rh_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $gs_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $gs_sizer->Add( $self->{'green'},    0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $gs_sizer->Add( $self->{'display'},  0, &Wx::wxGROW|&Wx::wxLEFT|&Wx::wxALIGN_CENTER_VERTICAL, 15);
    $gs_sizer->Add( $self->{'sat'},      0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $gs_sizer->Add( 0,                   0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $bl_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $bl_sizer->Add( $self->{'blue'},    0, &Wx::wxGROW|&Wx::wxLEFT, 10);
    $bl_sizer->Add( $self->{'light'},   0, &Wx::wxGROW|&Wx::wxLEFT, 50);
    $bl_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);


    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $rh_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $gs_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $bl_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);

    $self->SetSizer($sizer);
    $self;
}

sub init {
    my ($self) = @_;
    $self->set_data( $self->{'init'} );
}    

sub get_data { $_[0]->{'display'}->get_color( ) }

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' 
        and exists $data->{'red'} and exists $data->{'green'} and exists $data->{'blue'};
    $self->{'red'}->SetValue( $data->{'red'}, 1);
    $self->{'green'}->SetValue( $data->{'green'}, 1);
    $self->{'blue'}->SetValue( $data->{'blue'} );
}


1;
