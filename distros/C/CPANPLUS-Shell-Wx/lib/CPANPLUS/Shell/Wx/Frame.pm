package CPANPLUS::Shell::Wx::Frame;
#TODO: Create a first-time wizard
#TODO: Check if CPAN/CPANPLUS is updated at startup


use base qw(Wx::Frame);
use Wx qw/:allclasses wxFD_SAVE wxFD_OVERWRITE_PROMPT wxID_OK wxID_CANCEL
    wxFD_OPEN wxLIST_AUTOSIZE wxYES_NO wxYES wxTB_TEXT/;
use Wx::Event qw(EVT_MENU EVT_TOOL EVT_WINDOW_CREATE EVT_BUTTON EVT_TEXT_ENTER);
use Wx::ArtProvider qw/:artid :clientid/;
use Wx::Help qw/wxHF_DEFAULT_STYLE/;

use CPANPLUS::Shell::Wx::Configure;
use CPANPLUS::Shell::Wx::ModuleTree;
use CPANPLUS::Shell::Wx::ModulePanel;
use CPANPLUS::Shell::Wx::util;
use CPANPLUS::Shell::Wx::PODReader;

#use File::Spec;

#enable gettext support
use Wx::Locale gettext => '_T';

use Cwd;
use Data::Dumper;

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new();
    $self->{is_created}=0;
    $self->{parent} = $parent;
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    return $self;
}
sub OnCreate{
    my $self = shift;
    my ($event) = @_;
    return if $self->{is_created};
    $self->{list}=Wx::Window::FindWindowByName('nb_main_mod_tree_pane');

    print _T("Setting up UI\n");

    #set the window icon to the default
    $self->SetIcon(Wx::GetWxPerlIcon());

    #create a logging console first off log_console
    print _T("Switching to Logging Console...");
    $self->{log} = Wx::Log::SetActiveTarget(
            Wx::LogTextCtrl->new(
                    Wx::Window::FindWindowByName('log_console')) );
    Wx::LogMessage(_T("Initializing Log Console..."));
    print _T("[DONE]\nNew messages will be redirected to Logging console, under the Log Tab\n");

    #create references for easier access and faster execution
    $self->{cpan}   = CPANPLUS::Backend->new(); #only one Backend per running program
    $self->{config} = $self->{cpan}->configure_object;
#    $self->{categories}=$self->_get_categories;

    #unused variable used to initialize cpan
    my $unused_var_to_init_cpanpp=$self->{cpan}->module_tree('CPANPLUS');

    $self->{is_created}=1;

    #ssetup various controls
    $self->_setup_toolbar();
    $self->_setup_menu();
    $self->_setup_modules();
#    $self->_setup_actionslist();

    my $main_nb=Wx::Window::FindWindowByName('nb_main');
    $self->{podReader}=CPANPLUS::Shell::Wx::PODReader::Embed->new($main_nb);
    $main_nb->AddPage(
        $self->{podReader},
        _T("POD Reader")
    );

    EVT_BUTTON($self, Wx::Window::FindWindowByName('actions_clear'),\&ClearActions);
    EVT_BUTTON($self, Wx::Window::FindWindowByName('actions_process'),\&ProcessActions);

    #destroy splash screen, if any.
    $self->{parent}->{splash}->Destroy if $self->{parent}->{splash};

    #check for updated version of CPANPLUS and First Time usage
    $self->CheckUpdate();
    $self->CheckFirstTime();

    #$self->ShowPrefs; #for testing

    _uShowErr;
}

