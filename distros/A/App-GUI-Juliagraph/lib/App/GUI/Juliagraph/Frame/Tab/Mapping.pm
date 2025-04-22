
# visible tab with all visual settings

package App::GUI::Juliagraph::Frame::Tab::Mapping;
use v5.12;
use warnings;
use base qw/Wx::Panel/;
use Graphics::Toolkit::Color qw/color/;
use Wx;
use App::GUI::Juliagraph::Widget::SliderStep;
use App::GUI::Juliagraph::Widget::SliderCombo;
use App::GUI::Juliagraph::Widget::ProgressBar;

my $default_settings =  {
        custom_partition => 0, scale_steps => 20, scale_distro => 'square',
        user_colors => 1, begin_color => 'color 2', end_color => 'color 4', background_color => 'black',
        gradient_dynamic => 0, gradient_space => 'HSL',
        use_subgradient => 0, subgradient_size => 500, subgradient_steps => 5,
        subgradient_dynamic => 0, subgradient_space => 'HSL', subgradient_distro => 'sqrt',
    };

sub new {
    my ( $class, $parent, $config ) = @_;

    my $self = $class->SUPER::new( $parent, -1);
    $self->{'config'}   = $config;
    $self->{'callback'} = sub {};
    $self->{'tab'}{'color'} = '';

    my $map_lbl = Wx::StaticText->new($self, -1, 'C o l o r   G r a d i e n t : ' );
    my $color_lbl = Wx::StaticText->new($self, -1, 'User Colors : ' );
    $self->{'lbl_backg'} = Wx::StaticText->new($self, -1, 'Background : ' );
    $self->{'lbl_begin'} = Wx::StaticText->new($self, -1, 'Begin : ' );
    $self->{'lbl_end'}   = Wx::StaticText->new($self, -1, 'End : ' );
    my $map_dyn_lbl = Wx::StaticText->new($self, -1, 'Dynamic : ' );
    my $map_space_lbl = Wx::StaticText->new($self, -1, 'Space : ' );
    my $scale_lbl = Wx::StaticText->new($self, -1, 'P a r t i t i o n i n g   T h e   I t e r a t i o n   S c a l e : ' );
    my $custom_lbl = Wx::StaticText->new($self, -1, 'Custom : ' );
    $self->{'lbl_max'} = Wx::StaticText->new($self, -1, 'Iterations (Size) : ' );
    $self->{'lbl_distro'} = Wx::StaticText->new($self, -1, 'Distribution : ' );
    my $submap_lbl = Wx::StaticText->new($self, -1, 'S u b   G r a d i e n t : ' );
    $self->{'lbl_sub_use'} = Wx::StaticText->new($self, -1, 'Activate : ' );
    $self->{'lbl_sub_dyn'} = Wx::StaticText->new($self, -1, 'Dynamic : ' );
    $self->{'lbl_sub_space'} = Wx::StaticText->new($self, -1, 'Space : ' );
    $self->{'lbl_sub_distro'} = Wx::StaticText->new($self, -1, 'Distribution : ' );
    $map_lbl->SetToolTip('Decide which colors are used to paint the drawing.');
    $color_lbl->SetToolTip('Use slected colors (on) or just simple gray scale (off)');
    $self->{'lbl_backg'}->SetToolTip('Which color is used to paint areas where computation never exceeds the bailout value.');
    $self->{'lbl_begin'}->SetToolTip('Starting color of the rainbow.');
    $self->{'lbl_end'}->SetToolTip('Endcolor of the rainbow');
    $map_dyn_lbl->SetToolTip('How many big is the slant of a color gradient in one or another direction (between the selected colors in next tab)');
    $map_space_lbl->SetToolTip('In which color space will the gradient between chosen colors be computed ?');
    $scale_lbl->SetToolTip('Divide the scale of possible iterations into goups (partitions) that can be mapped to colors.');
    $custom_lbl->SetToolTip('Divide the scale of possible iterations into goups (partitions) that can be mapped to colors. Use every iteration count gets its own color when off.');
    $self->{'lbl_max'}->SetToolTip('Maximal iteration count that gets partitioned.');
    $self->{'lbl_distro'}->SetToolTip('How to compute the partitioning of the iteration scale. Linear means evenly sized portions.');
    $submap_lbl->SetToolTip('Gradients between areas of iteration counts based on final value.');
    $self->{'lbl_sub_use'}->SetToolTip('Make even more fine grained color gradients, my computing gradient between color regions.');
    $self->{'lbl_sub_dyn'}->SetToolTip('How big is the slant of a color sub gradient in one or another direction ?');
    $self->{'lbl_sub_space'}->SetToolTip('In which color space will the subgradient between chosen colors be computed ?');

    my @color_names = map { 'color '.$_ } 1 .. 11;
    $self->{'custom_partition'} = Wx::CheckBox->new( $self, -1,  '', [-1,-1],[30, -1]);
    $self->{'user_colors'}      = Wx::CheckBox->new( $self, -1,  '', [-1,-1],[30, -1]);
    $self->{'use_subgradient'}  = Wx::CheckBox->new( $self, -1,  '', [-1,-1],[30, -1]);
    $self->{'scale_steps'}  = App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 252, 'Steps :', "In how many parts the scale (0 .. max) will be partitioned, meaning: how many different colors/shades we use to paint the fractal", 2, 100, 20);
    $self->{'scale_max'}    = Wx::TextCtrl->new( $self, -1,         0, [-1,-1], [60, -1], &Wx::wxTE_RIGHT | &Wx::wxTE_READONLY);
    $self->{'scale_distro'} = Wx::ComboBox->new( $self, -1, 'linear',  [-1,-1],[100, -1], [qw/log cubert sqrt linear square cube exp/]);
    $self->{'begin_color'}  = Wx::ComboBox->new( $self, -1, 'color 3', [-1,-1],[100, -1], [@color_names]);
    $self->{'end_color'}    = Wx::ComboBox->new( $self, -1, 'color 4', [-1,-1],[100, -1], [@color_names]);
    $self->{'background_color'}   = Wx::ComboBox->new( $self, -1,'black', [-1,-1],[100,-1], [qw/black blue gray white/, 'color 1']);
    $self->{'gradient_dynamic'}   = Wx::ComboBox->new( $self, -1,      0, [-1,-1],[80, -1], [-5, -4, -3, -2.5, -2, -1.6, -1.3, -1, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1, 1.3, 1.6, 2, 2.5, 3, 4, 5]);
    $self->{'gradient_space'}     = Wx::ComboBox->new( $self, -1,  'RGB', [-1,-1],[80, -1], [qw/RGB HSL/]);
    $self->{'subgradient_steps'}  = App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 249, 'Steps :', "How man shades toes the subgradient have ?", 2, 100, 5, 1);
    $self->{'subgradient_size'}   = App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 249, 'Size :', "Up to which value (Bailout/Stop Value + X) does the scale goes, from which subgradient is computed", 100, 5000, 500, 50);
    $self->{'subgradient_space'}  = Wx::ComboBox->new( $self, -1,  'RGB', [-1,-1],[80, -1], [qw/RGB HSL/]);
    $self->{'subgradient_dynamic'}= Wx::ComboBox->new($self, -1,     0, [-1,-1],[80, -1], [-5, -4, -3, -2.5, -2, -1.6, -1.3, -1, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1, 1.3, 1.6, 2, 2.5, 3, 4, 5]);
    $self->{'subgradient_distro'} = Wx::ComboBox->new( $self, -1, 'linear',  [-1,-1],[100, -1], [qw/log cubert sqrt linear square cube exp/]);
    $self->{'custom_partition'}->SetToolTip('Divide the scale of possible iterations into goups (partitions) that can be mapped to colors. Use every iteration count gets its own color when off.');
    $self->{'scale_max'}->SetToolTip('Maximal iteration count.');
    $self->{'scale_distro'}->SetToolTip('Relation between partitions size wise, linear means they all equally big.');
    $self->{'user_colors'}->SetToolTip('Use chosen color selection to compute color rainbow (on) or just a gray scale (off).');
    $self->{'use_subgradient'}->SetToolTip('Make color gradient smoother by computing gradients between colored areas based on final value of iteration.');
    $self->{'begin_color'}->SetToolTip('Starting color of the rainbow.');
    $self->{'end_color'}->SetToolTip('Endcolor of the rainbow');
    $self->{'background_color'}->SetToolTip('Color that is used to paint areas where iteration stays below stop value.');
    $self->{'gradient_dynamic'}->SetToolTip('Skew direction of gradient (positive value = left)');
    $self->{'subgradient_dynamic'}->SetToolTip('Skew direction of gradient (positive value = left)');
    $self->{'subgradient_distro'}->SetToolTip('Relation between parts of subgradient size wise');
    $self->{'color_rainbow'}      = App::GUI::Juliagraph::Widget::ProgressBar->new( $self, 450, 30, [20, 20, 110]);
    $self->{'background_rainbow'} = App::GUI::Juliagraph::Widget::ProgressBar->new( $self, 450, 10, [20, 20, 110]);
    $self->{'color_rainbow'}->SetToolTip('Color gradient display.');
    $self->{'background_rainbow'}->SetToolTip('Background color display.');

    Wx::Event::EVT_CHECKBOX( $self, $self->{'custom_partition'},sub { $self->enable_partition($self->{'custom_partition'}->GetValue); $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'user_colors'},     sub { $self->enable_user_colors($self->{'user_colors'}->GetValue);    $self->{'callback'}->() });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'use_subgradient'}, sub { $self->enable_subgradient($self->{'use_subgradient'}->GetValue);$self->{'callback'}->() });
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_},                sub { $self->update_max_color; $self->{'callback'}->() })
        for qw/begin_color end_color/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_},                sub { $self->{'callback'}->() })
        for qw/scale_distro gradient_dynamic gradient_space background_color
               subgradient_distro subgradient_dynamic subgradient_space/;
    $self->{$_}->SetCallBack( sub { $self->{'callback'}->(); }) for qw/scale_steps subgradient_size subgradient_steps/;

    my $std_margin = 20;
    my $std  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box  = $std | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $item = $std | &Wx::wxLEFT;
    my $row  = $std | &Wx::wxTOP;

    my $div_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $div_sizer->AddSpacer( $std_margin );
    $div_sizer->AddSpacer( 10 );
    $div_sizer->Add( $custom_lbl,                 0, $box, 12);
    $div_sizer->AddSpacer( 10 );
    $div_sizer->Add( $self->{'custom_partition'}, 0, $box,  5);
    $div_sizer->AddSpacer( 20 );
    $div_sizer->Add( $self->{'scale_steps'},      0, $box,  5);
    $div_sizer->AddStretchSpacer();
    $div_sizer->AddSpacer( $std_margin );

    my $div2_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $div2_sizer->AddSpacer( $std_margin );
    $div2_sizer->AddSpacer( 75 );
    $div2_sizer->Add( $self->{'lbl_max'},         0, $box, 12);
    $div2_sizer->AddSpacer( 10 );
    $div2_sizer->Add( $self->{'scale_max'},       0, $box,  5);
    $div2_sizer->AddSpacer( 97 );
    $div2_sizer->Add(  $self->{'lbl_distro'},     0, $box, 12);
    $div2_sizer->AddSpacer( 10 );
    $div2_sizer->Add( $self->{'scale_distro'},    0, $box,  5);
    $div2_sizer->AddStretchSpacer();
    $div2_sizer->AddSpacer( $std_margin );

    my $color_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $color_sizer->AddSpacer( $std_margin );
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $color_lbl,                0, $box, 12);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'user_colors'},    0, $box,  0);
    $color_sizer->AddSpacer( 80 );
    $color_sizer->Add( $self->{'lbl_begin'},      0, $box, 12);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'begin_color'},    0, $box,  5);
    $color_sizer->AddSpacer( 28 );
    $color_sizer->Add( $self->{'lbl_end'},        0, $box, 12);
    $color_sizer->AddSpacer( 10 );
    $color_sizer->Add( $self->{'end_color'},      0, $box,  5);
    $color_sizer->AddStretchSpacer();
    $color_sizer->AddSpacer( $std_margin );

    my $map_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $map_sizer->AddSpacer( $std_margin );
    $map_sizer->AddSpacer( 10 );
    $map_sizer->Add( $self->{'lbl_backg'},        0, $box, 12);
    $map_sizer->AddSpacer( 10 );
    $map_sizer->Add( $self->{'background_color'}, 0, $box,  5);
    $map_sizer->AddSpacer( 23 );
    $map_sizer->Add( $map_dyn_lbl,                0, $box, 12);
    $map_sizer->AddSpacer( 10 );
    $map_sizer->Add( $self->{'gradient_dynamic'}, 0, $box,  5);
    $map_sizer->AddSpacer( 22 );
    $map_sizer->Add( $map_space_lbl,              0, $box, 12);
    $map_sizer->AddSpacer( 10 );
    $map_sizer->Add( $self->{'gradient_space'},   0, $box,  5);
    $map_sizer->AddStretchSpacer();
    $map_sizer->AddSpacer( $std_margin );

    my $sub_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sub_sizer->AddSpacer( $std_margin );
    $sub_sizer->AddSpacer( 10 );
    $sub_sizer->Add( $self->{'lbl_sub_use'},        0, $box, 12);
    $sub_sizer->AddSpacer( 10 );
    $sub_sizer->Add( $self->{'use_subgradient'},    0, $box,  5);
    $sub_sizer->AddSpacer( 20 );
    $sub_sizer->Add( $self->{'subgradient_steps'},  1, $box,  5);
    $sub_sizer->AddSpacer( $std_margin );

    my $sub2_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sub2_sizer->AddSpacer( $std_margin );
    $sub2_sizer->AddSpacer( 140 );
    $sub2_sizer->Add( $self->{'subgradient_size'},  1, $box,  4);
    $sub2_sizer->AddSpacer( $std_margin );

    my $sub3_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $sub3_sizer->AddSpacer( $std_margin );
    $sub3_sizer->AddSpacer( 10 );
    $sub3_sizer->Add( $self->{'lbl_sub_distro'},     0, $box, 12);
    $sub3_sizer->AddSpacer( 10 );
    $sub3_sizer->Add( $self->{'subgradient_distro'}, 0, $box,  4);
    $sub3_sizer->AddSpacer( 25 );
    $sub3_sizer->Add( $self->{'lbl_sub_dyn'},        0, $box, 12);
    $sub3_sizer->AddSpacer( 10 );
    $sub3_sizer->Add( $self->{'subgradient_dynamic'},0, $box,  4);
    $sub3_sizer->AddSpacer( 25 );
    $sub3_sizer->Add( $self->{'lbl_sub_space'},      0, $box, 12);
    $sub3_sizer->AddSpacer( 10 );
    $sub3_sizer->Add( $self->{'subgradient_space'},  0, $box,  4);
    $sub3_sizer->AddStretchSpacer();
    $sub3_sizer->AddSpacer( $std_margin );

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->AddSpacer( 10 );
    $sizer->Add( $map_lbl,      0, $item,  $std_margin);
    $sizer->Add( $color_sizer,  0, $row,   8);
    $sizer->Add( $map_sizer,    0, $row,  10);
    $sizer->AddSpacer( 2 );
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10 );
    $sizer->AddSpacer( 5 );
    $sizer->Add( $self->{'color_rainbow'},        0, $item | &Wx::wxRIGHT, 20 );
    $sizer->AddSpacer( 10 );
    $sizer->Add( $self->{'background_rainbow'},   0, $item | &Wx::wxRIGHT, 20 );
    $sizer->AddSpacer( 5 );
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10 );
    $sizer->Add( $scale_lbl,    0, $item,  $std_margin);
    $sizer->Add( $div_sizer,    0, $row,   8);
    $sizer->Add( $div2_sizer,   0, $row,  10);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10 );
    $sizer->Add( $submap_lbl,   0, $item, $std_margin);
    $sizer->Add( $sub_sizer,    0, $row,   8);
    $sizer->Add( $sub2_sizer,   0, $row,  10);
    $sizer->Add( $sub3_sizer,   0, $row,  10);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box,  10 );
    $sizer->AddStretchSpacer();
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init         { $_[0]->set_settings ( $default_settings ) }
sub set_settings {
    my ( $self, $settings ) = @_;
    return 0 unless ref $settings eq 'HASH' and exists $settings->{'user_colors'};
    $self->PauseCallBack();
    for my $key (qw/custom_partition scale_steps user_colors use_subgradient subgradient_size subgradient_steps/){
        next unless exists $settings->{$key} and exists $settings->{$key};
        $self->{$key}->SetValue( $settings->{$key} );
    }
    for my $key (qw/scale_distro background_color begin_color end_color gradient_dynamic
                gradient_space subgradient_dynamic subgradient_space subgradient_distro/){
        next unless exists $settings->{$key} and exists $self->{$key};
        $self->{$key}->SetSelection( $self->{$key}->FindString($settings->{$key}) );
    }
    $self->enable_partition( $settings->{'custom_partition'} );
    $self->enable_user_colors( $settings->{'user_colors'} );
    $self->enable_subgradient( $settings->{'use_subgradient'} );
    $self->update_max_color( );
    $self->RestoreCallBack();
    1;
}

