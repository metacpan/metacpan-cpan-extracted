use warnings ;
use strict;
use Test::More tests => 1 ;
use Config::Augeas::Exporter;

my $aug = Config::Augeas::Exporter->new();

ok($aug, "Created new Augeas object");

