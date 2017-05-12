#!perl -I./t

use strict;
use warnings;
use Test::More tests => 6;
use My_Test();
BEGIN { use_ok 'BTRIEVE::FileIO' }

my $B = BTRIEVE::FileIO->Open( $My_Test::File );
is $B->{Status}, 0,'Open';

$B->{Size} = $My_Test::Length;

for my $a ( @$My_Test::Data )
{
  $B->Insert( pack $My_Test::Mask, @$a );
  is $B->{Status}, 0,"Insert @$a";
}
$B->Insert( pack $My_Test::Mask, @{$My_Test::Data->[0]} );
is $B->{Status}, 5,"Insert @{$My_Test::Data->[0]} (dup)";
