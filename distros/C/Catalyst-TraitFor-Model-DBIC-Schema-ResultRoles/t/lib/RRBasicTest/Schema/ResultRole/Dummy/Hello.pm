
package RRBasicTest::Schema::ResultRole::Dummy::Hello;

use Moose::Role;

sub hello {
	return "hello world";
}
no Moose::Role;
1;
