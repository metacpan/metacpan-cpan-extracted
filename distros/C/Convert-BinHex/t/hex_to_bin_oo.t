use strict;
use warnings;

use Test::Most;
use FindBin '$Bin';
use File::Slurp;
use autodie;

my $binhex_file = "$Bin/../testin/eyeball.gif.hqx";
my $orig_file = "$Bin/../testin/eyeball.gif";

use Convert::BinHex;

# Test hex to bin, OO interface

open( my $in_fh, $binhex_file);

my $hqx = Convert::BinHex->open( FH => $in_fh );
$hqx->read_header();
my @data = $hqx->read_data();
my @rsrc = $hqx->read_resource();

my $orig_data = read_file( $orig_file, { 'binmode' => ':raw' });

eq_or_diff(join('', @data), $orig_data, 'data fork matches original');
is_deeply(\@rsrc, [], 'resource fork is empty');

is($hqx->filename(), 'eyeball.gif', 'filename is correct');
is($hqx->type(), '????', 'type is correct');
is($hqx->creator(), '????', 'creator is correct');

done_testing();
