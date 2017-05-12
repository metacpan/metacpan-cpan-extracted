use Test;
BEGIN { plan tests => 4 }
use CGI::Widget::Path;

ok(1);

# create new path object
ok( my $path = new CGI::Widget::Path( 
	separator => ' > ',
#	base_url  => 'http://www.foo.com',
	link_last => 1,
	elems     => [
	{ name => 'One', wrap => [ { tag => 'a', attr => { 'href' => 'url1', class => 'myclass' } } ], append => 1 },
	{ name => 'Two', wrap => [ { tag => 'a', attr => { 'href' => '/url2' } } ], append => 1 },
	]
) );
ok( $path->addElem( elems => [
	{ name => 'Three', wrap => [ { tag => 'a', attr => { 'href' => '/url3', class => 'myclass' } } ], append => 1 },
	{ name => 'Four', wrap => [ { tag => 'a', attr => { 'href' => '/url4' } } ], append => 1 }
	] ) );
ok( $path->asHTML );
print $path->{'out'};
