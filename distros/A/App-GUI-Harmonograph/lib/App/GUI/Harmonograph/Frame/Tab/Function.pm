
# panel behind modulation tab for changing base function of each pendulum

package App::GUI::Harmonograph::Frame::Tab::Function;
use v5.12;
use utf8;
use warnings;
use Wx;
use base qw/Wx::Panel/;

my @function_names = (qw/sin cos tan cot sec csc sinh cosh tanh coth sech csch/);
my @variable_names = ('X time',  'Y time', 'E time', 'F time', 'W time', 'R time',
                      'X freq.', 'Y freq.', 'E freq.', 'F freq.', 'W freq.', 'R freq.',
                      'X radius','Y radius', 'E radius', 'F radius', 'W radius', 'R radius'); # variable names
my @operator_names = (qw/= + - * \//);
my @pendulum_names = (qw/x y e f wx wy r11 r12 r21 r22/);
my @const_names = (1, '√2', '√3', '√5', 'π', 'τ', 'φ', 'Φ', 'ψ', 'e', 'γ', 'Γ', 'G', 'A');
my %const = (1 => 1, 2 => 2, 3 => 3, '√2' => 1.4142135623731, '3√3' => 1.44224957030740838232,
            '√3' => 1.73205080756888, '√5' => 2.236067977499789,
            'π' => 3.1415926535,  'τ' => 6.2831853071795,
            'φ' => 0.61803398874989, 'Φ' => 1.61803398874989, 'ψ' => 1.46557123187676802665,
              e => 2.718281828,  'γ' => 0.57721566490153286, 'Γ' => 1.7724538509055160,
              G => 0.9159655941772190150, A => 1.28242712910062,
);

my $default_settings = {
    x_function   => 'cos', x_operator   => '=', x_factor => '1',   x_constant => '1',   x_variable  => 'X time',
    y_function   => 'sin', y_operator   => '=', y_factor => '1',   y_constant => '1',   y_variable  => 'Y time',
    e_function   => 'cos', e_operator   => '=', e_factor => '1',   e_constant => '1',   e_variable  => 'E time',
    f_function   => 'sin', f_operator   => '=', f_factor => '1',   f_variable   => 'F time',
    wx_function  => 'cos', wx_operator  => '=', wx_factor => '1',  wx_variable  => 'W time',
    wy_function  => 'sin', wy_operator  => '=', wy_factor => '1',  wy_variable  => 'W time',
    r11_function => 'cos', r11_operator => '=', r11_factor => '1', r11_variable => 'R time',
    r12_function => 'sin', r12_operator => '=', r12_factor => '1', r12_variable => 'R time',
    r21_function => 'sin', r21_operator => '=', r21_factor => '1', r21_variable => 'R time',
    r22_function => 'cos', r22_operator => '=', r22_factor => '1', r22_variable => 'R time',
    first_rotary => 'r'
};

sub new {
    my ( $class, $parent ) = @_;

    my $self = $class->SUPER::new( $parent, -1);

    $self->{$_.'_function'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [ 82, -1], [@function_names], &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_operator'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [ 65, -1], [@operator_names], &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_factor'}   = Wx::ComboBox->new( $self, -1,  1, [-1,-1], [ 75, -1], [-1,1..17]       , &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_constant'} = Wx::ComboBox->new( $self, -1,  1, [-1,-1], [ 75, -1], [@const_names]   , &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{$_.'_variable'} = Wx::ComboBox->new( $self, -1, '', [-1,-1], [105, -1], [@variable_names], &Wx::wxTE_READONLY) for @pendulum_names;
    $self->{'order'} = Wx::RadioBox->new( $self, -1, 'Order of Rotary Pendula', [-1, -1], [165, -1], [' R > W ', ' W > R ']);
    $self->{'order'}->SetToolTip('apply which pendulum first ?');


    $self->{'x_function'}->SetToolTip('function that computes pendulum X: sine, cosine, tangent, cotangent, secans, cosecans, hyperbolic functions');
    $self->{'y_function'}->SetToolTip('function that computes pendulum Y');
    $self->{'e_function'}->SetToolTip('function that computes epicycle pendulum in x direction');
    $self->{'f_function'}->SetToolTip('function that computes epicycle pendulum in y direction');
    $self->{'wx_function'}->SetToolTip('function that computes pendulum W in x direction');
    $self->{'wy_function'}->SetToolTip('function that computes pendulum W in y direction');
    $self->{'r11_function'}->SetToolTip('left upper function in rotation matrix of pendulum R');
    $self->{'r12_function'}->SetToolTip('right upper function in rotation matrix of pendulum R');
    $self->{'r21_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');
    $self->{'r22_function'}->SetToolTip('left lower function in rotation matrix of pendulum R');

    $self->{'x_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'y_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'e_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'f_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'wx_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'wy_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'r11_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'r12_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'r21_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');
    $self->{'r22_operator'}->SetToolTip('replace (=), add, subtract, multiply or divide with the original variable value');

    $self->{$_.'_factor'}->SetToolTip('factor that will be multiplied with constant and variable (right beside it) before function on left is calculated') for @pendulum_names;
    $self->{$_.'_constant'}->SetToolTip('constant that will be multiplied with factor (left beside) and variable (right beside) before function on the most left is calculated') for @pendulum_names;

    $self->{'x_variable'}->SetToolTip('variable on which the function of pendulum X is computed upon');
    $self->{'y_variable'}->SetToolTip('variable on which the function of pendulum Y is computed upon');
    $self->{'e_variable'}->SetToolTip('variable on which the epicycle pendulum in x direction is computed');
    $self->{'f_variable'}->SetToolTip('variable on which the epicycle pendulum in y direction is computed');
    $self->{'wx_variable'}->SetToolTip('variable on which the function for x-direction of wobbling pendulum W is computed');
    $self->{'wy_variable'}->SetToolTip('variable on which the function for y-direction of wobbling pendulum W is computed');
    $self->{'r11_variable'}->SetToolTip('left upper variable in rotation matrix of pendulum R');
    $self->{'r12_variable'}->SetToolTip('right upper variable in rotation matrix of pendulum R');
    $self->{'r21_variable'}->SetToolTip('left lower variable in rotation matrix of pendulum R');
    $self->{'r22_variable'}->SetToolTip('left lower variable in rotation matrix of pendulum R');


    $self->{'callback'} = sub {};
    for my $val_type (qw/_function _operator _factor _constant _variable/){
        Wx::Event::EVT_COMBOBOX( $self, $self->{$_.$val_type}, sub { $self->{'callback'}->() }) for @pendulum_names;
    }
    Wx::Event::EVT_RADIOBOX( $self, $self->{'order'},          sub { $self->{'callback'}->() });

    my $label = { x => 'X', y => 'Y', w => 'W', r => 'R', e => 'E', f => 'F' };
    $self->{'lbl'}{$_} = Wx::StaticText->new(  $self, -1, $label->{$_}.' :' ) for keys %$label;

    my $std_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $next_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP;

    my $order_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $order_sizer->AddSpacer( 20 );
    $order_sizer->Add( $self->{'order'},  0, $std_attr, 0);
    $order_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);


    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    for my $pendulum (@pendulum_names){
        my $p_sigil = lc substr $pendulum, 0, 1;
        my $p_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
        if (exists $label->{ $p_sigil }) {
            $p_sizer->AddSpacer( 20 );
            $p_sizer->Add( $self->{'lbl'}{$p_sigil},    0, $box_attr, 12);
            $p_sizer->AddSpacer( $p_sigil eq 'w' ? 17 : 20 );
        } else {
            $p_sizer->AddSpacer( 55 );
        }
        $p_sizer->Add( $self->{$pendulum.'_function'},  0, $box_attr, 6);
        $p_sizer->AddSpacer( 10 );
        $p_sizer->Add( $self->{$pendulum.'_operator'},  0, $box_attr, 6);
        $p_sizer->AddSpacer( 10 );
        $p_sizer->Add( $self->{$pendulum.'_factor'},    0, $box_attr, 6);
        $p_sizer->AddSpacer( 10 );
        $p_sizer->Add( $self->{$pendulum.'_constant'},  0, $box_attr, 6);
        $p_sizer->AddSpacer( 10 );
        $p_sizer->Add( $self->{$pendulum.'_variable'},  0, $box_attr, 6);
        $p_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
        if (exists $label->{ $p_sigil }) {
            $sizer->Add( $p_sizer,                          0, $next_attr, 15);
            $sizer->Add( Wx::StaticLine->new( $self, -1),   0, $next_attr, 15) if $p_sigil eq $pendulum;
        } else {
            $sizer->Add( $p_sizer,                          0, $next_attr,  5);
        }
        delete $label->{ $p_sigil };
    }

    $sizer->Insert( 10, Wx::StaticLine->new( $self, -1),  0, $next_attr, 15);
    $sizer->Add( Wx::StaticLine->new( $self, -1),         0, $next_attr, 15);
    $sizer->Add( $order_sizer,                            0, $next_attr, 12);
    $sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->SetSizer( $sizer );
    $self->init;
    $self;
}

sub init { $_[0]->set_settings ( $default_settings ) }

sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'x_function'};

    for my $val_type (qw/_function _operator _factor _variable/){
        $self->{ $_.$val_type }->SetValue( ($settings->{$_.$val_type} // $default_settings->{$_.$val_type}) ) for @pendulum_names;
    }
    for my $pendulum (@pendulum_names){
        my $key = $pendulum.'_constant';
        $self->{ $key }->SetValue( 1 );
        if (exists $settings->{$key} and $settings->{$key}){
            for my $label (@const_names) {
                $self->{$key}->SetValue( $label ) if abs($const{ $label } - $settings->{$key}) < 0.0001;
            }
        }
    }
    $self->{'order' }->SetSelection( $settings->{'first_rotary'} eq 'r' ? 0 : 1 );
    1;
}
sub get_settings {
    my ( $self ) = @_;
    my $settings = {};
    for my $val_type (qw/_function _operator _factor _variable/){
        $settings->{ $_.$val_type } = $self->{$_.$val_type}->GetValue() for @pendulum_names;
    }
    $settings->{ $_.'_constant' } = $const{ $self->{$_.'_constant'}->GetValue } for @pendulum_names;
    $settings->{'first_rotary'} = $self->{'order' }->GetSelection ? 'w' : 'r';
    $settings;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;
