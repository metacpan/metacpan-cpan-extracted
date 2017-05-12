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
my @files = <$this_dir/xml/*.xml>;

ok(scalar(@files) > 0);

for my $file(@files){
  my $importer;
  eval {
    $importer = Catmandu::Importer::MODS->new(file => $file,type => 'xml');
  };
  ok(defined($importer) && ref($importer) eq "Catmandu::Importer::MODS");
  my $count = $importer->count;
  ok($count > 0);
}

done_testing 3 + scalar(@files)*2;
