package CPANPLUS::Shell::Wx::ModulePanel;
use Wx qw[:everything];
use base qw(Wx::Panel);
use Wx::Event qw(EVT_CONTEXT_MENU EVT_WINDOW_CREATE EVT_BUTTON
        EVT_TREE_SEL_CHANGED EVT_TREE_ITEM_ACTIVATED EVT_RIGHT_DOWN
        EVT_TREE_ITEM_RIGHT_CLICK);
use Wx::ArtProvider qw/:artid :clientid/;

#since we want to route calls from here to the module tree,
our $AUTOLOAD;

use Data::Dumper;
use YAML qw/LoadFile Load/;
#use File::Spec;
#use File::Path;
use Storable;

use threads;
use LWP::Simple;
use Wx::Locale gettext => '_T';

use CPANPLUS::Shell::Wx::util;

sub new{
    my( $self, $parent, $id, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;
    $style  = wxTAB_TRAVERSAL    unless defined $style;

    $self = $self->SUPER::new( $parent, $id, $pos, $size, $style, $name );
    print "New ModulePanel\n";
    return $self;
}

#initialize all the children. This was the OnWindowCreate Handler
sub Init {
    my $self = shift;

    #get references so we can access them easier
    $self->{parent}=$self->GetParent();        #Wx::Window::FindWindowByName('main_window');
    $self->{mod_tree}=Wx::Window::FindWindowByName('tree_modules');
    $self->{mod_tree}->Init();
    #show info on what we are doing
    Wx::LogMessage _T("Showing "),$self->{'show'},_T(" by "),$self->{'sort'};

    #populate tree with default values
    #$self->{mod_tree}->Populate();

    #print Dumper $self->{mod_tree};
    #for testing purposes, insert test values
    my @testMods=qw/Alter CPAN Cache::BerkeleyDB CPANPLUS Module::NoExist Muck Acme::Time::Baby Wx/;
        foreach $item (sort(@testMods)){
            $self->{mod_tree}->AppendItem($self->{mod_tree}->GetRootItem(),$item,$self->{mod_tree}->_get_status_icon($item));
        }

    $self->_setup_search();
    $self->_setup_info_tabs();

    #my $cMenu=$self->{mod_tree}->GetContextMenu();
#    $self->{mod_tree}->SetCPP(\&HandleContextInfo);
    $self->{mod_tree}->SetInfoHandler(\&HandleContextInfo);
    $self->{mod_tree}->SetClickHandler( sub{$self->HandleTreeClick(@_)});
    #$self->{mod_tree}->SetDblClickHandler( sub{$self->ShowPODReader(@_)});

    _uShowErr;
}
#set up the search bar.
sub _setup_search{
    $self=shift;
    my $searchbox=Wx::Window::FindWindowByName('cb_main_search');
    my $typebox=Wx::Window::FindWindowByName('cb_search_type');
    EVT_TEXT_ENTER( $self,
        Wx::XmlResource::GetXRCID('cb_main_search'),
        sub{$self->{list}->search($typebox->GetValue,$searchbox->GetValue);} );

    my @items=();

    foreach $term (CPANPLUS::Module->accessors()){
        $term=~s/^\_//;
        push(@items,$term) unless grep(/$term/,@items) ;
    }
    foreach $term (CPANPLUS::Module::Author->accessors()){
        $term=~s/^\_//;
        push(@items,$term) unless grep(/$term/,@items) ;
    }
    $typebox->Append(ucfirst($_)) foreach (sort(@items));
    #$typebox->SetValue(0);
}


sub _setup_info_tabs{
    $self=shift;
    #attach menu events
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_more_info'),sub{$self->_get_more_info()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_readme'),sub{$self->_info_get_readme()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_status'),sub{$self->_info_get_status()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_prereqs'),sub{$self->_info_get_prereqs()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_files'),sub{$self->_info_get_files()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_versions'),sub{$self->_info_get_versions()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_contents'),sub{$self->_info_get_contents()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_report_this'),sub{$self->_info_get_report_this()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_report_all'),sub{$self->_info_get_report_all()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_get_validate'),sub{$self->_info_get_validate()} );

    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_fetch'),sub{$self->{mod_tree}->_fetch_module()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_extract'),sub{$self->{mod_tree}->_extract_module()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_prepare'),sub{$self->{mod_tree}->_prepare_module()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_create'),sub{$self->{mod_tree}->_create_module()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_test'),sub{$self->{mod_tree}->_test_module()} );
    EVT_BUTTON( $self, Wx::XmlResource::GetXRCID('info_install'),sub{$self->{mod_tree}->_install_module()} );

}
#update only info tab in the lower notebook and clear other items
sub HandleTreeClick{
    my ($self,$tree,$event)=@_;

    #set global variable for CPANPLUS::Module object of what the user selected
    $self->{thisName}=$tree->GetName;
    $self->{thisMod}=$self->_get_mod($self->{thisName});

    #reset all info in Info pane
    $self->_info_reset();

    #return if we can't get an object reference
    return unless $self->{thisMod};

    #display info
    $self->_info_get_info();
}


