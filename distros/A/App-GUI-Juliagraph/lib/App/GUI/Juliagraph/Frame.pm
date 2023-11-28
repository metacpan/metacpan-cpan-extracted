use v5.12;
use warnings;
use utf8;
use Wx::AUI;

package App::GUI::Juliagraph::Frame;
use base qw/Wx::Frame/;
use App::GUI::Juliagraph::Frame::Panel::Constraints;
use App::GUI::Juliagraph::Frame::Panel::Polynomial;
use App::GUI::Juliagraph::Frame::Panel::Mapping;
use App::GUI::Juliagraph::Frame::Panel::Color;
use App::GUI::Juliagraph::Frame::Part::Board;
use App::GUI::Juliagraph::Dialog::About;
use App::GUI::Juliagraph::Widget::ProgressBar;
use App::GUI::Juliagraph::Settings;
use App::GUI::Juliagraph::Config;

my @interactive_tabs = qw/constraints polynomial mapping/;
my @silent_tabs = qw/color/;
my @settings_tabs = (@interactive_tabs, @silent_tabs);

sub new {
    my ( $class, $parent, $title ) = @_;
    my $self = $class->SUPER::new( $parent, -1, $title );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->CreateStatusBar( 2 );
    $self->SetStatusWidths( 2, 600, 500 );
    $self->SetStatusText( "no file loaded", 1 );
    $self->{'config'} = App::GUI::Juliagraph::Config->new();
    $self->{'title'} = $title;
    Wx::ToolTip::Enable( $self->{'config'}->get_value('tips') );
    Wx::InitAllImageHandlers();

    # create GUI parts
    $self->{'tabs'}            = Wx::AuiNotebook->new($self, -1, [-1,-1], [-1,-1], &Wx::wxAUI_NB_TOP );
    $self->{'tab'}{'constraints'}  = App::GUI::Juliagraph::Frame::Panel::Constraints->new( $self->{'tabs'} );
    $self->{'tab'}{'polynomial'}   = App::GUI::Juliagraph::Frame::Panel::Polynomial->new( $self->{'tabs'} );
    $self->{'tab'}{'mapping'}      = App::GUI::Juliagraph::Frame::Panel::Mapping->new( $self->{'tabs'} );
    $self->{'tab'}{'color'}        = App::GUI::Juliagraph::Frame::Panel::Color->new( $self->{'tabs'}, $self->{'config'} );
    $self->{'tabs'}->AddPage( $self->{'tab'}{'constraints'},  'Constraints');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'polynomial'},   'Polynomial');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'mapping'},      'Color Mapping');
    $self->{'tabs'}->AddPage( $self->{'tab'}{'color'},        'Color Selection');

    $self->{'tab'}{$_}->SetCallBack( sub { $self->sketch( ) } ) for @interactive_tabs;

    $self->{'progress'}            = App::GUI::Juliagraph::Widget::ProgressBar->new( $self, 450, 5, [20, 20, 110]);
    $self->{'board'}               = App::GUI::Juliagraph::Frame::Part::Board->new( $self , 600, 600 );
    $self->{'dialog'}{'about'}     = App::GUI::Juliagraph::Dialog::About->new();

    my $btnw = 50; my $btnh     = 40;# button width and height
    $self->{'btn'}{'draw'}      = Wx::Button->new( $self, -1, '&Draw', [-1,-1],[$btnw, $btnh] );
    $self->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');

    Wx::Event::EVT_BUTTON(     $self, $self->{'btn'}{'draw'},  sub { draw( $self ) });
    Wx::Event::EVT_CLOSE(      $self, sub {
        $self->{'tab'}{'color'}->update_config();
        $self->{'config'}->save();
        $self->{'dialog'}{about}->Destroy();
        $_[1]->Skip(1)
    });

    # GUI layout assembly
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
            $self->{'board'}->set_size( $size );
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

    my $std_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALIGN_CENTER_HORIZONTAL;
    my $vert_attr = $std_attr | &Wx::wxTOP;
    my $vset_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $horiz_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr    = $std_attr | &Wx::wxALL;
    my $line_attr    = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT ;

    my $cmdi_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    my $image_lbl = Wx::StaticText->new( $self, -1, 'Image:' );
    $cmdi_sizer->Add( $image_lbl,     0, $all_attr, 15 );
    $cmdi_sizer->Add( $self->{'progress'},         0, &Wx::wxALIGN_LEFT | &Wx::wxALIGN_CENTER_VERTICAL| &Wx::wxALL, 10 );
    $cmdi_sizer->AddSpacer(5);
    $cmdi_sizer->Add( $self->{'btn'}{'draw'},      0, $all_attr, 5 );
    $cmdi_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $self->{'board'}, 0, $all_attr,  5);
    $board_sizer->Add( $cmdi_sizer,      0, $vert_attr, 5);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $self->{'tabs'}, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    #$setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 1, &Wx::wxEXPAND|&Wx::wxLEFT, 10);

    $self->SetSizer($main_sizer);
    $self->SetAutoLayout( 1 );
    $self->{'btn'}{'draw'}->SetFocus;
    my $size = [1110, 815];
    $self->SetSize($size);
    $self->SetMinSize($size);
    $self->SetMaxSize($size);

    $self->update_recent_settings_menu();
    $self->init();
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
    for (@$recent){
        my $path = $_;
        $self->{'recent_menu'}->Append($Recent_ID, $path);
        Wx::Event::EVT_MENU( $self, $Recent_ID++, sub { $self->open_setting_file( $path ) });
    }
    $self->{'setting_menu'}->Insert( 2, $set_menu_ID, '&Recent', $self->{'recent_menu'}, 'recently saved settings' );
}

