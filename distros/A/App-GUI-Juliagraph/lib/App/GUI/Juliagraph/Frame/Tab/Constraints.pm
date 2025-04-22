#

package App::GUI::Juliagraph::Frame::Tab::Constraints;
use v5.12;
use warnings;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Juliagraph::Widget::SliderStep;
use App::GUI::Juliagraph::Widget::SliderCombo;

my $default_settings = {
    type => 'Mandelbrot', coordinates_use => 'constant',
    zoom => 1, center_x => 0, center_y => 0,
    const_a => 0, const_b => 0, start_a => 0, start_b => 0,
    stop_nr => 6, stop_value => 3, stop_metric => '|var|'
};

sub new {
    my ( $class, $parent) = @_;
    my $self = $class->SUPER::new( $parent, -1);
    $self->{'callback'} = sub {};
    $self->{'tab'}{'polynome'} = '';
    $self->{'tab'}{'mapping'} = '';

    my $coor_lbl     = Wx::StaticText->new($self, -1, 'P i x e l   C o o r d i n a t e s : ' );
    my $zoom_lbl     = Wx::StaticText->new($self, -1, 'Z o o m : ' );
    my $pos_lbl      = Wx::StaticText->new($self, -1, 'P o s i t i o n : ' );
    my $x_lbl        = Wx::StaticText->new($self, -1, 'X : ' );
    my $y_lbl        = Wx::StaticText->new($self, -1, 'Y : ' );
    $self->{'lbl_const'} = Wx::StaticText->new($self, -1, 'C o n s t a n t :' );
    $self->{'lbl_consta'} = Wx::StaticText->new($self, -1, 'A : ' );
    $self->{'lbl_constb'} = Wx::StaticText->new($self, -1, 'B : ' );
    $self->{'lbl_starta'} = Wx::StaticText->new($self, -1, 'A : ' );
    $self->{'lbl_startb'} = Wx::StaticText->new($self, -1, 'B : ' );
    $self->{'lbl_start'} = Wx::StaticText->new($self, -1, 'S t a r t    V a l u e : ' );
    my $stop_lbl     = Wx::StaticText->new($self, -1, 'I t e r a t i o n   S t o p : ' );
    my $metric_lbl   = Wx::StaticText->new($self, -1, 'M e t r i c : ' );
    $coor_lbl->SetToolTip("Which role play pixel coordinates in computation:\n - as start value of the iteration (z_0)\n - added as constant at any iteration \n - as factor of one monomial on next page (numbered from top to bottom)");
    $zoom_lbl->SetToolTip('zoom factor: the larger the more you zoom in');
    $pos_lbl->SetToolTip('center coordinates of visible sector');
    $self->{'lbl_const'}->SetToolTip('complex constant that will be used according settings in first paragraph');
    $self->{'lbl_start'}->SetToolTip('value of iteration variable Z before first iteration');
    $stop_lbl->SetToolTip('conditions that stop the iteration (computation of pixel color)');
    $metric_lbl->SetToolTip('metric for computing stop value (|var| = sqrt(z.re**2 + z.i**2), x = z.real, y = z.im');

    $self->{'type'} = Wx::RadioBox->new( $self, -1, ' T y p e ', [-1,-1], [-1, -1], ['Mandelbrot', 'Julia', 'Any'] );
    $self->{'type'}->SetToolTip( "Choose fractal type: \njulia uses position as init value of iterator var and constant as such, mandelbrot is vice versa\nany means no such restrictions." );
    $self->{'coor_as_start'} = Wx::CheckBox->new( $self, -1, ' Start Value', [-1,-1], [-1, -1]);
    $self->{'coor_as_const'} = Wx::CheckBox->new( $self, -1, ' Constant',    [-1,-1], [-1, -1]);
    $self->{'coor_as_monom'} = Wx::CheckBox->new( $self, -1, ' Monomial',    [-1,-1], [-1, -1]);
    $self->{'coor_as_start'}->SetToolTip( "Use current pixel coordinates as iteration start value, or add them to it." );
    $self->{'coor_as_const'}->SetToolTip( "Use current pixel coordinates as constant added at every iteration." );
    $self->{'coor_as_monom'}->SetToolTip( "Use current pixel coordinates as monomial factor in the next tab page." );

    $self->{'zoom'}     = Wx::TextCtrl->new( $self, -1, 1, [-1,-1], [ 80, -1] );
    $self->{'center_x'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'center_y'} = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'const_a'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'const_b'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'start_a'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'start_b'}  = Wx::TextCtrl->new( $self, -1, 0, [-1,-1], [100, -1] );
    $self->{'reset_zoom'}     = Wx::Button->new( $self, -1, 1, [-1,-1], [ 30, -1] );
    $self->{'reset_center_x'} = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'reset_center_y'} = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'reset_const_a'}  = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'reset_const_b'}  = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'reset_start_a'}  = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'reset_start_b'}  = Wx::Button->new( $self, -1, 0, [-1,-1], [ 30, -1] );
    $self->{'button_zoom'} = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 0.3, 2, 2);
    $self->{'button_x'}    = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 1  , 7, 3);
    $self->{'button_y'}    = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 1  , 7, 3);
    $self->{'button_ca'}   = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 0.3, 3, 3);
    $self->{'button_cb'}   = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 0.3, 3, 3);
    $self->{'button_sa'}   = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 0.3, 3, 3);
    $self->{'button_sb'}   = App::GUI::Juliagraph::Widget::SliderStep->new( $self, 150, 3, 0.3, 3, 3);

    $self->{'button_zoom'}->SetToolTip('zoom factor: the larger the more you zoom in');
    $self->{'button_zoom'}->SetCallBack(sub { $self->{'zoom'}->SetValue( $self->{'zoom'}->GetValue + shift ) });
    $self->{'button_x'}->SetCallBack( sub { my $value = shift;$self->{'center_x'}->SetValue( $self->{'center_x'}->GetValue + ($value * $self->zoom_size) ) });
    $self->{'button_y'}->SetCallBack( sub { my $value = shift;$self->{'center_y'}->SetValue( $self->{'center_y'}->GetValue + ($value * $self->zoom_size) ) });
    $self->{'button_ca'}->SetCallBack(sub { $self->{'const_a'}->SetValue( $self->{'const_a'}->GetValue + shift ) });
    $self->{'button_cb'}->SetCallBack(sub { $self->{'const_b'}->SetValue( $self->{'const_b'}->GetValue + shift ) });
    $self->{'button_sa'}->SetCallBack(sub { $self->{'start_a'}->SetValue( $self->{'start_a'}->GetValue + shift ) });
    $self->{'button_sb'}->SetCallBack(sub { $self->{'start_b'}->SetValue( $self->{'start_b'}->GetValue + shift ) });

    $self->{'reset_zoom'}->SetToolTip('Reset zoom level to one !');
    $self->{'stop_nr'}     = App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 365, 'Count:', "Square root of maximal amount of iterations run on one pixel coordinates", 3, 120, 5, 0.25);
    $self->{'stop_nr'}->SetCallBack( sub { $self->{'callback'}->() });
    $self->{'stop_value'}  = App::GUI::Juliagraph::Widget::SliderCombo->new( $self, 200, 'Value:', "Square root of value that triggeres bailout / iteration stop", 1, 120, 5, 0.25);
    $self->{'stop_value'}->SetCallBack( sub { $self->{'callback'}->() });
    $self->{'stop_metric'} = Wx::ComboBox->new( $self, -1, '|var|', [-1,-1],[95, -1], ['|var|', '|x|+|y|', '|x|', '|y|', '|x+y|', 'x+y', 'x-y', 'y-x', 'x*y', '|x*y|']);
    $self->{'stop_metric'}->SetToolTip('metric for computing stop value (|var| = sqrt(z.re**2 + z.i**2), x = z.real, y = z.im');

    $self->{'const_widgets'} = [qw/const_a const_b button_ca button_cb lbl_const lbl_consta lbl_constb reset_const_a reset_const_b /];
    $self->{'start_widgets'} = [qw/start_a start_b button_sa button_sb lbl_start lbl_starta lbl_startb reset_start_a reset_start_b /];

    Wx::Event::EVT_BUTTON( $self, $self->{'reset_zoom'},     sub { $self->{'zoom'}->SetValue(1) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_center_x'}, sub { $self->{'center_x'}->SetValue(0) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_center_y'}, sub { $self->{'center_y'}->SetValue(0) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_const_a'},  sub { $self->{'const_a'}->SetValue(0) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_const_b'},  sub { $self->{'const_b'}->SetValue(0) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_start_a'},  sub { $self->{'start_a'}->SetValue(0) });
    Wx::Event::EVT_BUTTON( $self, $self->{'reset_start_b'},  sub { $self->{'start_b'}->SetValue(0) });
    Wx::Event::EVT_RADIOBOX( $self, $self->{'type'},  sub {
        $self->set_type( $self->{'type'}->GetStringSelection );           $self->{'callback'}->();
    });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'coor_as_monom'}, sub {
        $self->set_coordinates_as_factor( $self->{'coor_as_monom'}->GetValue );
        $self->freeze_last_coor_option(); $self->{'callback'}->();
    });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'coor_as_const'}, sub {
        $self->freeze_last_coor_option(); $self->{'callback'}->();
    });
    Wx::Event::EVT_CHECKBOX( $self, $self->{'coor_as_start'}, sub {
        $self->freeze_last_coor_option(); $self->{'callback'}->();
    });
    $self->{'stop_nr'}->SetCallBack( sub { $self->update_iter_count(); $self->{'callback'}->(); });
    $self->{'stop_value'}->SetCallBack( sub { $self->{'callback'}->(); });

    Wx::Event::EVT_TEXT( $self, $self->{$_},          sub { $self->{'callback'}->() }) for qw/zoom center_x center_y const_a const_b start_a start_b/;
    Wx::Event::EVT_COMBOBOX( $self, $self->{$_},      sub { $self->{'callback'}->() }) for qw/stop_metric/;

    my $std  = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxGROW;
    my $box  = $std | &Wx::wxTOP | &Wx::wxBOTTOM;
    my $item = $std | &Wx::wxLEFT;
    my $row  = $std | &Wx::wxTOP;
    my $all  = $std | &Wx::wxALL;

    my $left_margin = 20;
    my $coor_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $coor_sizer->Add( $self->{'coor_as_start'},   0, $box, 2);
    $coor_sizer->Add( $self->{'coor_as_const'},   0, $box, 2);
    $coor_sizer->Add( $self->{'coor_as_monom'},   0, $box, 2);

    my $type_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $type_sizer->AddSpacer( $left_margin );
    $type_sizer->Add( $self->{'type'},        0, $box,  16);
    $type_sizer->AddSpacer( 40 );
    $type_sizer->Add( $coor_lbl,              0, $row,  32);
    $type_sizer->Add( $coor_sizer,            0, $item, 30);
    $type_sizer->AddStretchSpacer( );

    my $zoom_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $zoom_sizer->AddSpacer( $left_margin );
    $zoom_sizer->Add( $self->{'zoom'},        1, $box,  5);
    $zoom_sizer->Add( $self->{'button_zoom'}, 0, $box,  5);
    $zoom_sizer->Add( $self->{'reset_zoom'},  0, $box,  5);
    $zoom_sizer->AddSpacer( $left_margin );

    my $x_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $x_sizer->AddSpacer( $left_margin );
    $x_sizer->Add( $x_lbl,                    0, $row, 12);
    $x_sizer->AddSpacer( 10 );
    $x_sizer->Add( $self->{'center_x'},       1, $box,  5);
    $x_sizer->Add( $self->{'button_x'},       0, $box,  5);
    $x_sizer->Add( $self->{'reset_center_x'}, 0, $box,  5);
    $x_sizer->AddSpacer( $left_margin );

    my $y_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $y_sizer->AddSpacer( $left_margin );
    $y_sizer->Add( $y_lbl,                    0, $row, 12);
    $y_sizer->AddSpacer( 10 );
    $y_sizer->Add( $self->{'center_y'},       1, $box,  5);
    $y_sizer->Add( $self->{'button_y'},       0, $box,  5);
    $y_sizer->Add( $self->{'reset_center_y'}, 0, $box,  5);
    $y_sizer->AddSpacer( $left_margin );

    my $const_a_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $const_a_sizer->AddSpacer( $left_margin );
    $const_a_sizer->Add( $self->{'lbl_consta'},    0, $row, 12);
    $const_a_sizer->AddSpacer( 10 );
    $const_a_sizer->Add( $self->{'const_a'},       1, $box,  5);
    $const_a_sizer->Add( $self->{'button_ca'},     0, $box,  5);
    $const_a_sizer->Add( $self->{'reset_const_a'}, 0, $box,  5);
    $const_a_sizer->AddSpacer( $left_margin );

    my $const_b_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $const_b_sizer->AddSpacer( $left_margin );
    $const_b_sizer->Add( $self->{'lbl_constb'},   0, $row, 12);
    $const_b_sizer->AddSpacer( 10 );
    $const_b_sizer->Add( $self->{'const_b'},      1, $box,  5);
    $const_b_sizer->Add( $self->{'button_cb'},    0, $box,  5);
    $const_b_sizer->Add( $self->{'reset_const_b'},0, $box,  5);
    $const_b_sizer->AddSpacer( $left_margin );

    my $start_a_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $start_a_sizer->AddSpacer( $left_margin );
    $start_a_sizer->Add( $self->{'lbl_starta'},    0, $row, 12);
    $start_a_sizer->AddSpacer( 10 );
    $start_a_sizer->Add( $self->{'start_a'},       1, $box,  5);
    $start_a_sizer->Add( $self->{'button_sa'},     0, $box,  5);
    $start_a_sizer->Add( $self->{'reset_start_a'}, 0, $box,  5);
    $start_a_sizer->AddSpacer( $left_margin );

    my $start_b_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $start_b_sizer->AddSpacer( $left_margin );
    $start_b_sizer->Add( $self->{'lbl_startb'},    0, $row, 12);
    $start_b_sizer->AddSpacer( 10 );
    $start_b_sizer->Add( $self->{'start_b'},       1, $box,  5);
    $start_b_sizer->Add( $self->{'button_sb'},     0, $box,  5);
    $start_b_sizer->Add( $self->{'reset_start_b'}, 0, $box,  5);
    $start_b_sizer->AddSpacer( $left_margin );

    my $stop_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $stop_sizer->AddSpacer( $left_margin );
    $stop_sizer->Add( $self->{'stop_nr'},     1, $box,  5);
    #$stop_sizer->AddSpacer( $left_margin - 10 );

    my $stop2_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $stop2_sizer->AddSpacer( $left_margin );
    $stop2_sizer->Add( $self->{'stop_value'},  1, $box,  5);
    $stop2_sizer->AddSpacer( 20 );
    $stop2_sizer->Add( $metric_lbl,            0, $box, 12);
    $stop2_sizer->AddSpacer(  5 );
    $stop2_sizer->Add( $self->{'stop_metric'}, 0, $box,  5);
    $stop2_sizer->AddSpacer( $left_margin );

    my $sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $sizer->Add( $type_sizer,      0, $row, 10);
    $sizer->AddSpacer(  3 );
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box, 10 );
    $sizer->Add( $zoom_lbl,        0, $item, $left_margin);
    $sizer->Add( $zoom_sizer,      0, $row, 2);
    $sizer->AddSpacer(  5 );
    $sizer->Add( $pos_lbl,         0, $item, $left_margin);
    $sizer->Add( $x_sizer,         0, $row, 6);
    $sizer->Add( $y_sizer,         0, $row, 0);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box, 10 );
    $sizer->Add( $self->{'lbl_const'}, 0, $item, $left_margin);
    $sizer->Add( $const_a_sizer,   0, $row, 6);
    $sizer->Add( $const_b_sizer,   0, $row, 0);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box, 10 );
    $sizer->Add( $self->{'lbl_start'}, 0, $item, $left_margin);
    $sizer->Add( $start_a_sizer,   0, $row, 6);
    $sizer->Add( $start_b_sizer,   0, $row, 0);
    $sizer->Add( Wx::StaticLine->new( $self, -1), 0, $box, 10 );
    $sizer->Add( $stop_lbl,        0, $item, $left_margin);
    $sizer->Add( $stop_sizer,      0, $row, 10);
    $sizer->Add( $stop2_sizer,     0, $row,  6);
    $sizer->AddSpacer( $left_margin );
    $self->SetSizer($sizer);

    $self->init();
    $self;
}

