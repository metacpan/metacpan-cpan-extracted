# -*- Mode: CPerl -*-
use Test::More; #tests=>12;
use DDC::XS;

##-- rank
my ($f);
ok(($f=DDC::XS::CQFRankSort->new(DDC::XS::GreaterByRank)), "ranksort:new");
ok($f->toString =~ qr/^\#(?:DE?SC|GREATER)(?:_BY)?_RANK$/i, "ranksort:str");

##-- date
ok(($f=DDC::XS::CQFDateSort->new(DDC::XS::LessByDate, '1900-01-01', '2000')), "datesort:new");
like($f->toString, qr/^\#(?:ASC|LESS)(?:_BY)?_DATE\[1900-01-01,2000\]$/i, "datesort:str");

# v2.2.4 negative dates
ok(($f=DDC::XS::CQFDateSort->new(DDC::XS::LessByDate, '-427', '-347')), "datesort:negative:new");
like($f->toString, qr/^\#(?:ASC|LESS)(?:_BY)?_DATE\[-427,-347\]$/i, "datesort:negative:str");

##-- ctx : toString() buggy in ddc-2.0.37
ok(($f=DDC::XS::CQFContextSort->new(DDC::XS::LessByLeftContext, 'w',1,-1,'A','zzz')), "ctxsort:new");
like($f->toString, qr/^\#(?:ASC|LESS)(?:_BY)?_LEFT\[\'w\'\s*=1\s*-1,'A','zzz'\]$/i, "ctxsort:str");

##-- has-field (negated)
ok(($f=DDC::XS::CQFHasField->new('author','kant',1)), "hasfield:new");
like($f->toString, qr/^\!\#HAS(?:_FIELD)?\['author','kant'\]$/i, "hasfield:str");

##-- has-regex
ok(($f=DDC::XS::CQFHasFieldRegex->new('author','kant',0)), "hasregex:new");
like($f->toString, qr{^\#HAS(?:_FIELD)?\['author',/kant/\]$}i, "hasregex:str");

##-- has-set
ok(($f=DDC::XS::CQFHasFieldSet->new('author',[qw(kant hegel)],0)), "hasset:new");
like($f->toString, qr(^\#HAS(?:_FIELD)?\['author',\{'hegel','kant'\}\]$)i, "hasregex:str");

print "\n";
done_testing();