sub _setup_modules{
    my $self=shift;
    print "Setting up modules...\n";
    my $panel=Wx::Window::FindWindowByName('nb_main_mod_tree_pane');

    $self->{status_icons}=_uGetImageData();

#    print "Setting Module tree...\n";
    $self->{panel}=$panel;
    $panel->SetModuleTree(Wx::Window::FindWindowByName('tree_modules'));
#    print "Setting Image list...\n";
    $panel->SetCPP($self->{cpan});
    $panel->SetImageList($self->{status_icons});
    $panel->SetStatusBar(Wx::Window::FindWindowByName('main_window_status'));
    $panel->SetPODReader($self->{podReader});

    print "Initializing ModulePanel...\n";
    $panel->Init();
    $panel->SetDblClickHandler(sub{$self->ShowPODReader(@_)});
    $panel->SetInstallMenuHandler(sub{$self->SetAction(@_,_T('Install'))});
    $panel->SetUpdateMenuHandler(sub{$self->SetAction(@_,_T('Update'))});
    $panel->SetUninstallMenuHandler(sub{$self->SetAction(@_,_T('Uninstall'))});
    $panel->SetFetchMenuHandler(sub{$self->SetAction(@_,_T('Fetch'))});
    $panel->SetPrepareMenuHandler(sub{$self->SetAction(@_,_T('Prepare'))});
    $panel->SetBuildMenuHandler(sub{$self->SetAction(@_,_T('Build'))});
    $panel->SetTestMenuHandler(sub{$self->SetAction(@_,_T('Test'))});
}

#this method shows the PODReader tab and displays the documentation for the selected module
sub ShowPODReader{
    my $self     = shift;
    my ($event)  = @_;
    print "Showing POD Reader\n";
#    $self->{podReader}=CPANPLUS::Shell::Wx::PODReader::Frame->new($self) unless $self->{podReader};
#    $self->{podReader}->Show(1) if ($self->{podReader} && $self->{podReader}->isa('Wx::Frame'));
    $self->{podReader}->Search($self->{panel}->{thisName});
    Wx::Window::FindWindowByName('nb_main')->ChangeSelection(3);

}
sub SetAction{
    my ($self,$menu,$cmd_event,$modName,$cmd)=@_;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    my $modtree=Wx::Window::FindWindowByName('tree_modules');
    $actionslist->AddActionWithPre($modName,undef,$cmd);
}

sub CheckUpdate{
    my $self=shift;
    my $cp=$self->{cpan}->module_tree('CPANPLUS');
    unless ($cp->is_uptodate()){
        my $reply=Wx::MessageBox(_T("CPANPLUS needs to be updated. Would you like to update now?"), _T("Update CPANPLUS?"),
                            wxYES_NO, $self);
        $self->ShowUpdateWizard() if ($reply==wxYES);
    }

}
sub CheckFirstTime{
    my $self = shift;
    my ($event) = @_;
    unless (-e _uGetPath($self->{config},'app_config')){
        my $reply=Wx::MessageBox(_T("This is the first time you have run wxCPAN. Would you like to review your preferences?"), _T("Update CPANPLUS?"),
                            wxYES_NO, $self);
            $self->ShowPrefs if $reply==wxYES;
    }
}
sub ShowUpdateWizard{
    my $self = shift;
    my ($event) = @_;
    use CPANPLUS::Shell::Wx::UpdateWizard;
    my $wizard=new CPANPLUS::Shell::Wx::UpdateWizard();
    $wizard->SetCPPObject($self->{cpan});
    $wizard->Run();

}

#opens an actions file (.cpan default extension)
sub OnOpen{
    my $self = shift;
    my ($event) = @_;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    my $dlg=Wx::FileDialog->new($self,_T("Open Actions File:"),'','',_T("CPAN Actions files (*.cpan)|*.cpan|All files (*.*)|*.*"),wxFD_OPEN);
    if ($dlg->ShowModal() == wxID_OK){
        Wx::LogMessage( _T("Opening ").$dlg->GetPath() );
        if (open(F,$dlg->GetPath())){
            my @lines=<F>;
            close F;
            return unless @lines;   #check for empty file
            foreach $l (reverse(@lines)){
                chomp($l);
                next if $l=~/^\s*\#/; #skip comment lines
                my ($name,$action)=split(',',$l);
                $actionslist->InsertStringItem( 0, $name );
                $actionslist->SetItem( 0, 1, $action );
            }
        }
    }
}

