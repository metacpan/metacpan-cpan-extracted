use strict;
use warnings;

use Test::More;
use experimental qw(signatures);

use Acme::Signature::Arity;

for my $case (
    [ 'sub () { }', min => 0, max => 0 ],
    [ 'sub ($x) { }', min => 1, max => 1 ],
    [ 'sub ($x, @) { }', min => 1, max => undef ],
    [ 'sub ($x = 1, @) { }', min => 0, max => undef ],
    [ 'sub ($x, $y = 1, @) { }', min => 1, max => undef ],
    [ 'sub ($x, $y, %) { }', min => 2, max => undef ],
    [ 'sub ($x, $y, $z = 5) { }', min => 2, max => 3 ],
    [ 'sub { }', min => 0, max => undef ],
) {
    my ($def, %args) = @$case;
    subtest $def => sub {
        my $code = eval $def;
        is(min_arity($code), $args{min}, 'min arity is ' . ($args{min} // '<undef>')) or note explain [ arity($code) ] if exists $args{min};
        is(max_arity($code), $args{max}, 'max arity is ' . ($args{max} // '<undef>')) or note explain [ arity($code) ] if exists $args{max};
        done_testing;
    };
}

is(eval {
    Acme::Signature::Arity::coderef_ignoring_extra(sub ($x) {
        die 'invalid data passed' unless $x eq "first"
    })->("first", "second", 3, 4);
    1
}, 1) or note explain $@;

done_testing;