# Here, we reroute the calls to ModuleTree
sub AUTOLOAD{
    my $self=shift;
    my @ops=@_;
    my $type = ref($self) or return undef;
    my $func=$AUTOLOAD;
    #print "$func (".ref($func).") not found in ModulePanel. Trying ModuleTree...\n";
    $func =~ s/.*:://;
    if ($self->{mod_tree}->can($func)){
        @ops=map( ((defined($_))?$_:'undef'),@ops); #make sure undefs are kept undef
        return $self->{mod_tree}->$func(@ops);
    }elsif ($self->{mod_tree}->{$func}){
        return $self->{mod_tree}->{$func};
    }else{
        Wx::LogError("$func does not exist!");
    }

}

sub HandleContextInfo{
    my ($self,$menu,$cmd_event,$modName)=@_;
    my $modtree=Wx::Window::FindWindowByName('tree_modules');

    $modtree->_get_more_info($self->{cpan}->parse_tree(module=>$modName));
}

#accessors (should be obvious)
sub SetStatusBar{$_[0]->{statusBar}=$_[1];$_[0]->{mod_tree}->SetStatusBar($_[1]);}        #any widget that has SetStatusText($txt) method
sub GetStatusBar{return $_->{statusbar};}
sub SetPODReader{$_[0]->{PODReader}=$_[1];}        #must be a CPANPLUS::Shell::Wx::PODReader
sub GetPODReader{return $_->{PODReader};}
sub SetImageList{                                #must be a Wx::ImageList
    my ($self,$imgList)=@_;
    $self->{imageList}=$imgList;
    $self->{mod_tree}->SetImageList($imgList);
    print "Assigning imagelist....".$imgList->imageList."\n";
    Wx::Window::FindWindowByName('info_prereqs')->AssignImageList($imgList->imageList);
}
sub GetImageList{return $_->{imageList};}
sub SetModuleTree{$_[0]->{mod_tree}=$_[1];}        #must be a CPANPLUS::Shell::Wx::ModuleTree
sub GetModuleTree{return $_->{mod_tree};}
sub SetCPP{                                        #must be a CPANPLUS::Backend
    my $self=shift;
    my $cpp=shift;
    $self->{cpan}=$cpp;
    $self->{config}=$cpp->configure_object;
    $self->{mod_tree}->{cpan}=$cpp if $self->{mod_tree};
    $self->{mod_tree}->{config}=$cpp->configure_object if $self->{mod_tree};
}
sub GetCPP{return $_[0]->{cpan};}
sub SetConfig{$_[0]->{config}=$_[1];}            #must be a CPANPLUS::Backend::Configure
sub GetConfig{return $_[0]->{config};}
#sub _get_mod{shift->{mod_tree}->_get_mod(@_)}
#sub _get_modname{shift->{mod_tree}->_get_modname(@_)}
#sub SetDblClickHandler{$_[0]->{mod_tree}->SetDblClickHandler($_[1]);}

##################################
##### Moved from ModuleTree #####
##################################

#get prereqs and fills in Prereqs tab
sub _info_get_prereqs{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    my $version=shift||'';

    return unless $mod;
    #set up variables for retrieving and setting data
    $self->{thisPrereq}=[];

    #get correct control and clear all items
    my $preTree=Wx::Window::FindWindowByName('info_prereqs');
    $preTree->DeleteAllItems();
    my $root=$preTree->AddRoot('prereqs');

    #append all prerequisites to root item
    $self->{mod_tree}->_append_prereq($self->_get_mod($mod,$version),$preTree,$root);

    #show any CPANPLUS errors in Log tab
    _uShowErr;
}

