use strict;
use warnings;
use Test::More;
use Catmandu::Fix::xml_simple as => 'simple';

my $xml = '<root><a>x</a><a>y</a><a>z</a></root>';
my $data = { xml => $xml };
simple($data,'xml');
is_deeply $data->{xml}, { a => [qw(x y z)] }, 'parse with xml_simple';

# TODO: include attributes

$xml = [ root => {}, [[a=>{},['x']],[a=>{},['y']],[a=>{},['z']] ] ];
$data = { xml => $xml };
simple($data,'xml');
is_deeply $data, { xml => { a => [qw(x y z)] } }, 'transform with xml_simple';

done_testing;