sub get_settings {
    my ( $self ) = @_;
    return {
        custom_partition  => int $self->{'custom_partition'}->GetValue,
        user_colors       => int $self->{'user_colors'}->GetValue,
        use_subgradient   => int $self->{'use_subgradient'}->GetValue,
        scale_steps       => $self->{'scale_steps'}->GetValue,
        scale_distro      => $self->{'scale_distro'}->GetStringSelection,
        background_color  => $self->{'background_color'}->GetStringSelection,
        begin_color       => $self->{'begin_color'}->GetStringSelection,
        end_color         => $self->{'end_color'}->GetStringSelection,
        gradient_dynamic  => $self->{'gradient_dynamic'}->GetStringSelection,
        gradient_space    => $self->{'gradient_space'}->GetStringSelection,
        subgradient_size  => $self->{'subgradient_size'}->GetValue,
        subgradient_steps => $self->{'subgradient_steps'}->GetValue,
        subgradient_dynamic=>$self->{'subgradient_dynamic'}->GetStringSelection,
        subgradient_space => $self->{'subgradient_space'}->GetStringSelection,
        subgradient_distro => $self->{'subgradient_distro'}->GetStringSelection,
    };
}

sub enable_partition {
    my ( $self, $on ) = @_;
    $on //= $self->{'custom_partition'}->GetValue;
    $self->{'custom_partition'}->SetValue( $on ) unless int($on) == int $self->{'custom_partition'}->GetValue;
    $self->{$_}->Enable( $on ) for qw/scale_steps scale_distro scale_max lbl_max lbl_distro/;
    $self->enable_subgradient(0) if $on;
    $self->{'use_subgradient'}->Enable( not $on );
    $self->{'lbl_sub_use'}->Enable( not $on );
}
sub enable_user_colors {
    my ( $self, $on ) = @_;
    $on //= $self->{'user_colors'}->GetValue;
    $self->{'user_colors'}->SetValue( $on ) unless int($on) ==  int $self->{'user_colors'}->GetValue;
    $self->{ $_ }->Enable( $on ) for qw/background_color begin_color end_color lbl_begin lbl_end lbl_backg/;
}
sub enable_subgradient {
    my ( $self, $on ) = @_;
    $on //= $self->{'use_subgradient'}->GetValue;
    $self->{'use_subgradient'}->SetValue($on) unless int($on) == int $self->{'use_subgradient'}->GetValue;
    $self->{$_}->Enable( $on ) for qw/subgradient_steps subgradient_dynamic subgradient_space subgradient_distro
                                    lbl_sub_dyn lbl_sub_space lbl_sub_distro subgradient_size/;
}

sub update_max_color {
    my ( $self ) = @_;
    my $begin_color = substr $self->{'begin_color'}->GetStringSelection, 6;
    my $end_color = substr $self->{'end_color'}->GetStringSelection, 6;
    my $max_color = $begin_color > $end_color ? $begin_color : $end_color;
    $self->{'tab'}{'color'}->set_active_color_count( $max_color ) if ref $self->{'tab'}{'color'};
}

sub connect_color_tab {
    my ($self, $ref) = @_;
    return unless ref $ref eq 'App::GUI::Juliagraph::Frame::Tab::Color';
    $self->{'tab'}{'color'} = $ref;
    $self->update_max_color;
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}
sub PauseCallBack {
    my ($self) = @_;
    $self->{'pause'} = $self->{'callback'};
    $self->{'callback'} = sub {};
}
sub RestoreCallBack {
    my ($self) = @_;
    return unless exists $self->{'pause'};
    $self->{'callback'} = $self->{'pause'};
    delete $self->{'pause'};
}


1;