#saves an actions file to disk
sub OnSave{
    my $self = shift;
    my ($event) = @_;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    my $numInList=$actionslist->GetItemCount();
    #return if there are no items in the list
    unless ($numInList >0){
        Wx::MessageBox(_T("There are no items in the queue."));
        return;
    }
    my $dlg=Wx::FileDialog->new($self,_T("Save Actions File:"),'','',_T("CPAN Actions files (*.cpan)|*.cpan|All files (*.*)|*.*"),wxFD_SAVE|wxFD_OVERWRITE_PROMPT);
    if ($dlg->ShowModal() == wxID_OK){
        Wx::LogMessage( _T("Saving to ").$dlg->GetPath() );
        if (open(F,">".$dlg->GetPath())){
            for (my $i=0;$i<$numInList;$i++){
                my $item=$actionslist->GetItemText($i);
                my $action=$actionslist->GetItem(0,1)->GetText();
                print F "$item,$action\n";
            }
            close F;
        }
    }
}
sub ClearActions{
    my $self = shift;
    my ($event) = @_;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    $actionslist->DeleteAllItems();
}
sub ProcessActions{
    my $self = shift;
    my ($event) = @_;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    while ($modName=$actionslist->GetItemText(0)){
        my $action=$actionslist->GetItem(0,1)->GetText();
        $action = "create" if $action eq "Build";
        Wx::LogMessage(_T("Processing $action for $modName."));
        my $mod=$self->{cpan}->module_tree($modName);
        if ($mod){
            my $bool=0;
            eval "\$bool = \$mod->".lc($action)."();";
            print $@ if $@;
            Wx::LogMessage(_T("FAILED TO INSTALL ").$modName._T(". OUTPUT:")) if $bool;
            _uShowErr;
        }
        $actionslist->DeleteItem(0);
    }
}

sub ShowConfigDump{
    my $self = shift;
    my ($event) = @_;
    Wx::Window::FindWindowByName('log_console')->AppendText(Dumper($self->{config}));
}

#exit program, destroy window
sub OnQuit{
    my $self = shift;
    $self->Close(1);
}

#show preferences dialog
sub ShowPrefs{
    Wx::LogMessage _T("Displaying Preferences...");
    my $self     = shift;
    my ($event)  = @_;
    my $xrc_file     = _uGetInstallPath('CPANPLUS::Shell::Wx::res::PrefsWin.xrc');
    unless ( -e $xrc_file ) {
        Wx::LogError
          _T("ERROR: Unable to find XRC Resource file: $xrc_file !\n Exiting...");
        return 1;
    }
    my $prefsxrc = Wx::XmlResource->new();
    $prefsxrc->InitAllHandlers();
    $prefsxrc->Load($xrc_file);

    #print Dumper $self,$parent;
    $self->{prefsWin} = $prefsxrc->LoadDialog( $self, 'prefs_window' )
      or return;

    $self->{prefsWin}->Show(1);
}
#show podreader dialog
#sub ShowPODReader{
#    my $self     = shift;
#    my ($event)  = @_;
#    $self->{podReader}=CPANPLUS::Shell::Wx::PODReader::Frame->new($self) unless $self->{podReader};
#    $self->{podReader}->Show(1) if ($self->{podReader});
#    Wx::Window::FindWindowByName('nb_main')->ChangeSelection(3);
#}

sub _setup_actionslist{
    $self=shift;
    my $actionslist=Wx::Window::FindWindowByName('main_actions_list');
    $actionslist->InsertColumn( 0, _T('Module'));
    $actionslist->InsertColumn( 1, _T('Action') );
    $actionslist->SetColumnWidth(0,wxLIST_AUTOSIZE);
    $actionslist->SetColumnWidth(1,wxLIST_AUTOSIZE);

}


