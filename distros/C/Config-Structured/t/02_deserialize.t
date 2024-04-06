use v5.26;
use warnings;

use Test2::V0;

use Config::Structured;
use IO::All;

use ok 'Config::Structured';

my @f = (
  {conf => 't/conf/perl/config.conf', def => 't/conf/perl/config.conf.def'},
  {conf => 't/conf/json/config.json', def => 't/conf/json/definition.json'},
  {conf => 't/conf/yml/config.yml',   def => 't/conf/yml/definition.yml'},
);

foreach my $f (@f) {
  ok(my $conf = Config::Structured->new(structure => $f->{def}, config => $f->{conf}), 'Initialized with filenames');
  is($conf->db->pass, 'app_pass', 'Check conf->db->pass value');

  ok(
    my $fconf =
      Config::Structured->new(structure => scalar io->file($f->{def})->slurp, config => scalar io->file($f->{conf})->slurp),
    'Initialized with data'
  );
  is($fconf->db->pass, 'app_pass', 'Check fconf->db->pass value');
}

done_testing;
