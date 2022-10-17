use v5.12;
use utf8;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::Pendulum;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

sub new {
    my ( $class, $parent, $label, $help, $on, $max ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'name'} = $label;
    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;
    $self->{'callback'} = sub {};

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1], [-1,-1], $on );
    $self->{'on'}->SetToolTip('set partial pendulum on or off');
    
    my $lbl  = Wx::StaticText->new($self, -1, uc($label) );

    $self->{'radius'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Radius %', 'radius or amplitude of pendulum swing', 0, 150, 100);
    $self->{'radius_damp'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes amplitude over time)', 0, 800, 0);
    $self->{'radius_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'radius_damp_acc'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Acceleration ', 'accelaration of damping factor', 0, 100, 0);
    $self->{'radius_damp_acc_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '/', '+', '-']);
    $self->{'frequency'}  = App::GUI::Harmonograph::Widget::SliderCombo->new
                        ( $self, 100, 'Frequency', 'frequency of '.$help, 1, $max, 1 );
    $self->{'freq_dez'} = App::GUI::Harmonograph::Widget::SliderCombo->new
                        ( $self, 100, 'Decimals', 'decimals of frequency at '.$help, 0, 1000, 0);
    my @factor = grep {lc $_ ne lc $self->{'name'}} qw/1 π Φ φ Γ e X Y Z R/;
    $self->{'freq_factor'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[70, 20], \@factor);
    $self->{'freq_factor'}->SetToolTip('base factor frequency will be multiplied with: one (no), math constants or frequency of other pendula');
    $self->{'freq_damp'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Damp  ', 'damping factor (diminishes frequency over time)', 0, 400, 0);
    $self->{'freq_damp_type'} = Wx::ComboBox->new( $self, -1, '*', [-1,-1],[70, 20], [ '*', '-']);
    $self->{'invert_freq'} = Wx::CheckBox->new( $self, -1, ' Inv.');
    $self->{'invert_freq'}->SetToolTip('invert (1/x) pendulum frequency');
    $self->{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'direction'}->SetToolTip('invert pendulum direction (to counter clockwise)');
    $self->{'half_off'} = Wx::CheckBox->new( $self, -1, ' 180');
    $self->{'half_off'}->SetToolTip('pendulum starts with offset of half rotation');
    $self->{'quarter_off'} = Wx::CheckBox->new( $self, -1, ' 90');
    $self->{'quarter_off'}->SetToolTip('pendulum starts with offset of quater rotation');
    $self->{'offset'} = App::GUI::Harmonograph::Widget::SliderCombo->new
                            ($self, 110, 'Offset', 'additional offset pendulum starts with (0 - quater rotation)', 0, 100, 0);
                            
    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'},          sub { $self->update_enable(); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'invert_freq'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'direction'},   sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'half_off'},    sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'quarter_off'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'freq_factor'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'freq_damp_type'},       sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'radius_damp_type'},     sub {                $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'radius_damp_acc_type'}, sub {                $self->{'callback'}->() });
    
    my $base_attr = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr = $base_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $r_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $r_sizer->Add( $self->{'on'},       0, $base_attr| &Wx::wxLEFT, 0);
    $r_sizer->Add( $lbl,                0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $r_sizer->Add( $self->{'radius'},   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $r_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $rd_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $rd_sizer->Add( $self->{'radius_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $rd_sizer->AddSpacer( 17 );
    $rd_sizer->Add( $self->{'radius_damp_type'}, 0, $box_attr |&Wx::wxLEFT,  7);
    $rd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $ra_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $ra_sizer->Add( $self->{'radius_damp_acc'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 25);
    $ra_sizer->AddSpacer( 18 );
    $ra_sizer->Add( $self->{'radius_damp_acc_type'}, 0, $box_attr |&Wx::wxLEFT,  7);
    $ra_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->Add( $self->{'frequency'}, 0, $base_attr|&Wx::wxLEFT, 40);
    $f_sizer->AddSpacer( 18 );
    $f_sizer->Add( $self->{'freq_factor'}, 0, $box_attr |&Wx::wxLEFT,  7);
    $f_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $fd_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $fd_sizer->Add( $self->{'freq_dez'},    0, $base_attr|&Wx::wxLEFT, 49);
    $fd_sizer->Add( $self->{'invert_freq'}, 0, $base_attr|&Wx::wxLEFT, 9);
    $fd_sizer->Add( $self->{'direction'},   0, $base_attr|&Wx::wxLEFT, 7);
    $fd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $f_damp_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_damp_sizer->Add( $self->{'freq_damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT, 62);
    $f_damp_sizer->AddSpacer( 17 );
    $f_damp_sizer->Add( $self->{'freq_damp_type'}, 0, $box_attr |&Wx::wxLEFT, 7);
    $f_damp_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $o_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $o_sizer->AddSpacer( 65 );
    $o_sizer->Add( $self->{'offset'},      0, $box_attr,  8);
    $o_sizer->Add( $self->{'quarter_off'}, 0, $base_attr|&Wx::wxLEFT, 8);
    $o_sizer->Add( $self->{'half_off'},    0, $base_attr|&Wx::wxLEFT, 8);
    $o_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $r_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 2);
    $sizer->Add( $rd_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 4);
    $sizer->Add( $ra_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 6);
    $sizer->Add( $f_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 6);
    $sizer->Add( $fd_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 6);
    $sizer->Add( $f_damp_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 4);
    $sizer->Add( $o_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW| &Wx::wxTOP , 0);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ on => $self->{'initially_on'}, radius => 1, frequency => 1, freq_factor => 1, offset => 0,
        freq_damp => 0, freq_damp_type => '*', radius_damp => 0, radius_damp_acc => 0, radius_damp_type => '*', radius_damp_acc_type => '*' } );
}

sub get_data {
    my ( $self ) = @_;
    my $f = $self->{'frequency'}->GetValue + $self->{'freq_dez'}->GetValue/1000;
    $f = 1 / $f if $self->{ 'invert_freq' }->IsChecked;
    $f =    -$f if $self->{ 'direction' }->IsChecked;
    {
        on          => $self->{ 'on' }->IsChecked ? 1 : 0,
        frequency   => $f,
        freq_factor => $self->{'freq_factor'}->GetValue,
        freq_damp   => $self->{'freq_damp'}->GetValue,
        freq_damp_type => $self->{'freq_damp_type'}->GetValue,
        offset      => (0.5 * $self->{'half_off'}->IsChecked) 
                     + (0.25 * $self->{'quarter_off'}->IsChecked) 
                     + ($self->{'offset'}->GetValue / 400),
        radius      => $self->{'radius'}->GetValue / 100,
        radius_damp => $self->{'radius_damp'}->GetValue,
        radius_damp_acc  => $self->{'radius_damp_acc'}->GetValue,
        radius_damp_type => $self->{'radius_damp_type'}->GetValue,
        radius_damp_acc_type  => $self->{'radius_damp_acc_type'}->GetValue,
    }
}

sub SetCallBack {    
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    $self->{ $_ }->SetCallBack( $code ) for qw /radius radius_damp radius_damp_acc frequency freq_dez freq_damp offset/;
}


sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'frequency'}
        and exists $data->{'offset'} and exists $data->{'radius'} and exists $data->{'radius_damp'};
    $self->{ 'data'} = $data;
    $self->{ 'on' }->SetValue( $data->{'on'} );
    $self->{ 'direction' }->SetValue( $data->{'frequency'} < 0 );
    $data->{ 'frequency'} = abs $data->{'frequency'};
    $self->{ 'invert_freq' }->SetValue( $data->{'frequency'} < 1 );
    $data->{ 'frequency'} = 1 / $data->{'frequency'} if $data->{'frequency'} < 1;
    $self->{ 'frequency' }->SetValue( int $data->{'frequency'}, 1 );
    $self->{ 'freq_dez' }->SetValue( int( 1000 * ($data->{'frequency'} - int $data->{'frequency'} ) ), 'passive' );
    $self->{ 'freq_factor'}->SetValue(  $data->{ 'freq_factor'} // 0 );
    $self->{ 'freq_damp' }->SetValue( $data->{'freq_damp'}, 'passive' );
    $self->{ 'freq_damp_type'}->SetValue(  $data->{ 'freq_damp_type'} // '*' );
    $self->{ 'half_off' }->SetValue( $data->{'offset'} >= 0.5 );
    $data->{ 'offset' } -= 0.5 if $data->{'offset'} >= 0.5;
    $self->{ 'quarter_off' }->SetValue( $data->{'offset'} >= 0.25 );
    $data->{ 'offset' } -= 0.25 if $data->{'offset'} >= 0.25;
    $self->{ 'offset'}->SetValue( int( $data->{'offset'} * 400 ), 'passive');
    $self->{ 'radius' }->SetValue( $data->{'radius'} * 100, 'passive' );
    $self->{ 'radius_damp' }->SetValue( $data->{'radius_damp'}, 'passive' );
    $self->{ 'radius_damp_acc' }->SetValue( $data->{'radius_damp_acc'}, 'passive');
    $self->{ 'radius_damp_type'}->SetValue(  $data->{ 'radius_damp_type'} // '*' );
    $self->{ 'radius_damp_acc_type'}->SetValue(  $data->{ 'radius_damp_acc_type'} // '*' );
    $self->update_enable;
    1;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for qw/frequency freq_damp freq_damp_type freq_dez freq_factor invert_freq direction 
        half_off quarter_off offset  radius radius_damp radius_damp_acc radius_damp_type radius_damp_acc_type/;
}

1;
