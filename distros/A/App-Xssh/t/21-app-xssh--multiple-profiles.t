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

# Create some profile attributes to define the FG/BG
$config->add(["profile","local","foreground"],"red");
$config->add(["profile","trusted","background"],"red");

# Create a host entry that references both profile attributes
$config->add(["hosts","testhost","profile"],"local,trusted");

# See that the attribute contains the FG and the BG options
my $options = $xssh->getTerminalOptions($config,"testhost");
ok($options->{foreground} eq "red", "foreground option");
ok($options->{background} eq "red", "background option");

done_testing();
