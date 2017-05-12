
package CPANPLUS::Shell::Wx::ModuleTree;

use Wx qw/wxPD_APP_MODAL wxPD_APP_MODAL wxPD_CAN_ABORT
        wxPD_ESTIMATED_TIME wxPD_REMAINING_TIME wxLIST_AUTOSIZE
        wxVSCROLL wxALWAYS_SHOW_SB wxUPDATE_UI_RECURSE /;
use Wx::Event qw(EVT_CONTEXT_MENU EVT_WINDOW_CREATE EVT_BUTTON
        EVT_TREE_SEL_CHANGED EVT_TREE_ITEM_ACTIVATED EVT_RIGHT_DOWN
        EVT_TREE_ITEM_RIGHT_CLICK);
use Wx::ArtProvider qw/:artid :clientid/;

use Data::Dumper;
use YAML qw/LoadFile Load/;
use File::Spec;
use File::Path;
use Storable;

use threads;
use LWP::Simple;
use Wx::Locale gettext => '_T';

use CPANPLUS::Shell::Wx::util;

#the base class
use base 'Wx::TreeCtrl';

BEGIN {
    use vars qw( @ISA $VERSION);
    @ISA     = qw( Wx::TreeCtrl);
    $VERSION = '0.01';
}

#use some constants to better identify what's going on,
#so we can do stuff like:
#     $self->{'sort'}=(SORTBY)[CATEGORY]; #sort by category

use constant SORTBY => (_T("Author"), _T("Name"), _T("Category"));
use constant {AUTHOR=>0,NAME=>1,CATEGORY=>2};
use constant SHOW => (_T("Installed"),_T("Updated"),_T("New"),_T("All"))   ;
use constant {INSTALLED=>0,UPDATES=>1,NEW=>2,ALL=>3};
use constant MAX_PROGRESS_VALUE => 100000; #the max value of the progressdialogs


sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' TreeCtrl object

    #set default behavior
    $self->{'sort'}=(SORTBY)[CATEGORY]; #DEFAULT: sort by category
#    $self->{'sort'}=(SORTBY)[AUTHOR];   #sort by author
#    $self->{'sort'}=(SORTBY)[NAME];   #sort by module name
    $self->{'show'}=(SHOW)[INSTALLED];
#    $self->{'show'}=(SHOW)[UPDATES];  #DEFAULT: List Updated Modules
#    $self->{'show'}=(SHOW)[NEW];
#    $self->{'show'}=(SHOW)[ALL];

    #this is the thread reference to the info gathering method
    #this is started ad stopped when the listbox's selection is changed
    #threads may be removed in the future or not used at all.
    $self->{_threads}=();

    #setup category names for further use.
    #(they will be used to create hashes)
    $self->{catNames}=[
        _T("Not In Modulelist"),                        _T("Perl Core Modules"),
        _T("Language Extensions"),                        _T("Development Support"),
        _T("Operating System Interfaces"),                _T("Networking Devices, IPC"),
        _T("Data Type Utilities"),                         _T("Database Interfaces"),
        _T("User Interfaces"),                            _T("Language Interfaces"),
        _T("File Names, Systems Locking"),                 _T("String/Language/Text Processing"),
        _T("Options/Arguments/Parameters Processing"),    _T("Internationalization, Locale"),
        _T("Security and Encryption"),                    _T("World Wide Web, HTML, HTTP, CGI"),
        _T("Server and Daemon Utilities"),                _T("Archiving and Compression"),
        _T("Images, Pixmaps, Bitmaps"),                    _T("Mail and Usenet News"),
        _T("Control Flow Utilities"),                    _T("File Handle Input/Output"),
        _T("Microsoft Windows Modules"),                _T("Miscellaneous Modules"),
        _T("Commercial Software Interfaces"),            _T("Bundles"),
        _T("Documentation"),                            _T("Pragma"),
        _T("Perl6")];

    #add the root item.It is hidden.
    $self->AddRoot(_T('Modules'));

    #create links to events
#    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );            #when the tree is created
    EVT_TREE_SEL_CHANGED( $self, $self, \&OnSelChanged);    #when a user changes the selection
    EVT_TREE_ITEM_ACTIVATED($self, $self, \&OnDblClick);    #When the user double-clicks an item
    EVT_TREE_ITEM_RIGHT_CLICK( $self, $self, \&ShowPopupMenu );#when the user wants a pop-up menu
    $self->SetWindowStyleFlag($self->GetWindowStyleFlag()|wxVSCROLL);

    return $self;
}

#this is called when the control is created.
#sub OnCreate {
sub Init {
    my $self = shift;
    my ($event)=@_;

    #get references so we can access them easier
#    $self->{parent}=Wx::Window::FindWindowByName('main_window');
#    $self->{parent}=$self->GetParent();
#    $self->{cpan}=$self->{parent}->{cpan};
#    $self->{config}=$self->{cpan}->configure_object();

    #$self->AssignImageList($imgList);

#    Wx::Window::FindWindowByName('info_prereqs')->AssignImageList($imgList);
    #show info on what we are doing
    Wx::LogMessage _T("Showing "),$self->{'show'},_T(" by "),$self->{'sort'};

    #go ahead and get the list of categories
    $self->{category_list}=$self->_get_categories();

    #$self->{statusBar}=Wx::Window::FindWindowByName('main_window_status');

    #populate tree with default values
    #$self->Populate();

    #$self->{podReader}=$self->{parent}->{podReader} || CPANPLUS::Shell::Wx::PODReader::Frame->new($self);

    $self->SetWindowStyle($self->GetWindowStyleFlag()|wxVSCROLL|wxALWAYS_SHOW_SB);
    _uShowErr;
}

