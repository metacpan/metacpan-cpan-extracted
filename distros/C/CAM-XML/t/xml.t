#!/usr/bin/perl -w

use warnings;
use strict;
use File::Spec;

BEGIN
{ 
   use vars qw($pkg);
   $pkg = 'CAM::XML';
   use Test::More tests => 115;
   use_ok($pkg);
}

# First, try some failures:
is(CAM::XML->parse(-string => '<'), undef, 'bad xml');
is(CAM::XML->parse(-string => '<', -cleanwhitespace => 1), undef, 'bad xml');
is(CAM::XML->parse(-string => '<', -xmlopts => {}), undef, 'bad xml');



eval { CAM::XML->new('foo')->setAttributes('' => 1); };     ok($@, 'invalid attribute key');
eval { CAM::XML->new('foo')->setAttributes(undef, 1); };  ok($@, 'invalid attribute key');

is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChild(undef), undef, 'invalid child index');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChild('barfle'), undef, 'invalid child index');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChild(-1), undef, 'invalid child index');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChildNode(undef), undef, 'invalid child index');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChildNode('barfle'), undef, 'invalid child index');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChildNode(-1), undef, 'invalid child index');

eval { CAM::XML->new('foo')->add(undef); };           ok($@, 'invalid child node');
eval { CAM::XML->new('foo')->add(bless {}, 'Foo'); }; ok($@, 'invalid child node');
eval { CAM::XML->new('foo')->add(-foo => 1); };       ok($@, 'invalid child node');
eval { CAM::XML->new('foo')->add(-xml => '<'); };     ok($@, 'invalid child node');

my ($parsed, $root, $root2, $str);

#------------------------------------------
# This is the XML we will try to recreate

my $comparestr1 = <<'EOF';
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<root test="1">
<sub id="1">sub 1</sub>
<sub id="2">sub 2</sub>
<sub id="3">sub 3</sub>
<test> just a test </test>
<![CDATA[This is a simple CDATA test.]]>
<![CDATA[This is a complex <![CDATA[]]>]]&gt;<![CDATA[ test.]]>
&amp; ampersand
</root>
EOF

# Extract text from above
my $comparetext1 = <<'EOF';

sub 1
sub 2
sub 3
 just a test 
This is a simple CDATA test.
This is a complex <![CDATA[]]> test.
& ampersand
EOF

# Extract subsettext from above
my $comparetext1sub = 'sub 1sub 2sub 3';

my $comparestr2 = <<'EOF';
   <level1>
      <level2>
         <level3/>
      </level2>
   </level1>
EOF

# Extract whitespace from above
my $plainstr = '<level1><level2><level3/></level2></level1>';

my $comparestr3 = <<'EOF';
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<root><sub>sub 1</sub><sub>sub 2</sub>root</root>
EOF

my $comparefmt3 = <<'EOF';
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<root>
  <sub>
    sub 1
  </sub>
  <sub>
    sub 2
  </sub>
  root
</root>
EOF

my $comparefmttxt3 = <<'EOF';
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<root>
  <sub>sub 1</sub>
  <sub>sub 2</sub>
  root
</root>
EOF


#------------------------------------------


# Build the CAM::XML data structure
$root = $pkg->new('root', test => '1');
$root->add(CAM::XML::Text->new(text => "\n"));
#$root->add(-text => "\n");
for (my $i=1; $i<=3; $i++)
{
   my $sub = $pkg->new('sub');
   $sub->setAttributes(id => $i);
   $root->add($sub);
   $sub->add(-text => "sub $i");
   $root->add(-text => "\n");
}
$root->add(-xml => '<test> just a test </test>');
$root->add(-text => "\n");
$root->add(-cdata => 'This is a simple CDATA test.');
$root->add(-text => "\n");
$root->add(-cdata => 'This is a complex <![CDATA[]]> test.');
$root->add(-text => "\n");
$root->add(-text => '& ampersand');
$root->add(-text => "\n");

is_deeply([sort $root->getAttributeNames()], ['test'], 'getAttributeNames');
is($root->getAttribute('test'), '1', 'getAttribute');

is(scalar $root->getNodes(-tag => 'root'), 1, 'getNodes by tag');
is(scalar $root->getNodes(-tag => 'sub'), 3, 'getNodes by tag');
is(scalar $root->getNodes(-tag => 'foo'), 0, 'getNodes by tag');
is(scalar $root->getNodes(-attr => 'id', -value => 3), 1, 'getNodes by attribute');
is(scalar $root->getNodes(-attr => 'id', -value => 4), 0, 'getNodes by attribute');
is(scalar $root->getNodes(-path => '/root'), 1, 'getNodes by path');
is(scalar $root->getNodes(-path => 'root'), 1, 'getNodes by path');
is(scalar $root->getNodes(-path => 'sub'), 0, 'getNodes by path');
is(scalar $root->getNodes(-path => '/sub'), 0, 'getNodes by path');
is(scalar $root->getNodes(-path => '//sub'), 3, 'getNodes by path');
is(scalar $root->getNodes(-path => '/root/sub'), 3, 'getNodes by path');
is(scalar $root->getNodes(-path => '//'), 5, 'getNodes by path');

