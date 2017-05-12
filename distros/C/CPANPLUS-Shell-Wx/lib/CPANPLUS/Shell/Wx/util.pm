package CPANPLUS::Shell::Wx::util;

use Wx::Event qw(EVT_MENU EVT_TOOL EVT_WINDOW_CREATE EVT_BUTTON);
use Wx::ArtProvider qw/:artid :clientid/;
use Wx;
use CPANPLUS;
use Cwd;
use Data::Dumper;
use CPANPLUS::Error;
use File::Spec;
use File::HomeDir;
use Class::Struct qw(struct);

#enable gettext support
use Wx::Locale gettext => '_T';

use base qw(Exporter);
our @EXPORT = qw(_uPopulateTree _uGetTimed _uGetInstallPath
        _uShowErr _u_t_ShowErr _uGetImageData _uGetPath);

#returns the path for the specified item
#call: _uGetPath($cpp_config,$item)
#$item can be one of :
#    'app_config'        wxCPAN config file
#    'cpp_mod_dir'        path to $cpp_home/authors/id/, where cpanplus stores modules
#    'cpp_stat_file'        path to the cpp status.store file
#    'cpp_modlist'        path to the 03modlist.data.gz file
sub _uGetPath{
    my $conf=shift;        #a CPANPLUS::Config object
    my $path=shift;        #the value we want.
    my $op1=shift;        #the optional subdir
    my $ret=undef;        #return value
    my $home = File::HomeDir->my_home; #user's home directory
    my $cpp_home= $conf->get_conf('base');

    if ($path eq 'app_config'){
        $ret=File::Spec->catfile($cpp_home,'wxcpan.conf')
    }elsif($path eq 'cpp_mod_dir'){
        $ret=File::Spec->catdir($cpp_home,"authors","id");
    }elsif($path eq 'cpp_stat_file'){
        $ret=File::Spec->catdir($cpp_home,'status.stored');
    }elsif($path eq 'cpp_modlist'){
        $ret=File::Spec->catdir($cpp_home,'03modlist.data.gz');
    }else{
        print "Usage: CPANPLUS::Shell::Wx::util::_uGetPath('app_config')";
    }
    return $ret;
}

#TODO this method populates a tree with the correct status icon
sub _uPopulateModulesWithIcons{
    my $max_pval=10000;  #the maximum value of the progress bar
    my $tree=shift;
    my $parent=shift;
    my $aref=shift;
    my $progress = shift;
    my $percent=shift || $max_pval/(@{%$tree}/2);
    my $cnt=shift || 0;

    $progress=Wx::ProgressDialog->new(_T("Inserting Items..."),
                _T("Inserting Items Into List..."),
                $max_pval,
                $self,
                wxPD_APP_MODAL) unless $progress;

    #remove all items if we are stating anew
    $tree->DeleteChildren($tree->GetRootItem()) unless $cnt;

    foreach $items ( sort {lc $a cmp lc $b} keys(%$tree)  ){
        my $curParent=$tree->AppendItem(
            $self->GetRootItem(),
            $top_level,_uGetStatusIcon($top_level));
        $progress->Update($cnt*$percent); #,"[Step 2 of 2] Iserting ".keys(%tree)." Authors Into Tree...#$cnt : $top_level");
        foreach $item (sort(@{$tree{$top_level}})){
            if (keys(%$item)){
                my $new_parent=$self->AppendItem($curParent,(keys(%$item))[0],$self->_get_status_icon($item)) if ($curParent && $item);
                $cnt++;
                $progress->Update($cnt*$percent);
                $cnt=_uPopulateModulesWithIcons($tree,$new_parent,$item,$progress,$percent,$cnt);
            }else{
                my $new_parent=$self->AppendItem($curParent,$item,$self->_get_status_icon($item)) if ($curParent && $item);
                $progress->Update($cnt*$percent);
                $cnt++;
            }
        }
    }
    return $cnt;
    #$progress->Destroy();
}