sub _setup_menu{
    $self=shift;
    #attach menu events
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_file_quit'),  \&OnQuit );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_file_open'),  \&OnOpen );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_file_save'),  \&OnSave );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_edit_prefs'), \&ShowPrefs );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_help_show_log_console'), \&ShowLog );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_show_config_dump'), \&ShowConfigDump );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_help_pod_reader'), \&ShowPODReader );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_help_about'), \&ShowAboutBox );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_help_help'), \&ShowHelpWindow );
    EVT_MENU( $self, Wx::XmlResource::GetXRCID('mnu_help_updatewizard'), \&ShowUpdateWizard );

}
sub _setup_toolbar{
    $self=shift;
    my $tb=$self->GetToolBar() || $self->CreateToolBar(wxTB_TEXT);
    $self->{toolbar}=$tb;

    #get rid of old tools. The ones in XRC file are placeholders
    $tb->ClearTools();

    #set up icons
    my $tb_icon_installed=Wx::ArtProvider::GetBitmap(wxART_TICK_MARK,wxART_TOOLBAR_C);
    my $tb_icon_update=Wx::ArtProvider::GetBitmap(wxART_ADD_BOOKMARK,wxART_TOOLBAR_C);
    my $tb_icon_remove=Wx::ArtProvider::GetBitmap(wxART_DEL_BOOKMARK,wxART_TOOLBAR_C);
    my $tb_icon_not_installed=Wx::ArtProvider::GetBitmap(wxART_NEW_DIR,wxART_TOOLBAR_C);
    my $tb_icon_unknown=Wx::ArtProvider::GetBitmap(wxART_QUESTION,wxART_TOOLBAR_C);
    my $tb_icon_cat=Wx::ArtProvider::GetBitmap(wxART_QUESTION,wxART_TOOLBAR_C);
    my $tb_icon_authors=Wx::ArtProvider::GetBitmap(wxART_HELP_SETTINGS,wxART_TOOLBAR_C);
    my $tb_icon_names=Wx::ArtProvider::GetBitmap(wxART_QUESTION,wxART_TOOLBAR_C);
    my $tb_icon_populate=Wx::ArtProvider::GetBitmap(wxART_EXECUTABLE_FILE,wxART_TOOLBAR_C);

    #Add the tools. for some reason, we can't attach events in this step. It breaks.
    my $idstart=10000; #the control IDs start here
    my @tb_items=(
         $tb->AddRadioTool($idstart,_T("Installed"),$tb_icon_installed,$tb_icon_installed,_T("Show Installed Modules")),
         $tb->AddRadioTool($idstart+1,_T("Updates"),$tb_icon_update,$tb_icon_update,_T("List Modules to be Updated")),
         $tb->AddRadioTool($idstart+2,_T("New"),$tb_icon_not_installed,$tb_icon_not_installed,_T("List New Modules")),
         $tb->AddRadioTool($idstart+3,_T("All"),$tb_icon_installed,$tb_icon_installed,_T("List All Modules")),
         $tb->AddSeparator(),
         $tb->AddRadioTool($idstart+4,_T("Categories"),$tb_icon_cat,$tb_icon_cat,_T("Sort List by Category")),
         $tb->AddRadioTool($idstart+5,_T("Names"),$tb_icon_names,$tb_icon_names,_T("Sort List by Module Name")),
         $tb->AddRadioTool($idstart+6,_T("Authors"),$tb_icon_authors,$tb_icon_authors,_T("Sort List By Authors")),
          $tb->AddSeparator(),
         $tb->AddTool($idstart+7,_T("Update List"),$tb_icon_populate,_T("Re-Populate the tree"))
     );


    #attach events
    EVT_TOOL( $self, $idstart, sub{$self->{list}->ShowInstalled();} );
    EVT_TOOL( $self, $idstart+1, sub{$self->{list}->ShowUpdated();} );
    EVT_TOOL( $self, $idstart+2, sub{$self->{list}->ShowNew();} );
    EVT_TOOL( $self, $idstart+3, sub{$self->{list}->ShowAll();} );
    EVT_TOOL( $self, $idstart+4, sub{$self->{list}->SortByCategory();} );
    EVT_TOOL( $self, $idstart+5, sub{$self->{list}->SortByName();} );
    EVT_TOOL( $self, $idstart+6, sub{$self->{list}->SortByAuthor();} );
    EVT_TOOL( $self, $idstart+7, sub{$self->{list}->Populate();} );

}
sub ShowAboutBox{
    my $self=shift;
    my $info = Wx::AboutDialogInfo->new();
    $info->AddArtist('Skaman Sam Tyler');
    $info->AddArtist('');
    $info->AddArtist(_T('Thanks to David Vignoni,'));
    $info->AddArtist('  http://www.icon-king.com/,');
    $info->AddArtist(_T('  for the "box" in the Splash Screen,'));
    $info->AddArtist(_T('  Taken from the Nuvola Icon theme'));
    $info->AddArtist('');
    $info->AddArtist(_T('Thanks to Various Artists,'));
    $info->AddArtist('  http://tango.freedesktop.org');
    $info->AddArtist(_T('  for the "arrow" in the Splash Screen,'));
    $info->AddArtist(_T('  Taken from the Tango Icon theme'));
    $info->AddDeveloper('Skaman Sam Tyler');
    $info->AddDocWriter('Skaman Sam Tyler');
#    $info->AddTranslator('');
    $info->SetCopyright(_T("wxCPAN is GPL'd software."));
    $info->SetDescription(_T("wxCPAN is an interface to CPANPLUS. ").
            _T("It was written for the Google Summer of Code 2008, under the ").
            _T("mentoring abilities of Herbert Bruening. You can use wxCPAN to ").
            _T("manage your Perl installation, as well as create new Modules ").
            _T("to post to CPAN."));
#    $info->SetIcon('');
    $info->SetLicence(_T('This is GPL\'d software.'));
    $info->SetName('wxCPAN');
    $info->SetVersion('0.01');
    $info->SetWebSite('http://wxcpan.googlecode.com');
    Wx::AboutBox($info);
}
sub ShowHelpWindow{
    my $self=shift;

    use Wx::Help qw/wxHF_TOOLBAR wxHF_FLAT_TOOLBAR wxHF_CONTENTS wxHF_INDEX wxHF_SEARCH
    wxHF_BOOKMARKS wxHF_OPEN_FILES wxHF_PRINT wxHF_MERGE_BOOKS wxHF_ICONS_BOOK
    wxHF_ICONS_FOLDER wxHF_ICONS_BOOK_CHAPTER wxHF_EMBEDDED wxHF_DIALOG
    wxHF_FRAME wxHF_MODAL wxHF_DEFAULT_STYLE /;
    Wx::FileSystem::AddHandler(new Wx::ArchiveFSHandler);
    my $helpFile=_uGetInstallPath('CPANPLUS::Shell::Wx::help::wxCPAN.hhp');
    my $helpwin=Wx::HtmlHelpController->new();
    $helpwin->AddBook($helpFile,1);
    #my $helpwin=CPANPLUS::Shell::Wx::Frame::HelpWindow->new($self);
    $helpwin->DisplayContents();
}

