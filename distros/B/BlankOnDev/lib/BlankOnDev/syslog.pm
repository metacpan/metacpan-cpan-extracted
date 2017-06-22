package BlankOnDev::syslog;
use strict;
use warnings FATAL => 'all';

# Import :
use BlankOnDev::DataDev;
use BlankOnDev::Utils::file;

# Version :
our $VERSION = '0.1005';;

# Subroutine for bzr branch :
# ------------------------------------------------------------------------
sub bzr_branch {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrbranch_log'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }

    return $locfile_errlogs;
}
# Subroutine for list logs :
# ------------------------------------------------------------------------
sub bzr_convert_git {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrCgit_fllog'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }

    return $locfile_outlogs;
}
# Subroutine for git remote :
# ------------------------------------------------------------------------
sub git_remote {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_gitpush_fllog'};
    my $exit_filelog = $data_dev->{'logs_gitpush_ext'};
    my $filename_logs = $prefix_log.$pkg_name.'_'.$build_rilis.$exit_filelog;
    my $locfile_logs = $logs_dir.$build_rilis.'/'.$filename_logs;

    # Check Files :
    unless (-e $locfile_logs) {
        system("touch $locfile_logs");
    }
    return $locfile_logs;
}
# Subroutine for git push :
# ------------------------------------------------------------------------
sub git_push {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_gitpush_fllog'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }
    return $locfile_outlogs;
}
# Subroutine for bzr2git branch :
# ------------------------------------------------------------------------
sub bzr2git_branch {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_branchLg'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }

    return $locfile_errlogs;
}
# Subroutine for bzr2git bzr convert git :
# ------------------------------------------------------------------------
sub bzr2git_bzrCgit {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_bzr_cgit'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }

    return $locfile_errlogs;
}
# Subroutine for bzr2git git-push :
# ------------------------------------------------------------------------
sub bzr2git_gitpush {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_gitpush'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }
    return $locfile_outlogs;
}
# Subroutine for bzr2git re-git push :
# ------------------------------------------------------------------------
sub bzr2git_reGit_push {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_regit_push'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_logFile = $logs_dir.$build_rilis.'/';
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Check Files :
    unless (-e $locfile_outlogs) {
        BlankOnDev::Utils::file->create($filename_outlogs, $dir_logFile, '');
    }
    unless (-e $locfile_errlogs) {
        BlankOnDev::Utils::file->create($filename_errlogs, $dir_logFile, '');
    }
    return $locfile_outlogs;
}
# Subroutine for general logs :
# ------------------------------------------------------------------------
sub general_logs {
    my ($self, $allconfig, $msg) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $home_dir = $data_dev->{'home_dir'};
    my $dir_dev = $data_dev->{'dir_dev'};
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_general_log'};
    my $exit_filelog = $data_dev->{'prefix_general_ext'};
    my $filename_logs = $prefix_log.$build_rilis.$exit_filelog;
    my $locfile_logs = $logs_dir.$build_rilis.'/'.$filename_logs;

    # Check file Logs :
    unless (-e $locfile_logs) {
        system("touch $locfile_logs")
    }

    # Add New Logs :
    system("echo $msg >> $locfile_logs");
}
1;