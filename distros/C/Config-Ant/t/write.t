use Test::More tests => 4;

use strict;
use warnings;

BEGIN {
    use_ok('Config::Ant');   
}

use File::Temp;
use File::Slurp;

# Create a config
my $config = Config::Ant->new();
ok($config, "Got a value");
is(ref($config), 'Config::Ant', "Correctly blessed");

# Read the config
$config->read('t/data/file1.conf');
$config->read('t/data/file2.conf');

my $fh = File::Temp->new(UNLINK => 0);
$config->write($fh);
close($fh);

my $text = File::Slurp::read_file($fh->filename());
like($text, qr{perl\s*=\s*/usr/local/bin/perl}, "Found the perl substituted value");

1;
