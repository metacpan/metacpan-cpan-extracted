#!perl
# bin-fetchware-run.t tests bin/fetchware's run() subroutine, which
# does command line option parsing and executes whatever cmd_*() subroutine that
# is needed.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '13'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';


# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Load bin/fetchware "manually," because it isn't a real module, and has no .pm
# extenstion use expects.
BEGIN {
    my $fetchware = 'fetchware';
    use lib 'bin';
    require $fetchware;
    fetchware->import(':TESTING');
    ok(defined $INC{$fetchware}, 'checked bin/fetchware loading and import')
}


# Set FETCHWARE_DATABASE_PATH to a tempdir, so that this test uses a different
# path for your fetchware database than the one fetchware normally uses after it
# is installed. This is to avoid any conflicts with already installed fetchware
# packages, because if the actual fetchware database path is used for this test,
# then this test will actually upgrade any installed fetchware packages. Early
# in testing I found this acceptable, but now it's a massive bug. I've already
# implemented the FETCHWARE_DATABASE_PATH evironment variable, so I may as well
# take advantage of it.
$ENV{FETCHWARE_DATABASE_PATH} = tempdir("fetchware-test-$$-XXXXXXXXXX",
    CLEANUP => 1, TMPDIR => 1); 
ok(-e $ENV{FETCHWARE_DATABASE_PATH},
    'Checked creating upgrade test FETCHWARE_DATABASE_PATH success.');


subtest 'test run() install' => sub {
    # Clear App::Fetchware's internal configuration information, which I must do
    # if I parse more than one Fetchwarefile in a running of fetchware.
    __clear_CONFIG();

    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    verbose_on();

    {
        local @ARGV = ('install', $test_dist_path);
        fork_ok(sub { run() },
        'Checked run() test-dist install success');
    }

    ok(-e catfile(fetchware_database_path(), 'test-dist-1.00.fpkg'),
        'checked test-dist install copied to fetchware db.');

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_install() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_install() delete temp files.');
};


subtest 'test run() install with --keep-temp command line option.' => sub {
    # Clear App::Fetchware's internal configuration information, which I must do
    # if I parse more than one Fetchwarefile in a running of fetchware.
    __clear_CONFIG();

    # Since there is no way of knowing what path this specific tempdir is at, so
    # instead of trying to parse it out the output, I just specify a local
    # TMPDIR, and then the tempdir should be inside this path that I setup.
    local $ENV{TMPDIR} = tempdir("fetchware-test-$$-XXXXXXXXXX",
        CLEANUP => 1, TMPDIR => 1); 
    ok(-e $ENV{TMPDIR},
        'checked run() TMPDIR setup.');
    # For some reason tempdir() ignores your umask, and just creates its
    # tempfiles and tempdirs with 0700 perms, which in the case of drop_privs()
    # when root blows up, because the regular user that fetchware drop privs too
    # can't access a 0700 root only tempdir. So I must change the perms to 0755
    # to let the regular user have access.
    ok(chmod(0755, $ENV{TMPDIR}),
        'checked run() TMPDIR chmod(755).');

    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00', append_option => q{stay_root 'On'});
    ok(-e $test_dist_path, 'checked run() test-dist created.');
    my $test_dist_md5 = md5sum_file($test_dist_path);
    ok(-e $test_dist_md5, 'checked run() test-dist md5 created.');

    verbose_on();

    {
        # Run with --keep-temp option.
        local @ARGV = ('--keep-temp', 'install', $test_dist_path);
        fork_ok(sub { print "TMP[$ENV{TMPDIR}]"; run() },
        'Checked run() test-dist install success');
    }

    ok(-e catfile(fetchware_database_path(), 'test-dist-1.00.fpkg'),
        'checked test-dist install copied to fetchware db.');

    # Check that there's fetchware-test-$$ directory in TMPDIR.
    ok(chdir("$ENV{TMPDIR}"),
        'checked run() chdir()d to TMPDIR.');
    ok(-e glob("fetchware-*"),
        'checked run() glob()ed tempdir success.');

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_install() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_install() delete temp files.');
};


