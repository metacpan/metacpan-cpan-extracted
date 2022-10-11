use v5.12;
use utf8;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::Pendulum;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::SliderCombo;

sub new {
    my ( $class, $parent, $label, $help, $on, $max,  ) = @_;
    return unless defined $max;
    my $self = $class->SUPER::new( $parent, -1);

    $self->{'name'} = $label;
    $self->{'maxf'} = $max;
    $self->{'initially_on'} = $on;
    $self->{'callback'} = sub {};

    $self->{'on'} = Wx::CheckBox->new( $self, -1, '', [-1,-1],[-1,-1], 1 );
    $self->{'on'}->SetToolTip('set partial pendulum on or off');
    
    my $lbl  = Wx::StaticText->new($self, -1, uc($label) );

    $self->{'frequency'}  = App::GUI::Harmonograph::SliderCombo->new
                        ( $self, 100, 'f', 'frequency of '.$help, 1, $max, 1 );
    $self->{'freq_dez'} = App::GUI::Harmonograph::SliderCombo->new
                        ( $self, 100, 'f dec.', 'decimals of frequency at '.$help, 0, 1000, 0);
    $self->{'freq_factor'} = Wx::ComboBox->new( $self, -1, 1, [-1,-1],[70, -1], [1, 'π', 'Φ', 'φ', 'e', 'X','Y','Z','R'], 1);
    $self->{'freq_factor'}->SetToolTip('base factor of frequency: one, math constants or frequency of other pendula');
    $self->{'invert_freq'} = Wx::CheckBox->new( $self, -1, ' Inv.');
    $self->{'invert_freq'}->SetToolTip('invert (1/x) pendulum frequency');
    $self->{'direction'} = Wx::CheckBox->new( $self, -1, ' Dir.');
    $self->{'direction'}->SetToolTip('invert pendulum direction (to counter clockwise)');
    $self->{'half_off'} = Wx::CheckBox->new( $self, -1, ' 2');
    $self->{'half_off'}->SetToolTip('pendulum starts with offset of half rotation');
    $self->{'quarter_off'} = Wx::CheckBox->new( $self, -1, ' 4');
    $self->{'quarter_off'}->SetToolTip('pendulum starts with offset of quater rotation');
    $self->{'offset'} = App::GUI::Harmonograph::SliderCombo->new
                            ($self, 110, 'Offset', 'additional offset pendulum starts with (0 - quater rotation)', 0, 100, 0);
                            
                            
    $self->{'radius'} = App::GUI::Harmonograph::SliderCombo->new( $self, 100, 'r', 'radius or amplitude of pendulum swing', 0, 150, 100);
    $self->{'damp'} = App::GUI::Harmonograph::SliderCombo->new( $self, 100, 'Damp', 'damping factor (diminishes amplitude over time)', 0, 1000, 0);


    Wx::Event::EVT_CHECKBOX( $self, $self->{'on'},          sub { $self->update_enable(); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'invert_freq'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'direction'},   sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'half_off'},    sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'quarter_off'}, sub {                         $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'freq_factor'}, sub {                         $self->{'callback'}->() });
    
    my $base_attr = &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW;
    my $r_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $r_sizer->Add( $self->{'on'},       0, $base_attr| &Wx::wxLEFT, 0);
    $r_sizer->Add( $lbl,                0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $r_sizer->Add( $self->{'radius'},   0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $r_sizer->Add( $self->{'damp'},     0, &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxLEFT,  0);
    $r_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $f_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $f_sizer->Add( $self->{'frequency'}, 0, $base_attr|&Wx::wxLEFT,    49);
    $f_sizer->Add( $self->{'freq_dez'},  0, $base_attr|&Wx::wxLEFT||&Wx::wxTOP|&Wx::wxBOTTOM,  11);
    $f_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $o_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $o_sizer->AddSpacer( 26 );
    $o_sizer->Add( $self->{'freq_factor'}, 0, $base_attr|&Wx::wxTOP|&Wx::wxBOTTOM, 15);
    $o_sizer->Add( $self->{'invert_freq'}, 0, $base_attr|&Wx::wxLEFT,  8);
    $o_sizer->Add( $self->{'direction'},   0, $base_attr|&Wx::wxLEFT,  8);
    $o_sizer->Add( $self->{'half_off'},    0, $base_attr|&Wx::wxLEFT, 14);
    $o_sizer->Add( $self->{'quarter_off'}, 0, $base_attr|&Wx::wxLEFT,  8);
    $o_sizer->Add( $self->{'offset'},      0, $base_attr|&Wx::wxTOP|&Wx::wxBOTTOM,  10);
    $o_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);
    
    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $r_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $f_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $sizer->Add( $o_sizer,  0, &Wx::wxALIGN_LEFT|&Wx::wxGROW, 0);
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init {
    my ( $self ) = @_;
    $self->set_data ({ on => $self->{'initially_on'}, radius => 1, frequency => 1, factor => 1, offset => 0, damp => 0} );
}

sub get_data {
    my ( $self ) = @_;
    my $f = $self->{'frequency'}->GetValue + $self->{'freq_dez'}->GetValue/1000;
    $f = 1 / $f if $self->{ 'invert_freq' }->IsChecked;
    $f =    -$f if $self->{ 'direction' }->IsChecked;
    {
        on        => $self->{ 'on' }->IsChecked ? 1 : 0,
        frequency => $f,
        factor    => $self->{'freq_factor'}->GetValue,
        offset    => (0.5 * $self->{'half_off'}->IsChecked) 
                   + (0.25 * $self->{'quarter_off'}->IsChecked) 
                   + ($self->{'offset'}->GetValue / 400),
        radius    => $self->{'radius'}->GetValue / 100,
        damp      => $self->{'damp'}->GetValue,
    }
}

sub SetCallBack {    
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
    $self->{ $_ }->SetCallBack( $code ) for qw /radius damp frequency freq_dez offset/;
}


sub set_data {
    my ( $self, $data ) = @_;
    return unless ref $data eq 'HASH' and exists $data->{'frequency'}
        and exists $data->{'offset'} and exists $data->{'radius'} and exists $data->{'damp'};
    $self->{ 'data'} = $data;
    $self->{ 'on' }->SetValue( $data->{'on'} );
    $self->{ 'direction' }->SetValue( $data->{'frequency'} < 0 );
    $data->{ 'frequency'} = abs $data->{'frequency'};
    $self->{ 'invert_freq' }->SetValue( $data->{'frequency'} < 1 );
    $data->{ 'frequency'} = 1 / $data->{'frequency'} if $data->{'frequency'} < 1;
    $self->{ 'frequency' }->SetValue( int $data->{'frequency'}, 1 );
    $self->{ 'freq_dez' }->SetValue( int( 1000 * ($data->{'frequency'} - int $data->{'frequency'} ) ), 1 );
    $self->{ 'freq_factor'}->SetValue(  $data->{ 'factor'} );
    $self->{ 'half_off' }->SetValue( $data->{'offset'} >= 0.5 );
    $data->{ 'offset' } -= 0.5 if $data->{'offset'} >= 0.5;
    $self->{ 'quarter_off' }->SetValue( $data->{'offset'} >= 0.25 );
    $data->{ 'offset' } -= 0.25 if $data->{'offset'} >= 0.25;
    $self->{ 'offset'}->SetValue( int( $data->{'offset'} * 400 ), 1);
    $self->{ 'radius' }->SetValue( $data->{'radius'} * 100, 1 );
    $self->{ 'damp' }->SetValue( $data->{'damp'}, 1 );
    $self->update_enable;
    1;
}

sub update_enable {
    my ($self) = @_;
    my $val = $self->{ 'on' }->IsChecked;
    $self->{$_}->Enable( $val ) for qw/frequency freq_dez freq_factor invert_freq direction half_off quarter_off offset radius damp/;
}


1;
