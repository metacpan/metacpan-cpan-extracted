#!perl -I./t

use strict;
use warnings;
use Test::More tests => 3;
use My_Test();
BEGIN { use_ok 'BTRIEVE::FileIO' }

my $B = BTRIEVE::FileIO->Open( $My_Test::File );
is $B->{Status}, 0,'Open';

$B->{Size} = $My_Test::Length;

for ( $B->StepFirst; $B->IsOk; $B->StepNext )
{
  print '# ', join(':', unpack( $My_Test::Mask, $B->{Data} ) ), "\n";
}
is $B->{Status}, 9,'EOF';
