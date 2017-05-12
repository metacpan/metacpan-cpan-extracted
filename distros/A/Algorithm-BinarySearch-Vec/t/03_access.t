# -*- Mode: CPerl -*-
# t/03_access.t; test access

use lib qw(blib/lib blib/arch);
use Test::More tests => 28;
use Algorithm::BinarySearch::Vec qw(:all);
no warnings 'portable';

my $HAVE_QUAD = $Algorithm::BinarySearch::Vec::HAVE_QUAD;

##--------------------------------------------------------------
## utils

sub check_set {
  my ($i,$nbits,$val) = @_;
  my $vec='';
  my $label = "vset(\$vec,index=$i,nbits=$nbits,val=$val); vec(...)==$val";
 SKIP: {
    skip("$label: 64-bit support disabled", 1) if ($nbits > 32 && !$HAVE_QUAD);
    vec($vec,$i,$nbits) = 0; ##-- pre-allocate (no longer required?)
    Algorithm::BinarySearch::Vec::vset($vec,$i,$nbits,$val);
    my $vval = vec($vec,$i,$nbits);
    is($vval, $val, "vset(\$vec,index=$i,nbits=$nbits,val=$val); vec(...)==$val");
  }
}

sub check_get {
  my ($i,$nbits,$val) = @_;
  my $vec='';
  my $label = "vec(\$vec,index=$i,nbits=$nbits)=$val; vget(...)==$val";
 SKIP: {
    skip("$label: 64-bit support disabled", 1) if ($nbits > 32 && !$HAVE_QUAD);
    vec($vec,$i,$nbits) = $val;
    my $vval = Algorithm::BinarySearch::Vec::vget($vec,$i,$nbits);
    is($vval, $val, $label);
  }
}


##--------------------------------------------------------------
## tests

##-- +4 : nbits=1
foreach my $ib (
		[63,1=>0],[63,1=>1],   ##-- x2: nbits=1
		[17,2=>0],[17,2=>3],   ##-- x2: nbits=2
		[5, 4=>0],[17,4=>9],   ##-- x2: nbits=4
		[3, 8=>0],[17,8=>129], ##-- x2: nbits=8
		[41,16=>0],[41,16=>32769], ##-- x2: nbits=16
		[37,32=>0],[37,32=>65537], ##-- x2: nbits=32
		[7,64=>0], [7,64=>4294967297], ##-- x2: nbits=64
	       )
  {
    check_set(@$ib);
    check_get(@$ib);
  }

# end of t/03_access.t