########################################
########### Search Button ##############
########################################

package CPANPLUS::Shell::Wx::Frame::SearchButton;
use base 'Wx::Button';
use Wx::Event qw/EVT_WINDOW_CREATE EVT_BUTTON/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );

    return $self;
}

sub OnCreate {
    my $self = shift;
    EVT_BUTTON( $self, $self, \&OnClick );
}

sub OnClick{
    my $self=shift;
    my $searchbox=Wx::Window::FindWindowByName('cb_main_search')->GetValue();
    my $typebox=Wx::Window::FindWindowByName('cb_search_type')->GetValue();
    Wx::Window::FindWindowByName('main_window')->{list}->search(
        $typebox,
        $searchbox);

}

########################################
############# Search Box ###############
########################################

package CPANPLUS::Shell::Wx::Frame::SearchBox;
use base 'Wx::ComboBox';
use Wx::Event qw/EVT_WINDOW_CREATE EVT_TEXT_ENTER/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );

    return $self;
}

sub OnCreate {
    my $self = shift;
    EVT_TEXT_ENTER( $self, $self, \&OnEnter );
}

sub OnEnter{
    my $self=shift;
    my $searchbox=$self->GetValue();
    my $typebox=Wx::Window::FindWindowByName('cb_search_type')->GetValue();
    Wx::Window::FindWindowByName('main_window')->{list}->search(
        $typebox,
        $searchbox);

}
########################################
############### Toolbar ################
########################################

