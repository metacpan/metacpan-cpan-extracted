use v5.12;
use warnings;
use utf8;
use Wx::AUI;
# fast preview
# modular conections
# X Y sync ? , undo ?

package App::GUI::Cellgraph::Frame;
use base qw/Wx::Frame/;
use App::GUI::Cellgraph::Frame::Panel::Rules;
use App::GUI::Cellgraph::Frame::Panel::Start;
use App::GUI::Cellgraph::Frame::Part::Board;
use App::GUI::Cellgraph::Dialog::Function;
use App::GUI::Cellgraph::Dialog::Interface;
use App::GUI::Cellgraph::Dialog::About;
use App::GUI::Cellgraph::Settings;

sub new {
    my ( $class, $parent, $title ) = @_;
    my $self = $class->SUPER::new( $parent, -1, $title );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->CreateStatusBar( 1 );
    #$self->SetStatusWidths(2, 800, 100);
    Wx::InitAllImageHandlers();

    # create GUI parts
    $self->{'tabs'}           = Wx::AuiNotebook->new( $self, -1, [-1,-1], [-1,-1], &Wx::wxAUI_NB_TOP );
    $self->{'panel'}{'rules'} = App::GUI::Cellgraph::Frame::Panel::Rules->new( $self->{'tabs'} );
    $self->{'panel'}{'start'} = App::GUI::Cellgraph::Frame::Panel::Start->new( $self->{'tabs'} );
    #$self->{'tab'}{'pen'}       = Wx::Panel->new($self->{'tabs'});
    $self->{'tabs'}->AddPage( $self->{'panel'}{'start'}, 'Start');
    $self->{'tabs'}->AddPage( $self->{'panel'}{'rules'}, 'Rules');
    #$self->{'tabs'}->AddPage( $self->{'tab'}{'pen'},    'Pen Settings');
    $self->{'tabs'}{'type'} = 0;
    $self->{'img_size'} = 700;
    $self->{'img_format'} = 'png';

    #$self->{'color'}{'start'}   = App::GUI::Cellgraph::Frame::Part::ColorBrowser->new( $self->{'tab'}{'pen'}, 'start', { red => 20, green => 20, blue => 110 } );
    #$self->{'color'}{'startio'} = App::GUI::Cellgraph::Frame::Part::ColorPicker->new( $self->{'tab'}{'pen'}, $self, 'Color IO', $self->{'config'}->get_value('color') , 162, 1);
                               
    $self->{'board'}               = App::GUI::Cellgraph::Frame::Part::Board->new( $self , 800, 800 );
    $self->{'dialog'}{'about'}     = App::GUI::Cellgraph::Dialog::About->new();
    # $self->{'dialog'}{'interface'} = App::GUI::Cellgraph::Dialog::Interface->new();
    # $self->{'dialog'}{'function'}  = App::GUI::Cellgraph::Dialog::Function->new();
    $self->{'panel'}{'rules'}->SetCallBack( sub { $self->draw( ) } );
    $self->{'panel'}{'start'}->SetCallBack( sub { $self->draw( ) } );

    Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $self, $self->{'tabs'}, sub {
        $self->{'tabs'}{'type'} = $self->{'tabs'}->GetSelection unless $self->{'tabs'}->GetSelection == $self->{'tabs'}->GetPageCount - 1;
    });
    Wx::Event::EVT_CLOSE( $self, sub {
       # my $all_color = $self->{'config'}->get_value('color');
       # my $startc = $self->{'color'}{'startio'}->get_data;
       # for my $name (keys %$startc){
       #     $all_color->{$name} = $startc->{$name} unless exists $all_color->{$name};
       # }
        $self->{'dialog'}{$_}->Destroy() for qw/about/; # interface function
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
            $self->{'img_size'} = 100 * ($_[1]->GetId - 12100); 
            $self->{'board'}->set_size( $self->{'img_size'} );
        });
        
    }
    $image_size_menu->Check( 12100 +($self->{'img_size'} / 100), 1);

    
    my $image_menu = Wx::Menu->new();
    # $image_menu->Append( 12300, "&Draw\tCtrl+D", "complete a sketch drawing" );
    $image_menu->Append( 12100, "S&ize",  $image_size_menu,   "set image size" );
    $image_menu->Append( 12400, "&Save\tCtrl+S", "save currently displayed image" );

    
    my $help_menu = Wx::Menu->new();
    #$help_menu->Append( 13100, "&Function\tAlt+F", "Dialog with information how an Cellgraph works" );
    #$help_menu->Append( 13200, "&Knobs\tAlt+K", "Dialog explaining the layout and function of knobs" );
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
    Wx::Event::EVT_MENU( $self, 13100, sub { $self->{'dialog'}{'function'}->ShowModal });
    Wx::Event::EVT_MENU( $self, 13200, sub { $self->{'dialog'}{'interface'}->ShowModal });
    Wx::Event::EVT_MENU( $self, 13300, sub { $self->{'dialog'}{'about'}->ShowModal });

    my $std_attr = &Wx::wxALIGN_LEFT|&Wx::wxGROW|&Wx::wxALIGN_CENTER_HORIZONTAL;
    my $vert_attr = $std_attr | &Wx::wxTOP;
    my $vset_attr = $std_attr | &Wx::wxTOP| &Wx::wxBOTTOM;
    my $horiz_attr = $std_attr | &Wx::wxLEFT;
    my $all_attr    = $std_attr | &Wx::wxALL;
    my $line_attr    = $std_attr | &Wx::wxLEFT | &Wx::wxRIGHT ;
 
    #my $pen_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    #$pen_sizer->AddSpacer(5);
    #$pen_sizer->Add( $self->{'line'},             0, $vert_attr, 10);
    #$pen_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'pen'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    #$pen_sizer->AddSpacer(10);
    #$pen_sizer->Add( Wx::StaticText->new( $self->{'tab'}{'pen'}, -1, 'Start Color', [-1,-1], [-1,-1], &Wx::wxALIGN_CENTRE_HORIZONTAL), 0, &Wx::wxALIGN_CENTER_HORIZONTAL|&Wx::wxGROW|&Wx::wxALL, 5);
    #$pen_sizer->Add( $self->{'color'}{'start'},   0, $vert_attr, 0);
    #$pen_sizer->AddSpacer( 5);
    #$pen_sizer->Add( Wx::StaticLine->new( $self->{'tab'}{'pen'}, -1, [-1,-1], [ 135, 2] ),  0, $vert_attr, 10);
    #$pen_sizer->AddSpacer( 5);
    #$pen_sizer->Add( $self->{'color'}{'startio'}, 0, $vert_attr,  5);
    #$pen_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    #$self->{'tab'}{'pen'}->SetSizer( $pen_sizer );
    
    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $self->{'board'}, 0, $all_attr,  5);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $self->{'tabs'}, 1, &Wx::wxEXPAND | &Wx::wxGROW);
    #$setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 1, &Wx::wxEXPAND|&Wx::wxLEFT, 0);

    $self->SetSizer($main_sizer);
    $self->SetAutoLayout( 1 );
    $self->{'tabs'}->SetFocus;
    my $size = [1295, 880];
    $self->SetSize($size);
    $self->SetMinSize($size);
    $self->SetMaxSize($size);
  
    $self->init();
    $self->SetStatusText( "settings in init state", 0 );
    $self->{'last_file_settings'} = $self->get_data;
    $self;
}

