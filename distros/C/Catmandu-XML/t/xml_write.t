use strict;
use warnings;
use Test::More;
use Catmandu::Fix::xml_write as => 'serialize';

my $xml  = [ 'foo', { bar => 'doz' }, [ 'baz' ] ];
my $data = { xml =>  [ 'foo', { bar => 'doz' }, [ 'baz' ] ] };

serialize($data,'xml');
is_deeply $data->{xml}, 
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<foo bar=\"doz\">baz</foo>\n",
    'xml_write';

$data = { xml => [ foo => [ [ bar => ['doz'] ] ] ] };
serialize($data,'xml', attributes => 0, pretty => 1, xmldecl => 0);
is_deeply $data->{xml}, <<XML, 'xml_write(attributes:0, pretty:1, xmldecl:0)'; 
<foo>
  <bar>doz</bar>
</foo>
XML

done_testing;
