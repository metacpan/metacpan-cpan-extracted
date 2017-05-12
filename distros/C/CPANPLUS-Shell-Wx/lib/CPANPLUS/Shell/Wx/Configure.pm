#TODO clean up Log Messages

package CPANPLUS::Shell::Wx::Configure;
use Wx;
use Data::Dumper;
use Wx::XRC;
use Cwd;
use CPANPLUS::Shell::Wx::util;

#use CPANPLUS::Shell::Wx::prefsCheck;
use Wx::Event qw(EVT_CHECKBOX EVT_WINDOW_CREATE);
use Wx::Locale gettext => '_T';

BEGIN {
    use vars qw( @ISA $VERSION );
    @ISA     = qw( Wx::Dialog);
    $VERSION = '0.01';
}

use base 'Wx::Dialog';

#when creating a new window, add the config property to it,
#and crete a new backend::configure object so we can manipulate it
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object

    $self->{cpan}   = Wx::Window::FindWindowByName('main_window')->{cpan};
    $self->{config} = $self->{cpan}->configure_object();

    #NOTE Freeze object so we can revert changes upon cancel
    use Storable qw[dclone];
    $self->{old_conf}=dclone($self->{config}->conf);
    $self->_check_config_file();
    return $self;

}

#this checks to see if user config file is present.
#if not, it creates one
sub _check_config_file{
    my $self=shift;
    my $file=_uGetPath($self->{config},'app_config');
    unless (-e $file ){
        if (open(F,">$file") ){
            print F '';
            close F;
        }else{
            Wx::LogError("Cannot create wxCPAN Preferences File: $file");
        }
    }else{
        Wx::LogMessage("Using wxCPAN Preferences file: $file");
    }
}

########################################
############ LibListCtrl ###############
########################################
package CPANPLUS::Shell::Wx::Configure::LibListCtrl;
use Wx::Event qw(EVT_WINDOW_CREATE EVT_BUTTON);
use Data::Dumper;
use Wx::Locale gettext => '_T';

use base 'Wx::ListView';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{cpan}   = Wx::Window::FindWindowByName('prefs_window')->{cpan};
    $self->{config} = $self->{cpan}->configure_object();

    #This is need because, for some unknown reason, OnCreate()
    # is being called 3 times
    $self->{'has_inited'} = 0;

    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    return if $self->{'has_inited'};
    my @vals = $self->{config}->get_conf('hosts');
    $self->InsertColumn(0,_T("Library Path"));
    $self->SetColumnWidth(0,-1);
    $self->RePopulate();
    $self->{'has_inited'} = 1;
}
sub RePopulate{
    my $self = shift;
    my $vals = $self->{config}->get_conf('lib');
    $self->DeleteAllItems();
    Wx::LogMessage Dumper $vals;
    foreach $item ( @$vals ) {
        $self->InsertStringItem( 0, $item );
    }
    $self->SetColumnWidth(0,-1);                            #resize the column to fit new width
}

########################################
############## SpinCtrl ################
########################################

package CPANPLUS::Shell::Wx::Configure::SpinCtrl;
use Wx::Event qw(EVT_SPINCTRL EVT_WINDOW_CREATE);
use Wx::Locale gettext => '_T';

BEGIN {
    use vars qw( @ISA $VERSION );
    @ISA     = qw( Wx::SpinCtrl);
    $VERSION = '0.01';
}

use base 'Wx::SpinCtrl';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_SPINCTRL( $self, $self, \&OnSpin );
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{config} = Wx::Window::FindWindowByName('prefs_window')->{config};
    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    my $name = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->SetValue(\$self->{config}->get_$name'))";
    $self->SetRange(0,65535);
}

#this method happens when a spinner is spinned.
#The name [GetName() in wxWidgets] is used to retrieve the value
#and category in the CPANPLUS::Configure module
sub OnSpin {
    my $self    = shift;
    my ($event) = @_;
    my $name    = $self->GetName();
    $name =~ s|_|\('|;
    eval "\$self->{config}->set_$name'=>\$self->GetValue)";
}

########################################
############## CheckBox ################
########################################

package CPANPLUS::Shell::Wx::Configure::CheckBox;
use Wx::Event qw(EVT_CHECKBOX EVT_WINDOW_CREATE);
use Wx::Locale gettext => '_T';

use base 'Wx::CheckBox';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_CHECKBOX( $self, $self, \&OnToggle );
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{config} = Wx::Window::FindWindowByName('prefs_window')->{config};
    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    my $name = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->SetValue(\$self->{config}->get_$name'))";
}

#this method happens when a checkbox is toggled.
#The name [GetName() in wxWidgets] is used to retrieve the value
#and category in the CPANPLUS::Configure module
sub OnToggle {
    my $self    = shift;
    my ($event) = @_;
    my $name    = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->{config}->set_$name'=>\$self->GetValue)";
}

########################################
############## ComboBox ################
########################################

package CPANPLUS::Shell::Wx::Configure::ComboBox;
use Wx::Event qw(EVT_COMBOBOX EVT_TEXT EVT_WINDOW_CREATE);
use Data::Dumper;
use Wx::Locale gettext => '_T';

use base 'Wx::ComboBox';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{config} = Wx::Window::FindWindowByName('prefs_window')->{config};
    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    my $name = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    my $val;
    eval "\$val=\$self->{config}->get_$name')";
    EVT_COMBOBOX( $self, $self, \&OnSelect ) if $name=~/prereqs/;
    EVT_TEXT($self, $self, \&OnEdit) if $name=~/dist_type/;
    $self->SetSelection($val) if $name=~/prereqs/;
    $self->SetValue($val) if $name=~/dist_type/;
}

