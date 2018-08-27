# -*- Mode: CPerl -*-
use Test::More tests=>9;

#use lib qw(../blib/lib ../blib/arch);
use DDC::XS;

##-- 1: constructor
my $compiler = DDC::XS::CQueryCompiler->new;
ok($compiler, "CQCompiler->new");

##-- 2: ParseQuery (bad)
my ($q);
eval {
  $q = $compiler->ParseQuery('Haus #');
};
ok(!defined($q) && defined($@) && $@ =~ /syntax error/,
   "compiler->ParseQuery('Haus #') -> error");

##-- 3: ParseQuery (good)
ok(($q=$compiler->ParseQuery('Haus')), "compiler->ParseQuery('Haus')");

##-- 4: QueryToString
ok($compiler->QueryToString =~ /Haus/, "QueryToString");

##-- 5: QueryToJson
ok($compiler->QueryToJson =~ /Haus/, "QueryToJson");

##-- 6: TO_JSON
use JSON;
my %jopts = (allow_blessed=>1,convert_blessed=>1,canonical=>1);
my $json = JSON::to_json($compiler, \%jopts);
ok(defined($json), "to_json - defined");

##-- 7: toHash
my ($hash);
ok(defined($hash=$compiler->toHash), "toHash - defined");

##-- 8..9: fromHash
my $c2 = ref($compiler)->newFromHash($hash);
ok(defined($c2), "newFromHash - defined");
is(JSON::to_json($c2,\%jopts), $json, "to_json(fromHash(toHash(src)))==to_json(src)");


print "\n";

