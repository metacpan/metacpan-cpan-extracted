## -*- Mode: CPerl -*-
use Test::More;
use DDC::Any;

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
  ok(defined($sub=DDC::Any->can($_)), "can($_)");
  ok(defined($sub) && defined($sub->()), "defined($_())");
}

##-- ($NC+1)..(($NC+1)*2*@hse) : hitsortenum
foreach (@hse) {
  my $e = DDC::Any->can($_)->();
  is($DDC::Any::HitSortEnum{$_}, $e, "$_ - HitSortEnum{}");
  is($DDC::Any::HitSortEnum[$e], $_, "$_ - HitSortEnum[]");
}

print "\n";