subtest 'test run() uninstall' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    # I obviously must install apache before I can test uninstalling it :)
    cmd_install($test_dist_path);
    # And then test if the install was successful.
    ok(grep /test-dist-1.00/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) test setup success.');


    # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();

    {
        local @ARGV = ('uninstall', 'test-dist-1.00');
        fork_ok(sub { run() },
            'Checked run() uninstall test-dist success.');
    }

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_uninstall() clean up.');
};


##BROKEN## Even t/bin-fetchware-new.t does not actually test new completly yet,
#so until that is done I can not test it here.
##BROKEN##subtest 'test run() new' => sub {
##BROKEN##
##BROKEN##};


subtest 'test run() upgrade' => sub {
    # Actually test during user install!!!
    # Delete all existing httpd fetchware packages in fetchware_database_path(),
    # which will screw up the installation and upgrading of httpd below.
    for my $fetchware_package (glob catfile(fetchware_database_path(), '*')) {
        # Clean up $fetchware_package.
        if ($fetchware_package =~ /test-dist/) {
            ok((unlink $fetchware_package),
                'checked cmd_upgrade() clean up fetchware database path')
                if -e $fetchware_package
        }
    }


    # Create a $temp_dir for make_test_dist() to use. I need to do this, so that
    # both the old and new test dists can be in the same directory.
    my $upgrade_temp_dir = tempdir("fetchware-$$-XXXXXXXXXX",
        CLEANUP => 1, TMPDIR => 1);
    # However, not only do I have create the tempdir, but I must also chmod 755
    # this temporary directory to ensure read access if this test file is run as
    # root, and then drops its privs without the extra read perms this test will
    # fail, because the nobody user will not be able to access this directory's
    # 700 perms.
    chmod 0755, $upgrade_temp_dir or fail(<<EOF);
Failed to chmod(0755, [$upgrade_temp_dir])! This is probably a bug or something?
EOF

note("UPGRADETD[$upgrade_temp_dir]");

    my $old_test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00', destination_directory => $upgrade_temp_dir);
    
    my $old_test_dist_path_md5 = md5sum_file($old_test_dist_path);

    # Delete all existing httpd fetchware packages in fetchware_database_path(),
    # which will screw up the installation and upgrading of httpd below.
    for my $fetchware_package (glob catfile(fetchware_database_path(), '*')) {
        # Delete *only* httpd.
        if ($fetchware_package =~ /test-dist/) {
            # Clean up $fetchware_package.
            ok((unlink $fetchware_package),
                'checked cmd_upgrade() clean up fetchware database path')
                if -e $fetchware_package;
        }
    }

note("INSTALLPATH[$old_test_dist_path]");

    # I obviously must install test-dist before I can test upgrading it :)
    my $fetchware_package_path = cmd_install($old_test_dist_path);
    # And then test if the install was successful.
    ok(grep /test-dist/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) success.');


    # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();


    # Sleep for 2 seconds to ensure that the new version is a least a couple of
    # seconds newer than the original version. Perl is pretty fast, so it can
    # actually execute this whole friggin subtest in less than one second on my
    # decent desktop system.
    sleep 2;


    my $new_test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.01', destination_directory => $upgrade_temp_dir);

    my $new_test_dist_path_md5 = md5sum_file($new_test_dist_path);

    {
        local @ARGV = ('upgrade', 'test-dist');
        fork_ok(sub { run() },
            'Checked run() @ARGV upgrade success');
    }

    print_ok(sub {cmd_list()},
        sub {grep({$_ =~ /test-dist-1\.01/} (split "\n", $_[0]))},
        'check cmd_upgrade() success.');



    # Test for when cmd_upgrade() determines that the latest version is
    # installed.
    # Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();
    {
        local @ARGV = ('upgrade', 'test-dist');
        fork_ok(sub { run() },
            'Checked run() @ARGV upgrade version already installed');
    }

    # Clean up upgrade path.
    ok(unlink($old_test_dist_path, $old_test_dist_path_md5,
            $new_test_dist_path, $new_test_dist_path_md5),
        'checked cmd_upgrade() delete temp upgrade files');

    # Clean up installed and upgraded test-dist!
    ok(unlink(catfile(fetchware_database_path(), 'test-dist-1.01.fpkg')),
        'checked cmd_ugprade() delete useless test-dist from package database.');
};


