#!perl
# App-Fetchware-unarchive.t tests App::Fetchware's unarchive() subroutine, which
# unzips or untars your downloaded archived software.
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
use Test::More 0.98 tests => '8'; #Update if this changes.
use File::Spec::Functions qw(devnull catfile);

use Test::Fetchware ':TESTING';
use App::Fetchware::Util ':UTIL';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT :OVERRIDE_UNARCHIVE)); }


# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");


# Call start() to create & cd to a tempdir, so end() called later can delete all
# of the files that will be downloaded.
my $temp_dir = start();


subtest 'OVERRIDE_UNARCHIVE exports what it should' => sub {
    my @expected_overide_unarchive_exports = qw(
        check_archive_files    
        list_files
        list_files_tar
        list_files_zip
        unarchive_package
        unarchive_tar
        unarchive_zip
    );
    # sort them to make the testing their equality very easy.
    my @sorted_unarchive_tag = sort
        @{$App::Fetchware::EXPORT_TAGS{OVERRIDE_UNARCHIVE}};
    @expected_overide_unarchive_exports = sort @expected_overide_unarchive_exports;
    is_deeply(\@sorted_unarchive_tag, \@expected_overide_unarchive_exports,
        'checked for correct OVERRIDE_UNARCHIVE @EXPORT_TAG');
};


my $tar_package_path;
subtest 'test list_files_tar()' => sub {
    skip_all_unless_release_testing();

    # download() an example tar file to list its files.
    $tar_package_path = download_file_url($ENV{FETCHWARE_LOCAL_URL});
    $tar_package_path = catfile($temp_dir, $tar_package_path);
    ok(-e $tar_package_path,
        'checked list_files_tar() download tar file successful.');

    my $file_list = list_files_tar($tar_package_path);
    my @file_list = @$file_list;
    for my $expected (qw(
        README
        LAYOUT
        configure
    )) {
        ok(grep /$expected$/,  @file_list,
            "checked list_files_tar() success [$expected]");
    }

};


my $zip_package_path;
subtest 'test list_files_zip()' => sub {
    skip_all_unless_release_testing();


    # download() an example tar file to list its files.
    $zip_package_path = download_file_url($ENV{FETCHWARE_LOCAL_ZIP_URL});
    $zip_package_path = catfile($temp_dir, $zip_package_path);
    ok(-e $zip_package_path,
        'checked list_files_zip() download zip file successful.');

    my $file_list = list_files_zip($zip_package_path);
    my @file_list = @$file_list;
    for my $expected (qw(
        README
        NEWS
        MAINTAINERS
        COPYING
        EXTENDING.html
    )) {
        ok(grep /$expected$/, @file_list,
            "checked list_files_tar() success [$expected]");
    }

};



subtest 'test unarchive_tar()' => sub {
    skip_all_unless_release_testing();

    my @extracted_files = unarchive_tar($tar_package_path);

    ok(@extracted_files,
        'checked unarchive_tar() successfully extracted file');

    ok(-e $_, "checked unarchive_tar() extracted file exists [$_]")
        for @extracted_files;
};


subtest 'test unarchive_zip()' => sub {
    skip_all_unless_release_testing();

    ok(unarchive_zip($zip_package_path),
        'checked unarchive_zip() success');
};



subtest 'test check_archive_files' => sub {
    my $fake_file_paths = [qw(
        samedir/blah/file/who.cares
        samedir/not/a/rea/file/but/who.cares
        samedir/a/real/file/just/joking
        samedir/why/am/i/adding/yet/another/worthless/fake.file
    )];

    ok(check_archive_files($fake_file_paths),
        'checked check_archive_files() success');

    push @$fake_file_paths, '/absolute/path/';
    eval_ok(sub {check_archive_files($fake_file_paths)},
        <<EOE, 'checked check_archive_files() absolute path failure');
App-Fetchware: run-time error. The archive you asked fetchware to download has
one or more files with an absolute path. Absolute paths in archives is
dangerous, because the files could potentially overwrite files anywhere in the
filesystem including important system files. That is why this is a fatal error
that cannot be ignored. See perldoc App::Fetchware.
Absolute path [/absolute/path/].
[
samedir/blah/file/who.cares
samedir/not/a/rea/file/but/who.cares
samedir/a/real/file/just/joking
samedir/why/am/i/adding/yet/another/worthless/fake.file
/absolute/path/
]
EOE
    pop @$fake_file_paths;


    push @$fake_file_paths, 'differentdir/to/test/differeent/dir/die';
    {
        local $SIG{__WARN__} = sub {
            is($_[0],
                <<EOI, 'checked check_archive_files() different dir failure');
App-Fetchware: run-time warning. The archive you asked Fetchware to download 
does *not* have *all* of its files in one and only one containing directory.
This is not a problem for fetchware, because it does all of its downloading,
unarchive, and building in a temporary directory that makes it easy to
automatically delete all of the files when fetchware is done with them. See
perldoc App::Fetchware.
EOI
        };
        check_archive_files($fake_file_paths);
    }
    pop @$fake_file_paths;
};


subtest 'test unarchive()' => sub {
    skip_all_unless_release_testing(); 

    my $package_path = $ENV{FETCHWARE_LOCAL_URL};
    $package_path =~ s!^file://!!;

    ok(unarchive($package_path), 'checked unarchive() success');
};



# Call end() to delete temp dir created by start().
end();


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
