#!perl -I./t

use strict;
use warnings;
use Test::More tests => 4;
use My_Test();
BEGIN { use_ok 'BTRIEVE::FileIO' }

my $B = BTRIEVE::FileIO->Open( $My_Test::File );
is $B->{Status}, 0,'Open';

$B->{Size} = $My_Test::Length;

$B->{KeyNum} = 0;
$B->{Key} = $My_Test::FirstKey;

for ( $B->GetEqual; $B->IsOk; $B->GetPrevious )
{
  print '# ', join(':', unpack( $My_Test::Mask, $B->{Data} ) ), "\n";
}
is $B->{Status}, 9,'EOF';

$B->{Key} = $My_Test::FirstKey;
for ( $B->GetGreater; $B->IsOk; $B->GetNext )
{
  print '# ', join(':', unpack( $My_Test::Mask, $B->{Data} ) ), "\n";
}
is $B->{Status}, 9,'EOF';

