# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Cindy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Cindy') };

#########################

use Cindy;

sub strip_ws($) {
  my ($str) = @_;
  # Remove all whitespace
  $str =~ s/\s+//gm;
  return $str;
}

sub is_up_to_ws
{
  my $got = strip_ws(shift(@_));
  my $exp = strip_ws(shift(@_));
  my $name = shift(@_);
  is($got, $exp, $name);
}

sub test($$$) {
  my ($doc, $data, $cis) = @_;
  my $xdoc; 
  my $is_xml_doc = ($doc =~ /^<\?xml/);
  if ($is_xml_doc) {
    $xdoc  = parse_xml_string($doc);
  } else {
    $xdoc  = parse_html_string($doc);
  }
  my $xdata = parse_xml_string ($data);
  my $xcis  = parse_cis_string ($cis);

  # Data will not be modified
  $xdata->indexElements();

  if ($is_xml_doc) {
    return inject($xdata, $xdoc, $xcis)->toString();
  } else {
    return inject($xdata, $xdoc, $xcis)->toStringHTML();
  }
}

#########################
# Basic test
my $cis = q|
use xpath ;

; Testing comments
/data/title/@test content   /html/head/title ;
/data/content     content   /html/body/h2[1] ;
; Testing enclosing "
"/data/replace"   replace   /html/body/p[1]/b[1] ;
/data/script      copy      /html/head/script ;
/data/omit        omit-tag  /html/body/p[1]/b[2] ;
/data/size        attribute /html/body/p[1]/font size ;
/data/color       attribute /html/body/p[1]/font color ;
/data/color       attribute /html/body/p[2]/span[2]/font color ;
/data/cfalse      condition /html/body/p[2]/span[1] ;
/data/ctrue       condition /html/body/p[2]/span[2] ;
false()           condition /html/body/p[2]/span[3] ;
"'A comment'"     comment   /html/body/select ;
/data/repeat/row  repeat    /html/body/table/tr {
  ./value           content   ./th ;
  ./text            content   ./td 
} ;
/data/repeat/row  repeat      /html/body/select/option {
  current()/value           attribute   .  value ;
  ./selected        attribute   .  selected ;
  ./text            content     . 
} ;
; Test "no data found" case
/data/does-not-exist  attribute /html/body//span class ;
/data/does-not-exist  attribute /html/body//p class ;
|;

my $data = q|<?xml version="1.0" encoding="utf-8" ?>
<data>
  <title test="This is the Cindy Test Page" />
  <content>Hello Test</content>
	<replace>This is NOT bold.</replace>
	<omit>1</omit>
	<!-- attributes are done with content -->
	<size>+2</size>
	<color>red</color>
  <repeat>
    <row>
      <value>1</value>
      <text>one</text>
    </row>
    <row>
      <value>2</value>
      <text>two</text>
      <selected>1</selected>
    </row>
    <row>
      <value>3</value>
      <text>three</text>
    </row>
  </repeat>
	<cfalse>0</cfalse>
	<ctrue>1</ctrue>
  <comment>A comment</comment>
  <script language="javascript"
    >if (2 &lt; 1) alert("Impossible");</script>
</data>
|;

my $doc = q|<!DOCTYPE html>
<html>
<head>
  <title>This is an Error</title>
  <script />
</head>

<body>

<a href="http://www.heute-morgen.de/test/About_Cindy.html">About</a>

<h2 test="I will survive">This is an Error for content</h2>
<p class="first"><b class="first">This is an Error for replace</b>
<b class="second"><i>This is not bold,</i> too.</b>
This is <font>Big and Red</font></p>
<p class="second"><span class="first">Das wird <b>entfernt</b>.</span>
<span class="second">Das <font>bleibt</font>.</span>
<span class="third">Das <font>verschwindet.</font>.</span>
</p>

<table>
	<tr>
    <th>0</th>
		<td>Text</td>
  </tr>
</table>

<select>
	<option value="test">Text</option>
</select>

</body>
</html>
|;

my $expected =  q|<!DOCTYPE html>
<html>
<head>
<title>This is the Cindy Test Page</title>
<script language="javascript">if (2 < 1) alert("Impossible");</script>
</head>
<body>

<a href="http://www.heute-morgen.de/test/About_Cindy.html">About</a>

<h2 test="I will survive">Hello Test</h2>
<p>This is NOT bold.
<i>This is not bold,</i> too.
This is <font size="+2" color="red">Big and Red</font></p>
<p>
<span>Das <font color="red">bleibt</font>.</span>

</p>

<table>
<tr>
<th>1</th>
		<td>one</td>
  </tr>
<tr>
<th>2</th>
		<td>two</td>
  </tr>
<tr>
<th>3</th>
		<td>three</td>
  </tr>
</table>
<select><option value="1">one</option>
<option value="2" selected>two</option>
<option value="3">three</option>
<!--A comment--></select>
</body>
</html>
|;

is_up_to_ws(test($doc, $data, $cis), $expected, 'Basic');

#########################
# Basic with css selectors

$cis = q|
; Testing comment before usage
use css ;

