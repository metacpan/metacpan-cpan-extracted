package App::MaMGal::Unit::ImageInfo::ExifTool;
use strict;
use warnings;
use Carp 'verbose';
use File::stat;
use Test::More;
use Test::Exception;
use Test::Warn;
BEGIN { our @ISA = 'App::MaMGal::Unit::ImageInfo'; }
BEGIN { do 't/010_unit_imageinfo.t' }
use lib 'testlib';
use App::MaMGal::TestHelper;

use vars '%ENV';
$ENV{MAMGAL_FORCE_IMAGEINFO} = 'App::MaMGal::ImageInfo::ExifTool';
App::MaMGal::Unit::ImageInfo::ExifTool->runtests unless defined caller;

1;
