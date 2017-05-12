use Test::More tests => 6; 

use_ok('CGI::XMLPost');

$ENV{CONTENT_LENGTH} = -s 'test.xml';
$ENV{CONTENT_TYPE}   = 'application/xml';
$ENV{REQUEST_METHOD} = 'POST';

open(STDIN,'test.xml');

my $xmlpost = CGI::XMLPost->new({strict => 1});

ok($xmlpost,'Can open the document');

is($xmlpost->data(),<<EOXML,'Get back what we expected');
<test>
  <data>
    <item index="1" />
    <item index="2" />
    <item index="3" />
  </data>
</test>
EOXML

is('application/xml', $xmlpost->content_type(),'Got content type');
is($ENV{CONTENT_LENGTH}, $xmlpost->content_length(),'Got correct content length');

my $got_xpath = 0;

eval
{
   require XML::XPath;
   $got_xpath = 1;
};

SKIP:
{
   skip 'No XML::XPath', 1 unless $got_xpath;

   my $xpath;
   is('XML::XPath',ref($xpath = $xmlpost->as_xpath()),'Got XPath Object');
}
