package CPANPLUS::Shell::Wx::App;
use Wx qw(wxBITMAP_TYPE_BMP wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_NO_TIMEOUT wxSIMPLE_BORDER
    wxFRAME_NO_TASKBAR wxSTAY_ON_TOP);
use Wx::XRC;
use Cwd;
use Data::Dumper;
use CPANPLUS::Shell::Wx::Frame;
use CPANPLUS::Shell::Wx::util;

#enable gettext support
use Wx::Locale gettext => '_T';

BEGIN {
  use vars        qw( @ISA $VERSION );
  @ISA        =   qw( Wx::App);
  $VERSION    =   '0.01';
}

use base 'Wx::App';

#create a new app instance
sub new {
    my( $class, $parent ) = @_;
    print _T("Creating new CPANPLUS::Shell::Wx::App...\n");
    my $self = $class->SUPER::new( $parent );
    return $self;
}

#initialize the app
sub OnInit{
    my $self=shift;

    #create splaashscreen
    my $splashImage=Wx::Bitmap->new(_uGetInstallPath('CPANPLUS::Shell::Wx::res::splash.bmp'),wxBITMAP_TYPE_BMP );
    $self->{splash}=Wx::SplashScreen->new(
        $splashImage, wxSPLASH_CENTRE_ON_SCREEN|wxSPLASH_NO_TIMEOUT,10000,undef);


    print _T("Creating new CPANPLUS::Shell::Wx::Frame...\n");
    #ensure we are working with a valid files
    my $xrc_file     = _uGetInstallPath('CPANPLUS::Shell::Wx::res::MainWin.xrc');
    print _T("Locating XRC File: $xrc_file...");
    unless ( -e $xrc_file ) {
        print _T("[ERROR]\n\tUnable to find XRC Resource file!\n\tExiting...\n");
        return 1;
    }
    print _T("[Done]\nCreating New Frame and Loading XRC File...");

    #create frame from xrc file
    $self->{xresWin} = Wx::XmlResource->new();
    Wx::XmlResource::AddSubclassFactory( CPANPLUS::Shell::Wx::Frame::XRCFactory->new );
    $self->{xresWin}->InitAllHandlers();
    $self->{xresWin}->Load($xrc_file);
    my $mainWin=CPANPLUS::Shell::Wx::Frame->new($self); #CPANPLUS::Shell::Wx::Frame->new($self);
    $self->{xresWin}->LoadFrame( $mainWin,undef, 'main_window' )
      or return;
    print _T("[Done]\n");

    #show the main window
    $mainWin->Show(1);

    return 1;
}
1;