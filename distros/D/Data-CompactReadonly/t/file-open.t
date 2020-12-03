use strict;
use warnings;

use Test::More;
use Test::Exception;

use File::Temp qw(tempfile);
use String::Binary::Interpolation;
use Fcntl qw(:seek);

use Data::CompactReadonly;

my $header_bytes = "CROD\x00";

my $byte_at_root = "$header_bytes${b11000000}A"; # 65
(undef, my $filename) = tempfile(UNLINK => 1);
open(my $fh, '>', $filename) || die("Can't write $filename: $!\n");
print $fh $byte_at_root;
close($fh);

is(Data::CompactReadonly->read($filename), 65, "can read a Byte from root node when given a filename");

open($fh, '<:unix', $filename) || die("Can't read $filename: $!\n");
is(Data::CompactReadonly->read($fh), 65, "can read from file handle");
close($fh);

open($fh, '<', \$byte_at_root) || die("Can't read from reference: $!\n");;
is(Data::CompactReadonly->read($fh), 65, "can read from in-memory file handle");
seek($fh, 0, SEEK_SET);
is(Data::CompactReadonly->read($fh), 65, "can re-read from in-memory file handle after seeking back to beginning");
close($fh);

open($fh, '<:utf8', $filename) || die("Can'tread $filename: $!\n");
throws_ok
    { Data::CompactReadonly->read($fh) }
    qr/invalid encoding/,
    "refuse to play with a file not opened as bytes (:utf8)";
close($fh);

open($fh, '<:encoding(UTF-8)', $filename) || die("Can'tread $filename: $!\n");
throws_ok
    { Data::CompactReadonly->read($fh) }
    qr/invalid encoding/,
    "refuse to play with a file not opened as bytes (:encoding(UTF-8))";
close($fh);

throws_ok
    { Data::CompactReadonly->read('i-dont-exist') }
    qr/couldn't open file/,
    "can't open file";

open($fh, '<', \'CROD');
throws_ok
    { Data::CompactReadonly->read($fh) }
    qr/header invalid: doesn't match .CROD../,
    "refuse to play with a file with a dodgy header";
close($fh);

open($fh, '<', \"CROD\xff");
throws_ok
    { Data::CompactReadonly->read($fh) }
    qr/header invalid: bad version/,
    "version number too high";
close($fh);

done_testing;
