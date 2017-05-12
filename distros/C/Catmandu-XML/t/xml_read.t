use strict;
use warnings;
use Test::More;
use Catmandu::Fix::xml_read as => 'parse';

my $xml = '<foo bar="doz">baz</foo>';
my $data = { xml => $xml };

parse($data,'xml');
is_deeply $data->{xml}, [ 'foo', { bar => 'doz' }, [ 'baz' ] ], 'xml_read';

$data = { xml => $xml };
parse($data,'xml', attributes=> 0);
is_deeply $data->{xml}, [ 'foo', [ 'baz' ] ], 'xml_read(attributes=0)';

$xml = '<root><a>x</a><a>y</a><a>z</a></root>';
$data = { xml => $xml };
parse($data,'xml', simple => 1);
is_deeply $data->{xml}, { a => [qw(x y z)] }, 'xml_read(simple=0)';

$data = { xml => $xml };
parse($data,'xml', attributes => 0, path => 'a');
is_deeply $data->{xml}, [[a=>['x']],[a=>['y']],[a=>['z']] ], 'xml_read(path=a)';

done_testing;