#this method happens when a selection is made
sub OnSelect {
    my $self    = shift;
    my ($event) = @_;
    my $name    = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->{config}->set_$name'=>\$self->GetSelection)";
}
#this is called when the edit box is edited. Only applies to dist_type
sub OnEdit {
    my $self    = shift;
    my ($event) = @_;
    my $name    = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->{config}->set_$name'=>'".$self->GetValue."')";
}

########################################
############## TextCtrl ################
########################################
package CPANPLUS::Shell::Wx::Configure::TextCtrl;
use Wx::Event qw(EVT_KILL_FOCUS EVT_WINDOW_CREATE);
use Wx::Locale gettext => '_T';

use base 'Wx::TextCtrl';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_KILL_FOCUS( $self, \&OnBlur );
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{config} = Wx::Window::FindWindowByName('prefs_window')->{config};
    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    my $name = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->SetValue(\$self->{config}->get_$name'))";
}

#this method happens when the textctrl loses focus.
#it sets the config value
sub OnBlur {
    my $self    = shift;
    my ($event) = @_;
    my $name    = $self->GetName();
    $name =~ s|_|\('|; #for use with wxGlade
    eval "\$self->{config}->set_$name'=>'".$self->GetValue."')";
}

########################################
############ HostListCtrl ##############
########################################
package CPANPLUS::Shell::Wx::Configure::HostListCtrl;
use Wx::Event qw(EVT_WINDOW_CREATE EVT_BUTTON);
use Data::Dumper;
use Wx::Locale gettext => '_T';

use base 'Wx::ListView';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{cpan}   = Wx::Window::FindWindowByName('prefs_window')->{cpan};
    $self->{config} = $self->{cpan}->configure_object();

    #This is need because, for some unknown reason, OnCreate()
    # is being called 3 times
    $self->{'has_inited'} = 0;
    return $self;
}

#this is called after new()
sub OnCreate {
    my $self = shift;
    return if $self->{'has_inited'};
    my @vals = $self->{config}->get_conf('hosts');

    $self->InsertColumn( 0, 'Host' );
    $self->InsertColumn( 1, 'Path' );
    $self->InsertColumn( 2, 'Scheme' );

    $self->RePopulate();

    $self->{'has_inited'} = 1;
}
sub RePopulate{
    my $self = shift;
    my @vals = $self->{config}->get_conf('hosts');
    $self->DeleteAllItems();
    foreach $item ( @{ $vals[0] } ) {
        $self->InsertStringItem( 0, $item->{'host'} );
        $self->SetItem( 0, 1, $item->{'path'} );
        $self->SetItem( 0, 2, $item->{'scheme'} );
    }
}


########################################
############### Button #################
########################################

package CPANPLUS::Shell::Wx::Configure::Button;
use Wx::Event qw(EVT_WINDOW_CREATE EVT_BUTTON);
use Data::Dumper;
use Wx::Locale gettext => '_T';

use base 'Wx::Button';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();    # create an 'empty' Frame object
    EVT_WINDOW_CREATE( $self, $self, \&OnCreate );
    $self->{cpan}   = Wx::Window::FindWindowByName('prefs_window')->{cpan};
    $self->{config} = $self->{cpan}->{config};
    return $self;
}

sub OnCreate {
    my $self = shift;
    my $name = $self->GetName();
    my $id=$self->GetId();

    $self->{conflist} = Wx::Window::FindWindowByName('conf_hosts');
    $self->{config} = $self->{conflist}->{config};  #
    $self->{cpan} = $self->{conflist}->{cpan};
    $self->{liblist} = Wx::Window::FindWindowByName('conf_lib');

    EVT_BUTTON( $self, $self, \&OnAdd )         if ( $name eq 'AddHost' );
    EVT_BUTTON( $self, $self, \&OnRemove )      if ( $name eq 'RemoveHost' );
    EVT_BUTTON( $self, $self, \&OnPrefsCancel ) if ( $name eq 'prefs_cancel' );
    EVT_BUTTON( $self, $self, \&OnPrefsSave )   if ( $name eq 'prefs_save' );
    EVT_BUTTON( $self, $self, \&OnAddLib )   if ( $name eq 'AddLib' );
    EVT_BUTTON( $self, $self, \&OnRemoveLib )   if ( $name eq 'RemoveLib' );
    EVT_BUTTON( $self, $self, \&OnSelectFile )   if ( $name =~ /^selectFile_/ );
    EVT_BUTTON( $self, $self, \&OnSelectDir )   if ( $name =~ /^selectDir_/ );

}

