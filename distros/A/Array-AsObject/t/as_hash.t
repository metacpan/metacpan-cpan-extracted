#!/usr/bin/perl -w

require 5.001;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
  $dir="./lib";
  $tdir="t";
} elsif ( -f "test.pl" ) {
  require "test.pl";
  $dir="../lib";
  $tdir=".";
} else {
  die "ERROR: cannot find test.pl\n";
}

unshift(@INC,$dir);
use Array::AsObject;

sub test {
  ($o,$full) = @_;
  $o = $obj{$o};
 
  if ($full) {

    @ret = ();
    ($count,$vals) = $o->as_hash(1);
    @k = sort { ref($$vals{$a}) cmp ref($$vals{$b})  ||
                $a cmp $b } keys %$count;
    foreach my $k (@k) {
       my $v = $$vals{$k};
       if (ref($v)) {
          push(@ret,ref($v) . "($k)",$$count{$k});
       } else {
          push(@ret,$v,$$count{$k});
       }
    }
    return @ret;

  } else {

    @ret = ();
    %h = $o->as_hash();
    @k = sort keys %h;
    foreach my $k (@k) {
      push(@ret,$k,$h{$k});
    }
    return @ret;

  }
}

%obj       = ();
$o         = new Array::AsObject qw( a b c a b );
$obj{'01'} = $o;

$i         = [ qw(a b) ];
$o         = new Array::AsObject ('a', $i, $i, 'b', 'a');
$obj{'02'} = $o;

$j         = [ qw(a b) ];
$o         = new Array::AsObject ('a', $i, $j, 'b', 'a');
$obj{'03'} = $o;


$tests = "

01 0 ~ a 2 b 2 c 1

01 1 ~ a 2 b 2 c 1

02 0 ~ a 2 b 1

02 1 ~ a 2 b 1 ARRAY(2) 2

03 0 ~ a 2 b 1

03 1 ~ a 2 b 1 ARRAY(2) 1 ARRAY(3) 1

";

print "as_hash...\n";
test_Func(\&test,$tests,$runtests);

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