sub init {
    my ($self) = @_;
    $self->{'tab'}{$_}->init() for qw/constraints polynomial mapping color/;
    $self->sketch( );
    $self->SetStatusText( "all settings are set to default", 1);
    $self->show_settings_save(1);
}

sub draw {
    my ($self) = @_;
    $self->SetStatusText( "drawing .....", 0 );
    $self->{'board'}->draw( $self->get_settings );
    $self->SetStatusText( "done complete drawing", 0 );
}

sub sketch {
    my ($self) = @_;
    $self->SetStatusText( "sketching a preview .....", 0 );
    $self->{'board'}->sketch( $self->get_settings );
    $self->SetStatusText( "done sketching a preview", 0 );
    $self->show_settings_save(0);
}


sub get_settings {
    my $self = shift;
    return {
        $self->{'tab'}{'polynomial'}->get_settings,
        constraints => $self->{'tab'}{'constraints'}->get_settings,
        mapping     => $self->{'tab'}{'mapping'}->get_settings,
        color       => $self->{'tab'}{'color'}->get_settings,
    };
}
sub set_settings {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    $self->{'tab'}{$_}->set_settings( $data->{$_} ) for qw/constraints mapping color/;
    $self->{'tab'}{'polynomial'}->set_settings( $data );
}

sub show_settings_save {
    my ($self, $status)  = @_;
    $self->{'saved'} = $status;
    $self->SetTitle( $self->{'title'} .($self->{'saved'} ? '': ' *'));
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
        my $dir = App::GUI::Juliagraph::Settings::extract_dir( $path );
        $self->{'config'}->set_value('save_dir', $dir);
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
    my $dir = App::GUI::Juliagraph::Settings::extract_dir( $path );
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
    else     { $self->{'config'}->set_value('save_dir', App::GUI::Juliagraph::Settings::extract_dir( $path )) }
}

sub open_setting_file {
    my ($self, $file ) = @_;
    my $settings = App::GUI::Juliagraph::Settings::load( $file );
    if (ref $settings) {
        $self->set_settings( $settings );
        $self->draw;
        my $dir = App::GUI::Juliagraph::Settings::extract_dir( $file );
        $self->{'config'}->set_value('open_dir', $dir);
        $self->{'config'}->add_setting_file( $file );
        $self->{'tab'}{'color'}->set_state_count( exists $settings->{'mapping'}{'select'}
                                                ? $settings->{'mapping'}{'select'} - 1 : 8);
        $self->update_recent_settings_menu();
        $self->show_settings_save(1);
        $settings;
    } else {
         $self->SetStatusText( $settings, 0);
    }
}

sub write_settings_file {
    my ($self, $file)  = @_;
    my $ret = App::GUI::Juliagraph::Settings::write( $file, $self->get_settings );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
    else     {
        $self->{'config'}->add_setting_file( $file );
        $self->update_recent_settings_menu();
        $self->SetStatusText( "saved settings into file $file", 1 );
        $self->show_settings_save(1);
    }
}

sub write_image {
    my ($self, $file)  = @_;
    $self->{'board'}->save_file( $file );
    $file = App::GUI::Juliagraph::Settings::shrink_path( $file );
    $self->SetStatusText( "saved image under: $file", 0 );
    $self->show_settings_save(1);
}

1;
