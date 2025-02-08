#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::CheckManifest' => '0.9' };

Test::CheckManifest->import();
ok_manifest({ filter => [qr/(\.git)|(\..+\.yml$)/] });
