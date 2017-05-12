use warnings ;
use strict;
use Test::More tests => 2;
use Config::Augeas;
use Config::Augeas::Exporter;
use File::Path;

# pseudo root were input config file are read
my $from_root = 'augeas-from/';

# pseudo root where config files are written by config-model
my $to_root = 'augeas-to/';

my $from_aug = Config::Augeas::Exporter->new(root => $from_root);

ok($from_aug, "Created new Augeas object for to_hash direction");

my $hash = $from_aug->to_hash();

ok($hash, "Got Hash");

