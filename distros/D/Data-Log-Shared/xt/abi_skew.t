use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Log::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.log');
close $fh;

{
    my $l = Data::Log::Shared->new($path, 4096);
    undef $l;
}

open(my $w, '+<', $path) or die;
binmode $w;
seek($w, 4, 0);
print $w pack('V', 99);
close $w;

my $r = eval { Data::Log::Shared->new($path, 4096) };
ok !$r, "version-mismatched log rejected";
like $@ || '', qr/invalid|version|incompatible/i, "meaningful error";

open(my $w2, '+<', $path) or die;
binmode $w2;
seek($w2, 0, 0);
print $w2 pack('V', 0x12345678);
close $w2;

my $r2 = eval { Data::Log::Shared->new($path, 4096) };
ok !$r2, "magic-mismatched log rejected";

done_testing;
