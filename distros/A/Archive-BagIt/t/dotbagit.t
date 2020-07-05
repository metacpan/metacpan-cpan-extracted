
BEGIN { chdir 't' if -d 't' }

use Test::More 'no_plan';
use strict;
use warnings;


use lib '../lib';

use File::Spec;
use File::Path;
use File::Copy;

my $Class = 'Archive::BagIt::DotBagIt';
use_ok($Class);

my @ROOT = grep {length} 'src','dotbagit';

note( "What is ROOT:");
note (explain(@ROOT));


my $SRC_BAG = File::Spec->catdir( @ROOT, 'src_bag');
my $SRC_FILES = File::Spec->catdir( @ROOT, 'src_files');
my $DST_BAG = File::Spec->catdir(@ROOT, 'dst_bag');


#validate tests

{
  my $bag = $Class->new({bag_path=>$SRC_BAG});
  note "the bag object: ";note explain ($bag);
  ok($bag,        "Object created");
  isa_ok ($bag,   $Class);

  note "checksum algos:"; note explain($bag->checksum_algos);
  note "manifest files:"; note explain $bag->manifest_files;
  note "bag path:"; note explain $bag->bag_path;
  note "metadata path: "; note explain $bag->metadata_path;
  note "tagmanifest_files: "; note explain $bag->tagmanifest_files;
  note "manifest_entries: ";note explain $bag->manifest_entries;
  note "tagmanifest_entries: ";note explain $bag->tagmanifest_entries;
  note "payload files: "; note explain $bag->payload_files;

  my $result = $bag->verify_bag;
  ok($result,     "Bag verifies");
}

{
  mkdir($DST_BAG);
  copy($SRC_FILES."/1", $DST_BAG);
  copy($SRC_FILES."/2", $DST_BAG);

  my $bag = $Class->make_bag($DST_BAG);

  ok ($bag,       "Object created");
  isa_ok ($bag,   $Class);
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

__END__
