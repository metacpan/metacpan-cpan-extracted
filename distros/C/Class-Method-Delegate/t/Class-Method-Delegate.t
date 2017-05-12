# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Method-Delegate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Class::Method::Delegate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

FROM: {
  package test_package_to_delegate_from;
  use Class::Method::Delegate;

  sub new {
    return bless {}, shift;
  }

  delegate methods => [ 'simple_string', 'with_attributes', 'return_myself' ], to => sub { test_package_to_delegate_to->new() };

}

TO: {
  package test_package_to_delegate_to;

  sub new {
    return bless {}, shift;
  }

  sub simple_string {
    return "simple_string returned a string";
  }

  sub with_attributes {
    my $self = shift;

    return @_;
  }

  sub delegated_by {
    my $self = shift;
    if(@_) {
        $self->{delegated_by} = shift;
    }
    return $self->{delegated_by};
  }

  sub return_myself {
    return shift;
  }  
}

ok my $test_package_to_delegate_from = test_package_to_delegate_from->new();

is( $test_package_to_delegate_from->simple_string(), "simple_string returned a string");
ok my @response = $test_package_to_delegate_from->with_attributes(1,2,3,5);
is( $response[0], 1);
is( $response[1], 2);
is( $response[2], 3);
is( $response[3], 5);
is( $test_package_to_delegate_from->return_myself()->delegated_by(), $test_package_to_delegate_from);

done_testing();
