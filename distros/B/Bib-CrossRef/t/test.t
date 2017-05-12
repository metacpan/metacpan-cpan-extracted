#!perl 

use Test::More tests => 29;
#use Data::Dumper;

BEGIN {
    use_ok( 'Bib::CrossRef' ) || print "Bail out!\n";
}

note("tests without using network ...\n");

my $ref = new_ok("Bib::CrossRef");
is($ref->{html},0);
$ref->sethtml; is($ref->{html},1);

$ref->_setdoi('http://dx.doi.org/10.1080/002071700411304');
is($ref->doi, 'http://dx.doi.org/10.1080/002071700411304');
$ref->_setscore(1);
is($ref->score,1);
$ref->_setatitle('Survey of gain-scheduling analysis and design');
is($ref->atitle,'Survey of gain-scheduling analysis and design');
$ref->_setjtitle('International Journal of Control');
is($ref->jtitle,'International Journal of Control');
$ref->_setvolume(1);
is($ref->volume,1);
$ref->_setissue(2);
is($ref->issue,2);
$ref->_setdate('2015');
is($ref->date,'2015');
$ref->_setgenre('article');
is($ref->genre,'article');
$ref->_setauthcount(2);
$ref->_setauth(1,'D. J. Leith');
$ref->_setauth(2,'W. E. Leithead');
is($ref->authcount,2);
is($ref->auth(1),'D. J. Leith');
is($ref->auth(2),'W. E. Leithead');
$ref->_setspage('1001');
$ref->_setepage('1025');
is($ref->spage,'1001');
is($ref->epage,'1025');
my $out;
ok($out=$ref->print('2'));
my $expected=<<"END";
<tr id="cite"><td>2</td><td><input type="checkbox" name="2" value="" checked></td><td></td><td contenteditable="true">article</td><td contenteditable="true">2015</td><td contenteditable="true">D. J. Leith and W. E. Leithead</td><td contenteditable="true">Survey of gain-scheduling analysis and design</td><td contenteditable="true">International Journal of Control</td><td contenteditable="true">1</td><td contenteditable="true">2</td><td contenteditable="true">1001-1025</td><td contenteditable="true">10.1080/002071700411304</td><td contenteditable="true"></td><td></td></tr>
<tr><td colspan=12 style="color:#C0C0C0"></td></tr>
END
is($out,$expected);

note("tests requiring a network connection ...\n");

$ref = new_ok("Bib::CrossRef"); # fresh ref
$ref->parse_text("Survey of gain-scheduling analysis and design DJ Leith, WE Leithead International journal of control 73 (11), 1001-1025");
$r = $ref->{ref};
#print Dumper($r);
SKIP: {
  skip "Optional network tests", 9 unless (exists $r->{query});
  is($r->{query},"Survey of gain-scheduling analysis and design DJ Leith, WE Leithead International journal of control 73 (11), 1001-1025");
  is($ref->atitle,'Survey of gain-scheduling analysis and design');
  is($ref->jtitle,'International Journal of Control');
  is($ref->authcount,2);
  is($ref->auth(1),'D. J. Leith');
  is($ref->doi,'http://dx.doi.org/10.1080/002071700411304');
  is($ref->doi(),'http://dx.doi.org/10.1080/002071700411304');
  ok($out=$ref->print('1'));
  $expected="1. article: 2000, D. J. Leith and W. E. Leithead, 'Survey of gain-scheduling analysis and design'. International Journal of Control, 73(11),pp1001-1025, DOI: 10.1080/002071700411304, http://dx.doi.org/10.1080/002071700411304";
  is($out,$expected);
}

diag( "Testing Bib::CrossRef $Bib::CrossRef::VERSION, Perl $], $^X" );
