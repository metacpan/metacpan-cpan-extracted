use Test::More tests => 12;

use strict;
use warnings;

BEGIN {
    use_ok('Config::Ant');   
}

# Create a config
my $config = Config::Ant->new();
ok($config, "Got a value");
is(ref($config), 'Config::Ant', "Correctly blessed");

# Read the config
$config->read('t/data/file1.conf');
ok($config->{_}->{'root.directory'}, "Found a value for the root directory");
is($config->{_}->{'root.directory'}, '/usr/local', "Found the correct value for the root directory");

ok($config->{_}->{'perl'}, "Found a value for perl");
is($config->{_}->{'perl'}, '/usr/local/bin/perl', "Found the correct value for perl");

ok(! exists($config->{_}->{'include'}), "No definition (yet) for include");

# You can also read a second file, with properties substituted from the first
$config->read('t/data/file2.conf');
ok(exists($config->{_}->{'include'}), "Now we get a definition for include");
is($config->{_}->{'include'}, '/usr/local/include', "Found the correct value for include");

ok(exists($config->{_}->{'etc'}), "Now we get a definition for etc");
is($config->{_}->{'etc'}, '${system.directory}/etc', "Found the correct value for include");

1;