package CPANPLUS::Shell::Wx::Frame::ToolBar;
use Wx::Event qw(EVT_WINDOW_CREATE EVT_BUTTON);
use Data::Dumper;

BEGIN {
    use vars qw( @ISA $VERSION );
    @ISA     = qw( Wx::ToolBar);
    $VERSION = '0.01';
}

use base 'Wx::ToolBar';
use Wx::ArtProvider qw/:artid :clientid/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    print "Toolbar items: ".$self->GetToolsCount;


    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    return $self;
}
sub OnCreate {
    my $self = shift;
    my ($event)=@_;

}


########################################
########## Logging Console #############
########################################

package CPANPLUS::Shell::Wx::Frame::LogConsole;
use Wx::Event qw(EVT_WINDOW_CREATE EVT_BUTTON EVT_TEXT);
use Data::Dumper;
use Wx qw/wxRED/;
BEGIN {
    use vars qw( @ISA $VERSION );
    @ISA     = qw( Wx::TextCtrl Wx::Log Wx::LogTextCtrl);
    $VERSION = '0.01';
}

use base 'Wx::TextCtrl';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_TEXT($self,$self,\&DoLog);
    $self->{old_pos}=0;
    $self->{new_pos}=0;
    return $self;
}

#this method is called after the text is sent to the LogConsole.
#it is supposed to colorize the messages based on the level,
#but it doesn't seem to work correctly as of yet.
#TODO Fix this so it colors correctly.
sub DoLog{
    my ($self,$event)=@_;
    $self->{new_pos}=$self->GetLastPosition();
    my $txt=$self->GetRange($self->{old_pos},$self->{new_pos});
    $txt=~/((\d\d\:\s*\d\d:\s*\d\d\s*[P|A]M):\s*(\[.*?\])?)\s*(.*)/; #\s*(\[.*?\])?(.*)/;
    my $prefix=$1;my $time=$2;my $cpan=$3;my $msg=$4;
    my $msg_start=$self->{old_pos}+length($prefix);
    $self->SetStyle($msg_start,$self->{new_pos},Wx::TextAttr->new(wxRED));
    $self->{old_pos}=$self->GetLastPosition();
}
sub DoLogString{
    print "DoLogString ".Dumper(@_);
}


########################################
############ XRC Factory ###############
########################################
package CPANPLUS::Shell::Wx::Frame::XRCFactory;
use strict;
use Wx;
use Data::Dumper;
use base "Wx::XmlSubclassFactory";
sub new {
     my $class = shift;
     my $self = $class->SUPER::new();
     return $self;
}
sub Create { #($self,$object)
    my $object=$_[1]->new;
#    print "Creating Object: $object;\n";
    return $object;
}
sub DoCreateResource{
    print "DoCreateResource()\n";
}

########################################
############ Help Window ###############
########################################
package CPANPLUS::Shell::Wx::Frame::HelpWindow;
use Data::Dumper;
use CPANPLUS::Shell::Wx::util;

use Wx qw[:everything];
use base qw(Wx::Frame);
use strict;

sub new {
    my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $title  = ""                 unless defined $title;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    Wx::InitAllImageHandlers();

    $style = wxDEFAULT_FRAME_STYLE
        unless defined $style;

    $self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{view} = Wx::HtmlWindow->new($self, -1);

    $self->SetTitle(_T("wxCPAN Help"));
    $self->SetSize(Wx::Size->new(520, 518));

    $self->{sizer_1} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_1}->Add($self->{view}, 1, wxEXPAND, 0);
    $self->SetSizer($self->{sizer_1});
    $self->Layout();

    $self->{view}->LoadPage(_uGetInstallPath('CPANPLUS::Shell::Wx::help::index.html'));

#    Wx::Event::EVT_HTML_LINK_CLICKED($self,$self->{view}->GetId,\&OnLinkClicked);


    return $self;

}

sub OnLinkClicked{
    my ($self,$event)=@_;
    my $ctrl=$event->GetEventObject();
    my $link=$event->GetLinkInfo()->GetHref();
    $self->{view}->LoadPage(_uGetInstallPath("CPANPLUS::Shell::Wx::help::$link"));
}