#clears all info fields. Optionally takes a tab name to clear only that tab's fields.
sub _info_reset{
    my $self=shift;
    my $context=shift;

    Wx::Window::FindWindowByName('info_tab_text')->SetValue('') unless $self->{thisName};
    Wx::Window::FindWindowByName('info_tab_text')->SetValue($self->{thisName}._T(" may not exist!")) if (!$context || $context eq 'info');
    Wx::Window::FindWindowByName('info_report')->DeleteAllItems() if (!$context || $context eq 'report');
    Wx::Window::FindWindowByName('info_prereqs')->DeleteAllItems() if (!$context || $context eq 'prereqs');
    Wx::Window::FindWindowByName('info_validate')->Clear() if (!$context || $context eq 'validate');
    Wx::Window::FindWindowByName('info_files')->Clear() if (!$context || $context eq 'files');
    Wx::Window::FindWindowByName('info_contents')->Clear() if (!$context || $context eq 'contents');
    Wx::Window::FindWindowByName('info_readme')->Clear() if (!$context || $context eq 'readme');
    Wx::Window::FindWindowByName('info_distributions')->Clear() if (!$context || $context eq 'readme');
    if (!$context || $context eq 'status'){
        Wx::Window::FindWindowByName('info_status_installed')->SetValue(0);
        Wx::Window::FindWindowByName('info_status_uninstall')->SetValue(0);
        Wx::Window::FindWindowByName('info_status_fetch')->SetValue('');
        Wx::Window::FindWindowByName('info_status_signature')->SetValue(0);
        Wx::Window::FindWindowByName('info_status_extract')->SetValue('');
        Wx::Window::FindWindowByName('info_status_created')->SetValue(0);
        Wx::Window::FindWindowByName('info_status_installer_type')->SetValue('');
        Wx::Window::FindWindowByName('info_status_checksums')->SetValue('');
        Wx::Window::FindWindowByName('info_status_checksum_value')->SetValue('');
        Wx::Window::FindWindowByName('info_status_checksum_ok')->SetValue(0);
    }
}

sub _get_more_info{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;

    $self->{statusBar}->SetStatusText(_T("Getting Status for ").$mod->name."...");

    $progress=Wx::ProgressDialog->new(_T("Getting Extended Info..."),
                _T("Updating List of Files..."),
                8,$self,wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME
                );
    $self->_info_get_versions($mod) if $progress->Update(4,_T("Getting Version Information..."));
    $self->_info_get_files($mod)  if $progress->Update(0);
    $self->_info_get_readme($mod) if $progress->Update(1,_T("Getting README..."));
    $self->_info_get_status($mod) if $progress->Update(2,_T("Getting Status for ").$self->{thisName}."...");
    $self->_info_get_prereqs($mod) if $progress->Update(3,_T("Getting Prerequisites for ").$self->{thisName}."...");
    $self->_info_get_contents($mod) if $progress->Update(5,_T("Getting Contents..."));
    $self->_info_get_report_all($mod) if $progress->Update(6,_T("Getting Reports..."));
    $self->_info_get_validate($mod) if $progress->Update(7,_T("Validating Module..."));

    $self->{statusBar}->SetStatusText('');
    $progress->Destroy();
    _uShowErr;

}

