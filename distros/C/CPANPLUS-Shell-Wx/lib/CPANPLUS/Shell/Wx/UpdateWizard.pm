package CPANPLUS::Shell::Wx::UpdateWizard;

use base qw(Wx::Wizard);
use Wx qw/:allclasses wxID_OK wxID_CANCEL wxHORIZONTAL
    wxVERTICAL wxADJUST_MINSIZE wxDefaultPosition wxDefaultSize wxTE_MULTILINE
    wxTE_READONLY wxTE_CENTRE wxTE_WORDWRAP wxALIGN_CENTER_VERTICAL wxEXPAND
    wxALIGN_CENTER_HORIZONTAL wxGA_HORIZONTAL wxGA_SMOOTH wxLC_REPORT
    wxSUNKEN_BORDER/;
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGED EVT_WINDOW_CREATE EVT_BUTTON EVT_CHECKBOX EVT_WIZARD_PAGE_CHANGING);
use Wx::ArtProvider qw/:artid :clientid/;
use Cwd;
use Data::Dumper;

use Wx::Locale gettext => '_T';

use constant {
    INTRO_PAGE=>0,
    UPDATE_TYPE_PAGE=>1,
    REVIEW_UPDATE_PAGE=>2,
    PROGRESS_PAGE=>3,
    REPORT_PAGE=>4
};

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent,-1,"Update CPANPLUS");
    $self->{parent} = $parent;
    EVT_WIZARD_PAGE_CHANGED($self,$self,\&OnPageChanged);
    #get all the pages
    $self->{page1}=CPANPLUS::Shell::Wx::UpdateWizard::IntroPage->new($self);

    return $self;
}

sub OnPageChanged{
    my ($self,$event)=@_;
    #print "OnPageChanged ",@_,"\n";
    my $curPage=$event->GetPage;
    my $type=$curPage->{type};
    #print "TYPE IS $type";
#    if ($type eq 'PROGRESS_PAGE'){
#        $curPage->doUpdate();
#    }
}

#runs the wizard.
sub Run{
    my $self=shift;
    $self->RunWizard($self->{page1});
}

sub SetCPPObject{
    my $self=shift;
    $self->{cpan}=shift;

    #get the version so we can see if Selfupdate is supported
    my $curVersion=$self->{cpan}->VERSION;
    $curVersion=~s/_//;                 #delete underscore in version so we can compare
    print "Current CPP Verison is: $curVersion\n";
    if ( $curVersion >= 0.7702){    #check if we can use CPANPLUS::Selfupdate
        $self->{update} = $self->{cpan}->selfupdate_object;
    }else{
        $self->{update}=undef;
    }

    if ($self->{update}){ print "Using Selfupdate!\n";}

    $self->_setupTheList();
}

#this sets up a hash of all the values in selfupdate.
#this should work with all
sub _setupTheList{
    my $self=shift;
    my $update=$self->{update};

    #if we can't use selfupdate,set list to just CPANPLUS and return
    unless ($update){
        $self->{theList}={core_mods => {'CPANPLUS'=>'0.77_02'}} ;
        return;
    }

    #check for enabled features
    foreach $m ($update->list_enabled_features){
        $self->{theList}->{enabled_features}->{$m}= \$update->modules_for_feature($m,AS_HASH);
    }
    foreach $m ($update->list_features(AS_HASH)){
        $self->{theList}->{features}->{$m}= \$update->modules_for_feature($m,AS_HASH);
    }
    $self->{theList}->{core_deps} = $update->list_core_dependencies(AS_HASH);
    $self->{theList}->{core_mods} = $update->list_core_modules(AS_HASH);

    #the areas to update
    $self->{theList}->{areas_to_update}={
            core_mods=>0,
            core_deps=>0,
            features=>0,
            enabled_features=>0
    };

#    print Dumper $self->{theList};
    $self->{page1}->GetNext()->check_update();
}


