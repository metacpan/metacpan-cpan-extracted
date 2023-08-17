# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 00-test-os.t".
#
# Without "Build" file it could be called with "perl -I../lib 00-test-os.t"
# or "perl -Ilib t/00-test-os.t".  This is also the command needed to find
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

use Test::More tests => 4;

#########################################################################
# get some OS details:
open my $osr, '<', '/etc/os-release';
ok($osr, 'could open /etc/os-release');
if ($osr)
{
    while (<$osr>)
    {	diag($_)  if  m/^\s*(?:ID|ID_LIKE|NAME|PRETTY_NAME|VERSION)\s*=/;   }
    close $osr;
}

#########################################################################
# check for necessary LXC programs:
foreach (qw(lxc-ls lxc-execute lxc-attach))
{
    my @paths = ();
    foreach my $path (split m/:/, $ENV{PATH})
    {
	$path .= '/' . $_;
	-x $path  and  push  @paths , $path;
    }
    # If we're running in a smoker we try skipping the failed tests:
 SKIP:
    {
	if (0 == @paths  &&  -t STDIN)
	{   skip 'on smoke tests: ignoring missing ' . $_, 1;   }
	else
	{   ok(0 < @paths, 'found ' . $_);   }
    }
    diag('found ', $_, " as @paths");
}
