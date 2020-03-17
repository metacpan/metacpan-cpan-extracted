use strict;
use warnings qw(all);
use 5.022;

use Test::More;

use Config::Structured;

use File::Slurp qw(slurp);

my @f = (
  {conf => 't/conf/perl/config.conf', def => 't/conf/perl/config.conf.def'},
  {conf => 't/conf/json/config.json', def => 't/conf/json/definition.json'},
  {conf => 't/conf/yml/config.yml',   def => 't/conf/yml/definition.yml'},
);

plan tests => 1 + 4 * @f;

use_ok('Config::Structured', 'Loaded Config::Structured');

foreach my $f (@f) {
  ok(my $conf = Config::Structured->new(structure => $f->{def}, config => $f->{conf}), 'Initialized with filenames');
  is($conf->db->pass, 'app_pass', 'Check conf->db->pass value');

  ok(my $fconf = Config::Structured->new(structure => scalar slurp($f->{def}), config => scalar slurp($f->{conf})),
    'Initialized with data');
  is($fconf->db->pass, 'app_pass', 'Check fconf->db->pass value');
}