#this is a template for a page. You must set the var's
# $self->{nextPage} and $self->{prevPage} in your constructor
package CPANPLUS::Shell::Wx::UpdateWizard::Page;
use base qw(Wx::WizardPage);
use Wx;
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGED EVT_WINDOW_CREATE);
use Data::Dumper;
use constant {
    INTRO_PAGE=>0,
    UPDATE_TYPE_PAGE=>1,
    REVIEW_UPDATE_PAGE=>2,
    PROGRESS_PAGE=>3,
    REPORT_PAGE=>4
};
use Wx::Locale gettext => '_T';

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent);
    $self->{parent}=$parent;
    $self->{prevPage}=undef;
    $self->{nextPage}=undef;
    return $self;
}
sub GetParent{ my $self=shift; return $self->{parent};}
sub SetPrev{ my $self=shift; $self->{prevPage}=shift;}
sub GetNext{ my $self=shift; return $self->{nextPage};}
sub GetPrev{ my $self=shift; return $self->{prevPage};}

#page 1: introduction
package CPANPLUS::Shell::Wx::UpdateWizard::IntroPage;

use base qw(CPANPLUS::Shell::Wx::UpdateWizard::Page);
use Wx qw/:allclasses wxHORIZONTAL
    wxVERTICAL wxADJUST_MINSIZE wxDefaultPosition wxDefaultSize wxTE_MULTILINE
    wxTE_READONLY wxTE_CENTRE wxTE_WORDWRAP wxALIGN_CENTER_VERTICAL wxEXPAND
    wxALIGN_CENTER_HORIZONTAL/;
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGED EVT_WINDOW_CREATE);
use Data::Dumper;

use Wx::Locale gettext => '_T';

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent);
    $self->{type}=INTRO_PAGE;

    $txt = Wx::TextCtrl->new($self, -1,
        _T("Welcome to the CPANPLUS update wizard. \n".
        "    \nWe will begin by asking a few simple questions to update ".
        "CPANPLUS. \n    \nClick Next to begin."),
        wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY|wxTE_CENTRE|wxTE_WORDWRAP);

    $txt->Enable(0);

    $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($txt, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->SetSizer($sizer);
    $sizer->Fit($self);

    $self->{nextPage}=CPANPLUS::Shell::Wx::UpdateWizard::UpdateTypePage->new($self->{parent});
    $self->{nextPage}->SetPrev($self);

    bless($self,$class);
    return $self;
}

#page 2:
package CPANPLUS::Shell::Wx::UpdateWizard::UpdateTypePage;

use base qw(CPANPLUS::Shell::Wx::UpdateWizard::Page);
use Wx qw/:allclasses wxHORIZONTAL
    wxVERTICAL wxADJUST_MINSIZE wxDefaultPosition wxDefaultSize wxTE_MULTILINE
    wxTE_READONLY wxTE_CENTRE wxTE_WORDWRAP wxALIGN_CENTER_VERTICAL wxEXPAND
    wxALIGN_CENTER_HORIZONTAL/;
use Wx::Event qw(EVT_CHECKBOX);
use Data::Dumper;