; Testing comments
title@test      content    "head > title" ;
content         content    "h2[test]" ;
replace         replace    "p.first > b.first" ;
script          copy       "head > script" ;
omit            omit-tag   "p.first > b.second" ;
size            attribute  "p.first > font" size ;
color           attribute  "p.first > font" color ;
color           attribute  "p > span > font" color ;
cfalse          condition  "p > span.first, span.third" ;
ctrue           condition  "p > span.second" ;
comment         comment    "select" ;
"repeat > row"  repeat     "table > tr" {
  value           content   th ;
  text            content   td 
} ;
"repeat > row"  repeat      "select > option" {
  value           attribute   ""  value ;
  selected        attribute   ""  selected ;
  text            content     "" 
} ;
; remove class
does-not-exist  attribute  "span, p" class ;  
|;

SKIP: {
  skip "HTML::Selector::XPath is not installed.",
       1 unless eval {require HTML::Selector::XPath;} ;

  is_up_to_ws(test($doc, $data, $cis), $expected, 'CSS');
}

#########################
# Order of execution

$cis = q|

/data/before attribute /html/body//span[@class='list1'] test:before ;
/data/row repeat /html/body/ul[1]/li {
  . content ./span ;
  . attribute ./span test:repeat ;
} ;
/data/after attribute /html/body//span[@class='list1'] test:after ;

; This is actually bad behaviour that may not be maintained in
; future releases.
'before' attribute /html/body//span[@class='list2']  class;
/data/row repeat /html/body/ul[2]/li {
  . content ./span[@class='before'] ;
} ;
|;

$data = q|<?xml version="1.0" encoding="UTF-8"?>
<data>
  <before>This is done before</before>
  <after>This is done after</after>
  <row>One</row>
  <row>Two</row>
</data>
|;

# DOCTYPE is added by libxml
$doc = q|<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Tests for cindy order of execution</title>
</head>

<body>

<a href="http://www.heute-morgen.de/test/About_Cindy.html">About</a>

<ul>
<li><span class="list1"></span></li>
</ul>

<ul>
<li><span class="list2">This is replaced, 
which means a change done before is matched.</span></li>
</ul>

</body>
</html>
|;

$expected = q|<!DOCTYPE html PUBLIC "-//W3C//DTDHTML4.0Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Tests for cindy order of execution</title></head>
<body>

<a href="http://www.heute-morgen.de/test/About_Cindy.html">About</a>

<ul>
<li><span class="list1" test:before="This is done before" test:repeat="One">One</span></li>
<li><span class="list1" test:before="This is done before" test:repeat="Two">Two</span></li>
</ul>
<ul>
<li><span class="before">One</span></li>
<li><span class="before">Two</span></li>
</ul>
</body>
</html>
|;

is_up_to_ws(test($doc, $data, $cis), $expected, 'Order');

#########################
# Repeat condition

$cis = q|
/data/filter/*    repeat      /html/body/table/tr/td 
                              local-name(DATA/*)=DOC/*/@class {
  .                 content   . ;
  'red'             attribute . bgcolor 
} ;
|;

$data = q|<?xml version="1.0" encoding="UTF-8"?>
<data>
  <filter>
    <third>3</third>
    <first>1</first>
    <second>2</second>
  </filter>
</data>
|;

$doc = q|<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Tests the cindy repeat condition</title>
</head>

<body>

<table>
	<tr>
    <th>First</th>
		<td class="first">Value</td>
  </tr>
	<tr>
    <th>Second</th>
		<td class="second">Value</td>
  </tr>
	<tr>
    <th>Third</th>
		<td class="third">Value</td>
  </tr>
</table>

</body>
</html>
|;

$expected = q|<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Tests the cindy repeat condition</title></head>
<body>

<table>
<tr>
<th>First</th>
		<td class="first" bgcolor="red">1</td>
  </tr>
<tr>
<th>Second</th>
		<td class="second" bgcolor="red">2</td>
  </tr>
<tr>
<th>Third</th>
		<td class="third" bgcolor="red">3</td>
  </tr>
</table>
</body>
</html>
|;

is_up_to_ws(test($doc, $data, $cis), $expected, 'Repeat condition');

#########################
# No data found

$cis = q|

/data/does-not-exist  content /doc/content ;
/data/does-not-exist  replace /doc/replace ;
/data/does-not-exist  copy /doc/copy ;
/data/does-not-exist  omit-tag /doc/omit-tag   ;
/data/does-not-exist  attribute /doc/attribute attribute ;
/data/does-not-exist  condition /doc/condition ;
/data/does-not-exist  comment /doc/comment ;
/data/does-not-exist  repeat /doc/repeat {
  ./does-not-exist      content ./does-not-exist ;
} ;
|;

$data = q|<?xml version="1.0" encoding="UTF-8"?>
<data/>
|;

$doc = q|<?xml version="1.0" encoding="UTF-8"?>
<doc>
<content>This should be unchanged.</content>
<replace>This should be unchanged.</replace>
<copy>This should be unchanged.</copy>
<omit-tag>This should be unchanged.</omit-tag>
<attribute 
  attribute="will be removed">This should be unchanged.</attribute>
<omit-tag>This should be unchanged.</omit-tag>
<condition>This should be completely removed.</condition>
<comment>This should be unchanged.</comment>
<repeat>This should be completely removed.</repeat>
</doc>
|;

$expected = q|<?xml version="1.0" encoding="UTF-8"?>
<doc>
<content>This should be unchanged.</content>
<replace>This should be unchanged.</replace>
<copy>This should be unchanged.</copy>
<omit-tag>This should be unchanged.</omit-tag>
<attribute>This should be unchanged.</attribute>
<omit-tag>This should be unchanged.</omit-tag>

<comment>This should be unchanged.</comment>

</doc>
|;

is_up_to_ws(test($doc, $data, $cis), $expected, 'No data found');

