use strict;
use warnings;

use Test::More;
use File::Temp;

use App::Xssh;
use App::Xssh::Config;

# Arrange for a safe place to play
$ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );

my $xssh = App::Xssh->new();

# Mess with the config data
my $c = App::Xssh::Config->new();
ok($xssh->setValue($c,"profile","testprofile","attribute","red"), "setprofile profile");
ok($xssh->setValue($c,"hosts","testhost","foreground","red"), "sethost foreground");
ok($xssh->setValue($c,"hosts","DEFAULT","background","red"), "sethost default background");
ok($xssh->setValue($c,"hosts","testhost","profile","testprofile"), "sethost testhost profile");

# Test whether the config options taken hold
my $c2 = App::Xssh::Config->new();
my $options = $xssh->getTerminalOptions($c2,"testhost");
is($options->{foreground}, "red", "host option found");
is($options->{background}, "red", "default option found");
is($options->{attribute}, "red", "profile option found");

# test if showConfig returns the same information
my $str = $c2->show();
like($str, qr/foreground.*red/, "showconfig() contains similar data");

# Just in case all the above isn't really testing anything
isnt($options->{foreground}, "blue", "control test");

done_testing();
