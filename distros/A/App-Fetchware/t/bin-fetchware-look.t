#!perl
# bin-fetchware-look.t tests bin/fetchware's look() subroutine, which
# is fetchware's version of cpan's look command.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '3'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use App::Fetchware::Util 'original_cwd';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Copy 'mv';
use File::Spec::Functions qw(catfile splitpath updir);
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


# Save cwd to chdir to it later, because cmd_look() completes with a changed cwd(),
# which messes up the relative path that the next subtest uses, so this lame
# cwd() and chdir hack is used. I should refactor these out of fetchware's test
# suite.
my $original_cwd = cwd();


subtest 'test cmd_look() success' => sub {
    skip_all_unless_release_testing();

my $fetchwarefile = <<EOF;
use App::Fetchware;

program 'Apache 2.2';

lookup_url '$ENV{FETCHWARE_HTTP_LOOKUP_URL}';

mirror '$ENV{FETCHWARE_FTP_MIRROR_URL}';

filter 'httpd-2.2';
EOF

    my $fetchwarefile_path = create_test_fetchwarefile($fetchwarefile);
note("FFP[$fetchwarefile_path]");
    ok(-e $fetchwarefile_path,
        'check create_test_fetchwarefile() test Fetchwarefile');

    my $look_path = cmd_look($fetchwarefile_path);
note("LP[$look_path]");

    # And then test if cmd_look() was successful.
    like($look_path, qr/@{[config('filter')]}/,
        'check cmd_look(Fetchware) success.');

    # Also check if the $look_path actually still exists on the filesystem!
    ok(-e $look_path, 'check cmd_look(Fetchware) look path exists');
    # Remove $look_path's parent, which is the tempdir that cmd_look() used to
    # store test-dist in. If I don't do this this tempdir will stick around,
    # because cmd_look() does not have File::Test remove it, because this
    # directory is supposed to stick around, so the user can look through it.
    # Also, chdir back to original_cwd(), because my pwd is currently
    # $parent_look_path, which I'm about to delete, because its my pwd, I can
    # not delete it, so I'll have to go somewhere else first.
    chdir(original_cwd())
        or fail('Failed to chdir back to original_cwd().');
    my $parent_look_path = dir($look_path)->parent;
    rmdashr_ok($parent_look_path,
        "check cmd_look() remove look path success[$parent_look_path]"); 
};


# And clear CONFIG.
__clear_CONFIG();


subtest 'test cmd_look() test-dist success' => sub {
    my $test_dist_path = make_test_dist(file_name => 'test-dist', ver_num => '1.00');
    my $test_dist_md5 = md5sum_file($test_dist_path);

    my $look_path = cmd_look($test_dist_path);
note("LOOKPATH[$look_path]");

    like($look_path, qr/test-dist-1\.00/,
        'check cmd_look(test-dist) success.');

    # Also check if the $look_path actually still exists on the filesystem!
    ok(-e $look_path, 'check cmd_look(test-dist) look path exists');

    # Cleanup the test-dist crap.
    ok(unlink($test_dist_path, $test_dist_md5),
        'checked cmd_list() delete temp files.');
    # Remove $look_path's parent, which is the tempdir that cmd_look() used to
    # store test-dist in. If I don't do this this tempdir will stick around,
    # because cmd_look() does not have File::Test remove it, because this
    # directory is supposed to stick around, so the user can look through it.
    # Also, chdir back to original_cwd(), because my pwd is currently
    # $parent_look_path, which I'm about to delete, because its my pwd, I can
    # not delete it, so I'll have to go somewhere else first.
    chdir(original_cwd())
        or fail('Failed to chdir back to original_cwd().');
    my $parent_look_path = dir($look_path)->parent;
    rmdashr_ok($parent_look_path,
        "check cmd_look() remove look path success[$parent_look_path]"); 
};




# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
