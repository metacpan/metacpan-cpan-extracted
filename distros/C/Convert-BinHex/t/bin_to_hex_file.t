use strict;
use warnings;

use autodie;

use Test::Most;
use FindBin '$Bin';
use File::Temp;
use File::Compare;

use Convert::BinHex;

my $source_file = "$Bin/../testin/eyeball.gif";
my $comparison = "$Bin/../testin/eyeball.gif.hqx";
#my $comparison = "$Bin/../testin/hands_m.eps.hqx";


my $hqx = Convert::BinHex->new();
$hqx->filename('eyeball.gif');
$hqx->type('????');
$hqx->creator('????');
$hqx->data( Path => $source_file );
$hqx->resource( Data => '' );

my $tmp_fh = File::Temp->new();
$hqx->encode($tmp_fh);
$tmp_fh->flush();
$tmp_fh->seek(0,0);

ok( compare( $tmp_fh, $comparison) == 0, "File is binary correct");

done_testing();