# Index tests
is(scalar $root->getNodes(-path => '/root/[1]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/[32]'), 0, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[2]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '[1]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '[2]'), 0, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '[1]/test'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[1]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[2]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[3]'), 1, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[4]'), 0, 'getNodes by path, index');
is(scalar $root->getNodes(-path => '/root/sub[-1]'), 1, 'getNodes by path, -index');
is(scalar $root->getNodes(-path => '/root/sub[-2]'), 1, 'getNodes by path, -index');
is(scalar $root->getNodes(-path => '/root/sub[-3]'), 1, 'getNodes by path, -index');
is(scalar $root->getNodes(-path => '/root/sub[-4]'), 0, 'getNodes by path, -index');
is(scalar $root->getNodes(-path => '/root/sub[last()]'), 1, 'getNodes by path, last');

# Attribute tests
is(scalar $root->getNodes(-path => '[@test="1"]'), 1, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '[@test="2"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '[@foo=""]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/[@test="1"]'), 1, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/[@test="2"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/[@foo=""]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root[@test="1"]'), 1, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root[@test="2"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root[@foo=""]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/sub[@id="1"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/sub[@id="0"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/sub[@foo=""]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '//sub[@id="1"]'), 1, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '//sub[@id="0"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '//sub[@foo=""]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root/sub[@id="1"]'), 1, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root/sub[@id="0"]'), 0, 'getNodes by path, attr');
is(scalar $root->getNodes(-path => '/root/sub[@foo=""]'), 0, 'getNodes by path, attr');

# Text tests
is(join('',map{$_->getInnerText()} $root->getNodes(-path => '/text()')), $comparetext1, 'getNodes by path, text');
is(join('',map{$_->getInnerText()} $root->getNodes(-path => '//sub/text()')), $comparetext1sub, 'getNodes by path, text');

#<root test="1">
#<sub id="1">sub 1</sub>
#<sub id="2">sub 2</sub>
#<sub id="3">sub 3</sub>
#<test> just a test </test>
#<![CDATA[This is a simple CDATA test.]]>
#<![CDATA[This is a complex <![CDATA[]]>]]&gt;<![CDATA[ test.]]>
#&amp; ampersand
#</root>

ok($root->getChildNode(0), 'getChildNode');
is($root->getChildNode(4), undef, 'getChildNode');
is(scalar $root->getChildNodes(), 4, 'getChildNodes');

# Get the XML output
$str = $root->header() . $root->toString() . "\n";

is($str, $comparestr1, 'Plain XML with cdata');

is($root->getInnerText(), $comparetext1, 'getInnerText');

$parsed = $pkg->parse($comparestr1);
SKIP: {
   # Hack to make our test data structure LOOK like XML::Parser output
   splice(@{$root->{children}}, 11, 1, 
          CAM::XML::Text->new('cdata', 'This is a complex <![CDATA['),
          CAM::XML::Text->new('text', ']]>'),
          CAM::XML::Text->new('cdata', ' test.'),
          );
   is_deeply($parsed, $root, 'Parse test');
}

$str = $parsed->header() . $parsed->toString() . "\n";
is($str, $comparestr1, 'Deparse parsed XML');

$root = $pkg->new('level1')
                ->add($pkg->new('level2')
                              ->add($pkg->new('level3'))
                      );
$str = $root->toString(-formatted=>1, -level=>1, -indent=>3);
is($str, $comparestr2, 'Formatted XML');

$str = $comparestr2;
$str =~ s/>\s+</></gs; # undo the formatting for the next test

$parsed = $pkg->parse(-filename => File::Spec->catfile('t', 'sample.xml'));
is_deeply($parsed->toString(), '<foo>bar</foo>', 'Parse file');

$parsed = $pkg->parse(-filename => File::Spec->catfile('t', 'nosuchfile.xml'));
is($parsed, undef, 'Parse non-existent file');

$parsed = $root->parse(-string => $str);
is_deeply($parsed, $root, 'Parse test');

$str = $parsed->toString(-formatted=>1, -level=>1, -indent=>3);
is($str, $comparestr2, 'Deparse parsed XML');

$parsed->removeWhitespace();
is($parsed->toString(), $plainstr, 'removeWhitespace');

$parsed = $pkg->parse('  <xml>    </xml>   ');
$parsed->removeWhitespace();
is($parsed->toString(), '<xml/>', 'removeWhitespace');

$parsed = $pkg->parse('  <xml> test </xml>   ');
$parsed->removeWhitespace();
is($parsed->toString(), '<xml> test </xml>', 'removeWhitespace');


$parsed = $pkg->parse("  <xml>\ntest\n<test>test</test> \r\n  <br\n/></xml>   ");
$parsed->removeWhitespace();
is($parsed->toString(), "<xml>\ntest\n<test>test</test><br/></xml>", 'removeWhitespace');

$root2 = CAM::XML->new('root');
ok($root2->setChildren($root->getChildren()), 'setChildren');
eval { $root2->setChildren(1,2,3); };  ok($@, 'setChildren (bad)');
eval { $root2->setChildren(undef); };  ok($@, 'setChildren (bad)');
eval { $root2->setChildren(bless {}, 'Foo'); };  ok($@, 'setChildren (bad)');
ok(scalar $root2->getChildren() > 0, 'getChildren');

ok($root2->setChildren(CAM::XML->new("foo")), 'setChildren');
is(scalar $root2->getChildren(), 1, 'getChildren');
ok($root2->setChildren(CAM::XML::Text->new(text => "")), 'setChildren');
is(scalar $root2->getChildren(), 1, 'getChildren');
ok($root2->setChildren(CAM::XML::Text->new(cdata => "")), 'setChildren');
is(scalar $root2->getChildren(), 1, 'getChildren');

$parsed = $pkg->parse($comparestr3);
$str = $parsed->header() . $parsed->toString(-formatted => 1);
is($str, $comparefmt3, 'Fomatted XML - text spacing');
$str = $parsed->header() . $parsed->toString(-formatted => 1, -textformat => 0);
is($str, $comparefmttxt3, 'Fomatted XML - text spacing');

my $esctest;
$esctest = CAM::XML->new('esc')->add(-text => 'one & two');
is($esctest->toString(), '<esc>one &amp; two</esc>', 'amp escaping');
is($esctest->toString(-formatted => 1, -textformat => 0), "<esc>one &amp; two</esc>\n", 'amp escaping');
$esctest = CAM::XML->new('esc')->add(-text => 'one < two');
is($esctest->toString(), '<esc>one &lt; two</esc>', 'lt escaping');
is($esctest->toString(-formatted => 1, -textformat => 0), "<esc>one &lt; two</esc>\n", 'lt escaping');
$esctest = CAM::XML->new('esc')->add(-text => 'two > one');
is($esctest->toString(), '<esc>two &gt; one</esc>', 'gt escaping');
is($esctest->toString(-formatted => 1, -textformat => 0), "<esc>two &gt; one</esc>\n", 'gt escaping');

is(CAM::XML::Text->new()->toString(), q{}, 'empty text');

eval { CAM::XML->new(); };   ok($@, 'empty constructor');

is(CAM::XML->new('foo')->getName(), 'foo', 'getName');
is_deeply({CAM::XML->new('foo', bar => 'baz')->getAttributes()}, {bar => 'baz'}, 'getAttributes');
is(CAM::XML->new('foo')->getAttribute(undef), undef, 'getAttribute');
is(CAM::XML->new('foo')->add(CAM::XML->new('bar'))->getChild(0)->getName(), 'bar', 'getChild');

is(CAM::XML->new('foo')->add(-text => undef)->getInnerText(), q{}, 'empty text');

is(CAM::XML->parse(-string => '<foo> </foo>', -cleanwhitespace => 1)->toString(), '<foo/>', 'cleanwhitespace');

my $attrtest = CAM::XML->new('foo', bar => 1);
ok($attrtest->deleteAttribute('missing'), 'deleteAttribute');
ok($attrtest->deleteAttribute('bar'), 'deleteAttribute');
is($attrtest->getAttribute('bar'), undef, 'deleteAttribute');

is(CAM::XML->_XML_escape(undef), '', 'xml escape');

my $indenttest = CAM::XML->new('foo')->add(CAM::XML->new('bar')->add(-text => 'baz'));
my $indentcmp = $indenttest->toString(-formatted => 1);
is($indenttest->toString(-formatted => 1, -indent => 2), $indentcmp, 'indent test');
isnt($indenttest->toString(-formatted => 1, -indent => 0), $indentcmp, 'indent test');
is($indenttest->toString(-formatted => 1, -indent => 'bogus'), $indentcmp, 'indent test');
