package BlankOnDev::Migration::bazaar2GitHub::bazaar;
use strict;
use warnings FATAL => 'all';

# Import :
use BlankOnDev::DataDev;
use BlankOnDev::syslog;
use BlankOnDev::Utils::file;
use BlankOnDev::command;
use Capture::Tiny::Extended 'capture';

# Version :
our $VERSION = '0.1005';;

# Subrouitne for cmd bzr branch :
# ------------------------------------------------------------------------
sub cmd_bzrBranch {
    my ($type, $locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $dest_dir, $bzr_branch, $branch_url) = @_;
    my $command;
    if ($type eq 'rm') {
        $command = "rm -rf $dest_dir; cd $dirPkg_grp; $bzr_branch $branch_url $dest_dir";
    } else {
        $command = "cd $dirPkg_grp; $bzr_branch $branch_url $dest_dir";
    }

    my ($out, $err, $ret) = capture (
        sub {
            return system($command);
        },
        {
            stdout => $locfile_outlogs,
            stderr => $locfile_errlogs,
        }
    );
#    print $err if $res;
}
# End of Subroutine for bazaar format repo to githb format repo.
# ===========================================================================================================

# Subroutine for branch via bazaar :
# ------------------------------------------------------------------------
sub branch {
    my ($self, $type, $allconfig, $input_group, $pkg_name) = @_;

#    print "PkgName :$pkg_name\n";

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $bzr = $allconfig->{'bzr'};
    my $bzr_url = $bzr->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrbranch_log'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dirPkg_grp = $dir_pkgs.'/'.$input_group;
    my $dest_dir = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Remove file Logs :
    system("rm -rf ".$locfile_errlogs) if (-e $locfile_errlogs);
    system("rm -rf ".$locfile_outlogs) if (-e $locfile_outlogs);

    # Bzr branch Logs :
    my $log_branch = BlankOnDev::syslog->bzr_branch($allconfig, $pkg_name);
    my $re_branch;

    my $cmd_list = BlankOnDev::command::bzr();
    my $bzr_branch = $cmd_list->{'bzr'}->{'branch'};
    my $branch_url = $bzr_url.'/'.$pkg_name;

    # Check Dir :
    if (-d $dest_dir) {
        if ($type ne 'no' and $type eq 'rm') {
            cmd_bzrBranch('rm', $locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $dest_dir, $bzr_branch, $branch_url);
            print "Action re-branch for packages \"$pkg_name\" \n";
        } else {
            print "Action branch for packages \"$pkg_name\" \n";
        }
    } else {
        cmd_bzrBranch($type, $locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $dest_dir, $bzr_branch, $branch_url);
        print "\n";
        print "Branch : \"$pkg_name\"\n";
    }
    #    system("cd $dirPkg_grp; $bzr_branch $branch_url $dest_dir %> $log_branch");
    #    open (my $file_branch, '>>', $log_branch) or die "Could not open file: $!";
    #    my $output = "cd $dirPkg_grp; $bzr_branch $branch_url $dest_dir";
    #    print $file_branch `$output`;

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_branch);
    if ($read_file =~ m/(bzr)\:\s+(ERROR)\:\s+(.*)\:/) {
        if ($3 eq 'Not a branch') {
            return 3;
        }
        elsif ($3 eq 'Already a branch') {
            return 2;
        } else {
            my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
            if ($read_errfile =~ m/(bzr)\:\s+(ERROR)\:\s+(.*)\:/) {
                return 3;
            } else {
                return 0;
            }
        }
    }
    else {
        system("rm -rf $locfile_outlogs");
        system("rm -rf $locfile_errlogs");

        # Bzr branch Logs :
#        BlankOnDev::syslog->bzr_branch($allconfig, $pkg_name);
        return 1;
    }
}
# Subroutine for bazaar format repo to githb format repo :
# ------------------------------------------------------------------------
sub cmd_bzrConvertGit {
    my ($locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $bzrCgit) = @_;
    my $command = "cd $dirPkg_grp; $bzrCgit";
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
# Subroutine for check Bzr Branch :
# ------------------------------------------------------------------------
sub bzr_convert_git {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $bzr = $allconfig->{'bzr'};
    my $bzr_url = $bzr->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrCgit_fllog'};
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

    # Bazaar convert git Logs :
    my $log_bzrCgit = BlankOnDev::syslog->bzr_convert_git($allconfig, $pkg_name);

    my $cmd_list = BlankOnDev::command::bzr();;
    my $bzr_export = $cmd_list->{'bzr'}->{'bzr-export'};
    my $bzr_import = $cmd_list->{'bzr'}->{'bzr-fast-import'};
    my $cmd_bzrCgit = "git init; $bzr_export $dirOfPkgs | $bzr_import";
#    system("cd $dirOfPkgs; $cmd_bzrCgit %> $log_bzrCgit");
    cmd_bzrConvertGit($locfile_outlogs, $locfile_errlogs, $dirOfPkgs, $cmd_bzrCgit);

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_bzrCgit);
    if ($read_file =~ m/(fatal)\:\s+(.*)/) {
        return 0;
    } else {
        my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
        if ($read_errfile =~ m/(fatal)\:\s+(.*)/) {
            return 0;
        } elsif ($read_errfile =~ m/(bzr)\:\s+(ERROR)\:/) {
            return 2;
        } else {
            return 1;
        }
    }
}
# Subroutine for bzr2git_branch :
# ------------------------------------------------------------------------
sub bzr2git_branch {
    my ($self, $allconfig, $pkg_name, $input_group) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $bzr = $allconfig->{'bzr'};
    my $bzr_url = $bzr->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_branchLg'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};
    my $dirPkg_grp = $dir_pkgs.'/'.$input_group;
    my $dest_dir = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;
    my $filename_outlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_out_log;
    my $filename_errlogs = $prefix_log.$pkg_name.'_'.$build_rilis.$ext_err_log;
    my $locfile_outlogs = $logs_dir.$build_rilis.'/'.$filename_outlogs;
    my $locfile_errlogs = $logs_dir.$build_rilis.'/'.$filename_errlogs;

    # Remove file Logs :
    system("rm -rf ".$locfile_errlogs) if (-e $locfile_errlogs);
    system("rm -rf ".$locfile_outlogs) if (-e $locfile_outlogs);

    # Bzr branch Logs :
    my $log_branch = BlankOnDev::syslog->bzr2git_branch($allconfig, $pkg_name);
    my $re_branch;

    my $cmd_list = BlankOnDev::command::bzr();
    my $bzr_branch = $cmd_list->{'bzr'}->{'branch'};
    my $branch_url = $bzr_url.'/'.$pkg_name;

    # Check Dir :
    if (-d $dest_dir) {
        cmd_bzrBranch('rm', $locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $dest_dir, $bzr_branch, $branch_url);
        print "Action re-branch for packages \"$pkg_name\" \n";
    } else {
        cmd_bzrBranch('no', $locfile_outlogs, $locfile_errlogs, $dirPkg_grp, $dest_dir, $bzr_branch, $branch_url);
        print "Branch : \"$pkg_name\"\n";
    }

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_branch);
    if ($read_file =~ m/(bzr)\:\s+(ERROR)\:\s+(.*)\:/) {
        if ($3 eq 'Not a branch') {
            return 3;
        }
        elsif ($3 eq 'Already a branch') {
            return 2;
        } else {
            my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
            if ($read_errfile =~ m/(bzr)\:\s+(ERROR)\:\s+(.*)\:/) {
                return 3;
            } else {
                return 0;
            }
        }
    }
    else {
        system("rm -rf $locfile_outlogs");
        system("rm -rf $locfile_errlogs");
        return 1;
    }
}
# Subroutine for convert format bazaar to git :
# ------------------------------------------------------------------------
sub bzr2git_bzr_cgit {
    my ($self, $allconfig, $pkg_name) = @_;

    # Get current Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $pkg->{'dirpkg'};
    my $bzr = $allconfig->{'bzr'};
    my $bzr_url = $bzr->{'url'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzr2git_bzr_cgit'};
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

    # Bazaar convert git Logs :
    my $log_bzrCgit = BlankOnDev::syslog->bzr2git_bzrCgit($allconfig, $pkg_name);

    my $cmd_list = BlankOnDev::command::bzr();;
    my $bzr_export = $cmd_list->{'bzr'}->{'bzr-export'};
    my $bzr_import = $cmd_list->{'bzr'}->{'bzr-fast-import'};
    my $cmd_bzrCgit = "git init; $bzr_export $dirOfPkgs | $bzr_import";
    #    system("cd $dirOfPkgs; $cmd_bzrCgit %> $log_bzrCgit");
    cmd_bzrConvertGit($locfile_outlogs, $locfile_errlogs, $dirOfPkgs, $cmd_bzrCgit);

    # Read File :
    my $read_file = BlankOnDev::Utils::file->read($log_bzrCgit);
    if ($read_file =~ m/(fatal)\:\s+(.*)/) {
        return 0;
    } else {
        my $read_errfile = BlankOnDev::Utils::file->read($locfile_errlogs);
        if ($read_errfile =~ m/(fatal)\:\s+(.*)/) {
            return 0;
        } elsif ($read_errfile =~ m/(bzr)\:\s+(ERROR)\:/) {
            return 2;
        } else {
            return 1;
        }
    }
}
# Subroutine for Bazaar activies logs :
# ------------------------------------------------------------------------
sub bzr_activities {
    my ($self, $allconfig, $input_group, $input_pkg, $result_actv, $type) = @_;

    # Get current Config :
    my $curr_timezone = $allconfig->{'timezone'};
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $loc_pkg = $curr_pkg.'/'.$input_group.'/'.$input_pkg;

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};

    # Branch Logs :
    my $prefix_log = $data_dev->{'prefix_fllog'};
    my $exit_filelog = $data_dev->{'fileLog_ext'};
    my $filename_logs = $prefix_log.$input_pkg.'_'.$build_rilis.$exit_filelog;
    my $locfile_logs = $logs_dir.$build_rilis.'/'.$filename_logs;

    # For Type :
    my $data_msg = '';
    if ($type eq 'branch') {
        $data_msg = "Bazaar Branch | $loc_pkg" if $result_actv == 1;
        $data_msg = "Bazaar Branch | $locfile_logs" if $result_actv == 0;
        $data_msg = "Bazaar Branch | $loc_pkg" if $result_actv == 2;
        $data_msg = "Bazaar Branch | $locfile_logs" if $result_actv == 3;
    } else {
        $data_msg = "Bzr convert Git | $loc_pkg" if $result_actv == 1;
        $data_msg = "Bzr convert Git | $locfile_logs" if $result_actv == 0;
    }

    # Define $result_actv :
    my $code_actv = '';
    $code_actv = '[success]' if $result_actv == 1;
    $code_actv = '[error]' if $result_actv == 0;
    $code_actv = '[info]' if $result_actv == 2;
    $code_actv = '[warning]' if $result_actv == 3;

    # Get DateTime :
    my $timestamp = time();
    my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
            'date'     => '-',
            'time'     => ':',
            'datetime' => ' ',
            'format'   => 'DD-MM-YYYY hms'
        });
    my $time_logs = $get_dataTime->{'custom'};

    # Create Msg Logs :
    my $msg = "$time_logs";
    $msg .= $msg.sprintf("%-2s %-5s %-4s", $time_logs, $input_group, $input_pkg, $data_msg);

    # Create Logs :
    BlankOnDev::syslog->general_logs($allconfig, $msg);
}
1;