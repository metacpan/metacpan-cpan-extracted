# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 09-curses.t".
#
# Without "Build" file it could be called with "perl -I../lib 09-curses.t"
# or "perl -Ilib t/09-curses.t".  This is also the command needed to find
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

use Test::More;

#####################################
# prepare fixed environment:
use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);
use constant TMP_PATH => T_PATH . '/tmp';

do(T_PATH . '/functions/sub_perl.pl');

use constant HOME_PATH => TMP_PATH . '/home';

BEGIN {
    eval { require Curses::UI; };
    $@  and  plan skip_all => 'Curses::UI not found';
    plan tests => 1;

    delete $ENV{DISPLAY};
    $ENV{UI} = 'Curses';
    # no testing outside of t:
    $ENV{HOME} = HOME_PATH;
    $ENV{LXC_DEFAULT_CONF_DIR} = TMP_PATH;
}

-f TMP_PATH . '/lxc/conf/10-NET-default.conf'
    or  die "$0 can only run after a successful invocation of t/02-init.t\n";

#########################################################################
# simple failing test to trigger END of Container.pm:
my $re =
    "using 'Curses' as UI\n" .
    'The name of the container may only contain word char.*! at -e line.*' .
    "\\s+waiting \\d+ seconds before screen is cleared\\s*";
$_ = _sub_perl('use App::LXC::Container;
		App::LXC::Container::setup("bad-name!");');
like($_, qr/^$re$/, 'using UI::Curses waits at END');
