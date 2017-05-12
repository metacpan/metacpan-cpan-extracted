# -*-perl -*- 
# B::Generate <1.41 broke Concise dumping of const ops on threaded perls
# https://rt.cpan.org/Public/Bug/Display.html?id=70398
use Test::More
  $] < 5.007
   ? (skip_all => "no 5.6.2 Concise testing")
   : (tests => 3);
use Config;

sub const_iv {
  my $s = shift;
  $s =~ m/const[\(\[](IV .+?)[\)\]]/;
  return $1;
}

# broken on win95, do not care enough
my $X = $^X =~ m/\s/ ? qq{"$^X" -Iblib/arch -Iblib/lib} : "$^X -Iblib/arch -Iblib/lib";

my $pure=`$X -MO=-qq,Concise -lwe "print 123"`;
# <$> const[IV 123] s ->5
is (const_iv($pure), "IV 123", "Concise without B::Generate");

# causes endless recursion in Concise.pm:470 (loop until !sibling) with -DPERL_OP_PARENT
if ($] >= 5.021002 and $Config{ccflags} =~ /-DPERL_OP_PARENT/) {
  ok(1, "skip Concise combination with -DPERL_OP_PARENT");
  ok(1, "skip Concise combination with -DPERL_OP_PARENT");
} else {
  my $polluted=`$X -MB::Generate -MO=-qq,Concise -lwe "print 123"`;
  # was: <$> const(IV \32163568)[t1] s ->5
  is (const_iv($polluted), "IV 123", "Concise with B::Generate");

  # workaround
  my $q = $^O eq 'MSWin32' ? '"' : "'"; # such is life
  my $workaround = "-MO=-qq,Concise -lwe$q".q(BEGIN{require B;my $sv=\&B::SVOP::sv;require B::Generate;no warnings; *B::SVOP::sv=$sv;} print 123).$q;

  like (`$X $workaround`, qr/const[\(\[]IV 123[\)\]]/, "workaround");
}