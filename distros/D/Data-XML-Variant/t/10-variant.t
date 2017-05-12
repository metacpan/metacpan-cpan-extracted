#!perl -w

use strict;

use Test::More tests => 7;
#use Test::More qw/no_plan/;
use Test::XML;

my $Variant;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $Variant = 'Data::XML::Variant';
    use_ok($Variant) or die;
}

can_ok $Variant, 'new';
ok my $xml = $Variant->new(
    {
        foo         => 'foo',
        'florp:bar' => 'bar',
    }
  ),
  '... and calling it with valid arguments should succeed';
isa_ok $xml, 'Data::XML::Variant::Build', '... and the object it returns';

my $expected = '<florp:bar id="3"><foo>message</foo></florp:bar>';
my $result   =
  $xml->start_bar( [ id => 3 ] ) . $xml->foo('message') . $xml->end_bar;
is $result, $expected, 'Calling start and end methods should succeed';

$result = $xml->bar( [ id => 3 ], $xml->foo('message') );
is $result, $expected, '... even if we call them inline';

$xml->Remove;    # delete all tag methods
$xml = Data::XML::Variant->new(
    {
        'ns:foo'  => 'foo',
        'bar'     => 'bar',
        'ns2:baz' => 'baz',
    }
);
my $xslt_url = 'http://www.example.com/xslt/';
my $url      = 'http://www.example.com/url/';
$result = join "\n" => $xml->Decl,    # add declaration (optional)
  $xml->PI( 'xml-stylesheet', [ type => 'text/xsl', href => "$xslt_url" ] ),
  $xml->foo(
    [ id => 3, 'xmlns:ns2' => $url ], "\n",
    $xml->bar('silly'),                   "\n",
    $xml->Comment('this is a > comment'), "\n",
    $xml->baz( [ 'asdf:some_attr' => 'value' ], 'whee!' ), "\n"
  );

chomp( $expected = <<"END_XML");
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="$xslt_url"?>
<ns:foo id="3" xmlns:ns2="$url">
<bar>silly</bar>
<!-- this is a &gt; comment -->
<ns2:baz asdf:some_attr="value">whee!</ns2:baz>
</ns:foo>
END_XML

is $result, $expected,
  'We should be able to generate complex XML with newlines';