subtest 'test run() upgrade-all' => sub {
    # Actually test during user install!!!

    # Create a $temp_dir for make_test_dist() to use. I need to do this, so that
    # both the old and new test dists can be in the same directory.
    my $upgrade_temp_dir = tempdir("fetchware-$$-XXXXXXXXXX",
        CLEANUP => 1, TMPDIR => 1);
    # However, not only do I hav to create the tempdir, but I must also chmod
    # 755 this temporary directory to ensuer read access if this test file is
    # run as root, and then drops its privs without the extra read perms this
    # test will fail, because the nobody user will not be able to access this
    # directory's 700 perms.
    chmod 0755, $upgrade_temp_dir or fail(<<EOF);
Failed to chmod(0755, [$upgrade_temp_dir])! This is probably a bug or something?
EOF

    my $old_test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00', destination_directory => $upgrade_temp_dir);
    my $old_another_dist_path = make_test_dist(file_name => 'another-dist',
        ver_num => '1.00', destination_directory => $upgrade_temp_dir);

    my $old_test_dist_path_md5 = md5sum_file($old_test_dist_path);
    my $old_another_dist_path_md5 = md5sum_file($old_another_dist_path);


    # I obviously must install test-dist before I can test upgrading it :)
    for my $fpkg_to_install ($old_test_dist_path, $old_another_dist_path) {
        my $fetchware_package_path = cmd_install($fpkg_to_install);
        # And then test if the install was successful.
        ok(grep /test-dist|another-dist/,
            glob(catfile(fetchware_database_path(), '*')),
            'check cmd_install(Fetchware) success.');

        # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
        # twice, and it's only supported once.
        __clear_CONFIG();
    }


    # Sleep for 2 seconds to ensure that the new version is a least a couple of
    # seconds newer than the original version. Perl is pretty fast, so it can
    # actually execute this whole friggin subtest on my decent desktop system
    # in less thatn one second.
    sleep 2;


    # Create new test fpkgs and md5s in same dir for cmd_upgrade_all() to work.
    my $new_test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.01', destination_directory => $upgrade_temp_dir);
    my $new_another_dist_path = make_test_dist(file_name => 'another-dist',
        ver_num => '1.01', destination_directory => $upgrade_temp_dir);

    my $new_test_dist_path_md5 = md5sum_file($new_test_dist_path);
    my $new_another_dist_path_md5 = md5sum_file($new_another_dist_path);


    # Upgrade all installed fetchware packages.
    {
        local @ARGV = ('upgrade-all');
        fork_ok(sub { run() },
            'Checked run() @ARGV upgrade-all success. ');
    }

    print_ok(sub {cmd_list()},
        sub {grep({$_ =~ /(test|another)-dist-1\.01/} (split "\n", $_[0]))},
        'check cmd_upgrade_all() success.');


    # Test for when cmd_upgrade() determines that the latest version is
    # installed.
    # Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();
    is(cmd_upgrade_all(), 'No upgrade needed.',
        'checked cmd_upgrade() latest version already installed.');

    # Clean up upgrade path.
    ok(unlink($old_test_dist_path, $old_test_dist_path_md5,
        $old_another_dist_path, $old_another_dist_path_md5,
        $new_test_dist_path, $new_test_dist_path_md5,
        $new_another_dist_path, $new_another_dist_path_md5,
        ), 'checked cmd_upgrade() delete temp upgrade files');

    # Clean up installed and upgraded test-dist!
    ok(unlink(catfile(fetchware_database_path(), 'test-dist-1.01.fpkg')),
        'checked cmd_ugprade() delete useless test-dist from package database.');
    ok(unlink(catfile(fetchware_database_path(), 'another-dist-1.01.fpkg')),
        'checked cmd_ugprade() delete useless test-dist from package database.');

};


