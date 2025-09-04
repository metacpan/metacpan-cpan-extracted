
# settings for all pendula

package App::GUI::Harmonograph::Frame::Panel::Pendulum;
use base qw/Wx::Panel/;
use v5.12;
use utf8;
use warnings;
use Wx;
use App::GUI::Wx::Widget::Custom::SliderCombo;

my @const_names = (1, 2, 3, '√2', '√3', '√5', 'π', 'τ', 'φ', 'Φ', 'ψ', 'e', 'γ', 'Γ', 'G', 'A');
my %const = (1 => 1, 2 => 2, 3 => 3, '√2' => 1.4142135623731, '√3' => 1.73205080756888, '√5' => 2.236067977499789,
            'π' => 3.1415926535,  'τ' => 6.2831853071795,
            'φ' => 0.61803398874989, 'Φ' => 1.61803398874989, 'ψ' => 1.46557123187676802665,
              e => 2.718281828,  'γ' => 0.57721566490153286, 'Γ' => 1.7724538509055160,
              G => 0.9159655941772190150, A => 1.28242712910062,
);

sub new {
    my ( $class, $parent, $label, $help, $on, $max ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'name'} = $label;
    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;
    $self->{'callback'} = sub {};

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1], [-1,-1], $on );
    $self->{'on'}->SetToolTip("set partial $help on or off");

    my $main_label  = Wx::StaticText->new($self, -1, uc($label) );
    $main_label->SetToolTip($help);

    $self->{'frequency'}  = App::GUI::Wx::Widget::Custom::SliderCombo->new
                        ( $self, 100, 'Frequency', 'frequency of '.$help, 1, $max, 1 );
    $self->{'freq_dez'} = App::GUI::Wx::Widget::Custom::SliderCombo->new
                        ( $self, 100, 'Precise   ', 'decimals of frequency at '.$help, 0, 1000, 0);
    $self->{'freq_factor'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[70, 20], [@const_names]);
    $self->{'freq_factor'}->SetToolTip('base factor the frequency will be multiplied with: one (no), or a math constants as shown');
    $self->{'freq_damp'} = App::GUI::Wx::Widget::Custom::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes frequency over time)', 0, 200, 0);
    $self->{'freq_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'freq_damp_acc'} = App::GUI::Wx::Widget::Custom::SliderCombo->new( $self, 100, 'Acceleration ', 'accelaration of damping factor', 0, 100, 0);
    $self->{'freq_damp_acc_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '/', '+', '-']);
    $self->{'invert_freq'} = Wx::CheckBox->new( $self, -1, ' Inv.');
    $self->{'invert_freq'}->SetToolTip('invert (1/x) pendulum frequency');
    $self->{'neg_freq'} = Wx::CheckBox->new( $self, -1, ' Neg.');
    $self->{'neg_freq'}->SetToolTip('allow frequency to become negative');
    $self->{'invert_dir'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'invert_dir'}->SetToolTip('invert pendulum direction (to counter clockwise)');
    $self->{'half_off'} = Wx::CheckBox->new( $self, -1, ' 180');
    $self->{'half_off'}->SetToolTip("$help starts with offset of half rotation");
    $self->{'quarter_off'} = Wx::CheckBox->new( $self, -1, ' 90');
    $self->{'quarter_off'}->SetToolTip("$help starts with offset of quater rotation");
    $self->{'offset'} = App::GUI::Wx::Widget::Custom::SliderCombo->new
                            ($self, 110, 'Offset', "additional offset $help starts with (0 - quater rotation)", 0, 100, 0);
    $self->{'radius'} = App::GUI::Wx::Widget::Custom::SliderCombo->new( $self, 100, 'Radius %', "radius / amplitude of $help swing", 0, 200, 100);
    $self->{'radius_factor'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[70, 20], [@const_names]);
    $self->{'radius_factor'}->SetToolTip('base factor the radius will be multiplied with: one (no), or a math constants as shown');
    $self->{'neg_radius'} = Wx::CheckBox->new( $self, -1, ' Neg.');
    $self->{'neg_radius'}->SetToolTip('allow radius to become negative');
    $self->{'radius_damp'} = App::GUI::Wx::Widget::Custom::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes amplitude over time)', 0, 200, 0);
    $self->{'radius_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'radius_damp_acc'} = App::GUI::Wx::Widget::Custom::SliderCombo->new( $self, 100, 'Acceleration ', 'accelaration of damping factor', 0, 100, 0);
    $self->{'radius_damp_acc_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '/', '+', '-']);
    $self->{'reset_radius'} = Wx::Button->new( $self, -1, '1', [-1,-1], [35, 17] );
    $self->{'reset_radius'}->SetToolTip('reset radius to 100 %');

    Wx::Event::EVT_BUTTON( $self, $self->{'reset_radius'}, sub { $self->{'radius'}->SetValue(100) });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'},         sub { $self->update_enable(); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{ $_ },         sub { $self->{'callback'}->() })
        for qw/invert_freq invert_dir neg_freq half_off quarter_off neg_radius/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{ $_ },         sub { $self->{'callback'}->() })
        for qw/freq_factor freq_damp_type freq_damp_acc_type radius_damp_type radius_damp_acc_type/;

    my $base_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr = $base_attr | &Wx::wxTOP | &Wx::wxBOTTOM;

    my $fd = 6;
    $fd += 3 if lc $label eq 'f';
    $fd-- if lc $label eq 'w';
    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->Add( $self->{'on'},        0, $base_attr, 0);
    $f_sizer->Add( $main_label,          0, $base_attr|&Wx::wxTOP|&Wx::wxLEFT, $fd);
    $f_sizer->Add( $self->{'frequency'}, 0, $base_attr|&Wx::wxLEFT, 5);
    $f_sizer->AddSpacer( 18 );
    $f_sizer->Add( $self->{'freq_factor'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $f_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $fdez_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $fdez_sizer->Add( $self->{'freq_dez'},    0, $base_attr|&Wx::wxLEFT, 51);
    $fdez_sizer->AddSpacer( 5 );
    $fdez_sizer->Add( $self->{'invert_freq'}, 0, $base_attr|&Wx::wxLEFT, 9);
    $fdez_sizer->Add( $self->{'invert_dir'},   0, $base_attr|&Wx::wxLEFT, 7);
    $fdez_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $f_damp_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_damp_sizer->Add( $self->{'freq_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $f_damp_sizer->AddSpacer( 19 );
    $f_damp_sizer->Add( $self->{'freq_damp_type'}, 0, $box_attr |&Wx::wxLEFT, 0);
    $f_damp_sizer->AddSpacer( 12 );
    $f_damp_sizer->Add( $self->{'neg_freq'}, 0, $box_attr|&Wx::wxLEFT,  0);
    $f_damp_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $f_acc_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_acc_sizer->Add( $self->{'freq_damp_acc'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 25);
    $f_acc_sizer->AddSpacer( 19 );
    $f_acc_sizer->Add( $self->{'freq_damp_acc_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $f_acc_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $offset_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $offset_sizer->AddSpacer( 65 );
    $offset_sizer->Add( $self->{'offset'},      0, $box_attr,  8);
    $offset_sizer->Add( $self->{'quarter_off'}, 0, $base_attr|&Wx::wxLEFT, 8);
    $offset_sizer->Add( $self->{'half_off'},    0, $base_attr|&Wx::wxLEFT, 8);
    $offset_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $r_sizer->Add( $self->{'radius'},   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  50);
    $r_sizer->AddSpacer( 18 );
    $r_sizer->Add( $self->{'radius_factor'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_sizer->AddSpacer( 18 );
    $r_sizer->Add( $self->{'reset_radius'}, 0, $box_attr,  2);
    $r_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_damp_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_damp_sizer->Add( $self->{'radius_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $r_damp_sizer->AddSpacer( 18 );
    $r_damp_sizer->Add( $self->{'radius_damp_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_damp_sizer->AddSpacer( 12 );
    $r_damp_sizer->Add( $self->{'neg_radius'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_damp_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $r_acc_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_acc_sizer->Add( $self->{'radius_damp_acc'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 25);
    $r_acc_sizer->AddSpacer( 18 );
    $r_acc_sizer->Add( $self->{'radius_damp_acc_type'}, 0, $box_attr |&Wx::wxLEFT,  0);
    $r_acc_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 5 );
    $sizer->Add( $f_sizer,      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 0);
    $sizer->Add( $fdez_sizer,   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $f_damp_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $f_acc_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $offset_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP ,  8);
    $sizer->Add( $r_sizer,      0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP ,  8);
    $sizer->Add( $r_damp_sizer, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->Add( $r_acc_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 13);
    $sizer->AddSpacer( 5 );
    $self->SetSizer($sizer);
    $self->init();
    $self;
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    $self->{ $_ }->SetCallBack( $code ) for qw /radius radius_damp radius_damp_acc offset
                                                freq_damp_acc frequency freq_dez freq_damp/;
}

sub init {
    my ( $self ) = @_;
    $self->set_settings ({
        on => $self->{'initially_on'},
        frequency => 1, freq_factor => 1, freq_damp => 0, freq_damp_type => '*',
        freq_damp_acc => 0,freq_damp_acc_type => '*', invert_dir => 0, invert_freq => 0, neg_freq => 0,
        offset => 0, radius => 1, radius_factor => 1, radius_damp => 0, radius_damp_acc => 0,
        neg_radius => 0, radius_damp_type => '*', radius_damp_acc_type => '*' } );
}

sub get_settings {
    my ( $self ) = @_;
    {
        on          => $self->{ 'on' }->IsChecked ? 1 : 0,
        invert_dir  => $self->{ 'invert_dir'}->IsChecked ? 1 : 0,
        invert_freq => $self->{ 'invert_freq'}->IsChecked ? 1 : 0,
        neg_freq    => $self->{ 'neg_freq'}->IsChecked ? 1 : 0,
        neg_radius  => $self->{ 'neg_radius'}->IsChecked ? 1 : 0,
        frequency   => $self->{'frequency'}->GetValue + $self->{'freq_dez'}->GetValue/1000,
        freq_factor => $const{$self->{'freq_factor'}->GetValue},
        freq_damp   => $self->{'freq_damp'}->GetValue,
        freq_damp_type => $self->{'freq_damp_type'}->GetValue,
        freq_damp_acc => $self->{'freq_damp_acc'}->GetValue,
        freq_damp_type => $self->{'freq_damp_type'}->GetValue,
        freq_damp_acc_type  => $self->{'freq_damp_acc_type'}->GetValue,
        offset      => (0.5 * $self->{'half_off'}->IsChecked)
                     + (0.25 * $self->{'quarter_off'}->IsChecked)
                     + ($self->{'offset'}->GetValue / 400),
        radius       => $self->{'radius'}->GetValue / 100,
        radius_factor => $const{$self->{'radius_factor'}->GetValue},
        radius_damp    => $self->{'radius_damp'}->GetValue,
        radius_damp_acc => $self->{'radius_damp_acc'}->GetValue,
        radius_damp_type => $self->{'radius_damp_type'}->GetValue,
        radius_damp_acc_type => $self->{'radius_damp_acc_type'}->GetValue,
    }
}

sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'frequency'}
        and exists $settings->{'offset'} and exists $settings->{'radius'};

    $self->{ 'freq_factor'}->SetValue( 1 );
    $self->{ 'radius_factor'}->SetValue( 1 );
    if (exists $settings->{'freq_factor'} and $settings->{'freq_factor'}){
        for my $label (@const_names) {
            $self->{ 'freq_factor'}->SetValue( $label ) if abs($const{ $label } - $settings->{'freq_factor'}) < 0.0001;
        }
    }
    if (exists $settings->{'radius_factor'} and $settings->{'radius_factor'}){
        for my $label (@const_names) {
            $self->{ 'radius_factor'}->SetValue( $label ) if abs($const{ $label } - $settings->{'radius_factor'}) < 0.0001;
        }
    }
    $self->{ 'on' }->SetValue( $settings->{'on'} );
    $self->{ 'invert_dir' }->SetValue( $settings->{'invert_dir'} );
    $self->{ 'invert_freq' }->SetValue( $settings->{'invert_freq'} );
    $self->{ 'neg_freq' }->SetValue( $settings->{'neg_freq'} );
    $self->{ 'neg_radius' }->SetValue( $settings->{'neg_radius'} );
    $self->{ 'frequency'}->SetValue( int $settings->{'frequency'}, 'passive' );
    $self->{ 'freq_dez' }->SetValue( int( 1000 * ($settings->{'frequency'} - int $settings->{'frequency'} ) ), 'passive' );

    $self->{ 'freq_damp' }->SetValue( $settings->{'freq_damp'}, 'passive' );
    $self->{ 'freq_damp_acc' }->SetValue( $settings->{'freq_damp_acc'}, 'passive' );
    $self->{ 'freq_damp_type'}->SetValue(  $settings->{ 'freq_damp_type'} // '-' );
    $self->{ 'freq_damp_acc_type'}->SetValue(  $settings->{ 'freq_damp_acc_type'} // '+' );
    $self->{ 'half_off' }->SetValue( $settings->{'offset'} >= 0.5 );
    $settings->{ 'offset' } -= 0.5 if $settings->{'offset'} >= 0.5;
    $self->{ 'quarter_off' }->SetValue( $settings->{'offset'} >= 0.25 );
    $settings->{ 'offset' } -= 0.25 if $settings->{'offset'} >= 0.25;
    $self->{ 'offset'}->SetValue( int( $settings->{'offset'} * 400 ), 'passive');
    $self->{ 'radius' }->SetValue( $settings->{'radius'} * 100, 'passive' );
    $self->{ 'radius_damp' }->SetValue( $settings->{'radius_damp'}, 'passive' );
    $self->{ 'radius_damp_acc' }->SetValue( $settings->{'radius_damp_acc'}, 'passive');
    $self->{ 'radius_damp_type'}->SetValue(  $settings->{ 'radius_damp_type'} // '-' );
    $self->{ 'radius_damp_acc_type'}->SetValue(  $settings->{ 'radius_damp_acc_type'} // '+' );
    $self->update_enable;
    1;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for qw/
        freq_dez freq_factor invert_freq invert_dir neg_freq half_off quarter_off offset
        frequency freq_damp freq_damp_acc freq_damp_type freq_damp_acc_type
        radius radius_factor neg_radius reset_radius
        radius_damp radius_damp_acc radius_damp_type radius_damp_acc_type/;
}

1;
