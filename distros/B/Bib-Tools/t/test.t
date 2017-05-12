#!perl 

use Test::More tests => 27;
#use Data::Dumper;

BEGIN {
    use_ok( 'Bib::Tools' ) || print "Bail out!\n";
}

note("tests without using network ...\n");

my $refs = new_ok("Bib::Tools");
is($refs->{ratelimit},5);

my $ref = new_ok("Bib::CrossRef");
$ref->_setdoi('http://dx.doi.org/10.1080/002071700411304');
$ref->_setscore(1);
$ref->_setatitle('Survey of gain-scheduling analysis and design');
$ref->_setjtitle('International Journal of Control');
$ref->_setvolume(1); $ref->_setissue(2);
$ref->_setdate('2015'); $ref->_setgenre('article');
$ref->_setauthcount(2);
$ref->_setauth(1,'D. J. Leith'); $ref->_setauth(2,'W. E. Leithead');
$ref->_setspage('1001'); $ref->_setepage('1025');

$refs->append($ref);
$refs->append($ref);
ok($refs->_split_duplicates);
my $len1 = @{$refs->{refs}};
is($len1,1);
my $len2 = @{$refs->{duprefs}};
is($len2,1);
my $len3 = @{$refs->{nodoi_refs}};
is($len3,0);

is($refs->num,1);
is($refs->num_nodoi,0);
my $r1;
ok($r1 = $refs->getref(0));
my $out1;
ok($out1 = $r1->print(1));
my $out;
ok($out = $refs->print);
is($out,$out1."\n");
ok($out=$refs->send_resp);
my $expected=<<"END";
<!DOCTYPE HTML><html><head><meta charset="utf-8"><meta http-equiv="Content-Type"><script src="post.js"></script></head><body><table id="doi"><tr style="font-weight:bold"><td></td><td>Use</td><td></td><td>Type</td><td>Year</td><td>Authors</td><td>Title</td><td>Journal</td><td>Volume</td><td>Issue</td><td>Pages</td><td>DOI</td><td>url</td><td></td></tr>
<tr id="cite"><td>1</td><td><input type="checkbox" name="1" value="" checked></td><td></td><td contenteditable="true">article</td><td contenteditable="true">2015</td><td contenteditable="true">D. J. Leith and W. E. Leithead</td><td contenteditable="true">Survey of gain-scheduling analysis and design</td><td contenteditable="true">International Journal of Control</td><td contenteditable="true">1</td><td contenteditable="true">2</td><td contenteditable="true">1001-1025</td><td contenteditable="true">10.1080/002071700411304</td><td contenteditable="true"></td><td></td></tr>
<tr><td colspan=12 style="color:#C0C0C0"></td></tr>

</table>
<input id="Submit" type="button" value="Submit" onclick="GetCellValues(\'doi\');GetCellValues('nodoi');" /><div id="out"></div></body></html>
END
is($out."\n",$expected);

my $bibtex=<<"END";
\@article{DBLP:journals/corr/abs-1206-3120,
  author    = {Vijay G. Subramanian and
               Douglas J. Leith},
  title     = {Convexity Conditions for 802.11 WLANs},
  journal   = {CoRR},
  volume    = {abs/1206.3120},
  year      = {2012},
  url       = {http://arxiv.org/abs/1206.3120},
  timestamp = {Wed, 10 Oct 2012 01:00:00 +0200},
  biburl    = {http://dblp.uni-trier.de/rec/bib/journals/corr/abs-1206-3120},
  bibsource = {dblp computer science bibliography, http://dblp.org}
}
END
use IO::File;
open my $fh, '<', \$bibtex;
$refs = new_ok("Bib::Tools");
ok($refs->add_bibtex($fh));
$expected='1. article: 2012, Vijay G. Subramanian and Douglas J. Leith, \'Convexity Conditions for 802.11 WLANs\'. CoRR, abs/1206.3120, http://arxiv.org/abs/1206.3120';
is($refs->print_nodoi,$expected);

note("tests requiring a network connection ...\n");

$refs = new_ok("Bib::Tools");
my @lines;
$lines[0]='25.	Dangerfield, I., Malone, D., Leith, D.J., 2011, Incentivising fairness and policing nodes in WiFi, IEEE Communications Letters, 15(5), pp500-502.';
$lines[1]='26.	D. Giustiniano, D. Malone, D.J. Leith and K. Papagiannaki, 2010. Measuring transmission opportunities in 802.11 links. IEEE/ACM Transactions on Networking, 18(5), pp1516-1529';
$refs->add_details(@lines);

SKIP: {
  skip "Optional network tests", 7 unless ((defined ${$refs->{refs}}[0])&&(defined ${$refs->{refs}}[1]));

  my $expected1 ='article: 2011, I Dangerfield and D Malone and D J Leith, \'Incentivising Fairness and Policing Nodes in WiFi\'. IEEE Communications Letters, 15(5),pp500-502, DOI: 10.1109/lcomm.2011.040111.102111, http://dx.doi.org/10.1109/lcomm.2011.040111.102111';
  is(${$refs->{refs}}[0]->print,$expected1);
  my $expected2='article: 2010, Domenico Giustiniano and David Malone and Douglas J. Leith and Konstantina Papagiannaki, \'Measuring Transmission Opportunities in 802.11 Links\'. IEEE/ACM Transactions on Networking, 18(5),pp1516-1529, DOI: 10.1109/tnet.2010.2051038, http://dx.doi.org/10.1109/tnet.2010.2051038';
  is(${$refs->{refs}}[1]->print,$expected2);
  ok($out=$refs->print());
$expected1='1. article: 2011, I Dangerfield and D Malone and D J Leith, \'Incentivising Fairness and Policing Nodes in WiFi\'. IEEE Communications Letters, 15(5),pp500-502, DOI: 10.1109/lcomm.2011.040111.102111, http://dx.doi.org/10.1109/lcomm.2011.040111.102111
2. article: 2010, Domenico Giustiniano and David Malone and Douglas J. Leith and Konstantina Papagiannaki, \'Measuring Transmission Opportunities in 802.11 Links\'. IEEE/ACM Transactions on Networking, 18(5),pp1516-1529, DOI: 10.1109/tnet.2010.2051038, http://dx.doi.org/10.1109/tnet.2010.2051038
';  is($out,$expected1);

my $text=<<"END";
10.1109/lcomm.2011.040111.102111
10.1109/tnet.2010.2051038
END
  open $fh,"<",\$text;
  ok($refs->add_fromfile($fh));
  ok($out=$refs->print());
  is($out,$expected1);
}

diag( "Testing Bib::Tools $Bib::Tools::VERSION, Perl $], $^X" );