sub _uGetInstallPath{
    my $file=shift;
    #$file=~s|::|/|g;
    my @path=split('::',$file);
    foreach $p (@INC){
        my $file=File::Spec->catfile($p,@path);
        #print "$p/$file\n";
        return $file if(-e $file) ;
    }
}

#it checks the stack in CPANPLUS::Error,
# and logs it to wherever Wx::LogMessage is sent to
sub _uShowErr{
    foreach $msg (CPANPLUS::Error::stack()){
        my $lvl=$msg->level;
        $lvl=~s/cp_//;
        Wx::LogMessage("[CPANPLUS ".(uc($lvl||''))."@".$msg->when."]".$msg->message);
        CPANPLUS::Error::flush();
    }
}
#this method retrieves the local directory where CPANPLUS
#stores its information regarding each module
sub _uGetModDir{
    my $mod=shift;

}
#TODO this method populates a tree with the given array ref
sub _uPopulateModules($$){
    my $tree=shift;
    my $aref=shift;
}

#@return the time in readable - mm:ss - format
#@params:
#    $begin: the time we are comparing to
#@usage:
#    use util qw/_uGetTimed/;
#    my $begin=time();
#    {... code to be timed ...}
#    my $totalTime=_uGetTimed($begin);
sub _uGetTimed($){
    my $begin=shift;
    mu $end=time();
    return sprintf("%2d",(($end-$begin)/60)).":".sprintf("%2d",(($end-$begin) % 60));
}


#the following two structs are used to hold the image data
#for the image lists for the various treectrl's.
#    idx is the value from imglist->Add($img)
#    icon is the actual icon data
struct ('CPANPLUS::Shell::Wx::util::imagedata' => {
    idx        =>    '$',
    icon    =>    '$'
});
struct 'CPANPLUS::Shell::Wx::util::images' => {
    installed        => 'CPANPLUS::Shell::Wx::util::imagedata',
    update            => 'CPANPLUS::Shell::Wx::util::imagedata',
    remove            => 'CPANPLUS::Shell::Wx::util::imagedata',
    not_installed    => 'CPANPLUS::Shell::Wx::util::imagedata',
    unknown            => 'CPANPLUS::Shell::Wx::util::imagedata',
    imageList        => 'Wx::ImageList'
};

#this method returns a images struct with appropriate data
sub _uGetImageData{
    my $imgList=Wx::ImageList->new(16,16,1);
    $icon_installed=Wx::ArtProvider::GetBitmap(wxART_TICK_MARK,wxART_BUTTON_C);
    $icon_update=Wx::ArtProvider::GetBitmap(wxART_ADD_BOOKMARK,wxART_BUTTON_C);
    $icon_remove=Wx::ArtProvider::GetBitmap(wxART_DEL_BOOKMARK,wxART_BUTTON_C);
    $icon_not_installed=Wx::ArtProvider::GetBitmap(wxART_NEW_DIR,wxART_BUTTON_C);
    $icon_unknown=Wx::ArtProvider::GetBitmap(wxART_QUESTION,wxART_BUTTON_C);

    $images=CPANPLUS::Shell::Wx::util::images->new(
        installed => CPANPLUS::Shell::Wx::util::imagedata->new(
                idx        =>    $imgList->Add($icon_installed),
                icon    =>    $icon_installed
            ),
        update => CPANPLUS::Shell::Wx::util::imagedata->new(
                idx        =>    $imgList->Add($icon_update),
                icon    =>    $icon_update
            ),
        remove => CPANPLUS::Shell::Wx::util::imagedata->new(
                idx        =>    $imgList->Add($icon_remove),
                icon    =>    $icon_remove
            ),
        not_installed => CPANPLUS::Shell::Wx::util::imagedata->new(
                idx        =>    $imgList->Add($icon_not_installed),
                icon    =>    $icon_not_installed
            ),
        unknown => CPANPLUS::Shell::Wx::util::imagedata->new(
                idx        =>    $imgList->Add($icon_unknown),
                icon    =>    $icon_unknown
            ),
        imageList=>$imgList
        );
    return $images;
}


1;