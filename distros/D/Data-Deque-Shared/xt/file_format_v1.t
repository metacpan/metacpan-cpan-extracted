use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Deque::Shared;

# Fabricate a v1 file — v2 code must reject cleanly.
# Header layout starts with magic + version (first 8 bytes).

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.deque');
# DEQ_MAGIC "DEQ1" = 0x44455131, version field follows.
# Write bytes matching v1 magic + version=1 + plausible sizes.
# The point is: v2 code must reject "version != 2" without crashing.
my $v1 = pack('V V', 0x44455131, 1);  # magic + v1
# pad to typical header size
$v1 .= "\0" x 1024;
print $fh $v1;
close $fh;

my $obj = eval { Data::Deque::Shared::Int->new($path, 16) };
my $err = $@;
ok !defined($obj), 'v1 file: construction rejected';
like $err, qr/(version|invalid|incompatible)/i, 'error mentions version/invalid';

done_testing;