###############################
####### PUBLIC METHODS ########
###############################
#these methods are called from outside to display the relevant modules
sub ShowInstalled{shift->_switch_show(INSTALLED)}
sub ShowUpdated{shift->_switch_show(UPDATES)}
sub ShowNew{shift->_switch_show(NEW)}
sub ShowAll{shift->_switch_show(ALL)}
sub SortByAuthor{shift->_switch_sort(AUTHOR)}
sub SortByName{shift->_switch_sort(NAME)}
sub SortByCategory{shift->_switch_sort(CATEGORY)}

#the following methods are for setting the event handlers for the various
# menu items in the context menu. They all take one parameter:a code ref
#The code ref is then executed with three parameters:
# the menu [Wx::Menu], the event [Wx::CommandEvent], and the name of the selected module
sub SetInfoHandler{$_[0]->{_minfoHandler}=$_[1];}
sub SetInstallMenuHandler{print "Install: ",@_;$_[0]->{_minstallHandler}=$_[1];}
sub SetUpdateMenuHandler{$_[0]->{_mupdateHandler}=$_[1];}
sub SetUninstallMenuHandler{$_[0]->{_muninstallHandler}=$_[1];}
sub SetFetchMenuHandler{$_[0]->{_mfetchHandler}=$_[1];}
sub SetPrepareMenuHandler{$_[0]->{_mprepareHandler}=$_[1];}
sub SetBuildMenuHandler{$_[0]->{_mbuildHandler}=$_[1];}
sub SetTestMenuHandler{$_[0]->{_mtestHandler}=$_[1];}
sub SetExtractMenuHandler{$_[0]->{_mextractHandler}=$_[1];}
sub SetClickHandler{$_[0]->{_clickHandler}=$_[1];}
sub SetDblClickHandler{print "DblClick:",@_,"\n";$_[0]->{_dblClickHandler}=$_[1];}
sub SetStatusBar{$_[0]->{statusBar}=$_[1];}
sub SetMenu{$_[0]->{menu}=$_[1];}
sub GetName{return $_[0]->{thisName}}
sub GetMod{return $_[0]->{thisMod}}
sub SetCPP{$_[0]->{cpan}=$_[1];$_[0]->{config}=$_[1]->configure_object();}

#this is called when the user right-clicks on an item in the tree
sub ShowPopupMenu{
    my $self = shift;
    my ($event)=@_;

    #we can't do any actions on unknown modules
    return if $self->GetItemImage($event->GetItem()) == 4;
    #create the menu
    $menu = CPANPLUS::Shell::Wx::ModuleTree::Menu->new($self,$event->GetItem());
    #show the menu
    $self->PopupMenu($menu,$event->GetPoint());
}


#this is called when the user double-clicks on an item in the tree
sub OnDblClick{
    my $self = shift;
    my ($event)=@_;
    #we can't do any actions on unknown modules
    my $img=$self->GetItemImage($event->GetItem());
    print "Double Click!:".$self->{_dblClickHandler}." img = $img\n";
    return if $img == 4;
    &{$self->{_dblClickHandler}}(@_) if $self->{_dblClickHandler};
}
#this method calls the other methods to populate the tree
sub Populate{
    my $self = shift;

    $self->OnSelChanged();        #clear all values in Info pane
    $self->DeleteAllItems();    #clear all items in tree

    #add the root item with the name of what we are showing
    my $root=$self->AddRoot($self->{'show'});

    #tell the user we are populating the list
    $self->{statusBar}->SetStatusText(_T("Populating List..").$self->{'show'}._T(" By ").$self->{'sort'});

    #call the appropriate method for displaying the modules
    if ($self->{'sort'} eq (SORTBY)[AUTHOR]){
        $self->_show_installed_by_author() if ( $self->{'show'} eq (SHOW)[INSTALLED]);
        $self->_show_updates_by_author() if ( $self->{'show'} eq (SHOW)[UPDATES]);
        $self->_show_new_by_author() if ( $self->{'show'} eq (SHOW)[NEW]);
        $self->_show_all_by_author() if ( $self->{'show'} eq (SHOW)[ALL]);
    }
    if ($self->{'sort'} eq (SORTBY)[NAME]){
        $self->_show_installed_by_name() if ( $self->{'show'} eq (SHOW)[INSTALLED]);
        $self->_show_updates_by_name() if ( $self->{'show'} eq (SHOW)[UPDATES]);
        $self->_show_new_by_name() if ( $self->{'show'} eq (SHOW)[NEW]);
        $self->_show_all_by_name() if ( $self->{'show'} eq (SHOW)[ALL]);
    }
    if ($self->{'sort'} eq (SORTBY)[CATEGORY]){
        $self->_show_installed_by_category() if ( $self->{'show'} eq (SHOW)[INSTALLED]);
        $self->_show_updates_by_category() if ( $self->{'show'} eq (SHOW)[UPDATES]);
        $self->_show_new_by_category() if ( $self->{'show'} eq (SHOW)[NEW]);
        $self->_show_all_by_category() if ( $self->{'show'} eq (SHOW)[ALL]);
    }

    #show any errors generated by CPANPLUS
    _uShowErr;
}

#update only info tab in the lower notebook and clear other items
sub OnSelChanged{
    my ($self,$event)=@_;

    #set global variable for name of what the user selected
    $self->{thisName}=$self->GetItemText($self->GetSelection());
    #set global variable for CPANPLUS::Module object of what the user selected
    $self->{thisMod}=$self->_get_mod($self->{thisName});
    #return if we can't get an object reference
    return unless $self->{thisMod};
    &{$self->{_clickHandler}}($self,$event) if $self->{_clickHandler};
}

