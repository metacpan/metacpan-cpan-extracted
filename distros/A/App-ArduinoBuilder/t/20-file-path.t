use strict;
use warnings;
use utf8;

use Test2::V0;

use App::ArduinoBuilder::FilePath;
use File::Spec::Functions;
use List::Util 'shuffle';

use FindBin;

for (1..10) {
  is(App::ArduinoBuilder::FilePath::_pick_highest_version_string(shuffle(qw(1.2 1.20 1.2.1 1.15))), '1.20');
  is(App::ArduinoBuilder::FilePath::_pick_highest_version_string(shuffle(qw(1.2 1.2.1 1.15))), '1.15');
  is(App::ArduinoBuilder::FilePath::_pick_highest_version_string(shuffle(qw(1.2 1.2.1))), '1.2.1');
  is(App::ArduinoBuilder::FilePath::_pick_highest_version_string(shuffle(qw(1.2))), '1.2');
}

my $dir_with_versions = "${FindBin::Bin}/data/dir_with_versions";
my $dir_without_versions = "${FindBin::Bin}/data/dir_without_versions";
is (App::ArduinoBuilder::FilePath::find_latest_revision_dir($dir_with_versions), catdir($dir_with_versions, '1.20'));
is (App::ArduinoBuilder::FilePath::find_latest_revision_dir($dir_without_versions), $dir_without_versions);

done_testing;
