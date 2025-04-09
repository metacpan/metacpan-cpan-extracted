
# tab with visual settings, line dots and color flow (change)

package App::GUI::Harmonograph::Frame::Tab::Visual;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Widget::SliderCombo;

my $default_settings = {
        draw => 'line', pen_style => 'solid', line_thickness => 1, dot_probability => 100,
        duration=> 60, dot_density => 200, colors_used => 2,
        color_flow_type => 'no', color_flow_dynamic => 0, color_flow_speed => 4, invert_flow_speed => 0,
};
my @state_keys = keys %$default_settings;
my @state_widgets = qw/line_thickness pen_style dot_probability color_flow_type
                       color_flow_dynamic color_flow_speed invert_flow_speed colors_used/;
my @widget_keys;

sub new {
    my ($class, $parent, $color_tab) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    return unless ref $color_tab eq 'App::GUI::Harmonograph::Frame::Tab::Color';
    $self->{'callback'} = sub {};

    $self->{'label'}{'line'}   = Wx::StaticText->new($self, -1, 'Pen Settings' );
    $self->{'label'}{'time'}   = Wx::StaticText->new($self, -1, 'Drawing Duration (Line Length)' );
    $self->{'label'}{'dense'}  = Wx::StaticText->new($self, -1, 'Dot Density' );
    $self->{'label'}{'random'}  = Wx::StaticText->new($self, -1, 'Dot Randomisation' );
    $self->{'label'}{'flow'}   = Wx::StaticText->new($self, -1, 'Color Change' );
    $self->{'label'}{'flow_type'} = Wx::StaticText->new( $self, -1, 'Change Type:');
    $self->{'label'}{'colors'} = Wx::StaticText->new( $self, -1, 'Colors:');
    $self->{'label'}{'pen'}    = Wx::StaticText->new( $self, -1, 'Pen Style:');

    $self->{'widget'}{'draw'} = Wx::RadioBox->new( $self, -1, 'Draw', [-1, -1], [120, -1], ['Dots', 'Line']);
    $self->{'widget'}{'draw'}->SetToolTip('draw just dots (off) or connect them with lines (on)');
    $self->{'widget'}{'pen_style'} = Wx::ComboBox->new( $self, -1, 'solid', [-1,-1], [125, -1],
        [qw/dotted short_dash solid vertical horizontal cross diagonal bidiagonal/], &Wx::wxTE_READONLY );
    $self->{'widget'}{'pen_style'}->SetToolTip('which pattern is engraved in drawn line / dots');
    $self->{'widget'}{'line_thickness'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 355, 'Thickness','dot size or thickness of drawn line in pixel',  1,  55,  1);
    $self->{'widget'}{'duration_min'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 85, 'Minutes','', 0,  100,  10);
    $self->{'widget'}{'duration_s'}   = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 85, 'Seconds','', 0,  59,  10);
    $self->{'widget'}{'dot_probability'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 340, 'Probability','', 1,  100,  100, .1);
    $self->{'widget'}{'dot_probability'}->SetToolTip("How high is the chance that a dot is actually set in percent ?");
    $self->{'widget'}{'100dots_per_second'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 110, 'Coarse','how many dots is drawn in a second in batches of 50 ?',  0,  90,  10);
    $self->{'widget'}{'dots_per_second'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 100, 'Fine','how many dots is drawn in a second ?',  0,  99,  10);
    $self->{'widget'}{'color_flow_type'} = Wx::ComboBox->new( $self, -1, 'no', [-1,-1], [115, -1], [qw/no one_time alternate circular/], &Wx::wxTE_READONLY );
    $self->{'widget'}{'color_flow_type'}->SetToolTip("type of color flow: - linear - from start to end color \n  - alter(nate) - linearly between start and end color \n   - cicular - around the rainbow from start color visiting end color");
    $self->{'label'}{'flow_type'}->SetToolTip("type of color flow: - linear - from start to end color \n  - alter(nate) - linearly between start and end color \n   - cicular - around the rainbow from start color visiting end color");
    $self->{'widget'}{'color_flow_dynamic'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 115, 'Dynamic', '0 = equally paced color change, larger = starting with slow color change becoming faster - or vice versa when dir activated', -12,  12,  0, .01);
    $self->{'widget'}{'color_flow_speed'} = App::GUI::Harmonograph::Widget::SliderCombo->new( $self, 116, 'Speed','color changes per minute', 1, 90, 1, .1);
    $self->{'widget'}{'invert_flow_speed'} = Wx::CheckBox->new( $self, -1, ' Invert');
    $self->{'widget'}{'invert_flow_speed'}->SetToolTip("invert value of color change speed by 1/x");

    $self->{'widget'}{'colors_used'} = Wx::ComboBox->new( $self, -1, 2, [-1,-1], [75, -1], [2 .. 10], &Wx::wxTE_READONLY );
    $self->{'widget'}{'colors_used'}->SetToolTip("Select how many colors will be used / changed between.");
    $self->{'label'}{'colors'}->SetToolTip("Select how many colors will be used / changed between.");
    @widget_keys = keys %{$self->{'widget'}};

    Wx::Event::EVT_RADIOBOX( $self, $self->{'widget'}{'draw'},              sub { $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'widget'}{'invert_flow_speed'}, sub { $self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{'pen_style'},         sub { $self->{'callback'}->(); });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{'color_flow_type'},   sub { $self->update_enable; $self->{'callback'}->(); });
    Wx::Event::EVT_COMBOBOX( $self, $self->{'widget'}{'colors_used'},       sub {
        $color_tab->set_active_color_count( $self->{'widget'}{'colors_used'}->GetString($_[1]->GetInt) );
        $self->{'callback'}->();
    });
    $self->{'widget'}{ $_ }->SetCallBack( sub {  $self->{'callback'}->() } )
        for qw/line_thickness dot_probability duration_min duration_s
               100dots_per_second dots_per_second color_flow_dynamic color_flow_speed/;

    my $std_attr  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box_attr  = $std_attr | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $all_attr = &Wx::wxALL | &Wx::wxALIGN_CENTER_HORIZONTAL | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;

    my $line_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $line_sizer->AddSpacer( 60 );
    $line_sizer->Add( $self->{'widget'}{'draw'},        0, $std_attr| &Wx::wxBOTTOM, 10);
    $line_sizer->AddSpacer( 85 );
    $line_sizer->Add( $self->{'label'}{'pen'},           0, $all_attr, 18);
    $line_sizer->AddSpacer( 2 );
    $line_sizer->Add( $self->{'widget'}{'pen_style'},    0, $box_attr,  8);
    $line_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $l2_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $l2_sizer->AddSpacer( 20 );
    $l2_sizer->Add( $self->{'widget'}{'line_thickness'},  0, $box_attr, 5);
    $l2_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $random_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $random_sizer->AddSpacer( 20 );
    $random_sizer->Add( $self->{'widget'}{'dot_probability'},  0, $box_attr, 5);
    $random_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $time_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $time_sizer->AddSpacer( 20 );
    $time_sizer->Add( $self->{'widget'}{'duration_min'},  0, $box_attr, 5);
    $time_sizer->AddSpacer( 20 );
    $time_sizer->Add( $self->{'widget'}{'duration_s'},    0, $box_attr, 5);
    $time_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $dense_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $dense_sizer->AddSpacer( 20 );
    $dense_sizer->Add( $self->{'widget'}{'100dots_per_second'},  0, $box_attr, 5);
    $dense_sizer->AddSpacer( 20 );
    $dense_sizer->Add( $self->{'widget'}{'dots_per_second'},     0, $box_attr, 5);
    $dense_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $color_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $color_sizer->AddSpacer( 20 );
    $color_sizer->Add( $self->{'label'}{'flow_type'},            0, $box_attr, 11);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'widget'}{'color_flow_type'},     0, $box_attr, 5);
    $color_sizer->AddSpacer( 20 );
    $color_sizer->Add( $self->{'widget'}{'color_flow_dynamic'},  0, $box_attr, 5);
    $color_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    my $flow_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $flow_sizer->AddSpacer( 20 );
    $flow_sizer->Add( $self->{'label'}{'colors'},             0, $box_attr, 11);
    $flow_sizer->AddSpacer( 10 );
    $flow_sizer->Add( $self->{'widget'}{'colors_used'},       0, $box_attr, 5);
    $flow_sizer->AddSpacer( 50 );
    $flow_sizer->Add( $self->{'widget'}{'invert_flow_speed'},      0, $box_attr, 5);
    $flow_sizer->AddSpacer( 10 );
    $flow_sizer->Add( $self->{'widget'}{'color_flow_speed'},  0, $box_attr, 5);
    $flow_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'label'}{'line'},        0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $line_sizer,                     0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( $l2_sizer,                       0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'random'},      0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $random_sizer,                   0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'dense'},       0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $dense_sizer,                    0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'time'},        0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $time_sizer,                     0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( $self->{'label'}{'flow'},        0, &Wx::wxALIGN_CENTER_HORIZONTAL,  0);
    $sizer->Add( $color_sizer,                    0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( $flow_sizer,                     0, $std_attr|&Wx::wxTOP,           10);
    $sizer->Add( Wx::StaticLine->new($self, -1),  0, $box_attr,                      10);
    $sizer->Add( 0, 1, $std_attr );
    $self->SetSizer( $sizer );
    $self->init();
    $self;
}