#this method check to see which prerequisites have not been met
# We only want recursion when a prereq is NOT installed.
#returns a list of prerequisites, in reverse install order
# i.e. $list[-1] needs to be installed first
sub CheckPrerequisites{
    my $self=shift;
    my $modName=shift;
    my $version=shift||'';
    my $pre=$self->GetPrereqs($modName,$version);
#    print Dumper $pre;
#    return;
    my @updates=();
    foreach $name (@$pre){
        my $mod=$self->_get_mod($name);
        next unless $mod;
        if ($mod->installed_version && $mod->installed_version >= $mod->version){
            $self->{statusBar}->SetStatusText($mod->name." v".$mod->installed_version._T(" is sufficient."));
        }else{
            $self->{statusBar}->SetStatusText($mod->name." v".$mod->installed_version._T(" needs to be updated to ").$name);
            push (@updates,$name);
            push (@updates,$self->CheckPrerequisites($name));
        }
    }
    $self->{statusBar}->SetStatusText('');
    return @updates;
}

#this method fetches the META.yml file from
#search.cpan.org and parses it using YAML.
#It returns the Prerequisites for the given module name
# or the currently selected module, if none given.
# It stores the yml data in the same hierarchy as CPANPLUS
#stores its readme files and other data.
#returns: a list of modules that can be parsed by parse_module()
sub GetPrereqs{
    my $self=shift;
    my $modName=shift || $self->{thisName};
    my $version=shift||'';
#    print "GetPrereqs($modName) \n ";
    my $mod=$self->_get_mod($modName,$version);
#    print $modName.(($version)?"-$version":'')."\n";
#    print Dumper $mod;
    return unless $mod; #if we can't get a module from the name, return

    #set up the directory structure fro storing the yml file
    my $storedDir=_uGetPath($self->{config},'cpp_mod_dir'); #the top-level directory for storing files
    my $author=$mod->author->cpanid; #get the cpanid of the author
    my @split=split('',$author); #split the author into an array so we can:
    my $dest=File::Spec->catdir($storedDir,$split[0],$split[0].$split[1],$author); #extract the first letters
    my $package=$mod->package_name.'-'.$mod->package_version; #name the file appropriately
    $dest=File::Spec->catfile($dest,"$package.yml");
    my $src="http://search.cpan.org/src/$author/$package/META.yml"; #where we are getting the file from

    my $ymldata=''; #the yaml data
    #if we already have this file, read it. Otherwise, get it from web
    if (-e $dest){
        $ymldata=LoadFile($dest);
    }else{
        mkpath($dest,0,0775) unless (-d $dest);        #create the path
        my $yml=getstore($src,$dest) ;                #get and store the yaml file
        $yml=get($src);                                #get the file. TODO add test for existence of yaml file
        $ymldata=Load($yml);                        #load the data
    }

    #return the prequisites
    my $reqs=$ymldata->{'requires'}||{};
    my @ret=();
    foreach $modName (keys(%$reqs)){
        $name=$self->_get_modname($modName,$reqs->{$modName});
#        print "$name-".$reqs->{$key}."\n";
        push(@ret,"$name");
    }

    return \@ret;
}

#appends prequisites the given tree.
#parameters:
#    $module_name, $treeCtrl, $parentNodeInTree = $treeCtrl->GetRootItem
sub _append_prereq{
    my $self=shift;
    my $modName=shift;
    my $preTree=shift||$self;
    my $parentNode=shift || $preTree->GetRootItem();

#    print "_append_prereq($modName)\n";

    my $pre=$self->GetPrereqs($modName);
    #print Dumper $pre;
    foreach $mod (@$pre){
        push (@{$self->{thisPrereq}},$mod) unless ( grep($mod,@{$self->{thisPrereq}}) );
        my $icon=$self->_get_status_icon($mod);
        #print "$mod icon: $icon\n";
        my $pNode=$preTree->AppendItem($parentNode,$mod,$icon);
        $self->_append_prereq($mod,$preTree,$pNode);
    }
}

#this method returns a module for the given name.
# it is OK to pass an existing module ref, as it will
# simply return the ref. You can use this to validate
# all modules and names. You can pass an optional
# boolean denoting whether you would like to return the name
# so parse_module can understand it.
sub _get_modname{
    my ($self,$mod,$version)=@_;
    $version=$version?"-".$version:''; #the version we want

    if (ref($mod) && ($mod->isa('CPANPLUS::Module') or $mod->isa('CPANPLUS::Module::Fake'))){
        if ($version){
            my $name=$mod->name;
            $name =~ s/::/-/g;                                    #parse out the colons in the name
            $mod=$self->{cpan}->parse_module(module=>$name.$version );
        }
            return $mod->package_name;
    }
    $mod =~ s/::/-/g;                                    #parse out the colons in the name
    $mod=$self->{cpan}->parse_module(module=>$mod.$version); #get the module
    return $mod->package_name if $mod;    #return the name if we want to
    return '';
}

sub _get_mod{
    my ($self,$mod,$version)=@_;

    $version=$version?"-".$version:''; #add dash so parse_module can understand

#    print "_get_mod($name,$version,$onlyName)\n";
    #if a module ref is passed, return the ref or the package_name
    if (ref($mod) && ($mod->isa('CPANPLUS::Module') or $mod->isa('CPANPLUS::Module::Fake'))){
        #get new module for $version
        if ($version){
            my $modname=$mod->name;
            $modname =~ s/::/-/g;                                    #parse out the colons in the name
            $mod=$self->{cpan}->parse_module(module=>$modname.$version );
            #return $newMod;
        }
        return $mod;
    }
    $mod =~ s/::/-/g;                                    #parse out the colons in the name
    $mod=$self->{cpan}->parse_module(module=>$mod.$version); #get the module
    return $mod;                                        #return the module object
}
###############################
####### PRIVATE METHODS #######
###############################
#switch the type to show and populate list
#NOTE: These 2 methods are put here to eliminate repetative code
sub _switch_show{
    my ($self,$type) = @_;
    $self->{'show'}=(SHOW)[$type];
    Wx::LogMessage _T("Showing ").$self->{'show'}._T(" Modules");
    $self->Populate();
    _uShowErr;
}
sub _switch_sort{
    my ($self,$type) = @_;
    $self->{'sort'}=(SORTBY)[$type];
    Wx::LogMessage _T("Sorting by ").$self->{'sort'};
    $self->Populate();
    _uShowErr;
}





