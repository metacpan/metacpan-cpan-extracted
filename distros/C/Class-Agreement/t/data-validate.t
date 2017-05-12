#!perl

use strict;
use warnings;

# =head2 Why not just use Carp::Assert?
#
# Use L<Carp::Assert> and L<Carp::Assert> if you need to check I<values>. If you
# want to assert I<behavior>, L<Class::Agreement> does everything that
# L<Carp::Assert> can do for you B<and> it tells you which components are faulty
# if something fails.
#
# If you're looking for the sexiness of L<Carp::Assert::More>, try using
# L<Class::Agreement> with L<Data::Validate>:

use Test::More;
use Test::Exception;

my $optional_module = "Data::Validate 0.04";
eval "use $optional_module";
plan $@
    ? (
    skip_all => "Optional module $optional_module required for this test" )
    : ( tests => 6 );

{

    package Camel;
    use Class::Agreement;
    require Data::Validate;
    import Data::Validate qw(:math :string);

    precondition foo => sub { is_integer( $_[1] ) };
    precondition bar => sub { is_greater_than( $_[1], 0 ) };
    precondition baz => sub { is_alphanumeric( $_[1] ) };

    sub foo { }
    sub bar { }
    sub baz { }
}

lives_ok { Camel->foo(5) } "is_integer simple success";
dies_ok  { Camel->foo(2.48) } "is_integer simple failure";
lives_ok { Camel->bar(5) } "is_greater_than simple success";
dies_ok  { Camel->bar(-8) } "is_greater_than simple failure";
lives_ok { Camel->baz('a8dj2') } "is_alphanumeric simple success";
dies_ok  { Camel->baz('!9*d.3$a') } "is_alphanumeric simple failure";
