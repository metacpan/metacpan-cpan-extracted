use strict;
use warnings;

package Test::Class::TestGroup;

no warnings 'redefine';

use parent 'Test::Class';

use Test::More;

sub TestGroup : ATTR(CODE,RAWDATA) {
    my ( $class, $symbol, $code_ref, $attr, $args ) = @_;

    # get the test description either from the args, or from the sub routine name; then reset the args to 1 (single test)
    my $test_description = $args || *{$symbol}{NAME};
    $args = 1;

    # wrap the old function in a subtest
    my $old_func = \&{$symbol};
    *{$symbol} = sub {
        my @params = @_;
        subtest $test_description => sub {
            $old_func->( @params );
        };
    };

    # tell Test::Class to run as a single test
    Test::Class::Test( $class, $symbol, $code_ref, $attr, $args );
}

1;
