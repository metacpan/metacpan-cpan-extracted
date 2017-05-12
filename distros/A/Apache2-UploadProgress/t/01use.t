#!perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

$ENV{UPLOADPROGRESS_SHARE_FILE} = 't/logs/cache_file';

use_ok('Apache2::UploadProgress');