###############################
######## Module Actions #######
###############################
sub _install_module{
    my $self=shift;
    my $mod=shift||$self->{thisMod};
    my $version=shift||'';
    return unless $mod;

    #if no version supplied, check version list in Actions tab
    unless ($version){
        my $versionList=Wx::Window::FindWindowByName('info_distributions');
        $version=$versionList->GetValue() || '';
    }
    my $fullname=$mod->name.'-'.$version;
    $self->{statusBar}->SetStatusText(_T("Installing ").$fullname."...");

    #$mod=$self->{cpan}->parse_module(module => $mod->name.'-'.$version) if $version;
#    print Dumper $mod;
    $self->_install_with_prereqs($mod->name,$version);

    _uShowErr;
}

sub _install_with_prereqs{
    my $self=shift;
    my $modName=shift;
    return unless $modName;
    my $version=shift||'';
    my @prereqs=$self->CheckPrerequisites($modName,$version);
    #print Dumper @prereqs;
    unshift (@prereqs,$modName.($version?"-$version":''));
    my @mods=();            #$self->{cpan}->module_tree(reverse(@prereqs));
    foreach $n (reverse(@prereqs)){
        push @mods, $self->{cpan}->parse_module(module=>$n);
    }

    #print Dumper @mods;
    my $curMod;
    my $isSuccess=1;
    foreach $mod (@mods){
        $curMod=$mod;
        unless ($self->_fetch_module($mod)){$isSuccess=0;last;}
        unless ($self->_extract_module($mod)){$isSuccess=0;last;}
        unless ($self->_prepare_module($mod)){$isSuccess=0;last;}
        unless ($self->_create_module($mod)){$isSuccess=0;last;}
        unless ($self->_test_module($mod)){$isSuccess=0;last;}
        $self->{statusBar}->SetStatusText(_T('Installing ').$mod->name);
        unless ($mod->install){$isSuccess=0;last;}
        $self->{statusBar}->SetStatusText(_T('Successfully installed ').$mod->name);
    }
    #store status info and populate status tab
    $self->_store_status(@mods);
    #$self->_info_get_status();

    unless ($isSuccess){
        $self->{statusBar}->SetStatusText(_T('Failed to install ').$curMod->name._T(". Please Check Log."));
        Wx::MessageBox(_T("Failed to install ").$curMod->name._T("\nCheck Log for more information."));
        return 0;
    }

    _uShowErr;
    return 1;
}

sub _store_status{
    my $self=shift;
    my @mods=@_;
    my $status={};
    my $file=_uGetPath($self->{config},'cpp_stat_file');
    $status=retrieve($file) if (-e $file);
    foreach $mod (@mods){
        $status->{$mod->name}=$mod->status();
    }
    store $status, $file;
}
sub _fetch_module{
    my $self=shift;
    my $mod=shift || $self->{thisMod};
    $mod = $self->{cpan}->parse_module(module=>$mod) unless ($mod->isa('CPANPLUS::Module') || $mod->isa('CPANPLUS::Module::Fake'));
    return unless $mod;
    #print Dumper $mod;
    $self->{statusBar}->SetStatusText(_T('Fetching ').$mod->{'package'});
    my $path=$mod->fetch();
    return 0 unless $path;
    _uShowErr;
    return 1;
}

sub _extract_module{
    my $self=shift;
    my $mod=shift || $self->{thisMod};
    $mod = $self->{cpan}->parse_module(module=>$mod) unless ($mod->isa('CPANPLUS::Module') || $mod->isa('CPANPLUS::Module::Fake'));
    return unless $mod;
    $self->{statusBar}->SetStatusText(_T('Extracting ').$mod->name);
    my $path=$mod->extract();
    return 0 unless $path;
    _uShowErr;
    return 1;
}
sub _prepare_module{
    my $self=shift;
    my $mod=shift || $self->{thisMod};
    $mod = $self->{cpan}->parse_module(module=>$mod) unless ($mod->isa('CPANPLUS::Module') || $mod->isa('CPANPLUS::Module::Fake'));
    return unless $mod;
    $self->{statusBar}->SetStatusText(_T('Preparing ').$mod->name);
    my $path=$mod->prepare();
    return 0 unless $path;
    _uShowErr;
    return 1;
}