sub init         { $_[0]->set_settings( $default_settings ) }
sub set_settings {
    my ( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH' and exists $settings->{'draw'};
    $settings->{ $_ } //= $default_settings->{ $_ } for @state_keys;
    $self->{'widget'}{ $_ }->SetValue( $settings->{ $_ } ) for @state_widgets;

    $self->{'widget'}{'draw'}->SetSelection(
        lc $settings->{'draw'} eq lc $self->{'widget'}{'draw'}->GetString(1) ? 1 : 0);
    $self->{'widget'}{ 'duration_min' }->SetValue( int($settings->{ 'duration'} / 60), 'passive');
    $self->{'widget'}{ 'duration_s' }->SetValue(       $settings->{ 'duration'} % 60, 'passive');
    $self->{'widget'}{ '100dots_per_second'}->SetValue( int($settings->{ 'dot_density'} / 100), 'passive');
    $self->{'widget'}{ 'dots_per_second' }->SetValue(       $settings->{ 'dot_density'} % 100, 'passive');
    $self->update_enable;
    1;
}
sub get_settings {
    my ( $self ) = @_;
    my $settings = { map { $_ => $self->{'widget'}{$_}->GetValue } @state_widgets};
    $settings->{'duration'} = ($self->{'widget'}{ 'duration_min' }->GetValue * 60)
                             + $self->{'widget'}{ 'duration_s' }->GetValue;
    $settings->{'dot_density'} = ($self->{'widget'}{ '100dots_per_second' }->GetValue * 100)
                                + $self->{'widget'}{ 'dots_per_second' }->GetValue;
    $settings->{'draw'} = $self->{'widget'}{'draw'}->GetString( $self->{'widget'}{ 'draw' }->GetSelection );
    $settings;
}

sub update_enable {
    my ( $self ) = @_;
    my $type = $self->{'widget'}{'color_flow_type'}->GetValue;
    if      ($type eq 'no'){
        $self->{'widget'}{$_}->Enable(0) for qw/color_flow_speed invert_flow_speed colors_used color_flow_dynamic/;
    } elsif ($type eq 'one_time'){
        $self->{'widget'}{$_}->Enable(1) for qw/color_flow_speed invert_flow_speed colors_used color_flow_dynamic/;
        $self->{'widget'}{'color_flow_speed'}->Enable(0);
        $self->{'widget'}{'invert_flow_speed'}->Enable(0);
    } else {
        $self->{'widget'}{$_}->Enable(1) for qw/color_flow_speed invert_flow_speed colors_used color_flow_dynamic/;
    }
}

sub SetCallBack {
    my ( $self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}

1;
