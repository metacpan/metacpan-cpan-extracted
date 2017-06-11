package BlankOnDev::DataDev;
use strict;
use warnings FATAL => 'all';

# Version :
our $VERSION = '0.1003';

# Subroutine for  :
# ------------------------------------------------------------------------
sub data_dev {
    my $home_dir = $ENV{"HOME"};
    my %data = (
        'home_dir' => $home_dir,
        'dir_dev' => $home_dir . "/.BlankOnDev/",
        'prefix_flcfg' => 'boi_',
        'fileCfg_ext' => '.config',
        'dir_pkg' => 'packages',
        'filePkg_ext' => '.boikg'
    );

    # Temp Addpkg :
    $data{'prefix_tmpflcfg'} = 'addpkg_';
    $data{'fileTmp_Cfg_ext'} = '.bpkg_tmp';

    # General Logs :
    $data{'dirlogs'} = $home_dir . "/.BlankOnDev/logs/";
    $data{'prefix_general_log'} = 'actv_';
    $data{'prefix_general_ext'} = '.boidevlogs';

    # Log Extension File :
    $data{'log_ext_out'} = '.boioutlog';
    $data{'log_ext_err'} = '.boierrlog';

    # Logs Branch :
    $data{'prefix_bzrbranch_log'} = 'logs_';

    # Logs bzr convert to git :
    $data{'prefix_bzrCgit_fllog'} = 'bzrCgit_logs_';

    # Logs for git remote :
    $data{'prefix_gitremote_fllog'} = 'gitremote_logs_';

    # Logs for gitpush :
    $data{'prefix_gitpush_fllog'} = 'gitpush_logs_';
    return \%data;
}
1;