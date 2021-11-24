use 5.010;      # v5.8 equired for in-memory files; v5.10 required for named backreferences and // in the commented-note() calls
use strict;
use warnings;
use Test::More;

use version 0.77;
use FindBin;
use lib "$FindBin::Bin/unpatched";
use CAD::Mesh3D::STL;


my $exp = version::->parse( v0.2.1 );
my $got = version::->parse($CAD::Format::STL::VERSION);
is $got, $exp, 'CAD::Format::STL needs-patching Version from ' . $INC{'CAD/Format/STL.pm'} . ":$exp";
is my $FORMATTER = $CAD::Mesh3D::STL::STL_FORMATTER, 'CAD::Mesh3D::FormatSTL', 'Verify CAD::Mesh3D::STL chose STL_FORMATTER = CAD::Mesh3D::FormatSTL';
my $FORMATTER_KEY = $FORMATTER;
for($FORMATTER_KEY) { s{::}{/}g; s{$}{.pm}; }

sub hex2float { unpack 'f>' => pack 'H*' => shift }
my $fcr   = hex2float('3F810D00');
my $flf   = hex2float('3F820A00');
my $fcrlf = hex2float('3F830D0A');
my $flfcr = hex2float('3F840A0D');

{
    my $v = $FORMATTER->VERSION;
    my $p = $INC{$FORMATTER_KEY} // '<INC error>';
    ok($v, "using $FORMATTER $v from '$p'");
}

my $stl = $FORMATTER->new;
isa_ok($stl, $FORMATTER);

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

  $stl = $FORMATTER->new();   # need a new object.
  $stl->load(binary => $file);
  my $expect = [[0,0,0], @$expected_points];    # normal, tri1, tri2, tri3
  my $face = (($stl->parts)[0]->facets)[0];
  my $fail_read;
  is_deeply( $face, $expect, $FORMATTER . ' _read_binary() bug check: correct triangle coordinates') or ++$fail_read;
  if($fail_read) {
    diag "\tDETAILS:";
    foreach my $i ( 0 .. $#$face ) {
      my $tri = $face->[$i];
      diag sprintf "\t\t\$got->[%d] = [%.16f, %.16f, %.16f]", $i, @$tri;
    }
  };
  unlink $file if -e $file;

  if($fail_write or $fail_read) {
      diag "Looks like $FORMATTER ", $FORMATTER->VERSION, " is not patched";
      diag "To patch,";
      diag "\tfind '", $INC{'CAD/Format/STL.pm'}, "'";
      diag "\tand add 'binmode \$fh' to _write_binary() and _read_binary()\n\tright after argument processing in each";
  }
}

done_testing();

# vim:ts=2:sw=2:et:sta
