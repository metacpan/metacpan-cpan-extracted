use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Stack::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.stack');
# STK_MAGIC "STK1" + version=1
my $v1 = pack('V V', 0x53544B31, 1);
$v1 .= "\0" x 1024;
print $fh $v1;
close $fh;

my $obj = eval { Data::Stack::Shared::Int->new($path, 16) };
my $err = $@;
ok !defined($obj), 'v1 file: construction rejected';
like $err, qr/(version|invalid|incompatible)/i, 'error mentions version/invalid';

done_testing;
