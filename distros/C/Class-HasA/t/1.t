# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
ok(1); # If we made it this far, we're ok.

sub fowl { return bless {}, "Dummy" }
use Class::HasA (fish => "fowl", [qw[foo bar]] => "fowl");

(bless {})->fish(1);
(bless {})->foo(1);

sub Dummy::fish { my ($self, $arg) = @_; Test::ok($arg) }
sub Dummy::foo { my ($self, $arg) = @_; Test::ok($arg) }


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

