use v5.12;
use utf8;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::ModMatrix;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my $default = { x_function => 'cos', y_function => 'sin' };

sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1);

    $self->{'lbl'}{'x'} = Wx::StaticText->new( $self, -1, 'X :');
    $self->{'lbl'}{'y'} = Wx::StaticText->new( $self, -1, 'Y :');
    $self->{'x_function'} = Wx::ComboBox->new( $self, -1, 'cos', [-1,-1],[95, -1], [qw/sin cos tan cot sec csc sinh cosh tanh coth sech csch/], &Wx::wxTE_READONLY);
    $self->{'y_function'} = Wx::ComboBox->new( $self, -1, 'sin', [-1,-1],[95, -1], [qw/sin cos tan cot sec csc sinh cosh tanh coth sech csch/], &Wx::wxTE_READONLY);

    $self->{'callback'} = sub {};

                          
#    Wx::Event::EVT_CHECKBOX( $self, $self->{'quarter_off'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'x_function'},  sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'y_function'},  sub {                $self->{'callback'}->() });
    
    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $x_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $x_sizer->AddSpacer( 15 );
    $x_sizer->Add( $self->{'lbl'}{'x'},    0, $box_attr, 10);
    $x_sizer->AddSpacer( 25 );
    $x_sizer->Add( $self->{'x_function'},  0, $box_attr, 5);
    $x_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $y_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $y_sizer->AddSpacer( 15 );
    $y_sizer->Add( $self->{'lbl'}{'y'},    0, $box_attr, 10);
    $y_sizer->AddSpacer( 25 );
    $y_sizer->Add( $self->{'y_function'},  0, $box_attr, 5);
    $y_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $x_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $std_attr | &Wx::wxTOP, 15);
    $sizer->Add( $y_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub SetCallBack {    
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    # $self->{ $_ }->SetCallBack( $code ) for qw /radius radius_damp radius_damp_acc frequency freq_dez freq_damp offset/;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ( $default );
}

sub get_data {
    my ( $self ) = @_;
    {
        x_function   => $self->{'x_function'}->GetValue,
        y_function   => $self->{'y_function'}->GetValue,
    }
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'x_function'};
    $self->{ 'x_function' }->SetValue( $data->{ 'x_function' } // $default->{ 'x_function' } );
    $self->{ 'y_function' }->SetValue( $data->{ 'y_function' } // $default->{ 'y_function' } );
    1;
}

1;
