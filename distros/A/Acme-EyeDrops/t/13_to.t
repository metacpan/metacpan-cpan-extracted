#!/usr/bin/perl
# 13_to.t
# Tests _make_filler(), get_eye_dir(), slurp_yerself()
# get_eye_properties(), get_eye_keywords(), find_eye_shapes()

use strict;
use Acme::EyeDrops qw(get_eye_dir
                      get_eye_shapes
                      get_eye_properties
                      get_eye_keywords
                      find_eye_shapes);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

my $tmpf = 'bill.tmp';

# --------------------------------------------------
# A valid property file should:
#  1) contain no "weird" chars.
#  2) no line should contain trailing spaces
#  3) be properly newline-terminated
#  4) contain no leading newlines
#  5) contain no trailing newlines
# test_one_propchars() below verifies that is
# the case for all .eyp shapes.
#  6) contain only valid properties
# Tested by get_prop_names()
#  7) contain only valid keywords
# Tested near the end via get_eye_keywords().
# --------------------------------------------------

my @eye_shapes = get_eye_shapes();
my $n_tests = @eye_shapes * 6;
$n_tests += 101;   # plus other tests

print "1..$n_tests\n";

# --------------------------------------------------

my $itest = 0;

# --------------------------------------------------

# Test _make_filler()
{
   my $fillv = '#';
   # This line is used in A::E pour_sightly().
   # Note: 11 is the length of, for example, $:='.'^'~';
   # Multiple of 6 because each filler contains 6 tokens:
   #   $:  =  '.'  ^  '~'  ;
   # Also, no single quoted string should contain " or ;
   # Oh, and $; variable is banned.
   # XXX: add tests for all these later.
   my @filler = Acme::EyeDrops::_make_filler(
                   ref($fillv) ? $fillv : [ '$:', '$~', '$^' ]);
   my $nfiller = @filler;
   $nfiller == 72 or print "not ";
   ++$itest; print "ok $itest - _make_filler 72 items (got $nfiller)\n";
   $nfiller % 6 == 0 or print "not ";
   ++$itest; print "ok $itest - _make_filler multiple of 6 (got $nfiller)\n";

   @filler = Acme::EyeDrops::_make_filler([ '$:', '$~', '$^', '$:', '$~' ]);
   $nfiller = @filler;
   $nfiller == 60 or print "not ";
   ++$itest; print "ok $itest - _make_filler 60 items (got $nfiller)\n";
   $nfiller % 6 == 0 or print "not ";
   ++$itest; print "ok $itest - _make_filler multiple of 6 (got $nfiller)\n";

   my $badfiller = [ '$:', '$~', '$^',
                     '$:', '$~', '$^',
                     '$:', '$~', '$^',
                     '$:', '$~', '$^',
                     '$:' ];
   eval { Acme::EyeDrops::_make_filler($badfiller) };
   $@ or print "not ";
   ++$itest; print "ok $itest - _make_filler, too many filler vars\n";
}

# -----------------------------------------------------------------------

