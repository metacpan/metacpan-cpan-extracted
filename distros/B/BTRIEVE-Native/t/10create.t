#!perl -I./t

use strict;
use warnings;
use Test::More tests => 2;
use My_Test();
BEGIN { use_ok 'BTRIEVE::Native' }

my $B = \&BTRIEVE::Native::Call;

my $p = "\0" x 128;
my $d = pack 'SSSx4SCxS'  , @{$My_Test::Spec->{File}};
   $d.= pack 'SSSx4CCx2CC', @{$My_Test::Spec->{Key}};
my $l = 16 + 1 * 16;
my $k = $My_Test::File;

is $B->( 14, $p, $d, $l, $k, 0 ), 0,'create';
