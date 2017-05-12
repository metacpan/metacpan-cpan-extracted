#!perl
# App-Fetchware-verify.t tests App::Fetchware's verify() subroutine, which gpg
# verifies your downloaded archive if possible. If not it will also try md5/sha.
# Pretend to be bin/fetchware, so that I can test App::Fetchware as though
# bin/fetchware was calling it.
package fetchware;
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

use Fcntl ':mode';
use File::Spec::Functions 'devnull';
use File::Copy 'cp';
use File::Temp 'tempfile';

use App::Fetchware::Util ':UTIL';
use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '9'; #Update if this changes.

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT :OVERRIDE_VERIFY)); }

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");




subtest 'OVERRIDE_VERIFY exports what it should' => sub {
    my @expected_overide_verify_exports = qw(
        gpg_verify
        sha1_verify
        md5_verify
        digest_verify
    );
    # sort them to make the testing their equality very easy.
    my @sorted_verify_tag = sort @{$App::Fetchware::EXPORT_TAGS{OVERRIDE_VERIFY}};
    @expected_overide_verify_exports = sort @expected_overide_verify_exports;
    is_deeply(\@sorted_verify_tag, \@expected_overide_verify_exports,
        'checked for correct OVERRIDE_VERIFY @EXPORT_TAG');
};



my $download_path;
my $package_path;
subtest 'Do verify() prereqs.' => sub {
    skip_all_unless_release_testing();
    # Call start() to create & cd to a tempdir, so end() called later can delete
    # all of the files that will be downloaded.
    my $temp_dir = start();
    # Use config subs to determine a $download_path based on the current version
    # of apache instead of updating this manually.
    program 'httpd-2.2';
    lookup_url 'http://www.apache.org/dist/httpd';
    mirror 'http://apache.mirrors.pair.com/httpd';
    filter 'httpd-2.2';
    $download_path = lookup();
    $package_path = download($temp_dir, $download_path);

    ok(-e $temp_dir,
        'checked successful start().');
    ok(defined $download_path,
        'checked successful lookup().');
    ok(-e $package_path,
        'checked successful download().');
};

subtest 'test digest_verify()' => sub {
    skip_all_unless_release_testing();

    for my $digest_type (qw(SHA-1 MD5)) {

        note("TYPE[$digest_type]");


        ok(digest_verify($digest_type, $download_path, $package_path),
            "checked digest_verify($digest_type) success.");

        eval_ok(sub {
                digest_verify($digest_type, $download_path,
                    './doesntexistunlessyoucreateitbutdontdothat');
        }, <<EOE, "checked digest_verify($digest_type) package path failure");
App-Fetchware: run-time error. Fetchware failed to open the file it downloaded
while trying to read it in order to check its MD5 sum. The file was
[./doesntexistunlessyoucreateitbutdontdothat]. See perldoc App::Fetchware.
EOE
        # Undo last tests change to make it fail, so now it'll succeed.

###HOWTOTEST###eval_ok(sub {}, <<EOE, 'checked md5_verify() md5 croaked with error'
###HOWTOTEST###    eval_ok(sub {}, <<EOD, 'checked md5_verify() failed to open downloaded md5m file');
###HOWTOTEST###App-Fetchware: run-time error. Fetchware failed to open the md5sum file it
###HOWTOTEST###downloaded while trying to read it in order to check its MD5 sum. The file was
###HOWTOTEST###[$md5_file]. See perldoc App::Fetchware.
###HOWTOTEST###EOE

        # Test failure by setting $package_path to the wrong thing.
        # Create a useless file to test against.
        my ($tf_fh, $tf_name)
            =
            tempfile("fetchware-test-$$-XXXXXXXXXX", TMPDIR => 1, UNLINK => 1);
        ok(-e $tf_name,
            'checked tempfile creation to test digest_verify() failure()');
        print $tf_fh 'SOME CRAP TO ACTUALLY MD5/SHA1 SUM!!!!!';
        close $tf_fh;
        is(digest_verify($digest_type, $download_path, $tf_name), undef,
            "checked digest_verify($digest_type) failure");

        eval_ok(sub {
            digest_verify($digest_type,
                'ftp://fake.url/will.fail', $package_path);
        }, <<EOE, "checked digest_verify($digest_type) download digest failure");
App-Fetchware: Fetchware was unable to download the $digest_type sum it needs to
download to properly verify you software package. This is a fatal error, because
failing to verify packages is a perferable default over potentially installin
compromised ones. If failing to verify your software package is ok to you, then
you may disable verification by adding verify_failure_ok 'On'; to your
Fetchwarefile. See perldoc App::Fetchware.
EOE

    } # End for.
};


subtest 'test md5_verify()' => sub {
    skip_all_unless_release_testing();

    ok(md5_verify($download_path, $package_path),
        "checked md5_verify() success.");

    md5_url 'http://www.apache.org/dist/httpd/';

    ok(md5_verify($download_path, $package_path),
        'checked md5_verify() md5_url success.');
};

subtest 'test sha1_verify()' => sub {
    skip_all_unless_release_testing();

    ok(sha1_verify($download_path, $package_path),
        "checked sha1_verify() success.");

    sha1_url 'http://www.apache.org/dist/httpd/';

    ok(sha1_verify($download_path, $package_path),
        'checked sha1_verify() sha_url success.');
};