sub _info_get_files{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;

    $self->{statusBar}->SetStatusText(_T("Getting File Info..."));
    my $info_files=Wx::Window::FindWindowByName('info_files');
    $info_files->Clear();

    my @files=$mod->files();
    my $text=$mod->name._T(" has ").(@files || _T('NO'))._T(" installed files:\n");
    foreach $file (@files){
        $text.="$file\n";
    }
    $text.=_T("There was a problem retrieving the file information for this module.\n").
        ("Please see the log for more info.\n") unless @files;
    $info_files->AppendText($text);
    _uShowErr;
}
sub _info_get_info{
    my $self=shift;
    my $mod=shift||$self->{mod_tree}->GetMod();
    #return unless $mod;

    my $info_ctrl=Wx::Window::FindWindowByName('info_tab_text');
    $info_ctrl->Clear();
    $self->{statusBar}->SetStatusText(_T("Getting Info for ").$mod->name."...");

    my $status_info_text='';
    #update info panel
    unless ($mod){
        $info_ctrl->AppendText(_T("No Information Found!"));
    }else{
        my $info=$mod->details();
         $status_info_text.=_T("\tAuthor\t\t\t\t").$info->{'Author'}."\n" if $info->{'Author'};
         $status_info_text.=_T("\tDescription\t\t\t").$info->{'Description'}."\n" if $info->{'Description'};
         $status_info_text.=_T("\tIs Perl Core?\t\t\t").($mod->package_is_perl_core()?_T('Yes'):_T('No'))."\n";
         $status_info_text.=_T("\tDevelopment Stage\t").$info->{'Development Stage'}."\n" if $info->{'Development Stage'};
         $status_info_text.=_T("\tInstalled File\t\t\t").$info->{'Installed File'}."\n" if $info->{'Installed File'};
         $status_info_text.=_T("\tInterface Style\t\t").$info->{'Interface Style'}."\n" if $info->{'Interface Style'};
          $status_info_text.=_T("\tLanguage Used\t\t").$info->{'Language Used'}."\n" if $info->{'Language Used'};
         $status_info_text.=_T("\tPackage\t\t\t\t").$info->{'Package'}."\n" if $info->{'Package'};
         $status_info_text.=_T("\tPublic License\t\t").$info->{'Public License'}."\n" if $info->{'Public License'};
         $status_info_text.=_T("\tSupport Level\t\t").$info->{'Support Level'}."\n" if $info->{'Support Level'};
         $status_info_text.=_T("\tVersion Installed\t\t").$info->{'Version Installed'}."\n" if $info->{'Version Installed'};
         $status_info_text.=_T("\tVersion on CPAN\t\t").$info->{'Version on CPAN'}."\n" if $info->{'Version on CPAN'};
        $status_info_text.=_T("\tComment\t\t\t").($mod->comment || 'N/A')."\n";
        $status_info_text.=_T("\tPath On Mirror\t\t").($mod->path || 'N/A')."\n";
        $status_info_text.=_T("\tdslip\t\t\t\t").($mod->dslip || 'N/A')."\n";
        $status_info_text.=_T("\tIs Bundle?\t\t\t").($mod->is_bundle()?_T('Yes'):_T('No'))."\n";
        #third-party information
        $status_info_text.=_T("\tThird-Party?\t\t\t").($mod->is_third_party()?_T('Yes'):_T('No'))."\n";
        if ($mod->is_third_party()) {
            my $info = $self->{cpan}->module_information($mod->name);
            $status_info_text.=
                  _T("\t\tIncluded In\t\t").$info->{name}."\n".
                  _T("\t\tModule URI\t").$info->{url}."\n".
                  _T("\t\tAuthor\t\t\t").$info->{author}."\n".
                  _T("\t\tAuthor URI\t").$info->{author_url}."\n";
        }
        $info_ctrl->AppendText($status_info_text);
        $info_ctrl->ShowPosition(0);
    }
    $self->{statusBar}->SetStatusText('');
    _uShowErr;


}
sub _info_get_versions{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;

    $self->{statusBar}->SetStatusText(_T("Getting Version Info for ").$mod->name."...");
    my $versionList=Wx::Window::FindWindowByName('info_distributions');
    $versionList->Clear();

    my @versions=();
    foreach $m ($mod->distributions()){
        my $v=($m->version || 0.0) if $m;
        push(@versions,$v) unless (grep(/$v/,@versions));
    }
    @versions=sort(@versions);
    my $numInList=@versions;
    $versionList->Append($_) foreach (@versions);
    $versionList->SetValue($versions[-1]);
    #$versionList->SetFirstItem($numInList);

    _uShowErr;
}

#get installer status info
#TODO Make this work! Store status info after build into file
#Update the status tab
sub _info_get_status{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    Wx::LogMessage _T("Getting status for ").$mod->name."...";

    #get status from module
    my $status=$mod->status();

    #if we haven't retrieved the file and the stored info exists
    #then use the stored values
    my $statFile=_uGetPath($self->{config},'cpp_stat_file');
    if (!defined($status->fetch) && -e $statFile && (my $Allstatus=retrieve($statFile)) ){
        $thisStat=$Allstatus->{$mod->name};
        $status=$thisStat if $Allstatus->{$mod->name};
    }
    #print Dumper $status;
    Wx::Window::FindWindowByName('info_status_installed')->SetValue($status->installed || 0);
    Wx::Window::FindWindowByName('info_status_uninstall')->SetValue($status->uninstall || 0);
    Wx::Window::FindWindowByName('info_status_fetch')->SetValue($status->fetch||'n/a');
    Wx::Window::FindWindowByName('info_status_signature')->SetValue($status->signature||0);
    Wx::Window::FindWindowByName('info_status_extract')->SetValue($status->extract||'n/a');
    Wx::Window::FindWindowByName('info_status_created')->SetValue($status->created||0);
    Wx::Window::FindWindowByName('info_status_installer_type')->SetValue($status->installer_type||'n/a');
    Wx::Window::FindWindowByName('info_status_checksums')->SetValue($status->checksums || 'n/a');
    Wx::Window::FindWindowByName('info_status_checksum_value')->SetValue($status->checksum_value||'n/a');
    Wx::Window::FindWindowByName('info_status_checksum_ok')->SetValue($status->checksum_ok || 0);
    _uShowErr;

}

