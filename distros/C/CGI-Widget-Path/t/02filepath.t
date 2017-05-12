use Test;
BEGIN { plan tests => 3 }
use CGI::Widget::Path;

ok(1);

# create new path object
ok( my $path = new CGI::Widget::Path( 
	separator => ' / ',
	base_url  => 'http://www.foo.com',
	path => '/one/two/tree/four.txt'
) );
$path->{elems}->[0]->{name} = 'My Home';
ok( $path->asHTML );
print $path->{'out'};
