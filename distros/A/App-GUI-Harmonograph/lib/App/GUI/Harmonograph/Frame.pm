use v5.12;
use warnings;
use utf8;
use Wx::AUI;

package App::GUI::Harmonograph::Frame;
use base qw/Wx::Frame/;
use App::GUI::Harmonograph::Dialog::About;
use App::GUI::Harmonograph::Frame::Part::Board;
use App::GUI::Harmonograph::Frame::Part::ColorBrowser;
use App::GUI::Harmonograph::Frame::Part::ColorFlow;
use App::GUI::Harmonograph::Frame::Part::ColorPicker;
use App::GUI::Harmonograph::Frame::Part::Pendulum;
use App::GUI::Harmonograph::Frame::Part::PenLine;
use App::GUI::Harmonograph::Frame::Part::ModMatrix;
use App::GUI::Harmonograph::Widget::ProgressBar;
use App::GUI::Harmonograph::Settings; # file IO for parameters of image
use App::GUI::Harmonograph::Config;   # file IO for program config: dirs, color set store

sub new {
    my ( $class, $parent, $title ) = @_;
    my $self = $class->SUPER::new( $parent, -1, $title );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->CreateStatusBar( 2 );
    $self->SetStatusWidths(2, 800, 100);
    $self->SetStatusText( "no file loaded", 1 );
    $self->{'config'} = App::GUI::Harmonograph::Config->new();
    Wx::ToolTip::Enable( $self->{'config'}->get_value('tips') );
    Wx::InitAllImageHandlers();
    $self->{'title'} = $title;

    # create GUI parts
    $self->{'tabs'}             = Wx::AuiNotebook->new($self, -1, [-1,-1], [-1,-1], &Wx::wxAUI_NB_TOP );
    $self->{'tab'}{'linear'}    = Wx::Panel->new($self->{'tabs'});
    $self->{'tab'}{'circular'}  = Wx::Panel->new($self->{'tabs'});
    $self->{'tab'}{'mod'}       = App::GUI::Harmonograph::Frame::Part::ModMatrix->new( $self->{'tabs'} );
    $self->{'tab'}{'pen'}       = Wx::Panel->new($self->{'tabs'});
    $self->{'tabs'}->AddPage( $self->{'tab'}{'linear'},   'Lateral Pendulum');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'circular'}, 'Rotary Pendulum');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'mod'},      'Modulation Matrix');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'pen'},      'Pen Settings');

    $self->{'pendulum'}{'x'}    = App::GUI::Harmonograph::Frame::Part::Pendulum->new( $self->{'tab'}{'linear'}, 'x','pendulum in x direction (left to right)', 1, 100);
    $self->{'pendulum'}{'y'}    = App::GUI::Harmonograph::Frame::Part::Pendulum->new( $self->{'tab'}{'linear'}, 'y','pendulum in y direction (left to right)', 1, 100);
    $self->{'pendulum'}{'z'}    = App::GUI::Harmonograph::Frame::Part::Pendulum->new( $self->{'tab'}{'circular'}, 'z','circular pendulum',        0, 100);
    $self->{'pendulum'}{'r'}    = App::GUI::Harmonograph::Frame::Part::Pendulum->new( $self->{'tab'}{'circular'}, 'R','rotating pendulum',        0, 100);

    $self->{'color'}{'start'}   = App::GUI::Harmonograph::Frame::Part::ColorBrowser->new( $self->{'tab'}{'pen'}, 'start', { red => 20, green => 20, blue => 110 } );
    $self->{'color'}{'end'}     = App::GUI::Harmonograph::Frame::Part::ColorBrowser->new( $self->{'tab'}{'pen'}, 'end',  { red => 110, green => 20, blue => 20 } );

    $self->{'color'}{'startio'} = App::GUI::Harmonograph::Frame::Part::ColorPicker->new( $self->{'tab'}{'pen'}, $self, 'Start Color IO', $self->{'config'}->get_value('color') , 162, 1);
    $self->{'color'}{'endio'}   = App::GUI::Harmonograph::Frame::Part::ColorPicker->new( $self->{'tab'}{'pen'}, $self, 'End Color IO', $self->{'config'}->get_value('color') , 162, 7);

    $self->{'color_flow'}       = App::GUI::Harmonograph::Frame::Part::ColorFlow->new( $self->{'tab'}{'pen'}, $self );
    $self->{'line'}             = App::GUI::Harmonograph::Frame::Part::PenLine->new( $self->{'tab'}{'pen'} );

    $self->{'pendulum'}{$_}->SetCallBack( sub { $self->sketch( ) } ) for qw/x y z r/;
    $self->{'line'}->SetCallBack( sub { $self->sketch( ) } );
    $self->{'color_flow'}->SetCallBack( sub { $self->sketch( ) } );
    $self->{'tab'}{'mod'}->SetCallBack( sub { $self->sketch( ) } );

    $self->{'progress'}            = App::GUI::Harmonograph::Widget::ProgressBar->new( $self, 450,  10, { red => 20, green => 20, blue => 110 });
    $self->{'board'}               = App::GUI::Harmonograph::Frame::Part::Board->new( $self , 600, 600 );
    $self->{'dialog'}{'about'}     = App::GUI::Harmonograph::Dialog::About->new();

    my $btnw = 50; my $btnh     = 40;# button width and height
    $self->{'btn'}{'dir'}       = Wx::Button->new( $self, -1, 'Di&r',   [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'write_next'}= Wx::Button->new( $self, -1, '&INI',   [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'draw'}      = Wx::Button->new( $self, -1, '&Draw', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'save_next'} = Wx::Button->new( $self, -1, '&Save', [-1,-1],[$btnw, $btnh] );
    $self->{'txt'}{'file_bdir'} = Wx::TextCtrl->new( $self,-1, $self->{'config'}->get_value('file_base_dir'), [-1,-1],  [170, -1] );
    $self->{'txt'}{'file_bname'}= Wx::TextCtrl->new( $self,-1, $self->{'config'}->get_value('file_base_name'), [-1,-1],   [100, -1] );
    $self->{'txt'}{'file_bnr'}  = Wx::TextCtrl->new( $self,-1, $self->{'config'}->get_value('file_base_counter'), [-1,-1], [ 36, -1], &Wx::wxTE_READONLY );

    $self->{'btn'}{'dir'}->SetToolTip('select directory to save file series in');
    $self->{'btn'}{'write_next'}->SetToolTip('save current image settings into text file with name seen in text field with added number and file ending .ini');
    $self->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $self->{'btn'}{'save_next'}->SetToolTip('save current image into SVG file with name seen in text field with added number and file ending .svg');
    $self->{'txt'}{'file_bname'}->SetToolTip("file base name (without ending) for a series of files you save (settings and images)");
    $self->{'txt'}{'file_bnr'}->SetToolTip("index of file base name,\nwhen pushing Next button, image or settings are saved under Dir + File + Index + Ending");

    # Events
    Wx::Event::EVT_TEXT_ENTER( $self, $self->{'txt'}{'file_bname'}, sub { $self->update_base_name });
    Wx::Event::EVT_KILL_FOCUS(        $self->{'txt'}{'file_bname'}, sub { $self->update_base_name });

    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'dir'},  sub { $self->change_base_dir }) ;
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'write_next'},  sub {
        my $data = get_data( $self );
        my $path = $self->base_path . '.ini';
        $self->write_settings_file( $path);
        $self->{'config'}->add_setting_file( $path );
        $self->{'last_file_settings'} = $data;
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'save_next'},  sub {
        my $data = get_data( $self );
        my $path = $self->base_path . '.' . $self->{'config'}->get_value('file_base_ending');
        $self->write_image( $path );
        $self->{'last_file_settings'} = $data;
    });
    Wx::Event::EVT_BUTTON( $self, $self->{'btn'}{'draw'},  sub { draw( $self ) });
    Wx::Event::EVT_CLOSE( $self, sub {
        my $all_color = $self->{'config'}->get_value('color');
        my $startc = $self->{'color'}{'startio'}->get_data;
        my $endc = $self->{'color'}{'endio'}->get_data;
        for my $name (keys %$endc){
            $all_color->{$name} = $endc->{$name} unless exists $all_color->{$name};
        }
        for my $name (keys %$startc){
            $all_color->{$name} = $startc->{$name} unless exists $all_color->{$name};
        }
        for my $name (keys %$all_color){
            if (exists $startc->{$name} and exists $endc->{$name}){
                $endc->{$name} = $startc->{$name} if $startc->{$name}[0] != $all_color->{$name}[0]
                                                  or $startc->{$name}[1] != $all_color->{$name}[1]
                                                  or $startc->{$name}[2] != $all_color->{$name}[2];
                $all_color->{$name} = $endc->{$name};
            } else { delete $all_color->{$name} }
        }
        $self->{'config'}->save();
        $self->{'dialog'}{'about'}->Destroy();
        $_[1]->Skip(1)
    });

    # Menu
    my $settings_menu = $self->{'setting_menu'} = Wx::Menu->new();
    $settings_menu->Append( 11100, "&Init\tCtrl+I", "put all settings to default" );
    $settings_menu->Append( 11200, "&Open\tCtrl+O", "load settings from an INI file" );
    $settings_menu->Append( 11400, "&Write\tCtrl+W", "store curent settings into an INI file" );
    $settings_menu->AppendSeparator();
    $settings_menu->Append( 11500, "&Quit\tAlt+Q", "save configs and close program" );

    my $image_size_menu = Wx::Menu->new();
    for (1 .. 20) {
        my $size = $_ * 100;
        $image_size_menu->AppendRadioItem(12100 + $_, $size, "set image size to $size x $size");
        Wx::Event::EVT_MENU( $self, 12100 + $_, sub {
            my $size = 100 * ($_[1]->GetId - 12100);
            $self->{'config'}->set_value('image_size', $size);
        });

    }
    $image_size_menu->Check( 12100 +($self->{'config'}->get_value('image_size') / 100), 1);

    my $image_format_menu = Wx::Menu->new();
    $image_format_menu->AppendRadioItem(12201, 'PNG', "set default image format to PNG");
    $image_format_menu->AppendRadioItem(12202, 'JPEG', "set default image format to JPEG");
    $image_format_menu->AppendRadioItem(12203, 'SVG', "set default image format to SVG");

    Wx::Event::EVT_MENU( $self, 12201, sub { $self->{'config'}->set_value('file_base_ending', 'png') });
    Wx::Event::EVT_MENU( $self, 12202, sub { $self->{'config'}->set_value('file_base_ending', 'jpg') });
    Wx::Event::EVT_MENU( $self, 12203, sub { $self->{'config'}->set_value('file_base_ending', 'svg') });

    $image_format_menu->Check( 12201, 1 ) if $self->{'config'}->get_value('file_base_ending') eq 'png';
    $image_format_menu->Check( 12202, 1 ) if $self->{'config'}->get_value('file_base_ending') eq 'jpg';
    $image_format_menu->Check( 12203, 1 ) if $self->{'config'}->get_value('file_base_ending') eq 'svg';

    my $image_menu = Wx::Menu->new();
    $image_menu->Append( 12300, "&Draw\tCtrl+D", "complete a sketch drawing" );
    $image_menu->Append( 12100, "S&ize",  $image_size_menu,   "set image size" );
    $image_menu->Append( 12200, "&Format",  $image_format_menu, "set default image formate" );
    $image_menu->Append( 12400, "&Save\tCtrl+S", "save currently displayed image" );

    my $help_menu = Wx::Menu->new();
    $help_menu->Append( 13300, "&About\tAlt+A", "Dialog with general information about the program" );

    my $menu_bar = Wx::MenuBar->new();
    $menu_bar->Append( $settings_menu, '&Settings' );
    $menu_bar->Append( $image_menu,    '&Image' );
    $menu_bar->Append( $help_menu,     '&Help' );
    $self->SetMenuBar($menu_bar);

    Wx::Event::EVT_MENU( $self, 11100, sub { $self->init });
    Wx::Event::EVT_MENU( $self, 11200, sub { $self->open_settings_dialog });
    Wx::Event::EVT_MENU( $self, 11400, sub { $self->write_settings_dialog });
    Wx::Event::EVT_MENU( $self, 11500, sub { $self->Close });
    Wx::Event::EVT_MENU( $self, 12300, sub { $self->draw });
    Wx::Event::EVT_MENU( $self, 12400, sub { $self->save_image_dialog });
    Wx::Event::EVT_MENU( $self, 13300, sub { $self->{'dialog'}{'about'}->ShowModal });

    # GUI layout assembly
    my $std_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALIGN_CENTER_HORIZONTAL;
    my $vert_attr = $std_attr | &Wx::wxTOP;
    my $vset_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $horiz_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr    = &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL |&Wx::wxGROW| &Wx::wxALL;
    my $line_attr    = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT ;

    my $linear_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $linear_sizer->AddSpacer(5);
    $linear_sizer->Add( $self->{'pendulum'}{'x'},   0, $vert_attr| &Wx::wxLEFT, 15);
    $linear_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'linear'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $linear_sizer->AddSpacer(5);
    $linear_sizer->Add( $self->{'pendulum'}{'y'},   0, $vert_attr| &Wx::wxLEFT, 15);
    $linear_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->{'tab'}{'linear'}->SetSizer( $linear_sizer );

    my $circular_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $circular_sizer->AddSpacer(5);
    $circular_sizer->Add( $self->{'pendulum'}{'z'},   0, $vert_attr| &Wx::wxLEFT, 15);
    $circular_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'circular'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $circular_sizer->AddSpacer(5);
    $circular_sizer->Add( $self->{'pendulum'}{'r'},   0, $vert_attr| &Wx::wxLEFT, 15);
    $circular_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->{'tab'}{'circular'}->SetSizer( $circular_sizer );

    my $pen_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $pen_sizer->AddSpacer( 5);
    $pen_sizer->Add( $self->{'line'},             0, $vert_attr, 10);
    $pen_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'pen'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $pen_sizer->Add( $self->{'color_flow'},       0, $vert_attr, 15);
    $pen_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'pen'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $pen_sizer->AddSpacer(10);
    $pen_sizer->Add( Wx::StaticText->new( $self->{'tab'}{'pen'}, -1, 'Start Color', [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL), 0, &Wx::wxALIGN_CENTER_HORIZONTAL|&Wx::wxGROW|&Wx::wxALL, 5);
    $pen_sizer->Add( $self->{'color'}{'start'},   0, $vert_attr, 0);
    $pen_sizer->AddSpacer( 5);
    $pen_sizer->Add( Wx::StaticText->new( $self->{'tab'}{'pen'}, -1, 'End Color', [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL), 0, &Wx::wxALIGN_CENTER_HORIZONTAL|&Wx::wxGROW|&Wx::wxALL, 5);
    $pen_sizer->Add( $self->{'color'}{'end'},     0, $vert_attr, 0);
    $pen_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'pen'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    $pen_sizer->AddSpacer( 3);
    $pen_sizer->Add( $self->{'color'}{'startio'}, 0, $vert_attr,  5);
    $pen_sizer->Add( $self->{'color'}{'endio'},   0, $vert_attr,  5);

    $pen_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    $self->{'tab'}{'pen'}->SetSizer( $pen_sizer );

    my $cmdi_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $image_lbl = Wx::StaticText->new( $self, -1, 'Image:' );
    $cmdi_sizer->Add( $image_lbl,     0, $all_attr, 15 );
    $cmdi_sizer->Add( $self->{'progress'},         0, $vset_attr, 20 );
    $cmdi_sizer->AddSpacer(5);
    $cmdi_sizer->Add( $self->{'btn'}{'draw'},      0, $all_attr, 5 );

    my $cmds_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $series_lbl = Wx::StaticText->new( $self, -1, 'Series:' );
    $cmds_sizer->Add( $series_lbl,     0, $all_attr, 15 );
    $cmds_sizer->AddSpacer( 5 );
    $cmds_sizer->Add( $self->{'btn'}{'dir'},         0, $all_attr, 5 );
    $cmds_sizer->Add( $self->{'txt'}{'file_bdir'},   0, $all_attr, 5 );
    $cmds_sizer->Add( $self->{'txt'}{'file_bname'},  0, $all_attr, 5 );
    $cmds_sizer->Add( $self->{'txt'}{'file_bnr'},    0, $all_attr, 5 );
    $cmds_sizer->AddSpacer( 10 );
    $cmds_sizer->Add( $self->{'btn'}{'write_next'},  0, $all_attr, 5 );
    $cmds_sizer->AddSpacer( 10 );
    $cmds_sizer->Add( $self->{'btn'}{'save_next'},   0, $all_attr, 5 );
    $cmds_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $self->{'board'}, 1, $all_attr,  5);
    $board_sizer->Add( $cmdi_sizer,      0, $vert_attr, 5);
    $board_sizer->Add( 0, 5);
    $board_sizer->Add( Wx::StaticLine->new( $self, -1, [-1,-1], [ 125, 2] ),  0, $line_attr, 20);
    $board_sizer->Add( 0, 5);
    $board_sizer->Add( $cmds_sizer,      0, $vert_attr, 5);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $self->{'tabs'}, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    #$setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 1, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 1, &Wx::wxEXPAND|&Wx::wxLEFT, 10);

    $self->SetSizer($main_sizer);
    $self->SetAutoLayout( 1 );
    my $size = [1230, 823];
    $self->SetSize($size);
    $self->SetMinSize($size);
    $self->SetMaxSize($size);

    $self->update_recent_settings_menu();
    $self->init();
    $self->{'btn'}{'draw'}->SetFocus;
    $self->{'last_file_settings'} = get_data( $self );

    $self;
}

