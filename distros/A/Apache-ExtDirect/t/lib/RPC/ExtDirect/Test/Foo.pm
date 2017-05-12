package RPC::ExtDirect::Test::Foo;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect;

# Return scalar result
sub foo_foo : ExtDirect(1) {
    return "foo! '${_[1]}'"
}

# Return arrayref result
sub foo_bar : ExtDirect(2) {
    return [ 'foo! bar!', $_[1], $_[2] ]
}

# Return hashref result
sub foo_baz : ExtDirect( params => [foo, bar, baz] ) {
    my $class = shift;
    my %param = @_;

    my $ret = { msg => 'foo! bar! baz!', foo => $param{foo},
                bar => $param{bar},      baz => $param{baz},
              };

    delete @param{ qw(foo bar baz _env) };
    @$ret{ keys %param } = values %param;

    return $ret;
}

1;
