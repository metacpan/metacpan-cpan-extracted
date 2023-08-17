# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 99-cleanup.t".
#
# Without "Build" file it could be called with "perl -I../lib 99-cleanup.t"
# or "perl -Ilib t/99-cleanup.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd;
use File::Path;

use Test::More tests => 3;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/files_directories.pl');

_setup_dir('');
use constant HOME_PATH => TMP_PATH . '/home';
_setup_dir('/home');

BEGIN {
    delete $ENV{DISPLAY};
    $ENV{UI} = 'PoorTerm';	# PoorTerm allows easy testing
    # no testing outside of t:
    $ENV{HOME} = HOME_PATH;
    defined $ENV{LXC_DEFAULT_CONF_DIR}  and  delete $ENV{LXC_DEFAULT_CONF_DIR};
}

use App::LXC::Container;

#########################################################################
# we only remove the left-overs of all previous tests:

my $errors = '';
$_ = File::Path::remove_tree(TMP_PATH, {error => \$errors});
ok($_ > 0, 'remove_tree removed something');
is(@$errors, 0, 'remove_tree had no error');
is(-e TMP_PATH, undef, 'TMP_PATH is gone');
