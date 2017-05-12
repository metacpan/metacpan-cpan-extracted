#!perl
# bin-fetchware-upgrade-all.t tests bin/fetchware's cmd_upgrade_all()
# subroutine, which upgrades *all* of fetchware's installed packages.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '5'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Copy 'cp';
use File::Spec::Functions qw(catfile splitpath);
use Path::Class;
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
# is installed. This is to avoid any conflicts--especially because this test
# file upgrades everything in your fetchware database path, so we need to ensure
# that there are just simple testing packages in ther, and not something more
# annoying.
$ENV{FETCHWARE_DATABASE_PATH} = tempdir("fetchware-test-$$-XXXXXXXXXX",
    CLEANUP => 1, TMPDIR => 1); 
ok(-e $ENV{FETCHWARE_DATABASE_PATH},
    'Checked creating test FETCHWARE_DATABASE_PATH success.');

# Only those who run fetchware's own author tests will have
# FETCHWARE_NONROOT_USER set when the test suite runs. So most users will get an
# annoying uninitialized warning from this. Also, this will set the user config
# file option to the empty string, which fetchware most likely considers similar
# to undef so that probably doesn't cause any weird bugs. To deal with this
# situation, I'll just set it here to nobody, which is otherwise the default
# anyway.
#
# Other options are to have if statements everywhere FETCHWARE_NONROOT_USER is
# used. Something like.
#
#    if (defined $ENV{FETCHWARE_NONROOT_USER}) {
#    my $test_dist_path = make_test_dist(file_name => 'test-dist',
#        ver_num => '1.00',
#        append_option => qq{user '$ENV{FETCHWARE_NONROOT_USER}';});
#    } else {
#        my $test_dist_path = make_test_dist(file_name => 'test-dist',
#            ver_num => '1.00');
#    }
# But that's fugly, and adds annoying code duplication. I know my test suite was
# created with loads of copy and paste, but that doesn't mean this kind of
# garbage code is okay. I'd kill for like a line oriented, smart (meaning fixes
# obvious syntax errors for you) ifdef system where I could just if def this
# argument, where only if FETCHWARE_NONROOT_USER was defined this stupid
# argument would be added. Do Perl 6 macros do this???
$ENV{FETCHWARE_NONROOT_USER} = 'nobody' if not defined $ENV{FETCHWARE_NONROOT_USER};
 

