BEGIN { chdir 't' if -d 't' }
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Spec;
use File::Path;
use File::Copy;
use Test::More 'no_plan';
use Test::Warnings;
use lib '../lib';

my $Class = 'Archive::BagIt';
use_ok($Class);

my @ROOT = grep {length} 'src';

#warn "what is this: ".Dumper(@ROOT);

my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');

#validate tests

{
  my $bag = $Class->new({bag_path=>$SRC_BAG});
  ok($bag,        "Object created");
  isa_ok ($bag,   $Class);

  note ("checksum algos:", explain $bag->checksum_algos);
  note ("manifest files:", explain $bag->manifest_files);
  note ("bag path:", explain $bag->bag_path);
  note ("metadata path: ", explain $bag->metadata_path);
  note explain $bag->tagmanifest_files;
  my $result = $bag->verify_bag;
  ok($result,     "Bag verifies");
}

{
  note "copying to $DST_BAG";
  if(-d $DST_BAG) {
    rmtree($DST_BAG);
  }
  mkdir($DST_BAG);
  copy($SRC_FILES."/1", $DST_BAG);
  copy($SRC_FILES."/2", $DST_BAG);
  copy($SRC_FILES."/thréê", $DST_BAG);

  note "making bag $DST_BAG";
  my $bag;
  my $warning = Test::Warnings::warning { $bag = $Class->make_bag($DST_BAG) };
  like (
    $warning ,
    qr/no payload path/,
    'Got expected warning from make_bag()',
  ) or diag 'got unexpected warnings:' , explain($warning);

  ok ($bag,       "Object created");
  isa_ok ($bag,   $Class);
  ok ($bag->load(), "Bag loaded");

  my $result = $bag->verify_bag();
  ok($result,     "Bag verifies");

  rmtree($DST_BAG);
}

{

  my $bag = $Class->new($SRC_BAG);
  my @manifests = $bag->manifest_files();
  my $cnt = scalar @manifests;
  my $expect = 1;

  is($cnt, $expect, "All manifests counted");

  my @tagmanifests = $bag->tagmanifest_files();
  my $tagcnt = scalar @tagmanifests;
  my $tagexpect =1;

  is($tagcnt, $tagexpect, "All tagmanifests counted");

}
{
  my $bag = $Class->new(bag_path=>$SRC_BAG, use_plugins => 'Archive::BagIt::Plugin::Manifest::MD5');
  isa_ok($bag, 'Archive::BagIt');
  my %plugins = %{ $bag->plugins() };
  foreach my $k (keys %plugins) {
    isa_ok($plugins{$k}, 'Archive::BagIt::Plugin::Algorithm::MD5');
  }
}

__END__