sub OnSelectDir{
    my $self = shift;
    my $myName = $self->GetName();
    my $textCtrlName=$myName;
    $myName =~ s|selectDir_||; #remove item prefix
    $myName =~ s|_|\('|;        #make into function call
    $textCtrlName=~s/selectDir_//;#name of textctrl to update
    my $curDir='';
    eval "\$curDir=\$self->{config}->get_$myName')";

    my $dlg=Wx::DirDialog->new($self,_T("Choose a Directory:"),$curDir);
    if ($dlg->ShowModal()){
        Wx::LogMessage _T("Setting ").$myName._T(" to ").$dlg->GetPath."\n";
        eval "\$self->{config}->set_$myName'=>\$dlg->GetPath())";
        my $textctrl=Wx::Window::FindWindowByName($textCtrlName);
        $textctrl->SetValue($dlg->GetPath()) if $textctrl;
    }
}
sub OnSelectFile{
    my $self = shift;
    my $myName = $self->GetName();
    my $textCtrlName=$myName;
    $myName =~ s|selectFile_||; #remove item prefix
    $myName =~ s|_|\('|;        #make into function call
    $textCtrlName=~s/selectFile_//;#name of textctrl to update
    my $curDir='';
    eval "\$curDir=\$self->{config}->get_$myName')";

    my $dlg=Wx::FileDialog->new($self,_T("Choose a File:"),$curDir);
    if ($dlg->ShowModal()){
        eval "\$self->{config}->set_$myName'=>\$dlg->GetPath())";
        my $textctrl=Wx::Window::FindWindowByName($textCtrlName);
        $textctrl->SetValue($dlg->GetPath()) if $textctrl;
    }
}

sub OnRemoveLib {
    my $self     = shift;
    my ($event)  = @_;
    my $selectedIdx=$self->{liblist}->GetFirstSelected();
    my $selected = $self->{liblist}->GetItemText($selectedIdx);
    $self->{liblist}->DeleteItem($selectedIdx);

    my $old_libs=$self->{config}->get_conf('lib');
    my @new_libs=();
    for (my $i=0;$i<@$old_libs;$i++){
        push(@new_libs,$old_libs->[$i]) unless ($old_libs->[$i] eq $selected);
    }
    $self->{config}->set_conf(lib => \@new_libs);
}

sub OnAddLib {
    my $self = shift;
    my ($event) = @_;
    my $new_path=Wx::DirSelector(                            #get path from user
        _T("Select a Path to add to @INC:"));
    return unless $new_path;                                 #if user cancelled, do nothing else

    $libCtrl = Wx::Window::FindWindowByName('conf_lib');    #get the lib list control
    my $libs=$self->{config}->get_conf('lib');                #get curent libs array
    push (@$libs,$new_path);                                 #append to current libs array
    $self->{config}->set_conf(lib => $libs);                 #set the libs array to new value
    $libCtrl->InsertStringItem( 0,$new_path );                 #Insert the new value into list
    $libCtrl->SetColumnWidth(0,-1);                            #resize the column to fit new width

}

sub OnPrefsCancel {
    my $self = shift;
    my ($event) = @_;
#    $self->{config}->init();
    my $prefsWin=Wx::Window::FindWindowByName('prefs_window');

    #replace config object with a stored copy
     $prefsWin->{config}->conf($prefsWin->{old_conf});

    $prefsWin->Destroy();
}

sub OnPrefsSave {
    my $self       = shift;
    my ($event)    = @_;
    Wx::LogMessage("Saving Prefs...");
    my $prefsWin=Wx::Window::FindWindowByName('prefs_window');
    my $thisConfig = $prefsWin->{config};
    Wx::Window::FindWindowByName('main_window')->{config} = $thisConfig;
    if ( $thisConfig->can_save() ) {
        $thisConfig->save();
        Wx::LogMessage(_T("Preferences Saved!"));
    } else {
        Wx::MessageBox( _T('Sorry! I cannot save your file!'),
                        _T('Save Failed'), wxOK | wxICON_INFORMATION, $self );
        return;
    }
    $prefsWin->Destroy();
}

#some code in this function is taken from CPANPLUS::Configure::Setup.
sub OnAdd {
    my $self = shift;
    my ($event) = @_;
    use Wx qw(wxYES_NO wxID_YES wxYES wxID_NO wxNO wxCANCEL wxID_CANCEL wxICON_QUESTION);
    my @cur_hosts=@{$self->{config}->get_conf('hosts')};

    #get what type we are adding - custom or mirror
    my $qDialog=Wx::MessageDialog->new( $self, _T('Do You Want to add a custom entry(yes) or select from a list(no)?'),
                        _T('Select Entry Type'), (wxYES_NO | wxICON_QUESTION) );
    if ($qDialog->ShowModal() == wxID_YES){
        my $custom_dialog = Wx::TextEntryDialog->new(
            $self, _T("Enter the URI of your custom source:"),
            _T("Enter Custom Source")
            );
        my $custom_source=$custom_dialog->ShowModal;
        return if( $custom_source == wxID_CANCEL );
        $custom_source=$custom_dialog->GetValue();
        my $href;
        ($href->{scheme},$href->{host},$href->{path})=$custom_source =~ /\s*(.*)\:\/\/(.*?)(\/.*)\s*/;
        push @cur_hosts,$href;
        goto END;
    }

    my %hosts   = (); #hash containing host entries
    my %location_tree = (); #a tree of locations

    use CPANPLUS::Module::Fake;
    use CPANPLUS::Module::Author::Fake;

    my $file = $self->{cpan}->_fetch(
        fetchdir => $self->{config}->get_conf('base'),
        module => CPANPLUS::Module::Fake->new(
            module  => $self->{config}->_get_source('hosts'),
            path    => '',
            package => $self->{config}->_get_source('hosts'),
            author => CPANPLUS::Module::Author::Fake->new( _id => $self->{cpan}->_id ),
            _id    => $self->{cpan}->_id,
            )
        );

    #read in the MIRRORS.txt file and parse it
    my $curhost = '';
    open F, $file;
    foreach $line (<F>) {
        unless ( $line =~ /^\#/ ) {    #skip lines that begin with a comment
            $curhost = $1 if ( $line =~ /(^(\S+\.)+\S+)\:/ );  #lines that begin with x.y.z: mean a new entry
            $hosts{$curhost}->{$1} = $2 if ( $line =~ /(\w*?)\s*=\s*\"(.*?)\"/ ); #add info to host
        }
    }
    close F;

    foreach $key ( keys(%hosts) ) {
        my @loc = split( ', ', $hosts{$key}->{'dst_location'} );        #split line like "city,state,country,region (lat long)"
        $loc[-1] =~ s/\s*\((.*)\)//;                                    #get rid of lat, long coord
        $1 =~ /\s*(\-?\d+\.\d+)\s*(\-?\d+\.\d+)/;                         #search for lat, long
        ($hosts{$key}->{'lat'},$hosts{$key}->{'long'}) = ($1,$2);        #assign lat,long
        $location_tree{ $loc[-1] }->{ $loc[-2] }->{ $loc[-3] } = $hosts{$key};    #all entries have at least depths
        if ( $loc[-4] ){                                                #some entries have four depths
            $location_tree{ $loc[-1] }->{ $loc[-2] }->{ $loc[-3] }={};
            $location_tree{ $loc[-1] }->{ $loc[-2] }->{ $loc[-3] }->{ $loc[-4] }=$hosts{$key};
        }
    }

    my $selection = \%location_tree;
    my @titles_tree = ( _T('Region'), _T('Country'), _T('State'), _T('City') );
    until ( $selection->{'dst_location'} ) {
        my $title  = shift @titles_tree;
        my $choice = Wx::GetSingleChoice( _T("Select ").$title,
                                     _T("Select ").$title.":",
                                     [ sort( keys( %{$selection} ) ) ], $self );
        return unless $choice;
        $selection = $selection->{$choice};
    }

    my $href;
    $selection=$selection->{'dst_http'};
    ($href->{scheme},$href->{host},$href->{path})=$selection =~ /\s*(.*)\:\/\/(.*?)(\/.*)\s*/;
    push @cur_hosts,$href;

    END:
    $self->{config}->set_conf( hosts => \@cur_hosts );
    $self->{conflist}->RePopulate();

}

sub OnRemove {
    my $self     = shift;
    my ($event)  = @_;
    my $selected = $self->{conflist}->GetItemText($self->{conflist}->GetFirstSelected());
    $self->{conflist}->DeleteItem($self->{conflist}->GetFirstSelected());

    my $old_hosts=$self->{config}->get_conf('hosts');
    my @new_hosts=();
    for (my $i=0;$i<@$old_hosts;$i++){
        push(@new_hosts,$old_hosts->[$i]) unless ($old_hosts->[$i]->{'host'} eq $selected);
    }

    $self->{config}->set_conf(hosts => \@new_hosts);
}
1;