sub _create_module{
    my $self=shift;
    my $mod=shift || $self->{thisMod};
    $mod = $self->{cpan}->parse_module(module=>$mod) unless ($mod->isa('CPANPLUS::Module') || $mod->isa('CPANPLUS::Module::Fake'));
    return unless $mod;
    $self->{statusBar}->SetStatusText(_T('Building ').$mod->name);
    my $path=$mod->create();
    return 0 unless $path;
    _uShowErr;
    return 1;
}
sub _test_module{
    my $self=shift;
    my $mod=shift || $self->{thisMod};
    $mod = $self->{cpan}->parse_module(module=>$mod) unless ($mod->isa('CPANPLUS::Module') || $mod->isa('CPANPLUS::Module::Fake'));
    return unless $mod;
    $self->{statusBar}->SetStatusText(_T('Testing ').$mod->name);
    my $path=$mod->test();
    return 0 unless $path;
    _uShowErr;
    return 1;
}
#populates the list with the tree items
#This function takes a tree hash, and optionally a progressdialog or bar
# and the max value of the progress bar
#return 1 on success, or 0 if the user cancelled
# call like:
#$user_has_cancelled = $self->PopulateWithHash(\%tree,[$progress],[$max_pval]);
sub PopulateWithHash{
    #get parameters
    my $self=shift;
    my $tree=shift;
    my $progress=shift;
    my $max_progress=shift;

    #print "Window Height: ".$self->GetClientSize()->GetWidth." , ".$self->GetClientSize()->GetHeight."\n";

    #set defaults.
    #Use half the number of items in the hash as a total items count, if none given
    my $numFound=$tree->{'_items_in_tree_'} || %$tree/2;
    $max_progress=($numFound || 10000) unless $max_progress;

    #create a progressdialog if none specified in params
    $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("Inserting ").$numFound._T(" Items Into Tree..."),
                $numFound,$self,wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME
                ) unless $progress;

    #start timing
    $begin=time();

    #restart count if another progressdialog is passeed in
    $progress->Update(0,_T("Inserting ").$numFound._T(" Items Into Tree..."));
    my $percent=$max_progress/$numFound;
    $cnt=0;

    foreach $top_level ( sort( keys(%$tree) ) ){
        next if $top_level eq '_items_in_tree_';
        my $display=$top_level;
        my $curParent=$self->AppendItem(
            $self->GetRootItem(),
            $top_level,$self->_get_status_icon($top_level));
        foreach $item (sort(@{$tree->{$top_level}})){
            $self->AppendItem($curParent,$top_level."::".$item,$self->_get_status_icon($item)) if ($curParent && $item);
            last unless $progress->Update($cnt*$percent);
            $cnt++;
        }
    }
#	my $dummy=$self->AppendItem($self->GetRootItem(),'end');
#	my $subDummy=$self->AppendItem($dummy,'end');

#    $progress->Update($numFound+1);
    $progress->Destroy();
    my $inserted_time=time()-$begin;
    Wx::LogMessage _T("Finished Inserting in ").sprintf("%d",($inserted_time/60)).":".($inserted_time % 60)."\n";

#    print "Window Height: ".$self->GetClientSize()->GetWidth." , ".$self->GetClientSize()->GetHeight."\n";
    _uShowErr;
    return 1;
}

