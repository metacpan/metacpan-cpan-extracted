#!perl
# bin-fetchware-list.t tests bin/fetchware's cmd_list() subroutine, which
# lists your installed packages based on fetchware_database_path();
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '2'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Copy 'mv';
use File::Spec::Functions qw(catfile splitpath);
use Path::Class;


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

#my $fetchware_package_path = '/var/log/fetchware/httpd-2.2.22.fpkg';
my $fetchware_package_path;


subtest 'test cmd_list() success' => sub {
    # First install a test package to make sure there is something for cmd_list()
    # to find.
    my $test_dist_path = make_test_dist(file_name => 'test-dist',
        ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    ok(cmd_install($test_dist_path),
        'checked cmd_list() by installing a test-dist to list');
note("CWD[@{[cwd()]}]");

    print_ok(sub {cmd_list()}, qr/test-dist-1\.00/,
        'checked cmd_list() success.');

# Annoyingly clean up CONFIG. Shouln't end() do this!!!!:)
__clear_CONFIG();

note("CWD2[@{[cwd()]}]");
    # Now uninstall the useless test dist.
    ok(cmd_uninstall('test-dist-1.00'),
        'checked cmd_list() clean up installed test-dist.');

    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
