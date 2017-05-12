#!perl
# bin-fetchware-uninstall.t tests bin/fetchware's cmd_uninstall() subroutine, which
# uninstalls fetchware packages and from a Fetchwarefile.
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
use File::Copy 'mv';
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


my $fetchware_package_path;
subtest 'test cmd_uninstall() success' => sub {
    skip_all_unless_release_testing();

# Changed from FETCHWARE_HTTP_LOOKUP_URL, because Apache does *not* have a make # uninstall, which fetchware needs for automatic package uninstalltion.
my ($vol, $dirs, $file) = splitpath("$ENV{FETCHWARE_LOCAL_BUILD_URL}");
note("VOL[$vol][$dirs][$file]");
my $lookup_url =  "file://$dirs";
note("LOOKUPURL[$lookup_url]");
my $fetchwarefile = <<EOF;
use App::Fetchware;

program 'ctags';

lookup_url '$lookup_url';

# Must provide a mirror as well, so just use the same thing as the lookup_url.
mirror '$lookup_url';

filter 'ctags';
###BUGALERT### Add local verification for this.
verify_failure_ok 'On';

# FETCHWARE_LOCAL_URL is in a user's home directory, so drop_privs() default of
# nobody has no access to this directory hence need for user config option.
user '$ENV{FETCHWARE_NONROOT_USER}';
EOF

note('FETCHWAREFILE');
note("$fetchwarefile");
    my $fetchwarefile_path = create_test_fetchwarefile($fetchwarefile);

    ok(-e $fetchwarefile_path,
        'check create_test_fetchwarefile() test Fetchwarefile');

    # I obviously must install apache before I can test uninstalling it :)
    $fetchware_package_path = cmd_install($fetchwarefile_path);
    # And then test if the install was successful.
    ok(grep /ctags/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) success.');

    # Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();

    # cmd_uninstall accepts a string that needs to be found in the fetchware
    # database. It does *not* take Fetchwarefiles or fetchware packages as
    # arguments.
    my $uninstalled_package_path = cmd_uninstall('ctags');

    like($fetchware_package_path, qr/$uninstalled_package_path/,
        'check cmd_install(Fetchware) success.');
};


subtest 'test cmd_uninstall() failure' => sub {
    skip_all_unless_release_testing();

    # Save cwd to chdir to it later, because the uninstall exceptions that I'm
    # trapping below do *not* chdir back to the main fetchware directory after
    # they are thrown, so I must do it manually.
    my $original_cwd = cwd();

###BUGALERT### The exception below cannot be tested, because the condition it
#tests for is tested previously as tested in the test below. Remove throwing
#this exception, or move throwing it to cmd_uninstall() from
#determine_fetchware_package_path().
###    eval_ok(sub {cmd_uninstall('fetchware-test' . rand(2838382828282))},
###        <<EOE, 'checkec cmd_uninstall() package existence
###fetchware: The argument you provided to fetchware upgrade was not found in
###fetchware's package database. To get a list of available packages to upgrade
###just run the fetchware list command to list all installed packages. Select one
###of those to upgrade, and then rerun fetchware upgrade.
###EOE

    # Test for correct error if a package isn't installed.
    eval_ok(sub {cmd_uninstall('fetchware-test' . rand(3739929293))},
        # Use a regex, because a variable is interpolated in the error message.
        qr/fetchware: Fetchware failed to determine the fetchware package that is
associated with the argument that you provided to fetchware/ ,
        'checked cmd_uninstall() package existence');


    # Test for unique package error.
    # Create fake fetchware packages 
    my $tf1 = catfile(fetchware_database_path(), 'fetchware-test-1.fpkg');
    my $tf2 = catfile(fetchware_database_path(), 'fetchware-test-2.fpkg');
    open my $fh, '>', $tf1
            or fail('Can\'t create test file [fetchware-test-1.fpkg');
        print $fh 'Not a real fetchware package.'; close $fh;
    open my $fh2, '>', $tf2
            or fail('Can\'t create test file [fetchware-test-2.fpkg');
        print $fh2 'Not a real fetchware package.'; close $fh2;
    eval_ok(sub {cmd_uninstall('fetchware-test')},
        <<EOE, 'checked cmd_uninstall() not a unique package.');
Choose which package from the list above you want to upgrade, and rerun
fetchware upgrade using it as the argument for the package you want to upgrade.
EOE

    # Delete garbage test files for test case above.
    ok(unlink($tf1, $tf2),
        'checked cmd_uninstall() remove garbage test packages');

    
    # Copy and paste more create test file crap.
    my $tf = catfile(fetchware_database_path(), 'fetchware-test');
    open my $fh3, '>', $tf
            or fail('Can\'t create test file [fetchware-test');
        print $fh3 'Not a real fetchware package.'; close $fh3;
    eval_ok(sub{cmd_uninstall('fetchware-test')},
        <<EOE, 'checked cmd_uninstall() argument not fetchware package');
fetchware: The option you provided to uninstall is not a currently installed
fetchware package. Please rerun uninstall after determining the proper name for
the already installed fetchware package. To see a list of already installed
fetchware packages please try fetchware's list command: fetchware list
EOE

    # Delete garbage test files for test case above.
    ok(unlink($tf),
        'checked cmd_uninstall() remove garbage test packages again.');

    # Copy and paste even more create test file crap.
    my $another_tf = catfile(fetchware_database_path(), 'fetchware-test.fpkg');
    open my $fh4, '>', $another_tf
            or fail('Can\'t create test file [fetchware-test');
        print $fh4 'Not a real fetchware package.'; close $fh4;
###BUGALERT### Can't actually test this exception either, because a prior
#exception catches this error. Should I remove this test, or what???
###    eval_ok(sub{cmd_uninstall('fetchware-test')},
###        <<EOE, 'checked cmd_uninstall() failed to extract fetchwarefile');
###fetchware: fetchware upgrade failed to extract the Fetchwarefile from the
###fetchware package that should be stored in fetchware's database.
###EOE

    eval_ok(sub{cmd_uninstall('fetchware-test')},
        qr/fetchware: Archive::Tar failed to read in the gunziped file \[/,
        'checked cmd_uninstall() failed to extract fetchwarefile');

    # Delete garbage test files for test case above.
    ok(unlink($another_tf),
        'checked cmd_uninstall() remove garbage test packages yet again.');

    # Chdir to $original_cwd so next tests run correctly.
    chdir $original_cwd 
        or fail("Failed to chdir! Causing next subtest to fail!");
};

# Clear internal %CONFIG variable, because I have to pare a Fetchwarefile
# twice, and it's only supported once.
__clear_CONFIG();

subtest 'test cmd_uninstall() with test-dist.fpkg' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00',
        append_option => qq{user '$ENV{FETCHWARE_NONROOT_USER}';});
    my $test_dist_md5 = md5sum_file($test_dist_path);

    # I obviously must install apache before I can test uninstalling it :)
    $fetchware_package_path = cmd_install($test_dist_path);
    # And then test if the install was successful.
    ok(grep /test-dist-1.00/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) test setup success.');

    # Clear internal %CONFIG variable, because I have to parse a Fetchwarefile
    # twice, and it's only supported once.
    __clear_CONFIG();

    # cmd_uninstall accepts a string that needs to be found in the fetchware
    # database. It does *not* take Fetchwarefiles or fetchware packages as
    # arguments.
    my $uninstalled_package_path = cmd_uninstall('test-dist-1.00');

    like($fetchware_package_path, qr/$uninstalled_package_path/,
        'check cmd_uninstall() success.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_uninstall() clean up.');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