sub update_recent_settings_menu {
    my ($self) = @_;
    my $recent = $self->{'config'}->get_value('last_settings');
    return unless ref $recent eq 'ARRAY';
    my $set_menu_ID = 11300;
    $self->{'setting_menu'}->Destroy( $set_menu_ID );
    my $Recent_ID = $set_menu_ID + 1;
    $self->{'recent_menu'} = Wx::Menu->new();
    for (reverse @$recent){
        my $path = $_;
        $self->{'recent_menu'}->Append($Recent_ID, $path);
        Wx::Event::EVT_MENU( $self, $Recent_ID++, sub { $self->open_setting_file( $path ) });
    }
    $self->{'setting_menu'}->Insert( 2, $set_menu_ID, '&Recent', $self->{'recent_menu'}, 'recently saved settings' );

}

sub init {
    my ($self) = @_;
    $self->{'pendulum'}{$_}->init() for qw/x y z r/;
    $self->{'tab'}{'mod'}->init();
    $self->{'color'}{$_}->init() for qw/start end/;
    $self->{ $_ }->init() for qw/color_flow line/;
    $self->{'progress'}->set_color( { red => 20, green => 20, blue => 110 } );
    $self->sketch( );
    $self->SetStatusText( "all settings are set to default", 1);
    $self->set_settings_save(1);
}

