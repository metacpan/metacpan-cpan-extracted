#!/usr/bin/perl -w

use Test::More tests => 5;

use_ok(CGI::Form2XML);


my $x = CGI::Form2XML->new();

ok($x,"create object");

$x->ns_prefix("nfd");

is($x->ns_prefix(),'nfd',"Can set prefix");

$x->omit_info(1);

ok($x->omit_info(),'Omit info works');

$x->param('foo','bar');

my $foo =<<EOXML;
<nfd:form_data xmlns:nfd="http://schemas.gellyfish.com/FormData">
   <nfd:items>
      <nfd:field name="foo">bar</nfd:field>
   </nfd:items>
</nfd:form_data>
EOXML

my $xml = $x->asXML();

is($xml,$foo,'Output looks alright');
