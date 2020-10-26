#!/usr/bin/perl
use warnings;
use strict;
use 5.010;      # for pack 'd>', and //

use Test::More;

use CAD::Format::STL;

diag <<"EOH";
CAD::Format::STL: v0.2.1 and earlier had a bug on Windows for reading
or writing binary STL, where
1) if the binary encoding for the float to be written includes 0x0A (LF),
it will be written as 0x0D0A (so an extra byte gets written to convert
LF to make CRLF), which corrupts the binary STL.
2) if the file already has 0x0D0A written, then when the file gets read,
it will be be interpreted as just 0x0A, and will thus be a corrupted

This test determines whether your version of CAD::Format::STL has had
the bug removed and/or has been patched.
EOH

diag "\n";
diag "CAD::Format::STL ", CAD::Format::STL->VERSION(), " from ", $INC{'CAD/Format/STL.pm'};
diag "\n"x2;

note "\n";
note "Floats with 0x0D (CR), 0x0A (LF), or both (CRLF) embedded in the bigendian representation";
sub hex2float { unpack 'f>' => pack 'H*' => shift }
note sprintf '    %-4s => %.16f', 'CR',
my $fcr   = hex2float('3F810D00');
note sprintf '    %-4s => %.16f', 'LF',
my $flf   = hex2float('3F820A00');
note sprintf '    %-4s => %.16f', 'CRLF',
my $fcrlf = hex2float('3F830D0A');
note sprintf '    %-4s => %.16f', 'LFCR',
my $flfcr = hex2float('3F840A0D');
note "\n";

{
    my $v = CAD::Format::STL->VERSION;
    my $p = $INC{'CAD/Format/STL.pm'} // '<INC error>';
    ok($v, "using CAD::Format::STL $v from '$p'");
}

my $stl = CAD::Format::STL->new;
isa_ok($stl, 'CAD::Format::STL');

my $part = $stl->add_part('cube');
isa_ok($part, 'CAD::Format::STL::part');
is($part->name, 'cube', 'part name');

my $expected_points = [[0,0,1], [$fcr,$flf,2], [$fcrlf,$flfcr,3]];
$part->add_facets( $expected_points );
is(scalar($part->facets), 1, 'one triangle');

# establish a valid temporary-file directory
my $tdir;
for my $try ( $ENV{TEMP}, $ENV{TMP}, '/tmp', '.' ) {
    next unless defined $try;
    # diag "before: ", $try;
    $try =~ s{\\}{/}gx if index($try, '\\')>-1 ;        # without the if-index, died with modification of read-only value on /tmp or .
    # diag "after:  ", $try;
    next unless -d $try;
    next unless -w _;
    $tdir = $try;
    last;
}
#diag "final: '", $tdir // '<undef>', "'";
die "could not find a writeable directory" unless defined $tdir && -d $tdir && -w $tdir;

# verify binary bug is fixed
{
  # write binary STL to a temporary file (ie, require file system access, to trigger the bug)
  my $file = $tdir . '/' . 'binout.stl';
  $stl->save(binary => $file);
  is(-s $file, 134, 'CAD::Format::STL _write_binary() bug check: correct output file size');
  my $string = do { open my $fi, '<:raw', $file or die "$file:$!"; local $/; join '', <$fi>; };
  #diag $string;
  my $fail_write;
  is index($string, qq/\x00\x0D\x81\x3F/), 108, 'includes little-endian 0x3F810D00 at right file offset' or ++$fail_write;
  is index($string, qq/\x00\x0A\x82\x3F/), 112, 'includes little-endian 0x3F820A00 at right file offset' or ++$fail_write;
  is index($string, qq/\x0A\x0D\x83\x3F/), 120, 'includes little-endian 0x3F830D0A at right file offset' or ++$fail_write;
  is index($string, qq/\x0D\x0A\x84\x3F/), 124, 'includes little-endian 0x3F840A0D at right file offset' or ++$fail_write;
  diag map { sprintf '%02X ', ord $_} split //, $string if $fail_write;
  unlink $file if -e $file;

  # read binary STL to a temporary file (ie, require file system access, to trigger the bug)
  # actually, start with writing a known-good copy of the file using binmode, so that it will
  # correctly fail even if the _write fails (rather than having the two errors cancel)
  $string = "\x63\x75\x62\x65\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x3F\x00\x0D\x81\x3F\x00\x0A\x82\x3F\x00\x00\x00\x40\x0A\x0D\x83\x3F\x0D\x0A\x84\x3F\x00\x00\x40\x40\x00\x00";
  {
    open my $fh, '>:raw', $file or diag "could not open '$file': $!";
    print {$fh} $string;
    close $fh;
    is(-s $file, 134, 'create known-good test input file');
  };

  $stl = CAD::Format::STL->new();   # need a new object.
  $stl->load(binary => $file);
  my $expect = [[0,0,0], @$expected_points];    # normal, tri1, tri2, tri3
  my $face = (($stl->parts)[0]->facets)[0];
  my $fail_read;
  is_deeply( $face, $expect, 'CAD::Format::STL _read_binary() bug check: correct triangle coordinates') or ++$fail_read;
  if($fail_read) {
    diag "\tDETAILS:";
    foreach my $i ( 0 .. $#$face ) {
      my $tri = $face->[$i];
      diag sprintf "\t\t\$got->[%d] = [%.16f, %.16f, %.16f]", $i, @$tri;
    }
  };
  unlink $file if -e $file;

  if($fail_write or $fail_read) {
      diag "Looks like CAD::Format::STL ", CAD::Format::STL->VERSION, " is not patched";
      diag "To patch,";
      diag "\tfind '", $INC{'CAD/Format/STL.pm'}, "'";
      diag "\tand add 'binmode \$fh' to _write_binary() and _read_binary()\n\tright after argument processing in each";
  }
}

done_testing();

# vim:ts=2:sw=2:et:sta
