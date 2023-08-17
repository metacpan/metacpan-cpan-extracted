# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 00-test-functions.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 00-test-functions.t" or "perl -Ilib t/00-test-functions.t".  This is also
# the command needed to find out what specific tests failed in a "./Build
# test" as the later only gives you a number and not the description of the
# test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd;

use Test::More tests => 4;

use constant T_PATH => map { s|/[^/]+$||; $_ } Cwd::abs_path($0);

foreach (qw(call_with_stdin.pl sub_perl.pl))
{
    ok(-f T_PATH . '/functions/' . $_, 'found ' . $_);
    my $rc = do(T_PATH . '/functions/' . $_);
    ok($rc, 'could run ' . $_);
    unless ($rc)
    {
	$@  and  warn 'parsing error: ', $@, "\n";
	defined $rc  or
	    warn 'access error "', T_PATH, '/functions/', $_, '": ', $!, "\n";
    }
}