use Wx::Locale gettext => '_T';

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent);

    $self->{type}=UPDATE_TYPE_PAGE;

    $self->{parent}=$parent;

    $txt = Wx::TextCtrl->new($self, -1, _T("First, we need to know which modules you would like to update:"), wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY|wxTE_CENTRE|wxTE_WORDWRAP);
    $parent->{update_core} = Wx::CheckBox->new($self, -1, _T("Core: \n  Just the core CPANPLUS modules."), wxDefaultPosition, wxDefaultSize, );
    $parent->{update_deps} = Wx::CheckBox->new($self, -1, _T("Dependencies: \n  All the modules which CPANPLUS depends upon."), wxDefaultPosition, wxDefaultSize, );
    $parent->{update_efeatures} = Wx::CheckBox->new($self, -1, _T("Enabled Features: \n  Currently enabled features of CPANPLUS."), wxDefaultPosition, wxDefaultSize, );
    $parent->{update_features} = Wx::CheckBox->new($self, -1, _T("All Features: \n  Enabled and Non-Enabled Features"), wxDefaultPosition, wxDefaultSize, );
    $parent->{update_all} = Wx::CheckBox->new($self, -1, _T("All"), wxDefaultPosition, wxDefaultSize, );
    $line = Wx::StaticLine->new($self, -1, wxDefaultPosition, wxDefaultSize, );
    $parent->{latest_version} = Wx::CheckBox->new($self, -1, _T("Update to Latest Version"), wxDefaultPosition, wxDefaultSize, );

    $txt->Enable(0);

    $parent->{update_all}->SetValue(1);
    $parent->{latest_version}->SetValue(1);

    $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($txt, 0, wxEXPAND|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_core}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_deps}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_efeatures}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_features}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_all}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $sizer->Add($line, 0, wxEXPAND, 0);
    $sizer->Add($parent->{latest_version}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
    $self->SetSizer($sizer);
    $sizer->Fit($self);
    bless($self,$class);

    EVT_CHECKBOX($self,$parent->{update_core},\&UpdateCore);
    EVT_CHECKBOX($self,$parent->{update_deps},\&UpdateDeps);
    EVT_CHECKBOX($self,$parent->{update_efeatures},\&UpdateEFeatures);
    EVT_CHECKBOX($self,$parent->{update_features},\&UpdateFeatures);
    EVT_CHECKBOX($self,$parent->{update_all},\&UpdateAll);
    EVT_CHECKBOX($self,$parent->{latest_version},\&UpdateLatest);

    $self->{nextPage}=CPANPLUS::Shell::Wx::UpdateWizard::ReviewUpdatesPage->new($self->{parent});
    $self->{nextPage}->SetPrev($self);

    return $self;

}
sub check_update{
    my $self=shift;
    $parent=$self->{parent};
    #if we can't use selfupdate, disable all relevant controls
    unless ($parent->{update}){
        $parent->{update_core}->Enable(0);
        $parent->{update_deps}->Enable(0);
        $parent->{update_efeatures}->Enable(0);
        $parent->{update_features}->Enable(0);
        $parent->{update_all}->Enable(0);
    }

}
sub UpdateCore{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{areas_to_update}->{core_mods}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
sub UpdateDeps{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{areas_to_update}->{core_deps}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
sub UpdateEFeatures{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{areas_to_update}->{enabled_features}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
sub UpdateFeatures{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{areas_to_update}->{features}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
sub UpdateAll{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{areas_to_update}->{all}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
sub UpdateLatest{
    my $self=shift;
    my $event=shift;
    $parent=$self->{parent};
    $parent->{theList}->{_latest}=$event->IsChecked;
    $self->{nextPage}->Populate();
}
#page 3
package CPANPLUS::Shell::Wx::UpdateWizard::ReviewUpdatesPage;

use base qw(CPANPLUS::Shell::Wx::UpdateWizard::Page);
use Wx qw/:allclasses wxHORIZONTAL wxLB_MULTIPLE
    wxVERTICAL wxADJUST_MINSIZE wxDefaultPosition wxDefaultSize wxTE_MULTILINE
    wxTE_READONLY wxTE_CENTRE wxTE_WORDWRAP wxALIGN_CENTER_VERTICAL wxEXPAND
    wxALIGN_CENTER_HORIZONTAL wxSUNKEN_BORDER wxPD_APP_MODAL wxPD_CAN_ABORT
    wxPD_ELAPSED_TIME wxPD_ESTIMATED_TIME wxPD_REMAINING_TIME/;
use Wx::Event qw(EVT_BUTTON EVT_WIZARD_PAGE_CHANGED EVT_WINDOW_CREATE
    EVT_LISTBOX EVT_LIST_ITEM_SELECTED);
use Data::Dumper;
use CPANPLUS::Shell::Wx::util;

use Wx::Locale gettext => '_T';

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent);

    $self->{type}=REVIEW_UPDATE_PAGE;

    $txt = Wx::TextCtrl->new($self, -1, _T("Next, review all the modules that need to be upgraded or installed. Press the Update button when ready."), wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY|wxTE_CENTRE|wxTE_WORDWRAP);
    #$parent->{update_list} = Wx::CheckListBox->new($self, -1, wxDefaultPosition, wxDefaultSize, [],wxSUNKEN_BORDER);
    #$parent->{update_list} = Wx::ListBox->new($self, -1, wxDefaultPosition, wxDefaultSize, [],wxSUNKEN_BORDER|wxLB_MULTIPLE);
    $parent->{update_list} = CPANPLUS::Shell::Wx::Frame::ActionsList->new($self, -1, wxDefaultPosition, wxDefaultSize, [],wxSUNKEN_BORDER|wxLB_MULTIPLE);
    $parent->{do_update} = Wx::Button->new($self,-1,_T("Update!"));


    $txt->Enable(0);

    $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($txt, 0, wxEXPAND|wxADJUST_MINSIZE, 0);
    $sizer->Add($parent->{update_list}, 1, wxEXPAND, 0);
    $sizer->Add($parent->{do_update}, 0, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->SetSizer($sizer);
    $sizer->Fit($self);
    bless($self,$class);

    EVT_BUTTON($self,$parent->{do_update},\&_update);

    $self->{nextPage}=CPANPLUS::Shell::Wx::UpdateWizard::ReportPage->new($self->{parent});
    $self->{nextPage}->SetPrev($self);

    return $self;

}

sub Populate{
    my $self=shift;
    $parent=$self->{parent};
    my $list=$parent->{theList};
    my $listctrl=$parent->{update_list};
    $listctrl->ClearList();

    my @mods=();
    my $num=1;

    foreach $area (keys(%$list)){
        #skip 'features' and 'areas' since the need special handling
        next if ($area eq 'areas_to_update' || $area eq 'features' ||
            $area eq 'enabled_features' || !($list->{areas_to_update}->{$area})
            );
        foreach $name (keys(%{$list->{$area}})){
            my $h={name=>$name,version=>$list->{$area}->{$name}};
            #print Dumper $h;
            push(@mods,$h) unless grep {$_->{name} =~ /^$name$/} @mods;
            $num++;
        }
    }
    if ($list->{areas_to_update}->{features}){
        foreach my $confDep (keys(%{$list->{features}})){
            my $confDepList=$list->{features}->{$confDep};
            next if ref($confDepList) eq 'SCALAR'; #skip empty refs
            $confDepList=$$confDepList if ref($confDepList) eq 'REF';
            foreach $name (keys(%{$confDepList})){
                my $h={name=>$name,version=>$confDepList->{$name}};
                #print Dumper $h;
                push (@mods,$h ) unless grep {$_->{name} =~ /^$name$/} @mods;
                $num++;
            }
        }
    }
    if ($list->{areas_to_update}->{enabled_features}){
        foreach my $confDep (keys(%{$list->{enabled_features}})){
            my $confDepList=$list->{enabled_features}->{$confDep};
            next if ref($confDepList) eq 'SCALAR'; #skip empty refs
            $confDepList=$$confDepList if ref($confDepList) eq 'REF';
            foreach $name (keys(%{$confDepList})){
                my $h={name=>$name,version=>$confDepList->{$name}};
                #print Dumper $h;
                push (@mods,$h ) unless grep {$_->{name} =~ /^$name$/} @mods;
                $num++;
            }
        }
    }

    #add all the items to the list
    foreach $m (@mods){
        $listctrl->AddActionWithPre($m->{name},$m->{version},'update');
    }
}

#run the update
sub _update{
    my $self=shift;
    my $parent=$self->{parent};
    my $list=$parent->{theList};
    my $listctrl=$parent->{update_list};
    my $modtree=Wx::Window::FindWindowByName('tree_modules');
    print "Running Update...";
    my $total=$listctrl->GetItemCount;
    my $progress=Wx::ProgressDialog->new(
            "Updating CPANPLUS...",
            "Updating...",$total*6,$self,
            wxPD_APP_MODAL|wxPD_CAN_ABORT|wxPD_ELAPSED_TIME|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);
    my $i=1;
    my $debug='';
    while ($listctrl->GetItemCount > 0){
        my $name=$listctrl->GetItemText(0);
        my $mod=$modtree->_get_mod($name);
        next unless $mod;
        $self->_install($mod,$progress,\$i,\$debug);
        #$mod->install();
        $listctrl->DeleteItem(0);
        $i++;
    }
    $progress->Destroy();
    $parent->{problems}->SetValue($parent->{problems}->GetValue.
        "\nOUTPUT:\n\n".$debug."\n\nSee Log Tab for full output.\n");
    _uShowErr();
}

sub _install{
    my ($self,$mod,$progress,$curProgRef,$txtref)=@_;
    return unless $mod;
    $$txtref.=$mod->name.":\n";

    if ($progress->Update($$curProgRef,"Fetching ".$mod->name."...")){
        $$txtref.="\tFetch: ";
        if ($mod->fetch()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    if ($progress->Update($$curProgRef,"Extracting ".$mod->name."...")){
        $$txtref.="\tExtract: ";
        if ($mod->extract()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    if ($progress->Update($$curProgRef,"Preparing ".$mod->name."...")){
        $$txtref.="\tPrepare: ";
        if ($mod->prepare()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    if ($progress->Update($$curProgRef,"Building ".$mod->name."...")){
        $$txtref.="\tBuild: ";
        if ($mod->create()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    if ($progress->Update($$curProgRef,"Testing ".$mod->name."...")){
        $$txtref.="\tTest: ";
        if ($mod->test()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    if ($progress->Update($$curProgRef,"Installing ".$mod->name."...")){
        $$txtref.="\tInstall: ";
        if ($mod->install()){
            $$txtref.="[Success]\n";
            $$curProgRef++;
        }else{
            $$txtref.="[Failed]\n";
            return 0;
        }
    }else{$$txtref.="User Cancelled\n";return 0;}

    return 1;
}


#page 3
package CPANPLUS::Shell::Wx::UpdateWizard::ReportPage;

use base qw(CPANPLUS::Shell::Wx::UpdateWizard::Page);
use Wx qw/:allclasses wxHORIZONTAL
    wxVERTICAL wxADJUST_MINSIZE wxDefaultPosition wxDefaultSize wxTE_MULTILINE
    wxTE_READONLY wxTE_CENTRE wxTE_WORDWRAP wxALIGN_CENTER_VERTICAL wxEXPAND
    wxALIGN_CENTER_HORIZONTAL wxSUNKEN_BORDER/;
use Wx::Event qw(EVT_WIZARD_PAGE_CHANGED EVT_WINDOW_CREATE);
use Data::Dumper;
use CPANPLUS::Shell::Wx::util;

use Wx::Locale gettext => '_T';

sub new{
    my $class = shift;
    my ($parent) = @_;
    my $self = $class->SUPER::new($parent);

    $self->{type}=REPORT_PAGE;

    $parent->{problems} = Wx::TextCtrl->new($self, -1, _T("If there were any problems, they are listed below."), wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY|wxTE_WORDWRAP);
    $parent->{problems}->Enable(0);

    $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($parent->{problems}, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->SetSizer($sizer);
    $sizer->Fit($self);

    return $self;

}

sub ShowDebug{
    my $self=shift;


}
1;
