#!perl
use strict;
use warnings;
use Test::More;
use Catmandu::Importer::MODS;
use File::Basename;
use Catmandu::Util qw(:io :is);

BEGIN {
  use_ok 'Catmandu::Importer::MODS';
}

require_ok 'Catmandu::Importer::MODS';

my $this_dir =dirname(__FILE__);
my @files = <$this_dir/json/*.json>;

ok(scalar(@files) > 0);

for my $file(@files){
  my $importer;
  eval {
    $importer = Catmandu::Importer::MODS->new(file => $file,type => 'json');
  };
  ok(defined($importer) && ref($importer) eq "Catmandu::Importer::MODS");
  ok($importer->count > 0);
}

done_testing 3 + scalar(@files)*2;
