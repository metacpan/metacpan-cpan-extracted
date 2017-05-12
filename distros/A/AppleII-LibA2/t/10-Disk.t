# Before `./Build install' is performed this script should be runnable with
# `./Build test'. After `./Build install' it should work as `perl 10_Disk.t'
#---------------------------------------------------------------------
# 10_Disk.t
# Copyright 2006 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the AppleII::Disk module
#---------------------------------------------------------------------

use FindBin;

use Test::More tests => 36;
BEGIN { use_ok('AppleII::Disk') };

use bytes;

#---------------------------------------------------------------------

my $dir = "$FindBin::Bin/tmpdir";
mkdir $dir;
chdir $dir or die "Can't cd $dir: $!";

my $dfn = "test.DO";
my $pfn = "test.PO";

foreach ($dfn, $pfn) {
  unlink $_ or die "Can't unlink $_: $!" if -e $_;
}

#---------------------------------------------------------------------
# Create a new DOS 3.3-order image and test it:

my $d = AppleII::Disk->new($dfn, 'drw');
isa_ok($d, 'AppleII::Disk',        '$d');
isa_ok($d, 'AppleII::Disk::DOS33', '$d');

$d->blocks(280);                # 140KB floppy
is($d->blocks, 280, "$dfn is 280 blocks");

is($d->read_block(42), "\0" x 512, "block 42 is empty");

eval { $d->read_block(280) };
like($@, qr/Invalid (?:block|position)/, "Caught reading block out-of-range");

eval { $d->write_block(279, "A" x 256, "B") };
is($@, '', "Wrote block 279");

is($d->{actlen}, 0x23000, "$dfn is now 140KB"); # WARNING: internal data

is($d->read_sector(34,  1), "A" x 256, "Read 34/01");

is($d->read_sector(34, 15), "B" x 256, "Read 34/15");

# Fill in data for the ProDOS-order tests:
eval { $d->write_sector(34, 14, "C" x 256) };
is($@, '', "Wrote 34/14");

eval { $d->write_sector(34,  0, '', "D") };
is($@, '', "Wrote 34/00");

eval { $d->write_sector(34,  0, '', "D") };
is($@, '', "Wrote 34/00");

eval { $d->write_sector( 0,  0, 'HI' x 128) };
is($@, '', "Wrote 00/00");

is($d->read_block(0), ('HI' x 128) . ("\0" x 256), "Read block 0");

undef $d;

#---------------------------------------------------------------------
# Open the same image, but treat it as ProDOS-order:

my $pd = AppleII::Disk->new($dfn, 'prw');
isa_ok($pd, 'AppleII::Disk',         '$pd');
isa_ok($pd, 'AppleII::Disk::ProDOS', '$pd');

is($pd->blocks, 280, "$dfn is still 280 blocks");

is($pd->read_block(42), "\0" x 512, "block 42 is still empty");

eval { $pd->read_block(280) };
like($@, qr/Invalid (?:block|position)/, "Caught reading block out-of-range");

is($pd->{actlen}, 0x23000, "$dfn is still 140KB"); # WARNING: internal data

is($pd->read_block(279), ("C" x 256) . ("B" x 256), "Read block 279");

is($pd->read_block(272), ("D" x 256) . ("A" x 256), "Read block 272");

is($pd->read_blocks([279, 0, 272]),
   ("C" x 256) . ("B" x 256) . ("\0" x 512) . ("D" x 256) . ("A" x 256),
   "Read blocks 279, NULL, 272");

# write_blocks shouldn't alter block 0:
eval { $pd->write_blocks([279, 0, 272], 'F' x 0x600) };
is($@, '', 'Wrote blocks 279, 0, 272');

is($pd->read_block(279), ("F" x 512), "Read block 279 again");

is($pd->read_block(272), ("F" x 512), "Read block 272 again");

is($pd->read_block(0), ('HI' x 128) . ("\0" x 256), "Read block 0 again");

undef $pd;

#---------------------------------------------------------------------
# Create a new ProDOS-order image and test it:

my $np = AppleII::Disk->new($pfn, 'prw');
isa_ok($np, 'AppleII::Disk',         '$np');
isa_ok($np, 'AppleII::Disk::ProDOS', '$np');

$np->blocks(280);                # 140KB floppy
is($np->blocks, 280, "$pfn is 280 blocks");

eval { $np->write_block(279, "A" x 256) };
like($@, qr/Data block is 256 bytes/, "Caught writing short block");

is($np->read_block(279), "\0" x 512, "Block 279 still empty");

eval { $np->write_block(279, "A" x 256, "B") };
is($@, '', "Wrote block 279 to $pfn");

is($np->read_block(279), ("A" x 256) . ("B" x 256), "Read block 279");

is($np->{actlen}, 0x23000, "$pfn is now 140KB"); # WARNING: internal data

undef $np;

#---------------------------------------------------------------------
# Local Variables:
# mode: perl
# End:
