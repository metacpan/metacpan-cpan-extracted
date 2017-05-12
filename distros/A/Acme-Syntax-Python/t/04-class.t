use lib './lib';
use strict;
use warnings;
use Acme::Syntax::Python;
import Test::More;
class Test::Class:
    import Test::More;
    def __init__:
        $self->{test} = "Hello";

    def method1($self):
        ok($self->{test} eq "Hello", "Methods work!");

my $tc = Test::Class->new();
$tc->method1();
done_testing();
