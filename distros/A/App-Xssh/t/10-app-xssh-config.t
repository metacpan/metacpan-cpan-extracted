use strict;
use warnings;

use Test::More;
use File::Temp;

use App::Xssh::Config;

# Arrange for a safe place to play
my $dir = File::Temp::tempdir( CLEANUP => 1 );
$ENV{HOME} = $dir;

# Create an object
my $xssh = App::Xssh::Config->new();
ok($xssh, "Create Object");

# Test (and modify) location of config file
ok($xssh->_configFilename() =~ m/xsshrc/, "reasonable config filename");

SKIP: {
  skip("Windows filenames don't play nicely as regular expressions",1) if $dir =~ m/\\/;

  ok($xssh->_configFilename() =~ m/$dir/, "config filename modified");
}

# try reading and changing the config data
my $data = $xssh->read();
ok($data, "read empty config file");
ok($xssh->add(["location","key"],"value1"), "Modified config data");
ok($xssh->add(["location","deep","key"],"value2"), "Modified config again");
ok($xssh->add(["location","deep","deleteme"],"value3"), "Modified config again");
ok($xssh->delete(["location","deep","deleteme"]), "deleted config value");

# Save and reread the config data
ok($xssh->write(), "Write config out");
my $data2 = $xssh->read();
ok($data2, "read config file again");
ok($data2->{location}->{key} eq "value1", "Value retrieved");
ok($data2->{location}->{deep}->{key} eq "value2", "Deep value retrieved");
ok(!defined($data2->{location}->{deep}->{deleteme}), "Deleted value removed");

done_testing();
