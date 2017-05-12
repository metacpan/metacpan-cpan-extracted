#!perl
# bin-fetchware-command-line.t tests bin/fetchware's command line interface.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '12'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Config;


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


# Set FETCHWARE_DATABASE_PATH to a tempdir, so that this entire test file uses a
# different path for your fetchware database than the one fetchware normally
# uses after it is installed. This is to avoid any conflicts with already
# installed fetchware packages, because if the actual fetchware database path
# is used for this test, then this test will actually upgrade any installed
# fetchware packages. Early in testing I found this acceptable, but now it's a
# massive bug. I've already implemented the FETCHWARE_DATABASE_PATH evironment
# variable, so I may as well take advantage of it.
$ENV{FETCHWARE_DATABASE_PATH} = tempdir("fetchware-test-$$-XXXXXXXXXX",
    CLEANUP => 1, TMPDIR => 1); 
ok(-e $ENV{FETCHWARE_DATABASE_PATH},
    'Checked creating upgrade test FETCHWARE_DATABASE_PATH success.');


subtest 'test command line install' => sub {
    # Clear App::Fetchware's internal configuration information, which I must do
    # if I parse more than one Fetchwarefile in a running of fetchware.
    __clear_CONFIG();

    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    verbose_on();

    ok(run_perl('install', $test_dist_path),
    'Checked command line test-dist install success');

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_install() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_install() delete temp files.');
};


subtest 'test command line uninstall' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    # I obviously must install test-dist before I can test uninstalling it :)
    cmd_install($test_dist_path);
    # And then test if the install was successful.
    ok(grep /test-dist-1.00/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) test setup success.');


    # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();

    ok(run_perl('uninstall', 'test-dist-1.00'),
        'Checked command line uninstall test-dist success.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_uninstall() clean up.');
};


##BROKEN## Even t/bin-fetchware-new.t does not actually test new completly yet,
#so until that is done I can not test it here.
##BROKEN##subtest 'test command line new' => sub {
##BROKEN##
##BROKEN##};


subtest 'test command line upgrade' => sub {
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

    ok(run_perl('upgrade', 'test-dist'),
        'Checked command line @ARGV upgrade success');

    print_ok(sub {cmd_list()},
        sub {grep({$_ =~ /test-dist-1\.01/} (split "\n", $_[0]))},
        'check cmd_upgrade() success.');



    # Test for when cmd_upgrade() determines that the latest version is
    # installed.
    # Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();
    ok(run_perl('upgrade', 'test-dist'),
        'Checked command line @ARGV upgrade version already installed');

    # Clean up upgrade path.
    ok(unlink($old_test_dist_path, $old_test_dist_path_md5,
            $new_test_dist_path, $new_test_dist_path_md5),
        'checked cmd_upgrade() delete temp upgrade files');

    # Clean up installed and upgraded test-dist!
    ok(unlink(catfile(fetchware_database_path(), 'test-dist-1.01.fpkg')),
        'checked cmd_ugprade() delete useless test-dist from package database.');
};


subtest 'test command line upgrade-all' => sub {
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
    ok(run_perl('upgrade-all'),
        'Checked command line @ARGV upgrade-all success. ');

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


subtest 'test command line list' => sub {
    # First install a test package to make sure there is something for cmd_list()
    # to find.
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    ok(cmd_install($test_dist_path),
        'checked cmd_list() by installing a test-dist to list');

    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(sub {run_perl('list')},
        'checked list success.');

# Annoyingly clean up CONFIG. Shouln't end() do this!!!!:)
__clear_CONFIG();

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_list() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


subtest 'test command line look' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    ok(run_perl('look', $test_dist_path),
        'checked command line look success.');

    # Cleanup the test-dist crap.
    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


subtest 'test command line clean' => sub {
    # Create a "testing temporary directory", because when run as root inside a
    # user directory like I do when testing root support during development,
    # tempdir() complains, because root does not "own" the directory these
    # directories are going to be created in. So, to avoid this issue without
    # comprimising security, just use "another level" of temporary directory.
    my $fetchware_base_tempdir = tempdir("fetchware-$$-XXXXXXXXX", TMPDIR => 1,
        CLEANUP => 1);

    # Test cmd_clean()'s ability to delete temporary files that start with
    # fetchware-* or Fetchwarefile-*.
    my $fetchware_tempdir = tempdir("fetchware-$$-XXXXXXXXX", DIR =>
        $fetchware_base_tempdir, CLEANUP => 1);
    my $fetchwarefile_tempdir = tempdir("Fetchwarefile-$$-XXXXXXXXX",
        DIR => $fetchware_base_tempdir, CLEANUP => 1);

    ok(-e $fetchware_tempdir, 'checked creating fetchware temporary directory.');
    ok(-e $fetchwarefile_tempdir, 'checked creating Fetchwarefile temporary directory.');

    # Delete newly created tempfiles.
    ok(run_perl('clean', $fetchware_base_tempdir),
        'checked command line clean success.');

    ok(! -e $fetchware_tempdir,
        'checked deleting fetchware temporary directory success.');
    ok(! -e $fetchwarefile_tempdir,
        'checked deleting Fetchwarefile temporary directory success.');
};


# Tests command line when @ARGV's first value is *not* one of fetchware's allowable
# commands.
subtest 'test command line default' => sub {
    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl($Config{perlpath}, 'bin/fetchware'),
        'Checked command line @ARGV = help.');


    # Now test that the same else is hit if an unrecognized command is
    # specified.
    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('unrecognized'),
        'Checked command line @ARGV = help.');
};


subtest 'test command line help' => sub {
    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('help'),
        'Checked command line @ARGV = help.');
};


subtest 'test command line command line options' => sub {
    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('-h'),
        'Checked command line @ARGV = -h.');

    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('--help'),
        'Checked command line @ARGV = --help.');

    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('-?'),
        'Checked command line @ARGV = -?.');

    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('-V'),
        'checked command line -V option success.');

    ###BUGALERT### Only tests if bin/fetchware's exit value is 0, because
    #print_ok() cannot test a forked and execed processes' STDOUT only the
    #current processes STDOUT.
    ok(run_perl('--version'),
        'checked command line --version option success.');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();

# Like run_prog() but never prints anything extra, and includes the $Config{perlpath} and
# 'bin/fetchware' stuff all of these tests need. And it returns 
sub run_perl {
    my $retval = system($Config{perlpath}, 'bin/fetchware', @_);
    $retval == 0 or die <<EOD;
system(\$Config{perlpath}, 'bin/fetchware', @_) failed. OS error [$!].
EOD
    # system() returns 0 for success, but 0 is false in perl, so I have to turn
    # it into a normal true or false value for use with ok() or print_ok().
    return $retval == 0 ? 1 : 0;
}
