#!perl
# bin-fetchware-install.t tests bin/fetchware's cmd_install() subroutine, which
# installs fetchware packages and from a Fetchwarefile.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '7'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Copy 'mv';
use File::Spec::Functions qw(catfile splitpath tmpdir);
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


#my $fetchware_package_path = '/var/log/fetchware/httpd-2.2.22.fpkg';
my $fetchware_package_path;
subtest 'test cmd_install(Fetchwarefile)' => sub {
    skip_all_unless_release_testing();

my $fetchwarefile = <<EOF;
use App::Fetchware;

program 'Apache 2.2';

lookup_url '$ENV{FETCHWARE_HTTP_LOOKUP_URL}';

mirror '$ENV{FETCHWARE_FTP_MIRROR_URL}';

filter 'httpd-2.2';
EOF

note('FETCHWAREFILE');
note("$fetchwarefile");
    my $fetchwarefile_path = create_test_fetchwarefile($fetchwarefile);

    ok(-e $fetchwarefile_path,
        'check create_test_fetchwarefile() test Fetchwarefile');

    $fetchware_package_path = cmd_install($fetchwarefile_path);

    ok(grep /httpd-2\.2/, glob(catfile(fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) success.');

    # *Don't delete httpd-2.2*.fpkg to clean up this test, because the next
    # test attempts to use that file to test fetchware install *.fpkg.
};



subtest 'test cmd_install(*.fpkg)' => sub {
    skip_all_unless_release_testing();

    # Clear App::Fetchware's internal configuration information, which I must do
    # if I parse more than one Fetchwarefile in a running of fetchware.
    __clear_CONFIG();
    
    # Copy existing fetchware package to tmpdir(), so that after I try installing
    # it I can test if it was successful by seeing if it was copied back to the
    # fetchware database dir.
    # It must be a dir with the sticky bit set or owned by the user running the
    # program to pass safe_open()'s security tests.
    note("FPP[$fetchware_package_path]");
    my $temp_dir = tempdir("fetchware-test-$$-XXXXXXXXXXXX",
        TMPDIR => 1, CLEANUP => 1);
    mv($fetchware_package_path, $temp_dir)
        ? pass("checked cmd_install() *.fpkg move fpkg.")
        : fail("Failed to cp [$fetchware_package_path] to cwd os error [$!].");

    # Steal the *.fpkg that was created in the previous step!
    my $new_fetchware_package_path
        =
        cmd_install(
            catfile($temp_dir, ( splitpath($fetchware_package_path) )[2] )
        );

    is($new_fetchware_package_path, $fetchware_package_path,
        'checked cmd_install(*.fpkg) success.');
};


subtest 'test test-dist.fpkg cmd_install' => sub {
    # Clear App::Fetchware's internal configuration information, which I must do
    # if I parse more than one Fetchwarefile in a running of fetchware.
    __clear_CONFIG();

    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);


    my $install_success = cmd_install($test_dist_path);
    note("IS[$install_success]");

    ok($install_success,
        'check test-dist.fpkg cmd_install');

    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_install() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_install() delete temp files.');
};


subtest 'test cmd_install() failure using fail-dist' => sub {
	# Must skip this test unless release testing, because it leaves an orfaned
    # fetchware directory sitting in your system temporary directory. I could
    # have fetchware clean clean this directory up, or try to parse the output
    # to determine the path this directory is in, but that's brittle and
    # ridiculous.
    skip_all_unless_release_testing();
    # Now test cmd_install() failure. Make use of make_test_dist()'s configure
    # option to create a test-dist whoose ./configure will always fail causing
    # build() to fail, which will allow me to test to see if the temp dir stays
    # around, so that when build's fail you can debug them easily.
    my $fail_test_dist = make_test_dist(file_name => 'fail-dist',
        ver_num => '1.00', configure => <<EOF);
# A test ./configure for testing cmd_install() failing

echo "fetchware: ./configure failed!"
# Return failure exit status to truly indicate failure.
exit 1
EOF
    my $fail_dist_md5 = md5sum_file($fail_test_dist);

	fork_not_ok(sub {cmd_install($fail_test_dist)},
		'checked cmd_install() failure.');
};



subtest 'test cmd_install(else)' => sub {
    eval_ok(sub {cmd_install()}, <<EOE, 'checked cmd_install() no args');
fetchware: You called fetchware install incorrectly. You must also specify
either a Fetchwarefile or a fetchware package that ends with [.fpkg].
EOE

    eval_ok(sub {cmd_install('fetchware-test' . rand(3739929293))},
        <<EOE, 'checked cmd_install() file existence');
fetchware: You called fetchware install incorrectly. You must also specify
either a Fetchwarefile or a fetchware package that ends with [.fpkg].
EOE


};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
