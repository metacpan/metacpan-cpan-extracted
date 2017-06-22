package BlankOnDev::Migration::bazaar2GitHub;
use strict;
use warnings FATAL => 'all';

# Import Module :
use Data::Dumper;
use JSON;
use JSON::XS;
use Term::ReadKey;
use Hash::MultiValue;
use BlankOnDev::DateTime;
use BlankOnDev::Utils::file;
use BlankOnDev::DataDev;
use BlankOnDev::HTTP::request;
use BlankOnDev::Migration::bazaar2GitHub::bazaar;
use BlankOnDev::Migration::bazaar2GitHub::github;
use Text::SimpleTable::AutoWidth;

# Version :
our $VERSION = '0.1005';

# Subroutine for get time :
# ------------------------------------------------------------------------
sub get_DateTime {
    my ($self, $allconfig) = @_;

    # Get data current config :
    my $curr_timezone = $allconfig->{'timezone'};
    my $timestamp = time();
    my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
            'date' => '-',
            'time' => ':',
            'datetime' => ' ',
            'format' => 'DD-MM-YYYY hms'
        });
    my $result = $get_dataTime->{'custom'};
    return $result;
}
# Subroutine for action re migration :
# ------------------------------------------------------------------------
sub action_re_migration {
    my ($self, $allconfig, $pkg_name, $pkg_group, $tmp_pkg, $time_branch) = @_;

    # Define hash or scalar :
    my %data = ();
    my $action_branch;
    my $action_bzrCgit;
    my $action_re_gtipush;
    my $action_check;
    my $time_gitpush;

    # Get data current config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dirpkg = $curr_pkg->{'dirpkg'};
    my $locdir_pkg = $dirpkg.'/'.$pkg_group.'/'.$pkg_name;

    system("rm -rf $locdir_pkg");
    system("mv -f $tmp_pkg $locdir_pkg");
    $action_bzrCgit = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr2git_bzr_cgit($allconfig, $pkg_name);
    if ($action_bzrCgit eq 1) {
        print "[success] re-Action \"bzr convert git -> $pkg_name\" $action_bzrCgit\n";
        $action_re_gtipush = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_reGitpush($allconfig, $pkg_name);
        if ($action_re_gtipush eq 1) {
            $time_gitpush = $self->get_DateTime($allconfig);
            print "[success] Action \"re-git push -> $pkg_name\" \n";
            $action_check = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_git_check($allconfig, $pkg_name);
            if ($action_check ne 'undef') {
                print "[success] Action \"git check -> $pkg_name\" $action_check\n";
            } else {
                print "[error] Action \"git check -> $pkg_name\" $action_check\n";
            }
        } else {
            print "[error] Action \"re-git push -> $pkg_name\" | $action_re_gtipush\n";
        }
    } else {
        print "[error] Action \"bzr convert git -> $pkg_name\" | $action_bzrCgit\n";
    }

    # Prepare Configure :
    my $prepare_config = prepare_config();
    my $result_cfg = $prepare_config->{'bzr2git'}($allconfig, $pkg_name, $action_branch, $action_bzrCgit, $action_re_gtipush, $action_check, $time_branch, $time_gitpush);

    # Place :
    $data{'bzr-cgit'} = $action_bzrCgit;
    $data{'git-push'} = $action_re_gtipush;
    $data{'git-check'} = $action_check;
    $data{'result-cfg'} = $result_cfg;
    return \%data;
}
# Subroutine for action migration :
# ------------------------------------------------------------------------
sub bzr2git_action_migration {
    my ($self, $allconfig, $list_pkg) = @_;

    # Define scalar :
    my $action_branch;
    my $action_bzrCgit;
    my $action_gitpush;
    my $action_check;
    my $time_branch;
    my $time_gitpush;

    # Get data current config :
    my $curr_timezone = $allconfig->{'timezone'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dirpkg = $curr_pkg->{'dirpkg'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_tmp = $data_dev->{'dir_tmp'};

    # For List Packages :
    my @list_packages = @{$list_pkg};

    # While loop to migration packages :
    my $i_p = 0;
    my $until_p = scalar @list_packages;
    my $pkg_name;
    my $pkg_group;
    my $result_cfg = $allconfig;
    while ($i_p < $until_p) {
        $pkg_name = $list_packages[$i_p]->{'name'};
        $pkg_group = $list_packages[$i_p]->{'group'};

        my $locdir_pkg = $dirpkg.'/'.$pkg_group.'/'.$pkg_name;
        my $locdir_tmp_pkg = $dir_tmp.$pkg_group.'_'.$pkg_name;

        $action_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr2git_branch($allconfig, $pkg_name, $pkg_group);
        if ($action_branch eq 1) {
            $time_branch = $self->get_DateTime($allconfig);
            system("cp -rf $locdir_pkg $locdir_tmp_pkg");
            print "[success] Action \"bzr branch -> $pkg_name\" : $action_branch\n";
            $action_bzrCgit = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr2git_bzr_cgit($allconfig, $pkg_name);
            if ($action_bzrCgit eq 1) {
                print "[success] Action \"bzr convert git -> $pkg_name\" $action_bzrCgit\n";
                $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_gitpush($allconfig, $pkg_name);
                if ($action_gitpush eq 1) {
                    $time_gitpush = $self->get_DateTime($allconfig);
                    print "[success] Action \"git push -> $pkg_name\" $action_gitpush\n";
                    $action_check = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_git_check($allconfig, $pkg_name);
                    if ($action_check ne 'undef') {
                        print "[success] Action \"git check -> $pkg_name\" $action_check\n";
                    } else {
                        print "[error] Action \"git check -> $pkg_name\" $action_check\n";
                    }
                } else {
                    # Re migration :
                    my $action_reMig = $self->action_re_migration($result_cfg, $pkg_name, $pkg_group, $locdir_tmp_pkg, $time_branch);
                    $action_bzrCgit = $action_reMig->{'bzr-cgit'};
                    $action_gitpush = $action_reMig->{'git-push'};
                    $action_check = $action_reMig->{'git-check'};
                    $result_cfg = $action_reMig->{'result-cfg'};
                }
            } else {
                print "[error] Action \"bzr convert git -> $pkg_name\" | $action_branch\n";
            }
        } else {
            print "[error] Action \"bzr branch -> $pkg_name\" | $action_branch\n";
        }
        print "----" x 18 . "\n";

        # Prepare Configure :
        my $prepare_config = prepare_config();
        $result_cfg = $prepare_config->{'bzr2git'}($result_cfg, $pkg_name, $action_branch, $action_bzrCgit, $action_gitpush, $action_check, $time_branch, $time_gitpush);

        # Save configure :
        my $saveConfig = save_newConfig();
        $saveConfig->{'bzr2git'}($result_cfg);
        $i_p++;
    }
}
# Subroutine for action migration one package  :
# ------------------------------------------------------------------------
sub action_bzr2git_single {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $pkg_name;
    my $action_branch;
    my $action_bzrCgit;
    my $action_gitpush;
    my $action_check;
    my $time_branch;
    my $time_gitpush;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dirpkg = $curr_pkg->{'dirpkg'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_tmp = $data_dev->{'dir_tmp'};

    # Form enter packages name ;
    print "\n";
    print "Enter packages name : ";
    chomp($pkg_name = <STDIN>);
    if ($pkg_name ne '') {
        print "\n";
        # Check Input Packages :
        if (exists $pkg_list->{$pkg_name}) {
            my $pkg_group = $pkg_list->{$pkg_name}->{'group'};

            my $locdir_pkg = $dirpkg.'/'.$pkg_group.'/'.$pkg_name;
            my $locdir_tmp_pkg = $dir_tmp.$pkg_group.'_'.$pkg_name;
            my $result_cfg = $allconfig;

            $action_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr2git_branch($allconfig, $pkg_name, $pkg_group);
            if ($action_branch eq 1) {
                $time_branch = $self->get_DateTime($allconfig);
                system("cp -rf $locdir_pkg $locdir_tmp_pkg");
                print "[success] Action \"bzr branch -> $pkg_name\" : $action_branch\n";
                $action_bzrCgit = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr2git_bzr_cgit($allconfig, $pkg_name);
                if ($action_bzrCgit eq 1) {
                    print "[success] Action \"bzr convert git -> $pkg_name\" $action_bzrCgit\n";
                    $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_gitpush($allconfig, $pkg_name);
                    if ($action_gitpush eq 1) {
                        $time_gitpush = $self->get_DateTime($allconfig);
                        print "[success] Action \"git push -> $pkg_name\" $action_gitpush\n";
                        $action_check = BlankOnDev::Migration::bazaar2GitHub::github->bzr2git_git_check($allconfig, $pkg_name);
                        if ($action_check ne 'undef') {
                            print "[success] Action \"git check -> $pkg_name\" $action_check\n";
                        } else {
                            print "[error] Action \"git check -> $pkg_name\" $action_check\n";
                        }
                    } else {
                        # Re migration :
                        my $action_reMig = $self->action_re_migration($result_cfg, $pkg_name, $pkg_group, $locdir_tmp_pkg);
                        $action_bzrCgit = $action_reMig->{'bzr-cgit'};
                        $action_gitpush = $action_reMig->{'git-push'};
                        $action_check = $action_reMig->{'git-check'};
                        $result_cfg = $action_reMig->{'result-cfg'};
                    }
                } else {
                    print "[error] Action \"bzr convert git -> $pkg_name\" | $action_branch\n";
                }
            } else {
                print "[error] Action \"bzr branch -> $pkg_name\" | $action_branch\n";
            }

            # Prepare Configure :
            my $prepare_config = prepare_config();
            $result_cfg = $prepare_config->{'bzr2git'}($allconfig, $pkg_name, $action_branch, $action_bzrCgit, $action_gitpush, $action_check, $time_branch, $time_gitpush);

            # Save configure :
            my $saveConfig = save_newConfig();
            $saveConfig->{'bzr2git'}($result_cfg);
            print "\n";
            print "====" x 5 . " Migration packages \"$pkg_name\" has been finished ";
            print "====" x 5 . "\n\n";
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Packages \"$pkg_name\" is not exists...\n";
        }
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Please Enter name package for Migration !!!\n";
        exit 0;
    }
}
# Subroutine for get amount of packages on group :
# ------------------------------------------------------------------------
sub amount_pkg {
    my ($self, $allconfig, $input_group) = @_;

    # Get data current config :
    my $curr_build = $allconfig->{'build'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_pkg = $curr_pkg->{'pkgs'};

    # While loop to get list packages :
    my $i = 0;
    my @pre_data_pkg = ();
    while (my ($key, $value) = each %$list_pkg) {
        my $pkg_group = $list_pkg->{$key}->{'group'};
        if ($pkg_group eq $input_group) {
            $pre_data_pkg[$i] = $list_pkg->{$key};
        }
        $i++;
    }
    my @data_pkg = grep($_, @pre_data_pkg);
    my $amount_pkg = scalar keys(@data_pkg);
    return $amount_pkg;
}
# Subroutine for get list group and amount packages :
# ------------------------------------------------------------------------
sub bzr2git_get_list_group_amount_pkg {
    my ($self, $allconfig) = @_;
    my %data = ();

    # Get data current config :
    my $curr_build = $allconfig->{'build'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_group = $curr_pkg->{'group'};
    my $size_list_group = scalar keys(%{$list_group});

    # Check count list packages group :
    if ($size_list_group > 0) {

        # While loop for list packages group :
        my $i = 0;
        my @pre_list_pkggrp = ();
        while (my ($key, $value) = each %$list_group) {
            $pre_list_pkggrp[$i] = $key;
            $i++;
        }

        # Remove "undef" value on array :
        my @list_pkggrp = grep($_, @pre_list_pkggrp);

        $i = 0;
        my %data_group = ();
        my $choice = '';
        my $until = scalar @list_pkggrp;
        my $num = 0;
        my $amount_pkg;
        while ($i < $until) {
            $amount_pkg = $self->amount_pkg($allconfig, $list_pkggrp[$i]);
            $num = $i + 1;
            $data_group{$num} = $list_pkggrp[$i];
            $choice .= sprintf("$num. %-25s %s\n", "$list_pkggrp[$i]", "[$amount_pkg]");
            $i++;
        }
        $data{'data'} = \%data_group;
        $data{'choice'} = $choice;
        return \%data;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
        exit 0;
    }
}
# Subroutine for action migration by group :
# ------------------------------------------------------------------------
sub action_bzr2git2 {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $form_group;

    # Get data current config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $data_list_grp = $self->bzr2git_get_list_group_amount_pkg($allconfig);
    my $choice_grp = $data_list_grp->{'data'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_tmp = $data_dev->{'dir_tmp'};

    # Form Group name :
    print "\n";
    print "Choose packages group : \n";
    print "---" x 18 . "\n";
    print $data_list_grp->{'choice'};
    print "---" x 18 . "\n";
    print "Enter number of group name : ";
    chomp($form_group = <STDIN>);
    if (exists $choice_grp->{$form_group}) {
        my $input_group = $choice_grp->{$form_group};

        # Check group :
        my $list_group = $self->filter_listpkg_based_group($allconfig, $input_group);
        if ($list_group->{'result'} == 1) {
            my @list_all_pkg = @{$list_group->{'data'}};

            print "\n";
            print "Doing migration ...\n\n";

            # Action Migration :
            $self->bzr2git_action_migration($allconfig, \@list_all_pkg);

            print "\n";
            print "====" x 5 . " Migration all packages in group \"$input_group\" has been finished ";
            print "====" x 5 . "\n\n";
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages in list on group \"$input_group\".\n";
            print "Please run command \"boidev bzr2git addpkg\" to add new packages in group \"$input_group\",\n";
            print "or \"boidev bzr2git addpkg-file\" to add new packages in group \"$input_group\".\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : Enter number choice\n";
        print "====" x 18 . "\n";
        print "Please enter number choice. \n\n";
        exit 0;
    }
}
# Subroutine for get amount of packages on group :
# ------------------------------------------------------------------------
sub bzr2git_list_group {
    my ($self, $allconfig) = @_;

    # Define hash :
    my %data = ();
    my $data_list = '';

    # Get list group :
    my $get_list_group = $self->list_all_pkg_group($allconfig);
    my @list_group = @{$get_list_group->{'data'}};

    # While loop to get list packages group :
    my $i = 0;
    my $until = scalar keys(@list_group);
    my $num = 0;
    my $amount_pkg = '';
    my @pre_dataGroup = ();
    while ($i < $until) {
        $amount_pkg = $self->amount_pkg($allconfig, $list_group[$i]);
        if ($amount_pkg > 0) {
            $num = $num + 1;
            $data_list .= sprintf("$num. %-20s %s\n", "$list_group[$i]", "[$amount_pkg]");
            $pre_dataGroup[$num] = $list_group[$i];
        }
        $i++;
    }
    my @data_group = grep($_, @pre_dataGroup);

    $data{'msg'} = $data_list;
    $data{'data'} = \@data_group;
    return \%data;
}
# Subroutine for action migration all packages :
# ------------------------------------------------------------------------
sub action_bzr2git1 {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $confirm_form;
    my $confirm_form_pkg;
    my $data_confirm = 0;
    my $data_confirm_pkg = 0;

    # Get list group :
    my $getList_group = $self->bzr2git_list_group($allconfig);
    my $list = $getList_group->{'msg'};
    my @list_groups = @{$getList_group->{'data'}};

    # Form Confirm :
    print "\n";
    print "You want migration all packages with automatically ? [y or n] ";
    chomp($confirm_form = <STDIN>);
    if ($confirm_form eq 'y' or $confirm_form eq 'Y') {
        $data_confirm = 1;
        $data_confirm_pkg = 1;
    } else {
        $data_confirm = 0;
    }

    print "\n";
    print "List Group packages to Migration : \n";
    print "---" x 15 . "\n";
    print $list;
    print "---" x 15 . "\n";

    # While loop to migration :
    my $i = 0;
    my $until = scalar @list_groups;
    my $amount_pkg = 0;
    my $get_list_pkgs;
    my @list_packages;
    my $data_groups;
    while ($i < $until) {
        $data_groups = $list_groups[$i];
        $get_list_pkgs = $self->filter_listpkg_based_group($allconfig, $data_groups);
        $amount_pkg = $self->amount_pkg($allconfig, $data_groups);
        @list_packages = @{$get_list_pkgs->{'data'}};

        # Check Confirm :
        if ($data_confirm == 1) {

            print "\n";
            print "Action Migration for all packages in group \"$data_groups [$amount_pkg]\" \n";
            print "----" x 18 . "\n";

            # Action Migration :
            $self->bzr2git_action_migration($allconfig, \@list_packages);
        }
        if ($data_confirm == 0) {
            print "\n";
            print "You want to migration all packages in group \"$data_groups [$amount_pkg]\" ? [y or n] ";
            chomp($confirm_form_pkg = <STDIN>);
            if ($confirm_form_pkg eq 'y' or $confirm_form_pkg eq 'Y') {
                print "\n";
                print "[migration] All packages in group \"$data_groups\" \n";
                print "----" x 18 . "\n";

                # Action Migration :
                $self->bzr2git_action_migration($allconfig, \@list_packages);
            } else {
                print "\n";
                print "[no-migration] All packages in group \"$data_groups\" \n";
            }
        }
        $i++;
    }
    print "\n";
    print "====" x 5 . " Migration packages has been finished ";
    print "====" x 5 . "\n\n";
}
# Action Bzr2git :
# ------------------------------------------------------------------------
sub action_bzr2git {
    my ($self, $allconfig) = @_;
    my $choose_act;

    # For Action :
    my $switch_act = {
        '1' => 'action_bzr2git1',
        '2' => 'action_bzr2git2',
        '3' => 'action_bzr2git_single'
    };

    # Form action migration :
    print "\n";
    print "-----" x 15 . "\n";
    print " Choose Action : \n";
    print "-----" x 15 . "\n";
    print "1. All Packages\n";
    print "2. Specific Group Packages\n";
    print "3. Single Packages\n";
    print "Answer: ";
    chomp($choose_act = <STDIN>);
    if (exists $switch_act->{$choose_act}) {
        my $subr_act = $switch_act->{$choose_act};
        $self->$subr_act($allconfig);
    } else {
        print "\n";
        print "System automatic choose to specific group name ...\n";
        $self->action_bzr2git2($allconfig);
    }
}
# Subroutine for option "bzr2git" :
# ------------------------------------------------------------------------
sub _bzr2git {
    my ($self, $allconfig) = @_;

    my $options2 = {
        'addpkg-group' => '_addpkg_group',
        'addpkg' => '_addpkg',
        'addpkg-file' => '_addpkg_file',
        'rename-pkg-group' => '_rename_group_pkg',
        'remove-pkg-group' => '_remove_group_pkg',
        'remove-pkg' => '_removepkg',
        'list-pkg' => '_list_pkg',
        'list-pkg-group' => '_list_pkggrp',
        'search-pkg' => '_search_pkg',
        'branch' => '_branch',
        'bzr-cgit' => '_bzr_cgit',
        'git-push' => '_gitpush',
        'git-push-new' => '_gitpush_new',
        'git-check' => '_git_check',
        're-branch' => '_re_branch',
        're-gitpush' => '_re_gitpush',
    };
    
    my $options3 = {
        'help' => 'usage_arg_3',
    };

    # Check Argv :
    my $arg_len = scalar @ARGV;
    if ($arg_len > 1) {
        if ($arg_len == 2) {
            if ($allconfig->{'bzr'}->{'url'} eq '' or $allconfig->{'git'}->{'url'} eq '') {
                print "\n";
                print "Warning : \n";
                print "=====" x 16 . "\n";
                print "Please run command \"boidev mig_prepare\" to complete config this application !!! \n\n";
                exit 0;
            } else {
                # Check Option :
                if (exists $options2->{$ARGV[1]}) {
                    my $sub_act = $options2->{$ARGV[1]};
                    $self->$sub_act($allconfig);
                } else {
                    print "\n";
                    print "Warning : \n";
                    print "=====" x 16 . "\n";
                    print "Error: Undefined arguments. You must valid input for argument two.\n";
                    $self->usage();
                }
            }
        }
        elsif ($arg_len == 3) {
            if (exists $options2->{$ARGV[1]}) {
                if (exists $options3->{$ARGV[2]}) {
                    my $sub_act = $options3->{$ARGV[2]};
                    $self->$sub_act($allconfig);
                } else {
                    my $sub_act = $options2->{$ARGV[1]};
                    $self->$sub_act($allconfig);
                }
            } else {
                print "\n";
                print "Warning : \n";
                print "=====" x 16 . "\n";
                print "Error: Undefined arguments. You must valid input for argument two.\n";
                $self->usage();
            }
        }
        else {
            print "\n";
            print "Warning : \n";
            print "=====" x 16 . "\n";
            print "Error: Undefined arguments. You must input 1 - 3 arguments for command [boidev].\n";
            exit 0;
        }
    }
    elsif ($arg_len == 1) {
        $self->action_bzr2git($allconfig);
    }
    else {
        print "\n";
        print "Warning : \n";
        print "=====" x 16 . "\n";
        print "Error : Undefined arguments. You must input arguments for command [boidev].\n";
        $self->usage();
    }
}
# Subroutine for check exists group :
# ------------------------------------------------------------------------
sub check_exists_group {
    my ($self, $type, $group_cfg, $new_group) = @_;

    my %data = ();
    my $result = 1;
    my $list_grp = '';
    my $check_list = 0;
    my $count = scalar keys(%{$group_cfg});

    if ($type eq 'list') {
        if ($count > 0) {
            while (my ($key, $value) = each %{$group_cfg}) {
                $list_grp .= "- $key\n";
            }
            $check_list = 1;
        } else {
            $check_list = 0;
        }
        $result = 1;
    } else {
        print "Jumlah $count\n";
        if ($count >= 1) {
            while (my ($key, $value) = each %{$group_cfg}) {
                $list_grp .= "- $key\n";
                if (exists $group_cfg->{$new_group}) {
                    $result = 0;
                } else {
                    $result = 1;
                }
            }
            $check_list = 1;
        } else {
            $list_grp = '';
            $check_list = 1;
        }
    }
    $data{'result'} = $result;
    $data{'check'} = $check_list;
    $data{'data'} = $list_grp;

    return \%data;
}
# Subroutine for add packages group :
# ------------------------------------------------------------------------
sub _addpkg_group {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $input_new_grp = '';
    my $new_grp = '';

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $dir_pkgs = $data_dev->{'dir_pkg'};

    # get data current pkg :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check List Group :
        my $check_list_group = $self->check_exists_group('list', $curr_pkg->{'group'}, '');

        # Form add group :
        if ($check_list_group->{result} == 1) {
            print "\n";
            print "Exists Groups : \n";
            print "---" x 18 . "\n";
            print $check_list_group->{'data'};
            print "\n\n";
        }
        print "Enter new group name : ";
        chomp($input_new_grp = <STDIN>);
        if ($input_new_grp ne '') {
            if ($input_new_grp =~ m/^[A-Za-z0-9\-\_]+$/) {
                $new_grp = $input_new_grp;
            }
            else {
                $new_grp = '';
                print "\n";
                print "Name of group package must combination : \n";
                print "- Alphabetic\n";
                print "- Alphabetic Numberic\n";
                print "- Alpabetic Numberic and [_] character or/and [-] character\n";
                print "\n";
                exit 0;
            }

            # Check Group Name :
            my $check_group = $self->check_exists_group('check', $curr_pkg->{'group'}, $new_grp);
            if ($check_group->{'result'} == 1) {
                my $locdir_pkg = $dir_dev.$dir_pkgs;
                my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;
                my $locdir_pkggroup = $locdir_rilis.'/'.$new_grp;

                # Make Dir Group Packages :
                unless (-d $locdir_pkggroup) {
                    mkdir($locdir_pkggroup);
                }

                # Prepare Config ;
                my $save_config = prepare_config();
                my $result_addgrp = $save_config->{'add-group'}($allconfig, $new_grp);

                # Save Configure :
                unless (exists $curr_pkg->{'group'}->{$new_grp}) {
                    my $for_saveCfg = save_newConfig();
                    $for_saveCfg->{'addgroup'}($result_addgrp);
                }

                print "\n";
                print "Success added package group with name \"$new_grp\"\n\n";
            } else {
                print "\n";
                print "Warning : \n";
                print "=====" x 16 . "\n";
                print "group name is already exists, Please input another group name !!! \n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "=====" x 16 . "\n";
            print "Input valid name group \n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # get data argument :
        $new_grp = $ARGV[2];

        # Check Group Name :
        my $check_group = $self->check_exists_group('check', $curr_pkg->{'group'}, $new_grp);
        if ($check_group->{'result'} == 1) {
            my $locdir_pkg = $dir_dev.$dir_pkgs;
            my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;
            my $locdir_pkggroup = $locdir_rilis.'/'.$new_grp;

            # Make Dir Group Packages :
            unless (-d $locdir_pkggroup) {
                mkdir($locdir_pkggroup);
            }

            # Prepare Config ;
            my $save_config = prepare_config();
            my $result_addgrp = $save_config->{'add-group'}($allconfig, $new_grp);

            # Save Configure :
            unless (exists $curr_pkg->{'group'}->{$new_grp}) {
                my $for_saveCfg = save_newConfig();
                $for_saveCfg->{'addgroup'}($result_addgrp);
            }

            print "\n";
            print "Success added package group with name \"$new_grp\"\n\n";
        } else {
            print "\n";
            print "Warning : \n";
            print "=====" x 16 . "\n";
            print "group name is already exists, Please input another group name !!! \n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $arguments = '';
        for (my $i = 0; $arg_len; $i++)
        {
            if ($i == $arg_len) {
                $arguments .= $ARGV[$i];
            } else {
                $arguments .= $ARGV[$i].' ';
            }
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $arguments\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for list packages group :
# ------------------------------------------------------------------------
sub _list_pkggrp {
    my ($self, $allconfig) = @_;

    # get data current pkg :
    my $curr_pkg = $allconfig->{'pkg'};

    # Check List Group :
    my $check_list_group = $self->check_exists_group('list', $curr_pkg->{'group'}, '');

    # Form add group :
    if ($check_list_group->{result} == 1) {
        print "\n";
        print "Exists Groups : \n";
        print "---" x 18 . "\n";
        print $check_list_group->{'data'};
        print "\n\n";
    } else {
        print "\n";
        print "Info : \n";
        print "---" x 18 . "\n";
        print "No group in list\n\n";
    }
}
# Subroutine for Rename Group Packages :
# ------------------------------------------------------------------------
sub _rename_group_pkg {
    my ($self, $allconfig) = @_;

    # Check Argumenets :
    my $arg_len = scalar @ARGV;
    my $input_grp;
    my $new_input_group;
    my $old_pkg_group;

    # Define scalar for config :
    my $curr_data_pkg = $allconfig->{'pkg'};
    my $list_group = $curr_data_pkg->{'group'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {
        print "\n";
        print "Choose Group Packages.\n";

        my $num = 0;
        my %num_grp = ();
        while (my ($key, $value) = each %{$list_group}) {
            my $_num = $num + 1;
            $num_grp{$_num} = $key;
            print "$_num. $key\n";
            $num++;
        }
        print "Enter Number choice : ";
        chomp($input_grp = <STDIN>);
        if ($input_grp ne '') {
            if ($input_grp =~ m/^[0-9]+$/) {
                $old_pkg_group = $num_grp{$input_grp};

                # Check Packages Group :
                if (exists $list_group->{$old_pkg_group}) {
                    # Form New Group Name :
                    print "\n";
                    print "Enter new group name : ";
                    chomp($new_input_group = <STDIN>);
                    if ($new_input_group ne '') {
                        # Check Group name :
                        unless (exists $list_group->{$new_input_group}) {
                            my $dataPkg_cfg;

                            # Get list Packages based group :
                            my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $old_pkg_group);
                            if ($get_list_pkg->{'result'} == 1) {
                                my @list_pkgs = @{$get_list_pkg->{'data'}};

                                my $i = 0;
                                my $size_list = scalar keys(@list_pkgs);
                                $dataPkg_cfg = $allconfig;
                                while ($i < $size_list) {
                                    my $data_list_pkgs = $list_pkgs[$i]->{'name'};

                                    # Prepare Config :
                                    my $prepare_cfgPkgs = prepare_config();
                                    $dataPkg_cfg = $prepare_cfgPkgs->{'rename-pkg-group'}($dataPkg_cfg, $old_pkg_group, $new_input_group, $data_list_pkgs);

                                    print "Packages \"$data_list_pkgs\" change Group name \"$old_pkg_group\" to \"$new_input_group\" has success changed...\n";

                                    $i++;
                                }

                                my $prepare_cfgGrp = prepare_config();
                                $dataPkg_cfg = $prepare_cfgGrp->{'rename-group-pkg'}($dataPkg_cfg, $old_pkg_group, $new_input_group);

                                # Execute Config :
                                my $execute_config = save_newConfig();
                                $execute_config->{'rename-pkg-group'}($dataPkg_cfg);

                                print "Packages change Group name \"$old_pkg_group\" to \"$new_input_group\" has success changed...\n";
                            } else {
                                $dataPkg_cfg = $allconfig;
                                my $prepare_cfgGrp = prepare_config();
                                $dataPkg_cfg = $prepare_cfgGrp->{'rename-group-pkg'}($dataPkg_cfg, $old_pkg_group, $new_input_group);

                                # Execute Config :
                                my $execute_config = save_newConfig();
                                $execute_config->{'rename-pkg-group'}($dataPkg_cfg);

                                print "Packages change Group name \"$old_pkg_group\" to \"$new_input_group\" has success changed...\n";
                            }
                        } else {
                            print "\n";
                            print "Warning : \n";
                            print "====" x 18 . "\n";
                            print "New Group name is exists !! \n\n";
                            exit 0;
                        }
                    } else {
                        print "\n";
                        print "Warning : \n";
                        print "====" x 18 . "\n";
                        print "No input new name grup !! \n\n";
                        exit 0;
                    }
                } else {
                    print "\n";
                    print "Warning : \n";
                    print "====" x 18 . "\n";
                    print "Input Group Packages is not found\n\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "Choice Group only Numberic...\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Please Number choice for Group Packages if you want to rename group packages on apps system.\n";
            print "Or run command \"boidev bzr2git rename-pkg-group <Name_packages>\".\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # Define scalar :
        $old_pkg_group = $ARGV[2];

        # Check Packages Group :
        if (exists $list_group->{$old_pkg_group}) {
            # Form New Group Name :
            print "\n";
            print "Enter new group name : ";
            chomp($new_input_group = <STDIN>);
            if ($new_input_group ne '') {
                # Check Group name :
                unless (exists $list_group->{$new_input_group}) {
                    my $dataPkg_cfg;

                    # Get list Packages based group :
                    my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $old_pkg_group);
                    if ($get_list_pkg->{'result'} eq 1) {
                        my @list_pkgs = @{$get_list_pkg->{'data'}};

                        my $i = 0;
                        my $size_list = scalar keys(@list_pkgs);
                        $dataPkg_cfg = $allconfig;
                        while ($i < $size_list) {
                            my $data_list_pkgs = $list_pkgs[$i]->{'name'};

                            # Prepare Config :
                            my $prepare_cfgPkgs = prepare_config();
                            $dataPkg_cfg = $prepare_cfgPkgs->{'rename-pkg-group'}($dataPkg_cfg, $old_pkg_group, $new_input_group, $data_list_pkgs);

                            print "Packages \"$data_list_pkgs\" change Group name \"$old_pkg_group\" to \"$new_input_group\", success...\n";

                            $i++;
                        }

                        my $prepare_cfgGrp = prepare_config();
                        $dataPkg_cfg = $prepare_cfgGrp->{'rename-group-pkg'}($dataPkg_cfg, $old_pkg_group, $new_input_group);

                        # Execute Config :
                        my $execute_config = save_newConfig();
                        $execute_config->{'rename-pkg-group'}($dataPkg_cfg);

                        print "Packages change Group name \"$old_pkg_group\" to \"$new_input_group\" has success changed...\n";
                    } else {
                        $dataPkg_cfg = $allconfig;
                        my $prepare_cfgGrp = prepare_config();
                        $dataPkg_cfg = $prepare_cfgGrp->{'rename-group-pkg'}($dataPkg_cfg, $old_pkg_group, $new_input_group);

                        # Execute Config :
                        my $execute_config = save_newConfig();
                        $execute_config->{'rename-pkg-group'}($dataPkg_cfg);

                        print "Packages change Group name \"$old_pkg_group\" to \"$new_input_group\" has success changed...\n";
                    }
                } else {
                    print "\n";
                    print "Warning : \n";
                    print "====" x 18 . "\n";
                    print "New Group name is exists !! \n\n";
                }
            } else {
                print "\n";
                print "Warning : \n";
                print "====" x 18 . "\n";
                print "No input new name grup !! \n\n";
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Input Group Packages is not found\n\n";
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for Remove PkgGroup :
# ------------------------------------------------------------------------
sub remove_pkg_grp {
    my ($self, $allconfig, $input_group) = @_;

    # Define scalar :
    my $new_input_group;
    my $confirm_remove;
    my $confirm_remove_pkg;
    my $confirm_add_pkggrp;
    my $form_rename_pkg_grp;
    my $confirm_rename_pkg_grp = 0;
    my $new_group_name = '';

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $dir_pkgs = $data_dev->{'dir_pkg'};

    # get data current pkg :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};

    # Get list Packages based group :
    my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($get_list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$get_list_pkg->{'data'}};

        # Confirm to rename group name in data packages :
        print "\n";
        print "Found Packages related on group name\n";
        print "You want to remove group name [y/n] : ";
        chomp($confirm_remove = <STDIN>);
        if ($confirm_remove eq 'y' or $confirm_remove eq 'Y') {

            # Form Remove All Packages :
            print "\n";
            print "You want remove all packages in group [y/n] : ";
            chomp($confirm_remove_pkg = <STDIN>);
            if ($confirm_remove_pkg eq 'y' or $confirm_remove_pkg eq 'Y') {
                $confirm_remove_pkg = 1;
            } else {
                $confirm_remove_pkg = 0;
            }

            # From for add new group :
            print "\n";
            print "You want to create new group : [y/n] : ";
            chomp($confirm_add_pkggrp = <STDIN>);
            if ($confirm_add_pkggrp eq 'y' or $confirm_add_pkggrp eq 'Y') {
                $confirm_add_pkggrp = 1;
            } else {
                $confirm_add_pkggrp = 0;
            }

            # For Dir Groups :
            my $locdir_pkg = $dir_dev.$dir_pkgs;
            my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;
            my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;
            my $dataPkg_cfg = $allconfig;

            # Form Rename Group :
            if ($confirm_remove_pkg == 0 and $confirm_add_pkggrp == 1) {
                print "\n";
                print "You want to rename group in data packages [y/n] : ";
                chomp($form_rename_pkg_grp = <STDIN>);
                if ($form_rename_pkg_grp eq 'y' or $form_rename_pkg_grp eq 'Y') {
                    $confirm_rename_pkg_grp = 1;
                    print "Enter new group name : ";
                    chomp($new_group_name = <STDIN>);
                    if ($new_group_name ne '') {
                        $new_group_name = $new_group_name;
                    } else {
                        $new_group_name = 'undef-group';
                    }
                }
            }

            my $i = 0;
            my $size_list = scalar keys(@list_pkgs);
            while ($i < $size_list) {
                my $data_list_pkgs = $list_pkgs[$i]->{'name'};
                my $data_old_pkg_grp = $list_pkgs[$i]->{'group'};
                my $locdir_datapkg = $locdir_rilis.'/'.$input_group.'/'.$data_list_pkgs;

                if ($confirm_remove_pkg == 1) {
                    # Prepare Config :
                    my $prepare_cfgPkgs = prepare_config();
                    $dataPkg_cfg = $prepare_cfgPkgs->{'remove-pkg'}($dataPkg_cfg, $data_list_pkgs);
                } else {
                    if ($confirm_rename_pkg_grp eq 1) {
                        # Prepare Config :
                        my $prepare_cfgPkgs = prepare_config();
                        $dataPkg_cfg = $prepare_cfgPkgs->{'rename-pkg-group'}($dataPkg_cfg, $data_old_pkg_grp, $new_group_name, $data_list_pkgs);
                    }
                }

                $i++;
            }
            if ($confirm_remove_pkg == 0 and $confirm_rename_pkg_grp == 1) {

                print "\n";
                print "All packages change group name to \"$new_group_name\" \n\n";
            }

            # Remove Group Name :
            my $remove_grup = prepare_config();
            $dataPkg_cfg = $remove_grup->{'remove-group'}($dataPkg_cfg, $input_group);

            # Save Config :
            my $saveConfig = save_newConfig();
            $saveConfig->{'remove-group'}($dataPkg_cfg);

            # Make Dir Group Packages :
            if (-d $locdir_pkggroup) {
                system("rm -rf $locdir_pkggroup");
            }

            print "\n";
            print "Group name \"$input_group\" has success deleted...\n\n";

            if ($confirm_add_pkggrp == 1) {

                if ($confirm_add_pkggrp == 1 and $confirm_remove_pkg == 1) {
                    print "Enter new group name : ";
                    chomp($new_group_name = <STDIN>);
                    if ($new_group_name ne '') {
                        $new_group_name = $new_group_name;
                    } else {
                        $new_group_name = 'undef-group';
                    }
                }

                # add Group Name :
                my $add_grp = prepare_config();
                $dataPkg_cfg = $add_grp->{'add-group'}($dataPkg_cfg, $new_group_name);

                # Save Config :
                $saveConfig = save_newConfig();
                $saveConfig->{'addgroup'}($dataPkg_cfg);

                print "Add group name \"$new_group_name\" has success added...\n\n";
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Input Group Packages is not found\n\n";
            exit 0;
        }
    } else {
        # Remove Group Name :
        my $dataPkg_cfg = $allconfig;
        my $remove_grup = prepare_config();
        $dataPkg_cfg = $remove_grup->{'remove-group'}($dataPkg_cfg, $input_group);

        # Save Config :
        my $saveConfig = save_newConfig();
        $saveConfig->{'remove-group'}($dataPkg_cfg);

        # For Dir Groups :
        my $locdir_pkg = $dir_dev.$dir_pkgs;
        my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;
        my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;

        # Make Dir Group Packages :
        if (-d $locdir_pkggroup) {
            system("rm -rf $locdir_pkggroup");
        }

        print "Group name \"$input_group\" has success deleted...\n\n";
        exit 0;
    }
}
# Subroutine for Remove Group Packages :
# ------------------------------------------------------------------------
sub _remove_group_pkg {
    my ($self, $allconfig) = @_;

    # Check Argumenets :
    my $arg_len = scalar @ARGV;
    my $input_grp;
    my $old_pkg_group;

    # Define scalar for config :
    my $curr_data_pkg = $allconfig->{'pkg'};
    my $list_group = $curr_data_pkg->{'group'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {
        print "\n";
        print "Choose Group Packages.\n";

        my $num = 0;
        my %num_grp = ();
        while (my ($key, $value) = each %{$list_group}) {
            my $_num = $num + 1;
            $num_grp{$_num} = $key;
            print "$_num. $key\n";
            $num++;
        }
        print "Enter Number choice : ";
        chomp($input_grp = <STDIN>);
        if ($input_grp ne '') {
            if ($input_grp =~ m/^[0-9]+$/) {
                $old_pkg_group = $num_grp{$input_grp} if exists $num_grp{$input_grp};
                $old_pkg_group = 'no' unless exists $num_grp{$input_grp};

                # Check Packages Group :
                if (exists $list_group->{$old_pkg_group}) {
                    # Action Remove Group :
                    $self->remove_pkg_grp($allconfig, $old_pkg_group);
                } else {
                    print "\n";
                    print "Warning : \n";
                    print "====" x 18 . "\n";
                    print "Input Group Packages is not found\n\n";
                    exit 0;
                }

            } else {
                print "\n";
                print "Choice Group only Numberic...\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Please Number choice for Group Packages if you want to remove group packages on apps system.\n";
            print "Or run command \"boidev bzr2git remove-pkg-group <Name_packages>\".\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # For Get arguments :
        my $input_arg = $ARGV[2];

        # Check Packages Group :
        if (exists $list_group->{$input_arg}) {
            # Action Remove Group :
            $self->remove_pkg_grp($allconfig, $input_arg);
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Input Group Packages is not found\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for Group Packages :
# ------------------------------------------------------------------------
sub group_pkg {
    my ($self, $allconfig) = @_;

    # Define hash or scalar ;
    my %data = ();
    my $num_pkg_group;
    my $input_pkg_group = '';
    my $pkg_group = '';
    my $pkg_group_stts = 0;
    my $r_pkg_group;

    # Define scalar for group packages :
    if (exists $allconfig->{'pkg'}->{'group'}) {
        my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
        my $size_datapkg = scalar keys(%{$curr_dataPkg_grp});
        if ($size_datapkg > 0) {
            print "\n";
            print "Choose Group Packages.\n";

            my $num = 0;
            my %num_grp = ();
            while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                my $_num = $num + 1;
                $num_grp{$_num} = $key;
                print "$_num. $key\n";
                $num++;
            }
            print "Enter Number choice : ";
            chomp($num_pkg_group = <STDIN>);
            if ($num_pkg_group eq '') {
                $r_pkg_group = 0;
                $pkg_group = '';
                print "\n";
                print "Please Number choice for Group Packages...\n";
            } else {
                if ($num_pkg_group =~ m/^[0-9]+$/) {
                    $pkg_group = $num_grp{$num_pkg_group};
                    $r_pkg_group = 1;
                    $pkg_group_stts = 2;
                } else {
                    print "\n";
                    print "Choice Group only Numberic...\n\n";
                    exit 0;
                }
            }
        } else {
            print "\n";
            print "Enter group name packages before migration : ";
            chomp($input_pkg_group = <STDIN>);
            if ($input_pkg_group =~ m/^[A-Za-z0-9\-\_]+$/) {
                $pkg_group = $input_pkg_group;
                $r_pkg_group = 1;
                $pkg_group_stts = 1;
            }
            elsif ($input_pkg_group =~ m/^[A-Za-z]+$/) {
                $pkg_group = $input_pkg_group;
                $r_pkg_group = 1;
                $pkg_group_stts = 1;
            }
            else {
                $r_pkg_group = 0;
                $pkg_group = '';
                $pkg_group_stts = 0;
                print "\n";
                print "Name of group package must combination : \n";
                print "- Alphabetic\n";
                print "- Alphabetic Numberic\n";
                print "- Alpabetic Numberic and [_] character or/and [-] character\n";
                print "\n";
                exit 0;
            }
        }
    } else {
        print "\n";
        print "Enter group name packages before migration.\n";
        chomp($input_pkg_group = <STDIN>);
        if ($input_pkg_group =~ m/^[A-Za-z0-9\-\_]+$/) {
            $pkg_group = $input_pkg_group;
            $r_pkg_group = 1;
            $pkg_group_stts = 1;
        }
        elsif ($input_pkg_group =~ m/^[A-Za-z]+$/) {
            $pkg_group = $input_pkg_group;
            $r_pkg_group = 1;
            $pkg_group_stts = 1;
        }
        else {
            $r_pkg_group = 0;
            $pkg_group = '';
            $pkg_group_stts = 0;
            print "\n";
            print "Name of group package must combination : \n";
            print "- Alphabetic\n";
            print "- Alphabetic Numberic\n";
            print "- Alpabetic Numberic and [_] character or/and [-] character\n";
            print "\n";
            exit 0;
        }
    }

    $data{'result'} = $r_pkg_group;
    $data{'data'} = $pkg_group;
    $data{'status'} = $pkg_group_stts;

    return \%data;
}
# Subroutine for option "addpkg" :
# ------------------------------------------------------------------------
sub _addpkg {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $new_pkg;
    my $arg_len = scalar @ARGV;

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $dir_pkgs = $data_dev->{'dir_pkg'};

    # Check Package Group :
    my $pkg_group = $self->group_pkg($allconfig);

    if ($pkg_group->{'result'} eq 1) {
        # Define scalar for data packages :
        my $input_group = $pkg_group->{'data'};
        my $status_group = $pkg_group->{'status'};
        my $build = $allconfig->{build};
        my $build_rilis = $build->{'rilis'};
        my $build_gpg = $build->{'gpg'};
        my $data_bzr = $allconfig->{bzr}->{url};
        my $data_git = $allconfig->{git}->{url};
        my $curr_data_pkg = $allconfig->{'pkg'};
        my $locdir_pkg = $dir_dev.$dir_pkgs;
        my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;

        # Check Status group packages :
        if ($status_group == 1) {
            # Define hash or scalar :
            my %data = ();
            my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;

            # Make Dir Group Packages :
            unless (-d $locdir_pkggroup) {
                mkdir($locdir_pkggroup);
            }

            # Check Arguments :
            if ($arg_len == 2) {

                print "Enter Packages : ";
                chomp($new_pkg = <STDIN>);
                if ($new_pkg ne '') {
                    unless (exists $allconfig->{'pkg'}->{'pkgs'}->{$new_pkg}) {

                        # Define scalar for config :
                        my $save_config = prepare_config();
                        my $rdt_config = $save_config->{'newpkg'}($allconfig, {
                                'pkg' => $new_pkg,
                                'group' => $input_group
                            });
                        my $for_saveCfg;

                        # Add list pkgs :
                        unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$new_pkg}) {
                            $for_saveCfg = save_newConfig();
                            $for_saveCfg->{'addpkg'}($rdt_config);
                        }
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages \"$new_pkg\" is exists...\n";
                        exit 0;
                    }

                } else {
                    print "Please Enter name package for add !!!\n";
                    exit 0;
                }
            } elsif ($arg_len == 3) {
                $new_pkg = $ARGV[2];
                unless (exists $allconfig->{'pkg'}->{'pkgs'}->{$new_pkg}) {

                    # Define scalar for config :
                    my $save_config = prepare_config();
                    my $rdt_config = $save_config->{'newpkg'}($allconfig, {
                            'pkg' => $new_pkg,
                            'group' => $input_group
                        });
                    my $for_saveCfg;

                    # Add list pkgs :
                    unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$new_pkg}) {
                        $for_saveCfg = save_newConfig();
                        $for_saveCfg->{'addpkg'}($rdt_config);
                    }
                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Packages \"$new_pkg\" is exists...\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "====" x 18 . "\n";
                print "your command: boidev $ARGV[0] $ARGV[1] $ARGV[2]\n";
                print "----" x 18 . "\n";
                print "\n";
                print "Warning : \n";
                print "====" x 18 . "\n";
                print "Error input arguments\n\n";
                exit 0;
            }
        }
        elsif ($status_group eq 2) {

            # Check Arguments :
            if ($arg_len == 2) {
                # Form Add Package :
                print "Enter New Packages : ";
                chomp($new_pkg = <STDIN>);
                if ($new_pkg ne '') {
                    unless (exists $allconfig->{'pkg'}->{'pkgs'}->{$new_pkg}) {
                        my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;
                        my $curr_group = $curr_data_pkg->{$input_group};
                        my $url_repo = $data_bzr.'/'.$new_pkg;
                        my $loc_localrepo = $locdir_pkggroup.'/'.$new_pkg;

                        # Define scalar for config :
                        my $save_config = prepare_config();
                        my $rdt_config = $save_config->{'newpkg-grp-exists'}($allconfig, {
                                'pkg' => $new_pkg,
                                'group' => $input_group
                            });
                        my $for_saveCfg;

                        # Add list pkgs :
                        unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$new_pkg}) {
                            $for_saveCfg = save_newConfig();
                            $for_saveCfg->{'addpkg'}($rdt_config);
                        }
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages \"$new_pkg\" is exists...\n";
                        exit 0;
                    }
                } else {
                    print "\n";
                    print "Warning : \n";
                    print "====" x 18 . "\n";
                    print "Please Enter name package for add !!!\n";
                    exit 0;
                }
            } elsif ($arg_len == 3) {
                $new_pkg = $ARGV[2];
                unless (exists $allconfig->{'pkg'}->{'pkgs'}->{$new_pkg}) {

                    my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;
                    my $curr_group = $curr_data_pkg->{$input_group};
                    my $url_repo = $data_bzr.'/'.$new_pkg;
                    my $loc_localrepo = $locdir_pkggroup.'/'.$new_pkg;

                    # Define scalar for config :
                    my $save_config = prepare_config();
                    my $rdt_config = $save_config->{'newpkg-grp-exists'}($allconfig, {
                            'pkg'   => $new_pkg,
                            'group' => $input_group
                        });
                    my $for_saveCfg;

                    # Add list pkgs :
                    unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$new_pkg}) {
                        $for_saveCfg = save_newConfig();
                        $for_saveCfg->{'addpkg'}($rdt_config);
                    }
                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Packages \"$new_pkg\" is exists...\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "====" x 18 . "\n";
                print "your command: boidev $ARGV[0] $ARGV[1] $ARGV[2]\n";
                print "----" x 18 . "\n";
                print "\n";
                print "Warning : \n";
                print "====" x 18 . "\n";
                print "Error input arguments\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Please Enter valid name for Group Packages...\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Please Enter valid name for Group Packages...\n";
        exit 0;
    }
}

# Subroutine for option "addpkg-file".
# This subroutine functionate to add packages to list from File.
# ------------------------------------------------------------------------
sub _addpkg_file {
    my ($self, $allconfig) = @_;

    # Check Argumenets :
    my $arg_len = scalar @ARGV;

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $filepkg_ext = $data_dev->{'filePkg_ext'};
    my $dir_pkgs = $data_dev->{'dir_pkg'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    if ($arg_len == 3) {

        if ($ARGV[2] =~ m/$filepkg_ext$/) {

            # Check File :
            if (-e $ARGV[2]) {
                my $loc_file_cfg = $ARGV[2];

                # Define scalar :
                my $new_pkg;
                my @list_pkg = ();

                # Check Package Group :
                my $pkg_group = $self->group_pkg($allconfig);

                # Get List Command :
                my $list_cmd = list_cmd();

                # Define hash or scalar :
                my $input_group = $pkg_group->{'data'};
                my $status_group = $pkg_group->{'status'};
                my $build = $allconfig->{build};
                my $build_rilis = $build->{'rilis'};
                my $curr_data_pkg = $allconfig->{'pkg'};
                my $list_pkgs = $curr_data_pkg->{'pkgs'};
                my $locdir_pkg = $dir_dev.$dir_pkgs;
                my $locdir_rilis = $locdir_pkg.'/'.$build_rilis;
                my $locdir_pkggroup = $locdir_rilis.'/'.$input_group;

                if ($status_group == 1) {

                    # Make Dir Group Packages :
                    unless (-d $locdir_pkggroup) {
                        mkdir($locdir_pkggroup);
                    }

                    # Read file list packages :
                    my $save_config;
                    my $rdt_config;
                    my $data_allcfg = $allconfig;
                    open(FH, '<', $loc_file_cfg) or die $! . " - " . $loc_file_cfg;
                    while (my $lines = <FH>) {
                        $lines =~ s/^\s+//g;
                        $lines =~ s/\s+$//g;
                        $new_pkg = $lines;

                        # Check if pkg is exists :
                        unless (exists $list_pkgs->{$new_pkg}) {

                            # Define scalar for config :
                            $save_config = prepare_config();
                            $data_allcfg = $save_config->{'newpkg'}($data_allcfg, {
                                    'pkg' => $lines,
                                    'group' => $input_group
                                });
                            print "$new_pkg has success added. \n";
                            push(@list_pkg, $lines);
                        } else {
                            print "$new_pkg is exists. \n";
                        }

                        my $for_saveCfg;
                        unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$lines}) {
                            $for_saveCfg = save_newConfig();
                            $for_saveCfg->{'addpkg'}($data_allcfg);
                        }
                    }

                    # CLose File :
                    close (FH);
                    my $size_pkgs = scalar @list_pkg;
                    print "\n $size_pkgs packages has added...\n"
                }
                elsif ($status_group == 2) {

                    # Read file list packages :
                    my $save_config;
                    my $rdt_config;
                    my $data_allcfg = $allconfig;
                    open(FH, '<', $loc_file_cfg) or die $! . " - " . $loc_file_cfg;
                    while (my $lines = <FH>) {
                        $lines =~ s/^\s+//g;
                        $lines =~ s/\s+$//g;

                        # Define scalar for config :
                        $save_config = prepare_config();
                        $data_allcfg = $save_config->{'newpkg'}($data_allcfg, {
                                'pkg' => $lines,
                                'group' => $input_group
                            });
                        my $for_saveCfg;
                        print "\"$lines\" has success added.\n";
                        push(@list_pkg, $lines);

                        unless (exists $curr_data_pkg->{'group'}->{$input_group} && exists $curr_data_pkg->{'pkgs'}->{$lines}) {
                            $for_saveCfg = save_newConfig();
                            $for_saveCfg->{'addpkg'}($data_allcfg);
                        }
                    }

                    # CLose File :
                    close (FH);
                    my $size_pkgs = scalar @list_pkg;
                    print "\n $size_pkgs packages has added...\n"
                }
                else {
                    print "\n";
                    print "Warning : \n";
                    print "====" x 18 . "\n";
                    print "Please Enter valid name for Group Packages...\n\n";
                    exit 0;
                }
            }

        } else {
            print "\n";
            print "====" x 18 . "\n";
            print "your command: boidev $ARGV[0] $ARGV[1] $ARGV[2]\n";
            print "----" x 18 . "\n";
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "File extension is not valid. Extension file list packages must \"$filepkg_ext\"\n";
            print "or Please using valid arguments three\n\n";
            BlankOnDev::usage_bzr2git_addpkgfile();
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len != 3 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len != 3.
    # ========================================================================
}
# Subroutine for remove packages :
# ------------------------------------------------------------------------
sub _removepkg {
    my ($self, $allconfig) = @_;

    # Check Argumenets :
    my $arg_len = scalar @ARGV;
    my $input_pkg;

    # Define scalar for config :
    my $curr_data_pkg = $allconfig->{'pkg'};
    my $list_group = $curr_data_pkg->{'group'};
    my $list_pkgs = $curr_data_pkg->{'pkgs'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {
        # Form Packages :
        print "\n";
        print "---------" x 8 . "\n";
        print " Form Remove Packages on Apps System : \n";
        print "---------" x 8 . "\n";
        print "\n";
        print "Enter packages name : ";
        chomp($input_pkg = <STDIN>);
        if ($input_pkg ne '') {
            if (exists $list_pkgs->{$input_pkg}) {

                # Prepare Config :
                my $prepare_config = prepare_config();
                my $r_Cfg = $prepare_config->{'remove-pkg'}($allconfig, $input_pkg);

                # Execute Config :
                my $execute_config = save_newConfig();
                $execute_config->{'removePkg'}($r_Cfg);

            } else {
                print "\n";
                print "Warning : \n";
                print "====" x 18 . "\n";
                print "Packages is not found\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Enter packages name if you want to remove packages on apps system.\n";
            print "Or run command \"boidev bzr2git remove-pkg <Name_packages>\".\n\n";
            exit 0;
        }
    }

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # get data arguments :
        my $input_argv = $ARGV[2];
        my $remove_pkgInGrp;
        my $remove_pkg;

        # Check Packages Group :
        if (exists $list_group->{$input_argv}) {
            # Form Packageg Group :
            print "\n";
            print "=========" x 8 . "\n";
            print "=========" x 8 . "\n";
            print " Are you sure to remove all packages in group \"$input_argv\" [y/n] : \n";
            print " IF you not valid input, packages not removed\n";
            print "---------" x 8 . "\n";
            print "Your Answer : ";
            chomp($remove_pkgInGrp = <STDIN>);
            if ($remove_pkgInGrp eq 'y' or $remove_pkgInGrp eq 'Y') {

                # Get List Packages :
                my $listOf_pkg = $self->filter_listpkg_based_group($allconfig, $input_argv);
                if ($listOf_pkg->{'result'} eq 1) {
                    my @list_pkgs = @{$listOf_pkg->{'data'}};

                    my $i = 0;
                    my $size_list = scalar keys(@list_pkgs);
                    my $dataPkg_cfg = $allconfig;
                    while ($i < $size_list) {
                        my $num = $i + 1;
                        my $this_currPkg = $list_pkgs[$i]->{'name'};

                        # Prepare Config :
                        my $prepare_config = prepare_config();
                        $dataPkg_cfg = $prepare_config->{'remove-pkg'}($dataPkg_cfg, $this_currPkg);

                        # Execute Config :
                        my $execute_config = save_newConfig();
                        $execute_config->{'removePkg'}($dataPkg_cfg);

                        print "Packages \"$this_currPkg\" on Group \"$input_argv\", has success deleted...\n";
                        $i++;
                    }

                }
            }
        } else {
            # Check Packages :
            if (exists $list_pkgs->{$input_argv}) {
                my $group_name = $list_pkgs->{$input_argv}->{'group'};
                # Form Packages :
                print "\n";
                print "=========" x 8 . "\n";
                print "=========" x 8 . "\n";
                print " Are you sure to packages \"$input_argv\" [y/n] : \n";
                print " IF you not valid input, packages not removed\n";
                print "---------" x 8 . "\n";
                print "Your Answer : ";
                chomp($remove_pkg = <STDIN>);
                if ($remove_pkg eq 'Y' or $remove_pkg eq 'y') {

                    # Prepare Config :
                    my $prepare_config = prepare_config();
                    my $r_Cfg = $prepare_config->{'remove-pkg'}($allconfig, $input_argv);

                    # Execute Config :
                    my $execute_config = save_newConfig();
                    $execute_config->{'removePkg'}($r_Cfg);

                    print "Packages \"$input_argv\" on Group \"$group_name\", success deleted...\n\n";
                }
            } else {
                print "\n";
                print "Warning : \n";
                print "====" x 18 . "\n";
                print "Packages is not found\n\n";
                exit 0;
            }
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for filter list pkg based group name :
# ------------------------------------------------------------------------
sub filter_listpkg_based_group {
    my ($self, $allconfig, $group) = @_;

    # Define hash or scalar :
    my %data = ();

    # Get data current config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_pkg = $curr_pkg->{'pkgs'};

    # Check List Packages :
    my $i = 0;
    my $size_pkgs = scalar keys(%{$list_pkg});
    if ($size_pkgs > 0) {

        # Check Group :
        if (exists $curr_pkg->{'group'}->{$group}) {

            # While loop for list pkgs :
            my $num_true = 0;
            my $num_false = 0;
            my $num = 0;
            my @pre_data_rows = ();
            while (my ($key, $value) = each %$list_pkg) {
                if ($list_pkg->{$key}->{'group'} eq $group) {
                    $num_true = $num_true + 1;
                    $pre_data_rows[$num] = $list_pkg->{$key};
                } else {
                    $num_false = $num_false + 1;
                }
                $num++;
            }

            # Remove "undef" value on array :
            my @data_rows = grep($_, @pre_data_rows);

            # Place result :
            $data{'result'} = 1 if $num_true > 0;
            $data{'result'} = 0 if $num_true == 0 && $num_false > 0;
            $data{'data'} = \@data_rows;

            return \%data;

        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list. Please run command \"boidev bzr2git addpkg\" to add new packages.\n\n";
        exit 0;
    }
}
# Subroutine for list all packages group :
# ------------------------------------------------------------------------
sub list_all_pkg_group {
    my ($self, $allconfig) = @_;

    # Define hash or scalar :
    my %data = ();

    # Get data current config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_group = $curr_pkg->{'group'};
    my $size_list_group = scalar keys(%{$list_group});

    # Check count list packages group :
    if ($size_list_group > 0) {

        # While loop for list packages group :
        my $i = 0;
        my @pre_data_rows = ();
        while (my ($key, $value) = each %$list_group) {
            $pre_data_rows[$i] = $key;
            $i++;
        }

        # Remove "undef" value on array :
        my @data_rows = grep($_, @pre_data_rows);

        # Place result :
        $data{'data'} = \@data_rows;

        return \%data;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
        exit 0;
    }
}
# Subroutine for list packages by group :
# ------------------------------------------------------------------------
sub list_pkg_by_group {
    my ($self, $allconfig, $group) = @_;

    # Define hash or scalar :
    my %data = ();

    # Get data current config :
    my $curr_build = $allconfig->{'build'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_pkg = $curr_pkg->{'pkgs'};

    # Check List Packages :
    my $i = 0;
    my $size_pkgs = scalar keys(%{$list_pkg});
    if ($size_pkgs > 0) {

        # Check Group :
        if (exists $curr_pkg->{'group'}->{$group}) {

            # While loop for list pkgs :
            my $num_true = 0;
            my $num_false = 0;
            my $num = 0;
            my @pre_data_rows = ();
            while (my ($key, $value) = each %$list_pkg) {
                if ($list_pkg->{$key}->{'group'} eq $group) {
                    $num_true = $num_true + 1;
                    $pre_data_rows[$num] = $list_pkg->{$key};
                } else {
                    $num_false = $num_false + 1;
                }
                $num++;
            }

            # Remove "undef" value on array :
            my @data_rows = grep($_, @pre_data_rows);

            # Place result :
            $data{'result'} = 1 if $num_true > 0;
            $data{'result'} = 0 if $num_true == 0 && $num_false > 0;
            $data{'data'} = \@data_rows;

        } else {
            $data{'result'} = 0;
            $data{'data'} = [];
        }
    } else {
        $data{'result'} = 0;
        $data{'data'} = [];
    }

    return \%data;
}
# Subroutine for list pkg :
# ------------------------------------------------------------------------
sub _list_pkg {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $date_branch;
    my $date_gitpush;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $buld_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $prefix_flcfg = $data_dev->{'prefix_flcfg'};
    my $file_cfg_ext = $data_dev->{'fileCfg_ext'};
    my $file_nameCfg = $prefix_flcfg.$buld_rilis.$file_cfg_ext;
    my $loc_fileCfg = $dir_dev.$file_nameCfg;

    # Check Argumenets :
    my $arg_len = scalar @ARGV;

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    if ($arg_len == 3) {

        # Check file config :
        if (-e $loc_fileCfg) {

            # Check if $ARGV[2] == 'all' :
            if ($ARGV[2] eq 'all') {
                my $list_all_pkggroup = $self->list_all_pkg_group($allconfig);
                my @list_allpkg_group = @{$list_all_pkggroup->{'data'}};

                # Create Text Table :
                my $textTbl;

                # While loop to get list packages group :
                my $i = 0;
                my $until = scalar @list_allpkg_group;
                my $data_list = '';
                my $size_list = 0;
                my $get_list_pkg_bygrp = '';
                while ($i < $until) {

                    my $group_name = $list_allpkg_group[$i];

                    # Get list packages by Group :
                    $get_list_pkg_bygrp = $self->list_pkg_by_group($allconfig, $group_name);
                    if ($get_list_pkg_bygrp->{'result'} eq 1) {
                        my @list_all_pkg = @{$get_list_pkg_bygrp->{'data'}};

                        # Print "Header" :
                        $data_list .= "\n";
                        $data_list .= "List Packages for group \"$group_name\"\n";

                        # Create Text Table :
                        $textTbl = Text::SimpleTable::AutoWidth->new(captions => [( '#', 'Group Name', 'Packages Name', 'Date Add', 'Date bzr branch', 'Date git push', 'status', 'on GitHub')]);

                        # While loop to get list packages :
                        my $i_p = 0;
                        my $until_p = scalar @list_all_pkg;
                        while ($i_p < $until_p) {
                            $size_list = $size_list + 1;
                            my $num = $i_p + 1;
                            my $curr_grpname = $list_all_pkg[$i_p]->{'group'};
                            my $pkg_name = $list_all_pkg[$i_p]->{'name'};
                            my $date_add = $list_all_pkg[$i_p]->{'date-add'};
                            $date_branch = exists $list_all_pkg[$i_p]->{'date-branch'} && $list_all_pkg[$i_p]->{'date-branch'} eq '' ? '-' : $list_all_pkg[$i_p]->{'date-branch'};
                            $date_gitpush = exists $list_all_pkg[$i_p]->{'date-gitpush'} && $list_all_pkg[$i_p]->{'date-gitpush'} eq '' ? '-' : $list_all_pkg[$i_p]->{'date-gitpush'};
                            my $status_branch = $list_all_pkg[$i_p]->{'status'}->{'bzr-branch'};
                            my $status_gitpush = $list_all_pkg[$i_p]->{'status'}->{'git-push'};
                            my $status_gitCgit = $list_all_pkg[$i_p]->{'status'}->{'bzrConvertGit'};
                            my $status = "bzrBranch = $status_branch, bzrConvertGit = $status_gitCgit, gitPush = $status_gitpush";
                            my $status_ongit = exists $list_all_pkg[$i_p]->{'status'}->{'ongit'} ? $list_all_pkg[$i_p]->{'status'}->{'ongit'} : '';
                            my @data_rows = ($num, $curr_grpname, $pkg_name, $date_add, $date_branch, $date_gitpush, $status, $status_ongit);
#                            my @data_rows = ($num, $curr_grpname, $pkg_name, $date_add, '-', '-', $status, $status_ongit);
                            $textTbl->row(@data_rows);
                            $i_p++
                        }
                        $data_list .= $textTbl->draw();
                    }
                    $i++;
                }

                # Print List :
                print "\n";
                print "---------" x 11 . "\n";
                print " List Packages with amount \"$size_list\" packages : \n";
                print "---------" x 11 . "\n";
                printf("%s", "Status :\n");
                print "---------" x 11 . "\n";
                BlankOnDev::help_list_pkg();
                print "\n";
                print $data_list;
                print "\n";
                print "---------" x 11 . "\n";
                printf("%s", "Status :\n");
                print "---------" x 11 . "\n";
                BlankOnDev::help_list_pkg();
                print "\n";
                exit 0;
            }

            # Check New Group :
            my $check_group = $self->check_exists_group('check', $curr_pkg->{'group'}, $ARGV[2]);
            if ($check_group->{'result'} == 0) {
                my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $ARGV[2]);
                if ($get_list_pkg->{'result'} eq 1) {
                    my @list_pkgs = @{$get_list_pkg->{'data'}};

                    # Create Text Table :
                    my $textTbl = Text::SimpleTable::AutoWidth->new(captions => [( '#', 'Group Name', 'Packages Name', 'Date Add', 'Date bzr branch', 'Date git push', 'status', 'on GitHub')]);

                    my $i = 0;
                    my $size_list = scalar keys(@list_pkgs);
                    while ($i < $size_list) {
                        my $num = $i + 1;
                        my $group_name = $list_pkgs[$i]->{'group'};
                        my $pkg_name = $list_pkgs[$i]->{'name'};
                        my $date_add = $list_pkgs[$i]->{'date-add'};
                        my $date_branch = $list_pkgs[$i]->{'date-branch'} eq '' ? '-' : $list_pkgs[$i]->{'date-branch'};
                        my $date_gitpush = $list_pkgs[$i]->{'date-gitpush'} eq '' ? '-' : $list_pkgs[$i]->{'date-gitpush'};
                        my $status_branch = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
                        my $status_gitpush = $list_pkgs[$i]->{'status'}->{'git-push'};
                        my $status_gitCgit = $list_pkgs[$i]->{'status'}->{'bzrConvertGit'};
                        my $status = "bzrBranch = $status_branch, bzrConvertGit = $status_gitCgit, gitPush = $status_gitpush";
                        my $status_ongit = exists $list_pkgs[$i]->{'status'}->{'ongit'} ? $list_pkgs[$i]->{'status'}->{'ongit'} : '';
                        my @data_rows = ($num, $group_name, $pkg_name, $date_add, $date_branch, $date_gitpush, $status, $status_ongit);
                        $textTbl->row(@data_rows);
                        $i++;
                    }

                    # Print List :
                    print "\n";
                    print "---------" x 11 . "\n";
                    print " List Packages in group \"$ARGV[2]\" and result \"$size_list\" packages : \n";
                    print "---------" x 11 . "\n";
                    printf("%s", "Status :\n");
                    print "---------" x 11 . "\n";
                    BlankOnDev::help_list_pkg();
                    print "\n";
                    print $textTbl->draw();
                    print "\n";
                    print "---------" x 11 . "\n";
                    printf("%s", "Status :\n");
                    print "---------" x 11 . "\n";
                    BlankOnDev::help_list_pkg();
                    print "\n";
                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Not found packages in list on group $ARGV[2]. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Warning : \n";
            print "====" x 18 . "\n";
            print "Not found configure. Please run command \"boidev mig_prepare\" first. \n\n";
            exit 0;
        }
    }
    # ----------------------------------------------------------------
    # check IF $arg_len == 2 :
    # ----------------------------------------------------------------
    elsif ($arg_len == 2) {

        # Define scalar :
        my $num_pkg_group;
        my $pkg_group = '';

        # Data current config :
        my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
        my $size_datapkg = scalar keys(%{$curr_dataPkg_grp});

        if ($size_datapkg > 0) {
            print "\n";
            print "Choose Group Packages.\n";

            my $num = 0;
            my %num_grp = ();
            while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                my $_num = $num + 1;
                $num_grp{$_num} = $key;
                print "$_num. $key\n";
                $num++;
            }
            print "Enter Number choice : ";
            chomp($num_pkg_group = <STDIN>);
            if ($num_pkg_group eq '') {
                $pkg_group = '';
                print "\n";
                print "Please Number choice for Group Packages...\n";
            } else {
                if ($num_pkg_group =~ m/^[0-9]+$/) {
                    $pkg_group = $num_grp{$num_pkg_group};
                } else {
                    print "\n";
                    print "Choice Group only Numberic...\n\n";
                    exit 0;
                }
            }

            # Execute :
            my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $pkg_group);
            if ($get_list_pkg->{'result'} eq 1) {
                my @list_pkgs = @{$get_list_pkg->{'data'}};

                # Create Text Table :
                my $textTbl = Text::SimpleTable::AutoWidth->new(captions => [( '#', 'Group Name', 'Packages Name', 'Date Add', 'Date bzr branch', 'Date git push', 'status', 'on GitHub')]);

                my $i = 0;
                my $size_list = scalar keys(@list_pkgs);
                while ($i < $size_list) {
                    my $numb = $i + 1;
                    my $group_name = $list_pkgs[$i]->{'group'};
                    my $pkg_name = $list_pkgs[$i]->{'name'};
                    my $date_add = $list_pkgs[$i]->{'date-add'};
                    my $date_branch = $list_pkgs[$i]->{'date-branch'} eq '' ? '-' : $list_pkgs[$i]->{'date-branch'};
                    my $date_gitpush = $list_pkgs[$i]->{'date-gitpush'} eq '' ? '-' : $list_pkgs[$i]->{'date-gitpush'};
                    my $status_branch = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
                    my $status_gitpush = $list_pkgs[$i]->{'status'}->{'git-push'};
                    my $status_gitCgit = $list_pkgs[$i]->{'status'}->{'bzrConvertGit'};
                    my $status = "bzrBranch = $status_branch, bzrConvertGit = $status_gitCgit, gitPush = $status_gitpush";
                    my $status_ongit = exists $list_pkgs[$i]->{'status'}->{'ongit'} ? $list_pkgs[$i]->{'status'}->{'ongit'} : '';
                    my @data_rows = ($numb, $group_name, $pkg_name, $date_add, $date_branch, $date_gitpush, $status, $status_ongit);
                    $textTbl->row(@data_rows);
                    $i++;
                }

                # Print List :
                print "\n";
                print "---------" x 11 . "\n";
                print " List Packages in group \"$pkg_group\" and result \"$size_list\" packages : \n";
                print "---------" x 11 . "\n";
                printf("%s", "Status :\n");
                print "---------" x 11 . "\n";
                BlankOnDev::help_list_pkg();
                print "\n";
                print $textTbl->draw();
                print "\n";
                print "---------" x 11 . "\n";
                printf("%s", "Status :\n");
                print "---------" x 11 . "\n";
                BlankOnDev::help_list_pkg();
                print "\n";
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "Not found packages in list on group $pkg_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len != 3 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "Error input arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len != 3.
    # ========================================================================
}
# Subroutine for search packages :
# ------------------------------------------------------------------------
sub search_pkg {
    my ($self, $allconfig, $pkg) = @_;

    # Define hash or scalar :
    my %data = ();

    # Get data current config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $list_pkg = $curr_pkg->{'pkgs'};

    # Check List Packages :
    my $i = 0;
    my $size_pkgs = scalar keys(%{$list_pkg});
    if ($size_pkgs > 0) {

        # While loop for list pkgs :
        my $num_true = 0;
        my $num_false = 0;
        my $num = 0;
        my @pre_data_rows = ();
        while (my ($key, $value) = each %{$list_pkg}) {
            if ($key =~ m/$pkg/) {
                $num_true = $num_true + 1;
                $pre_data_rows[$num] = $list_pkg->{$key};
            } else {
                $num_false = $num_false + 1;
            }
            $num++;
        }

        # Remove "undef" value on array :
        my @data_rows = grep($_, @pre_data_rows);

        # Place result :
        $data{'result'} = 1 if $num_true > 0;
        $data{'result'} = 0 if $num_true == 0 && $num_false > 0;
        $data{'data'} = \@data_rows;

        return \%data;

    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list. Please run command \"boidev bzr2git addpkg\" to add new packages.\n\n";
        exit 0;
    }
}
# Subroutine for form search packages :
# ------------------------------------------------------------------------
sub form_search_pkg {
    # Define scalar
    my $data = '';
    my $search_pkg;
    my $re_search_pkg;

    # Form Search :
    print "\n";
    print "Please Enter name of packages will be search : ";
    chomp($search_pkg = <STDIN>);
    if ($search_pkg ne '') {

    } else {
        print "\n";
        print "You not input packages name for search. \n";
        print "You want re-search Packages [y/n]";
        chomp($re_search_pkg = <STDIN>);
        if ($re_search_pkg eq 'y' or $re_search_pkg eq 'Y') {
            form_search_pkg();
        } else {
            exit 0;
        }
    }

    $data = $search_pkg;

}
# Subroutine for search packages :
# ------------------------------------------------------------------------
sub _search_pkg {
    my ($self, $allconfig) = @_;

    # For Arguments :
    my $arg_len = scalar @ARGV;

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Form Search :
        my $search_pkg = form_search_pkg();

        # Check Packages :
        my $check_packages = $self->search_pkg($allconfig, $search_pkg);
        if ($check_packages->{'result'} == 1) {
            my @list_pkgs = @{$check_packages->{'data'}};

            # Create Text Table :
            my $textTbl = Text::SimpleTable::AutoWidth->new(captions => [( '#', 'Group Name', 'Packages Name', 'Date Add', 'Date bzr branch', 'Date git push', 'status')]);

            my $i = 0;
            my $size_list = scalar keys(@list_pkgs);
            while ($i < $size_list) {
                my $num = $i + 1;
                my $group_name = $list_pkgs[$i]->{'group'};
                my $pkg_name = $list_pkgs[$i]->{'name'};
                my $date_add = $list_pkgs[$i]->{'date-add'};
                my $date_branch = $list_pkgs[$i]->{'date-branch'} eq '' ? '-' : $list_pkgs[$i]->{'date-branch'};
                my $date_gitpush = $list_pkgs[$i]->{'date-gitpush'} eq '' ? '-' : $list_pkgs[$i]->{'date-gitpush'};
                my $status_branch = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
                my $status_gitpush = $list_pkgs[$i]->{'status'}->{'git-push'};
                my $status_gitCgit = $list_pkgs[$i]->{'status'}->{'bzrConvertGit'};
                my $status = "bzrBranch = $status_branch, bzrConvertGit = $status_gitCgit, gitPush = $status_gitpush";
                my @data_rows = ($num, $group_name, $pkg_name, $date_add, $date_branch, $date_gitpush, $status);
                $textTbl->row(@data_rows);
                $i++;
            }

            # Print List :
            print "\n";
            print "---------" x 11 . "\n";
            print " Result Search Packages \"$search_pkg\" And result of \"$size_list\" : \n";
            print "---------" x 11 . "\n";
            printf("%s", "Status :\n");
            print "---------" x 11 . "\n";
            BlankOnDev::help_list_pkg();
            print "\n";
            print $textTbl->draw();
            print "\n";
            print "---------" x 11 . "\n";
            printf("%s", "Status :\n");
            print "---------" x 11 . "\n";
            BlankOnDev::help_list_pkg();
            print "\n";
        } else {
            print "\n";
            print "-----" x 15 . "\n";
            print " Your Search Packages \"$search_pkg\" is not Found\n";
            print "-----" x 15 . "\n";
            print "\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {

        # Get Arguments :
        my $search_pkg = $ARGV[2];

        # Check Packages :
        my $check_packages = $self->search_pkg($allconfig, $search_pkg);
        if ($check_packages->{'result'} == 1) {
            my @list_pkgs = @{$check_packages->{'data'}};

            # Create Text Table :
            my $textTbl = Text::SimpleTable::AutoWidth->new(captions => [( '#', 'Group Name', 'Packages Name', 'Date Add', 'Date bzr branch', 'Date git push', 'status')]);
            my $i = 0;
            my $size_list = scalar keys(@list_pkgs);
            while ($i < $size_list) {
                my $num = $i + 1;
                my $group_name = $list_pkgs[$i]->{'group'};
                my $pkg_name = $list_pkgs[$i]->{'name'};
                my $date_add = $list_pkgs[$i]->{'date-add'};
                my $date_branch = $list_pkgs[$i]->{'date-branch'} eq '' ? '-' : $list_pkgs[$i]->{'date-branch'};
                my $date_gitpush = $list_pkgs[$i]->{'date-gitpush'} eq '' ? '-' : $list_pkgs[$i]->{'date-gitpush'};
                my $status_branch = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
                my $status_gitpush = $list_pkgs[$i]->{'status'}->{'git-push'};
                my $status = "bzrBranch = $status_branch, gitPush = $status_gitpush";
                my @data_rows = ($num, $group_name, $pkg_name, $date_add, $date_branch, $date_gitpush, $status);
                $textTbl->row(@data_rows);
                $i++;
            }

            # Print List :
            print "\n";
            print "---------" x 11 . "\n";
            print " Result Search Packages \"$ARGV[2]\" And result of \"$size_list\" packages : \n";
            print "---------" x 11 . "\n";
            printf("%s", "Status :\n");
            print "---------" x 11 . "\n";
            BlankOnDev::help_list_pkg();
            print "\n";
            print $textTbl->draw();
            print "\n";
            print "---------" x 11 . "\n";
            printf("%s", "Status :\n");
            print "---------" x 11 . "\n";
            BlankOnDev::help_list_pkg();
            print "\n";
        } else {
            print "\n";
            print "-----" x 15 . "\n";
            print " Your Search Packages \"$search_pkg\" is not Found\n";
            print "-----" x 15 . "\n";
            print "\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len != 3 or $arg_len != 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len != 3 or $arg_len != 2.
    # ========================================================================
}
# Subroutine for branch packages :
# ------------------------------------------------------------------------
sub branch_pkg {
    my ($self, $allconfig, $group_pkg, $pkg_name, $action_rebranch) = @_;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $locdir_group = $dir_pkgs.'/'.$group_pkg;

    # Check Group Directori :
    unless (-d $locdir_group) {
        mkdir($locdir_group);
    }

    # Action bzr Branch :
    my $act_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->branch($action_rebranch, $allconfig, $group_pkg, $pkg_name);

    # Prepare Configure Bzr Branch :
    my $prepare_cfg = prepare_config();
    my $result_cfg = $prepare_cfg->{'bzr-branch'}($allconfig, $pkg_name, $act_branch);

    # Save Configure :
    my $saveConfig = save_newConfig();
    $saveConfig->{'bzr-branch'}($result_cfg);
    print "\n";
    print "====" x 5 . " Packages $pkg_name has been finished to bzr branch ";
    print "====" x 5 . "\n\n";
    exit 0;
}
# Subroutine for Branch based group :
# ------------------------------------------------------------------------
sub branch_pkg_group {
    my ($self, $allconfig, $input_group) = @_;

    # Define scalar :
    my $confirm_rebranch;
    my $action_rebranch = 'new';

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $locdir_group = $dir_pkgs.'/'.$input_group;

    # Check Group Directori :
    unless (-d $locdir_group) {
        mkdir($locdir_group);
    }

    # Get list Packages based Group :
    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        # From for rebranch :
        print "\n";
        print "You want to re-branch if packages is exists on local directory [y/n] : ";
        chomp($confirm_rebranch = <STDIN>);
        if ($confirm_rebranch eq 'y' or $confirm_rebranch eq 'Y') {
            $action_rebranch = 'rm';
        } else {
            $action_rebranch = 'no'
        }

        my $i = 0;
        my $size_list = scalar keys(@list_pkgs);
        my $saveConfig;
        my $result_cfg = $allconfig;
        my $count_branch = 0;
        my $count_rebranch = 0;
        my $num = $i;
        while ($i < $size_list) {
            $num = $num + 1;
            my $group_name = $list_pkgs[$i]->{'group'};
            my $pkg_name = $list_pkgs[$i]->{'name'};

            # For file/dir pkgs :
            my $dest_dir = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check exists pkg :
            if (-d $dest_dir) {
                if ($action_rebranch eq 'rm') {
                    $count_rebranch = $count_branch + 1;
                }
            } else {
                $count_branch = $count_branch + 1;
            }

            # Action bzr Branch :
            my $act_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->branch($action_rebranch, $result_cfg, $group_name, $pkg_name);

            print "Result Action branch : $act_branch\n";

            # Prepare Configure Bzr Branch :
            my $prepare_cfg = prepare_config();
            $result_cfg = $prepare_cfg->{'bzr-branch'}($result_cfg, $pkg_name, $act_branch);

            # Save Configure :
            $saveConfig = save_newConfig();
            $saveConfig->{'bzr-branch'}($result_cfg);

            $i++;
        }
        my $notes = " Re-branch : $count_rebranch - New Branch : $count_branch ";
        print "\n";
        print "====" x 5 . " bzr branch has finished ";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }

}
# Subroutine for option "branch" :
# ------------------------------------------------------------------------
sub _branch {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;
    my $confirm_rebranch;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {
                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                # Check Group Packages Input :
                if (exists $curr_dataPkg_grp->{$input_group}) {

                    # Action Branch :
                    $self->branch_pkg_group($allconfig, $input_group);

                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Group is not found !!!\n\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    if ($arg_len == 3) {

        # Define scalar :
        my $input_arg = $ARGV[2];
        my $confirm_grp;

        # Check Group :
        if (exists $pkg_groups->{$input_arg}) {

            # For Confirm :
            print "\n";
            print "You want to branch based group [y/n] : ";
            chomp($confirm_grp = <STDIN>);
            if ($confirm_grp eq 'y' or $confirm_grp eq 'Y') {

                # Action Branch :
                $self->branch_pkg_group($allconfig, $input_arg);
            } else {

            }
        } else {
            # Check Packages :
            if (exists $pkg_list->{$input_arg}) {
                my $r_pkgGrp = $pkg_list->{$input_arg}->{'group'};

                # For file/dir pkgs :
                my $dest_dir = $dir_pkgs.'/'.$r_pkgGrp.'/'.$input_arg;

                # Check packages in Local dir :
                if (-d $dest_dir) {

                    # Form Confirm :
                    print "\n";
                    print "You want to Re-branch [y/n] : ";
                    chomp($confirm_rebranch = <STDIN>);
                    if ($confirm_rebranch eq 'y' or $confirm_rebranch eq 'Y') {

                        # Msg :
                        print "\n";
                        print "Bazaar re-branch for packages : \"$input_arg\"\n";

                        # Action Branch :
                        $self->branch_pkg($allconfig, $r_pkgGrp, $input_arg, 'rm');
                    }
                } else {

                    # Msg :
                    print "\n";
                    print "Bazaar Branch for packages : \"$input_arg\"\n";

                    # Action Branch :
                    $self->branch_pkg($allconfig, $r_pkgGrp, $input_arg, 'new');
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "Not found packages. Please try another packages.\n\n";
                exit 0;
            }
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len != 3 or $arg_len != 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len != 3 or $arg_len != 2.
    # ========================================================================
}
# Subroutine for convert packages from repo bazaar to github :
# ------------------------------------------------------------------------
sub bazaar_cgit_pkg {
    my ($self, $allconfig, $pkg_name) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Loc dir packages :
    my $data_pkg = $pkg_list->{$pkg_name};
    my $group_pkg = $data_pkg->{'group'};
    my $bzrbranch = $data_pkg->{'brz-branch'};
    my $bzrbranch_status = $data_pkg->{'status'}->{'bzr-branch'};
    my $locdir_pkg = $dir_pkgs.'/'.$group_pkg.'/'.$pkg_name;

    # Check Branch :
    if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

        # Check File Packages :
        if (-d $locdir_pkg) {

            # Action Convert Bzr to git :
            my $action_bzr2git = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr_convert_git($allconfig, $pkg_name);

            # Prepare Config :
            my $prepare_config = prepare_config();
            my $result_cfg = $prepare_config->{'bzr-convert'}($allconfig, $pkg_name, $action_bzr2git);

            # Save Configure :
            my $saveConfig = save_newConfig();
            $saveConfig->{'bzr-convert'}($result_cfg);
            print "\n";
            print "====" x 5 . " Packages $pkg_name has been finished to convert ";
            print "====" x 5 . "\n\n";
            exit 0;

        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "File Packages [$pkg_name] is not found. \n";
            print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : Branch status \n";
        print "====" x 18 . "\n";
        print "File Packages [$pkg_name] is not found. \n";
        print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
        exit 0;
    }
}
# Subroutine for convert packages in group from repo bazaar to github  :
# ------------------------------------------------------------------------
sub bazaar_cgit_pkg_group {
    my ($self, $allconfig, $input_group) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};

    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        # While loop to convert repository format :
        my $i = 0;
        my $until = scalar @list_pkgs;
        my $saveConfig;
        my $result_cfg = $allconfig;
        while ($i < $until) {
            my $pkg_name = $list_pkgs[$i]->{'name'};
            my $bzrbranch = $list_pkgs[$i]->{'bzr-branch'};
            my $bzrbranch_status = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
            my $locdir_pkg = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check Status Branch :
            if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

                # Check If data repo is exists :
                if (-d $locdir_pkg) {

                    # Action Convert Bzr to git :
                    my $action_bzr2git = BlankOnDev::Migration::bazaar2GitHub::bazaar->bzr_convert_git($allconfig, $pkg_name);

                    print "Action Convert $pkg_name : $action_bzr2git\n";

                    # Prepare Config :
                    my $prepare_config = prepare_config();
                    $result_cfg = $prepare_config->{'bzr-convert'}($result_cfg, $pkg_name, $action_bzr2git);

                    # Save Configure :
                    $saveConfig = save_newConfig();
                    $saveConfig->{'bzr-convert'}($result_cfg);
                } else {

                    print "\n";
                    print "File Packages [$pkg_name] has deleted. \n";
                    print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
                }
            } else {

                print "\n";
                print "File Packages [$pkg_name] is not found. \n";
                print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            }
            $i++;
        }
        print "\n";
        print "====" x 5 . " Packages in group \"$input_group\" has been finished to convert ";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "bzr-cgit" :
# ------------------------------------------------------------------------
sub _bzr_cgit {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};
    my $bzr = $allconfig->{'bzr'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {
                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                print "\n";
                print "Converting .... \n";
                print "\n";

                # Action Convert :
                $self->bazaar_cgit_pkg_group($allconfig, $input_group);
                
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # Get data argument ;
        my $input_arg = $ARGV[2];

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                # Check Group Input :
                if (exists $pkg_groups->{$input_arg}) {

                    print "\n";
                    print "Converting .... \n";
                    print "\n";

                    # Action Convert :
                    $self->bazaar_cgit_pkg_group($allconfig, $input_arg);
                } else {
                    # Check Packages Input :
                    if (exists $pkg_list->{$input_arg}) {

                        print "\n";
                        print "Converting .... \n";
                        print "\n";

                        # Action Convert :
                        $self->bazaar_cgit_pkg($allconfig, $input_arg);
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages is not found. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                    }
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for git push pkg handle :
# ------------------------------------------------------------------------
sub gitpush_pkg {
    my ($self, $allconfig, $pkg_name) = @_;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Loc dir packages :
    my $data_pkg = $pkg_list->{$pkg_name};
    my $group_pkg = $data_pkg->{'group'};
    my $bzrbranch = $data_pkg->{'brz-branch'};
    my $bzrbranch_status = $data_pkg->{'status'}->{'bzr-branch'};
    my $locdir_pkg = $dir_pkgs.'/'.$group_pkg.'/'.$pkg_name;

    # Check Status Branch :
    if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

        # Check If data repo is exists :
        if (-d $locdir_pkg) {

            # Action Git Push :
            my $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->git_push($allconfig, $pkg_name, $build_rilis);

            # Print Action :
            print "Action Git push for packages $pkg_name : $action_gitpush \n";

            # Prepare Config :
            my $prepare_config = prepare_config();
            my $result_cfg = $prepare_config->{'git-push'}($allconfig, $pkg_name, $action_gitpush);

            # Save Configure :
            my $saveConfig = save_newConfig();
            $saveConfig->{'git-push'}($result_cfg);
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "File Packages [$pkg_name] is not found. \n";
            print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "File Packages [$pkg_name] is not found. \n";
        print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
    }
}
# Subroutine for git push pkg handle by group :
# ------------------------------------------------------------------------
sub gitpush_pkg_group {
    my ($self, $allconfig, $input_group) = @_;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};

    # Get list Packages based Group :
    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        # While loop to action git push :
        my $i = 0;
        my $until = scalar @list_pkgs;
        my $saveConfig;
        my $result_cfg = $allconfig;
        while ($i < $until) {
            my $pkg_name = $list_pkgs[$i]->{'name'};
            my $bzrbranch = $list_pkgs[$i]->{'bzr-branch'};
            my $bzrbranch_status = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
            my $locdir_pkg = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check Status Branch :
            if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

                # Check If data repo is exists :
                if (-d $locdir_pkg) {

                    # Action Git Push :
                    my $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->git_push($allconfig, $pkg_name, $build_rilis);

                    # Print Action :
                    print "Action Git push for packages $pkg_name : $action_gitpush \n";

                    # Prepare Config :
                    my $prepare_config = prepare_config();
                    $result_cfg = $prepare_config->{'git-push'}($result_cfg, $pkg_name, $action_gitpush);

                    # Save Configure :
                    $saveConfig = save_newConfig();
                    $saveConfig->{'git-push'}($result_cfg);
                } else {

                    print "\n";
                    print "File Packages [$pkg_name] has deleted. \n";
                    print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
                }
            } else {

                print "\n";
                print "File Packages [$pkg_name] is not found. \n";
                print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            }
            $i++;
        }
        print "\n";
        print "====" x 5 . " Packages in group \"$input_group\" has been finished to git push ";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "git-push" :
# ------------------------------------------------------------------------
sub _gitpush {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                print "\n";
                print "Push to github .... \n";
                print "\n";

                # Action git push by group :
                $self->gitpush_pkg_group($allconfig, $input_group);

            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    if ($arg_len == 3) {
        # Get data argument ;
        my $input_arg = $ARGV[2];

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                # Check Group input :
                if (exists $pkg_groups->{$input_arg}) {

                    print "\n";
                    print "Push to github .... \n";
                    print "\n";

                    # Action git push by group :
                    $self->gitpush_pkg_group($allconfig, $input_arg);
                } else {

                    # Check Packages Input :
                    if (exists $pkg_list->{$input_arg}) {

                        print "\n";
                        print "Push to github for packages $input_arg\n";
                        print "\n";

                        # Action git push :
                        $self->gitpush_pkg($allconfig, $input_arg);
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages is not found. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                    }
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for handling "git-push-new" for one packages :
# ------------------------------------------------------------------------
sub gitpush_new_pkg {
    my ($self, $allconfig, $pkg_name, $commit) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Loc dir packages :
    my $data_pkg = $pkg_list->{$pkg_name};
    my $group_pkg = $data_pkg->{'group'};
    my $bzrbranch = $data_pkg->{'brz-branch'};
    my $bzrbranch_status = $data_pkg->{'status'}->{'bzr-branch'};
    my $locdir_pkg = $dir_pkgs.'/'.$group_pkg.'/'.$pkg_name;

    # Check Status Branch :
    if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

        # Check If data repo is exists :
        if (-d $locdir_pkg) {

            # Action git push for new repo ;
            BlankOnDev::Migration::bazaar2GitHub::github->gitpush_new($allconfig, $pkg_name, $commit);

            print "\n";
            print "Git push new repositori : $pkg_name \n";
            print "Commit git push : \"$commit\"\n\n";
            exit 0;
        } else {
            print "\n";
            print "Info : Not convert to git \n";
            print "====" x 18 . "\n";
            print "File Packages [$pkg_name] has deleted. \n";
            print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "File Packages [$pkg_name] is not found. \n";
        print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
        exit 0;
    }
}
# Subroutine for handling "git-push-new" packages by group :
# ------------------------------------------------------------------------
sub gitpush_new_pkg_group {
    my ($self, $allconfig, $input_group, $commit) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};

    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        # While loop for git push new repo :
        my $i = 0;
        my $until = scalar @list_pkgs;
        while ($i < $until) {
            my $pkg_name = $list_pkgs[$i]->{'name'};
            my $bzrbranch = $list_pkgs[$i]->{'bzr-branch'};
            my $bzrbranch_status = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
            my $locdir_pkg = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check Status Branch :
            if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

                # Check If data repo is exists :
                if (-d $locdir_pkg) {

                    # Action git push for new repo ;
                    BlankOnDev::Migration::bazaar2GitHub::github->gitpush_new($allconfig, $pkg_name, $commit);

                    print "\n";
                    print "Git push new repositori : $pkg_name \n";
                    print "Commit git push : \"$commit\"\n";
                } else {

                    print "\n";
                    print "File Packages [$pkg_name] has deleted. \n";
                    print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
                }
            } else {

                print "\n";
                print "File Packages [$pkg_name] is not found. \n";
                print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            }
            $i++;
        }

        print "\n";
        print "push to git has been finished \n";
        print "----" x 10 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file <location_of_packages_list.boikg>\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "git-push-new" :
# ------------------------------------------------------------------------
sub _gitpush_new {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;
    my $input_commit = 'new repositori';

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                print "\n";
                print "Push to github .... \n";
                print "----" x 10 . "\n";
                print "\n";

                # Form for enter your commit :
                print "\n";
                print "Enter \"commit\" for git push : ";
                chomp($input_commit = <STDIN>);
                if ($input_commit ne '') {
                    $input_commit = $input_commit;
                    $input_commit =~ s/\"+//g;
                    $input_commit =~ s/\'+//g;
                }

                # Action git push by group :
                $self->gitpush_new_pkg_group($allconfig, $input_group, $input_commit);

            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # Get data argument ;
        my $input_arg = $ARGV[2];

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                print "\n";
                print "Push to github .... \n";
                print "----" x 10 . "\n";
                print "\n";

                # Check Group Input :
                if (exists $pkg_groups->{$input_arg}) {

                    # Form for enter your commit :
                    print "\n";
                    print "Enter \"commit\" for git push : ";
                    chomp($input_commit = <STDIN>);
                    if ($input_commit ne '') {
                        $input_commit = $input_commit;
                    }

                    # Action git push by group :
                    $self->gitpush_new_pkg_group($allconfig, $input_arg, $input_commit);

                } else {
                    # Check Packages Input :
                    if (exists $pkg_list->{$input_arg}) {

                        # Form for enter your commit :
                        print "\n";
                        print "Enter \"commit\" for git push : ";
                        chomp($input_commit = <STDIN>);
                        if ($input_commit ne '') {
                            $input_commit = $input_commit;
                            $input_commit =~ s/\"+//g;
                            $input_commit =~ s/\'+//g;
                        }

                        # action :
                        $self->gitpush_new_pkg($allconfig, $input_arg, $input_commit);
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages is not found. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                        exit 0;
                    }
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for action re-branch pkg :
# ------------------------------------------------------------------------
sub rebranch_pkg {
    my ($self, $allconfig, $group_pkg, $pkg_name, $action_rebranch) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $locdir_group = $dir_pkgs.'/'.$group_pkg;

    # Check Group Directori :
    unless (-d $locdir_group) {
        mkdir($locdir_group);
    }

    # Action bzr Branch :
    my $act_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->branch($action_rebranch, $allconfig, $group_pkg, $pkg_name);

    # Prepare Configure Bzr Branch :
    my $prepare_cfg = prepare_config();
    my $result_cfg = $prepare_cfg->{'bzr-branch'}($allconfig, $pkg_name, $act_branch);

    # Save Configure :
    my $saveConfig = save_newConfig();
    $saveConfig->{'bzr-branch'}($result_cfg);
    print "\n";
    print "====" x 5 . " Packages $pkg_name has been finished to bzr branch ";
    print "====" x 5 . "\n\n";
    exit 0;
}
# Subroutine for action re-branch pkg by group :
# ------------------------------------------------------------------------
sub rebranch_pkg_group {
    my ($self, $allconfig, $input_group) = @_;

    # Define scalar :
    my $act_branch;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $locdir_group = $dir_pkgs.'/'.$input_group;

    # Check Group Directori :
    unless (-d $locdir_group) {
        mkdir($locdir_group);
    }

    print "\n";

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $logs_dir = $data_dev->{'dirlogs'};
    my $prefix_log = $data_dev->{'prefix_bzrbranch_log'};
    my $ext_out_log = $data_dev->{'log_ext_out'};
    my $ext_err_log = $data_dev->{'log_ext_err'};

    # Get list Packages based Group :
    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        my $i = 0;
        my $size_list = scalar keys(@list_pkgs);
        my $saveConfig;
        my $result_cfg = $allconfig;
        my $num = $i;
        while ($i < $size_list) {
            $num = $num + 1;
            my $group_name = $list_pkgs[$i]->{'group'};
            my $pkg_name = $list_pkgs[$i]->{'name'};

            # For file/dir pkgs :
            my $dest_dir = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check exists pkg :
            if (-d $dest_dir) {

                # Action bzr Branch :
                $act_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->branch('rm', $result_cfg, $group_name, $pkg_name);
            } else {

                # Action bzr Branch :
                $act_branch = BlankOnDev::Migration::bazaar2GitHub::bazaar->branch('no', $result_cfg, $group_name, $pkg_name);
            }

            print " $act_branch\n";

            # Prepare Configure Bzr Branch :
            my $prepare_cfg = prepare_config();
            $result_cfg = $prepare_cfg->{'bzr-branch'}($result_cfg, $pkg_name, $act_branch);

            # Save Configure :
            $saveConfig = save_newConfig();
            $saveConfig->{'bzr-branch'}($result_cfg);

            $i++;
        }

        print "\n";
        print "====" x 5 . " bzr branch has finished ";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "re-branch" :
# ------------------------------------------------------------------------
sub _re_branch {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;
    my $confirm_rebranch;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {
                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                # Check Group Packages Input :
                if (exists $curr_dataPkg_grp->{$input_group}) {

                    # Action Branch :
                    $self->rebranch_pkg_group($allconfig, $input_group);

                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Group is not found !!!\n\n";
                    exit 0;
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {

        # Define scalar :
        my $input_arg = $ARGV[2];
        my $confirm_grp;

        # Check Group :
        if (exists $pkg_groups->{$input_arg}) {

            # For Confirm :
            print "\n";
            print "You want to branch based group [y/n] : ";
            chomp($confirm_grp = <STDIN>);
            if ($confirm_grp eq 'y' or $confirm_grp eq 'Y') {

                # Action Branch :
                $self->rebranch_pkg_group($allconfig, $input_arg);
            } else {

                print "\n";
                print "Program has aborted.\n\n";
            }
        } else {
            # Check Packages :
            if (exists $pkg_list->{$input_arg}) {
                my $r_pkgGrp = $pkg_list->{$input_arg}->{'group'};

                # For file/dir pkgs :
                my $dest_dir = $dir_pkgs.'/'.$r_pkgGrp.'/'.$input_arg;

                # Check packages in Local dir :
                if (-d $dest_dir) {

                    # Form Confirm :
                    print "\n";
                    print "You want to Re-branch [y/n] : ";
                    chomp($confirm_rebranch = <STDIN>);
                    if ($confirm_rebranch eq 'y' or $confirm_rebranch eq 'Y') {

                        # Msg :
                        print "\n";
                        print "Bazaar re-branch for packages : \"$input_arg\"\n";

                        # Action Branch :
                        $self->rebranch_pkg($allconfig, $r_pkgGrp, $input_arg, 'rm');
                    }
                } else {

                    # Msg :
                    print "\n";
                    print "Bazaar Branch for packages : \"$input_arg\"\n";

                    # Action Branch :
                    $self->branch_pkg($allconfig, $r_pkgGrp, $input_arg, 'new');
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "Not found packages. Please try another packages.\n\n";
                exit 0;
            }
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for handle action "re-gitpush" package :
# ------------------------------------------------------------------------
sub regitpush_pkg {
    my ($self, $allconfig, $pkg_name) = @_;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # For Check Branch :
    my $data_pkg = $pkg_list->{$pkg_name};
    my $group_pkg = $data_pkg->{'group'};
    my $bzrbranch = $data_pkg->{'brz-branch'};
    my $bzrbranch_status = $data_pkg->{'status'}->{'bzr-branch'};
    my $bzrCgit_status = $data_pkg->{'status'}->{'bzrConvertGit'};
    my $locdir_pkg = $dir_pkgs.'/'.$group_pkg.'/'.$pkg_name;

    # Check Status Branch :
    if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

        # Check File :
        if (-d $locdir_pkg) {

            # Check Result convert to github format :
            if ($bzrCgit_status eq 1) {

                # Action :
                my $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->repush_git($allconfig, $pkg_name, $build_rilis);

                # Prepare Config :
                my $prepare_config = prepare_config();
                my $result_cfg = $prepare_config->{'git-push'}($allconfig, $pkg_name, $action_gitpush);

                # Save Configure :
                my $saveConfig = save_newConfig();
                $saveConfig->{'git-push'}($result_cfg);

                print "\n";
                print "re-push to git for packages \"$pkg_name\" has success. \n";
                print "\n";
                exit 0;
            } else {
                print "\n";
                print "Info : Not convert to git \n";
                print "====" x 18 . "\n";
                print "File Packages [$pkg_name] not convert to github format repository. \n";
                print "Please run command \"boidev bzr2git bzr-cgit <packages_name>\" for converting format repository to github.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "File Packages [$pkg_name] has deleted. \n";
            print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
            exit 0;
        }
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "File Packages [$pkg_name] is not found. \n";
        print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package from bazaar server repository..\n\n";
        exit 0;
    }
}
# Subroutine for handle action "re-gitpush" packages by group :
# ------------------------------------------------------------------------
sub regitpush_pkg_group {
    my ($self, $allconfig, $input_group) = @_;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};

    # Get list Packages based Group :
    my $list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($list_pkg->{'result'} == 1) {
        my @list_pkgs = @{$list_pkg->{'data'}};

        # While loop to action git push :
        my $i = 0;
        my $until = scalar @list_pkgs;
        my $result_cfg = $allconfig;
        while ($i < $until) {
            my $pkg_name = $list_pkgs[$i]->{'name'};
            my $bzrbranch = $list_pkgs[$i]->{'bzr-branch'};
            my $bzrbranch_status = $list_pkgs[$i]->{'status'}->{'bzr-branch'};
            my $bzrCgit_status = $list_pkgs[$i]->{'status'}->{'bzrConvertGit'};
            my $locdir_pkg = $dir_pkgs.'/'.$input_group.'/'.$pkg_name;

            # Check Status Branch :
            if ($bzrbranch eq 1 or ($bzrbranch eq 0 and $bzrbranch_status eq 1)) {

                # Check File ;
                if (-d $locdir_pkg) {

                    # Check result convert :
                    if ($bzrCgit_status eq 1) {

                        # Action Git Push :
                        my $action_gitpush = BlankOnDev::Migration::bazaar2GitHub::github->repush_git($allconfig, $pkg_name, $build_rilis);

                        # Print Action :
                        print "Action re-push git for packages $pkg_name : $action_gitpush \n";

                        # Prepare Config :
                        my $prepare_config = prepare_config();
                        $result_cfg = $prepare_config->{'git-push'}($result_cfg, $pkg_name, $action_gitpush);

                        # Save Configure :
                        my $saveConfig = save_newConfig();
                        $saveConfig->{'git-push'}($result_cfg);
                    } else {
                        print "\n";
                        print "File Packages [$pkg_name] not convert to github format repository. \n";
                        print "Please run command \"boidev bzr2git bzr-cgit <packages_name>\" for converting format repository to github.\n\n";
                    }
                } else {
                    print "\n";
                    print "File Packages [$pkg_name] has deleted. \n";
                    print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$pkg_name] from bazaar server repository..\n\n";
                }
            } else {

                print "\n";
                print "File Packages [$pkg_name] is not found. \n";
                print "Please run command \"boidev bzr2git branch <packages_name>\" to branch package [$pkg_name] from bazaar server repository..\n\n";
            }
            $i++;
        }
        print "\n";
        print "====" x 5 . " Packages in group \"$input_group\" has been finished re-push to git";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "re-gitpush" :
# ------------------------------------------------------------------------
sub _re_gitpush {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $num_pkg_group;
    my $input_group;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};

    # Data current config :
    my $curr_dataPkg_grp = $allconfig->{'pkg'}->{'group'};
    my $curr_data_pkg = $allconfig->{'pkg'}->{'pkgs'};
    my $size_pkgGrp = scalar keys(%{$curr_dataPkg_grp});
    my $size_pkg = scalar keys(%{$curr_data_pkg});

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                # Form Group Packages :
                print "\n";
                print "Choose Group Packages.\n";

                my $num = 0;
                my %num_grp = ();
                while (my ($key, $value) = each %{$curr_dataPkg_grp}) {
                    my $_num = $num + 1;
                    $num_grp{$_num} = $key;
                    print "$_num. $key\n";
                    $num++;
                }
                print "Enter Number choice : ";
                chomp($num_pkg_group = <STDIN>);
                if ($num_pkg_group eq '') {
                    $input_group = '';
                    print "\n";
                    print "Please Number choice for Group Packages...\n";
                } else {
                    if ($num_pkg_group =~ m/^[0-9]+$/) {
                        $input_group = $num_grp{$num_pkg_group} if exists $num_grp{$num_pkg_group};
                        $input_group = 'no' unless exists $num_grp{$num_pkg_group};
                    } else {
                        print "\n";
                        print "Choice Group only Numberic...\n\n";
                        exit 0;
                    }
                }

                print "\n";
                print "Re-push to GitHub .... \n";
                print "----" x 10 . "\n";
                print "\n";

                # Action git push by group :
                $self->regitpush_pkg_group($allconfig, $input_group);

            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {

        # Define scalar :
        my $input_arg = $ARGV[2];

        # Check Group :
        if ($size_pkgGrp > 0) {

            # Check list Packages
            if ($size_pkg > 0) {

                print "\n";
                print "Re-push to GitHub .... \n";
                print "----" x 10 . "\n";
                print "\n";

                # Check Group input :
                if (exists $pkg_groups->{$input_arg}) {

                    # Action git push by group :
                    $self->regitpush_pkg_group($allconfig, $input_arg);
                } else {

                    # Check Packages Input :
                    if (exists $pkg_list->{$input_arg}) {

                        # Action git push for one packages :
                        $self->regitpush_pkg($allconfig, $input_arg);
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "Packages is not found. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                    }
                }
            } else {
                print "\n";
                print "Info : \n";
                print "====" x 18 . "\n";
                print "No more packages in list. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                exit 0;
            }
        } else {
            print "\n";
            print "Info : \n";
            print "====" x 18 . "\n";
            print "Not found packages groups. Please run command \"boidev bzr2git addpkg-group\" to add new group packages.\n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # -----------------------------------------------------------------b-------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for check all packages on github :
# ------------------------------------------------------------------------
sub git_check_allpkg {
    my ($self, $allconfig) = @_;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};

    # Get list packages group :
    my $get_list_grp = $self->list_all_pkg_group($allconfig);

    my @list_group = %{$get_list_grp->{'data'}};

    # While loop for group packages :
    my $i = 0;
    my $until = scalar @list_group;
    my $prepare_config;
    my $result_cfg;
    while ($i < $until) {
        my $pkg_group = $list_group[$i];

        # Print Header :
        print "\n";
        print "Check repo on github for packages in group $pkg_group : \n";

        # Get list packages by group :
        my $list_pkg = $self->filter_listpkg_based_group($allconfig, $pkg_group);
        if ($list_pkg->{'result'} eq 1) {
            my @list_pkg = @{$list_pkg->{'data'}};

            # While loop for check packages :
            my $i_p = 0;
            my $until_p = scalar @list_pkg;
            while ($i_p < $until_p) {
                my $data_package = $list_pkg[$i_p];
                my $data_pkg_name = $data_package->{'name'};
                my $data_pkg_group = $data_package->{'group'};
                my $locdir_pkg = $dir_pkgs.'/'.$data_pkg_group.'/'.$data_pkg_name;

                # Check dir packages :
                if (-d $locdir_pkg) {

                    # Action Command :
                    my $action_check = BlankOnDev::Migration::bazaar2GitHub::github->git_check($allconfig, $data_pkg_name);

                    print "Group packages $pkg_group = No List Packages\n";

                    # prepare Config :
                    $prepare_config = prepare_config();
                    $result_cfg = $prepare_config->{'git-check'}($allconfig, $data_pkg_name, $action_check);

                    # Save Configure :
                    my $saveConfig = save_newConfig();
                    $saveConfig->{'git-check'}($result_cfg);
                } else {

                    print "\n";
                    print "File Packages [$data_pkg_name] is not found. \n";
                    print "Please run command \"boidev bzr2git branch <packages_name>\" to download file package [$data_pkg_name] from bazaar server repository..\n\n";
                }

                $i_p++;
            }
            print "\n";
            print "====" x 5 . " Git Check All Packages has finished";
            print "====" x 5 . "\n\n";
            exit 0;
        } else {
            print "Group packages $pkg_group = No List Packages\n";
        }
        $i++;
    }
}
# Subroutine for check all packages by group :
# ------------------------------------------------------------------------
sub git_check_allpkg_grp {
    my ($self, $allconfig, $input_group) = @_;

    # Define scalar :
    my $act_gitcheck;

    # For All config :
    my $curr_build = $allconfig->{'build'};
    my $build_rilis = $curr_build->{'rilis'};
    my $curr_pkg = $allconfig->{'pkg'};
    my $dir_pkgs = $curr_pkg->{'dirpkg'};
    my $locdir_group = $dir_pkgs.'/'.$input_group;

    my $get_list_pkg = $self->filter_listpkg_based_group($allconfig, $input_group);
    if ($get_list_pkg->{'result'} eq 1) {
        my @list_pkgs = @{$get_list_pkg->{'data'}};

        # Print Header :
        print "\n";
        print "Check repo on github for all packages : \n";

        # While loop to action git push :
        my $i = 0;
        my $until = scalar @list_pkgs;
        my $saveConfig;
        my $result_cfg = $allconfig;
        while ($i < $until) {
            my $data_package = $list_pkgs[$i];
            my $data_pkg_name = $data_package->{'name'};
            my $data_pkg_group = $data_package->{'group'};
            my $locdir_pkg = $dir_pkgs.'/'.$input_group.'/'.$data_pkg_name;

            # Check dir packages :
            if (-d $locdir_pkg) {

                # Action Command :
                $act_gitcheck = BlankOnDev::Migration::bazaar2GitHub::github->git_check($allconfig, $data_pkg_name);

                # Print "Header"
                print "Check Repo [$data_pkg_name] on github : $act_gitcheck \n";

                # prepare Config :
                my $prepare_config = prepare_config();
                $result_cfg = $prepare_config->{'git-check'}($result_cfg, $data_pkg_name, $act_gitcheck);

                # Save Configure :
                $saveConfig = save_newConfig();
                $saveConfig->{'git-check'}($result_cfg);
            } else {

                print "\n";
                print "File Packages [$data_pkg_name] is not found. \n";
                print "Please run command \"boidev bzr2git branch <packages_name>\" to download file package [$data_pkg_name] from bazaar server repository..\n\n";
            }
            $i++;
        }
        print "\n";
        print "====" x 5 . " Git Check All Packages on Group [$input_group] has finished";
        print "====" x 5 . "\n\n";
        exit 0;
    } else {
        print "\n";
        print "Info : \n";
        print "====" x 18 . "\n";
        print "Not found packages in list on group $input_group. Please run command \"boidev bzr2git addpkg\" to add new packages in group.\n\n";
        exit 0;
    }
}
# Subroutine for option "git-check" :
# ------------------------------------------------------------------------
sub _git_check {
    my ($self, $allconfig) = @_;

    # Define scalar :
    my $arg_len = scalar @ARGV;
    my $form_group;

    # For All config :
    my $curr_pkg = $allconfig->{'pkg'};
    my $curr_dirpkg = $curr_pkg->{'dirpkg'};
    my $pkg_groups = $curr_pkg->{'group'};
    my $pkg_list = $curr_pkg->{'pkgs'};
    my $data_list_grp = $self->bzr2git_get_list_group_amount_pkg($allconfig);
    my $choice_grp = $data_list_grp->{'data'};

    # ------------------------------------------------------------------------
    # Check IF $arg_len == 2 :
    # ------------------------------------------------------------------------
    if ($arg_len == 2) {

        # Form :
        print "\n";
        print "Choose packages group : \n";
        print "---" x 18 . "\n";
        print $data_list_grp->{'choice'};
        print "---" x 18 . "\n";
        print "Enter number of group name : ";
        chomp($form_group = <STDIN>);
        if (exists $choice_grp->{$form_group}) {
            my $input_group = $choice_grp->{$form_group};

            # Action Check :
            $self->git_check_allpkg_grp($allconfig, $input_group);
        } else {
            print "\n";
            print "Info : Enter number choice\n";
            print "====" x 18 . "\n";
            print "Please enter number choice. \n\n";
            exit 0;
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 :
    # ------------------------------------------------------------------------
    elsif ($arg_len == 3) {
        # Get data argument ;
        my $input_arg = $ARGV[2];

        # Check if $input_arg == 'all' :
        if ($input_arg eq 'all') {

            # Check All group :
            $self->git_check_allpkg($allconfig);

        } else {

            # Check Input in Group :
            if (exists $pkg_groups->{$input_arg}) {

                # Action Check :
                $self->git_check_allpkg_grp($allconfig, $input_arg);
            } else {

                # Check Input in packages :
                if (exists $pkg_list->{$input_arg}) {
                    my $data_package = $pkg_list->{$input_arg};
                    my $data_pkg_name = $data_package->{'name'};
                    my $data_pkg_group = $data_package->{'group'};
                    my $loc_of_pkg = $curr_dirpkg.'/'.$data_pkg_group.'/'.$data_pkg_name;

                    # Check if exists dir packages :
                    if (-d $loc_of_pkg) {

                        # Action Command :
                        my $action_check = BlankOnDev::Migration::bazaar2GitHub::github->git_check($allconfig, $data_pkg_name);

                        # Print "Header"
                        print "Check Repo [$data_pkg_name] on github : $action_check \n";

                        # prepare Config :
                        my $prepare_config = prepare_config();
                        my $result_cfg = $prepare_config->{'git-check'}($allconfig, $data_pkg_name, $action_check);

                        # Save Configure :
                        my $saveConfig = save_newConfig();
                        $saveConfig->{'git-check'}($result_cfg);

                        print "\n";
                        print "git check repository for packages \"$data_pkg_name\" | $action_check. \n";
                        print "\n";
                    } else {
                        print "\n";
                        print "Info : \n";
                        print "====" x 18 . "\n";
                        print "File Packages [$data_pkg_name] has deleted. \n";
                        print "Please run command \"boidev bzr2git re-branch <packages_name>\" to download file package [$data_pkg_name] from bazaar server repository..\n\n";
                        exit 0;
                    }

                } else {
                    print "\n";
                    print "Info : \n";
                    print "====" x 18 . "\n";
                    print "Packages is not found. Please run command \"boidev bzr2git addpkg\" or \"boidev bzr2git addpkg-file\" to add new packages in list.\n\n";
                    exit 0;
                }
            }
        }
    }
    # ------------------------------------------------------------------------
    # Check IF $arg_len == 3 or $arg_len == 2 :
    # ------------------------------------------------------------------------
    else {
        my $i = 0;
        my $data_cmd = '';
        foreach my $arg (each @ARGV) {
            if ($arg_len - 1 == $i) {
                $data_cmd .= $arg;
            } else {
                $data_cmd .= "$arg ";
            }
            $i++;
        }
        print "\n";
        print "====" x 18 . "\n";
        print "your command: boidev $data_cmd\n";
        print "----" x 18 . "\n";
        print "\n";
        print "Warning : \n";
        print "====" x 18 . "\n";
        print "This command max three arguments\n\n";
        exit 0;
    }
    # ------------------------------------------------------------------------
    # End of check IF $arg_len == 3 or $arg_len == 2.
    # ========================================================================
}
# Subroutine for option "help" :
# ------------------------------------------------------------------------
sub usage {
    print "\n";
    print "-----" x 15 . "\n";
    print " For Help Command : \n";
    print "-----" x 15 . "\n";
    print "\n";

    print "USAGE : boidev bzr2git <OPTIONS2>\n";
    BlankOnDev::usage_bzr2git;
    print "\n";
    exit 0;
}
# Subroutine for option help command "boidev bzr2git <OPTIONS2> <OPTIONS3> :
# ------------------------------------------------------------------------
sub usage_arg_3 {
    my $options3 = {
        'addpkg-group' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git addpkg-group <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_addpkg_group();
            print "\n";
            exit 0;
        },
        'addpkg' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git addpkg <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_addpkg();
            print "\n";
            exit 0;
        },
        'addpkg-file' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git addpkg-file <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_addpkgfile();
            print "\n";
            exit 0;
        },
        'list-pkg' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git list-pkg <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_listpkg();
            print "\n";
            exit 0;
        },
        'rename-pkg-group' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git rename-pkg-group <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_renamepkg_group();
            print "\n";
            exit 0;
        },
        'remove-pkg-group' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git remove-pkg-group <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_removepkg_group();
            print "\n";
            exit 0;
        },
        'remove-pkg' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git removepkg <OPTIONS3>\n\n";
            BlankOnDev::usage_bzr2git_removepkg();
            print "\n";
            exit 0;
        },
        'search-pkg' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git search-pkg <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git search-pkg <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_searchpkg();
            print "\n";
            exit 0;
        },
        'branch' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git branch <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git branch <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_branch();
            print "\n";
            exit 0;
        },
        'bzr-cgit' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git bzr-cgit <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git bzr-cgit <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_bzr_cgit();
            print "\n";
            exit 0;
        },
        'git-push' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git git-push <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git git-push <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_gitpush();
            print "\n";
            exit 0;
        },
        'git-push-new' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git git-push-new <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git git-push-new <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_gitpush_new();
            print "\n";
            exit 0;
        },
        'git-check' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git git-check <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git git-check <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_git_check();
            print "\n";
            exit 0;
        },
        're-branch' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git re-branch <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git re-branch <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_reBranch();
            print "\n";
            exit 0;
        },
        're-gitpush' => sub {
            print "\n";
            print "-----" x 15 . "\n";
            print " For Help Command : boidev $ARGV[0] $ARGV[1] \n";
            print "-----" x 15 . "\n";
            print "\n";

            print "USAGE : boidev bzr2git re-branch <OPTIONS3>\n";
            print "-- or --\n";
            print "USAGE : boidev bzr2git re-branch <INPUT>\n\n";
            BlankOnDev::usage_bzr2git_reGitpush();
            print "\n";
            exit 0;
        }
    };
    if (exists $options3->{$ARGV[1]}) {
        $options3->{$ARGV[1]}();
    } else {
        usage();
    }
}
# Subroutine for cmd :
# ------------------------------------------------------------------------
sub list_cmd {
    my %data = ();
    $data{'bzr'} = {
        'branch' => 'bzr branch',
        'bzr' => {
            'bzr-export' => 'bzr fast-export',
            'bzr-fast-import' => 'git fast-import'
        },
        'git' => {
            'init' => 'git init',
            'reset-head' => 'git reset HEAD',
            'remote' => 'git remote add origin',
            'push' => 'git push -u origin master',
        }
    };
    return \%data;
}
# Subroutine for save new configure :
# ------------------------------------------------------------------------
sub save_newConfig {
    my $data_rilis = $BlankOnDev::config::rilisCfg;

    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $dir_dev = $data_dev->{'dir_dev'};
    my $prefix_flcfg = $data_dev->{'prefix_flcfg'};
    my $file_cfg_ext = $data_dev->{'fileCfg_ext'};
    my $file_name = $prefix_flcfg.$data_rilis.$file_cfg_ext;

    # Define hashref for switch :
    my $switch = {
        'addpkg' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'addgroup' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'removePkg' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'rename-pkg-group' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'remove-group' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'bzr-branch' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'bzr-convert' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'git-push' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'git-check' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        },
        'bzr2git' => sub {
            my ($new_config) = @_;

            # Create File :
            my $newData_cfg = encode_json($new_config);
            BlankOnDev::Utils::file->create($file_name, $dir_dev, $newData_cfg);
        }
    };

    return $switch;
}
# Subroutine for prepare new configure :
# ------------------------------------------------------------------------
sub prepare_config {

    # Define hashref for switch :
    my $switch = {
        'newpkg' => sub {
            my ($curr_cfg, $data_newpkg) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_pkg;

            # Define scalar for new pkg :
            my $new_group = $data_newpkg->{'group'};
            my $new_pkg = $data_newpkg->{'pkg'};

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};

            # Get DateTime :
            my $timestamp = time();
            my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
                    'date' => '-',
                    'time' => ':',
                    'datetime' => ' ',
                    'format' => 'DD-MM-YYYY hms'
                });
            my $time_add = $get_dataTime->{'custom'};

            # Check data group pkg :
            if (exists $curr_pkg->{'group'}) {
                # Add Group Packages :
                my $add_group = Hash::MultiValue->new(%{$curr_pkg->{'group'}});
                $add_group->add($new_group => 0);
                my $r_addGroup = $add_group->as_hashref;

                # Add Packages :
                my $add_pkg = Hash::MultiValue->new(%{$curr_pkg->{'pkgs'}});
                $add_pkg->add($new_pkg => {
                        'name' => $new_pkg,
                        'group' => $new_group,
                        'brz-branch' => 0,
                        'git-push' => 0,
                        'status' => {
                            'bzr-branch' => 0,
                            'git-push' => 0,
                            'bzrConvertGit' => 0,
                        },
                        'date-add' => $time_add,
                        'date-branch' => '',
                        'date-gitpush' => '',
                    });
                my $r_addPkg = $add_pkg->as_hashref;

                # Merge :
                my $mergePkg = Hash::MultiValue->new(%{$curr_pkg});
                $mergePkg->set('group' => $r_addGroup);
                $mergePkg->set('pkgs' => $r_addPkg);
                $newData_pkg = $mergePkg->as_hashref;
            } else {
                # Add Group Packages :
                my $add_group = Hash::MultiValue->new(%{$curr_cfg->{'pkg'}});
                $add_group->add('group' => {
                        $new_group => 1
                    });
                my $r_addGroup = $add_group->as_hashref;

                # Add Packages :
                my $add_pkg = Hash::MultiValue->new(%{$r_addGroup});
                $add_pkg->add('pkgs' => {
                        $new_pkg => {
                            'group' => $new_group,
                            'brz-branch' => 0,
                            'git-push' => 0,
                        }
                    });
                my $r_addPkg = $add_pkg->as_hashref;

                # Merge :
                $newData_pkg = $r_addPkg;
            }

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = $newData_pkg;

            return \%data;
        },
        'newpkg-grp-exists' => sub {
            my ($curr_cfg, $data_newpkg) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_pkg;
            my $mergePkgs;

            # Define scalar for new pkg :
            my $new_group = $data_newpkg->{'group'};
            my $new_pkg = $data_newpkg->{'pkg'};

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};

            # Get DateTime :
            my $timestamp = time();
            my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
                    'date' => '-',
                    'time' => ':',
                    'datetime' => ' ',
                    'format' => 'DD-MM-YYYY hms'
                });
            my $time_add = $get_dataTime->{'custom'};

            # Add Packages :
            my $add_pkg = Hash::MultiValue->new(%{$curr_pkg->{'pkgs'}});
            $add_pkg->add($new_pkg => {
                    'name' => $new_pkg,
                    'group' => $new_group,
                    'brz-branch' => 0,
                    'git-push' => 0,
                    'status' => {
                        'bzr-branch' => 0,
                        'git-push' => 0,
                        'bzrConvertGit' => 0,
                    },
                    'date-add' => $time_add,
                    'date-branch' => '',
                    'date-gitpush' => '',
                });
            my $r_addPkg = $add_pkg->as_hashref;

            # Merge :
            $mergePkgs = Hash::MultiValue->new(%{$curr_pkg});
            $mergePkgs->set('pkgs' => $r_addPkg);
            $newData_pkg = $mergePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = $newData_pkg;

            return \%data;
        },
        'add-group' => sub {
            my ($curr_cfg, $data_newgrp) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_group;
            my $result_merge;

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $size_group = scalar keys(%{$pkg_group});

            if ($size_group > 0) {
                my $add_group = Hash::MultiValue->new(%{$pkg_group});
                $add_group->add($data_newgrp => 0);
                $newData_group = $add_group->as_hashref;
            } else {
                my $add_group = Hash::MultiValue->new(%{$pkg_group});
                $add_group->add($data_newgrp => 0);
                $newData_group = $add_group->as_hashref;
            }

            # Merge :
            my $forMerger = Hash::MultiValue->new(%{$curr_pkg});
            $forMerger->set('group' => $newData_group);
            $result_merge = $forMerger->as_hashref;

            # Place new data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = $result_merge;

            return \%data;
        },
        'rename-group-pkg' => sub {
            my ($curr_cfg, $old_pkg_group, $new_pkg_group) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_group;

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $curr_dirpkgs = $curr_pkg->{'dirpkg'};
            my $curr_pkgGrp = $curr_pkg->{'group'};
            my $curr_pkgs = $curr_pkg->{'pkgs'};

            # For Data Developer :
            my $data_dev = BlankOnDev::DataDev::data_dev();

            # For Data Packages :
            my $dir_pkgs = $data_dev->{'dir_pkg'};
            my $locdir_pkgs = $dir_pkgs.'/'.$build_rilis.'/'.$old_pkg_group.'/';
            my $new_locdir_pkgs = $dir_pkgs.'/'.$build_rilis.'/'.$new_pkg_group.'/';

            # Check Local Directory Packages :
            if (-d $locdir_pkgs) {
                system("mv -f $locdir_pkgs $new_locdir_pkgs");
            }

            # Rename Group name :
            my $rename_grp = Hash::MultiValue->new(%{$curr_pkgGrp});
            $rename_grp->remove($old_pkg_group);
            $rename_grp->add($new_pkg_group => 0);
            $newData_group = $rename_grp->as_hashref;

            # Place data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $curr_dirpkgs,
                'group' => $newData_group,
                'pkgs' => $curr_pkgs
            };

            return \%data;

        },
        'rename-pkg-group' => sub {
            my ($curr_cfg, $old_pkg_group, $new_pkg_group, $pkg_name) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_pkg;

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $curr_dirpkgs = $curr_pkg->{'dirpkg'};
            my $curr_pkgGrp = $curr_pkg->{'group'};
            my $list_pkgs = $curr_pkg->{'pkgs'};

            # For Data Developer :
            my $data_dev = BlankOnDev::DataDev::data_dev();

            # For Data Packages :
            my $dir_pkgs = $data_dev->{'dir_pkg'};
            my $locdir_pkgs = $dir_pkgs.'/'.$build_rilis.'/'.$old_pkg_group.'/';
            my $new_locdir_pkgs = $dir_pkgs.'/'.$build_rilis.'/'.$new_pkg_group.'/';

            # Check Local Directory Packages :
            if (-d $locdir_pkgs) {
                system("mv -f $locdir_pkgs $new_locdir_pkgs");
            }

            # Rename group in data packages :
            my $rename_grpInPkg = Hash::MultiValue->new(%{$list_pkgs->{$pkg_name}});
            $rename_grpInPkg->set('group' => $new_pkg_group);
            my $result_changeGrp = $rename_grpInPkg->as_hashref;

            # Merge Data :
            my $forMerge = Hash::MultiValue->new(%{$list_pkgs});
            $forMerge->set($pkg_name => $result_changeGrp);
            $newData_pkg = $forMerge->as_hashref;

            # Place data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $curr_dirpkgs,
                'group' => $curr_pkgGrp,
                'pkgs' => $newData_pkg
            };

            return \%data;
        },
        'remove-group' => sub {
            my ($curr_cfg, $old_group_name) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_group;

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $curr_dirpkgs = $curr_pkg->{'dirpkg'};
            my $curr_pkgGrp = $curr_pkg->{'group'};
            my $curr_pkgs = $curr_pkg->{'pkgs'};

            # For Data Developer :
            my $data_dev = BlankOnDev::DataDev::data_dev();

            # For Data Packages :
            my $dir_pkgs = $data_dev->{'dir_pkg'};
            my $locdir_group = $dir_pkgs.'/'.$build_rilis.'/'.$old_group_name.'/';

            # Check Local Group :
            if (-d $locdir_group) {
                system("rm -rf $locdir_group");
            }

            # Remove Group :
            my $remove_group = Hash::MultiValue->new(%{$curr_pkgGrp});
            $remove_group->remove($old_group_name);
            $newData_group = $remove_group->as_hashref;

            # Place data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $curr_dirpkgs,
                'group' => $newData_group,
                'pkgs' => $curr_pkgs
            };

            return \%data;
        },
        'remove-pkg' => sub {
            my ($curr_cfg, $pkg_names) = @_;

            # Define hash of scalar :
            my %data = ();
            my $newData_pkg;
            my $delData_pkg;

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $curr_dirpkgs = $curr_pkg->{'dirpkg'};
            my $curr_pkgGrp = $curr_pkg->{'group'};
            my $list_pkgs = $curr_pkg->{'pkgs'};

            # For Data Developer :
            my $data_dev = BlankOnDev::DataDev::data_dev();
            my $home_dir = $data_dev->{'home_dir'};
            my $dir_dev = $data_dev->{'dir_dev'};
            my $prefix_flcfg = $data_dev->{'prefix_flcfg'};
            my $file_cfg_ext = $data_dev->{'fileCfg_ext'};

            # For Data Packages :
            my $dir_pkgs = $data_dev->{'dir_pkg'};
            my $dir_pkgGrp = $list_pkgs->{$pkg_names}->{'group'};
            my $locdir_pkgs = $dir_pkgs.'/'.$build_rilis.'/'.$dir_pkgGrp.'/';

            # Remove in config ;
            my $remove_pkgs = Hash::MultiValue->new(%{$list_pkgs});
            $remove_pkgs->remove($pkg_names);
            $newData_pkg = $remove_pkgs->as_hashref;

            # Check Local Directory Packages :
            if (-d $locdir_pkgs) {
                # Form :
                print "\n";
                print "You want delete Packages in Local Directory [y/n] : ";
                chomp($delData_pkg = <STDIN>);
                if ($delData_pkg eq 'y' or $delData_pkg eq 'Y') {
                    rmdir $locdir_pkgs;
                }
            }

            # Place data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $curr_dirpkgs,
                'group' => $curr_pkgGrp,
                'pkgs' => $newData_pkg
            };

            return \%data;
        },
        'bzr-branch' => sub {
            my ($curr_cfg, $pkg_input, $r_branch) = @_;

            # Define hash or scalar :
            my %data = ();

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_dirpkg = $curr_pkg->{'dirpkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $pkg_list = $curr_pkg->{'pkgs'};

            # Data Current Packages :
            my $dataCurr_pkg = $pkg_list->{$pkg_input};
            my $status_pkg = $dataCurr_pkg->{'status'};
            my $stts_bzrPush = $status_pkg->{'git-push'};
            my $stts_bzrCgit = $status_pkg->{'bzrConvertGit'};

            # Get DateTime :
            my $timestamp = time();
            my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
                    'date' => '-',
                    'time' => ':',
                    'datetime' => ' ',
                    'format' => 'DD-MM-YYYY hms'
                });
            my $time_branch = $get_dataTime->{'custom'};

            # Update Packages:
            my $updatePkg_stts = Hash::MultiValue->new(%{$pkg_list->{$pkg_input}});
            $updatePkg_stts->set('status' => {
                    'bzr-branch' => $r_branch,
                    'git-push' => $stts_bzrPush,
                    'bzrConvertGit' => $stts_bzrCgit,
                });
            $updatePkg_stts->set('bzr-branch' => 1);
            $updatePkg_stts->set('date-branch' => $time_branch);
            my $rUpdate_sttsPkg = $updatePkg_stts->as_hashref;

            # Update Data Packages :
            my $updatePkgs = Hash::MultiValue->new(%{$pkg_list});
            $updatePkgs->set($pkg_input => $rUpdate_sttsPkg);
            my $newData_pkg = $updatePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $pkg_dirpkg,
                'group' => $pkg_group,
                'pkgs' => $newData_pkg,
            };

            return \%data;
        },
        'bzr-convert' => sub {
            my ($curr_cfg, $pkg_input, $r_bzrConver) = @_;

            # Define hash or scalar :
            my %data = ();

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_dirpkg = $curr_pkg->{'dirpkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $pkg_list = $curr_pkg->{'pkgs'};

            # Data Current Packages :
            my $dataCurr_pkg = $pkg_list->{$pkg_input};
            my $status_pkg = $dataCurr_pkg->{'status'};
            my $stts_bzrBranch = $status_pkg->{'bzr-branch'};
            my $stts_bzrPush = $status_pkg->{'git-push'};
            my $stts_bzrCgit = $status_pkg->{'bzrConvertGit'};

            # Update Packages:
            my $updatePkg_stts = Hash::MultiValue->new(%{$pkg_list->{$pkg_input}});
            $updatePkg_stts->set('status' => {
                    'bzr-branch' => $stts_bzrBranch,
                    'git-push' => $stts_bzrPush,
                    'bzrConvertGit' => $r_bzrConver,
                });
            my $rUpdate_sttsPkg = $updatePkg_stts->as_hashref;

            # Update Data Packages :
            my $updatePkgs = Hash::MultiValue->new(%{$pkg_list});
            $updatePkgs->set($pkg_input => $rUpdate_sttsPkg);
            my $newData_pkg = $updatePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $pkg_dirpkg,
                'group' => $pkg_group,
                'pkgs' => $newData_pkg,
            };

            return \%data;
        },
        'git-push' => sub {
            my ($curr_cfg, $pkg_input, $r_gitpush) = @_;

            # Define hash or scalar :
            my %data = ();

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $build_rilis = $curr_build->{'rilis'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_dirpkg = $curr_pkg->{'dirpkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $pkg_list = $curr_pkg->{'pkgs'};

            # Data Current Packages :
            my $dataCurr_pkg = $pkg_list->{$pkg_input};
            my $status_pkg = $dataCurr_pkg->{'status'};
            my $stts_bzrBranch = $status_pkg->{'bzr-branch'};
            my $stts_bzrCgit = $status_pkg->{'bzrConvertGit'};

            # Get DateTime :
            my $timestamp = time();
            my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
                    'date' => '-',
                    'time' => ':',
                    'datetime' => ' ',
                    'format' => 'DD-MM-YYYY hms'
                });
            my $time_gitpush = $get_dataTime->{'custom'};

            # Update Packages:
            my $updatePkg_stts = Hash::MultiValue->new(%{$pkg_list->{$pkg_input}});
            $updatePkg_stts->set('status' => {
                    'bzr-branch' => $stts_bzrBranch,
                    'git-push' => $r_gitpush,
                    'bzrConvertGit' => $stts_bzrCgit,
                });
            $updatePkg_stts->set('git-push' => 1);
            $updatePkg_stts->set('date-gitpush' => $time_gitpush);
            my $rUpdate_sttsPkg = $updatePkg_stts->as_hashref;

            # Update Data Packages :
            my $updatePkgs = Hash::MultiValue->new(%{$pkg_list});
            $updatePkgs->set($pkg_input => $rUpdate_sttsPkg);
            my $newData_pkg = $updatePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $pkg_dirpkg,
                'group' => $pkg_group,
                'pkgs' => $newData_pkg,
            };

            return \%data;
        },
        'git-check' => sub {
            my ($curr_cfg, $pkg_input, $r_gitcheck) = @_;

            # Define hash or scalar :
            my %data = ();

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_dirpkg = $curr_pkg->{'dirpkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $pkg_list = $curr_pkg->{'pkgs'};

            # Data Current Packages :
            my $dataCurr_pkg = $pkg_list->{$pkg_input};
            my $status_pkg = $dataCurr_pkg->{'status'};
            my $stts_bzrPush = $status_pkg->{'git-push'};
            my $stts_bzrBranch = $status_pkg->{'bzr-branch'};
            my $stts_bzrCgit = $status_pkg->{'bzrConvertGit'};

            # Update Packages:
            my $updatePkg_stts = Hash::MultiValue->new(%{$pkg_list->{$pkg_input}});
            $updatePkg_stts->set('status' => {
                    'bzr-branch' => $stts_bzrBranch,
                    'git-push' => $stts_bzrPush,
                    'bzrConvertGit' => $stts_bzrCgit,
                    'ongit' => $r_gitcheck,
                });
            my $rUpdate_sttsPkg = $updatePkg_stts->as_hashref;

            # Update Data Packages :
            my $updatePkgs = Hash::MultiValue->new(%{$pkg_list});
            $updatePkgs->set($pkg_input => $rUpdate_sttsPkg);
            my $newData_pkg = $updatePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $pkg_dirpkg,
                'group' => $pkg_group,
                'pkgs' => $newData_pkg,
            };

            return \%data;
        },
        'bzr2git' => sub {
            my ($curr_cfg, $pkg_input, $branch, $bzr_cgit, $git_push, $git_check, $time_branch, $time_gitpush) = @_;

            # Define hash or scalar :
            my %data = ();

            # get data current pkg :
            my $curr_timezone = $curr_cfg->{'timezone'};
            my $curr_prepare = $curr_cfg->{'prepare'};
            my $curr_build = $curr_cfg->{'build'};
            my $curr_bzr = $curr_cfg->{'bzr'};
            my $curr_git = $curr_cfg->{'git'};
            my $curr_pkg = $curr_cfg->{'pkg'};
            my $pkg_dirpkg = $curr_pkg->{'dirpkg'};
            my $pkg_group = $curr_pkg->{'group'};
            my $pkg_list = $curr_pkg->{'pkgs'};

            # Update Packages:
            my $updatePkg_stts = Hash::MultiValue->new(%{$pkg_list->{$pkg_input}});
            $updatePkg_stts->set('status' => {
                    'bzr-branch' => $branch,
                    'git-push' => $bzr_cgit,
                    'bzrConvertGit' => $git_push,
                    'ongit' => $git_check,
                });
            $updatePkg_stts->set('date-branch' => $time_branch);
            $updatePkg_stts->set('date-gitpush' => $time_gitpush);
            my $rUpdate_sttsPkg = $updatePkg_stts->as_hashref;

            # Update Data Packages :
            my $updatePkgs = Hash::MultiValue->new(%{$pkg_list});
            $updatePkgs->set($pkg_input => $rUpdate_sttsPkg);
            my $newData_pkg = $updatePkgs->as_hashref;

            # Create New Data :
            $data{'timezone'} = $curr_timezone;
            $data{'prepare'} = $curr_prepare;
            $data{'build'} = $curr_build;
            $data{'bzr'} = $curr_bzr;
            $data{'git'} = $curr_git;
            $data{'pkg'} = {
                'dirpkg' => $pkg_dirpkg,
                'group' => $pkg_group,
                'pkgs' => $newData_pkg,
            };

            return \%data;
        },
    };

    return $switch;
}
# Subroutine for save new configure to file config :
# ------------------------------------------------------------------------
sub save_to_file {
    my ($self, $filename, $dest_dir, $data) = @_;

    my $data_file = encode_json($data);
    my $create_file = BlankOnDev::Utils::file->create($filename, $dest_dir, $data_file);

    return $create_file;
}
1;