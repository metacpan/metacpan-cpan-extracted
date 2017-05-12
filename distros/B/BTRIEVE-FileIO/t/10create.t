#!perl -I./t

use strict;
use warnings;
use Test::More tests => 2;
use My_Test();
BEGIN { use_ok 'BTRIEVE::FileIO' }

my $FileName = $My_Test::File;
my $FileSpec = { LogicalRecordLength => $My_Test::Length };
my $KeySpecs = [ { KeyLength => $My_Test::KeyLength } ];

my $B = BTRIEVE::FileIO->Create( $FileName, $FileSpec, $KeySpecs );
is $B->{Status}, 0,'Create';
