use v5.12;
use utf8;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::ModMatrix;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my @function_names = (qw/sin cos tan cot sec csc sinh cosh tanh coth sech csch/);
my @var_names = (qw/x_time y_time z_time r_time x_freq y_freq z_freq r_freq x_radius y_radius z_radius r_radius zero one/); # variable names
my $default = { x_function => 'cos',   x_var => 'x_time',
                y_function => 'sin',   y_var => 'y_time',
                zx_function => 'cos',  zx_var => 'z_time',
                zy_function => 'sin',  zy_var => 'z_time',
                r11_function => 'cos', r12_function => 'sin',
                r21_function => 'sin', r22_function => 'cos',
                r11_var => 'r_time',   r12_var => 'r_time',
                r21_var => 'r_time',   r22_var => 'r_time',
};

sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1);

    $self->{'lbl'}{'x'} = Wx::StaticText->new( $self, -1, 'X :');
    $self->{'lbl'}{'y'} = Wx::StaticText->new( $self, -1, 'Y :');
    $self->{'lbl'}{'z'} = Wx::StaticText->new( $self, -1, 'Z :');
    $self->{'lbl'}{'r'} = Wx::StaticText->new( $self, -1, 'R :');
    $self->{'x_function'} = Wx::ComboBox->new( $self, -1, 'cos', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'x_var'}    = Wx::ComboBox->new( $self, -1, 'x_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'y_function'} = Wx::ComboBox->new( $self, -1, 'sin', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'y_var'}    = Wx::ComboBox->new( $self, -1, 'y_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'zx_function'} = Wx::ComboBox->new( $self, -1, 'cos', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'zx_var'}    = Wx::ComboBox->new( $self, -1, 'z_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'zy_function'} = Wx::ComboBox->new( $self, -1, 'sin', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'zy_var'}    = Wx::ComboBox->new( $self, -1, 'z_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'r11_function'} = Wx::ComboBox->new( $self, -1, 'cos', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'r12_function'} = Wx::ComboBox->new( $self, -1, 'sin', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'r21_function'} = Wx::ComboBox->new( $self, -1, 'sin', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'r22_function'} = Wx::ComboBox->new( $self, -1, 'cos', [-1,-1],[95, -1], [@function_names], &Wx::wxTE_READONLY);
    $self->{'r11_var'}    = Wx::ComboBox->new( $self, -1, 'r_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'r12_var'}    = Wx::ComboBox->new( $self, -1, 'r_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'r21_var'}    = Wx::ComboBox->new( $self, -1, 'r_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'r22_var'}    = Wx::ComboBox->new( $self, -1, 'r_time', [-1,-1],[95, -1], [@var_names], &Wx::wxTE_READONLY);
    $self->{'x_function'}->SetToolTip('function that computes pendulum X');
    $self->{'x_var'}->SetToolTip('variable on which the function of pendulum X is computed upon');
    $self->{'y_function'}->SetToolTip('function that computes pendulum Y');
    $self->{'y_var'}->SetToolTip('variable on which the function of pendulum Y is computed upon');
    $self->{'zx_function'}->SetToolTip('function that computes pendulum Z in x direction');
    $self->{'zx_var'}->SetToolTip('variable on which the function of pendulum Z is computed upon');
    $self->{'zy_function'}->SetToolTip('function that computes pendulum Z');
    $self->{'zy_var'}->SetToolTip('variable on which the function of pendulum Z is computed upon');
    $self->{'r11_function'}->SetToolTip('left upper function in rotation matrix of pendulum R');
    $self->{'r12_function'}->SetToolTip('right upper function in rotation matrix of pendulum R');
    $self->{'r21_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');
    $self->{'r22_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');
    $self->{'r11_var'}->SetToolTip('left upper variable in rotation matrix of pendulum R');
    $self->{'r12_var'}->SetToolTip('right upper variable in rotation matrix of pendulum R');
    $self->{'r21_var'}->SetToolTip('left lower variable in rotation matrix of pendulum R');
    $self->{'r22_var'}->SetToolTip('left lower variable in rotation matrix of pendulum R');

    $self->{'callback'} = sub {};


    Wx::Event::EVT_COMBOBOX( $self, $self->{'x_function'},  sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'y_function'},  sub {                $self->{'callback'}->() });

    my $std_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $x_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $x_sizer->AddSpacer( 15 );
    $x_sizer->Add( $self->{'lbl'}{'x'},    0, $box_attr, 10);
    $x_sizer->AddSpacer( 25 );
    $x_sizer->Add( $self->{'x_function'},  0, $box_attr, 5);
    $x_sizer->AddSpacer( 15 );
    $x_sizer->Add( $self->{'x_var'},  0, $box_attr, 5);
    $x_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $y_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
    $y_sizer->AddSpacer( 15 );
    $y_sizer->Add( $self->{'lbl'}{'y'},    0, $box_attr, 10);
    $y_sizer->AddSpacer( 25 );
    $y_sizer->Add( $self->{'y_function'},  0, $box_attr, 5);
    $y_sizer->AddSpacer( 15 );
    $y_sizer->Add( $self->{'y_var'},  0, $box_attr, 5);
    $y_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $z_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
      my $z1_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $z1_sizer->Add( $self->{'zx_function'},  0, $box_attr, 5);
      $z1_sizer->Add( $self->{'zy_function'},  0, $box_attr, 5);
      my $z2_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $z2_sizer->Add( $self->{'zx_var'},  0, $box_attr, 5);
      $z2_sizer->Add( $self->{'zy_var'},  0, $box_attr, 5);
    $z_sizer->AddSpacer( 15 );
    $z_sizer->Add( $self->{'lbl'}{'z'},    0, $box_attr, 10);
    $z_sizer->AddSpacer( 25 );
    $z_sizer->Add( $z1_sizer,  0, $box_attr, 5);
    $z_sizer->AddSpacer( 15 );
    $z_sizer->Add( $z2_sizer,  0, $box_attr, 5);
    $z_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);


    my $r_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL);
      my $r1_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $r1_sizer->Add( $self->{'r11_function'},  0, $box_attr, 5);
      $r1_sizer->Add( $self->{'r21_function'},  0, $box_attr, 5);
      my $r2_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $r2_sizer->Add( $self->{'r11_var'},  0, $box_attr, 5);
      $r2_sizer->Add( $self->{'r21_var'},  0, $box_attr, 5);
      my $r3_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $r3_sizer->Add( $self->{'r12_function'},  0, $box_attr, 5);
      $r3_sizer->Add( $self->{'r22_function'},  0, $box_attr, 5);
      my $r4_sizer = Wx::BoxSizer->new( &Wx::wxVERTICAL);
      $r4_sizer->Add( $self->{'r12_var'},  0, $box_attr, 5);
      $r4_sizer->Add( $self->{'r22_var'},  0, $box_attr, 5);
    $r_sizer->AddSpacer( 15 );
    $r_sizer->Add( $self->{'lbl'}{'r'},    0, $box_attr, 10);
    $r_sizer->AddSpacer( 25 );
    $r_sizer->Add( $r1_sizer,  0, $box_attr, 5);
    $r_sizer->AddSpacer( 15 );
    $r_sizer->Add( $r2_sizer,  0, $box_attr, 5);
    $r_sizer->AddSpacer( 35 );
    $r_sizer->Add( $r3_sizer,  0, $box_attr, 5);
    $r_sizer->AddSpacer( 15 );
    $r_sizer->Add( $r4_sizer,  0, $box_attr, 5);
    $r_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $x_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $std_attr | &Wx::wxTOP, 15);
    $sizer->Add( $y_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $std_attr | &Wx::wxTOP, 15);
    $sizer->Add( $z_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 135, 2] ),  0, $std_attr | &Wx::wxTOP, 15);
    $sizer->Add( $r_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 15);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $sizer );

    $self->init();
    $self;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ( $default );
}

sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'x_function'};
    for my $key (keys %$default){
        $self->{ $key }->SetValue( $data->{ $key } // $default->{ $key } );
    }
    1;
}

sub get_data {
    my ( $self ) = @_;
    return { map { $_, $self->{$_}->GetValue; } keys %$default };
}


1;
