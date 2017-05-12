## -*- Mode: CPerl -*-
use Test::More;
use DDC::PP;

my @hse =
  (
   qw(NoSort RandomSort),
   (map {("LessBy$_","GreaterBy$_")}
    qw(Date Size FreeBiblField Rank MiddleContext LeftContext RightContext CountKey CountValue)),
  );

my @constants =
  (
   ##--------------------------------------------------------------
   ## Constants: generic
   qw(library_version),

   ##--------------------------------------------------------------
   ## Constants: HitSortEnum
   @hse,
  );
plan(tests => (2*@constants) + (2*@hse));

##-- 1..($NC=2*@constants): test constant subs
my ($sub);
foreach (@constants) {
  ok(defined($sub=DDC::PP->can($_)), "can($_)");
  ok(defined($sub) && defined($sub->()), "defined($_())");
}

##-- ($NC+1)..(($NC+1)*2*@hse) : hitsortenum
foreach (@hse) {
  my $e = DDC::PP->can($_)->();
  is($DDC::PP::HitSortEnum{$_}, $e, "$_ - HitSortEnum{}");
  is($DDC::PP::HitSortEnum[$e], $_, "$_ - HitSortEnum[]");
}

print "\n";



