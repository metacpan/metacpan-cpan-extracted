# -*- Mode: CPerl -*-
# t/05_setops.t; test set operations

use Test::More tests=>24;
use Algorithm::BinarySearch::Vec ':default';
no warnings 'portable';

my $NOKEY = $KEY_NOT_FOUND;
my $PKG   = 'Algorithm::BinarySearch::Vec';
my $HAVE_QUAD = $Algorithm::BinarySearch::Vec::HAVE_QUAD;

##--------------------------------------------------------------
## utils

## $vec = makevec($nbits,\@vals);
sub makevec {
  my ($nbits,$vals) = @_;
  my $vec   = '';
  vec($vec,$_,$nbits)=$vals->[$_] foreach (0..$#$vals);
  return $vec;
}

## \@l = vec2list($vec,$nbits)
sub vec2list {
  use bytes;
  my ($vec,$nbits) = @_;
  return [map {vec($vec,$_,$nbits)} (0..(length($vec)*8/$nbits-1))];
}

## $str = l2str(\@vlist)
sub l2str {
  return join(' ', @{$_[0]});
}

## $str = v2str($vec,$nbits)
sub v2str {
  return l2str(vec2list(@_));
}

## $str = fstr("$func")
sub fstr {
  (my $func = shift) =~ s/^Algorithm::BinarySearch::Vec:://;
  return $func;
}

##======================================================================
## test: generic

sub check_setop {
  my ($func,$nbits,$al,$bl,$wantl) = @_;
 SKIP: {
    skip("XS support disabled", 1) if ($func =~ /\bXS\b/ && !$Algorithm::BinarySearch::Vec::HAVE_XS);
    skip("quad support disabled", 1) if ($nbits > 32 && !$HAVE_QUAD);
    my $code = eval "\\\&$func";
    my $av   = makevec($nbits,$al);
    my $bv   = makevec($nbits,$bl);
    my $cv   = $code->($av,$bv,$nbits);
    my $istr = v2str($cv,$nbits);
    my $wstr = l2str($wantl);
    is($istr, $wstr, "check_setop: ".fstr($func)."(nbits=$nbits,al=[".l2str($al)."],bl=[".l2str($bl)."]) == [$wstr]");
    return ($istr eq $wstr);
  }
}

##======================================================================
## test: common
my $al = [qw(1 2 3 4 5 6 7 8 9)];
my $bl = [qw(2 4 6 8 10 12 14)];
my ($c_want);

##======================================================================
## test: union +8
$c_want = [(1..9),(10,12,14)];
foreach my $func ("${PKG}::_vunion","${PKG}::XS::vunion") {
  foreach my $nbits (8,16,32,64) {
    check_setop($func, $nbits, $al,$bl, $c_want);
  }
}

##======================================================================
## test: intersect: +8
$c_want = [qw(2 4 6 8)];
foreach my $func ("${PKG}::_vintersect","${PKG}::XS::vintersect") {
  foreach my $nbits (8,16,32,64) {
    check_setop($func, $nbits, $al,$bl, $c_want);
  }
}

##======================================================================
## test: setdiff: +8
$c_want = [qw(1 3 5 7 9)];
foreach my $func ("${PKG}::_vsetdiff","${PKG}::XS::vsetdiff") {
  foreach my $nbits (8,16,32,64) {
    check_setop($func, $nbits, $al,$bl, $c_want);
  }
}


# end of t/05_setops.t
