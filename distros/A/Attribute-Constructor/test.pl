use Test;
BEGIN { plan tests => 6 };
use Attribute::Constructor;
ok(1); # If we made it this far, we're ok.

# Define the object that used it
package TestConstructor;
use Attribute::Constructor;
sub new : Constructor {
	my $self = shift;
	$self->{'attribute1'} = shift;
}
sub get_attribute1 {
	my $self = shift;
	return $self->{'attribute1'};
}

# Put us back in the 'main' namespace
package main;

my $test_obj = TestConstructor->new( 'bob' );
ok( defined($test_obj) ); # Static method works
ok( $test_obj->get_attribute1(), 'bob' ); # It is a real instance a real value

my $new_test_obj = $test_obj->new( 'cow' ); 
ok( defined($new_test_obj) ); # Virtual method works
ok( $new_test_obj->get_attribute1(), 'cow' ); # Value for new object

ok( $test_obj->get_attribute1(), 'bob' ); # Make sure we are dealing with
					# two different objects