sub test_one_propchars {
   my ($e, $s) = @_;
   $s =~ tr K-_:$@*&!%.;"'`()[]{},/\\ a-zA-Z0-9\nKKc and print "not ";
   ++$itest; print "ok $itest - $e valid chars\n";
   $s =~ / +$/m and print "not ";
   ++$itest; print "ok $itest - $e trailing spaces\n";
   substr($s, 0, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e leading blank lines\n";
   substr($s, -1, 1) eq "\n" or print "not ";
   ++$itest; print "ok $itest - $e trailing blank lines\n";
   substr($s, -2, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e properly newline terminated\n";
}

sub test_one_get_properties {
   my ($e, $pstr, $hexp) = @_;
   build_file($tmpf, $pstr);
   my $h = Acme::EyeDrops::_get_properties($tmpf);
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - _get_properties 1 $e\n";
   my @a = sort keys %$h; my @aexp = sort keys %$hexp;
   scalar(@a) == scalar(@aexp) or print "not ";
   ++$itest; print "ok $itest - _get_properties 2 $e\n";
   return unless @aexp;
   my $min = @a; $min = @aexp if @aexp < $min;
   for my $i (0 .. $min-1) {
      $a[$i] eq $aexp[$i] or print "not ";
      ++$itest; print "ok $itest - _get_properties 3 $e\n";
      $h->{$a[$i]} eq $hexp->{$aexp[$i]} or print "not ";
      ++$itest; print "ok $itest - _get_properties 4 $e\n";
   }
}

sub test_one_find_eye_shapes {
   my ($e, $s, $sexp) = @_;
   my @shapes = find_eye_shapes(@$s);
   scalar(@shapes) == scalar(@$sexp) or print "not ";
   ++$itest; print "ok $itest - find_eye_shapes 1 $e\n";
   return unless @$sexp;
   my $min = @shapes; $min = @$sexp if @$sexp < $min;
   for my $i (0 .. $min-1) {
      $shapes[$i] eq $sexp->[$i] or print "not ";
      ++$itest; print "ok $itest - find_eye_shapes 2 $e\n";
   }
}

sub test_one__find_eye_shapes {
   my ($e, $s, $sexp) = @_;
   my @shapes = Acme::EyeDrops::_find_eye_shapes('.', @$s);
   scalar(@shapes) == scalar(@$sexp) or print "not ";
   ++$itest; print "ok $itest - _find_eye_shapes 1 $e\n";
   return unless @$sexp;
   my $min = @shapes; $min = @$sexp if @$sexp < $min;
   for my $i (0 .. $min-1) {
      $shapes[$i] eq $sexp->[$i] or print "not ";
      ++$itest; print "ok $itest - _find_eye_shapes 2 $e\n";
   }
}

sub get_prop_names {
   my %h;
   for my $s (get_eye_shapes()) {
      my $p = get_eye_properties($s) or next;  # no properties
      my @k = keys(%{$p}) or next;
      for my $k (@k) { push(@{$h{$k}}, $s) }
   }
   return \%h;
}

# Hacked from _get_eye_shapes().
sub _get_eyp_shapes {
   my $d = shift; local *D;
   opendir(D, $d) or die "opendir '$d': $!";
   my @e = sort map(/(.+)\.eyp$/, readdir(D)); closedir(D); @e;
}

# -----------------------------------------------------------------------
# slurp_yerself() tests (primitive)

my $eyedrops_pm = Acme::EyeDrops::slurp_yerself();
my $elen = length($eyedrops_pm);
$elen > 50000 or print "not ";
++$itest; print "ok $itest - slurp_yerself length is $elen\n";
my $nlines = $eyedrops_pm =~ tr/\n//;
$nlines > 1000 or print "not ";
++$itest; print "ok $itest - slurp_yerself line count is $nlines\n";

# XXX: could add MD5 checksum test here.
# XXX: beware above test is fragile when testing auto-generated EyeDrops.pm
#      (as is done by 19_surrounds.t)

# -----------------------------------------------------------------------
# get_eye_dir() tests.

my $eyedir = get_eye_dir();
$eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir sane\n";
-d $eyedir or print "not ";
++$itest; print "ok $itest - get_eye_dir dir\n";
-f "$eyedir/camel.eye" or print "not ";
++$itest; print "ok $itest - get_eye_dir camel.eye\n";
# v1.50 added eye property (.eyp) files.
-f "$eyedir/camel.eyp" or print "not ";
++$itest; print "ok $itest - get_eye_dir camel.eyp\n";

# -----------------------------------------------------------------------
# Sanity check on all properties files.

{
   # Check that .eye files and .eyp files match.
   my @eyp_shapes = _get_eyp_shapes($eyedir);
   # print STDERR "# There are: " . scalar(@eyp_shapes) . " property files\n";
   scalar(@eye_shapes) == scalar(@eyp_shapes) or print "not ";
   ++$itest; print "ok $itest - num .eyp matches num .eye\n";
   for my $i (0 .. $#eye_shapes) {
      $eye_shapes[$i] eq $eyp_shapes[$i] or print "not ";
      ++$itest; print "ok $itest - '$eye_shapes[$i]' .eye matches .eyp\n";
   }
}

for my $e (@eye_shapes) {
   test_one_propchars($e,
      Acme::EyeDrops::_slurp_tfile($eyedir . '/' . $e . '.eyp'));
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_prop_names();
   # for my $k (sort keys %{$h}) { print "k='$k' v='@{$h->{$k}}'\n" }
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - valid props, hash ref\n";
   my @skey = sort keys %{$h};
   my $nskey = @skey;
   print STDERR "# properties: @skey\n";
   $nskey == 6 or print "not ";
   ++$itest; print "ok $itest - valid props, number should be $nskey\n";
   for my $k ('author',
              'authorcpanid',
              'description',
              'keywords',
              'nick',
              'source') {
      shift(@skey) eq $k or print "not ";
      ++$itest; print "ok $itest - valid props, '$k'\n";
   }
}

# -----------------------------------------------------------------------
# _get_properties() tests.

test_one_get_properties(
   'empty file',
   "",
   {}
);
test_one_get_properties(
   'simple file',
   "tang:autrijus\n",
   { 'tang' => 'autrijus' }
);
test_one_get_properties(
   'comment file',
   "  # comment\n \ttang \t :\t autrijus",
   { 'tang' => 'autrijus' }
);

test_one_get_properties(
   'extendo file',
   "wall:larry  \\\n \t not wall russ\n",
   { 'wall' => 'larry  not wall russ' }
);

test_one_get_properties(
   'two keys file',
   " wall:larry\\\nnot wall russ\n\tConway: The  Damian \t\n",
   { 'wall'   => 'larrynot wall russ',
     'Conway' => 'The  Damian' }
);

# -----------------------------------------------------------------------
# get_eye_properties() tests.

{
   my $tmpeyp = 'tmpeye.eyp';
   -f $tmpeyp and (unlink($tmpeyp) or die "error unlink '$tmpeyp': $!");
   my $h = Acme::EyeDrops::_get_eye_properties('.', 'tmpeye');
   defined($h) and print "not ";
   ++$itest; print "ok $itest - get_eye_properties, no props\n";
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_eye_properties('camel');
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 1\n";
   keys(%$h) == 2 or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 2\n";
   $h->{'keywords'} eq 'animal' or print "not ";
   ++$itest; print "ok $itest - get_eye_properties, camel 3\n";
}

# -----------------------------------------------------------------------
# find_eye_shapes() tests.

eval { find_eye_shapes() };
$@ or print "not ";
++$itest; print "ok $itest - find_eye_shapes, no params\n";

# XXX: need to update test when update shape properties.
test_one_find_eye_shapes(
   'one',
   [ 'flag' ],
   [ 'flag_canada' ]
);
# XXX: need to update test when update shape properties.
test_one_find_eye_shapes(
   'dup keyword',
   [ 'flag', 'flag' ],
   [ 'flag_canada' ]
);
# XXX: need to update test when update shape properties.
# This is the example from the doco that cog specifically asked for.
test_one_find_eye_shapes(
   'cog',
   [ 'face', 'person', 'perlhacker' ],
   [ 'acme',
     'adrianh',
     'autrijus',
     'damian',
     'dan',
     'eugene',
     'gelly',
     'larry',
     'larry2',
     'merlyn',
     'schwern2',
     'simon',
     'yanick' ]
);
# XXX: need to update test when update shape properties.
test_one_find_eye_shapes(
   'OR',
   [ 'flag OR sport' ],
   [ 'cricket',
     'flag_canada',
     'golfer' ]
);

{
   my $tmpeye  = 'tmpeye.eye';
   my $tmpeyp  = 'tmpeye.eyp';
   my $tmpeye2 = 'tmpeye2.eye';
   my $tmpeyp2 = 'tmpeye2.eyp';
   my $tmpeye3 = 'tmpeye3.eye';
   my $tmpeyp3 = 'tmpeye3.eyp';
   my $tmpeye4 = 'tmpeye4.eye';
   my $tmpeyp4 = 'tmpeye4.eyp';
   my $tmpeye5 = 'tmpeye5.eye';
   my $tmpeyp5 = 'tmpeye5.eyp';
   my $tmpeye6 = 'tmpeye6.eye';
   my $tmpeyp6 = 'tmpeye6.eyp';
   my $tmpeye7 = 'tmpeye7.eye';  # Test .eye file with no .eyp file
   build_file($tmpeye, "");  build_file($tmpeye2, "");
   build_file($tmpeye3, ""); build_file($tmpeye4, "");
   build_file($tmpeye5, ""); build_file($tmpeye6, "");
   build_file($tmpeye7, "");
   build_file($tmpeyp, <<'FLAMING_OSTRICHES');
keywords : pink cat
FLAMING_OSTRICHES
   build_file($tmpeyp2, <<'FLAMING_OSTRICHES');
keywords : dog orange
FLAMING_OSTRICHES
   build_file($tmpeyp3, <<'FLAMING_OSTRICHES');
keywords : dog apple
FLAMING_OSTRICHES
   build_file($tmpeyp4, <<'FLAMING_OSTRICHES');
keywords : dog big
FLAMING_OSTRICHES
   build_file($tmpeyp5, <<'FLAMING_OSTRICHES');
# Test a comment line, blank lines and empty keywords.

 
\t
 \t 
keywords : 
# final comment line
FLAMING_OSTRICHES
   build_file($tmpeyp6, <<'FLAMING_OSTRICHES');
# Test no keywords
FLAMING_OSTRICHES
   my @catdog = Acme::EyeDrops::_find_eye_shapes('.', 'cat', 'dog');
   @catdog == 0 or print "not ";
   ++$itest; print "ok $itest - _find_eye_shapes, no cats or dogs\n";

   test_one__find_eye_shapes(
      'OR',
      [ 'pink OR big' ],
      [ 'tmpeye',
        'tmpeye4' ]
   );
   test_one__find_eye_shapes(
      'AND OR',
      [ 'dog', 'apple OR orange' ],
      [ 'tmpeye2',
        'tmpeye3' ]
   );

   # Test some _get_eye_keywords...
   {
      my $h = Acme::EyeDrops::_get_eye_keywords('.');
      # for my $k (sort keys %{$h}) { print "k='$k' v='@{$h->{$k}}'\n" }
      ref($h) eq 'HASH' or print "not ";
      ++$itest; print "ok $itest - get_eye_keywords, hash ref\n";
      my @skey = sort keys %{$h};
      @skey == 6 or print "not ";
      ++$itest; print "ok $itest - get_eye_keywords, number\n";
      for my $k ('apple',
                 'big',
                 'cat',
                 'dog',
                 'orange',
                 'pink') {
         shift(@skey) eq $k or print "not ";
         ++$itest; print "ok $itest - get_eye_keywords, '$k'\n";
      }
   }

   unlink($tmpeye, $tmpeyp, $tmpeye2, $tmpeyp2, $tmpeye3, $tmpeyp3,
          $tmpeye4, $tmpeyp4, $tmpeye5, $tmpeyp5, $tmpeye6, $tmpeyp6,
          $tmpeye7);
}

{
   # XXX: need to update test when update shape properties.
   my $h = get_eye_keywords();
   # for my $k (sort keys %{$h}) { print "k='$k' v='@{$h->{$k}}'\n" }
   ref($h) eq 'HASH' or print "not ";
   ++$itest; print "ok $itest - get_eye_keywords, hash ref\n";
   my @skey = sort keys %{$h};
   @skey == 15 or print "not ";
   ++$itest; print "ok $itest - get_eye_keywords, number\n";
   for my $k ('animal',
              'debian',
              'face',
              'flag',
              'hbanner',
              'logo',
              'map',
              'object',
              'opera',
              'perlhacker',
              'person',
              'planet',
              'sport',
              'underwear',
              'vbanner') {
      shift(@skey) eq $k or print "not ";
      ++$itest; print "ok $itest - get_eye_keywords, '$k'\n";
   }
}

# -----------------------------------------------------------------------
# Old tests -- function set_eye_dir() has been removed.

# my $mypwd =  Cwd::cwd();
# my $mytesteyedir  =  "$mypwd/eyedir.tmp";
# my $mytesteyefile =  "$mytesteyedir/tmp.eye";
# -d $mytesteyedir or (mkdir($mytesteyedir, 0777) or die "error: mkdir '$mytesteyedir': $!");
# build_file($mytesteyefile, $mytestshapestr);

# set_eye_dir($mytesteyedir);
# get_eye_dir() eq $mytesteyedir or print "not ";
# ++$itest; print "ok $itest - set_eye_dir sane\n";
# my @eyes = get_eye_shapes();
# @eyes==1 or print "not ";
# ++$itest; print "ok $itest - set_eye_dir number\n";
# $eyes[0] eq 'tmp' or print "not ";
# ++$itest; print "ok $itest - set_eye_dir filename\n";
# test_one_shape('tmp', get_eye_string('tmp'));

# This is just a simple example of testing die inside EyeDrops.pm.
# eval { set_eye_dir($mytesteyefile) };
# $@ or print "not ";
# ++$itest; print "ok $itest - set_eye_dir eval die\n";
# $@ eq "error set_eye_dir '" . $mytesteyefile . "': no such directory\n"
#    or print "not ";
# ++$itest; print "ok $itest - set_eye_dir eval die string\n";

# -----------------------------------------------------------------------

# unlink($mytesteyefile) or die "error: unlink '$mytesteyefile': $!";
# rmdir($mytesteyedir) or die "error: rmdir '$mytesteyedir': $!";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

# ----------------------------------------------------------------
# Test for file that does not exist.

eval { Acme::EyeDrops::_get_properties($tmpf) };
$@ =~ /'\Q$tmpf\E':/ or print "not ";
++$itest; print "ok $itest - _get_properties, file not found\n";

eval { Acme::EyeDrops::_get_eye_shapes($tmpf) };
$@ =~ /'\Q$tmpf\E':/ or print "not ";
++$itest; print "ok $itest - _get_eye_shapes, dir not found\n";

# ----------------------------------------------------------------