sub init         { $_[0]->set_settings ( $default_settings ) }
sub set_settings {
    my ( $self, $settings ) = @_;
    return 0 unless ref $settings eq 'HASH' and exists $settings->{'type'};
    $self->PauseCallBack();
    for my $key (qw/coor_as_start coor_as_const coor_as_monom
                    const_a const_b start_a start_b center_x center_y zoom stop_nr stop_value/){
        next unless exists $settings->{$key} and exists $self->{$key};
        $self->{$key}->SetValue( $settings->{$key} );
    }
    for my $key (qw/stop_metric/){
        next unless exists $settings->{$key} and exists $self->{$key};
        $self->{$key}->SetSelection( $self->{$key}->FindString($settings->{$key}) );
    }
    $self->set_coordinates_as_factor( $settings->{'coor_as_monom'} );
    $self->set_type( $settings->{'type'} );
    $self->update_iter_count();
    $self->RestoreCallBack();
    1;
}
sub get_settings {
    my ( $self ) = @_;
    return {
        coor_as_start => int $self->{'coor_as_start'}->GetValue,
        coor_as_const => int $self->{'coor_as_const'}->GetValue,
        coor_as_monom => int $self->{'coor_as_monom'}->GetValue,
        zoom     => $self->{'zoom'}->GetValue  + 0,
        center_x => $self->{'center_x'}->GetValue + 0,
        center_y => $self->{'center_y'}->GetValue + 0,
        const_a  => $self->{'const_a'}->GetValue + 0,
        const_b  => $self->{'const_b'}->GetValue + 0,
        start_a  => $self->{'start_a'}->GetValue + 0,
        start_b  => $self->{'start_b'}->GetValue + 0,
        type     => $self->{'type'}->GetStringSelection,
        stop_nr  => $self->{'stop_nr'}->GetValue,
        stop_value => $self->{'stop_value'}->GetValue,
        stop_metric => $self->{'stop_metric'}->GetStringSelection,
    }
}

