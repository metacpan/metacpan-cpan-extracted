#!perl

## Import the DSL keywords into the current package (main) and then run some
## "domain specific" commands, including using the "baz" command to break the
## encapsulation and get at the underlying instance of the DSL.

use strict;
use warnings;

use lib qw(t/lib);

use Test::More;
use Test::Deep;

use MooseDSL qw( -install_dsl );

# peek under the covers, get instance
my $dsl = return_self;
isa_ok( $dsl, 'MooseDSL' );

# test argument handling, single scalar
argulator("a scalar");
cmp_deeply( $dsl->call_log, ['a scalar'], 'scalar arg works' );
clear_call_log;

# test argument handling, list of args
argulator(qw(a list of things));
cmp_deeply( $dsl->call_log, ['a::list::of::things'], 'list arg works' );
clear_call_log;

done_testing;
