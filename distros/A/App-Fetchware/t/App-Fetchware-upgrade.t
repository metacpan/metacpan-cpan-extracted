#!perl
# App-Fetchware-upgrade.t tests App::Fetchware's upgrade() subroutine, which
# determines if a new version of your program is available.
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

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# There is no ':OVERRIDE_START' to bother importing.
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT)); }

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");

my $class = 'App::Fetchware';


subtest 'test upgrade()' => sub {
    my @upgrade_succeeds = (
        ['/some/path/httpd-2.4.4.tar.bz2',
            '/var/log/fetchware/httpd-2.4.3.fpkg'],
        ['/some/path/httpd-2.4.1.tar.bz2',
            'var/log/fetchware/httpd-2.4.fpkg'],
        ['2', '1'],
    );

    for my $upgrade_args (@upgrade_succeeds) {
        ok(upgrade(@$upgrade_args),
            "checked upgrade(@$upgrade_args) success.");
    }



    my @upgrade_fails = (
        ['/some/path/httpd-2.4.3.tar.bz2',
            '/var/log/fetchware/httpd-2.4.4.fpkg'],
        ['/some/path/httpd-2.4.tar.bz2',
            'var/log/fetchware/httpd-2.4.1.fpkg'],
        [1, 2],

        ['/some/path/httpd-2.4.3.tar.bz2',
            '/var/log/fetchware/httpd-2.4.3.fpkg'],
        ['/some/path/httpd-2.4.1.tar.bz2',
            'var/log/fetchware/httpd-2.4.1.fpkg'],
        [1, 1],
    );

    for my $upgrade_args (@upgrade_fails) {
        ok(! upgrade(@$upgrade_args),
            "checked upgrade(@$upgrade_args) failure.");
    }
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