subtest 'test run() list' => sub {
    # First install a test package to make sure there is something for cmd_list()
    # to find.
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    ok(cmd_install($test_dist_path),
        'checked cmd_list() by installing a test-dist to list');

    {
        local @ARGV = ('list');
        fork_ok(sub {
                print_ok(sub {run()}, qr/test-dist-1\.00/,
                    'checked cmd_list() success.');
            },
            'Checked run() @ARGV list success');
    }

# Annoyingly clean up CONFIG. Shouln't end() do this!!!!:)
__clear_CONFIG();

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_list() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


subtest 'test run() look' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    {
        local @ARGV = ('look', $test_dist_path);
        fork_ok(sub {run()},
            'checked run() look success.');
    }

    # Cleanup the test-dist crap.
    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


subtest 'test run() clean' => sub {
    # Create a tempdir to create and test other tempdirs to test cmd_clean()
    # deleteing them.
    my $testing_tempdir = tempdir("fetchware-$$-XXXXXXXXXX", TMPDIR => 1,
        CLEANUP => 1);

    # Test cmd_clean()'s ability to delete temporary files that start with
    # fetchware-* or Fetchwarefile-*.
    my $fetchware_tempdir = tempdir("fetchware-$$-XXXXXXXXX",
        DIR => $testing_tempdir, CLEANUP => 1);
    my $fetchwarefile_tempdir = tempdir("Fetchwarefile-$$-XXXXXXXXX",
        DIR => $testing_tempdir, CLEANUP => 1);

    ok(-e $fetchware_tempdir, 'checked creating fetchware temporary directory.');
    ok(-e $fetchwarefile_tempdir, 'checked creating Fetchwarefile temporary directory.');

    # Delete newly created tempfiles.
    {
        local @ARGV = ('clean', $testing_tempdir);
        fork_ok(sub {run()},
            'checked run() clean success.');
    }

    ok(! -e $fetchware_tempdir,
        'checked deleting fetchware temporary directory success.');
    ok(! -e $fetchwarefile_tempdir,
        'checked deleting Fetchwarefile temporary directory success.');
};


# Tests run() when @ARGV's first value is *not* one of fetchware's allowable
# commands.
subtest 'test run() default' => sub {
    {
        local @ARGV = ();
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions. It gives you the/,
                'Checked run() @ARGV = help with print_ok().');
        },
            'Checked run() with an empty @ARGV.');
    }


    # Now test that the same else is hit if an unrecognized command is
    # specified.
    {
        local @ARGV = ('unrecognized');
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions. It gives you the/,
                'Checked run() @ARGV = help with print_ok().');
        },
            'Checked run() with an unrecognized @ARGV.');
    }
};



# Tests run() when @ARGV's first value is *not* one of fetchware's allowable
# commands.
subtest 'test run() help' => sub {
    {
        local @ARGV = ('help');
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions. It gives you the/,
                'Checked run() @ARGV = help with print_ok().');
        },
            'Checked run() @ARGV = help.');
    }
};


subtest 'test run() command line options' => sub {
    {
        local @ARGV = '-h';
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions.  It gives you the/,
                'Checked run() @ARGV = -h with print_ok().');
        },
            'checked run() -h success.');
    }

    {
        local @ARGV = '-?';
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions.  It gives you the/,
                'Checked run() @ARGV = -? with print_ok().');
        },
            'checked run() -? success.');
    }
    
    {
        local @ARGV = '--help';
        fork_ok(sub {
            print_ok(sub {run()},
                qr/fetchware is a package manager for source code distributions.  It gives you the/,
                'Checked run() @ARGV = --help with print_ok().');
        },
            'checked run() --help success.');
    }

    {
        local @ARGV = '-V';
        fork_ok(sub {
            print_ok(sub {run()},
                qr/Fetchware version \d.\d\d\d/,
                'checked run() -V option success with print_ok().');
        },
            'Checked run() -V option success.');
    }

    {
        local @ARGV = '--version';
        fork_ok(sub {
            print_ok(sub {run()},
                qr/Fetchware version \d.\d\d\d/,
                'checked run() --version option success with print_ok().');
        },
            'Checked run() --version option success.');
    }
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