subtest 'test gpg_verify()' => sub {
    skip_all_unless_release_testing();

    # Clean the gunk of of %CONFIG.
    __clear_CONFIG();

    # Test gpg_verify() success.
    lookup_url 'http://www.apache.org/dist/httpd';
    ok(gpg_verify($download_path), 'checked gpg_verify() success');

    # Test gpg_verify() success using gpg_keys_url.
    gpg_keys_url config('lookup_url') . '/KEYS';

    ok(gpg_verify($download_path), 'checked gpg_verify() success');

    eval_ok(sub {
        gpg_verify('ftp://fake.url/will.fail');
        }, <<EOE, 'checked gpg_verify() download gpg_sig_url failure'); 
App-Fetchware: Fetchware was unable to download the gpg_sig_url you specified or
that fetchware tried appending asc, sig, or sign to [http://www.apache.org/will.fail.sign]. It needs
to download this file to properly verify you software package. This is a fatal
error, because failing to verify packages is a perferable default over
potentially installing compromised ones. If failing to verify your software
package is ok to you, then you may disable verification by adding
verify_failure_ok 'On'; to your Fetchwarefile. See perldoc App::Fetchware.
EOE

};


subtest 'test verify()' => sub {
    skip_all_unless_release_testing();

    # test verify_method
    # test gpg verify_method
    # test sha1 verify_method
    # test md5 verify_method
    # Specify a DownloadURL to test some gpg_verify() guessing magic.
    for my $verify_method (qw(gpg sha md5)) {
        config_replace('verify_method', "$verify_method");
        eval {verify($download_path, $package_path)};

        unless ($@) {
            pass("checked verify() verify_method $verify_method");
        } else {
            fail("checked verify() verify_method $verify_method");
        }
    }


    # test using copied gpg_verify setup from above.
    eval {verify($download_path, $package_path)};
    note("exe[$@]");
    unless ($@) {
        pass("checked verify() automatic method gpg");
    } else {
        fail("checked verify() automatic method gpg");
    }
    # test for skiping gpg & using sha1. Can't find a site that does this.
###BUGALERT### Figure out how to test for this. I may have to wait until I
#implement testing webserver to download files from using maybe
#Test::Fake::HTTPD or something else.
###HOWTOTEST??    eval {verify()};
###HOWTOTEST??    unless ($@) {
###HOWTOTEST??        pass("checked verify() automatic method sha");
###HOWTOTEST??    } else {
###HOWTOTEST??        fail("checked verify() automatic method sha");
###HOWTOTEST??    }
    # test using just a plain old md5sum.
    # Use postgressql to test for only a md5, though I should find a smaller
    # progject that packages up md5 correctly.
    # Must temporarily change the lookup_url.
    my $old_lookup = config('lookup_url');
    config_replace(lookup_url => 'http://ftp.postgresql.org/pub/source/');
    my $postgres_download_path =
        'http://ftp.postgresql.org/pub/source/v9.2.4/postgresql-9.2.4.tar.bz2';
    eval {verify(
        $postgres_download_path, download_file($postgres_download_path)
    )};
    unless ($@) {
        pass("checked verify() automatic method md5");
    } else {
        die $@;
        fail("checked verify() automatic method md5");
    }
    config_replace(lookup_url => $old_lookup);


    # Clear CONFIG for next run.
    __clear_CONFIG();

    # test verify failure with verify_failure_ok Off.
    eval_ok(sub {verify('ftp://fake.url/doesnt/exist.ever',
            $package_path)}, <<EOE, 'checked verify() failure');
App-Fetchware: run-time error. Fetchware failed to verify your downloaded
software package. You can rerun fetchware with the --force option or add
[verify_failure_ok 'True';] to your Fetchwarefile. See the section VERIFICATION
FAILED in perldoc fetchware.
EOE

    # test verify_failure_ok
    ###BUGALERT### Must test success & failure with this option.
    verify_failure_ok 'On';
    note("vfo[@{[config('verify_failure_ok')]}]");
    is(verify('ftp://fake.url/doesnt/exist.ever', $package_path),
        'warned due to verify_failure_ok',
        'checked verify() verify_failure_ok');

    # Test an invalid verify_method.
    verify_method 'invalid';
    eval_ok(sub {verify($download_path, $package_path)},
        <<EOE, 'checked verify() invalid verify_method');
App-Fetchware: run-time error. Your fetchware file specified a wrong
verify_method option. The only supported types are 'gpg', 'sha', 'md5', but you
specified [invalid]. See perldoc App::Fetchware.
EOE
    config_delete('verify_method');

};


subtest 'Call end() to clean up temporary directory.' => sub {
    # Skip this simple test, because start() is only caled with the other
    # prereques, which are skipped except during release testing.
    skip_all_unless_release_testing();
    # Call end() to delete temp dir created by start().
    ok(end(),
        'cleared out fetchware temporary directory.');
};


###BUGALERT###Add a subtest that uses make_test_dist() and md5sum_file() to test
#verify() functionality on non FETCHWARE_RELEASE_TESTING systems.

# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
