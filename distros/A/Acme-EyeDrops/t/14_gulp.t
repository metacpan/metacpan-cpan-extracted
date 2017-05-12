#!/usr/bin/perl
# 14_gulp.t
# Test new SourceHandle attribute and invalid attributes (new with A::E v1.44).

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

$|=1;

# ----------------------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# ----------------------------------------------------------------

print "1..38\n";

my $helloteststr = <<'HELLOTEST';
# Just a test.
use strict;
for my $i (0..3) {
   print "hello test $i\n";
}
HELLOTEST
my $hellotestfile = 'hellotest.pl';
my $zerotestfile = '0';
my $yanick4str = get_eye_string('yanick4');
my $tmpf = 'bill.tmp';

build_file($hellotestfile, $helloteststr);
build_file($zerotestfile, $helloteststr);

# ----------------------------------------------------------------

my $itest = 0;
my $prog;

sub test_one {
   my ($e, $ostr, $sh) = @_;
   build_file($tmpf, $prog);
   my $outstr = `$^X -Tw -Mstrict $tmpf`;
   my $rc = $? >> 8;
   $rc == 0 or print "not ";
   ++$itest; print "ok $itest - $e rc\n";
   $outstr eq $ostr or print "not ";
   ++$itest; print "ok $itest - $e output\n";
   $prog =~ tr/!-~/#/;
   $prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
   $prog eq $sh or print "not ";
   ++$itest; print "ok $itest - $e shape\n";
}

sub skip_one {
   my $e = shift;
   ++$itest; print "ok $itest # skip $e, rc\n";
   ++$itest; print "ok $itest # skip $e, output\n";
   ++$itest; print "ok $itest # skip $e, shape\n";
}

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => $helloteststr,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('hellotest SourceString',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

$prog = sightly({ Shape         => 'yanick4',
                  SourceFile    => $hellotestfile,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('hellotest SourceFile string',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

# For different ways to pass a handle, see Perl Cookbook, 2nd edition,
# Recipe 7.5:
#  1) *FH            typeglob
#  2) \*FH           ref to typeglob
#  3) *FH{IO}        I/O object

open(FH, $hellotestfile) or die "error: open '$hellotestfile': $!";
$prog = sightly({ Shape         => 'yanick4',
                  SourceHandle  => *FH,
                  InformHandler => sub {},
                  Regex         => 1 } );
close(FH) or die "error: close '$hellotestfile': $!";
test_one('hellotest SourceHandle typeglob',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

open(FH, $hellotestfile) or die "error: open '$hellotestfile': $!";
$prog = sightly({ Shape         => 'yanick4',
                  SourceHandle  => \*FH,
                  InformHandler => sub {},
                  Regex         => 1 } );
close(FH) or die "error: close '$hellotestfile': $!";
test_one('hellotest SourceHandle typeglob ref',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

open(FH, $hellotestfile) or die "error: open '$hellotestfile': $!";
$prog = sightly({ Shape         => 'yanick4',
                  SourceHandle  => *FH{IO},
                  InformHandler => sub {},
                  Regex         => 1 } );
close(FH) or die "error: close '$hellotestfile': $!";
test_one('hellotest SourceHandle I/O object',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

require IO::File;
my $fh = IO::File->new();
$fh->open($hellotestfile) or die "error: open '$hellotestfile': $!";
$prog = sightly({ Shape         => 'yanick4',
                  SourceHandle  => $fh,
                  InformHandler => sub {},
                  Regex         => 1 } );
$fh->close() or die "error: close '$hellotestfile': $!";
test_one('hellotest SourceHandle IO::File',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

if ($] < 5.006) {
   skip_one("hellotest SourceHandle autovivify, perl version less than 5.006");
} else {
   open(my $fh, $hellotestfile) or die "error: open '$hellotestfile': $!";
   $prog = sightly({ Shape         => 'yanick4',
                     SourceHandle  => $fh,
                     InformHandler => sub {},
                     Regex         => 1 } );
   close($fh) or die "error: close '$hellotestfile': $!";
   test_one('hellotest SourceHandle autovivify',
      "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
      $yanick4str x 3);
}

$prog = sightly({ Shape         => 'yanick4',
                  SourceFile    => $zerotestfile,
                  InformHandler => sub {},
                  Regex         => 1 } );
test_one('hellotest zero SourceFile string',
   "hello test 0\nhello test 1\nhello test 2\nhello test 3\n",
   $yanick4str x 3);

# ----------------------------------------------------------------

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => '0',
                  InformHandler => sub {},
                  Print         => 1,
                  Regex         => 1 } );
test_one('0 SourceString', '0', $yanick4str);

$prog = sightly({ Shape         => 'yanick4',
                  SourceString  => '1',
                  InformHandler => sub {},
                  Print         => 1,
                  Regex         => 1 } );
test_one('1 SourceString', '1', $yanick4str);

# ----------------------------------------------------------------

eval { sightly( { Shape  => 'InvalidShape' } ) };
$@ =~ /InvalidShape/ or print "not ";
++$itest; print "ok $itest - InvalidShape\n";

eval { sightly( { InvalidAttr => 1 } ) };
$@ =~ /invalid parameter 'InvalidAttr'/ or print "not ";
++$itest; print "ok $itest - InvalidAttr\n";

eval {
   sightly({ Shape         => 'yanick4',
             SourceFile    => $hellotestfile,
             SourceHandle  => 1 } );
};
$@ =~ /SourceHandle/ or print "not ";
++$itest; print "ok $itest - InvalidAttrs SourceFile/SourceHandle\n";

eval {
   sightly({ Shape         => 'yanick4',
             SourceFile    => $hellotestfile,
             SourceString  => $helloteststr } );
};
$@ =~ /SourceFile/ or print "not ";
++$itest; print "ok $itest - InvalidAttrs SourceFile/SourceString\n";

eval {
   sightly({ Shape         => 'yanick4',
             SourceHandle  => 1,
             SourceString  => $helloteststr } );
};
$@ =~ /SourceString/ or print "not ";
++$itest; print "ok $itest - InvalidAttrs SourceString/SourceHandle\n";

eval {
   sightly({ Shape         => 'yanick4',
             ShapeString   => '#####' x 42,
             SourceString  => $helloteststr } );
};
$@ =~ /ShapeString/ or print "not ";
++$itest; print "ok $itest - InvalidAttrs Shape/ShapeString\n";

eval {
   sightly({ Width         => 3,
             SourceString  => $helloteststr } );
};
$@ =~ /invalid width/ or print "not ";
++$itest; print "ok $itest - Invalid Width\n";

# ----------------------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";
unlink($hellotestfile) or die "error: unlink '$hellotestfile': $!";
unlink($zerotestfile) or die "error: unlink '$zerotestfile': $!";

# ----------------------------------------------------------------
# Test for file that does not exist.

eval {
   sightly({ Shape         => 'yanick4',
             SourceFile    => $hellotestfile,
             InformHandler => sub {},
             Regex         => 1 } );
};
$@ =~ /'\Q$hellotestfile\E':/ or print "not ";
++$itest; print "ok $itest - Invalid SourceFile, file not found\n";

# ----------------------------------------------------------------