sub set_type {
    my ( $self, $type ) = @_;
    return unless defined $type;
    $type = ucfirst lc $type;
    my $selection_nr = $self->{'type'}->FindString( $type );
    return if $selection_nr == -1;
    my $paused = $self->CallBackiIsPaused;
    $self->PauseCallBack();
    $self->{'type'}->SetSelection( $selection_nr );
    if ($type eq 'Mandelbrot'){
        $self->{$_}->SetValue( 0 ) for qw/const_a const_b start_a start_b/;
        $self->{$_}->Enable( 0 ) for @{$self->{'const_widgets'}};
        $self->{'coor_as_start'}->SetValue( 0 );
        $self->{'coor_as_const'}->SetValue( 1 );
    } elsif ($type eq 'Julia') {
        $self->{$_}->SetValue( 0 ) for qw/start_a start_b/;
        $self->{$_}->Enable( 1 ) for @{$self->{'const_widgets'}};
        $self->{'coor_as_start'}->SetValue( 1 );
        $self->{'coor_as_const'}->SetValue( 0 );
    }
    if ($type eq 'Any') {
        $self->{$_}->Enable(1) for @{$self->{'const_widgets'}}, @{$self->{'start_widgets'}},
                                   qw/coor_as_start coor_as_const coor_as_monom/;
        $self->freeze_last_coor_option;
    } else {
        $self->{$_}->Enable(0) for @{$self->{'start_widgets'}},
                                   qw/coor_as_start coor_as_const coor_as_monom/;
        $self->{'coor_as_monom'}->SetValue( 0 );
        $self->{'tab'}{'polynome'}->init() if ref $self->{'tab'}{'polynome'};
    }
    $self->RestoreCallBack() unless $paused;
}
sub set_coordinates_as_factor {
    my ( $self, $on ) = @_;
    $on //= $self->{'coor_as_monom'}->GetValue;
    $self->{'coor_as_monom'}->SetValue( $on );
    $self->{'tab'}{'polynome'}->enable_coor( $on ) if ref $self->{'tab'}{'polynome'};
}

