#!perl
# App-Fetchware-uninstall.t tests App::Fetchware's uninstall() subroutine,
# uninstalls your program.
# # Pretend to be bin/fetchware, so that I can test App::Fetchware as though
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
use Test::More 0.98 tests => '1'; #Update if this changes.

use File::Spec::Functions qw(splitpath catfile);
use URI::Split 'uri_split';
use Cwd 'cwd';

use Test::Fetchware ':TESTING';

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





###BUGALERT### Add actual tests to actually test uninstall(). See the existing
#uninstall tests that are in t/bin-fetchware-uninstall.t.



# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