sub init {
    my ($self) = @_;
    #$self->{'color'}{$_}->init() for qw/start/;
    $self->{'panel'}{ $_ }->init() for qw/rules start/;
    $self->draw( );
    $self->SetStatusText( "all settings are set to default", 0);
}

sub get_data {
    my $self = shift;
    { 
        rules => $self->{'panel'}{'rules'}->get_data,
        start => $self->{'panel'}{'start'}->get_data,
    }
}

sub set_data {
    my ($self, $data) = @_;
    return unless ref $data eq 'HASH';
    #$self->{'color'}{$_}->set_data( $data->{ $_.'_color' } ) for qw/start/;
    $self->{'panel'}{ $_ }->set_data( $data->{ $_ } ) for qw/rules start/;
}

sub draw {
    my ($self) = @_;
    $self->{'board'}->set_data( $self->get_data );
    $self->{'board'}->Refresh;
}

sub open_settings_dialog {
    my ($self) = @_;
    my $dialog = Wx::FileDialog->new ( $self, "Select a settings file to load", '.', '',
                   ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    my $ret = $self->open_setting_file ( $path );
    if (not ref $ret) { $self->SetStatusText( $ret, 0) }
    else { 
        my $dir = App::GUI::Cellgraph::Settings::extract_dir( $path );
        $self->SetStatusText( "loaded settings from ".$dialog->GetPath, 0);
    }
}

sub write_settings_dialog {
    my ($self) = @_;
    my $dialog = Wx::FileDialog->new ( $self, "Select a file name to store data", '.', '',
               ( join '|', 'INI files (*.ini)|*.ini', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    #my $i = rindex $path, '.';
    #$path = substr($path, 0, $i - 1 ) if $i > -1;
    #$path .= '.ini' unless lc substr ($path, -4) eq '.ini';
    return if -e $path and
              Wx::MessageDialog->new( $self, "\n\nReally overwrite the settings file?", 'Confirmation Question',
                                      &Wx::wxYES_NO | &Wx::wxICON_QUESTION )->ShowModal() != &Wx::wxID_YES;
    $self->write_settings_file( $path );
    #~ my $dir = App::GUI::Cellgraph::Settings::extract_dir( $path );
    #~ $self->{'config'}->set_value('write_dir', $dir);
}

sub save_image_dialog {
    my ($self) = @_;
    my @wildcard = ( 'SVG files (*.svg)|*.svg', 'PNG files (*.png)|*.png', 'JPEG files (*.jpg)|*.jpg');
    my $wildcard = '|All files (*.*)|*.*';
    $wildcard = ( join '|', @wildcard[1,0,2]) . $wildcard;
    
    my $dialog = Wx::FileDialog->new ( $self, "select a file name to save image", '.', '', $wildcard, &Wx::wxFD_SAVE );
    return if $dialog->ShowModal == &Wx::wxID_CANCEL;
    my $path = $dialog->GetPath;
    return if -e $path and
              Wx::MessageDialog->new( $self, "\n\nReally overwrite the image file?", 'Confirmation Question',
                                      &Wx::wxYES_NO | &Wx::wxICON_QUESTION )->ShowModal() != &Wx::wxID_YES;
    my $ret = $self->write_image( $path );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
}


sub open_setting_file {
    my ($self, $file ) = @_;
    my $data = App::GUI::Cellgraph::Settings::load( $file );
    if (ref $data) {
        $self->set_data( $data );
        $self->draw;
        my $dir = App::GUI::Cellgraph::Settings::extract_dir( $file );
        $self->SetStatusText( "loaded settings from ".$file, 0) ;
        $self->update_recent_settings_menu();
        $data;
    } else {
         $self->SetStatusText( $data, 0);
    }
}

sub update_recent_settings_menu {
    my ($self) = @_;
    #    my $recent = $self->{'config'}->get_value('last_settings');
    # return unless ref $recent eq 'ARRAY';
#    my $set_menu_ID = 11300;
#    $self->{'setting_menu'}->Destroy( $set_menu_ID );
 #   my $Recent_ID = $set_menu_ID + 1;
  #  $self->{'recent_menu'} = Wx::Menu->new();
   # for (@$recent){
#        my $path = $_;
 #       $self->{'recent_menu'}->Append($Recent_ID, $path);
  #      Wx::Event::EVT_MENU( $self, $Recent_ID++, sub { $self->open_setting_file( $path ) });
   # }
    #$self->{'setting_menu'}->Insert( 2, $set_menu_ID, '&Recent', $self->{'recent_menu'}, 'recently saved settings' );

}

sub write_settings_file {
    my ($self, $file)  = @_;
    my $ret = App::GUI::Cellgraph::Settings::write( $file, $self->get_data );
    if ($ret){ $self->SetStatusText( $ret, 0 ) }
    else     { 
        $self->update_recent_settings_menu();
        $self->SetStatusText( "saved settings into file $file", 0 );
    }
}

sub write_image {
    my ($self, $file)  = @_;
    $self->{'board'}->save_file( $file );
    $file = App::GUI::Cellgraph::Settings::shrink_path( $file );
    $self->SetStatusText( "saved image under: $file", 0 );
}

1;