sub freeze_last_coor_option { # keep always one option chosen
    my ( $self ) = @_;
    my %val = (s => int($self->{'coor_as_start'}->GetValue),
               c => int($self->{'coor_as_const'}->GetValue),
               m => int($self->{'coor_as_monom'}->GetValue),
    );
    if ($val{'s'} + $val{'c'} + $val{'m'}  == 1){
        $self->{'coor_as_start'}->Enable(0) if $val{'s'};
        $self->{'coor_as_const'}->Enable(0) if $val{'c'};
        $self->{'coor_as_monom'}->Enable(0) if $val{'m'};
    } else {
        $self->{$_}->Enable(1) for qw/coor_as_start coor_as_const coor_as_monom/;
    }
}

sub move_center_position { # after mouse click
    my ( $self, $delta_x_percent, $delta_y_percent, $zoom_dir ) = @_;
    $self->PauseCallBack;
    my $zoom  =  $self->{'zoom'}->GetValue;
    my $cx = $self->{'center_x'}->GetValue;
    my $cy = $self->{'center_y'}->GetValue;
    my $d = sqrt( $delta_x_percent**2 + $delta_y_percent**2 );
    if ($zoom_dir){
        $self->{'zoom'}->SetValue( $zoom + (0.1 * $zoom_dir * $zoom) );
    } else {
        my $new_x = ($delta_x_percent / 2 / $zoom ) + $cx;
        my $new_y = -($delta_y_percent / 2 / $zoom ) + $cy;
        $self->{'center_x'}->SetValue( $new_x );
        $self->{'center_y'}->SetValue( $new_y );
    }
    $self->RestoreCallBack;
    $self->RunCallBack;
}