########################################
############ Actions List ##############
########################################
package CPANPLUS::Shell::Wx::Frame::ActionsList;
use Data::Dumper;
use CPANPLUS::Shell::Wx::util;

use Wx qw[:everything wxDEFAULT_FRAME_STYLE wxDefaultPosition
    wxDefaultSize wxLIST_AUTOSIZE wxLC_REPORT wxSUNKEN_BORDER
    wxDefaultValidator wxLC_LIST wxIMAGE_LIST_NORMAL wxIMAGE_LIST_SMALL];
use Wx::Event qw[EVT_WINDOW_CREATE];
use base qw(Wx::ListCtrl);
use strict;
#enable gettext support
use Wx::Locale gettext => '_T';

sub new {
    my( $self, $parent, $id, $pos, $size, $style, $validator, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $validator= wxDefaultValidator unless defined $validator;
    $name   = "ActionsList"      unless defined $name;

    Wx::InitAllImageHandlers();

    $style = wxLC_REPORT|wxSUNKEN_BORDER;
        #unless defined $style;

    $self = $self->SUPER::new($parent, $id, $pos, $size, $style );
    $self->{hasCreated}=0;

    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );

    return $self;

}
sub OnCreate{
    my $self=shift;
    return if $self->{hasCreated};
    my $modtree=Wx::Window::FindWindowByName('tree_modules');
    my $images=_uGetImageData;

    $self->SetImageList($images->imageList(),wxIMAGE_LIST_NORMAL);

#    $self->InsertColumn( 0, _T('Module'));
#    $self->InsertColumn( 1, _T('Action') );


    $self->{lastItem}=0;
    $self->{hasCreated}=1;
}
sub ClearList{
    my $self=shift;
    print "Clearing ".$self->GetItemCount." items\n";
    $self->DeleteAllItems();
    $self->InsertColumn( 0, _T('Module'));
    $self->InsertColumn( 1, _T('Action') );
    $self->{lastItem}=0;

}

#check to make sure we have the correct columns
sub _check_columns{
    my $self=shift;
    if ($self->GetColumnCount!=2){
        $self->DeleteColumn(0) while($self->GetColumnCount);
        $self->InsertColumn( 0, _T('Module'));
        $self->InsertColumn( 1, _T('Action') );
    }
}
#Add an action to the list
#TODO make icons work
sub AddAction{
    my ($self,$modName,$version,$action)=@_;
    $version=$version||0.0;
    my $modtree=Wx::Window::FindWindowByName('tree_modules');
    my $mod=$modtree->_get_mod($modName,$version);
    return 0 unless $mod;

    $self->_check_columns(); #make sure we have the necessary columns

    #do nothing if we have a more updated version installed
    return 1 if ($version!=0.0 && $mod->installed_version > $version);

    #insert the item
    my $itemname="$modName-$version";
    my $icon=$modtree->_get_status_icon($itemname);
    my $idx=$self->InsertStringItem( 0, $itemname);
    $self->SetItem( $idx, 1, $action );
    $self->SetColumnWidth($_,wxLIST_AUTOSIZE) foreach(0...($self->GetColumnCount()-1));
    $self->{lastItem}++;
    return 1;
}
sub AddActionWithPre{
    my ($self,$modName,$version,$action)=@_;

    my $modtree=Wx::Window::FindWindowByName('tree_modules');
    $self->AddAction($modName,$version,$action);
    print "Added action\n";

    if (lc($action) eq lc(_T('Install')) || lc($action) eq lc(_T('Update'))){
        print "$action with prereqs\n";
        my @prereqs=$modtree->CheckPrerequisites($modName);
        #print Dumper @prereqs;
        foreach my $preName (@prereqs){
            my $mod=$modtree->_get_mod($preName);                #get the module
            my $type=_T("Install");                                #set type to install
            $type=_T("Update") if ($mod->installed_version);    #set type to update if already installed
            $self->AddAction($preName,$version,$type);            #add the action
        }
    }

}
1;