###############################
######## New By Name ##########
###############################
sub _show_new_by_name{
    my $self=shift;
    if ($self->{'tree_NewByName'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_NewByName'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar
    my $numFound=0;

    $progress->Update(0,_T("Step 1 of 2: Sorting All ").$total._T(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        if (!($i->is_uptodate || $i->installed_version)){
            my ($top_level)=split('::',$thisName);
            push (@{$tree{$top_level}}, ($thisName eq $top_level)?():$thisName); #add the item to the tree
            $numFound++;
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_NewByName'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    _uShowErr;
    return 1;
}
###############################
######## New By Author ########
###############################
sub _show_new_by_author{
    my $self=shift;
    if ($self->{'tree_NewByAuthor'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_NewByAuthor'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar
    $numFound=0;

    $progress->Update(0,_T("Step 1 of 2: Categorizing All ").$total._T(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        if (!($i->is_uptodate || $i->installed_version)){
            my $thisAuthor=$i->author()->cpanid." [".$i->author()->author."]";
            my $cat_num=$self->{category_list}->{$thisName};
            push (@{$tree{$thisAuthor}}, $thisName); #add the item to the tree
            $numFound++;
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_NewByAuthor'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    _uShowErr;
    return 1;
}

###############################
######## New By Category ######
###############################
sub _show_new_by_category{
    my $self=shift;
    if ($self->{'tree_NewByCategory'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_NewByCategory'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),$max_pval,$self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar
    $numFound=0;

    $progress->Update(0,_T("Step 1 of 2: Categorizing All ").$total.(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        my $cat_num=$self->{category_list}->{$thisName};
        if (defined($cat_num) && !($i->is_uptodate || $i->installed_version)){
            $cat_num=0 if ($cat_num==99); #don't use index 99, it make array too large
            $cat_num=1 if ($i->module_is_supplied_with_perl_core() && $cat_num==2);
            push (@{$tree{$self->{catNames}->[$cat_num]}}, $thisName); #add the item to the tree
            $numFound++;
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }

    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_NewByCategory'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    _uShowErr;
    return 1;
}

###############################
######## All By Name ##########
###############################
sub _show_all_by_name{
    my $self=shift;
    if ($self->{'tree_AllByName'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_AllByName'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar

    $progress->Update(0,_T("Step 1 of 2: Sorting All ").$total._T(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        my ($top_level)=split('::',$thisName);
        push (@{$tree{$top_level}}, ($thisName eq $top_level)?():$thisName); #add the item to the tree
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$total;
    $self->{'tree_AllByName'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    _uShowErr;
    return 1;
}

###############################
######## All By Author ########
###############################
sub _show_all_by_author{
    my $self=shift;
    if ($self->{'tree_AllByAuthor'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_AllByAuthor'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar

    $progress->Update(0,_T("Step 1 of 2: Categorizing All ").$total._T(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        my $thisAuthor=$i->author()->cpanid." [".$i->author()->author."]";
        my $cat_num=$self->{category_list}->{$thisName};
        push (@{$tree{$thisAuthor}}, $thisName); #add the item to the tree
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$total;
    $self->{'tree_AllByAuthor'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    _uShowErr;
    return 1;
}

###############################
###### All By Category ########
###############################
sub _show_all_by_category{
    my $self=shift;
    if ($self->{'tree_AllByCategory'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_AllByCategory'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),$max_pval,$self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

    my %allMods=%{$self->{cpan}->module_tree()}; #get all modules
    my $total=keys(%allMods);
    my $percent=$max_pval/($total||1); #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @allMods - for progressbar

    $progress->Update(0,_T("Step 1 of 2: Categorizing All ").$total._T(" Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $thisName (keys(%allMods)){
        my $i=$allMods{$thisName};
        my $cat_num=$self->{category_list}->{$thisName};
        if (defined($cat_num)){
            $cat_num=0 if ($cat_num==99); #don't use index 99, it make array too large
            $cat_num=1 if ($i->module_is_supplied_with_perl_core() && $cat_num==2);
            push (@{$tree{$self->{catNames}->[$cat_num]}}, $thisName); #add the item to the tree
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }

    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$total;
    $self->{'tree_AllByCategory'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}


sub _show_updates_by_category{
    my $self=shift;
    if ($self->{'tree_UpdatesByCategory'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_UpdatesByCategory'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),$max_pval,$self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Categorizing ").@installed._T(" Installed Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        unless ($i->is_uptodate()){
            my $thisName=$i->name;
            my $cat_num=$self->{category_list}->{$thisName};
            if (defined($cat_num)){
                $cat_num=0 if ($cat_num==99); #don't use index 99, it make array too large
                $cat_num=1 if ($i->module_is_supplied_with_perl_core() && $cat_num==2);
                push (@{$tree{$self->{catNames}->[$cat_num]}}, $thisName); #add the item to the tree
                $numFound++; #increment the number of items that matched
            }
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }

    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_UpdatesByCategory'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}

sub _show_updates_by_author{
    my $self=shift;
    if ($self->{'tree_UpdatesByAuthor'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_UpdatesByAuthor'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Sorting ").@installed." Installed Modules..."); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        unless ($i->is_uptodate()){
            my $thisName=$i->name;
            my $thisAuthor=$i->author()->cpanid." [".$i->author()->author."]";
            my $cat_num=$self->{category_list}->{$thisName};
            push (@{$tree{$thisAuthor}}, $thisName); #add the item to the tree
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_UpdatesByAuthor'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}


sub _show_updates_by_name{
    my $self=shift;
    if ($self->{'tree_UpdatesByName'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_UpdatesByName'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Sorting ").@installed." Installed Modules..."); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        unless ($i->is_uptodate()){
            my $thisName=$i->name;
            my ($top_level)=split('::',$thisName);
            push (@{$tree{$top_level}}, ($thisName eq $top_level)?():$thisName); #add the item to the tree
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_UpdatesByName'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}


sub _show_installed_by_name{
    my $self=shift;
    if ($self->{'tree_InstalledByName'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_InstalledByName'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Sorting ").@installed._T(" Installed Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        my $thisName=$i->name;
        my ($top_level)=split('::',$thisName);
        push (@{$tree{$top_level}}, ($thisName eq $top_level)?():$thisName); #add the item to the tree
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=keys(%tree); #@installed; #$numFound;
    $self->{'tree_InstalledByName'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}

#populate tree with installed modules sorted by author id
sub _show_installed_by_author{
    my $self=shift;
    if ($self->{'tree_InstalledByAuthor'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_InstalledByAuthor'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new("Setting Up List...",
                "CPANPLUS is getting information...",
                $max_pval,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Sorting ").@installed._T(" Installed Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        my $thisName=$i->name;
        my $thisAuthor=$i->author()->cpanid." [".$i->author()->author."]";
        my $cat_num=$self->{category_list}->{$thisName};
        push (@{$tree{$thisAuthor}}, $thisName); #add the item to the tree
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_InstalledByAuthor'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;
}

#populate tree with installed modules sorted by category
sub _show_installed_by_category{
    my $self=shift;
    if ($self->{'tree_InstalledByCategory'}){
        return 0 unless $self->PopulateWithHash($self->{'tree_InstalledByCategory'});
        Wx::LogMessage _T("[Done]");
        return 1;
    }
    my %tree=();
    my $max_pval=10000;  #the maximum value of the progress bar
    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                10000,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

    my @installed=$self->{cpan}->installed(); #get installed modules
    my $percent=$max_pval/@installed; #number to increment progress by
    my $begin=time(); #for timing loops
    my $cnt=0;  #the count of current index of @installed - for progressbar
    my $numFound=0; #the number of modules that match CPAN to CPANPLUS::Installed
    $progress->Update(0,_T("Step 1 of 2: Categorizing ").@installed._T(" Installed Modules...")); #start actual progress

    #search through installed modules and insert them into the correct category
    foreach $i (@installed){
        my $thisName=$i->name;
        my $cat_num=$self->{category_list}->{$thisName};
        $progress->Update($cnt*$percent);
#            "Step 1 of 2: Categorizing ".@installed." Installed Modules...#$cnt : ".$i->name);
        if (defined($cat_num)){
            $cat_num=0 if ($cat_num==99); #don't use index 99, it make array too large
            $cat_num=1 if ($i->module_is_supplied_with_perl_core() && $cat_num==2);
            push (@{$tree{$self->{catNames}->[$cat_num]}}, $thisName); #add the item to the tree
            $numFound++; #increment the number of items that matched
        }
        unless ($progress->Update($cnt*$percent)){
            $progress->Destroy();
            return 0;
        }
        $cnt++; #increment current index in @installed
    }
    #end timing method
    my $end=time();
    Wx::LogMessage _T("Finished Sorting in ").sprintf("%d",(($end-$begin)/60)).":".(($end-$begin) % 60)."\n";

    #store tree for later use
    $tree{'_items_in_tree_'}=$numFound;
    $self->{'tree_InstalledByCategory'}=\%tree;

    #populate the TreeCtrl
    return 0 unless $self->PopulateWithHash(\%tree,$progress,$max_pval);

    Wx::LogMessage _T("[Done]");
    $progress->Destroy();
    _uShowErr;
    return 1;

}

#this returns a referece to a hash, (module_name=>category_number), of all modules
sub _get_categories{
    my $self = shift;

    my $moduleFile= _uGetPath($self->{config},'cpp_modlist');
    my $modlistEval;  #the string to evaluate == 03modlist.data.gz

    #inflate file into $modlistEval
    Wx::LogMessage _T("Getting Category List...Inflating...");
    use IO::Uncompress::AnyInflate qw(anyinflate $AnyInflateError) ;
    anyinflate $moduleFile => \$modlistEval
        or Wx::LogMessage _T("anyinflate failed: ").$AnyInflateError."\n";
    return unless $modlistEval;
    Wx::LogMessage _T("Successfully Inflated Module Info File!");

    #get rid of file info in header
    $modlistEval=~s/(.*)package CPAN\:\:Modulelist/package CPAN\:\:Modulelist/si ;#get rid of file info

    #create List of Categories
    my $cat_hash=(); #the hash that is stored in the file
    my %categories=(); #the return value of this function
    eval $modlistEval.'$cat_hash=(CPAN::Modulelist->data)[0];';Wx::LogMessage($@) if $@;
       $categories{$_}=$cat_hash->{$_}->{'chapterid'} foreach (keys(%$cat_hash));

    #return list
    Wx::LogMessage _T("Successfully read Category List!");
    return \%categories;
    _uShowErr;
}

#this method displays the search results.
#use: $self->search($type,@list_of_searches)
#TODO add support for multiple searches, using ',' as delimiter
#TODO show scrollbars
sub search{
    my $self=shift;
    my ($type,@search)=@_;
    $self->{statusBar}->SetStatusText(_T("Searching. Please Wait..."));

    my $progress=Wx::ProgressDialog->new(_T("Setting Up List..."),
                _T("CPANPLUS is getting information..."),
                MAX_PROGRESS_VALUE,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

    $self->DeleteChildren($self->GetRootItem());
    foreach $s (@search){
        Wx::LogMessage _T("Searching for: ").$search[0]._T(" by $type\n");
        if ($s=~m|/(.*)/(.*)|){
            #print "Matching Regex...\n";
            eval "\$s=qr/$1/".($2||'');
        }else{
            $s=qr/$s/i;
        }
    }
    $type= lc($type);

    my $mparent=$self->GetRootItem();
    my @names=();
    my $numFound=0;
    my $tmpCnt=1;
    $modules={};
    if ($type eq 'any' || $type eq 'all'){
        my @modterms=CPANPLUS::Module::accessors(); #('name','version','path','comment','package','description','dslip','status');
        my @authterms=CPANPLUS::Module::Author::accessors(); #('author','cpanid','email');
        my $percent = MAX_PROGRESS_VALUE/(@modterms+@authterms);
        my $count=0;
        foreach $term (@modterms){
            if ($progress->Update($percent*($count++),_T("Searching in $term: Found ").keys(%$modules)._T(" items"))){
                foreach $m ($self->{cpan}->search(type => $term, allow => \@search)){
                    if ($m->isa(CPANPLUS::Module)){
                        #print "module: ".$m->name." [".($percent*($count++)/MAX_PROGRESS_VALUE)."]\n";
                        $modules->{$m->name} = $m;
                    }
                    if ($m->isa(CPANPLUS::Module::Author)){
                        foreach $amod ($m->modules()){
                            #print "amodule: ".$m->name." [".($percent*($count++)/MAX_PROGRESS_VALUE)."]\n";
                            $modules->{$amod->name} = $amod;
                        }
                    }
                }
            }else{$progress->Destroy();return;}
        }
    }else{
        foreach $m ($self->{cpan}->search(type => $type, allow => \@search)){
            return unless $progress->Update(MAX_PROGRESS_VALUE-1,_T("Found ").keys(%$modules)._T(" items"));
            $modules->{$m->name}=$m;
        }
    }

    $self->PopulateWithModuleHash($progress,$modules);
    $progress->Destroy;


    #Wx::Window::FindWindowByName('module_splitter')->FitInside();
    #Wx::Window::FindWindowByName('module_splitter')->UpdateWindowUI(wxUPDATE_UI_RECURSE );

    _uShowErr;
    print "Window Height: ".$self->GetClientSize()->GetWidth." , ".$self->GetClientSize()->GetHeight."\n";
#    print Dumper $self->GetClientSize();
    $self->{statusBar}->SetStatusText('');
    my $curStyle=$self->GetWindowStyleFlag();
    $self->SetWindowStyleFlag($self->GetWindowStyleFlag()|wxVSCROLL);
    $self->GetParent()->SetWindowStyleFlag($self->GetParent()->GetWindowStyleFlag()|wxVSCROLL);
}

sub PopulateWithModuleHash{
    my $self=shift;
    my $progress=shift || Wx::ProgressDialog->new(_T("Please Wait..."),
                _T("Displaying List..."),
                MAX_PROGRESS_VALUE,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my $modules=shift;
    my @names=();
    my $count=0;
    my $numFound=keys(%$modules);
    return unless $numFound>0;
    my $percent=MAX_PROGRESS_VALUE / $numFound;
    return unless $progress->Update(0,_T("Getting info for $numFound items."));

	my $newTree={};
    #get information from modules
    foreach $modname (keys(%$modules)){
        last unless $progress->Update($percent*$count);
        if ($modules->{$modname}->isa('CPANPLUS::Module')){
            my @names=split('::',$modname);
            my $ref=$newTree;
            foreach $n (@names){
            	$ref=$ref->{$n}='';
#            	push(@names,$modname);
            }
        }
        if ($modules->{$modname}->isa('CPANPLUS::Module::Author')){
            foreach $m ($modules->{$modname}->modules()){
            	my @names=split('::',$m->name);
            	my $ref=$newTree;
	            foreach $n (@names){
	            	$ref=$ref->{$n}='';
#		            push(@names,$m->name);
	            }
            }
        }
        $count++;
    }

    #populate the tree ctrl
    return unless $progress->Update(0,_T("Populating tree with ").$numFound._T(" items.") );
    $count=0;
#	my $dummy=$self->AppendItem($self->GetRootItem(),'Modules');    
#   foreach $item (sort {lc($a) cmp lc($b)} @names){
#        $self->AppendItem($dummy,$item,$self->_get_status_icon($item));
#        $count++;
#	}	
	foreach $k (sort(keys(%$newTree))){
        return unless $progress->Update($percent*$count);
		my $parent=$self->AppendItem($self->GetRootItem(),$item,$self->_get_status_icon($item));
		my $ref=$newTree->{$k};
		while($ref){
			
		}
        $count++;
    }
#	my $dummy=$self->AppendItem($self->GetRootItem(),'end');
#	my $subDummy=$self->AppendItem($dummy,'end');
#	$self->EnsureVisible($dummy);
    return 1;
}

#this method populates the list with the given module objects.
#if the object is an Author, then get the module names he/she has written
sub PopulateWithModuleList{
    my $self=shift;
    my $progress=shift || Wx::ProgressDialog->new(_T("Please Wait..."),
                _T("Displaying List..."),
                MAX_PROGRESS_VALUE,
                $self,
                wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my $totalFound=shift;
    return unless $totalFound;
    my $numFound=$totalFound;
    my @modules=@_;
    my @names=();
    my $count=0;
    my $percent=MAX_PROGRESS_VALUE/$totalFound;
    return unless $progress->Update(0,_T("Getting info for $numFound items."));

    #get information from modules
    foreach $mod (@modules){
        last unless $progress->Update($percent*$count);
        if ($mod->isa('CPANPLUS::Module')){
            push(@names,$mod->name);
        }
        if ($mod->isa('CPANPLUS::Module::Author')){
            foreach $m ($mod->modules()){
                push(@names,$m->name);
            }
        }
        $count++;
    }

    #populate the tree ctrl
    return unless $progress->Update(0,_T("Populating tree with").$totalFound._T(" items.") );
    $count=0;
    foreach $item (sort {lc($a) cmp lc($b)} @names){
        return unless $progress->Update($percent*$count);
        $self->AppendItem($self->GetRootItem(),$item,$self->_get_status_icon($item));
        $count++;
    }
    return 1;
}

#this method returns the index in the imageList for the status of the passed name
sub _get_status_icon{
    my $self=shift;
    my ($name)=@_;
    my $mod=$self->_get_mod($name);
    return $self->{iconList}->unknown->idx unless $mod;
    return $self->{iconList}->installed->idx if $mod->is_uptodate();
    return $self->{iconList}->not_installed->idx if !$mod->installed_version();
    return $self->{iconList}->update->idx;

    _uShowErr;

}
sub SetImageList{                                #must be a Wx::ImageList
    my ($self,$list)=@_;
    $self->{iconList}=$list;
    $self->AssignImageList($list->imageList);
}

########################################
########### Context Menu ##############
########################################



package CPANPLUS::Shell::Wx::ModuleTree::Menu;
use base 'Wx::Menu';
use Wx::Event qw/EVT_WINDOW_CREATE EVT_MENU/;
use Data::Dumper;
use Wx::Locale gettext => '_T';

sub new {
    my $class = shift;
    my $parent=shift;
    my $item=shift;
    my $self  = $class->SUPER::new();    # create an 'empty' menu object
    #get image so we can determine what the status is
    $img=$parent->GetItemImage($item);
    $actions=new Wx::Menu();
    $install=$actions->Append(1000,_T("Install")) if $img == 3;
    $update=$actions->Append(1001,_T("Update")) if $img == 1;
    $uninstall=$actions->Append(1002,_T("Uninstall")) if ($img==0 or $img==1);
    $actions->AppendSeparator();
    $fetch=$actions->Append(1003,_T("Fetch"));
    $extract=$actions->Append(1004,_T("Extract"));
    $prepare=$actions->Append(1005,_T("Prepare"));
    $build=$actions->Append(1006,_T("Build"));
    $test=$actions->Append(1007,_T("Test"));

    $self->AppendSubMenu($actions,_T("Actions"));

    $info=$self->Append(1008,_T("Get All Information"));

    my $modName=$parent->GetItemText($item);

    EVT_MENU( $self, $info, sub{&{$parent->{_minfoHandler}}(@_,$modName)} ) if $parent->{_minfoHandler};
    EVT_MENU( $actions, $install, sub{&{$parent->{_minstallHandler}}(@_,$modName)} ) if ($img == 3 && $parent->{_minstallHandler});
    EVT_MENU( $actions, $update, sub{&{$parent->{_mupdateHandler}}(@_,$modName)} ) if ($img == 1 && $parent->{_mupdateHandler});
    EVT_MENU( $actions, $uninstall, sub{&{$parent->{_muninstallHandler}}(@_,$modName)} )if (($img==0 or $img==1) && $parent->{_muninstallHandler});
    EVT_MENU( $actions, $fetch, sub{&{$parent->{_mfetchHandler}}(@_,$modName)} )  if $parent->{_mfetchHandler};
    EVT_MENU( $actions, $prepare, sub{&{$parent->{_mprepareHandler}}(@_,$modName)} ) if $parent->{_mprepareHandler};
    EVT_MENU( $actions, $build, sub{&{$parent->{_mbuildHandler}}(@_,$modName)} ) if $parent->{_mbuildHandler};
    EVT_MENU( $actions, $test,sub{&{$parent->{_mtestHandler}}(@_,$modName)} ) if $parent->{_mtestHandler};
    EVT_MENU( $actions, $extract, sub{&{$parent->{_mextractHandler}}(@_,$modName)} ) if $parent->{_mextractHandler};
#    print "Ending ";
    return $self;
}



1;