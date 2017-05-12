use strict;
use warnings;

use Test::More;
use File::Temp;

use App::Xssh;
use App::Xssh::Config;

# Arrange for a safe place to play
$ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );

my $xssh = App::Xssh->new();
my $config = App::Xssh::Config->new();

# Create a wildcard host option
$config->add(["hosts","x.*","foreground"],"red");

# See that a wildcard doesn't change everything
my $o1 = $xssh->getTerminalOptions($config,"abc");
isnt($o1->{foreground}, "red", "options for x.* don't affect abc");

# See that a wildcard does change things that start with 'x'
my $o2 = $xssh->getTerminalOptions($config,"xyz");
is($o2->{foreground}, "red", "options for x.* affect xyz");

done_testing();