sub get_data {
    my $self = shift;
    {
        x => $self->{'pendulum'}{'x'}->get_data,
        y => $self->{'pendulum'}{'y'}->get_data,
        z => $self->{'pendulum'}{'z'}->get_data,
        r => $self->{'pendulum'}{'r'}->get_data,
        mod => $self->{'tab'}{'mod'}->get_data,
        start_color => $self->{'color'}{'start'}->get_data,
        end_color => $self->{'color'}{'end'}->get_data,
        color_flow => $self->{'color_flow'}->get_data,
        line => $self->{'line'}->get_data,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{'pendulum'}{$_}->set_data( $data->{$_} ) for qw/x y z r/;
    $self->{'tab'}{'mod'}->set_data( $data->{'mod'} );
    $self->{'color'}{$_}->set_data( $data->{ $_.'_color' } ) for qw/start end/;
    $self->{ $_ }->set_data( $data->{ $_ } ) for qw/color_flow line/;
}

sub draw {
    my ($self) = @_;
    $self->SetStatusText( "drawing .....", 0 );
    $self->{'progress'}->set_color( $self->{'color'}{'start'}->get_data );
    $self->{'board'}->draw( $self->get_data );
    $self->SetStatusText( "done complete drawing", 0 );
}

sub sketch {
    my ($self) = @_;
    $self->SetStatusText( "sketching a preview .....", 0 );
    $self->{'board'}->sketch( $self->get_data );
    $self->SetStatusText( "done sketching a preview", 0 );
    if ($self->{'saved'}){
        $self->inc_base_counter();
        $self->set_settings_save(0);
    }
}

sub write_image {
    my ($self, $file)  = @_;
    $self->{'board'}->save_file( $file );
    $file = App::GUI::Harmonograph::Settings::shrink_path( $file );
    $self->SetStatusText( "saved image under: $file", 0 );
    $self->set_settings_save(1);
}

sub set_settings_save {
    my ($self, $status)  = @_;
    $self->{'saved'} = $status;
    $self->SetTitle( $self->{'title'} .($self->{'saved'} ? '': ' *'));
}

sub update_base_name {
    my ($self) = @_;
    my $file = $self->{'txt'}{'file_bname'}->GetValue;
    $self->{'config'}->set_value('file_base_name', $file);
    $self->{'config'}->set_value('file_base_counter', 1);
    $self->inc_base_counter();
}

sub inc_base_counter {
    my ($self, $type) = @_;
    my $dir = $self->{'config'}->get_value('file_base_dir');
    $dir = App::GUI::Harmonograph::Settings::expand_path( $dir );
    my $base = File::Spec->catfile( $dir, $self->{'config'}->get_value('file_base_name') );
    my $cc = $self->{'config'}->get_value('file_base_counter');
    while (1){
        last unless -e $base.'_'.$cc.'.svg'
                 or -e $base.'_'.$cc.'.png'
                 or -e $base.'_'.$cc.'.jpg'
                 or -e $base.'_'.$cc.'.gif'
                 or -e $base.'_'.$cc.'.ini';
        $cc++;
    }
    $self->{'txt'}{'file_bnr'}->SetValue( $cc );
    $self->{'config'}->set_value('file_base_counter', $cc);
    $self->{'last_file_settings'} = get_data( $self );
}


sub change_base_dir {
    my $self = shift;
    my $dialog = Wx::DirDialog->new ( $self, "Select a directory to store a series of files", $self->{'config'}->get_value('file_base_dir'));
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $new_dir = $dialog->GetPath;
    $new_dir = App::GUI::Harmonograph::Settings::shrink_path( $new_dir ) . '/';
    $self->{'txt'}{'file_bdir'}->SetValue( $new_dir );
    $self->{'config'}->set_value('file_base_dir', $new_dir);
    $self->update_base_name();
}

sub base_path {
    my ($self) = @_;
    my $dir = $self->{'config'}->get_value('file_base_dir');
    $dir = App::GUI::Harmonograph::Settings::expand_path( $dir );
    File::Spec->catfile( $dir, $self->{'config'}->get_value('file_base_name') )
        .'_'.$self->{'config'}->get_value('file_base_counter');

}

sub open_settings_dialog {
    my ($self) = @_;
    my $dialog = Wx::FileDialog->new ( $self, "Select a settings file to load", $self->{'config'}->get_value('open_dir'), '',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    my $ret = $self->open_setting_file ( $path );
    if (not ref $ret) { $self->SetStatusText( $ret, 0) }
    else {
        my $dir = App::GUI::Harmonograph::Settings::extract_dir( $path );
        $self->{'config'}->set_value('open_dir', $dir);
        $self->SetStatusText( "loaded settings from ".$dialog->GetPath, 1);
    }
}

sub write_settings_dialog {
    my ($self) = @_;
    my $dialog = Wx::FileDialog->new ( $self, "Select a file name to store data",$self->{'config'}->get_value('write_dir'), '',
               ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    $path .= '.ini' unless lc substr ($path, -4) eq '.ini';
    return if -e $path and
              Wx::MessageDialog->new( $self, "\n\nReally overwrite the settings file?", 'Confirmation Question',
                                      &Wx::wxYES_NO | &Wx::wxICON_QUESTION )->ShowModal() != &Wx::wxID_YES;
    $self->write_settings_file( $path );
    my $dir = App::GUI::Harmonograph::Settings::extract_dir( $path );
    $self->{'config'}->set_value('write_dir', $dir);
}

sub save_image_dialog {
    my ($self) = @_;
    my @wildcard = ( 'SVG files (*.svg)|*.svg', 'PNG files (*.png)|*.png', 'JPEG files (*.jpg)|*.jpg');
    my $wildcard = '|All files (*.*)|*.*';
    my $default_ending = $self->{'config'}->get_value('file_base_ending');
    $wildcard = ($default_ending eq 'jpg') ? ( join '|', @wildcard[2,1,0]) . $wildcard :
                ($default_ending eq 'png') ? ( join '|', @wildcard[1,0,2]) . $wildcard :
                                             ( join '|', @wildcard[0,1,2]) . $wildcard ;
    my @wildcard_ending = ($default_ending eq 'jpg') ? (qw/jpg png svg/) :
                          ($default_ending eq 'png') ? (qw/png svg jpg/) :
                                                       (qw/svg jpg png/) ;

    my $dialog = Wx::FileDialog->new ( $self, "select a file name to save image", $self->{'config'}->get_value('save_dir'), '', $wildcard, &Wx::wxFD_SAVE );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    return if -e $path and
              Wx::MessageDialog->new( $self, "\n\nReally overwrite the image file?", 'Confirmation Question',
                                      &Wx::wxYES_NO | &Wx::wxICON_QUESTION )->ShowModal() != &Wx::wxID_YES;
    my $file_ending = lc substr ($path, -4);
    unless ($dialog->GetFilterIndex == 3 or # filter set to all endings
            ($file_ending eq '.jpg' or $file_ending eq '.png' or $file_ending eq '.svg')){
            $path .= '.' . $wildcard_ending[$dialog->GetFilterIndex];
    }
    my $ret = $self->write_image( $path );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
    else     { $self->{'config'}->set_value('save_dir', App::GUI::Harmonograph::Settings::extract_dir( $path )) }
}

sub open_setting_file {
    my ($self, $file ) = @_;
    my $data = App::GUI::Harmonograph::Settings::load( $file );
    if (ref $data) {
        $self->set_data( $data );
        $self->draw;
        my $dir = App::GUI::Harmonograph::Settings::extract_dir( $file );
        $self->{'config'}->set_value('open_dir', $dir);
        $self->SetStatusText( "loaded settings from ".$file, 1) ;
        $self->{'config'}->add_setting_file( $file );
        $self->update_recent_settings_menu();
        $self->set_settings_save( 1 );
        $data;
    } else {
         $self->SetStatusText( $data, 0);
    }
}

sub write_settings_file {
    my ($self, $file)  = @_;
    my $ret = App::GUI::Harmonograph::Settings::write( $file, $self->get_data );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
    else     {
        $self->{'config'}->add_setting_file( $file );
        $self->update_recent_settings_menu();
        $self->SetStatusText( "saved settings into file $file", 1 );
        $self->set_settings_save( 1 );
    }
}

1;