#get the readme file
sub _info_get_readme{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    my $info_readme=Wx::Window::FindWindowByName('info_readme');
    $info_readme->Clear();
    $info_readme->AppendText(($mod->readme || 'No README Found! Check Log for more information.'));
    $info_readme->ShowPosition(0);
    _uShowErr;
}

sub _info_get_contents{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    my $info_contents=Wx::Window::FindWindowByName('info_contents');
    $info_contents->Clear();
    my $txt='';
    foreach $m (sort {lc($a->name) cmp lc($b->name)} $mod->contains() ){
        $txt.=$m->name."\n";
    }
    $info_contents->AppendText($txt);
    $info_contents->ShowPosition(0); #set visible position to beginning
    _uShowErr;
}
sub _info_get_validate{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    my $display=Wx::Window::FindWindowByName('info_validate');
    $display->Clear();
    my $txt='';
    foreach $file (sort($mod->validate) ){
        $txt.=$file."\n";
    }
    $display->AppendText( ($txt || _T("No Missing Files or No Information. See Log.")) );
    $display->ShowPosition(0); #set visible position to beginning
    _uShowErr;
}


sub _info_get_report_all{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    my $info_report=Wx::Window::FindWindowByName('info_report');
    $info_report->DeleteAllItems();

    #set up the listctrl
    unless ($info_report->GetColumnCount == 3){
        while ($info_report->GetColumnCount){
            $info_report->DeleteColumn(0);
        }
        $info_report->InsertColumn( 0, _T('Distribution'));
        $info_report->InsertColumn( 1, _T('Platform') );
        $info_report->InsertColumn( 2, _T('Grade') );
    }
    my @versions=$mod->fetch_report(all_versions => 1, verbose => 1);
    @versions=reverse(sort { lc($a->{platform}) cmp lc($b->{platform})} @versions);
#    print Dumper $versions[0];
    foreach $item (@versions ){
        $info_report->InsertStringItem( 0, $item->{'dist'} );
        $info_report->SetItem( 0, 1, $item->{'platform'} );
        $info_report->SetItem( 0, 2, $item->{'grade'} );
    }
    $info_report->SetColumnWidth(0,wxLIST_AUTOSIZE);
    $info_report->SetColumnWidth(1,wxLIST_AUTOSIZE);
    $info_report->SetColumnWidth(2,wxLIST_AUTOSIZE);
    _uShowErr;
}
sub _info_get_report_this{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    return unless $mod;
    my $info_report=Wx::Window::FindWindowByName('info_report');
    $info_report->DeleteAllItems();

    #set up the listctrl
    unless ($info_report->GetColumnCount == 3){
        while ($info_report->GetColumnCount){
            $info_report->DeleteColumn(0);
        }
        $info_report->InsertColumn( 0, _T('Distribution') );
        $info_report->InsertColumn( 1, _T('Platform') );
        $info_report->InsertColumn( 2, _T('Grade') );
    }

    my @versions=$mod->fetch_report(all_versions => 0, verbose => 1);
    @versions=reverse(sort { lc($a->{platform}) cmp lc($b->{platform})} @versions);
    foreach $item (@versions ){
        $info_report->InsertStringItem( 0, $item->{'dist'} );
        $info_report->SetItem( 0, 1, $item->{'platform'} );
        $info_report->SetItem( 0, 2, $item->{'grade'} );
    }
    $info_report->SetColumnWidth(0,wxLIST_AUTOSIZE);
    $info_report->SetColumnWidth(1,wxLIST_AUTOSIZE);
    $info_report->SetColumnWidth(2,wxLIST_AUTOSIZE);
    _uShowErr;
}

sub GetInfo{
    my ($menu,$cmd_event,$modName)=@_;
    my $modtree=$self->{mod_tree};

    $modtree->_get_more_info($modtree->_get_mod($modName));
}

1;