package BlankOnDev::Migration::bazaar2GitHub::github;
use strict;
use warnings FATAL => 'all';

# Import :
use BlankOnDev::DataDev;
use BlankOnDev::syslog;
use BlankOnDev::Utils::file;
use Capture::Tiny::Extended 'capture';

# Version :
our $VERSION = '0.1003';

# Subroutine for git remote :
# ------------------------------------------------------------------------
sub git_remote {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $git = $allconfig->{'git'};
    my $git_url = $git->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $home_dir = $data_dev->{'home_dir'};
    my $dir_dev = $data_dev->{'dir_dev'};
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrCgit_fllog'};
    my $exit_filelog = $data_dev->{'bzrCgit_flext'};
    my $dir_pkggroup = $pkg->{'pkgs'}->{$pkg_name}->{'group'};
    my $dirOfPkgs = $dir_pkgs.'/'.$dir_pkggroup.'/'.$pkg_name;
    my $filename_logs = $prefix_log.$pkg_name.'_'.$build_rilis.$exit_filelog;
    my $locfile_logs = $logs_dir.$build_rilis.'/'.$filename_logs;

    # Git Logs :
    my $log_gitremote = BlankOnDev::syslog->git_remote($allconfig, $pkg_name);

    my $cmd_list = list_cmd();
    my $git_remote = $cmd_list->{'git'}->{'remote'};

    my $gitremote_url = $git_url.'/'.$pkg_name.'.git';
    system("cd $dirOfPkgs; $git_remote $gitremote_url &> $log_gitremote");

    # Read file
    my $read_file = BlankOnDev::Utils::file->read($gitremote_url);
    if ($read_file =~ m/(usage)\:\s(.*)/) {
        return(3);
    } else {
        rmdir $gitremote_url;
        return(1);
    }
}
# Subroutine for command git push handle :
# ------------------------------------------------------------------------
sub cmd_gitpush {
    my ($locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $cmd_gitpush) = @_;
    my $command = "cd $dirPkg_grp; $cmd_gitpush";
    my ($out, $err, $ret) = capture (
        sub {
            return system($command);
        },
        {
            stdout => $locfile_outlogs,
            stderr => $locfile_errlogs,
        }
    );
}
# Subroutine for get  :
# ------------------------------------------------------------------------
sub git_push {
    my ($self, $allconfig, $pkg_name) = @_;

    print "gitpush : $pkg_name\n";

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $git = $allconfig->{'git'};
    my $git_url = $git->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $home_dir = $data_dev->{'home_dir'};
    my $dir_dev = $data_dev->{'dir_dev'};
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_gitpush_fllog'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_pkggroup = $pkg->{'pkgs'}->{$pkg_name}->{'group'};
    my $dirOfPkgs = $dir_pkgs.'/'.$dir_pkggroup.'/'.$pkg_name;
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Remove file Logs :
    system("rm -rf ".$locfile_errlogs) if -e $locfile_errlogs;
    system("rm -rf ".$locfile_outlogs) if -e $locfile_outlogs;

    # Git Logs :
    my $log_gitpush = BlankOnDev::syslog->git_push($allconfig, $pkg_name);

    my $cmd_list = list_cmd();
    my $git_resetHead = $cmd_list->{'git'}->{'reset-head'};
    my $git_remote = $cmd_list->{'git'}->{'remote'};
    my $git_push = $cmd_list->{'git'}->{'push'};
    my $cmd_gitremote = $git_remote.' '.$git_url.'/'.$pkg_name.'.git';
    my $cmd_gitpush = "$git_resetHead; rm -rf .bzr; $cmd_gitremote; $git_push";
#    system("cd $dirOfPkgs; $git_push");
    cmd_gitpush($locfile_outlogs, $locfile_errlogs, $dirOfPkgs, $cmd_gitpush);

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_gitpush);
    if ($read_file =~ m/(fatal)\:\s(.*)/) {
        if ($3 =~ m/origin/) {
            return 3;
        } else {
            return 0;
        }
    }
    elsif ($read_file =~ m/^(error)\:\s+(.*)/) {
        if ($3 =~ m/(src)\s(refspec)\s(master)/) {
            return 3
        } else {
            return 0
        }
    }
    else {
        my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
        if ($read_errfile =~ m/(fatal)\:\s(.*)/) {
            return 3
        } else {
            return 1;
        }
    }
}
# Subroutine for command git push for new repository :
# ------------------------------------------------------------------------
sub general_cmd_gitpush {
    my ($dirpkg_group, $cmd_gitpush) = @_;
    my $command = "cd $dirpkg_group; $cmd_gitpush";
    my ($out, $err, $ret) = capture (
        sub {
            return system($command);
        },
    );
    print "OUTPUT : $out \n";
    print "OUTPUT  : $err \n";
}
# Subroutine for gitpush_new :
# ------------------------------------------------------------------------
sub gitpush_new {
    my ($self, $allconfig, $pkg_name, $commit) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $git = $allconfig->{'git'};
    my $git_url = $git->{'url'};
    my $dir_pkggroup = $pkg->{'pkgs'}->{$pkg_name}->{'group'};
    my $dirOfPkgs = $dir_pkgs.'/'.$dir_pkggroup.'/'.$pkg_name;

    my $cmd_list = list_cmd();
    my $git_init = $cmd_list->{'git'}->{'init'};
    my $git_add = $cmd_list->{'git'}->{'add'};
    my $git_commit = $cmd_list->{'git'}->{'commit'};
    my $git_resetHead = $cmd_list->{'git'}->{'reset-head'};
    my $git_remote = $cmd_list->{'git'}->{'remote'};
    my $git_push = $cmd_list->{'git'}->{'push'};
    my $cmd_git = '';
    $cmd_git .= "$git_init; ";
    $cmd_git .= "$git_add *; ";
    $cmd_git .= "$git_commit \"$commit\"; ";
    $cmd_git .= "$git_remote $git_url/$pkg_name.git; ";
    $cmd_git .= "$git_push";
    my $cmd_gitpush = "cd $dirOfPkgs; $cmd_git";

    # Action :
    general_cmd_gitpush($dirOfPkgs, $cmd_gitpush);
}
# Subroutine for command git push for new repository :
# ------------------------------------------------------------------------
sub cmd_re_gitpush {
    my ($locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $cmd_gitpush) = @_;
    my $command = "cd $dirPkg_grp; $cmd_gitpush";
    my ($out, $err, $ret) = capture (
        sub {
            return system($command);
        },
        {
            stdout => $locfile_outlogs,
            stderr => $locfile_errlogs,
        }
    );
}
# Subroutine for re-push git :
# ------------------------------------------------------------------------
sub repush_git {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $git = $allconfig->{'git'};
    my $git_url = $git->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_gitpush_fllog'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dir_pkggroup = $pkg->{'pkgs'}->{$pkg_name}->{'group'};
    my $dirOfPkgs = $dir_pkgs.'/'.$dir_pkggroup.'/'.$pkg_name;
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Remove file Logs :
    system("rm -rf ".$locfile_errlogs) if -e $locfile_errlogs;
    system("rm -rf ".$locfile_outlogs) if -e $locfile_outlogs;

    my $cmd_list = list_cmd();
    my $git_init = $cmd_list->{'git'}->{'init'};
    my $git_fetch = $cmd_list->{'git'}->{'fetch'};
    my $git_merge = $cmd_list->{'git'}->{'merge'};
    my $git_pull = $cmd_list->{'git'}->{'pull'};
    my $git_resetHead = $cmd_list->{'git'}->{'reset-head'};
    my $git_add = $cmd_list->{'git'}->{'add'};
    my $git_remote = $cmd_list->{'git'}->{'remote'};
    my $git_push = $cmd_list->{'git'}->{'push'};
    my $git_push_force = $cmd_list->{'git'}->{'push-force'};
    my $cmd_git = '';
    $cmd_git .= "$git_init; ";
#    $cmd_git .= "$git_fetch; ";
#    $cmd_git .= "$git_merge; ";
#    $cmd_git .= "$git_pull; ";
    $cmd_git .= "$git_resetHead; ";
    $cmd_git .= "rm -rf .bzr; ";
    $cmd_git .= "$git_add *; ";
    $cmd_git .= "$git_remote $git_url/$pkg_name.git; ";
    $cmd_git .= "$git_push; ";
    $cmd_git .= "$git_push_force";
    my $cmd_gitpush = "$cmd_git";
    my $cmd_gitpush_force = "cd $dirOfPkgs; $git_push_force";

    # Action :
    cmd_re_gitpush($locfile_outlogs, $locfile_errlogs, $dirOfPkgs, $cmd_gitpush);
    cmd_re_gitpush($locfile_outlogs, $locfile_errlogs, $dirOfPkgs, $cmd_gitpush_force);

    # Git Logs :
    my $log_gitpush = BlankOnDev::syslog->git_push($allconfig, $pkg_name);

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_gitpush);
    my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
    if ($read_file =~ m/(fatal)\:\s(.*)/) {
        if ($3 =~ m/origin/) {
            return 3;
        } else {
            return 0;
        }
    }
    elsif ($read_file =~ m/^(error)\:\s+(.*)/) {
        if ($3 =~ m/(src)\s(refspec)\s(master)/) {
            return 3
        } else {
            return 0
        }
    }
    else {
        if ($read_errfile =~ m/(fatal)\:\s(.*)/) {
            return 3
        }
        elsif ($read_errfile =~ m/(Everything)\s+(up\-to\-date)/) {
            return 1;
        }
        else {
            return 1;
        }
    }
    if ($read_file =~ m/(Everything)\s+(up\-to\-date)/) {
        return 1;
    } else {
        if ($read_errfile =~ m/(Everything)\s+(up\-to\-date)/) {
            return 1;
        }
    }
}

# Subroutine for git command :
# ------------------------------------------------------------------------
sub list_cmd {
    my %data = ();
    $data{'git'} = {
        'init' => 'git init',
        'add' => 'git add',
        'commit' => 'git commit -m',
        'reset-head' => 'git reset HEAD',
        'remote' => 'git remote add origin',
        'push' => 'git push -u origin master',
        'push-force' => 'git push origin master --force',
        'fetch' => 'git fetch origin',
        'merge' => 'git merge origin origin/master',
        'pull' => 'git pull origin',
    };
    return \%data;
}
1;