subtest 'test cmd_upgrade_all() success' => sub {
    skip_all_unless_release_testing();

    my $apache_fetchwarefile = <<EOF;
use App::Fetchware;

program 'Apache 2.2';

lookup_url '$ENV{FETCHWARE_LOCAL_UPGRADE_URL}';

mirror '$ENV{FETCHWARE_LOCAL_UPGRADE_URL}';

filter 'httpd-2.2';

# user needed when root, because nobody won't haver permissions to access local
# user's directory where the local files above for loookup_url and mirror are.
user 'dly';
EOF


    my $ctags_fetchwarefile = <<EOF;
use App::Fetchware;

program 'ctags';

lookup_url '$ENV{FETCHWARE_LOCAL_UPGRADE_URL}';

mirror '$ENV{FETCHWARE_LOCAL_UPGRADE_URL}';

filter 'ctags';

# Disable verification, because ctags provides none.
verify_failure_ok 'On';

# user needed when root, because nobody won't haver permissions to access local
# user's directory where the local files above for loookup_url and mirror are.
user 'dly';
EOF

    my @fetchware_packages;
    for my $fetchwarefile ($apache_fetchwarefile, $ctags_fetchwarefile) {
note('FETCHWAREFILE');
note("$fetchwarefile");
        my $package_name = $fetchwarefile;
        $package_name =~ /(httpd-2\.2|ctags)/; 
        $package_name = $1;
note("packagename[$package_name]");
        my $fetchwarefile_path = create_test_fetchwarefile($fetchwarefile);

        ok(-e $fetchwarefile_path,
            'check create_test_fetchwarefile() test Fetchwarefile');

        # I obviously must install apache before I can test upgrading it :)
        push @fetchware_packages, cmd_install($fetchwarefile_path);
        # And then test if the install was successful.
        ok(grep /$package_name/, glob(catfile(fetchware_database_path(), '*')),
            'check cmd_install(Fetchware) success.');

        # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
        # twice, and it's only supported once.
        __clear_CONFIG();
    }


    # upgrade_all: Copy over new version of ctags too.
    # Also copy over the latest version of httpd, so that I don't have to change
    # the lookup_url in the Fetchwarefile of the httpd fetchware package.
    # httpd copy stuff.
    my $striped_upgrade_path = $ENV{FETCHWARE_LOCAL_UPGRADE_URL};
    $striped_upgrade_path =~ s!^file://!!;
    my $parent_upgrade_path = dir($striped_upgrade_path)->parent();
    my $httpd_upgrade = catfile($parent_upgrade_path, 'httpd-2.2.22.tar.bz2');
    my $httpd_upgrade_asc = catfile($parent_upgrade_path,
        'httpd-2.2.22.tar.bz2.asc');
note("httpd_upgrade[$httpd_upgrade] stripedupgradepath[$striped_upgrade_path]");
    ok(cp($httpd_upgrade, $striped_upgrade_path),
        'checked cmd_upgrade() cp new version  httpd to local upgrade url');
note("httpd_upgrade_asc[$httpd_upgrade_asc]");
    ok(cp($httpd_upgrade_asc, $striped_upgrade_path),
        'checked cmd_upgrade() cp new version httpd asc to local upgrade url');
    # ctags copy stuff.
    my $ctags_upgrade = catfile($parent_upgrade_path, 'ctags-5.8.tar.gz');
note("ctags_upgrade[$ctags_upgrade]");
    ok(cp($ctags_upgrade, $striped_upgrade_path),
        'checked cmd_upgrade() cp new version ctags to local upgrade url');


    # upgrade all packages, which will test if upgrading everything in
    # fetchware_database_path works.
    my @upgraded_package_paths = cmd_upgrade_all();
    note("HERE");
    note explain \@upgraded_package_paths;


    # Test after both packages have been upgraded.
    print_ok(sub {cmd_list()},
        sub {grep({$_ =~ /httpd-2\.2\.22|ctags-5\.8/} (split "\n", $_[0]))},
        'check cmd_upgrade() success.');


    # Test for when cmd_upgrade() determines that the latest version is
    # installed.
    # Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();
    is(cmd_upgrade_all(), 'No upgrade needed.',
        'checked cmd_upgrade_all() latest version already installed.');

    # Clean up upgrade path.
    my $httpd_upgrade_to_delete = catfile($striped_upgrade_path,
        file($httpd_upgrade)->basename());
    my $httpd_upgrade_asc_to_delete = catfile($striped_upgrade_path,
        file($httpd_upgrade_asc)->basename());
    # upgrade_all: Clean up ctags new package too.
    my $ctags_upgrade_to_delete = catfile($striped_upgrade_path,
        file($ctags_upgrade)->basename());
    ok(unlink($httpd_upgrade_to_delete,
            $httpd_upgrade_asc_to_delete,
            $ctags_upgrade_to_delete),
        'checked cmd_upgrade_all() delete temp upgrade files');
};



# Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
# many times, and it's only supported once.
__clear_CONFIG();


subtest 'test cmd_upgrade_all() test-dist' => sub {
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
        ver_num => '1.00', destination_directory => $upgrade_temp_dir,
        append_option => qq{user '$ENV{FETCHWARE_NONROOT_USER}';});
    my $old_another_dist_path = make_test_dist(file_name => 'another-dist',
        ver_num => '1.00', destination_directory => $upgrade_temp_dir,
        append_option => qq{user 'ENV{FETCHWARE_NONROOT_USER}';});

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
        ver_num => '1.01', destination_directory => $upgrade_temp_dir,
        append_option => qq{user 'ENV{FETCHWARE_NONROOT_USER}';});
    my $new_another_dist_path = make_test_dist(file_name => 'another-dist',
        ver_num => '1.01', destination_directory => $upgrade_temp_dir,
        append_option => qq{user 'ENV{FETCHWARE_NONROOT_USER}';});

    my $new_test_dist_path_md5 = md5sum_file($new_test_dist_path);
    my $new_another_dist_path_md5 = md5sum_file($new_another_dist_path);


    # Upgrade all installed fetchware packages.
    my @upgraded_packages = cmd_upgrade_all();
note("UPGRADED_PACKAGES[@upgraded_packages]");
    for my $upgraded_package (@upgraded_packages) {
        like($upgraded_package, qr/(test|another)-dist-1\.01/,
            'checked cmd_upgrade_all() success.');
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


subtest 'check cmd_upgrade_all(argument) error' => sub {
    eval_ok(sub {cmd_upgrade_all('some arg')},
        <<EOE, 'checked cmd_upgrade_all(argument) error');
fetchware: fetchware's upgrade-all command takes no arguments. Instead, it
simply loops through fetchware's package database, and upgrades all already
installed fetchware packages. Please rerun fetchware upgrade-all without any
arguments to upgrade all already installed packages, or run fetchware help for
usage instructions.
EOE

};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
