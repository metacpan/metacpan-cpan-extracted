#!perl
# App-Fetchware-lookup.t tests App::Fetchware's lookup() subroutine, which
# determines if a new version of your program is available.
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

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '5'; #Update if this changes.

use File::Spec::Functions qw(splitpath catfile);
use URI::Split qw(uri_split uri_join);
use Cwd 'cwd';

use Test::Fetchware ':TESTING';
use App::Fetchware::Config ':CONFIG';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT :OVERRIDE_DOWNLOAD)); }

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");

my $class = 'App::Fetchware';



subtest 'OVERRIDE_DOWNLOAD exports what it should' => sub {
    my @expected_overide_download_exports = qw(
        determine_package_path
    );
    # sort them to make the testing their equality very easy.
    my @sorted_download_tag = sort @{$App::Fetchware::EXPORT_TAGS{OVERRIDE_DOWNLOAD}};
    @expected_overide_download_exports = sort @expected_overide_download_exports;
    is_deeply(\@sorted_download_tag, \@expected_overide_download_exports,
        'checked for correct OVERRIDE_DOWNLOAD @EXPORT_TAG');

};


subtest 'test determine_package_path()' => sub {
    my $cwd = cwd();
    note("cwd[$cwd]");

    is(determine_package_path($cwd, 'bin/fetchware'),
        catfile(cwd(), 'bin/fetchware'),
        'checked determine_package_path() success');

};


subtest 'test download()' => sub {
    skip_all_unless_release_testing();

    for my $url ($ENV{FETCHWARE_FTP_DOWNLOAD_URL},
        $ENV{FETCHWARE_HTTP_DOWNLOAD_URL}) {
note("URL[$url]");

        eval_ok(sub {download(cwd(), $url)},
            qr/App-Fetchware: download\(\) has been passed a full URL \*not\* only a path./,
            'checked download() url exception');

        # manually set $CONFIG{TempDir} to cwd().
        my $cwd = cwd();
        config_replace('temp_dir', "$cwd");

        # Determine $filename for is() test below.
        my ($scheme, $auth, $path, $query, $frag) = uri_split($url);
        # Be sure to define a mirror, because with just a path download() can't
        # work properly.
        config(mirror => uri_join($scheme, $auth, undef, undef, undef));
        
        my ($volume, $directories, $filename) = splitpath($path);
note("FILENAME[$filename]");
note("LASTURL[$url] CWD[$cwd]");
        # Remeber download() wants a $path not a $url.
        is(download($cwd, $path), catfile($cwd, $filename),
            'checked download() success.');

        ok(-e $filename, 'checked download() file exists success');
        ok(unlink $filename, 'checked deleting downloaded file');

    }

};


subtest 'test download() local file success' => sub {
    # manually set $CONFIG{TempDir} to cwd().
    my $cwd = cwd();
    config_replace('temp_dir', "$cwd");

    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00', destination_directory => 't');
    my $test_dist_md5 = md5sum_file($test_dist_path);
    my $url = "file://$test_dist_path";

    # Determine $filename for is() test below.
    my ($scheme, $auth, $path, $query, $frag) = uri_split($url);
    my ($volume, $directories, $filename) = splitpath($path);
    ###BUGALERT## Remove cwd(), and replace with temp dir, so tests can be run
    #in parallel to speed up development.
    # I must create a lookup_url to tell download_file() that it's downloading a
    # local file.
    config(lookup_url => $url);
    config(mirror => uri_join($scheme, $auth, undef, undef, undef));
    is(download($cwd, $path), catfile($cwd, $filename),
        'checked download() local file success.');

    ok(-e $filename, 'checked download() file exists success');
    ok(unlink($filename), 'checked deleting downloaded file');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