sub update_iter_count {
    my ( $self ) = @_;
    $self->{'tab'}{'mapping'}{'scale_max'}->SetValue( int $self->{'stop_nr'}->GetValue**2 ) if ref $self->{'tab'}{'mapping'};
}

sub zoom_size { 0.1 / ($_[0]->{'zoom'}->GetValue ** 2) }

sub connect_polynome_tab {
    my ($self, $ref) = @_;
    return unless ref $ref eq 'App::GUI::Juliagraph::Frame::Tab::Polynomial';
    $self->{'tab'}{'polynome'} = $ref;
}

sub connect_mapping_tab {
    my ($self, $ref) = @_;
    return unless ref $ref eq 'App::GUI::Juliagraph::Frame::Tab::Mapping';
    $self->{'tab'}{'mapping'} = $ref;
    $self->{'tab'}{'mapping'}{'scale_max'}->SetValue( $self->{'stop_nr'}->GetValue );
    $self->update_iter_count();
}

sub SetCallBack {
    my ($self, $code) = @_;
    return unless ref $code eq 'CODE';
    $self->{'callback'} = $code;
}
sub PauseCallBack {
    my ($self) = @_;
    return if $self->CallBackiIsPaused;
    $self->{'paused_call'} = $self->{'callback'};
    $self->{'callback'} = sub {};
}
sub CallBackiIsPaused { exists $_[0]->{'paused_call'} }
sub RunCallBack      { $_[0]->{'callback'}->() }
sub RestoreCallBack {
    my ($self) = @_;
    return unless $self->CallBackiIsPaused;
    $self->{'callback'} = $self->{'paused_call'};
    delete $self->{'paused_call'};
}

1;
